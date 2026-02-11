import 'package:hive/hive.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/enums/activity_level.dart';
import '../../domain/enums/diet_type.dart';

part 'user_profile_hive_model.g.dart';

@HiveType(typeId: 6)
class UserProfileHiveModel extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int age;

  @HiveField(2)
  final double height;

  @HiveField(3)
  final double targetWeight;

  @HiveField(4)
  final String activityLevel; // Store as String for simplicity in Hive

  @HiveField(5)
  final List<String> limitations;

  @HiveField(6)
  final String dietType; // Store as String

  @HiveField(7)
  final String? profilePicturePath;

  UserProfileHiveModel({
    required this.name,
    required this.age,
    required this.height,
    required this.targetWeight,
    required this.activityLevel,
    required this.limitations,
    required this.dietType,
    this.profilePicturePath,
  });

  // Mapper: From Entity
  factory UserProfileHiveModel.fromEntity(UserProfile entity) {
    return UserProfileHiveModel(
      name: entity.name,
      age: entity.age,
      height: entity.height,
      targetWeight: entity.targetWeight,
      activityLevel: entity.activityLevel.name,
      limitations: entity.limitations,
      dietType: entity.dietType.name,
      profilePicturePath: entity.profilePicturePath,
    );
  }

  // Mapper: To Entity
  UserProfile toEntity() {
    return UserProfile(
      name: name,
      age: age,
      height: height,
      targetWeight: targetWeight,
      activityLevel: ActivityLevel.values.firstWhere(
        (e) => e.name == activityLevel,
        orElse: () => ActivityLevel.moderate,
      ),
      limitations: limitations,
      dietType: DietType.values.firstWhere(
        (e) => e.name == dietType,
        orElse: () => DietType.maintenance,
      ),
      profilePicturePath: profilePicturePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'height': height,
      'targetWeight': targetWeight,
      'activityLevel': activityLevel,
      'limitations': limitations,
      'dietType': dietType,
      'profilePicturePath': profilePicturePath,
    };
  }

  factory UserProfileHiveModel.fromMap(Map<String, dynamic> map) {
    return UserProfileHiveModel(
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      height: (map['height'] ?? 0.0).toDouble(),
      targetWeight: (map['targetWeight'] ?? 0.0).toDouble(),
      activityLevel: map['activityLevel'] ?? 'moderate',
      limitations: List<String>.from(map['limitations'] ?? []),
      dietType: map['dietType'] ?? 'maintenance',
      profilePicturePath: map['profilePicturePath'],
    );
  }
}
