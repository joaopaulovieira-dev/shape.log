import '../enums/activity_level.dart';
import '../enums/diet_type.dart';

class UserProfile {
  final String name;
  final int age;
  final double height; // in meters (e.g. 1.75)
  final double? weight; // current weight in kg
  final double targetWeight; // in kg
  final ActivityLevel activityLevel;
  final List<String> limitations; // e.g. "Joelhos", "Ombros"
  final DietType dietType;

  const UserProfile({
    required this.name,
    required this.age,
    required this.height,
    this.weight,
    required this.targetWeight,
    required this.activityLevel,
    required this.limitations,
    required this.dietType,
  });

  UserProfile copyWith({
    String? name,
    int? age,
    double? height,
    double? weight,
    double? targetWeight,
    ActivityLevel? activityLevel,
    List<String>? limitations,
    DietType? dietType,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      targetWeight: targetWeight ?? this.targetWeight,
      activityLevel: activityLevel ?? this.activityLevel,
      limitations: limitations ?? this.limitations,
      dietType: dietType ?? this.dietType,
    );
  }
}
