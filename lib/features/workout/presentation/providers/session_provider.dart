import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/workout.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout_history.dart';
import '../providers/workout_provider.dart';

import '../../domain/entities/exercise_set_history.dart';
import '../../data/services/active_session_service.dart';

// State for the active session
class WorkoutSessionState {
  final Workout? activeWorkout;
  final int currentExerciseIndex;
  final DateTime? sessionStartTime;
  final bool isRestTimerRunning;
  final int restTimerDuration;
  final int restTimerRemaining;
  final bool isSessionComplete;
  final Map<String, ExerciseSetHistory> lastHistoryMap;
  final Set<String> completedExerciseNames; // For validation
  final bool showCompletionFeedback;
  final Map<String, List<ExerciseSetHistory>> setsRecords; // Track sets

  const WorkoutSessionState({
    this.activeWorkout,
    this.currentExerciseIndex = 0,
    this.sessionStartTime,
    this.isRestTimerRunning = false,
    this.restTimerDuration = 60,
    this.restTimerRemaining = 0,
    this.isSessionComplete = false,
    this.lastHistoryMap = const {},
    this.completedExerciseNames = const {},
    this.showCompletionFeedback = false,
    this.setsRecords = const {},
  });

  WorkoutSessionState copyWith({
    Workout? activeWorkout,
    int? currentExerciseIndex,
    DateTime? sessionStartTime,
    bool? isRestTimerRunning,
    int? restTimerDuration,
    int? restTimerRemaining,
    bool? isSessionComplete,
    Map<String, ExerciseSetHistory>? lastHistoryMap,
    Set<String>? completedExerciseNames,
    bool? showCompletionFeedback,
    Map<String, List<ExerciseSetHistory>>? setsRecords,
  }) {
    return WorkoutSessionState(
      activeWorkout: activeWorkout ?? this.activeWorkout,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      isRestTimerRunning: isRestTimerRunning ?? this.isRestTimerRunning,
      restTimerDuration: restTimerDuration ?? this.restTimerDuration,
      restTimerRemaining: restTimerRemaining ?? this.restTimerRemaining,
      isSessionComplete: isSessionComplete ?? this.isSessionComplete,
      lastHistoryMap: lastHistoryMap ?? this.lastHistoryMap,
      completedExerciseNames:
          completedExerciseNames ?? this.completedExerciseNames,
      showCompletionFeedback:
          showCompletionFeedback ?? this.showCompletionFeedback,
      setsRecords: setsRecords ?? this.setsRecords,
    );
  }

  Exercise? get currentExercise {
    if (activeWorkout == null) return null;
    if (currentExerciseIndex >= activeWorkout!.exercises.length) return null;
    return activeWorkout!.exercises[currentExerciseIndex];
  }
}

