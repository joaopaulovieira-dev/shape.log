import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shape_log/core/constants/app_colors.dart';
import '../providers/session_provider.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/exercise.dart';
import 'package:confetti/confetti.dart';
import '../../domain/services/workout_report_service.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/snackbar_utils.dart';
import 'package:image_picker/image_picker.dart';
import '../../../image_library/presentation/image_source_sheet.dart';
import '../../../common/services/image_storage_service.dart';
import '../../../../core/presentation/widgets/app_dialogs.dart';
import '../../../../core/presentation/widgets/app_modals.dart';

class WorkoutSessionPage extends ConsumerStatefulWidget {
  final Workout workout;

  const WorkoutSessionPage({super.key, required this.workout});

  @override
  ConsumerState<WorkoutSessionPage> createState() => _WorkoutSessionPageState();
}

class _WorkoutSessionPageState extends ConsumerState<WorkoutSessionPage> {
  late PageController _pageController;
  bool _isWarmup = false;
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _restController;
  late TextEditingController _equipmentController;

  final List<String> _recoveredImages = [];

  // Cardio Controllers
  late TextEditingController _cardioDurationController;
  late TextEditingController _cardioIntensityController;

  // Focus Nodes for Auto-Save
  final FocusNode _setsFocus = FocusNode();
  final FocusNode _repsFocus = FocusNode();
  final FocusNode _weightFocus = FocusNode();
  final FocusNode _restFocus = FocusNode();
  final FocusNode _equipmentFocus = FocusNode();
  final FocusNode _cardioDurationFocus = FocusNode();
  final FocusNode _cardioIntensityFocus = FocusNode();

  // Visual Feedback
  bool _showSavedFeedback = false;
  Timer? _feedbackTimer;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _setsController = TextEditingController();
    _repsController = TextEditingController();
    _weightController = TextEditingController();
    _restController = TextEditingController();
    _equipmentController = TextEditingController();
    _cardioDurationController = TextEditingController();
    _cardioIntensityController = TextEditingController();

    _retrieveLostData();

    // Initialize session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sessionState = ref.read(sessionProvider);

