import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/workout.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../data/datasources/workout_local_data_source.dart';
import '../../data/repositories/workout_repository_impl.dart';

// Dependency Injection
final workoutLocalDataSourceProvider = Provider<WorkoutLocalDataSource>((ref) {
  return WorkoutLocalDataSourceImpl();
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final localDataSource = ref.watch(workoutLocalDataSourceProvider);
  return WorkoutRepositoryImpl(localDataSource: localDataSource);
});

// State Management
final workoutListProvider = FutureProvider<List<Workout>>((ref) async {
  final repository = ref.watch(workoutRepositoryProvider);
  return repository.getWorkouts();
});
