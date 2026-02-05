import 'package:hive/hive.dart';
import '../../domain/entities/exercise.dart';

part 'exercise_model.g.dart';

@HiveType(typeId: 3)
class ExerciseModel extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int sets;

  @HiveField(2)
  final int reps;

  @HiveField(3)
  final double weight;

  @HiveField(4)
  final String? youtubeUrl;

  @HiveField(7)
  final List<String> imagePaths;

  @HiveField(6)
  final String? equipmentNumber;

  @HiveField(9)
  final String? technique;

  @HiveField(8)
  @HiveField(8)
  final bool isCompleted;

  @HiveField(10)
  final int restTimeSeconds;

  ExerciseModel({
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
    this.youtubeUrl,
    this.imagePaths = const [],
    this.equipmentNumber,
    this.technique,
    this.isCompleted = false,
    this.restTimeSeconds = 60,
  });

  factory ExerciseModel.fromEntity(Exercise exercise) {
    return ExerciseModel(
      name: exercise.name,
      sets: exercise.sets,
      reps: exercise.reps,
      weight: exercise.weight,
      youtubeUrl: exercise.youtubeUrl,
      imagePaths: exercise.imagePaths,
      equipmentNumber: exercise.equipmentNumber,
      technique: exercise.technique,
      isCompleted: exercise.isCompleted,
      restTimeSeconds: exercise.restTimeSeconds,
    );
  }

  Exercise toEntity() {
    return Exercise(
      name: name,
      sets: sets,
      reps: reps,
      weight: weight,
      youtubeUrl: youtubeUrl,
      imagePaths: imagePaths,
      equipmentNumber: equipmentNumber,
      technique: technique,
      isCompleted: isCompleted,
      restTimeSeconds: restTimeSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'youtubeUrl': youtubeUrl,
      'imagePaths': imagePaths,
      'equipmentNumber': equipmentNumber,
      'technique': technique,
      'isCompleted': isCompleted,
      'restTimeSeconds': restTimeSeconds,
    };
  }

  factory ExerciseModel.fromMap(Map<String, dynamic> map) {
    return ExerciseModel(
      name: map['name'] ?? '',
      sets: map['sets'] ?? 0,
      reps: map['reps'] ?? 0,
      weight: (map['weight'] ?? 0.0).toDouble(),
      youtubeUrl: map['youtubeUrl'],
      imagePaths: List<String>.from(map['imagePaths'] ?? []),
      equipmentNumber: map['equipmentNumber'],
      technique: map['technique'],
      isCompleted: map['isCompleted'] ?? false,
      restTimeSeconds: map['restTimeSeconds'] ?? 60,
    );
  }
}
