class Workout {
  final String id;
  final String name; // "A", "B", "C"
  final DateTime date;
  final List<Exercise> exercises;
  final int cardioMinutes;
  final String cardioType;
  final String? observation;

  Workout({
    required this.id,
    required this.name,
    required this.date,
    required this.exercises,
    this.cardioMinutes = 0,
    this.cardioType = '',
    this.observation,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'cardioMinutes': cardioMinutes,
      'cardioType': cardioType,
      'observation': observation,
    };
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'],
      name: json['name'],
      date: DateTime.parse(json['date']),
      exercises: (json['exercises'] as List)
          .map((e) => Exercise.fromJson(e))
          .toList(),
      cardioMinutes: json['cardioMinutes'] ?? 0,
      cardioType: json['cardioType'] ?? '',
      observation: json['observation'],
    );
  }
}

class Exercise {
  final String name;
  final double load; // kg
  final String? observation;
  final bool isCompleted;

  Exercise({
    required this.name,
    required this.load,
    this.observation,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'load': load,
      'observation': observation,
      'isCompleted': isCompleted,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'],
      load: (json['load'] as num).toDouble(),
      observation: json['observation'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}
