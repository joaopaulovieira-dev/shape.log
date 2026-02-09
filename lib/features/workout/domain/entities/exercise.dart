import 'exercise_set_history.dart';

enum ExerciseTypeEntity { weight, cardio }

class Exercise {
  final String name;
  final int sets;
  final int reps;
  final double weight;
  final String? youtubeUrl;
  final List<String> imagePaths;
  final String? equipmentNumber;
  final String? technique;
  final bool isCompleted;
  final int restTimeSeconds;

  final List<ExerciseSetHistory>? setsHistory;

  final ExerciseTypeEntity type;
  final double? cardioDurationMinutes;
  final String? cardioIntensity;

  const Exercise({
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
    this.setsHistory,
    this.type = ExerciseTypeEntity.weight,
    this.cardioDurationMinutes,
    this.cardioIntensity,
  });

  Exercise copyWith({
    String? name,
    int? sets,
    int? reps,
    double? weight,
    String? youtubeUrl,
    List<String>? imagePaths,
    String? equipmentNumber,
    String? technique,
    bool? isCompleted,
    int? restTimeSeconds,
    List<ExerciseSetHistory>? setsHistory,
    ExerciseTypeEntity? type,
    double? cardioDurationMinutes,
    String? cardioIntensity,
  }) {
    return Exercise(
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      imagePaths: imagePaths ?? this.imagePaths,
      equipmentNumber: equipmentNumber ?? this.equipmentNumber,
      technique: technique ?? this.technique,
      isCompleted: isCompleted ?? this.isCompleted,
      restTimeSeconds: restTimeSeconds ?? this.restTimeSeconds,
      setsHistory: setsHistory ?? this.setsHistory,
      type: type ?? this.type,
      cardioDurationMinutes:
          cardioDurationMinutes ?? this.cardioDurationMinutes,
      cardioIntensity: cardioIntensity ?? this.cardioIntensity,
    );
  }
}
