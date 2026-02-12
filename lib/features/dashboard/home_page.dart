import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_log/core/constants/app_colors.dart';
import '../../features/profile/presentation/providers/user_profile_provider.dart';
import 'package:shape_log/features/dashboard/widgets/dashboard_widgets.dart'; // Import Widgets
import '../../features/workout/data/services/active_session_service.dart';
import '../../features/workout/presentation/providers/workout_provider.dart';
import '../../features/workout/presentation/providers/session_provider.dart';
import '../../features/workout/domain/entities/workout.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
                return ValueListenableBuilder<Box<WorkoutHistoryHiveModel>>(
                  valueListenable: Hive.box<WorkoutHistoryHiveModel>(
                    'history_log',
                  ).listenable(),
                  builder: (context, box, _) {
                    final history = box.values.toList();

                    // Sort history for usage
                    final sortedHistory =
                        List<WorkoutHistoryHiveModel>.from(history)..sort(
                          (a, b) => b.completedDate.compareTo(a.completedDate),
                        );

                    final lastSession = sortedHistory.isNotEmpty
                        ? sortedHistory.first
                        : null;
                    final suggestedWorkout = _getSuggestedWorkout(
                      history,
                      allWorkouts,
                    );

                    return CustomScrollView(
                      slivers: [
                        // 1. Standardized App Bar
                        SliverAppBar(
                          expandedHeight: 120.0,
                          floating: true,
                          pinned: true,
                          backgroundColor: AppColors.background,
                          flexibleSpace: FlexibleSpaceBar(
                            centerTitle: true,
                            titlePadding: const EdgeInsets.only(bottom: 16),
                            title: Text(
                              'Shape.log',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            background: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.1),
                                    AppColors.background,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                          actions: [
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_none,
                                color: Colors.white,
                              ),
                              onPressed: () {}, // Future notification feature
                            ),
                          ],
                        ),

                        // 2. Content
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Welcome Section
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
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // 1. Resume Active Session (Priority)
                                if (_activeWorkout != null) ...[
                                  _buildResumeCard(),
                                  const SizedBox(height: 24),
                                ],

                                // 2. Weekly Streak Strip
                                WeeklyConsistencyStrip(history: history),
                                const SizedBox(height: 24),

                                // 3. Smart Action Card (Suggestion)
                                if (_activeWorkout ==
                                    null) // Only show if no active session
                                  SmartActionCard(
                                    suggestedWorkout: suggestedWorkout,
                                    onStart: () {
                                      if (suggestedWorkout != null) {
                                        context.push(
                                          '/session',
                                          extra: suggestedWorkout,
                                        );
                                      } else {
                                        // Fallback or go to workouts creation
                                        context.go('/workouts');
                                      }
                                    },
                                  ),

                                if (_activeWorkout == null)
                                  const SizedBox(height: 24),

                                // 4. Last Session Recap
                                if (lastSession != null) ...[
                                  LastSessionRecap(lastSession: lastSession),
                                  const SizedBox(height: 24),
                                ],

                                // 5. Weekly Performance Card
                                WeeklyPerformanceCard(history: history),

                                const SizedBox(height: 40), // Bottom padding
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Erro ao carregar treinos: $err')),
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
