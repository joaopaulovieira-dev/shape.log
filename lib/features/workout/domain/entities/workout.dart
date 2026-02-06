import 'exercise.dart';

class Workout {
  final String id;
  final String name; // Name of the routine (e.g., "Leg Day")
  final List<int> scheduledDays; // 1 = Monday, 7 = Sunday
  final int targetDurationMinutes;
  final String notes;
  final List<Exercise> exercises;
  final DateTime? activeStartTime;
  final DateTime? expiryDate;

  const Workout({
    required this.id,
    required this.name,
    required this.scheduledDays,
    required this.targetDurationMinutes,
    required this.notes,
    required this.exercises,
    this.activeStartTime,
    this.expiryDate,
  });

  Workout copyWith({
    String? id,
    String? name,
    List<int>? scheduledDays,
    int? targetDurationMinutes,
    String? notes,
    List<Exercise>? exercises,
    DateTime? activeStartTime,
    DateTime? expiryDate,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      scheduledDays: scheduledDays ?? this.scheduledDays,
      targetDurationMinutes:
          targetDurationMinutes ?? this.targetDurationMinutes,
      notes: notes ?? this.notes,
      exercises: exercises ?? this.exercises,
      activeStartTime: activeStartTime ?? this.activeStartTime,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }
}
