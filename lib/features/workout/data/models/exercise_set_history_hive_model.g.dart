// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_set_history_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseSetHistoryHiveModelAdapter
    extends TypeAdapter<ExerciseSetHistoryHiveModel> {
  @override
  final int typeId = 8;

  @override
  ExerciseSetHistoryHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseSetHistoryHiveModel(
      setNumber: fields[0] as int,
      weight: fields[1] as double,
      reps: fields[2] as int,
      isWarmup: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseSetHistoryHiveModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.setNumber)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.reps)
      ..writeByte(3)
      ..write(obj.isWarmup);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseSetHistoryHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
