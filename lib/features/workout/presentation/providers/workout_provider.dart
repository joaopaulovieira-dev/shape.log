import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_history.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../data/datasources/workout_local_data_source.dart';
import '../../data/repositories/workout_repository_impl.dart';

// Dependency Injection

// provider/workout_provider.dart

final workoutLocalDataSourceProvider = Provider<WorkoutLocalDataSource>((ref) {
  // Box 'routines' is opened in main.dart, so this is safe.
  return WorkoutHiveDataSource();
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final localDataSource = ref.watch(workoutLocalDataSourceProvider);
  return WorkoutRepositoryImpl(localDataSource: localDataSource);
});

// State Management
final routineListProvider = FutureProvider<List<Workout>>((ref) async {
  final repository = ref.watch(workoutRepositoryProvider);
  final routines = await repository.getRoutines();
  routines.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return routines;
});

final historyListProvider = FutureProvider<List<WorkoutHistory>>((ref) async {
  final repository = ref.watch(workoutRepositoryProvider);
  return repository.getHistory();
});
