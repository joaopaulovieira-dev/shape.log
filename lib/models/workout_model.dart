enum WorkoutType { A, B, C }

class ExerciseSet {
  final String name;
  final double weight;
  final String notes;

  ExerciseSet({
    required this.name,
    required this.weight,
    this.notes = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'weight': weight,
      'notes': notes,
    };
  }

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      name: json['name'],
      weight: (json['weight'] as num).toDouble(),
      notes: json['notes'] ?? '',
    );
  }
}

class CardioSession {
  final String type;
  final int durationMinutes;

  CardioSession({
    required this.type,
    required this.durationMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'durationMinutes': durationMinutes,
    };
  }

  factory CardioSession.fromJson(Map<String, dynamic> json) {
    return CardioSession(
      type: json['type'],
      durationMinutes: json['durationMinutes'],
    );
  }
}

class WorkoutSession {
  final String id;
  final DateTime date;
  final WorkoutType type;
  final List<ExerciseSet> exercises;
  final CardioSession? cardio;
  final String notes;

  WorkoutSession({
    required this.id,
    required this.date,
    required this.type,
    required this.exercises,
    this.cardio,
    this.notes = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type.name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'cardio': cardio?.toJson(),
      'notes': notes,
    };
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'],
      date: DateTime.parse(json['date']),
      type: WorkoutType.values.firstWhere((e) => e.name == json['type']),
      exercises: (json['exercises'] as List)
          .map((e) => ExerciseSet.fromJson(e))
          .toList(),
      cardio: json['cardio'] != null
          ? CardioSession.fromJson(json['cardio'])
          : null,
      notes: json['notes'] ?? '',
    );
  }
}
