import '../../domain/entities/workout.dart';

class WorkoutModel extends Workout {
  const WorkoutModel({
    required super.id,
    required super.name,
    required super.date,
    required super.durationMinutes,
  });

  factory WorkoutModel.fromJson(Map<String, dynamic> json) {
    return WorkoutModel(
      id: json['id'],
      name: json['name'],
      date: DateTime.parse(json['date']),
      durationMinutes: json['durationMinutes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'durationMinutes': durationMinutes,
    };
  }
}
