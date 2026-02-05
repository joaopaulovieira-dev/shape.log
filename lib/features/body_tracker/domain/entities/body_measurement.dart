class BodyMeasurement {
  final String id;
  final DateTime date;
  final double weight;
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

  BodyMeasurement({
    required this.id,
    required this.date,
    required this.weight,
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
  });

  BodyMeasurement copyWith({
    String? id,
    DateTime? date,
    double? weight,
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
  }) {
    return BodyMeasurement(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
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
    );
  }
}
