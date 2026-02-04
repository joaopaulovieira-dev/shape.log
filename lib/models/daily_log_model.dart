class DailyLog {
  final DateTime date;
  final Map<String, bool> supplements;
  final int waterIntake; // in ml
  final String? workoutId;

  DailyLog({
    required this.date,
    required this.supplements,
    this.waterIntake = 0,
    this.workoutId,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'supplements': supplements,
      'waterIntake': waterIntake,
      'workoutId': workoutId,
    };
  }

  factory DailyLog.fromJson(Map<String, dynamic> json) {
    return DailyLog(
      date: DateTime.parse(json['date']),
      supplements: Map<String, bool>.from(json['supplements']),
      waterIntake: json['waterIntake'] ?? 0,
      workoutId: json['workoutId'],
    );
  }
}
