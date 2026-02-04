import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

import '../../domain/entities/workout.dart';
import '../providers/workout_provider.dart';

class WorkoutDetailsPage extends ConsumerStatefulWidget {
  final String workoutId;

  const WorkoutDetailsPage({super.key, required this.workoutId});

  @override
  ConsumerState<WorkoutDetailsPage> createState() => _WorkoutDetailsPageState();
}

class _WorkoutDetailsPageState extends ConsumerState<WorkoutDetailsPage> {
  final Set<int> _completedExercises = {};

  @override
  Widget build(BuildContext context) {
    final routinesAsync = ref.watch(routineListProvider);

    return routinesAsync.when(
      data: (routines) {
        final workout = routines.firstWhere(
          (w) => w.id == widget.workoutId,
          orElse: () => Workout(
            id: '',
            name: 'Não encontrado',
            scheduledDays: [],
            targetDurationMinutes: 0,
            notes: '',
            exercises: [],
          ),
        );

        if (workout.id.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalhes do Treino')),
            body: const Center(child: Text('Treino não encontrado')),
          );
        }

        // Days formatting
        final daysStr = workout.scheduledDays.isEmpty
            ? 'Sem agendamento'
            : workout.scheduledDays
                  .map((d) {
                    const days = [
                      'Dom',
                      'Seg',
                      'Ter',
                      'Qua',
                      'Qui',
                      'Sex',
                      'Sáb',
                    ];
                    if (d == 7) return 'Dom';
                    return days[d];
                  })
                  .join(', ');

        return Scaffold(
          appBar: AppBar(
            title: Text(workout.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  context.push('/workouts/${workout.id}/edit');
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Excluir Treino'),
                      content: const Text(
                        'Tem certeza que deseja excluir esta treino?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Excluir'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await ref
                        .read(workoutRepositoryProvider)
                        .deleteRoutine(workout.id);
                    ref.invalidate(routineListProvider);
                    if (context.mounted) {
                      context.pop();
                    }
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.calendar_today, 'Dias:', daysStr),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.timer,
                        'Duração:',
                        '${workout.targetDurationMinutes} min',
                      ),
                      if (workout.notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.notes, 'Notas:', workout.notes),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Exercícios',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (workout.exercises.isEmpty)
                const Center(child: Text('Nenhum exercício cadastrado.')),
              ...workout.exercises.asMap().entries.map((entry) {
                final index = entry.key;
                final ex = entry.value;
                final isCompleted = _completedExercises.contains(index);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: isCompleted,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _completedExercises.add(index);
                              } else {
                                _completedExercises.remove(index);
                              }
                            });
                          },
                        ),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ex.imagePaths.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(ex.imagePaths.first),
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) =>
                                        const Icon(Icons.broken_image),
                                  ),
                                )
                              : const Icon(Icons.fitness_center),
                        ),
                      ],
                    ),
                    title: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: ex.name,
                            style: TextStyle(
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isCompleted ? Colors.grey : null,
                            ),
                          ),
                          if (ex.equipmentNumber != null)
                            TextSpan(
                              text: ' #${ex.equipmentNumber}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                    subtitle: Text(
                      '${ex.sets} séries x ${ex.reps} reps - ${ex.weight}kg',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () {
                        context.push(
                          '/workouts/${workout.id}/exercises/$index',
                        );
                      },
                    ),
                    onTap: () {
                      context.push('/workouts/${workout.id}/exercises/$index');
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Erro: $err'))),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }
}
