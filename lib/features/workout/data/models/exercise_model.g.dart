// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseModelAdapter extends TypeAdapter<ExerciseModel> {
  @override
  final int typeId = 3;

  @override
  ExerciseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseModel(
      name: fields[0] as String,
      sets: fields[1] as int,
      reps: fields[2] as int,
      weight: fields[3] as double,
      youtubeUrl: fields[4] as String?,
      imagePaths: (fields[7] as List).cast<String>(),
      equipmentNumber: fields[6] as String?,
      technique: fields[9] as String?,
      isCompleted: fields[8] as bool,
      restTimeSeconds: fields[10] as int,
      setsHistory: (fields[11] as List).cast<ExerciseSetHistoryHiveModel>(),
      type: fields[12] as ExerciseType?,
      cardioDurationMinutes: fields[13] as double?,
      cardioIntensity: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.sets)
      ..writeByte(2)
      ..write(obj.reps)
      ..writeByte(3)
      ..write(obj.weight)
      ..writeByte(4)
      ..write(obj.youtubeUrl)
      ..writeByte(7)
      ..write(obj.imagePaths)
      ..writeByte(6)
      ..write(obj.equipmentNumber)
      ..writeByte(9)
      ..write(obj.technique)
      ..writeByte(8)
      ..write(obj.isCompleted)
      ..writeByte(10)
      ..write(obj.restTimeSeconds)
      ..writeByte(11)
      ..write(obj.setsHistory)
      ..writeByte(12)
      ..write(obj.type)
      ..writeByte(13)
      ..write(obj.cardioDurationMinutes)
      ..writeByte(14)
      ..write(obj.cardioIntensity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExerciseTypeAdapter extends TypeAdapter<ExerciseType> {
  @override
  final int typeId = 9;

  @override
  ExerciseType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExerciseType.weight;
      case 1:
        return ExerciseType.cardio;
      default:
        return ExerciseType.weight;
    }
  }

  @override
  void write(BinaryWriter writer, ExerciseType obj) {
    switch (obj) {
      case ExerciseType.weight:
        writer.writeByte(0);
        break;
      case ExerciseType.cardio:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
