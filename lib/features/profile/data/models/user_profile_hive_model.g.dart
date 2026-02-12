// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileHiveModelAdapter extends TypeAdapter<UserProfileHiveModel> {
  @override
  final int typeId = 6;

  @override
  UserProfileHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfileHiveModel(
      name: fields[0] as String,
      age: fields[1] as int,
      height: fields[2] as double,
      targetWeight: fields[3] as double,
      activityLevel: fields[4] as String,
      limitations: (fields[5] as List).cast<String>(),
      dietType: fields[6] as String,
      profilePicturePath: fields[7] as String?,
      gender: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfileHiveModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.age)
      ..writeByte(2)
      ..write(obj.height)
      ..writeByte(3)
      ..write(obj.targetWeight)
      ..writeByte(4)
      ..write(obj.activityLevel)
      ..writeByte(5)
      ..write(obj.limitations)
      ..writeByte(6)
      ..write(obj.dietType)
      ..writeByte(7)
      ..write(obj.profilePicturePath)
      ..writeByte(8)
      ..write(obj.gender);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
