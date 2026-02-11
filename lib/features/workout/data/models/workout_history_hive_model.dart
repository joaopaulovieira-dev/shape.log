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

  @HiveField(10)
  final DateTime? endTime;

  @HiveField(11)
  final List<String>? imagePaths;

  WorkoutHistoryHiveModel({
    required this.id,
    required this.workoutId,
    required this.workoutName,
    required this.completedDate,
    required this.durationMinutes,
    required this.exercises,
    required this.notes,
    this.startTime,
    this.endTime,
    this.completionPercentage = 0,
    this.rpe,
    this.imagePaths,
  });

  @HiveField(9)
  final int? rpe;

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
      endTime: history.endTime,
      completionPercentage: history.completionPercentage,
      rpe: history.rpe,
      imagePaths: history.imagePaths,
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
      endTime: endTime,
      completionPercentage: completionPercentage,
      rpe: rpe,
      imagePaths: imagePaths ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutId': workoutId,
      'workoutName': workoutName,
      'completedDate': completedDate.toIso8601String(),
      'durationMinutes': durationMinutes,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'notes': notes,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'completionPercentage': completionPercentage,
      'rpe': rpe,
      'imagePaths': imagePaths,
    };
  }

  factory WorkoutHistoryHiveModel.fromMap(Map<String, dynamic> map) {
    return WorkoutHistoryHiveModel(
      id: map['id'] ?? '',
      workoutId: map['workoutId'] ?? '',
      workoutName: map['workoutName'] ?? '',
      completedDate: map['completedDate'] != null
          ? DateTime.parse(map['completedDate'])
          : DateTime.now(),
      durationMinutes: map['durationMinutes'] ?? 0,
      exercises: (map['exercises'] as List? ?? [])
          .map((e) => ExerciseModel.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      notes: map['notes'] ?? '',
      startTime: map['startTime'] != null
          ? DateTime.parse(map['startTime'])
          : null,
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      completionPercentage: (map['completionPercentage'] ?? 0.0).toDouble(),
      rpe: map['rpe'],
      imagePaths: (map['imagePaths'] as List?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}
