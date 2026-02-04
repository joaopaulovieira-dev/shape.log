import 'package:hive/hive.dart';
import '../../domain/entities/workout.dart';
import 'exercise_model.dart';
// For encoding scheduledDays if needed, or store as List<int> directly

part 'workout_hive_model.g.dart';

@HiveType(typeId: 0)
class WorkoutHiveModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<int> scheduledDays;

  @HiveField(3)
  final int targetDurationMinutes;

  @HiveField(4)
  final String notes;

  @HiveField(5)
  final List<ExerciseModel> exercises;

  @HiveField(6)
  final DateTime? activeStartTime;

  @HiveField(7)
  final DateTime? expiryDate;

  WorkoutHiveModel({
    required this.id,
    required this.name,
    required this.scheduledDays,
    required this.targetDurationMinutes,
    required this.notes,
    required this.exercises,
    this.activeStartTime,
    this.expiryDate,
  });

  factory WorkoutHiveModel.fromEntity(Workout workout) {
    return WorkoutHiveModel(
      id: workout.id,
      name: workout.name,
      scheduledDays: workout.scheduledDays,
      targetDurationMinutes: workout.targetDurationMinutes,
      notes: workout.notes,
      exercises: workout.exercises
          .map((e) => ExerciseModel.fromEntity(e))
          .toList(),
      activeStartTime: workout.activeStartTime,
      expiryDate: workout.expiryDate,
    );
  }

  Workout toEntity() {
    return Workout(
      id: id,
      name: name,
      scheduledDays: scheduledDays,
      targetDurationMinutes: targetDurationMinutes,
      notes: notes,
      exercises: exercises.map((e) => e.toEntity()).toList(),
      activeStartTime: activeStartTime,
      expiryDate: expiryDate,
    );
  }
}
