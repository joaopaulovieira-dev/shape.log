import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:marquee/marquee.dart';

import '../../domain/entities/workout.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout_history.dart';
import '../providers/workout_provider.dart';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../domain/services/workout_report_service.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';

import 'package:shape_log/core/constants/app_colors.dart';

class WorkoutDetailsPage extends ConsumerStatefulWidget {
  final String workoutId;

  const WorkoutDetailsPage({super.key, required this.workoutId});

  @override
  ConsumerState<WorkoutDetailsPage> createState() => _WorkoutDetailsPageState();
}

class _WorkoutDetailsPageState extends ConsumerState<WorkoutDetailsPage> {
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

        final now = DateTime.now();
        final isExpired =
            workout.expiryDate != null && workout.expiryDate!.isBefore(now);

        return Scaffold(
          appBar: AppBar(
            title: SizedBox(
              height: 50,
              child: Marquee(
                text: workout.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                scrollAxis: Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.center,
                blankSpace: 20.0,
                velocity: 30.0,
                pauseAfterRound: const Duration(seconds: 1),
                startPadding: 10.0,
                accelerationDuration: const Duration(seconds: 1),
                accelerationCurve: Curves.linear,
                decelerationDuration: const Duration(milliseconds: 500),
                decelerationCurve: Curves.easeOut,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'Histórico de Execuções',
                onPressed: () => _showWorkoutHistory(context, workout.id),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    context.push('/workouts/${workout.id}/edit');
                  } else if (value == 'delete') {
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
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Editar'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text(
                        'Excluir',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (isExpired)
                Card(
                  color: AppColors.error.withValues(alpha: 0.1),
                  margin: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: AppColors.error),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning, color: AppColors.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Este treino venceu em ${DateFormat('dd/MM/yyyy').format(workout.expiryDate!)}.',
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Por favor, notifique o agente de IA para gerar um novo treino.',
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.copy),
                            label: const Text(
                              'Copiar Mensagem',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              final dateStr = DateFormat(
                                'dd/MM/yyyy',
                              ).format(workout.expiryDate!);
                              final message =
                                  "Olá! Meu treino '${workout.name}' venceu em $dateStr. Por favor, me ajude a criar uma nova versão dele baseada no meu progresso recente.";
                              Clipboard.setData(ClipboardData(text: message));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Mensagem copiada!'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Card(
                margin: const EdgeInsets.fromLTRB(4, 4, 4, 12),
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
                      if (workout.expiryDate != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.event,
                          'Vencimento:',
                          DateFormat('dd/MM/yyyy').format(workout.expiryDate!),
                        ),
                      ],
                      if (workout.notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.notes, 'Notas:', workout.notes),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (workout.activeStartTime == null)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      context.push('/session', extra: workout);
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      'Iniciar Treino',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () => _finalizeWorkout(workout),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Finalizar Treino'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final completedCount = workout.exercises
                            .where((e) => e.isCompleted)
                            .length;
                        final totalCount = workout.exercises.length;
                        final percent = totalCount == 0
                            ? 0.0
                            : (completedCount / totalCount);
                        return Column(
                          children: [
                            LinearProgressIndicator(
                              value: percent,
                              backgroundColor: AppColors.surface,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Conclusão: ${(percent * 100).toInt()}% ($completedCount/$totalCount)',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
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

                return Card(
                  margin: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
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
                    title: Text.rich(
                      TextSpan(
                        children: [
                          if (ex.equipmentNumber != null &&
                              ex.equipmentNumber!.isNotEmpty)
                            TextSpan(
                              text: '#${ex.equipmentNumber} ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          TextSpan(
                            text: ex.name,
                            style: TextStyle(
                              decoration: ex.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: ex.isCompleted
                                  ? Colors.grey
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    subtitle: Text(
                      '${ex.sets} séries x ${ex.reps} reps - ${ex.weight}kg',
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

  Future<void> _finalizeWorkout(Workout workout) async {
    final now = DateTime.now();
    final startTime = workout.activeStartTime ?? now;
    final duration = now.difference(startTime).inMinutes;

    final completedCount = workout.exercises.where((e) => e.isCompleted).length;
    final totalCount = workout.exercises.length;
    final percentage = totalCount == 0 ? 0.0 : (completedCount / totalCount);

    final history = WorkoutHistory(
      id: const Uuid().v4(),
      workoutId: workout.id,
      workoutName: workout.name,
      completedDate: now,
      durationMinutes: duration,
      exercises: List.from(workout.exercises),
      notes: workout.notes,
      startTime: startTime,
      completionPercentage: percentage,
    );

    // Save to history
    await ref.read(workoutRepositoryProvider).saveHistory(history);

    // Reset exercises in routine and clear activeStartTime
    final resetExercises = workout.exercises
        .map(
          (ex) => Exercise(
            name: ex.name,
            sets: ex.sets,
            reps: ex.reps,
            weight: ex.weight,
            youtubeUrl: ex.youtubeUrl,
            imagePaths: ex.imagePaths,
            equipmentNumber: ex.equipmentNumber,
            isCompleted: false,
          ),
        )
        .toList();

    final updatedWorkout = Workout(
      id: workout.id,
      name: workout.name,
      scheduledDays: workout.scheduledDays,
      targetDurationMinutes: workout.targetDurationMinutes,
      notes: workout.notes,
      exercises: resetExercises,
      activeStartTime: null,
    );

    await ref.read(workoutRepositoryProvider).saveRoutine(updatedWorkout);
    ref.invalidate(routineListProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Treino finalizado e salvo!')),
      );
    }
  }

  void _showWorkoutHistory(BuildContext context, String workoutId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Consumer(
            builder: (context, ref, child) {
              final historyAsync = ref.watch(historyListProvider);

              return historyAsync.when(
                data: (allHistory) {
                  final history = allHistory
                      .where((h) => h.workoutId == workoutId)
                      .toList();

                  // Sort by date descending
                  history.sort(
                    (a, b) => b.completedDate.compareTo(a.completedDate),
                  );

                  if (history.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhum histórico encontrado para este treino.',
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Histórico de Execuções',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: history.length,
                          separatorBuilder: (ctx, index) => const Divider(),
                          itemBuilder: (ctx, index) {
                            final h = history[index];
                            final dateStr = DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(h.completedDate);

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(
                                  0.2,
                                ),
                                child: Text(
                                  _getRpeEmoji(h.rpe),
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              title: Text(
                                dateStr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Duração: ${h.durationMinutes} min • RPE: ${h.rpe ?? "?"}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.copy_all,
                                  color: AppColors.primary,
                                ),
                                tooltip: 'Copiar Relatório para IA',
                                onPressed: () async {
                                  final user = await ref.read(
                                    userProfileProvider.future,
                                  );
                                  final report = WorkoutReportService()
                                      .generateClipboardReport(h, user);
                                  await Clipboard.setData(
                                    ClipboardData(text: report),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Relatório copiado! Cole no ChatGPT.',
                                        ),
                                        backgroundColor:
                                            AppColors.surface, // Dark Grey
                                        action: SnackBarAction(
                                          label: 'OK',
                                          textColor: AppColors.primary,
                                          onPressed: () {},
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              onTap: () {
                                // Could show detailed view here if needed
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Erro: $err')),
              );
            },
          );
        },
      ),
    );
  }

  String _getRpeEmoji(int? rpe) {
    switch (rpe) {
      case 1:
        return '😁';
      case 2:
        return '🙂';
      case 3:
        return '😐';
      case 4:
        return '😫';
      case 5:
        return '🥵';
      default:
        return '🏋️';
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }
}
