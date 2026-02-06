import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../image_library/presentation/image_source_sheet.dart';
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
    _nameController = TextEditingController(text: ex.name);
    _setsController = TextEditingController(text: ex.sets.toString());
    _repsController = TextEditingController(text: ex.reps.toString());
    _weightController = TextEditingController(text: ex.weight.toString());
    _urlController = TextEditingController(text: ex.youtubeUrl ?? '');
    _equipController = TextEditingController(text: ex.equipmentNumber ?? '');
    _techniqueController = TextEditingController(text: ex.technique ?? '');
    _restTime = ex.restTimeSeconds;
    _imagePaths = List.from(ex.imagePaths);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _workout == null) return;

    final updatedExercise = Exercise(
      name: _nameController.text,
      sets: int.tryParse(_setsController.text) ?? 0,
      reps: int.tryParse(_repsController.text) ?? 0,
      weight: double.tryParse(_weightController.text) ?? 0,
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Exercício'),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Exercício',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Informe um nome' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _equipController,
              decoration: const InputDecoration(
                labelText: 'Nº Equipamento (Opcional)',
                border: OutlineInputBorder(),
                hintText: 'ex: 12 ou A-1',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _setsController,
                    decoration: const InputDecoration(
                      labelText: 'Séries',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _repsController,
                    decoration: const InputDecoration(
                      labelText: 'Repetições',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Carga (kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Link YouTube (Opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _techniqueController,
              decoration: const InputDecoration(
                labelText: 'Técnica / Observações',
                border: OutlineInputBorder(),
                hintText: 'ex: Drop-set na última série, cadência 4-0-2...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tempo de Descanso',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${(_restTime ~/ 60).toString().padLeft(2, '0')}:${(_restTime % 60).toString().padLeft(2, '0')} min',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [30, 45, 60, 90, 120, 180].map((time) {
                  final isSelected = _restTime == time;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(time >= 60 ? '${time ~/ 60}m' : '${time}s'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _restTime = time;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            Slider(
              value: _restTime.toDouble(),
              min: 0,
              max: 300,
              divisions: 20,
              label: '${_restTime}s',
              onChanged: (value) {
                setState(() {
                  _restTime = value.toInt();
                });
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Imagens',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_imagePaths.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagePaths.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(File(_imagePaths[index])),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            setState(() {
                              _imagePaths.removeAt(index);
                            });
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await showModalBottomSheet(
                    context: context,
                    builder: (context) => const ImageSourceSheet(),
                  ).then((files) {
                    if (files != null && files is List<File>) {
                      setState(() {
                        _imagePaths.addAll(files.map((e) => e.path));
                      });
                    }
                  });
                },
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Adicionar Foto'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 32,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
