import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shape_log/core/constants/app_colors.dart';
import '../providers/session_provider.dart';
import '../../domain/entities/workout.dart';
import 'package:marquee/marquee.dart';

class WorkoutSessionPage extends ConsumerStatefulWidget {
  final Workout workout;

  const WorkoutSessionPage({super.key, required this.workout});

  @override
  ConsumerState<WorkoutSessionPage> createState() => _WorkoutSessionPageState();
}

class _WorkoutSessionPageState extends ConsumerState<WorkoutSessionPage> {
  late PageController _pageController;
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _weightController = TextEditingController();
    _repsController = TextEditingController();

    // Initialize session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionProvider.notifier).startSession(widget.workout);
      _updateControllers();
    });
  }

  void _updateControllers() {
    final state = ref.read(sessionProvider);
    final exercise = state.currentExercise;
    if (exercise != null) {
      _weightController.text = exercise.weight.toString();
      _repsController.text = exercise.reps.toString();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Sync PageController with State if needed (e.g. if skipped via button)
    ref.listen(sessionProvider, (prev, next) {
      if (prev?.currentExerciseIndex != next.currentExerciseIndex) {
        if (_pageController.hasClients &&
            _pageController.page?.round() != next.currentExerciseIndex) {
          _pageController.animateToPage(
            next.currentExerciseIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        _updateControllers();
      }

      if (!prev!.isRestTimerRunning && next.isRestTimerRunning) {
        _showRestTimerOverlay(context);
      }
    });

    if (sessionState.isSessionComplete) {
      return _buildSummaryScreen();
    }

    final totalExercises = widget.workout.exercises.length;
    final currentStep = sessionState.currentExerciseIndex + 1;
    final progress = totalExercises > 0 ? currentStep / totalExercises : 0.0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      ref.read(sessionProvider.notifier).exitSession();
                      context.pop();
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exercício $currentStep de $totalExercises',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          color: AppColors.primary,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. PageView Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: totalExercises,
                onPageChanged: (index) {
                  ref.read(sessionProvider.notifier).jumpToExercise(index);
                },
                itemBuilder: (context, index) {
                  // We shouldn't necessarily depend on sessionState.currentExercise here because
                  // PageView builds multiple items. We should build based on 'index'.
                  final exercise = widget.workout.exercises[index];
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Image
                        Container(
                          height: 300,
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: exercise.imagePaths.isNotEmpty
                                ? Image.file(
                                    File(exercise.imagePaths.first),
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.broken_image,
                                      color: Colors.white,
                                      size: 50,
                                    ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.fitness_center,
                                      color: Colors.white,
                                      size: 60,
                                    ),
                                  ),
                          ),
                        ),

                        // Title
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            height: 40,
                            child: Marquee(
                              text: exercise.name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                              scrollAxis: Axis.horizontal,
                              blankSpace: 20.0,
                              velocity: 30.0,
                              startPadding: 0.0,
                              accelerationDuration: const Duration(seconds: 1),
                              decelerationDuration: const Duration(
                                milliseconds: 500,
                              ),
                            ),
                          ),
                        ),

                        // History
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            sessionState.lastHistoryMap[exercise.name] != null
                                ? "Última vez: ${sessionState.lastHistoryMap[exercise.name]}"
                                : "Última vez: --",
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Inputs - ONLY show active inputs if this is the current page?
                        // Ideally, we want inputs for *this* exercise.
                        // But controllers are single instances.
                        // To simplify for this "MVP++", we only enable editing if it matches active index,
                        // OR we update controllers when swiping (already done in synchronization).
                        // Note: Using shared controllers on PageView is tricky if user swipes fast.
                        // For now, valid assumption is user focuses on one.
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildInputCard(
                                  context,
                                  label: 'CARGA (Kg)',
                                  controller: _weightController,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildInputCard(
                                  context,
                                  label: 'REPS',
                                  controller: _repsController,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (exercise.technique != null &&
                            exercise.technique!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TÉCNICA',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    exercise.technique!,
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 100), // Spacing for FAB/Button
                      ],
                    ),
                  );
                },
              ),
            ),

            // 3. Bottom Action
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor:
                        Colors.black, // Always white text on primary
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final exercise = sessionState.currentExercise;
                    if (exercise != null) {
                      final restTime = exercise.restTimeSeconds;
                      ref
                          .read(sessionProvider.notifier)
                          .startRestTimer(restTime);
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'CONCLUIR SÉRIE',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Treino Concluído')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
            const SizedBox(height: 24),
            const Text(
              'Parabéns!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text('Você finalizou o treino.'),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              width: 200,
              child: FilledButton(
                onPressed: () {
                  ref.read(sessionProvider.notifier).exitSession();
                  context.pop();
                },
                child: const Text(
                  'Salvar e Sair',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRestTimerOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _RestTimerDialog(),
    ).then((_) {
      ref.read(sessionProvider.notifier).stopRestTimer();
    });
  }
}

class _RestTimerDialog extends ConsumerWidget {
  const _RestTimerDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionProvider);
    final remaining = state.restTimerRemaining;
    final progress = state.restTimerDuration > 0
        ? remaining / state.restTimerDuration
        : 0.0;

    ref.listen(sessionProvider, (prev, next) {
      if (!next.isRestTimerRunning && (prev?.isRestTimerRunning == true)) {
        Navigator.of(context).pop();
      }
    });

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Descanso',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 150,
              width: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor:
                        Colors.grey[200], // Keep generic grey for track
                    color: AppColors.primary,
                  ),
                  Center(
                    child: Text(
                      '$remaining',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    // +30s not implemented, keep placeholder
                  },
                  child: const Text('+30s'),
                ),
                FilledButton(
                  onPressed: () {
                    ref.read(sessionProvider.notifier).stopRestTimer();
                  },
                  child: const Text('Pular'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
