import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shape_log/core/constants/app_colors.dart';
import '../providers/session_provider.dart';
import '../../domain/entities/workout.dart';
import 'package:marquee/marquee.dart';
import 'package:confetti/confetti.dart';

class WorkoutSessionPage extends ConsumerStatefulWidget {
  final Workout workout;

  const WorkoutSessionPage({super.key, required this.workout});

  @override
  ConsumerState<WorkoutSessionPage> createState() => _WorkoutSessionPageState();
}

class _WorkoutSessionPageState extends ConsumerState<WorkoutSessionPage> {
  late PageController _pageController;
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _restController;
  late TextEditingController _equipmentController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _setsController = TextEditingController();
    _repsController = TextEditingController();
    _weightController = TextEditingController();
    _restController = TextEditingController();
    _equipmentController = TextEditingController();

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
      // Use existing text if focused to prevent cursor jumping?
      // For now, simple overwrite. If we type, local state updates.
      // But if we navigate back and forth, we need overwrite.
      if (_setsController.text != exercise.sets.toString()) {
        _setsController.text = exercise.sets.toString();
      }
      if (_repsController.text != exercise.reps.toString()) {
        _repsController.text = exercise.reps.toString();
      }
      if (_weightController.text != exercise.weight.toString()) {
        _weightController.text = exercise.weight.toString();
      }
      if (_restController.text != exercise.restTimeSeconds.toString()) {
        _restController.text = exercise.restTimeSeconds.toString();
      }
      if (_equipmentController.text != (exercise.equipmentNumber ?? '')) {
        _equipmentController.text = exercise.equipmentNumber ?? '';
      }
    }
  }

  void _saveChanges() {
    final state = ref.read(sessionProvider);
    final exercise = state.currentExercise;
    if (exercise == null) return;

    final updatedExercise = exercise.copyWith(
      sets: int.tryParse(_setsController.text) ?? exercise.sets,
      reps: int.tryParse(_repsController.text) ?? exercise.reps,
      weight: double.tryParse(_weightController.text) ?? exercise.weight,
      restTimeSeconds:
          int.tryParse(_restController.text) ?? exercise.restTimeSeconds,
      equipmentNumber: _equipmentController.text,
    );

    ref.read(sessionProvider.notifier).updateCurrentExercise(updatedExercise);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _restController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  void _tryFinishWorkout() {
    final state = ref.read(sessionProvider);
    final total = widget.workout.exercises.length;
    final completed = state.completedExerciseNames.length;

    if (completed < total) {
      // Show warning
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Treino Incompleto'),
          content: Text(
            'Você completou $completed de $total exercícios. Deseja finalizar mesmo assim?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showFeedbackDialog();
              },
              child: const Text('Finalizar'),
            ),
          ],
        ),
      );
    } else {
      _showFeedbackDialog();
    }
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _FeedbackDialog(
        onSave: (rpe) {
          ref.read(sessionProvider.notifier).finishSessionWithRpe(rpe);
          // Navigate out after save
          context.pop(); // Close dialog
          context.pop(); // Exit page
        },
      ),
    );
  }

  void _showHistoryDialog(String exerciseName) async {
    final history = await ref
        .read(sessionProvider.notifier)
        .getExerciseHistory(exerciseName);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  'Histórico: $exerciseName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: history.isEmpty
                      ? const Center(
                          child: Text('Nenhum histórico encontrado.'),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: history.length,
                          itemBuilder: (ctx, index) {
                            final h = history[index];
                            final exercise = h.exercises.firstWhere(
                              (e) => e.name == exerciseName,
                              orElse: () => h.exercises.first,
                            );

                            // Improve date formatting
                            final dateStr =
                                "${h.completedDate.day.toString().padLeft(2, '0')}/${h.completedDate.month.toString().padLeft(2, '0')}/${h.completedDate.year}";

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(
                                  0.2,
                                ),
                                child: const Icon(
                                  Icons.history,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                dateStr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                "${exercise.sets} séries x ${exercise.reps} reps",
                              ),
                              trailing: Text(
                                "${exercise.weight} Kg",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Sync PageController with State if needed
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

      // Initialize controllers when session starts (fixes empty fields bug)
      if (prev?.activeWorkout == null && next.activeWorkout != null) {
        _updateControllers();
      }

      if (!prev!.isRestTimerRunning && next.isRestTimerRunning) {
        _showRestTimerOverlay(context);
      }

      // Show completion feedback when requested
      if (!prev.showCompletionFeedback && next.showCompletionFeedback) {
        _showFeedbackDialog();
      }
    });

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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Exercício $currentStep de $totalExercises',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          color: AppColors.primary,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: _GlobalTimerWidget(
                            startTime: sessionState.sessionStartTime,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flag, color: AppColors.primary),
                    tooltip: 'Finalizar Treino',
                    onPressed: _tryFinishWorkout,
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
                  final exercise = widget.workout.exercises[index];
                  final isCompleted = sessionState.completedExerciseNames
                      .contains(exercise.name);

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
                            border: isCompleted
                                ? Border.all(color: AppColors.primary, width: 3)
                                : null,
                            boxShadow: isCompleted
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: ColorFiltered(
                                    colorFilter: isCompleted
                                        ? ColorFilter.mode(
                                            Colors.black.withOpacity(0.3),
                                            BlendMode.darken,
                                          )
                                        : const ColorFilter.mode(
                                            Colors.transparent,
                                            BlendMode.multiply,
                                          ),
                                    child: exercise.imagePaths.isNotEmpty
                                        ? Image.file(
                                            File(exercise.imagePaths.first),
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
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
                              ),
                              if (isCompleted)
                                Positioned.fill(
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.9,
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.black,
                                            size: 28,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            "CONCLUÍDO",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
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

                        const SizedBox(height: 16),

                        const SizedBox(height: 8), // Reduced spacing
                        // GENIUS GRID LAYOUT (Compact 2-Row)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              // Row 1: Sets, Reps, Weight
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInputCard(
                                      context,
                                      label: "SÉRIES",
                                      controller: _setsController,
                                      onChanged: (_) => _saveChanges(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildInputCard(
                                      context,
                                      label: "REPS",
                                      controller: _repsController,
                                      onChanged: (_) => _saveChanges(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2, // Larger for weight
                                    child: _buildInputCard(
                                      context,
                                      label: "CARGA (Kg)",
                                      controller: _weightController,
                                      showHistory: true,
                                      onHistoryTap: () =>
                                          _showHistoryDialog(exercise.name),
                                      onChanged: (_) => _saveChanges(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Row 2: Equipment, Rest
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInputCard(
                                      context,
                                      label: "EQP.",
                                      controller: _equipmentController,
                                      onChanged: (_) => _saveChanges(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: _buildInputCard(
                                      context,
                                      label: "DESCANSO (s)",
                                      controller: _restController,
                                      onChanged: (_) => _saveChanges(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        if (exercise.technique != null &&
                            exercise.technique!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        const SizedBox(height: 100),
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
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final rest = int.tryParse(_restController.text) ?? 60;
                    ref.read(sessionProvider.notifier).startRestTimer(rest);
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
    bool showHistory = false,
    VoidCallback? onHistoryTap,
    ValueChanged<String>? onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            if (showHistory)
              InkWell(
                onTap: onHistoryTap,
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Icon(
                    Icons.show_chart,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18, // Slightly smaller font
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
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

class _GlobalTimerWidget extends StatefulWidget {
  final DateTime? startTime;

  const _GlobalTimerWidget({this.startTime});

  @override
  State<_GlobalTimerWidget> createState() => _GlobalTimerWidgetState();
}

class _GlobalTimerWidgetState extends State<_GlobalTimerWidget> {
  late Timer _timer;
  String _displayText = "00:00";

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  @override
  void didUpdateWidget(covariant _GlobalTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startTime != oldWidget.startTime) {
      _startTicker();
    }
  }

  void _startTicker() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    _updateTime(); // initial
  }

  void _updateTime() {
    if (widget.startTime == null) return;
    final duration = DateTime.now().difference(widget.startTime!);
    final min = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;

    if (mounted) {
      setState(() {
        _displayText = hours > 0 ? "$hours:$min:$sec" : "$min:$sec";
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            _displayText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackDialog extends StatefulWidget {
  final Function(int) onSave;

  const _FeedbackDialog({required this.onSave});

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  late ConfettiController _confettiController;
  int? _selectedRpe;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Treino Concluído! 🎉',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Como foi a intensidade?',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildEmojiOption(1, '😁', 'Muito Leve'),
                    _buildEmojiOption(2, '🙂', 'Leve'),
                    _buildEmojiOption(3, '😐', 'Moderado'),
                    _buildEmojiOption(4, '😫', 'Difícil'),
                    _buildEmojiOption(5, '🥵', 'Exaustão'),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _selectedRpe == null
                        ? null
                        : () => widget.onSave(_selectedRpe!),
                    child: const Text('Salvar Treino'),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -20,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmojiOption(int value, String emoji, String label) {
    final isSelected = _selectedRpe == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRpe = value;
        });
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.2)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : Colors.grey.withOpacity(0.3),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestTimerDialog extends ConsumerWidget {
  const _RestTimerDialog();
  // ... (Keep existing implementation)
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ... Copy existing render logic to avoid breaking ...
    // Since I'm replacing the whole file, I need to include this class fully.
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
                    backgroundColor: Colors.grey[200],
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
                    // +30s logic could be added here later
                  },
                  child: const Text('+30s'),
                ),
                FilledButton(
                  onPressed: () {
                    ref.read(sessionProvider.notifier).skipRest();
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
