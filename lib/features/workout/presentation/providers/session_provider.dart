import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/exercise.dart';
import 'dart:async';
import '../providers/workout_provider.dart';
import '../../domain/entities/workout_history.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/exercise_set_history.dart';

// State for the active session
class WorkoutSessionState {
  final Workout? activeWorkout;
  final int currentExerciseIndex;
  final DateTime? sessionStartTime;
  final bool isRestTimerRunning;
  final int restTimerDuration;
  final int restTimerRemaining;
  final bool isSessionComplete;
  final Map<String, String> lastHistoryMap;
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
    Map<String, String>? lastHistoryMap,
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

  @override
  WorkoutSessionState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const WorkoutSessionState();
  }

  Future<void> startSession(Workout workout) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    DateTime startTime = now;
    await prefs.setString('current_session_start', now.toIso8601String());

    state = WorkoutSessionState(
      activeWorkout: workout,
      currentExerciseIndex: 0,
      sessionStartTime: startTime,
      lastHistoryMap: {},
      completedExerciseNames: {},
    );

    await _loadHistoryForWorkout(workout);
  }

  Future<void> _loadHistoryForWorkout(Workout workout) async {
    try {
      final repository = ref.read(workoutRepositoryProvider);
      final historyList = await repository.getHistory();

      final Map<String, String> newMap = {};

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
          newMap[exercise.name] =
              "${lastPerformed.weight}kg - ${lastPerformed.reps} reps";
        }
      }

      state = state.copyWith(lastHistoryMap: newMap);
    } catch (e) {
      print("Error loading history: $e");
    }
  }

  void markExerciseAsCompleted(String exerciseName) {
    if (state.activeWorkout == null) return;

    final newSet = Set<String>.from(state.completedExerciseNames);
    newSet.add(exerciseName);
    state = state.copyWith(completedExerciseNames: newSet);
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
    }
  }

  void jumpToExercise(int index) {
    if (state.activeWorkout == null) return;
    if (index >= 0 && index < state.activeWorkout!.exercises.length) {
      state = state.copyWith(
        currentExerciseIndex: index,
        isRestTimerRunning: false,
      );
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
    }
  }

  void skipRest() {
    nextExercise();
  }

  void startRestTimer(int durationSeconds, {bool isWarmup = false}) {
    _timer?.cancel();

    // Capture set history BEFORE resting
    if (state.currentExercise != null) {
      final currentEx = state.currentExercise!;
      final currentSets = state.setsRecords[currentEx.name] ?? [];
      final newSetNumber = currentSets.length + 1;

      final newSet = ExerciseSetHistory(
        setNumber: newSetNumber,
        weight: currentEx.weight,
        reps: currentEx.reps,
        isWarmup: isWarmup,
      );

      final newMap = Map<String, List<ExerciseSetHistory>>.from(
        state.setsRecords,
      );
      newMap[currentEx.name] = [...currentSets, newSet];

      markExerciseAsCompleted(currentEx.name);

      state = state.copyWith(setsRecords: newMap);
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
        // Timer finished -> auto-advance to next exercise
        nextExercise();
      }
    });
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

  Future<WorkoutHistory?> finishSessionWithRpe(int rpe) async {
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
      if (sets != null && sets.isNotEmpty) {
        return ex.copyWith(setsHistory: sets);
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
    );

    await ref.read(workoutRepositoryProvider).saveHistory(history);

    // Clear Session Prefs
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_session_start');

    state = state.copyWith(isSessionComplete: true);
    return history;
  }

  void exitSession() {
    stopRestTimer();
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('current_session_start');
    });

    state = const WorkoutSessionState();
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
