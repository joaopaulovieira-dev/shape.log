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
  });
}
