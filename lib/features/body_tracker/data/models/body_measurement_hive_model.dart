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

  @HiveField(19)
  final List<String> imagePaths;

  @HiveField(20)
  final String? reportUrl;

  @HiveField(21)
  final double? fatPercentage;

  @HiveField(22)
  final double? fatMassKg;

  @HiveField(23)
  final double? muscleMassKg;

  @HiveField(24)
  final int? visceralFat;

  @HiveField(25)
  final int? bmr;

  @HiveField(26)
  final double? waterPercentage;

  @HiveField(27)
  final int? bodyAge;

  @HiveField(28)
  final double? subcutaneousFat;

  @HiveField(29)
  final double? muscleLeftArm;

  @HiveField(30)
  final double? muscleRightArm;

  @HiveField(31)
  final double? muscleLeftLeg;

  @HiveField(32)
  final double? muscleRightLeg;

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
      imagePaths: entity.imagePaths,
      reportUrl: entity.reportUrl,
      fatPercentage: entity.fatPercentage,
      fatMassKg: entity.fatMassKg,
      muscleMassKg: entity.muscleMassKg,
      visceralFat: entity.visceralFat,
      bmr: entity.bmr,
      waterPercentage: entity.waterPercentage,
      bodyAge: entity.bodyAge,
      subcutaneousFat: entity.subcutaneousFat,
      muscleLeftArm: entity.muscleLeftArm,
      muscleRightArm: entity.muscleRightArm,
      muscleLeftLeg: entity.muscleLeftLeg,
      muscleRightLeg: entity.muscleRightLeg,
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
      imagePaths: imagePaths,
      reportUrl: reportUrl,
      fatPercentage: fatPercentage,
      fatMassKg: fatMassKg,
      muscleMassKg: muscleMassKg,
      visceralFat: visceralFat,
      bmr: bmr,
      waterPercentage: waterPercentage,
      bodyAge: bodyAge,
      subcutaneousFat: subcutaneousFat,
      muscleLeftArm: muscleLeftArm,
      muscleRightArm: muscleRightArm,
      muscleLeftLeg: muscleLeftLeg,
      muscleRightLeg: muscleRightLeg,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'weight': weight,
      'waistCircumference': waistCircumference,
      'chestCircumference': chestCircumference,
      'bicepsRight': bicepsRight,
      'bicepsLeft': bicepsLeft,
      'notes': notes,
      'bmi': bmi,
      'hipsCircumference': hipsCircumference,
      'thighRight': thighRight,
      'thighLeft': thighLeft,
      'calves': calves,
      'calvesRight': calvesRight,
      'calvesLeft': calvesLeft,
      'neck': neck,
      'forearmRight': forearmRight,
      'forearmLeft': forearmLeft,
      'shoulders': shoulders,
      'imagePaths': imagePaths,
      'reportUrl': reportUrl,
      'fatPercentage': fatPercentage,
      'fatMassKg': fatMassKg,
      'muscleMassKg': muscleMassKg,
      'visceralFat': visceralFat,
      'bmr': bmr,
      'waterPercentage': waterPercentage,
      'bodyAge': bodyAge,
      'subcutaneousFat': subcutaneousFat,
      'muscleLeftArm': muscleLeftArm,
      'muscleRightArm': muscleRightArm,
      'muscleLeftLeg': muscleLeftLeg,
      'muscleRightLeg': muscleRightLeg,
    };
  }

  factory BodyMeasurementHiveModel.fromMap(Map<String, dynamic> map) {
    return BodyMeasurementHiveModel(
      id: map['id'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      weight: (map['weight'] ?? 0.0).toDouble(),
      waistCircumference: (map['waistCircumference'] ?? 0.0).toDouble(),
      chestCircumference: (map['chestCircumference'] ?? 0.0).toDouble(),
      bicepsRight: (map['bicepsRight'] ?? 0.0).toDouble(),
      bicepsLeft: (map['bicepsLeft'] ?? 0.0).toDouble(),
      notes: map['notes'] ?? '',
      bmi: (map['bmi'] as num?)?.toDouble(),
      hipsCircumference: (map['hipsCircumference'] as num?)?.toDouble(),
      thighRight: (map['thighRight'] as num?)?.toDouble(),
      thighLeft: (map['thighLeft'] as num?)?.toDouble(),
      calves: (map['calves'] as num?)?.toDouble(),
      calvesRight: (map['calvesRight'] as num?)?.toDouble(),
      calvesLeft: (map['calvesLeft'] as num?)?.toDouble(),
      neck: (map['neck'] as num?)?.toDouble(),
      forearmRight: (map['forearmRight'] as num?)?.toDouble(),
      forearmLeft: (map['forearmLeft'] as num?)?.toDouble(),
      shoulders: (map['shoulders'] as num?)?.toDouble(),
      imagePaths: List<String>.from(map['imagePaths'] ?? []),
      reportUrl: map['reportUrl'],
      fatPercentage: (map['fatPercentage'] as num?)?.toDouble(),
      fatMassKg: (map['fatMassKg'] as num?)?.toDouble(),
      muscleMassKg: (map['muscleMassKg'] as num?)?.toDouble(),
      visceralFat: map['visceralFat'] as int?,
      bmr: map['bmr'] as int?,
      waterPercentage: (map['waterPercentage'] as num?)?.toDouble(),
      bodyAge: map['bodyAge'] as int?,
      subcutaneousFat: (map['subcutaneousFat'] as num?)?.toDouble(),
      muscleLeftArm: (map['muscleLeftArm'] as num?)?.toDouble(),
      muscleRightArm: (map['muscleRightArm'] as num?)?.toDouble(),
      muscleLeftLeg: (map['muscleLeftLeg'] as num?)?.toDouble(),
      muscleRightLeg: (map['muscleRightLeg'] as num?)?.toDouble(),
    );
  }
}
