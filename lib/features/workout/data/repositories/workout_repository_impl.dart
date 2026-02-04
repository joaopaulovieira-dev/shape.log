import '../../domain/entities/workout.dart';
import '../../domain/repositories/workout_repository.dart';
import '../datasources/workout_local_data_source.dart';
import '../models/workout_model.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  final WorkoutLocalDataSource localDataSource;

  WorkoutRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Workout>> getWorkouts() async {
    final models = await localDataSource.getLastWorkouts();
    return models;
  }

  @override
  Future<void> addWorkout(Workout workout) async {
    final model = WorkoutModel(
      id: workout.id,
      name: workout.name,
      date: workout.date,
      durationMinutes: workout.durationMinutes,
    );
    return localDataSource.cacheWorkout(model);
  }
}
