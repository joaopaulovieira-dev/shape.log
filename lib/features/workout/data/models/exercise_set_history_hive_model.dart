import 'package:hive/hive.dart';
import '../../domain/entities/exercise_set_history.dart';

part 'exercise_set_history_hive_model.g.dart';

@HiveType(typeId: 8)
class ExerciseSetHistoryHiveModel extends HiveObject {
  @HiveField(0)
  final int setNumber;

  @HiveField(1)
  final double weight;

  @HiveField(2)
  final int reps;

  @HiveField(3)
  final bool isWarmup;

  ExerciseSetHistoryHiveModel({
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.isWarmup = false,
  });

  factory ExerciseSetHistoryHiveModel.fromEntity(ExerciseSetHistory entity) {
    return ExerciseSetHistoryHiveModel(
      setNumber: entity.setNumber,
      weight: entity.weight,
      reps: entity.reps,
      isWarmup: entity.isWarmup,
    );
  }

  ExerciseSetHistory toEntity() {
    return ExerciseSetHistory(
      setNumber: setNumber,
      weight: weight,
      reps: reps,
      isWarmup: isWarmup,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'setNumber': setNumber,
      'weight': weight,
      'reps': reps,
      'isWarmup': isWarmup,
    };
  }

  factory ExerciseSetHistoryHiveModel.fromMap(Map<String, dynamic> map) {
    return ExerciseSetHistoryHiveModel(
      setNumber: map['setNumber'] ?? 0,
      weight: (map['weight'] ?? 0.0).toDouble(),
      reps: map['reps'] ?? 0,
      isWarmup: map['isWarmup'] ?? false,
    );
  }
}
