class BodyMeasurement {
  final String id;
  final DateTime date;
  final double weight;
  final double? bodyFatPercentage;
  final double? bmi;
  final double waistCircumference;
  final double chestCircumference;
  final double? hipsCircumference;
  final double bicepsRight;
  final double bicepsLeft;
  final double? thighRight;
  final double? thighLeft;
  final double? calvesRight;
  final double? calvesLeft;
  final double? neck;
  final double? forearmRight;
  final double? forearmLeft;
  final double? shoulders;
  final String notes;
  final List<String> imagePaths;
  final String? reportUrl;

  // Bioimpedance - Core
  final double? fatPercentage;
  final double? fatMassKg;
  final double? muscleMassKg;
  final int? visceralFat;
  final int? bmr;
  final double? waterPercentage;
  final int? bodyAge;

  // Bioimpedance - Segmented
  final double? subcutaneousFat;
  final double? muscleLeftArm;
  final double? muscleRightArm;
  final double? muscleLeftLeg;
  final double? muscleRightLeg;

  BodyMeasurement({
    required this.id,
    required this.date,
    required this.weight,
    this.bodyFatPercentage,
    this.bmi,
    required this.waistCircumference,
    required this.chestCircumference,
    this.hipsCircumference,
    required this.bicepsRight,
    required this.bicepsLeft,
    this.thighRight,
    this.thighLeft,
    this.calvesRight,
    this.calvesLeft,
    this.neck,
    this.forearmRight,
    this.forearmLeft,
    this.shoulders,
    this.notes = '',
    this.imagePaths = const [],
    this.reportUrl,
    this.fatPercentage,
    this.fatMassKg,
    this.muscleMassKg,
    this.visceralFat,
    this.bmr,
    this.waterPercentage,
    this.bodyAge,
    this.subcutaneousFat,
    this.muscleLeftArm,
    this.muscleRightArm,
    this.muscleLeftLeg,
    this.muscleRightLeg,
  });

  BodyMeasurement copyWith({
    String? id,
    DateTime? date,
    double? weight,
    double? bodyFatPercentage,
    double? bmi,
    double? waistCircumference,
    double? chestCircumference,
    double? hipsCircumference,
    double? bicepsRight,
    double? bicepsLeft,
    double? thighRight,
    double? thighLeft,
    double? calvesRight,
    double? calvesLeft,
    double? neck,
    double? forearmRight,
    double? forearmLeft,
    double? shoulders,
    String? notes,
    List<String>? imagePaths,
    String? reportUrl,
    double? fatPercentage,
    double? fatMassKg,
    double? muscleMassKg,
    int? visceralFat,
    int? bmr,
    double? waterPercentage,
    int? bodyAge,
    double? subcutaneousFat,
    double? muscleLeftArm,
    double? muscleRightArm,
    double? muscleLeftLeg,
    double? muscleRightLeg,
  }) {
    return BodyMeasurement(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      bmi: bmi ?? this.bmi,
      waistCircumference: waistCircumference ?? this.waistCircumference,
      chestCircumference: chestCircumference ?? this.chestCircumference,
      hipsCircumference: hipsCircumference ?? this.hipsCircumference,
      bicepsRight: bicepsRight ?? this.bicepsRight,
      bicepsLeft: bicepsLeft ?? this.bicepsLeft,
      thighRight: thighRight ?? this.thighRight,
      thighLeft: thighLeft ?? this.thighLeft,
      calvesRight: calvesRight ?? this.calvesRight,
      calvesLeft: calvesLeft ?? this.calvesLeft,
      neck: neck ?? this.neck,
      forearmRight: forearmRight ?? this.forearmRight,
      forearmLeft: forearmLeft ?? this.forearmLeft,
      shoulders: shoulders ?? this.shoulders,
      notes: notes ?? this.notes,
      imagePaths: imagePaths ?? this.imagePaths,
      reportUrl: reportUrl ?? this.reportUrl,
      fatPercentage: fatPercentage ?? this.fatPercentage,
      fatMassKg: fatMassKg ?? this.fatMassKg,
      muscleMassKg: muscleMassKg ?? this.muscleMassKg,
      visceralFat: visceralFat ?? this.visceralFat,
      bmr: bmr ?? this.bmr,
      waterPercentage: waterPercentage ?? this.waterPercentage,
      bodyAge: bodyAge ?? this.bodyAge,
      subcutaneousFat: subcutaneousFat ?? this.subcutaneousFat,
      muscleLeftArm: muscleLeftArm ?? this.muscleLeftArm,
      muscleRightArm: muscleRightArm ?? this.muscleRightArm,
      muscleLeftLeg: muscleLeftLeg ?? this.muscleLeftLeg,
      muscleRightLeg: muscleRightLeg ?? this.muscleRightLeg,
    );
  }
}
