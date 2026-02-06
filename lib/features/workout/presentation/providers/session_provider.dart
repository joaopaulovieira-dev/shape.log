import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/exercise.dart';
import 'dart:async';
import '../providers/workout_provider.dart';
import '../../domain/entities/workout_history.dart';

// State for the active session
class WorkoutSessionState {
  final Workout? activeWorkout;
  final int currentExerciseIndex;
  final DateTime? sessionStartTime;
  final bool isRestTimerRunning;
  final int restTimerDuration;
  final int restTimerRemaining;
  final bool isSessionComplete;
  final Map<String, String>
  lastHistoryMap; // Exercise ID/Name -> "10kg - 8 reps"

  // Logs for the current running session (could be a Map<ExerciseIndex, List<SetLog>>)
  // For simplicity, we can just store completion status or full logs if needed.
  // We'll keep it simple for the UI first.

  const WorkoutSessionState({
    this.activeWorkout,
    this.currentExerciseIndex = 0,
    this.sessionStartTime,
    this.isRestTimerRunning = false,
    this.restTimerDuration = 60,
    this.restTimerRemaining = 0,
    this.isSessionComplete = false,
    this.lastHistoryMap = const {},
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
    state = WorkoutSessionState(
      activeWorkout: workout,
      currentExerciseIndex: 0,
      sessionStartTime: DateTime.now(),
      lastHistoryMap: {},
    );

    // Load history asynchronously
    await _loadHistoryForWorkout(workout);
  }

  Future<void> _loadHistoryForWorkout(Workout workout) async {
    try {
      final repository = ref.read(workoutRepositoryProvider);
      final historyList = await repository.getHistory();

      final Map<String, String> newMap = {};

      // Sort history by date descending just in case repo doesn't
      // historyList.sort((a, b) => b.completedDate.compareTo(a.completedDate));

      for (final exercise in workout.exercises) {
        // Find the most recent history containing this exercise name
        Exercise? lastPerformed;

        for (final history in historyList) {
          // historyList is List<dynamic> in generic provider but List<WorkoutHistory> in reality
          // We cast it to ensure type safety if needed, or rely on dynamic dispatch
          final found = history.exercises
              .where((e) => e.name == exercise.name)
              .firstOrNull;
          if (found != null) {
            // Assuming historyList is sorted or we iterate to find the 'latest' by date
            // If the list isn't sorted, we should compare dates.
            // For now, assuming the repo returns sorted desc (common pattern) or we take the first we find.
            if (lastPerformed == null) {
              lastPerformed = found;
              break;
            }
          }
        }

        if (lastPerformed != null) {
          // Use Name as key since ID doesn't exist on Exercise
          newMap[exercise.name] =
              "${lastPerformed.weight}kg - ${lastPerformed.reps} reps";
        }
      }

      state = state.copyWith(lastHistoryMap: newMap);
    } catch (e) {
      print("Error loading history: $e");
    }
  }

  void nextExercise() {
    if (state.activeWorkout == null) return;

    if (state.currentExerciseIndex <
        state.activeWorkout!.exercises.length - 1) {
      state = state.copyWith(
        currentExerciseIndex: state.currentExerciseIndex + 1,
        isRestTimerRunning: false, // Ensure timer is off when switching
      );
    } else {
      finishSession();
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
        isRestTimerRunning: false, // Turn off timer if jumping/swiping
      );
    }
  }

  // Triggered when a set is completed
  void startRestTimer(int durationSeconds) {
    _timer?.cancel();
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
        stopRestTimer();
        // Here we could trigger sound/vibration logic via a separate provider/callback
      }
    });
  }

  void stopRestTimer() {
    _timer?.cancel();
    state = state.copyWith(isRestTimerRunning: false);
  }

  void finishSession() {
    stopRestTimer();
    state = state.copyWith(isSessionComplete: true);
  }

  void exitSession() {
    stopRestTimer();
    state = const WorkoutSessionState();
  }
}

final sessionProvider =
    NotifierProvider<SessionController, WorkoutSessionState>(() {
      return SessionController();
    });
