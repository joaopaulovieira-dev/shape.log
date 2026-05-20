import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_log/core/constants/app_colors.dart';
import '../../features/profile/presentation/providers/user_profile_provider.dart';
import 'package:shape_log/features/dashboard/widgets/dashboard_widgets.dart';
import '../../features/workout/data/services/active_session_service.dart';
import '../../features/workout/presentation/providers/workout_provider.dart';
import '../../features/workout/presentation/providers/session_provider.dart';
import '../../features/workout/domain/entities/workout.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../../features/workout/data/models/workout_history_hive_model.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Workout? _activeWorkout;
  Map<String, dynamic>? _sessionData;
  bool _isLoadingSession = true;

  @override
  void initState() {
    super.initState();
    _checkActiveSession();
  }

  Future<void> _checkActiveSession() async {
    try {
      final service = ref.read(activeSessionServiceProvider);
      final sessionData = await service.restoreSession();

      if (sessionData != null) {
        final workoutId = sessionData['workoutId'] as String;
        final repository = ref.read(workoutRepositoryProvider);
        final routines = await repository.getRoutines();
        // Determine active workout
        final workout = routines.where((w) => w.id == workoutId).firstOrNull;

        if (workout != null && mounted) {
          setState(() {
            _activeWorkout = workout;
            _sessionData = sessionData;
          });
        }
      }
    } catch (e) {
      debugPrint("Error checking active session: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSession = false;
        });
      }
    }
  }

  Future<void> _resumeSession() async {
    if (_activeWorkout != null && _sessionData != null) {
      // Restore state in provider
      await ref
          .read(sessionProvider.notifier)
          .restoreSessionState(_sessionData!);

      if (mounted) {
        context.push('/session', extra: _activeWorkout);
      }
    }
  }

  // --- Logic for Smart Suggestion ---
  Workout? _getSuggestedWorkout(
    List<WorkoutHistoryHiveModel> history,
    List<Workout> allWorkouts,
  ) {
    if (allWorkouts.isEmpty) return null;

    final now = DateTime.now();
    // 1. Check for a workout SCHEDULED for TODAY
    final todayWorkout = allWorkouts
        .where((w) => w.scheduledDays.contains(now.weekday))
        .firstOrNull;

    if (todayWorkout != null) {
      // Check if ALREADY DONE today
      final doneToday = history.any(
        (h) =>
            h.workoutId == todayWorkout.id &&
            h.completedDate.year == now.year &&
            h.completedDate.month == now.month &&
            h.completedDate.day == now.day,
      );

      if (!doneToday) {
        return todayWorkout; // Specific for today and not done!
      }
    }

    // 2. Look for the NEXT scheduled workout (Tomorrow onwards)
    for (int i = 1; i <= 7; i++) {
      final nextDay = now.add(Duration(days: i));
      final nextWeekday = nextDay.weekday;
      final nextWorkout = allWorkouts
          .where((w) => w.scheduledDays.contains(nextWeekday))
          .firstOrNull;

      if (nextWorkout != null) {
        return nextWorkout;
      }
    }

    // 3. Fallback: Rotation based on history
    if (history.isEmpty) return allWorkouts.first;

    // Sort history by date desc
    final sortedHistory = List<WorkoutHistoryHiveModel>.from(history)
      ..sort((a, b) => b.completedDate.compareTo(a.completedDate));

    final lastWorkoutHistory = sortedHistory.first;
    final lastIndex = allWorkouts.indexWhere(
      (w) => w.id == lastWorkoutHistory.workoutId,
    );

    if (lastIndex == -1) return allWorkouts.first;

    final nextIndex = (lastIndex + 1) % allWorkouts.length;
    return allWorkouts[nextIndex];
  }

  @override
  Widget build(BuildContext context) {
    final workoutAsync = ref.watch(routineListProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final userName = userProfileAsync.value?.name.split(' ').first ?? 'Atleta';

    // Limpa o card de retomar quando a sessão é cancelada
    ref.listen(sessionProvider, (prev, next) {
      if (prev?.activeWorkout != null && next.activeWorkout == null) {
        setState(() {
          _activeWorkout = null;
          _sessionData = null;
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.black, // Standard background
      body: _isLoadingSession
          ? const Center(child: CircularProgressIndicator())
          : workoutAsync.when(
              data: (allWorkouts) {
                if (kIsWeb) {
                  final historyAsync = ref.watch(historyListProvider);
                  return historyAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) =>
                        _buildHistoryContent([], allWorkouts, userName),
                    data: (entities) => _buildHistoryContent(
                      entities.map(WorkoutHistoryHiveModel.fromEntity).toList(),
                      allWorkouts,
                      userName,
                    ),
                  );
                }
                return ValueListenableBuilder<Box<WorkoutHistoryHiveModel>>(
                  valueListenable: Hive.box<WorkoutHistoryHiveModel>(
                    'history_log',
                  ).listenable(),
                  builder: (context, box, _) => _buildHistoryContent(
                    box.values.toList(),
                    allWorkouts,
                    userName,
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Erro ao carregar treinos: $err')),
            ),
    );
  }

  Widget _buildHistoryContent(
    List<WorkoutHistoryHiveModel> history,
    List<Workout> allWorkouts,
    String userName,
  ) {
    final sortedHistory = List<WorkoutHistoryHiveModel>.from(history)
      ..sort((a, b) => b.completedDate.compareTo(a.completedDate));

    if (kIsWeb) return _buildWebDashboard(sortedHistory, allWorkouts);

    final lastSession = sortedHistory.isNotEmpty ? sortedHistory.first : null;
    final suggestedWorkout = _getSuggestedWorkout(history, allWorkouts);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120.0,
          floating: true,
          pinned: true,
          backgroundColor: AppColors.background,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            titlePadding: const EdgeInsets.only(bottom: 16),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 22,
                    ),
                    children: [
                      const TextSpan(text: 'Shape'),
                      TextSpan(
                        text: '.log',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $userName 👋',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pronto para superar seus limites hoje?',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 24),
                if (!kIsWeb && _activeWorkout != null) ...[
                  _buildResumeCard(),
                  const SizedBox(height: 24),
                ],
                WeeklyConsistencyStrip(history: history),
                const SizedBox(height: 24),
                if (!kIsWeb && _activeWorkout == null)
                  SmartActionCard(
                    suggestedWorkout: suggestedWorkout,
                    onStart: () {
                      if (suggestedWorkout != null) {
                        context.push('/session', extra: suggestedWorkout);
                      } else {
                        context.go('/workouts');
                      }
                    },
                  ),
                if (!kIsWeb && _activeWorkout == null)
                  const SizedBox(height: 24),
                if (lastSession != null) ...[
                  LastSessionRecap(lastSession: lastSession),
                  const SizedBox(height: 24),
                ],
                WeeklyPerformanceCard(history: history),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebDashboard(
    List<WorkoutHistoryHiveModel> history,
    List<Workout> allWorkouts,
  ) {
    final now = DateTime.now();

    // ── Métricas calculadas ─────────────────────────────────────────
    final thisMonthSessions = history
        .where(
          (h) =>
              h.completedDate.month == now.month &&
              h.completedDate.year == now.year,
        )
        .toList();

    final avgDuration = history.isEmpty
        ? 0
        : (history.fold(0, (s, h) => s + h.durationMinutes) / history.length)
              .round();

    final avgCompletion = history.isEmpty
        ? 0.0
        : history.fold(0.0, (s, h) => s + h.completionPercentage) /
              history.length;

    // Streak: semanas consecutivas com pelo menos 1 treino
    int streak = 0;
    for (int w = 0; w < 52; w++) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + w * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final had = history.any(
        (h) =>
            !h.completedDate.isBefore(weekStart) &&
            !h.completedDate.isAfter(weekEnd),
      );
      if (!had) break;
      streak++;
    }

    // Frequência por semana (últimas 8 semanas)
    final weekCounts = List.generate(8, (i) {
      final start = now.subtract(Duration(days: now.weekday - 1 + (7 - i) * 7));
      final end = start.add(const Duration(days: 6));
      return history
          .where(
            (h) =>
                !h.completedDate.isBefore(start) &&
                !h.completedDate.isAfter(end),
          )
          .length;
    });

    // Distribuição por dia da semana (Seg=1..Dom=7)
    final dayDist = List.generate(7, (i) {
      final day = i + 1;
      return history.where((h) => h.completedDate.weekday == day).length;
    });

    final todayScheduled = allWorkouts
        .where((w) => w.scheduledDays.contains(now.weekday))
        .toList();

    // ── UI ──────────────────────────────────────────────────────────
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_weekdayLabel(now.weekday)}, ${now.day} de ${_monthLabel(now.month)} · Visão geral do seu progresso',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => context.go('/workouts'),
                icon: const Icon(Icons.fitness_center, size: 16),
                label: Text(
                  'Ver Treinos',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── KPI Cards ─────────────────────────────────────────────
          Row(
            children: [
              _KpiCard(
                label: 'Treinos este mês',
                value: '${thisMonthSessions.length}',
                sub: history.isEmpty
                    ? 'Sem histórico'
                    : 'de ${history.length} no total',
                icon: Icons.fitness_center_rounded,
                color: AppColors.primary,
                trend: _trendLabel(history, now),
              ),
              const SizedBox(width: 16),
              _KpiCard(
                label: 'Duração média',
                value: avgDuration == 0 ? '—' : '${avgDuration}min',
                sub: 'por sessão',
                icon: Icons.timer_outlined,
                color: Colors.blueAccent,
              ),
              const SizedBox(width: 16),
              _KpiCard(
                label: 'Taxa de conclusão',
                value: history.isEmpty
                    ? '—'
                    : '${avgCompletion.toStringAsFixed(0)}%',
                sub: 'média por sessão',
                icon: Icons.check_circle_outline,
                color: Colors.tealAccent,
              ),
              const SizedBox(width: 16),
              _KpiCard(
                label: 'Streak atual',
                value: streak == 0 ? '—' : '${streak}sem',
                sub: streak == 0
                    ? 'Comece esta semana!'
                    : streak == 1
                    ? 'semana consecutiva'
                    : 'semanas consecutivas',
                icon: Icons.local_fire_department_rounded,
                color: Colors.orangeAccent,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Gráfico de frequência + Atividade recente ─────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gráfico de barras — frequência semanal
              Expanded(
                flex: 6,
                child: _DashCard(
                  title: 'Frequência Semanal',
                  subtitle: 'Últimas 8 semanas',
                  child: SizedBox(
                    height: 180,
                    child: history.isEmpty
                        ? _emptyChart()
                        : _WeeklyBarChart(data: weekCounts),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Atividade recente
              Expanded(
                flex: 4,
                child: _DashCard(
                  title: 'Atividade Recente',
                  subtitle: 'Últimas sessões',
                  child: history.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Nenhuma sessão registrada.',
                            style: GoogleFonts.outfit(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : Column(
                          children: history.take(5).map((h) {
                            final d = h.completedDate;
                            final dateStr =
                                '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
                            final pct = h.completionPercentage;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: pct >= 80
                                          ? AppColors.primary
                                          : pct >= 50
                                          ? Colors.orangeAccent
                                          : Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      h.workoutName,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    dateStr,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: Colors.white38,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${h.durationMinutes}m',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: Colors.white38,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Distribuição por dia da semana + Rotinas ──────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heatmap dias da semana
              Expanded(
                flex: 4,
                child: _DashCard(
                  title: 'Preferência por Dia',
                  subtitle: 'Baseado no histórico',
                  child: history.isEmpty
                      ? _emptyChart()
                      : _DayDistributionChart(data: dayDist),
                ),
              ),
              const SizedBox(width: 20),
              // Rotinas de hoje / próximas
              Expanded(
                flex: 6,
                child: _DashCard(
                  title: todayScheduled.isEmpty
                      ? 'Rotinas Cadastradas'
                      : 'Treinos de Hoje',
                  subtitle: todayScheduled.isEmpty
                      ? '${allWorkouts.length} rotina${allWorkouts.length != 1 ? 's' : ''}'
                      : '${todayScheduled.length} agendado${todayScheduled.length != 1 ? 's' : ''}',
                  action: allWorkouts.isEmpty
                      ? null
                      : TextButton(
                          onPressed: () => context.go('/workouts'),
                          child: Text(
                            'Ver todos',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                  child: allWorkouts.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Nenhuma rotina cadastrada.',
                            style: GoogleFonts.outfit(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : Column(
                          children:
                              (todayScheduled.isNotEmpty
                                      ? todayScheduled
                                      : allWorkouts)
                                  .take(4)
                                  .map((w) {
                                    final days = const [
                                      '',
                                      'Seg',
                                      'Ter',
                                      'Qua',
                                      'Qui',
                                      'Sex',
                                      'Sáb',
                                      'Dom',
                                    ];
                                    final dayStr = w.scheduledDays
                                        .map((d) => days[d.clamp(1, 7)])
                                        .join(' · ');
                                    return InkWell(
                                      onTap: () =>
                                          context.go('/workouts/${w.id}'),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.fitness_center,
                                                color: AppColors.primary,
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    w.name,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  if (dayStr.isNotEmpty)
                                                    Text(
                                                      dayStr,
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 11,
                                                        color: Colors.white38,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '${w.exercises.length} ex',
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                color: Colors.white38,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.chevron_right,
                                              color: Colors.white24,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyChart() => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: Text(
        'Sem dados suficientes',
        style: GoogleFonts.outfit(color: Colors.white24, fontSize: 13),
      ),
    ),
  );

  String _weekdayLabel(int wd) {
    const l = [
      '',
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo',
    ];
    return l[wd.clamp(1, 7)];
  }

  String _monthLabel(int m) {
    const l = [
      '',
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];
    return l[m.clamp(1, 12)];
  }

  String _trendLabel(List<WorkoutHistoryHiveModel> history, DateTime now) {
    final prev = history
        .where(
          (h) =>
              h.completedDate.month == (now.month == 1 ? 12 : now.month - 1) &&
              h.completedDate.year ==
                  (now.month == 1 ? now.year - 1 : now.year),
        )
        .length;
    final curr = history
        .where(
          (h) =>
              h.completedDate.month == now.month &&
              h.completedDate.year == now.year,
        )
        .length;
    if (prev == 0) return 'primeiro mês';
    final diff = curr - prev;
    if (diff > 0) return '+$diff em relação ao mês anterior';
    if (diff < 0) return '$diff em relação ao mês anterior';
    return 'igual ao mês anterior';
  }

  Widget _buildResumeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.2),
            AppColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                "TREINO EM ANDAMENTO",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _activeWorkout?.name ?? "Treino sem nome",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Continuar de onde parou?",
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _resumeSession,
              icon: const Icon(Icons.play_arrow, color: Colors.black),
              label: const Text(
                "RETOMAR TREINO",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dashboard SaaS widgets ────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;
  final String? trend;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const Spacer(),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      trend!,
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        color: Colors.white38,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            Text(
              sub,
              style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  const _DashCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ?action,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── Gráfico de barras semanal ─────────────────────────────────────────────────

class _WeeklyBarChart extends StatelessWidget {
  final List<int> data; // 8 semanas, mais antiga primeiro

  const _WeeklyBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b);
    final labels = List.generate(8, (i) {
      final weeksAgo = 7 - i;
      if (weeksAgo == 0) return 'Esta\nsem.';
      if (weeksAgo == 1) return 'Sem\npassada';
      return '-${weeksAgo}s';
    });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(8, (i) {
        final val = data[i];
        final frac = maxVal == 0 ? 0.0 : val / maxVal;
        final isLast = i == 7;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (val > 0)
                  Text(
                    '$val',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: isLast ? AppColors.primary : Colors.white38,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  height: frac == 0 ? 4 : (130 * frac).clamp(8, 130),
                  decoration: BoxDecoration(
                    color: isLast
                        ? AppColors.primary
                        : val == 0
                        ? Colors.white.withOpacity(0.06)
                        : AppColors.primary.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    color: isLast ? Colors.white60 : Colors.white24,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── Gráfico de distribuição por dia da semana ─────────────────────────────────

class _DayDistributionChart extends StatelessWidget {
  final List<int> data; // [Seg, Ter, Qua, Qui, Sex, Sáb, Dom]

  const _DayDistributionChart({required this.data});

  @override
  Widget build(BuildContext context) {
    const labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final maxVal = data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b);
    final total = data.fold(0, (s, v) => s + v);
    final today = DateTime.now().weekday - 1; // 0=Seg..6=Dom

    return Column(
      children: List.generate(7, (i) {
        final val = data[i];
        final frac = maxVal == 0 ? 0.0 : val / maxVal;
        final pct = total == 0 ? 0 : ((val / total) * 100).round();
        final isToday = i == today;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  labels[i],
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: isToday ? AppColors.primary : Colors.white38,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: frac.clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 32,
                child: Text(
                  pct == 0 ? '' : '$pct%',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: Colors.white38,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
