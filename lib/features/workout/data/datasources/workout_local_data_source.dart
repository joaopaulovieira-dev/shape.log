import 'package:hive/hive.dart';
import '../models/workout_hive_model.dart';
import '../models/workout_history_hive_model.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_history.dart';

abstract class WorkoutLocalDataSource {
  Future<List<Workout>> getRoutines();
  Future<void> saveRoutine(Workout workout);
  Future<void> deleteRoutine(String id);

  Future<List<WorkoutHistory>> getHistory();
  Future<void> saveHistory(WorkoutHistory history);
  Future<void> deleteHistory(String id);
}

class WorkoutHiveDataSource implements WorkoutLocalDataSource {
  late Box<WorkoutHiveModel> _routineBox;
  late Box<WorkoutHistoryHiveModel> _historyBox;

  // Initialize both boxes
  // Note: Caller must ensure init() is called or boxes are opened.
  // In main.dart we opened 'workouts', we need to open 'routines' and 'history'.
  // For migration simplicity, let's treat old 'workouts' box as 'routines' or just separate.
  // I will use 'routines' box and 'history_log' box.

  WorkoutHiveDataSource();

  // Helper to ensure boxes are open. In a real app we might inject initialized boxes.
  Future<void> _ensureBoxes() async {
    if (!Hive.isBoxOpen('routines')) {
      _routineBox = await Hive.openBox<WorkoutHiveModel>('routines');
    } else {
      _routineBox = Hive.box<WorkoutHiveModel>('routines');
    }

    if (!Hive.isBoxOpen('history_log')) {
      _historyBox = await Hive.openBox<WorkoutHistoryHiveModel>('history_log');
    } else {
      _historyBox = Hive.box<WorkoutHistoryHiveModel>('history_log');
    }
  }

  @override
  Future<List<Workout>> getRoutines() async {
    await _ensureBoxes();
    return _routineBox.values.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> saveRoutine(Workout workout) async {
    await _ensureBoxes();
    final model = WorkoutHiveModel.fromEntity(workout);
    await _routineBox.put(model.id, model);
  }

  @override
  Future<void> deleteRoutine(String id) async {
    await _ensureBoxes();
    await _routineBox.delete(id);
  }

  @override
  Future<List<WorkoutHistory>> getHistory() async {
    await _ensureBoxes();
    // Sort by date descending usually
    final list = _historyBox.values.map((e) => e.toEntity()).toList();
    list.sort((a, b) => b.completedDate.compareTo(a.completedDate));
    return list;
  }

  @override
  Future<void> saveHistory(WorkoutHistory history) async {
    await _ensureBoxes();
    final model = WorkoutHistoryHiveModel.fromEntity(history);
    await _historyBox.put(model.id, model);
  }

  @override
  Future<void> deleteHistory(String id) async {
    await _ensureBoxes();
    await _historyBox.delete(id);
  }

  // Deprecated methods from interface refactor - removing/replacing
  // I should remove getWorkouts/saveWorkout/deleteWorkout
}
