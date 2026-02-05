enum DietType {
  cutting, // Weight Loss
  maintenance, // Maintain Weight
  bulking, // Gain Muscle
}

extension DietTypeExtension on DietType {
  String get label {
    switch (this) {
      case DietType.cutting:
        return 'Perda de Peso (Cutting)';
      case DietType.maintenance:
        return 'Manutenção';
      case DietType.bulking:
        return 'Ganho de Massa (Bulking)';
    }
  }
}