      // If we are already running THIS workout, don't restart it (Resume functionality)
      if (sessionState.activeWorkout?.id == widget.workout.id) {
        _updateControllers();
        // Jump to correct page if needed
        if (_pageController.hasClients) {
          _pageController.jumpToPage(sessionState.currentExerciseIndex);
        }
      } else {
        ref.read(sessionProvider.notifier).startSession(widget.workout);
        _updateControllers();
      }
    });

    // Setup Focus Listeners for Auto-Save
    _setsFocus.addListener(_onFocusChange);
    _repsFocus.addListener(_onFocusChange);
    _weightFocus.addListener(_onFocusChange);
    _restFocus.addListener(_onFocusChange);
    _equipmentFocus.addListener(_onFocusChange);
    _cardioDurationFocus.addListener(_onFocusChange);
    _cardioIntensityFocus.addListener(_onFocusChange);
  }

  Future<void> _retrieveLostData() async {
    final LostDataResponse response = await ImageSourceSheet.picker
        .retrieveLostData();
    if (response.isEmpty) return;
    if (response.file != null) {
      _recoveredImages.add(response.file!.path);
    } else if (response.files != null) {
      _recoveredImages.addAll(response.files!.map((f) => f.path));
    }

    if (_recoveredImages.isNotEmpty) {
      // If we recovered images, it means the activity was killed while taking a photo.
      // We should show the feedback dialog immediately so the user can save.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFeedbackDialog();
      });
    }
  }

  void _onFocusChange() {
    // If any field lost focus, we ensure state is saved.
    // Actually, we want to save when *valid* changes happen, which _saveChanges handles.
    // But we trigger it on blur to be safe.
    // Checks if any relevant focus node *lost* focus.
    // A simpler approach: iterate all. If none have focus, or just on every change.
    // The requirement is: "onFieldSubmitted and FocusNode.addListener (onBlur)"
    // We just call _saveChanges() on blur.

    // We can just call _saveChanges(). usage of _saveChanges reads from text controllers.
    // If the text controllers haven't changed, _saveChanges might still trigger an update,
    // but the provider logic checks against current state if we implemented it right?
    // Actually SessionProvider.updateCurrentExercise replaces the specific exercise instance.
    // It's cheap enough.

    // We only care if we *lost* focus on one of them.
    if (!_setsFocus.hasFocus &&
        !_repsFocus.hasFocus &&
        !_weightFocus.hasFocus &&
        !_restFocus.hasFocus &&
        !_equipmentFocus.hasFocus &&
        !_cardioDurationFocus.hasFocus &&
        !_cardioIntensityFocus.hasFocus) {
      _saveChanges();
    } else {
      // Even if switching between fields, we might want to save the one we just left.
      // So just calling _saveChanges() whenever a listener fires is safe,
      // as `_saveChanges` grabs all current values.
      _saveChanges();
    }
  }

  void _onFieldChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) _saveChanges();
    });
  }

  void _updateControllers() {
    // Cancel any pending debounce to avoid overwriting new state with old inputs
    _debounceTimer?.cancel();

    final state = ref.read(sessionProvider);
    final exercise = state.currentExercise;
    if (exercise != null) {
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

      // Cardio
      if (_cardioDurationController.text !=
          (exercise.cardioDurationMinutes?.toString() ?? '')) {
        _cardioDurationController.text =
            exercise.cardioDurationMinutes?.toString() ?? '';
      }
      if (_cardioIntensityController.text != (exercise.cardioIntensity ?? '')) {
        _cardioIntensityController.text = exercise.cardioIntensity ?? '';
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
      cardioDurationMinutes: double.tryParse(_cardioDurationController.text),
      cardioIntensity: _cardioIntensityController.text,
    );

    ref.read(sessionProvider.notifier).updateCurrentExercise(updatedExercise);

    // Show visual feedback
    if (mounted) {
      // Cancel previous timer if any
      _feedbackTimer?.cancel();

      setState(() {
        _showSavedFeedback = true;
      });

      _feedbackTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _showSavedFeedback = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _restController.dispose();
    _equipmentController.dispose();
    _cardioDurationController.dispose();
    _cardioIntensityController.dispose();

    _setsFocus.dispose();
    _repsFocus.dispose();
    _weightFocus.dispose();
    _restFocus.dispose();
    _equipmentFocus.dispose();
    _cardioDurationFocus.dispose();
    _cardioIntensityFocus.dispose();
    _feedbackTimer?.cancel();
    _debounceTimer?.cancel();

    super.dispose();
  }

  Future<void> _tryFinishWorkout() async {
    final state = ref.read(sessionProvider);
    final total = widget.workout.exercises.length;
    final completed = state.completedExerciseNames.length;

    if (completed < total) {
      // Show warning
      final confirmed = await AppDialogs.showConfirmDialog(
        context: context,
        title: 'Treino Incompleto',
        description:
            'Você completou $completed de $total exercícios. Deseja finalizar mesmo assim?',
        confirmText: 'FINALIZAR',
        cancelText: 'VOLTAR',
      );

      if (confirmed == true) {
        _showFeedbackDialog();
      }
    } else {
      _showFeedbackDialog();
    }
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _FeedbackDialog(
        initialImagePaths: _recoveredImages,
        onSave: (rpe, imagePaths) async {
          // Logic moved from _FeedbackDialog to here (or kept there if it was cleaner, but let's follow the pattern)
          // Actually, in the previous implementation, the dialog handled the logic.
          // In the new implementation I wrote above, the dialog *calls* onSave with the data.
          // So I need to execute the saving logic here.

          try {
            final history = await ref
                .read(sessionProvider.notifier)
                .finishSessionWithRpe(rpe, imagePaths: imagePaths);

            if (history != null && mounted) {
              // Generate report
              final user = await ref.read(userProfileProvider.future);
              final reportStr = WorkoutReportService().generateClipboardReport(
                history,
                user,
              );

              // Copy to clipboard
              await Clipboard.setData(ClipboardData(text: reportStr));

              if (mounted) {
                SnackbarUtils.showSuccess(
                  context,
                  'Relatório copiado para a área de transferência!',
                );
              }
            }
          } catch (e, stack) {
            debugPrint("Error saving session: $e\n$stack");
            if (mounted) {
              SnackbarUtils.showError(context, 'Erro ao salvar: $e');
            }
          } finally {
            // Close things
            if (mounted) {
              context.pop(); // Dialog
              if (context.mounted) {
                context.pop(true); // Exit page
              }
            }
          }
        },
      ),
    );
  }

  void _showHistoryDialog(String exerciseName) async {
    final history = await ref
        .read(sessionProvider.notifier)
        .getExerciseHistory(exerciseName);

    if (!mounted) return;

    if (!mounted) return;

    AppModals.showAppModal(
      context: context,
      title: 'Histórico: $exerciseName',
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: history.isEmpty
            ? const Center(
                child: Text(
                  'Nenhum histórico encontrado.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : ListView.builder(
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
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.2),
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
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      "${exercise.sets} séries x ${exercise.reps} reps",
                      style: TextStyle(color: Colors.grey[400]),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    // Sync PageController with State if needed
    ref.listen(sessionProvider, (prev, next) {
      // Update controllers if workout data changes (e.g. history loaded)
      // This fixes the issue where initial load was showing default values instead of history
      if (prev?.activeWorkout != next.activeWorkout) {
        _updateControllers();
      }

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
                  final lastHistory =
                      sessionState.lastHistoryMap[exercise.name];

                  // Set logic (handled in bottom button)
                  // final setsRecords = sessionState.setsRecords[exercise.name] ?? [];
                  // final currentSetNumber = setsRecords.length + 1;
                  // final totalSets = exercise.sets;

                  // unused: final isLastSet = currentSetNumber >= totalSets;

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Image (Reduced Size: 20-25% height)
                        SizedBox(
                          height: size.height * 0.22,
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(16),
                              border: isCompleted
                                  ? Border.all(
                                      color: AppColors.primary,
                                      width: 3,
                                    )
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
                                              errorBuilder: (_, _, _) =>
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
                                                size: 50,
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
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
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
                        ),

                        // Title with Copy Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  exercise.name,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                color: colorScheme.onSurfaceVariant,
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: exercise.name),
                                  );
                                  SnackbarUtils.showInfo(
                                    context,
                                    'Nome copiado!',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // INPUTS
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              if (exercise.type ==
                                  ExerciseTypeEntity.cardio) ...[
                                // CARDIO MODE
                                // Row 1: Time | Rest
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInputCard(
                                        context,
                                        label: "TEMPO (min)",
                                        controller: _cardioDurationController,
                                        focusNode: _cardioDurationFocus,
                                        onChanged: _onFieldChanged,
                                        largeFont: true,
                                        showSavedFeedback: _showSavedFeedback,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildInputCard(
                                        context,
                                        label: "DESCANSO (s)",
                                        controller: _restController,
                                        focusNode: _restFocus,
                                        onChanged: _onFieldChanged,
                                        largeFont: true,
                                        showSavedFeedback: _showSavedFeedback,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Row 2: Intensity (Full Width)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInputCard(
                                        context,
                                        label: "INTENSIDADE",
                                        controller: _cardioIntensityController,
                                        focusNode: _cardioIntensityFocus,
                                        onChanged: _onFieldChanged,
                                        isNumber: false, // Text input
                                        showSavedFeedback: _showSavedFeedback,
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                // WEIGHT MODE
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2, // More width for Weight
                                      child: _buildInputCard(
                                        context,
                                        label: "CARGA (Kg)",
                                        subtitle: lastHistory != null
                                            ? "Último: ${lastHistory.weight}kg"
                                            : null,
                                        controller: _weightController,
                                        focusNode: _weightFocus,
                                        showHistory: true,
                                        onHistoryTap: () =>
                                            _showHistoryDialog(exercise.name),
                                        onChanged: _onFieldChanged,
                                        largeFont: true,
                                        showSavedFeedback: _showSavedFeedback,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildInputCard(
                                        context,
                                        label: "REPS",
                                        controller: _repsController,
                                        focusNode: _repsFocus,
                                        onChanged: _onFieldChanged,
                                        largeFont: true,
                                        showSavedFeedback: _showSavedFeedback,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Row 2: Sets & Rest (Only for Weight, Rest is here)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInputCard(
                                        context,
                                        label: "SÉRIES ALVO",
                                        controller: _setsController,
                                        focusNode: _setsFocus,
                                        onChanged: _onFieldChanged,
                                        showSavedFeedback: _showSavedFeedback,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildInputCard(
                                        context,
                                        label: "DESCANSO (s)",
                                        controller: _restController,
                                        focusNode: _restFocus,
                                        onChanged: _onFieldChanged,
                                        showSavedFeedback: _showSavedFeedback,
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              const SizedBox(height: 16),

                              // Row 3: Equipment (Full Width)
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInputCard(
                                      context,
                                      label: "EQUIPAMENTO",
                                      controller: _equipmentController,
                                      focusNode: _equipmentFocus,
                                      onChanged: _onFieldChanged,
                                      isNumber: false, // Allow alphanumeric
                                      showSavedFeedback: _showSavedFeedback,
                                    ),
                                  ),
                                ],
                              ),

                              // Warmup Chip (Only for Weights)
                              if (exercise.type == ExerciseTypeEntity.weight)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ChoiceChip(
                                        avatar: Icon(
                                          Icons.local_fire_department,
                                          size: 18,
                                          color: _isWarmup
                                              ? Colors.deepOrange
                                              : null,
                                        ),
                                        label: Text(
                                          _isWarmup
                                              ? "Aquecimento"
                                              : "Série Normal",
                                          style: TextStyle(
                                            color: _isWarmup
                                                ? Colors.deepOrange
                                                : null,
                                            fontWeight: _isWarmup
                                                ? FontWeight.bold
                                                : null,
                                          ),
                                        ),
                                        selected: _isWarmup,
                                        onSelected: (selected) {
                                          setState(() => _isWarmup = selected);
                                        },
                                        selectedColor: Colors.deepOrange
                                            .withOpacity(0.2),
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                        showCheckmark: false,
                                      ),
                                    ],
                                  ),
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
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
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
            Consumer(
              builder: (context, ref, child) {
                // We need to access the CURRENT exercise logic here
                // But the button is outside the PageView builder.
                // We must rely on sessionState.currentExercise which is already synced.
                final exercise = sessionState.currentExercise;
                final setsRecords = exercise != null
                    ? (sessionState.setsRecords[exercise.name] ?? [])
                    : [];
                final currentSetNumber = setsRecords.length + 1;
                final totalSets = exercise?.sets ?? 3;
                final isLastSet = currentSetNumber >= totalSets;
                final isCardio = exercise?.type == ExerciseTypeEntity.cardio;

                String buttonLabel =
                    "CONCLUIR SÉRIE $currentSetNumber de $totalSets";
                if (isLastSet) buttonLabel = "FINALIZAR EXERCÍCIO";
                if (isCardio) buttonLabel = "FINALIZAR CARDIO";

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 64, // Bigger button
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        final rest = int.tryParse(_restController.text) ?? 60;
                        final currentWeight = double.tryParse(
                          _weightController.text,
                        );
                        final currentReps = int.tryParse(_repsController.text);

                        ref
                            .read(sessionProvider.notifier)
                            .startRestTimer(
                              rest,
                              isWarmup: _isWarmup,
                              currentWeight: currentWeight,
                              currentReps: currentReps,
                            );
                        if (mounted) setState(() => _isWarmup = false);
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 28),
                      label: Text(
                        buttonLabel,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
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
    FocusNode? focusNode,
    bool showHistory = false,
    VoidCallback? onHistoryTap,
    ValueChanged<String>? onChanged,
    bool largeFont = false,
    bool isNumber = true,
    int? maxLines = 1,
    bool showSavedFeedback = false,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Row(
              children: [
                if (showSavedFeedback)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 2),
                    child: Icon(
                      Icons.cloud_done,
                      size: 16,
                      color: AppColors.primary.withValues(alpha: 0.8),
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
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          keyboardType: isNumber
              ? TextInputType.number
              : (maxLines != 1 ? TextInputType.multiline : TextInputType.text),
          maxLines: maxLines,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: largeFont ? 40 : 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.2,
          ),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(vertical: largeFont ? 16 : 10),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
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

class _FeedbackDialog extends ConsumerStatefulWidget {
  final Function(int, List<String>) onSave;
  final List<String> initialImagePaths;

  const _FeedbackDialog({
    required this.onSave,
    this.initialImagePaths = const [],
  });

  @override
  ConsumerState<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<_FeedbackDialog> {
  late ConfettiController _confettiController;
  int? _selectedRpe;
  bool _isSaving = false;
  final List<String> _tempImagePaths = [];
  final ImageStorageService _imageService = ImageStorageService();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _confettiController.play();
    _tempImagePaths.addAll(widget.initialImagePaths);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await ImageSourceSheet.picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 60,
      );
      if (image != null) {
        setState(() {
          _tempImagePaths.add(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Erro ao selecionar imagem: $e');
      }
    }
  }

  Future<void> _handleSave() async {
    if (_selectedRpe == null) return;

    setState(() => _isSaving = true);

    try {
      // 1. Save images permanently
      final permanentPaths = <String>[];
      for (final path in _tempImagePaths) {
        // Create an XFile from the path (which is currently in cache)
        final xFile = XFile(path);
        final permanentPath = await _imageService.saveImage(xFile);
        permanentPaths.add(permanentPath);
      }

      // 2. Call onSave with RPE and Paths
      widget.onSave(_selectedRpe!, permanentPaths);
    } catch (e, stack) {
      debugPrint("Error saving session: $e\n$stack");
      if (mounted) {
        SnackbarUtils.showError(context, 'Erro ao salvar: $e');
        setState(() => _isSaving = false);
      }
    }
    // Logic for closing is handled in parent callback or we can do it here if we pass function differently
    // The original onSave handled the finishSession call.
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
            child: SingleChildScrollView(
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

                  // RPE Selector
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
                  const SizedBox(height: 24),

                  // Photos Section
                  const Text(
                    'Registrar Foto do Shape (Opcional)',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),

                  // Horizontal List of Photos + Add Button
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _tempImagePaths.length + 1,
                      separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                      itemBuilder: (ctx, index) {
                        if (index == _tempImagePaths.length) {
                          // Add Button
                          return Row(
                            children: [
                              _buildAddPhotoButton(
                                Icons.camera_alt,
                                "Câmera",
                                ImageSource.camera,
                              ),
                              const SizedBox(width: 8),
                              _buildAddPhotoButton(
                                Icons.photo_library,
                                "Galeria",
                                ImageSource.gallery,
                              ),
                            ],
                          );
                        }

                        // Photo Thumbnail
                        final path = _tempImagePaths[index];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _tempImagePaths.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _selectedRpe == null || _isSaving
                          ? null
                          : _handleSave,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Salvar e Copiar Relatório'),
                    ),
                  ),
                ],
              ),
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

  Widget _buildAddPhotoButton(IconData icon, String label, ImageSource source) {
    return InkWell(
      onTap: () => _pickImage(source),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.5),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : Colors.grey.withValues(alpha: 0.3),
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
                    ref.read(sessionProvider.notifier).addTime(30);
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
