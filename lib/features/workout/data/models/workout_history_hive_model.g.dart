// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_history_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutHistoryHiveModelAdapter
    extends TypeAdapter<WorkoutHistoryHiveModel> {
  @override
  final int typeId = 4;

  @override
  WorkoutHistoryHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutHistoryHiveModel(
      id: fields[0] as String,
      workoutId: fields[1] as String,
      workoutName: fields[2] as String,
      completedDate: fields[3] as DateTime,
      durationMinutes: fields[4] as int,
      exercises: (fields[5] as List).cast<ExerciseModel>(),
      notes: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutHistoryHiveModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.workoutId)
      ..writeByte(2)
      ..write(obj.workoutName)
      ..writeByte(3)
      ..write(obj.completedDate)
      ..writeByte(4)
      ..write(obj.durationMinutes)
      ..writeByte(5)
      ..write(obj.exercises)
      ..writeByte(6)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutHistoryHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
