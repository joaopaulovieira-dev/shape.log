import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/workout.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout_history.dart';
import '../providers/workout_provider.dart';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../domain/services/workout_report_service.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';

import 'package:shape_log/core/constants/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/presentation/widgets/app_dialogs.dart';
import '../../../../core/presentation/widgets/app_modals.dart';

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
          backgroundColor: Colors.black,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120.0,
                floating: true,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(bottom: 16),
                  title: Text(
                    'Treino',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.white),
                    tooltip: 'Histórico de Execuções',
                    onPressed: () => _showWorkoutHistory(context, workout.id),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        context.push('/workouts/${workout.id}/edit');
                      } else if (value == 'delete') {
                        final confirmed = await AppDialogs.showConfirmDialog(
                          context: context,
                          title: 'Excluir Treino',
                          description:
                              'Tem certeza que deseja excluir esta treino?',
                          confirmText: 'EXCLUIR',
                          isDestructive: true,
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
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
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
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
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
                                  const Icon(
                                    Icons.warning,
                                    color: AppColors.error,
                                  ),
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
                                    Clipboard.setData(
                                      ClipboardData(text: message),
                                    );
                                    SnackbarUtils.showInfo(
                                      context,
                                      'Mensagem copiada!',
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workout.name,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 2,
                            width: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildInfoRow(
                            Icons.calendar_today_outlined,
                            'Dias:',
                            daysStr,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.timer_outlined,
                            'Duração:',
                            '${workout.targetDurationMinutes} min',
                          ),
                          if (workout.expiryDate != null) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.event_available_outlined,
                              'Vencimento:',
                              DateFormat(
                                'dd/MM/yyyy',
                              ).format(workout.expiryDate!),
                            ),
                          ],
                          if (workout.notes.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.description_outlined,
                              'Notas:',
                              workout.notes,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (workout.activeStartTime == null)
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () async {
                            final result = await context.push<bool>(
                              '/session',
                              extra: workout,
                            );
                            if (result == true) {
                              ref.invalidate(routineListProvider);
                              ref.invalidate(historyListProvider);
                              if (context.mounted) {
                                setState(() {});
                              }
                            }
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 28),
                          label: Text(
                            'INICIAR TREINO',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
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
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppColors.primary,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Conclusão: ${(percent * 100).toInt()}% ($completedCount/$totalCount)',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    Text(
                      'Exercícios',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (workout.exercises.isEmpty)
                      const Center(child: Text('Nenhum exercício cadastrado.')),
                    ...workout.exercises.asMap().entries.map((entry) {
                      final index = entry.key;
                      final ex = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ex.imagePaths.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(ex.imagePaths.first),
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) =>
                                          const Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                          ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.fitness_center,
                                    color: AppColors.primary,
                                  ),
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
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    decoration: ex.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: ex.isCompleted
                                        ? Colors.grey
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              ex.type == ExerciseTypeEntity.cardio
                                  ? '${ex.cardioDurationMinutes?.toInt() ?? 0} min • ${ex.cardioIntensity ?? "Normal"} • ${ex.restTimeSeconds}s desc'
                                  : '${ex.sets} séries x ${ex.reps} reps • ${ex.weight}kg',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.white24,
                          ),
                          onTap: () {
                            context.push(
                              '/workouts/${workout.id}/exercises/$index',
                            );
                          },
                        ),
                      );
                    }),
                  ]),
                ),
              ),
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
    ref.invalidate(historyListProvider);

    if (mounted) {
      SnackbarUtils.showSuccess(context, 'Treino finalizado e salvo!');
    }
  }

  void _showWorkoutHistory(BuildContext context, String workoutId) {
    AppModals.showAppModal(
      context: context,
      title: 'Histórico de Execuções',
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Consumer(
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
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: history.length,
                  separatorBuilder: (ctx, index) =>
                      Divider(color: Colors.grey[800]),
                  itemBuilder: (ctx, index) {
                    final h = history[index];
                    final dateStr = DateFormat(
                      'dd/MM/yyyy HH:mm',
                    ).format(h.completedDate);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Text(
                          _getRpeEmoji(h.rpe),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      title: Text(
                        dateStr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        'Duração: ${h.durationMinutes} min • RPE: ${h.rpe ?? "?"}',
                        style: TextStyle(color: Colors.grey[400]),
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
                          await Clipboard.setData(ClipboardData(text: report));
                          if (context.mounted) {
                            SnackbarUtils.showInfo(
                              context,
                              'Relatório copiado! Cole no ChatGPT.',
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  'Erro: $err',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          },
        ),
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
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