class SessionController extends Notifier<WorkoutSessionState> {
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  WorkoutSessionState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _audioPlayer.dispose();
    });
    return const WorkoutSessionState();
  }

  Future<void> startSession(Workout workout) async {
    final now = DateTime.now();
    DateTime startTime = now;

    // Check if we are restoring? Handled by UI call usually, but let's assume new start unless specified
    // Ideally we should have a separate method for restore

    state = WorkoutSessionState(
      activeWorkout: workout,
      currentExerciseIndex: 0,
      sessionStartTime: startTime,
      lastHistoryMap: {},
      completedExerciseNames: {},
    );

    await _loadHistoryForWorkout(workout, applyToActiveWorkout: true);
    _saveSessionState();
  }

  Future<void> restoreSessionState(Map<String, dynamic> sessionData) async {
    final workoutId = sessionData['workoutId'] as String;
    final exerciseIndex = sessionData['exerciseIndex'] as int;
    final startTime = sessionData['startTime'] as DateTime;
    final setsRecords =
        sessionData['setsRecords'] as Map<String, List<ExerciseSetHistory>>;
    final completedExercises =
        sessionData['completedExerciseNames'] as Set<String>;

    final repository = ref.read(workoutRepositoryProvider);
    final routines = await repository.getRoutines();
    final workout = routines.firstWhere(
      (w) => w.id == workoutId,
      orElse: () => throw Exception('Treino não encontrado'),
    );

    state = WorkoutSessionState(
      activeWorkout: workout,
      currentExerciseIndex: exerciseIndex,
      sessionStartTime: startTime,
      setsRecords: setsRecords,
      completedExerciseNames: completedExercises,
      lastHistoryMap: {}, // Will be loaded below
    );

    await _loadHistoryForWorkout(workout, applyToActiveWorkout: true);
  }

  Future<void> _loadHistoryForWorkout(
    Workout workout, {
    bool applyToActiveWorkout = false,
  }) async {
    try {
      final repository = ref.read(workoutRepositoryProvider);
      final historyList = await repository.getHistory();

      final Map<String, ExerciseSetHistory> newMap = {};

      for (final exercise in workout.exercises) {
        Exercise? lastPerformed;
        for (final history in historyList) {
          final found = history.exercises
              .where((e) => e.name == exercise.name)
              .firstOrNull;
          if (found != null) {
            if (lastPerformed == null) {
              lastPerformed = found;
              break;
            }
          }
        }

        if (lastPerformed != null) {
          // Get the heaviest set or the last set?
          // Proposal: Last set usually indicates the final working weight.
          // Or we can find the set with max weight.
          // Let's stick to the simplest: THE LAST SET performed.
          if (lastPerformed.setsHistory != null &&
              lastPerformed.setsHistory!.isNotEmpty) {
            newMap[exercise.name] = lastPerformed.setsHistory!.last;
          } else {
            // Fallback if setsHistory is missing for some reason (legacy data)
            // We create a dummy one with proper values
            newMap[exercise.name] = ExerciseSetHistory(
              setNumber: 1,
              weight: lastPerformed.weight,
              reps: lastPerformed.reps,
              isWarmup: false,
            );
          }
        }
      }

      var newState = state.copyWith(lastHistoryMap: newMap);

      // Apply history values to the active workout session (Pre-fill)
      if (applyToActiveWorkout && newState.activeWorkout != null) {
        final updatedExercises = newState.activeWorkout!.exercises.map((
          exercise,
        ) {
          final history = newMap[exercise.name];
          if (history != null) {
            // Overwrite with historical values
            return exercise.copyWith(
              weight: history.weight,
              reps: history.reps,
            );
          }
          return exercise;
        }).toList();

        newState = newState.copyWith(
          activeWorkout: newState.activeWorkout!.copyWith(
            exercises: updatedExercises,
          ),
        );
      }

      state = newState;
    } catch (e) {
      print("Error loading history: $e");
    }
  }

  void markExerciseAsCompleted(String exerciseName) {
    if (state.activeWorkout == null) return;

    final newSet = Set<String>.from(state.completedExerciseNames);
    newSet.add(exerciseName);
    state = state.copyWith(completedExerciseNames: newSet);
    _saveSessionState();
  }

  void nextExercise() {
    if (state.activeWorkout == null) return;
    stopRestTimer();

    // If there is a next exercise, move to it.
    if (state.currentExerciseIndex <
        state.activeWorkout!.exercises.length - 1) {
      state = state.copyWith(
        currentExerciseIndex: state.currentExerciseIndex + 1,
        isRestTimerRunning: false,
      );
      _saveSessionState();
    } else {
      // Logic: If on the LAST exercise and next is called, trigger completion feedback
      state = state.copyWith(showCompletionFeedback: true);
    }
  }

  void previousExercise() {
    if (state.currentExerciseIndex > 0) {
      state = state.copyWith(
        currentExerciseIndex: state.currentExerciseIndex - 1,
        isRestTimerRunning: false,
      );
      _saveSessionState();
    }
  }

  void jumpToExercise(int index) {
    if (state.activeWorkout == null) return;
    if (index >= 0 && index < state.activeWorkout!.exercises.length) {
      state = state.copyWith(
        currentExerciseIndex: index,
        isRestTimerRunning: false,
      );
      _saveSessionState();
    }
  }

  void updateCurrentExercise(Exercise updatedExercise) {
    if (state.activeWorkout == null) return;
    final exercises = List<Exercise>.from(state.activeWorkout!.exercises);
    if (state.currentExerciseIndex < exercises.length) {
      exercises[state.currentExerciseIndex] = updatedExercise;
      final updatedWorkout = state.activeWorkout!.copyWith(
        exercises: exercises,
      );
      state = state.copyWith(activeWorkout: updatedWorkout);
      _saveSessionState(); // Persist immediately on update
    }
  }

  void skipRest() {
    // FIX: Only advance to next exercise if sets are done
    if (state.currentExercise != null) {
      final currentEx = state.currentExercise!;
      final currentSets = state.setsRecords[currentEx.name] ?? [];

      // If we haven't finished all sets yet, just stop timer and let user do next set
      if (currentSets.length < currentEx.sets) {
        stopRestTimer();
        return;
      }
    }

    // Otherwise go to next exercise
    nextExercise();
  }

  void startRestTimer(
    int durationSeconds, {
    bool isWarmup = false,
    double? currentWeight,
    int? currentReps,
  }) {
    _timer?.cancel();

    bool isLastSet = false;

    // Capture set history BEFORE resting
    if (state.currentExercise != null) {
      final currentEx = state.currentExercise!;
      final currentSets = state.setsRecords[currentEx.name] ?? [];
      final newSetNumber = currentSets.length + 1;

      // Use provided values or fallback to exercise defaults
      // Critical Fix: Use values passed from UI if available
      final recordedWeight = currentWeight ?? currentEx.weight;
      final recordedReps = currentReps ?? currentEx.reps;

      final newSet = ExerciseSetHistory(
        setNumber: newSetNumber,
        weight: recordedWeight,
        reps: recordedReps,
        isWarmup: isWarmup,
      );

      final newMap = Map<String, List<ExerciseSetHistory>>.from(
        state.setsRecords,
      );
      // Ensure list is modifiable
      final existingList = newMap[currentEx.name] ?? [];
      newMap[currentEx.name] = [...existingList, newSet];

      // Only mark as completed if we reached the target sets
      if (newSetNumber >= currentEx.sets) {
        markExerciseAsCompleted(currentEx.name);
        isLastSet = true;
      }

      state = state.copyWith(setsRecords: newMap);
      _saveSessionState();
    }

    // Check if ALL exercises are now completed
    if (state.activeWorkout != null) {
      final allDone = state.activeWorkout!.exercises.every(
        (e) => state.completedExerciseNames.contains(e.name),
      );
      if (allDone) {
        state = state.copyWith(showCompletionFeedback: true);
        return;
      }
    }

    state = state.copyWith(
      isRestTimerRunning: true,
      restTimerDuration: durationSeconds,
      restTimerRemaining: durationSeconds,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.restTimerRemaining > 0) {
        state = state.copyWith(
          restTimerRemaining: state.restTimerRemaining - 1,
        );
      } else {
        // Timer finished
        _triggerAlert();
        if (isLastSet) {
          // If it was the last set, auto-advance to next exercise
          nextExercise();
        } else {
          // If not the last set, just stop the timer (stay on current exercise for next set)
          stopRestTimer();
        }
      }
    });
  }

  Future<void> _triggerAlert() async {
    try {
      // Play using AssetSource (Robust & Standard)
      await _audioPlayer.setVolume(1.0); // Ensure max volume

      // Play 3 times (Beep... Beep... Beep)
      for (int i = 0; i < 3; i++) {
        await _audioPlayer.play(
          AssetSource('sounds/timer_alert.wav'),
          mode: PlayerMode.mediaPlayer,
          ctx: AudioContext(
            android: AudioContextAndroid(
              isSpeakerphoneOn: false,
              stayAwake: true,
              contentType: AndroidContentType.music,
              usageType: AndroidUsageType.media,
              audioFocus: AndroidAudioFocus.gainTransientMayDuck,
            ),
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playback,
              options: {
                AVAudioSessionOptions.mixWithOthers,
                AVAudioSessionOptions.duckOthers,
              },
            ),
          ),
        );
        // Wait for beep duration (500ms) + small pause (300ms)
        if (i < 2) await Future.delayed(const Duration(milliseconds: 800));
      }

      // 4. Vibrate (Sync with audio: 3x 500ms vibration)
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(
          pattern: [0, 500, 300, 500, 300, 500], // Wait 0, Vib 500, Wait 300...
          intensities: [0, 255, 0, 255, 0, 255],
        );
      }
    } catch (e) {
      print("Error playing alert: $e");
    }
  }

  void addTime(int seconds) {
    if (state.isRestTimerRunning) {
      state = state.copyWith(
        restTimerRemaining: state.restTimerRemaining + seconds,
        restTimerDuration: state.restTimerDuration + seconds,
      );
    }
  }

  void stopRestTimer() {
    _timer?.cancel();
    state = state.copyWith(isRestTimerRunning: false);
  }

  Future<WorkoutHistory?> finishSessionWithRpe(
    int rpe, {
    List<String> imagePaths = const [],
  }) async {
    stopRestTimer();
    if (state.activeWorkout == null) return null;

    final workout = state.activeWorkout!;
    final now = DateTime.now();
    final duration = state.sessionStartTime != null
        ? now.difference(state.sessionStartTime!).inMinutes
        : 0;

    // Calculate completion percentage
    final total = workout.exercises.length;
    final completed = state.completedExerciseNames.length;
    final percentage = total > 0 ? (completed / total) : 0.0;

    // Create new list of exercises with set history populated
    final historyExercises = workout.exercises.map((ex) {
      final sets = state.setsRecords[ex.name];
      // Critical Fix: Check if sets exists, if so attach them
      if (sets != null && sets.isNotEmpty) {
        // We must create a copy of the exercise with the set history attached
        // The default copyWith is shallow for lists? No, but we need to ensure the entity has this field
        // Exercise entity has setsHistory field now? Yes.
        return ex.copyWith(setsHistory: List.from(sets));
      }
      return ex;
    }).toList();

    final history = WorkoutHistory(
      id: const Uuid().v4(),
      workoutId: workout.id,
      workoutName: workout.name,
      completedDate: now,
      startTime: state.sessionStartTime,
      endTime: now,
      durationMinutes: duration,
      exercises: historyExercises, // Use populated exercises
      notes: workout.notes,
      rpe: rpe,
      completionPercentage: percentage,
      imagePaths: imagePaths,
    );

    await ref.read(workoutRepositoryProvider).saveHistory(history);

    // Clear Session Prefs
    await ref.read(activeSessionServiceProvider).clearSession();

    state = state.copyWith(isSessionComplete: true);
    return history;
  }

  void exitSession() {
    stopRestTimer();
    ref.read(activeSessionServiceProvider).clearSession();
    state = const WorkoutSessionState();
  }

  void _saveSessionState() {
    if (state.activeWorkout == null || state.sessionStartTime == null) return;

    ref
        .read(activeSessionServiceProvider)
        .saveSession(
          workoutId: state.activeWorkout!.id,
          exerciseIndex: state.currentExerciseIndex,
          startTime: state.sessionStartTime!,
          setsRecords: state.setsRecords,
          completedExerciseNames: state.completedExerciseNames,
        );
  }

  Future<List<WorkoutHistory>> getExerciseHistory(String exerciseName) async {
    final repository = ref.read(workoutRepositoryProvider);
    final allHistory = await repository.getHistory();

    final relevantHistory = allHistory.where((h) {
      return h.exercises.any((e) => e.name == exerciseName);
    }).toList();

    relevantHistory.sort((a, b) => b.completedDate.compareTo(a.completedDate));

    return relevantHistory;
  }
}

final sessionProvider =
    NotifierProvider<SessionController, WorkoutSessionState>(() {
      return SessionController();
    });
