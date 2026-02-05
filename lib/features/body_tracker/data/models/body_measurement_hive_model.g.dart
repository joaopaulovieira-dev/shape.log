// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'body_measurement_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BodyMeasurementHiveModelAdapter
    extends TypeAdapter<BodyMeasurementHiveModel> {
  @override
  final int typeId = 5;

  @override
  BodyMeasurementHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BodyMeasurementHiveModel(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      weight: fields[2] as double,
      waistCircumference: fields[3] as double,
      chestCircumference: fields[4] as double,
      bicepsRight: fields[5] as double,
      bicepsLeft: fields[6] as double,
      notes: fields[7] as String,
      bmi: fields[8] as double?,
      hipsCircumference: fields[9] as double?,
      thighRight: fields[10] as double?,
      thighLeft: fields[11] as double?,
      calves: fields[12] as double?,
      calvesRight: fields[13] as double?,
      calvesLeft: fields[14] as double?,
      neck: fields[15] as double?,
      forearmRight: fields[16] as double?,
      forearmLeft: fields[17] as double?,
      shoulders: fields[18] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, BodyMeasurementHiveModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.weight)
      ..writeByte(3)
      ..write(obj.waistCircumference)
      ..writeByte(4)
      ..write(obj.chestCircumference)
      ..writeByte(5)
      ..write(obj.bicepsRight)
      ..writeByte(6)
      ..write(obj.bicepsLeft)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.bmi)
      ..writeByte(9)
      ..write(obj.hipsCircumference)
      ..writeByte(10)
      ..write(obj.thighRight)
      ..writeByte(11)
      ..write(obj.thighLeft)
      ..writeByte(12)
      ..write(obj.calves)
      ..writeByte(13)
      ..write(obj.calvesRight)
      ..writeByte(14)
      ..write(obj.calvesLeft)
      ..writeByte(15)
      ..write(obj.neck)
      ..writeByte(16)
      ..write(obj.forearmRight)
      ..writeByte(17)
      ..write(obj.forearmLeft)
      ..writeByte(18)
      ..write(obj.shoulders);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyMeasurementHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
