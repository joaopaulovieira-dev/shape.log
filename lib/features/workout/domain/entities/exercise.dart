import 'exercise_set_history.dart';

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
    );
  }
}
