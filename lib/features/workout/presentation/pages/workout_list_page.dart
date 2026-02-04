import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/workout_provider.dart';

class WorkoutListPage extends ConsumerWidget {
  const WorkoutListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsyncVal = ref.watch(workoutListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Treinos')),
      body: workoutsAsyncVal.when(
        data: (workouts) => workouts.isEmpty
            ? const Center(child: Text('Nenhum treino encontrado.'))
            : ListView.builder(
                itemCount: workouts.length,
                itemBuilder: (context, index) {
                  final workout = workouts[index];
                  return ListTile(
                    leading: const Icon(Icons.fitness_center),
                    title: Text(workout.name),
                    subtitle: Text(
                      '${workout.date.day}/${workout.date.month}/${workout.date.year} - ${workout.durationMinutes} min',
                    ),
                    onTap: () {
                      // TODO: Navigate to details
                    },
                  );
                },
              ),
        error: (err, stack) => Center(child: Text('Erro: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Start new workout
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
