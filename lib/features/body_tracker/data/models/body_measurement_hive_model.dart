import 'package:hive/hive.dart';
import '../../domain/entities/body_measurement.dart';

part 'body_measurement_hive_model.g.dart';

@HiveType(typeId: 5)
class BodyMeasurementHiveModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final double weight;

  @HiveField(3)
  final double waistCircumference;

  @HiveField(4)
  final double chestCircumference;

  @HiveField(5)
  final double bicepsRight;

  @HiveField(6)
  final double bicepsLeft;

  @HiveField(7)
  final String notes;

  @HiveField(8)
  final double? bmi;

  @HiveField(9)
  final double? hipsCircumference;

  @HiveField(10)
  final double? thighRight;

  @HiveField(11)
  final double? thighLeft;

  @HiveField(12)
  final double? calves; // Deprecated, kept for migration

  @HiveField(13)
  final double? calvesRight;

  @HiveField(14)
  final double? calvesLeft;

  @HiveField(15)
  final double? neck;

  @HiveField(16)
  final double? forearmRight;

  @HiveField(17)
  final double? forearmLeft;

  @HiveField(18)
  final double? shoulders;

  BodyMeasurementHiveModel({
    required this.id,
    required this.date,
    required this.weight,
    required this.waistCircumference,
    required this.chestCircumference,
    required this.bicepsRight,
    required this.bicepsLeft,
    required this.notes,
    this.bmi,
    this.hipsCircumference,
    this.thighRight,
    this.thighLeft,
    this.calves,
    this.calvesRight,
    this.calvesLeft,
    this.neck,
    this.forearmRight,
    this.forearmLeft,
    this.shoulders,
  });

  factory BodyMeasurementHiveModel.fromEntity(BodyMeasurement entity) {
    return BodyMeasurementHiveModel(
      id: entity.id,
      date: entity.date,
      weight: entity.weight,
      waistCircumference: entity.waistCircumference,
      chestCircumference: entity.chestCircumference,
      bicepsRight: entity.bicepsRight,
      bicepsLeft: entity.bicepsLeft,
      notes: entity.notes,
      bmi: entity.bmi,
      hipsCircumference: entity.hipsCircumference,
      thighRight: entity.thighRight,
      thighLeft: entity.thighLeft,
      calves: null,
      calvesRight: entity.calvesRight,
      calvesLeft: entity.calvesLeft,
      neck: entity.neck,
      forearmRight: entity.forearmRight,
      forearmLeft: entity.forearmLeft,
      shoulders: entity.shoulders,
    );
  }

  BodyMeasurement toEntity() {
    // Migration: If new fields are null but old 'calves' exists, use it for both
    final effectiveCalvesRight = calvesRight ?? calves;
    final effectiveCalvesLeft = calvesLeft ?? calves;

    return BodyMeasurement(
      id: id,
      date: date,
      weight: weight,
      waistCircumference: waistCircumference,
      chestCircumference: chestCircumference,
      bicepsRight: bicepsRight,
      bicepsLeft: bicepsLeft,
      notes: notes,
      bmi: bmi,
      hipsCircumference: hipsCircumference,
      thighRight: thighRight,
      thighLeft: thighLeft,
      calvesRight: effectiveCalvesRight,
      calvesLeft: effectiveCalvesLeft,
      neck: neck,
      forearmRight: forearmRight,
      forearmLeft: forearmLeft,
      shoulders: shoulders,
    );
  }
}
