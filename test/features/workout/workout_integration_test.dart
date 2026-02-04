import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_log/features/workout/domain/entities/workout.dart';
import 'package:shape_log/features/workout/presentation/providers/workout_provider.dart';

void main() {
  test('Workout Provider returns mock data', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final workouts = await container.read(workoutListProvider.future);

    expect(workouts, isNotEmpty);
    expect(workouts.first, isA<Workout>());
    expect(workouts.length, greaterThanOrEqualTo(2));
    expect(workouts.first.name, contains('Treino '));
  });
}
