import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_history.dart';
import '../../domain/repositories/workout_repository.dart';
import '../datasources/workout_local_data_source.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  final WorkoutLocalDataSource localDataSource;

  WorkoutRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Workout>> getRoutines() async {
    return localDataSource.getRoutines();
  }

  @override
  Future<void> saveRoutine(Workout workout) async {
    return localDataSource.saveRoutine(workout);
  }

  @override
  Future<void> deleteRoutine(String id) async {
    return localDataSource.deleteRoutine(id);
  }

  @override
  Future<List<WorkoutHistory>> getHistory() async {
    return localDataSource.getHistory();
  }

  @override
  Future<void> saveHistory(WorkoutHistory history) async {
    return localDataSource.saveHistory(history);
  }
}
