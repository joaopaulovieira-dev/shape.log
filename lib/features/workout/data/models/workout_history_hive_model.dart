import 'package:hive/hive.dart';
import '../../domain/entities/workout_history.dart';
import 'exercise_model.dart';

part 'workout_history_hive_model.g.dart';

@HiveType(typeId: 4)
class WorkoutHistoryHiveModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String workoutId;

  @HiveField(2)
  final String workoutName;

  @HiveField(3)
  final DateTime completedDate;

  @HiveField(4)
  final int durationMinutes;

  @HiveField(5)
  final List<ExerciseModel> exercises;

  @HiveField(6)
  final String notes;

  @HiveField(7)
  final DateTime? startTime;

  @HiveField(8)
  final double completionPercentage;

  WorkoutHistoryHiveModel({
    required this.id,
    required this.workoutId,
    required this.workoutName,
    required this.completedDate,
    required this.durationMinutes,
    required this.exercises,
    required this.notes,
    this.startTime,
    this.completionPercentage = 0,
  });

  factory WorkoutHistoryHiveModel.fromEntity(WorkoutHistory history) {
    return WorkoutHistoryHiveModel(
      id: history.id,
      workoutId: history.workoutId,
      workoutName: history.workoutName,
      completedDate: history.completedDate,
      durationMinutes: history.durationMinutes,
      exercises: history.exercises
          .map((e) => ExerciseModel.fromEntity(e))
          .toList(),
      notes: history.notes,
      startTime: history.startTime,
      completionPercentage: history.completionPercentage,
    );
  }

  WorkoutHistory toEntity() {
    return WorkoutHistory(
      id: id,
      workoutId: workoutId,
      workoutName: workoutName,
      completedDate: completedDate,
      durationMinutes: durationMinutes,
      exercises: exercises.map((e) => e.toEntity()).toList(),
      notes: notes,
      startTime: startTime,
      completionPercentage: completionPercentage,
    );
  }
}
