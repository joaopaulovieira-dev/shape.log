import '../entities/workout.dart';

import '../../domain/entities/workout_history.dart';

abstract class WorkoutRepository {
  Future<List<Workout>> getRoutines();
  Future<void> saveRoutine(Workout workout);
  Future<void> deleteRoutine(String id);

  Future<List<WorkoutHistory>> getHistory();
  Future<void> saveHistory(WorkoutHistory history);
  Future<void> deleteHistory(String id);
}
