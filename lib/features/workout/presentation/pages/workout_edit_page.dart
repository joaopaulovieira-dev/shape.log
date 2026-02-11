import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      appBar: AppBar(
        title: Text(widget.workoutId == null ? 'Novo Treino' : 'Editar Treino'),
        actions: [
          if (widget.workoutId != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _delete,
            ),
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Treino (ex: Treino A - Peito)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Informe um nome' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Meta de Duração (min)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Dias Agendados:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: List.generate(7, (index) {
                        final dayNum = index + 1;
                        final isSelected = _scheduledDays.contains(dayNum);
                        // Using a fixed date to get weekday names
                        final dayName = DateFormat.E('pt_BR').format(
                          DateTime(2024, 1, 1).add(Duration(days: index)),
                        );

                        return FilterChip(
                          label: Text(dayName),
                          selected: isSelected,
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
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_available),
                      title: const Text('Data de Validade'),
                      subtitle: Text(
                        _expiryDate == null
                            ? 'Não definida'
                            : DateFormat('dd/MM/yyyy').format(_expiryDate!),
                      ),
                      trailing: const Icon(Icons.calendar_today, size: 20),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _expiryDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
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
            ),
            const SizedBox(height: 16),
            const Text(
              'Exercícios',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_exercises.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('Nenhum exercício adicionado.')),
              ),
            ..._exercises.asMap().entries.map((entry) {
              final i = entry.key;
              final ex = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
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
                        TextSpan(text: ex.name),
                      ],
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex.type == ExerciseTypeEntity.cardio
                            ? '${ex.cardioDurationMinutes?.toInt() ?? 0} min • ${ex.cardioIntensity ?? "Normal"} • ${ex.restTimeSeconds}s desc'
                            : '${ex.sets} x ${ex.reps} - ${ex.weight}kg',
                      ),
                      if (ex.youtubeUrl != null)
                        Text(
                          'YouTube: Sim',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 12,
                          ),
                        ),
                      if (ex.imagePaths.isNotEmpty)
                        Text(
                          'Imagens: ${ex.imagePaths.length}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      if (ex.technique != null && ex.technique!.isNotEmpty)
                        Text(
                          'Técnica: ${ex.technique}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => setState(() => _exercises.removeAt(i)),
                  ),
                  onTap: () => _editExercise(i),
                ),
              );
            }),
            ElevatedButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Exercício'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
