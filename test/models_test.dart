import 'package:flutter_test/flutter_test.dart';
import 'package:shape_log/models/workout_model.dart';
import 'package:shape_log/models/daily_log_model.dart';

void main() {
  group('WorkoutSession', () {
    test('should serialize and deserialize correctly', () {
      final session = WorkoutSession(
        id: '1',
        date: DateTime(2023, 10, 26),
        type: WorkoutType.A,
        exercises: [
          ExerciseSet(name: 'Bench Press', weight: 60.0, notes: 'Easy'),
        ],
        cardio: CardioSession(type: 'Treadmill', durationMinutes: 20),
        notes: 'Good workout',
      );

      final json = session.toJson();
      final fromJson = WorkoutSession.fromJson(json);

      expect(fromJson.id, session.id);
      expect(fromJson.date, session.date);
      expect(fromJson.type, session.type);
      expect(fromJson.exercises.first.name, session.exercises.first.name);
      expect(fromJson.exercises.first.weight, session.exercises.first.weight);
      expect(fromJson.cardio?.type, session.cardio?.type);
      expect(fromJson.notes, session.notes);
    });
  });

  group('DailyLog', () {
    test('should serialize and deserialize correctly', () {
      final log = DailyLog(
        date: DateTime(2023, 10, 26),
        supplements: {'Whey': true, 'Creatine': false},
        waterIntake: 2000,
        workoutId: '123',
      );

      final json = log.toJson();
      final fromJson = DailyLog.fromJson(json);

      expect(fromJson.date, log.date);
      expect(fromJson.supplements['Whey'], true);
      expect(fromJson.supplements['Creatine'], false);
      expect(fromJson.waterIntake, log.waterIntake);
      expect(fromJson.workoutId, log.workoutId);
    });
  });
}
