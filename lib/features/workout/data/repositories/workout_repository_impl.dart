import 'package:flutter/foundation.dart' show debugPrint;
import '../../../../core/services/sync_service.dart';
import '../models/workout_hive_model.dart';
import '../models/workout_history_hive_model.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_history.dart';
import '../../domain/repositories/workout_repository.dart';
import '../datasources/workout_local_data_source.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  final WorkoutLocalDataSource localDataSource;
  final SyncService? syncService;

  WorkoutRepositoryImpl({required this.localDataSource, this.syncService});

  @override
  Future<List<Workout>> getRoutines() async {
    return localDataSource.getRoutines();
  }

  void _fireAndForget(Future<void> future) {
    future.catchError((e) => debugPrint('[sync] pending: $e'));
  }

  @override
  Future<void> saveRoutine(Workout workout) async {
    await localDataSource.saveRoutine(workout);
    if (syncService != null) {
      _fireAndForget(syncService!.saveWorkout(WorkoutHiveModel.fromEntity(workout)));
    }
  }

  @override
  Future<void> deleteRoutine(String id) async {
    await localDataSource.deleteRoutine(id);
    if (syncService != null) {
      _fireAndForget(syncService!.deleteWorkout(id));
    }
  }

  @override
  Future<List<WorkoutHistory>> getHistory() async {
    return localDataSource.getHistory();
  }

  @override
  Future<void> saveHistory(WorkoutHistory history) async {
    await localDataSource.saveHistory(history);
    if (syncService != null) {
      _fireAndForget(syncService!.saveHistory(WorkoutHistoryHiveModel.fromEntity(history)));
    }
  }

  @override
  Future<void> deleteHistory(String id) async {
    await localDataSource.deleteHistory(id);
    if (syncService != null) {
      _fireAndForget(syncService!.deleteHistory(id));
    }
  }
}
