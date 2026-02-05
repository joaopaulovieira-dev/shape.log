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
  });
}
