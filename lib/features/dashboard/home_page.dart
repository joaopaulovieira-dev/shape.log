import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shape_log/core/constants/app_colors.dart';
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
    if (history.isEmpty)
      return allWorkouts.first; // Start with first if no history

    // Sort history by date desc
    final sortedHistory = List<WorkoutHistoryHiveModel>.from(history)
      ..sort((a, b) => b.completedDate.compareTo(a.completedDate));

    final lastWorkoutHistory = sortedHistory.first;

    // Find index of last workout in the current list of routines
    // We match by ID or Name (ID is safer)
    final lastIndex = allWorkouts.indexWhere(
      (w) => w.id == lastWorkoutHistory.workoutId,
    );

    if (lastIndex == -1) {
      // Last workout not found (maybe deleted), default to first
      return allWorkouts.first;
    }

    // Cycle: (Index + 1) % length
    final nextIndex = (lastIndex + 1) % allWorkouts.length;
    return allWorkouts[nextIndex];
  }

  @override
  Widget build(BuildContext context) {
    final workoutAsync = ref.watch(routineListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/logo.png', height: 28),
            const SizedBox(width: 12),
            const Text('Shape.log'),
          ],
        ),
      ),
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

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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

                          // 5. Quick Menu Grid
                          // 5. Weekly Performance Card
                          WeeklyPerformanceCard(history: history),

                          const SizedBox(height: 40), // Bottom padding
                        ],
                      ),
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
