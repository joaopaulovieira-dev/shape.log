import 'exercise.dart';

class WorkoutHistory {
  final String id;
  final String workoutId; // Reference to the Routine
  final String workoutName; // Snapshot of name in case it changes
  final DateTime completedDate;
  final int durationMinutes;
  final List<Exercise> exercises; // Snapshot of what was actually done
  final String notes;
  final DateTime? startTime;
  final double completionPercentage;

  const WorkoutHistory({
    required this.id,
    required this.workoutId,
    required this.workoutName,
    required this.completedDate,
    required this.durationMinutes,
    required this.exercises,
    required this.notes,
    this.startTime,
    this.completionPercentage = 0,
    this.rpe, // Rating of Perceived Exertion (1-5)
  });

  final int? rpe;
}
