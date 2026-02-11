class ExerciseSetHistory {
  final int setNumber;
  final double weight;
  final int reps;
  final bool isWarmup;

  ExerciseSetHistory({
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.isWarmup = false,
  });
}
