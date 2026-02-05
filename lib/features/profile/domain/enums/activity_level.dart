enum ActivityLevel {
  sedentary, // Little to no exercise
  light, // Light exercise 1-3 days/week
  moderate, // Moderate exercise 3-5 days/week
  active, // Heavy exercise 6-7 days/week
  athlete, // Very heavy exercise/physical job
}

extension ActivityLevelExtension on ActivityLevel {
  String get label {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Sedentário';
      case ActivityLevel.light:
        return 'Levemente Ativo';
      case ActivityLevel.moderate:
        return 'Moderadamente Ativo';
      case ActivityLevel.active:
        return 'Muito Ativo';
      case ActivityLevel.athlete:
        return 'Atleta';
    }
  }
}
