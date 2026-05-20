import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/image_path_resolver.dart';

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
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    ref.invalidate(routineListProvider);
    await ref.read(routineListProvider.future);
    if (mounted) {
      setState(() => _isRefreshing = false);
      SnackbarUtils.showSuccess(context, 'Treino atualizado!');
    }
  }

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

        if (kIsWeb) {
          return _buildWebLayout(context, workout, daysStr, isExpired, now);
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: const Color(0xFF1E1E1E),
            displacement: 60,
            edgeOffset: kToolbarHeight,
            onRefresh: _handleRefresh,
            child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                expandedHeight: 120.0,
                floating: false,
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
                    if (!kIsWeb && workout.activeStartTime == null)
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
                    else if (!kIsWeb)
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
                        child: Material(
                          color: Colors.transparent,
                          clipBehavior: Clip.antiAlias,
                          borderRadius: BorderRadius.circular(20),
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
                                    child: AppCachedImage(
                                      path: ex.imagePaths.first,
                                      fit: BoxFit.cover,
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
                        ),
                      );
                    }),
                  ]),
                ),
              ),
            ],
          ),
          ),
              // Barra de progresso visível no topo durante refresh
              if (_isRefreshing)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 3,
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
    final percentage = totalCount == 0 ? 0.0 : (completedCount / totalCount) * 100;

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

  // ── Layout web SaaS ───────────────────────────────────────────────────────
  Widget _buildWebLayout(
    BuildContext context,
    Workout workout,
    String daysStr,
    bool isExpired,
    DateTime now,
  ) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Top bar
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            color: const Color(0xFF0A0A0A),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white54, size: 20),
                  onPressed: () => context.pop(),
                  tooltip: 'Voltar',
                ),
                const SizedBox(width: 8),
                Text(
                  workout.name,
                  style: GoogleFonts.outfit(
                    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white,
                  ),
                ),
                if (isExpired) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('VENCIDO',
                        style: GoogleFonts.outfit(
                            fontSize: 10, color: AppColors.error,
                            fontWeight: FontWeight.w700, letterSpacing: 1)),
                  ),
                ],
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.push('/workouts/${workout.id}/edit'),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text('Editar', style: GoogleFonts.outfit()),
                  style: TextButton.styleFrom(foregroundColor: Colors.white54),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () async {
                    final confirmed = await AppDialogs.showConfirmDialog<bool>(
                      context: context,
                      title: 'Excluir Treino',
                      description: 'Tem certeza que deseja excluir este treino?',
                      confirmText: 'EXCLUIR',
                      isDestructive: true,
                    );
                    if (confirmed == true) {
                      await ref.read(workoutRepositoryProvider).deleteRoutine(workout.id);
                      ref.invalidate(routineListProvider);
                      if (context.mounted) context.pop();
                    }
                  },
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text('Excluir', style: GoogleFonts.outfit()),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.white.withOpacity(0.06)),
          // Conteúdo em duas colunas
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coluna esquerda — informações do treino
                SizedBox(
                  width: 300,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _WebInfoCard(label: 'Dias', value: daysStr.isEmpty ? 'Sem agendamento' : daysStr),
                        const SizedBox(height: 12),
                        _WebInfoCard(label: 'Duração alvo', value: '${workout.targetDurationMinutes} min'),
                        if (workout.expiryDate != null) ...[
                          const SizedBox(height: 12),
                          _WebInfoCard(
                            label: 'Validade',
                            value: DateFormat('dd/MM/yyyy').format(workout.expiryDate!),
                            valueColor: isExpired ? AppColors.error : null,
                          ),
                        ],
                        if (workout.notes.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _WebInfoCard(label: 'Notas', value: workout.notes),
                        ],
                        const SizedBox(height: 24),
                        Text('${workout.exercises.length} exercício${workout.exercises.length != 1 ? 's' : ''}',
                            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38)),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, color: Colors.white.withOpacity(0.06)),
                // Coluna direita — lista de exercícios
                Expanded(
                  child: workout.exercises.isEmpty
                      ? Center(
                          child: Text('Nenhum exercício.',
                              style: GoogleFonts.outfit(color: Colors.white38)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(24),
                          itemCount: workout.exercises.length,
                          separatorBuilder: (_, i) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final ex = workout.exercises[index];
                            final thumb = ex.imagePaths.isNotEmpty ? ex.imagePaths.first : null;
                            return InkWell(
                              onTap: () => context.push(
                                '/workouts/${workout.id}/exercises/$index'),
                              borderRadius: BorderRadius.circular(12),
                              hoverColor: Colors.white.withOpacity(0.03),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF111111),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.07)),
                                ),
                                child: Row(
                                  children: [
                                    // Thumbnail
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: 48, height: 48,
                                        color: const Color(0xFF1E1E1E),
                                        child: thumb != null
                                            ? AppCachedImage(path: thumb, fit: BoxFit.cover)
                                            : const Icon(Icons.fitness_center, color: AppColors.primary, size: 24),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(ex.name,
                                              style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white, fontSize: 14)),
                                          Text(
                                            ex.type.name == 'cardio'
                                                ? '${ex.cardioDurationMinutes?.toInt() ?? 0} min · ${ex.cardioIntensity ?? ''}'
                                                : '${ex.sets} séries × ${ex.reps} reps · ${ex.weight} kg',
                                            style: GoogleFonts.outfit(
                                                fontSize: 12, color: Colors.white38),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

class _WebInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _WebInfoCard({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? Colors.white)),
        ],
      ),
    );
  }
}
