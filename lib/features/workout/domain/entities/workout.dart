import 'exercise.dart';

class Workout {
  final String id;
  final String name; // Name of the routine (e.g., "Leg Day")
  final List<int> scheduledDays; // 1 = Monday, 7 = Sunday
  final int targetDurationMinutes;
  final String notes;
  final List<Exercise> exercises;

  const Workout({
    required this.id,
    required this.name,
    required this.scheduledDays,
    required this.targetDurationMinutes,
    required this.notes,
    required this.exercises,
  });
}
