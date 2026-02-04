class DailyLog {
  final String id; // usually date string YYYY-MM-DD
  final DateTime date;
  final int waterIntake; // in ml, goal 4000
  final Map<String, bool> supplements; // { 'Creatine': true, 'Whey': false ... }
  final bool workoutCompleted;
  final String? workoutId; // Reference to the Workout document if needed

  DailyLog({
    required this.id,
    required this.date,
    this.waterIntake = 0,
    this.supplements = const {},
    this.workoutCompleted = false,
    this.workoutId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'waterIntake': waterIntake,
      'supplements': supplements,
      'workoutCompleted': workoutCompleted,
      'workoutId': workoutId,
    };
  }

  factory DailyLog.fromJson(Map<String, dynamic> json) {
    return DailyLog(
      id: json['id'],
      date: DateTime.parse(json['date']),
      waterIntake: json['waterIntake'] ?? 0,
      supplements: Map<String, bool>.from(json['supplements'] ?? {}),
      workoutCompleted: json['workoutCompleted'] ?? false,
      workoutId: json['workoutId'],
    );
  }

  // Helper getters
  double get waterProgress => (waterIntake / 4000).clamp(0.0, 1.0);
}
