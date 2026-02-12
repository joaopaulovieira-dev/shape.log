import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_log/core/constants/app_colors.dart';
import '../../../image_library/presentation/image_source_sheet.dart';
import '../../../../core/presentation/widgets/app_modals.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout.dart';
import '../providers/workout_provider.dart';

class ExerciseEditPage extends ConsumerStatefulWidget {
  final String workoutId;
  final int exerciseIndex;

  const ExerciseEditPage({
    super.key,
    required this.workoutId,
    required this.exerciseIndex,
  });

  @override
  ConsumerState<ExerciseEditPage> createState() => _ExerciseEditPageState();
}

class _ExerciseEditPageState extends ConsumerState<ExerciseEditPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _urlController;
  late TextEditingController _equipController;
  late TextEditingController _techniqueController;
  int _restTime = 60;
  List<String> _imagePaths = [];
  bool _isLoading = true;
  Workout? _workout;

  ExerciseTypeEntity _selectedType = ExerciseTypeEntity.weight;
  late TextEditingController _cardioDurationController;
  late TextEditingController _cardioIntensityController;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _urlController.dispose();
    _equipController.dispose();
    _techniqueController.dispose();
    _cardioDurationController.dispose();
    _cardioIntensityController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final workouts = await ref.read(routineListProvider.future);
    _workout = workouts.firstWhere(
      (w) => w.id == widget.workoutId,
      orElse: () => throw Exception('Treino não encontrado'),
    );

    if (widget.exerciseIndex >= _workout!.exercises.length) {
      throw Exception('Exercício não encontrado');
    }

    final ex = _workout!.exercises[widget.exerciseIndex];
    _selectedType = ex.type;
    _nameController = TextEditingController(text: ex.name);
    _setsController = TextEditingController(text: ex.sets.toString());
    _repsController = TextEditingController(text: ex.reps.toString());
    _weightController = TextEditingController(text: ex.weight.toString());
    _urlController = TextEditingController(text: ex.youtubeUrl ?? '');
    _equipController = TextEditingController(text: ex.equipmentNumber ?? '');
    _techniqueController = TextEditingController(text: ex.technique ?? '');
    _restTime = ex.restTimeSeconds;
    _imagePaths = List.from(ex.imagePaths);

    _cardioDurationController = TextEditingController(
      text: ex.cardioDurationMinutes?.toString() ?? '30',
    );
    _cardioIntensityController = TextEditingController(
      text: ex.cardioIntensity ?? '',
    );

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _workout == null) return;

    final updatedExercise = Exercise(
      name: _nameController.text,
      type: _selectedType,
      youtubeUrl: _urlController.text.isEmpty ? null : _urlController.text,
      imagePaths: _imagePaths,
      equipmentNumber: _equipController.text.isEmpty
          ? null
          : _equipController.text,
      technique: _techniqueController.text.isEmpty
          ? null
          : _techniqueController.text,
      isCompleted: _workout!.exercises[widget.exerciseIndex].isCompleted,
      restTimeSeconds: _restTime,

      // Weight fields
      sets: int.tryParse(_setsController.text) ?? 0,
      reps: _selectedType == ExerciseTypeEntity.weight
          ? (int.tryParse(_repsController.text) ?? 0)
          : 0,
      weight: _selectedType == ExerciseTypeEntity.weight
          ? (double.tryParse(_weightController.text) ?? 0)
          : 0,

      // Cardio fields
      cardioDurationMinutes: _selectedType == ExerciseTypeEntity.cardio
          ? (double.tryParse(_cardioDurationController.text) ?? 0)
          : null,
      cardioIntensity: _selectedType == ExerciseTypeEntity.cardio
          ? (_cardioIntensityController.text.isEmpty
                ? null
                : _cardioIntensityController.text)
          : null,
    );

    final List<Exercise> updatedExercises = List.from(_workout!.exercises);
    updatedExercises[widget.exerciseIndex] = updatedExercise;

    final updatedWorkout = Workout(
      id: _workout!.id,
      name: _workout!.name,
      scheduledDays: _workout!.scheduledDays,
      targetDurationMinutes: _workout!.targetDurationMinutes,
      notes: _workout!.notes,
      exercises: updatedExercises,
      activeStartTime: _workout!.activeStartTime,
      expiryDate: _workout!.expiryDate,
    );

    await ref.read(workoutRepositoryProvider).saveRoutine(updatedWorkout);
    ref.invalidate(routineListProvider);

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Premium Header
            SliverAppBar(
              expandedHeight: 120.0,
              floating: true,
              pinned: true,
              backgroundColor: AppColors.background,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: const EdgeInsets.only(bottom: 16),
                title: Text(
                  'Editar Exercício',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.15),
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
                  icon: const Icon(Icons.check, color: Colors.white),
                  onPressed: _save,
                  tooltip: 'Salvar',
                ),
              ],
            ),

            // 2. Type Selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: SegmentedButton<ExerciseTypeEntity>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1E1E),
                    selectedBackgroundColor: AppColors.primary,
                    selectedForegroundColor: Colors.black,
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withOpacity(0.05)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: ExerciseTypeEntity.weight,
                      label: Text('Musculação'),
                      icon: Icon(Icons.fitness_center),
                    ),
                    ButtonSegment(
                      value: ExerciseTypeEntity.cardio,
                      label: Text('Cardio'),
                      icon: Icon(Icons.directions_run),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (Set<ExerciseTypeEntity> newSelection) {
                    setState(() {
                      _selectedType = newSelection.first;
                    });
                  },
                ),
              ),
            ),

            // 3. Main Info Section
            SliverToBoxAdapter(
              child: _buildFormCard(
                title: "DADOS DO EXERCÍCIO",
                children: [
                  TextFormField(
                    controller: _nameController,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: _buildDecoration(
                      'Nome do Exercício',
                      Icons.title,
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => v!.isEmpty ? 'Informe um nome' : null,
                  ),
                  const SizedBox(height: 16),

                  if (_selectedType == ExerciseTypeEntity.weight) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _setsController,
                            style: GoogleFonts.outfit(color: Colors.white),
                            decoration: _buildDecoration(
                              'Séries',
                              Icons.reorder,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _repsController,
                            style: GoogleFonts.outfit(color: Colors.white),
                            decoration: _buildDecoration('Reps', Icons.repeat),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _weightController,
                      style: GoogleFonts.outfit(color: Colors.white),
                      decoration: _buildDecoration(
                        'Carga (kg)',
                        Icons.fitness_center,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _setsController,
                            style: GoogleFonts.outfit(color: Colors.white),
                            decoration: _buildDecoration(
                              'Séries',
                              Icons.reorder,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _cardioDurationController,
                            style: GoogleFonts.outfit(color: Colors.white),
                            decoration: _buildDecoration(
                              'Tempo (min)',
                              Icons.timer_outlined,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cardioIntensityController,
                      style: GoogleFonts.outfit(color: Colors.white),
                      decoration: _buildDecoration(
                        'Intensidade / Velocidade',
                        Icons.speed_outlined,
                        hintText: 'Ex: 8km/h ou Moderado',
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 4. Details Section
            SliverToBoxAdapter(
              child: _buildFormCard(
                title: "INFORMAÇÕES ADICIONAIS",
                children: [
                  TextFormField(
                    controller: _equipController,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: _buildDecoration(
                      'Equipamento nº (Opcional)',
                      Icons.grid_3x3,
                      hintText: 'Número da máquina',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _urlController,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: _buildDecoration(
                      'YouTube link (Opcional)',
                      Icons.video_library_outlined,
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _techniqueController,
                    style: GoogleFonts.outfit(color: Colors.white),
                    maxLines: 3,
                    decoration: _buildDecoration(
                      'Técnica / Observações',
                      Icons.lightbulb_outline,
                    ),
                  ),
                ],
              ),
            ),

            // 5. Rest Time Section
            SliverToBoxAdapter(
              child: _buildFormCard(
                title: "TEMPO DE DESCANSO",
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(_restTime ~/ 60).toString().padLeft(2, '0')}:${(_restTime % 60).toString().padLeft(2, '0')}',
                    style: GoogleFonts.outfit(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                children: [
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [30, 45, 60, 90, 120, 180].map((time) {
                        final isSelected = _restTime == time;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              time >= 60 ? '${time ~/ 60}m' : '${time}s',
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            checkmarkColor: Colors.black,
                            labelStyle: GoogleFonts.outfit(
                              color: isSelected ? Colors.black : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            backgroundColor: const Color(0xFF2C2C2C),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white.withOpacity(0.05),
                            ),
                            onSelected: (selected) {
                              if (selected) setState(() => _restTime = time);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: Colors.white.withOpacity(0.1),
                      thumbColor: AppColors.primary,
                    ),
                    child: Slider(
                      value: _restTime.toDouble(),
                      min: 0,
                      max: 300,
                      divisions: 60,
                      onChanged: (value) =>
                          setState(() => _restTime = value.toInt()),
                    ),
                  ),
                ],
              ),
            ),

            // 6. Image Section
            SliverToBoxAdapter(
              child: _buildFormCard(
                title: "GALERIA DE IMAGENS",
                children: [
                  if (_imagePaths.isNotEmpty) ...[
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _imagePaths.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 140,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                  image: DecorationImage(
                                    image: FileImage(File(_imagePaths[index])),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 16,
                                child: GestureDetector(
                                  onTap: () => setState(
                                    () => _imagePaths.removeAt(index),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await AppModals.showAppModal(
                          context: context,
                          title: 'Selecionar Imagem',
                          child: const ImageSourceSheet(),
                        ).then((files) {
                          if (files != null && files is List<File>) {
                            setState(
                              () =>
                                  _imagePaths.addAll(files.map((e) => e.path)),
                            );
                          }
                        });
                      },
                      icon: const Icon(Icons.add_a_photo_outlined, size: 20),
                      label: Text(
                        'ADICIONAR FOTO',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard({
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                    letterSpacing: 1.2,
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  InputDecoration _buildDecoration(
    String label,
    IconData icon, {
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14),
      hintText: hintText,
      hintStyle: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: Colors.black.withOpacity(0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.02)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    );
  }
}
