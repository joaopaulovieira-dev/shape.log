import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/exercise.dart';
import '../providers/workout_provider.dart';
import 'package:shape_log/core/constants/app_colors.dart';

import '../../../../core/presentation/widgets/app_dialogs.dart';
import 'exercise_form_page.dart';

class WorkoutEditPage extends ConsumerStatefulWidget {
  final String? workoutId;

  const WorkoutEditPage({super.key, this.workoutId});

  @override
  ConsumerState<WorkoutEditPage> createState() => _WorkoutEditPageState();
}

class _WorkoutEditPageState extends ConsumerState<WorkoutEditPage> {
  final _formKey = GlobalKey<FormState>();

  late String _id;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _durationController;
  List<Exercise> _exercises = [];
  List<int> _scheduledDays = []; // 1=Mon, 7=Sun
  DateTime? _expiryDate;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _notesController = TextEditingController();
    _durationController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (widget.workoutId != null) {
      // Edit Mode
      final workouts = await ref.read(routineListProvider.future);
      final workout = workouts.firstWhere(
        (w) => w.id == widget.workoutId,
        orElse: () => throw Exception('Treino não encontrado'),
      );

      _id = workout.id;
      _nameController.text = workout.name;
      _scheduledDays = List.from(workout.scheduledDays);
      _durationController.text = workout.targetDurationMinutes.toString();
      _exercises = List.from(workout.exercises);
      _notesController.text = workout.notes;
      _expiryDate = workout.expiryDate;
    } else {
      // Create Mode
      _id = const Uuid().v4();
      _nameController.text = '';
      _scheduledDays = [];
      _durationController.text = '60';
      _notesController.text = '';
      _exercises = [];
      _expiryDate = DateTime.now().add(
        const Duration(days: 90),
      ); // Default 3 months
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final workout = Workout(
      id: _id,
      name: _nameController.text.isEmpty
          ? 'Treino Personalizado'
          : _nameController.text,
      scheduledDays: _scheduledDays,
      targetDurationMinutes: int.tryParse(_durationController.text) ?? 60,
      notes: _notesController.text,
      exercises: _exercises,
      expiryDate: _expiryDate,
    );

    await ref.read(workoutRepositoryProvider).saveRoutine(workout);
    ref.invalidate(routineListProvider);

    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final confirmed = await AppDialogs.showConfirmDialog(
      context: context,
      title: 'Excluir Treino',
      description: 'Tem certeza que deseja excluir esta treino?',
      confirmText: 'EXCLUIR',
      isDestructive: true,
    );

    if (confirmed == true) {
      await ref.read(workoutRepositoryProvider).deleteRoutine(_id);
      ref.invalidate(routineListProvider);
      if (mounted) context.pop();
    }
  }

  Future<void> _addExercise() async {
    final result = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(builder: (context) => const ExerciseFormPage()),
    );
    if (result != null) {
      setState(() {
        _exercises.add(result);
      });
    }
  }

  Future<void> _editExercise(int index) async {
    final result = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ExerciseFormPage(initialExercise: _exercises[index]),
      ),
    );
    if (result != null) {
      setState(() {
        _exercises[index] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
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
                  widget.workoutId == null ? 'Novo Treino' : 'Editar Treino',
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
                if (widget.workoutId != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: _delete,
                  ),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.white),
                  onPressed: _save,
                ),
              ],
            ),

            // 2. Base Info Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "IDENTIFICAÇÃO",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[500],
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Nome do Treino (ex: Treino A)',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              hintText: 'Digite o nome do treino...',
                              hintStyle: TextStyle(color: Colors.grey[700]),
                              prefixIcon: const Icon(
                                Icons.edit_note,
                                color: AppColors.primary,
                              ),
                              filled: true,
                              fillColor: Colors.black26,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1,
                                ),
                              ),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? 'Informe um nome' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _durationController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Meta de Duração (minutos)',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: const Icon(
                                Icons.timer_outlined,
                                color: AppColors.primary,
                              ),
                              filled: true,
                              fillColor: Colors.black26,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "AGENDAMENTO",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[500],
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(7, (index) {
                              final dayNum = index + 1;
                              final isSelected = _scheduledDays.contains(
                                dayNum,
                              );
                              final dayName = DateFormat.E('pt_BR').format(
                                DateTime(2024, 1, 1).add(Duration(days: index)),
                              );

                              return FilterChip(
                                label: Text(dayName),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                checkmarkColor: Colors.black,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white70,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                backgroundColor: Colors.white.withOpacity(0.05),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _scheduledDays.add(dayNum);
                                    } else {
                                      _scheduledDays.remove(dayNum);
                                    }
                                  });
                                },
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.event_available,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            title: const Text(
                              'Validade do Treino',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              _expiryDate == null
                                  ? 'Não definida'
                                  : DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_expiryDate!),
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            trailing: Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _expiryDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: AppColors.primary,
                                        onPrimary: Colors.black,
                                        surface: Color(0xFF1E1E1E),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  _expiryDate = picked;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Exercises Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "EXERCÍCIOS (${_exercises.length})",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                        letterSpacing: 1.2,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addExercise,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("ADICIONAR"),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Exercise List
            if (_exercises.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.fitness_center_outlined,
                          size: 48,
                          color: Colors.grey[800],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Nenhum exercício ainda.\nToque em ADICIONAR para começar.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final ex = _exercises[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: ListTile(
                        onTap: () => _editExercise(index),
                        contentPadding: const EdgeInsets.all(16),
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
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.repeat,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      ex.type == ExerciseTypeEntity.cardio
                                          ? '${ex.cardioDurationMinutes?.toInt() ?? 0} min • ${ex.cardioIntensity ?? "Médio"}'
                                          : '${ex.sets} séries x ${ex.reps} reps',
                                      style: TextStyle(color: Colors.grey[400]),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  if (ex.type != ExerciseTypeEntity.cardio) ...[
                                    Icon(
                                      Icons.fitness_center,
                                      size: 14,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${ex.weight} kg',
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                  ],
                                ],
                              ),
                              if (ex.technique != null &&
                                  ex.technique!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    ex.technique!,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _exercises.removeAt(index)),
                        ),
                      ),
                    );
                  }, childCount: _exercises.length),
                ),
              ),

            // 5. Notes Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                      Text(
                        "OBSERVAÇÕES",
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Digite observações adicionais ou foco...',
                          hintStyle: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Spacing
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
