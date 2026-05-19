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
                      entities
                          .map(WorkoutHistoryHiveModel.fromEntity)
                          .toList(),
                      allWorkouts,
                      userName,
                    ),
                  );
                }
                return ValueListenableBuilder<Box<WorkoutHistoryHiveModel>>(
                  valueListenable: Hive.box<WorkoutHistoryHiveModel>(
                    'history_log',
                  ).listenable(),
                  builder: (context, box, _) =>
                      _buildHistoryContent(box.values.toList(), allWorkouts, userName),
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
    final thisMonthCount = history
        .where((h) =>
            h.completedDate.month == now.month &&
            h.completedDate.year == now.year)
        .length;
    final lastSession = history.isNotEmpty ? history.first : null;
    final daysSinceLast = lastSession == null
        ? null
        : now.difference(lastSession.completedDate).inDays;

    final todayWorkouts = allWorkouts
        .where((w) => w.scheduledDays.contains(now.weekday))
        .toList();
    final weekWorkouts = allWorkouts.where((w) => w.scheduledDays.isNotEmpty).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat cards row
          Row(
            children: [
              _WebStatCard(
                icon: Icons.fitness_center,
                label: 'Treinos este mês',
                value: '$thisMonthCount',
                color: AppColors.primary,
              ),
              const SizedBox(width: 16),
              _WebStatCard(
                icon: Icons.history,
                label: 'Último treino',
                value: daysSinceLast == null
                    ? '—'
                    : daysSinceLast == 0
                        ? 'Hoje'
                        : '${daysSinceLast}d atrás',
                color: Colors.blueAccent,
              ),
              const SizedBox(width: 16),
              _WebStatCard(
                icon: Icons.calendar_today,
                label: 'Total de treinos',
                value: '${history.length}',
                color: Colors.purpleAccent,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Treinos de hoje
          if (todayWorkouts.isNotEmpty) ...[
            Text(
              'TREINOS DE HOJE',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white38,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...todayWorkouts.map((w) => _WebWorkoutRow(workout: w)),
            const SizedBox(height: 32),
          ],

          // Todos os treinos
          Text(
            'ROTINAS CADASTRADAS',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white38,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          if (weekWorkouts.isEmpty)
            Center(
              child: Text(
                'Nenhum treino cadastrado ainda.',
                style: GoogleFonts.outfit(color: Colors.white38),
              ),
            )
          else
            ...weekWorkouts.map((w) => _WebWorkoutRow(workout: w)),

          const SizedBox(height: 32),

          // Últimas sessões
          if (history.isNotEmpty) ...[
            Text(
              'ÚLTIMAS SESSÕES',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white38,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...history.take(5).map((h) => _WebHistoryRow(history: h)),
          ],
        ],
      ),
    );
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

// ── Web-only dashboard widgets ───────────────────────────────────────────────

class _WebStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _WebStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WebWorkoutRow extends StatelessWidget {
  final dynamic workout;
  const _WebWorkoutRow({required this.workout});

  @override
  Widget build(BuildContext context) {
    final days = ['', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final dayStr = (workout.scheduledDays as List)
        .map((d) => d < days.length ? days[d] : '')
        .join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.fitness_center, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.name as String,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                if (dayStr.isNotEmpty)
                  Text(
                    dayStr,
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38),
                  ),
              ],
            ),
          ),
          Text(
            '${(workout.exercises as List).length} exercícios',
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

class _WebHistoryRow extends StatelessWidget {
  final dynamic history;
  const _WebHistoryRow({required this.history});

  @override
  Widget build(BuildContext context) {
    final date = history.completedDate as DateTime;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              history.workoutName as String,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            dateStr,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38),
          ),
          const SizedBox(width: 16),
          Text(
            '${history.durationMinutes} min',
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
