import 'package:hive/hive.dart';
import '../../domain/entities/workout_enums.dart';

part 'workout_enums_adapter.g.dart';

@HiveType(typeId: 1)
enum WorkoutTypeHive {
  @HiveField(0)
  A,
  @HiveField(1)
  B,
  @HiveField(2)
  C,
}

extension WorkoutTypeMapper on WorkoutType {
  WorkoutTypeHive toHive() {
    return WorkoutTypeHive.values[index];
  }
}

extension WorkoutTypeHiveMapper on WorkoutTypeHive {
  WorkoutType toDomain() {
    return WorkoutType.values[index];
  }
}

@HiveType(typeId: 2)
enum WorkoutStatusHive {
  @HiveField(0)
  pending,
  @HiveField(1)
  completed,
}

extension WorkoutStatusMapper on WorkoutStatus {
  WorkoutStatusHive toHive() {
    return WorkoutStatusHive.values[index];
  }
}

extension WorkoutStatusHiveMapper on WorkoutStatusHive {
  WorkoutStatus toDomain() {
    return WorkoutStatus.values[index];
  }
}
