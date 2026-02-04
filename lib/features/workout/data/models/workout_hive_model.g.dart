// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutHiveModelAdapter extends TypeAdapter<WorkoutHiveModel> {
  @override
  final int typeId = 0;

  @override
  WorkoutHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutHiveModel(
      id: fields[0] as String,
      name: fields[1] as String,
      scheduledDays: (fields[2] as List).cast<int>(),
      targetDurationMinutes: fields[3] as int,
      notes: fields[4] as String,
      exercises: (fields[5] as List).cast<ExerciseModel>(),
      activeStartTime: fields[6] as DateTime?,
      expiryDate: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutHiveModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.scheduledDays)
      ..writeByte(3)
      ..write(obj.targetDurationMinutes)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.exercises)
      ..writeByte(6)
      ..write(obj.activeStartTime)
      ..writeByte(7)
      ..write(obj.expiryDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
