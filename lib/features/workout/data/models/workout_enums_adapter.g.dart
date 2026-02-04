// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_enums_adapter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutTypeHiveAdapter extends TypeAdapter<WorkoutTypeHive> {
  @override
  final int typeId = 1;

  @override
  WorkoutTypeHive read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WorkoutTypeHive.A;
      case 1:
        return WorkoutTypeHive.B;
      case 2:
        return WorkoutTypeHive.C;
      default:
        return WorkoutTypeHive.A;
    }
  }

  @override
  void write(BinaryWriter writer, WorkoutTypeHive obj) {
    switch (obj) {
      case WorkoutTypeHive.A:
        writer.writeByte(0);
        break;
      case WorkoutTypeHive.B:
        writer.writeByte(1);
        break;
      case WorkoutTypeHive.C:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutTypeHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkoutStatusHiveAdapter extends TypeAdapter<WorkoutStatusHive> {
  @override
  final int typeId = 2;

  @override
  WorkoutStatusHive read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WorkoutStatusHive.pending;
      case 1:
        return WorkoutStatusHive.completed;
      default:
        return WorkoutStatusHive.pending;
    }
  }

  @override
  void write(BinaryWriter writer, WorkoutStatusHive obj) {
    switch (obj) {
      case WorkoutStatusHive.pending:
        writer.writeByte(0);
        break;
      case WorkoutStatusHive.completed:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutStatusHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
