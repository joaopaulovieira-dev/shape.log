import '../models/workout_model.dart';

abstract class WorkoutLocalDataSource {
  Future<List<WorkoutModel>> getLastWorkouts();
  Future<void> cacheWorkout(WorkoutModel workout);
}

class WorkoutLocalDataSourceImpl implements WorkoutLocalDataSource {
  final List<WorkoutModel> _mockStorage = [];

  @override
  Future<List<WorkoutModel>> getLastWorkouts() async {
    // Mock data for MVP
    return [
      WorkoutModel(
        id: '1',
        name: 'Treino A (Peito e Tríceps)',
        date: DateTime.now(),
        durationMinutes: 60,
      ),
      WorkoutModel(
        id: '2',
        name: 'Treino B (Costas e Bíceps)',
        date: DateTime.now().subtract(const Duration(days: 1)),
        durationMinutes: 45,
      ),
      ..._mockStorage,
    ];
  }

  @override
  Future<void> cacheWorkout(WorkoutModel workout) async {
    _mockStorage.add(workout);
  }
}
