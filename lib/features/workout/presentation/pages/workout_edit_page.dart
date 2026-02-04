import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/exercise.dart';
import '../providers/workout_provider.dart';

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
    } else {
      // Create Mode
      _id = const Uuid().v4();
      _nameController.text = '';
      _scheduledDays = [];
      _durationController.text = '60';
      _notesController.text = '';
      _exercises = [];
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
    );

    await ref.read(workoutRepositoryProvider).saveRoutine(workout);
    ref.invalidate(routineListProvider);

    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Treino'),
        content: const Text('Tem certeza que deseja excluir esta treino?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(workoutRepositoryProvider).deleteRoutine(_id);
      ref.invalidate(routineListProvider);
      if (mounted) context.pop();
    }
  }

  void _addExercise() {
    setState(() {
      _exercises.add(
        const Exercise(name: 'Novo Exercício', sets: 3, reps: 10, weight: 0),
      );
    });
    _editExercise(_exercises.length - 1);
  }

  void _editExercise(int index) {
    final ex = _exercises[index];
    final nameCtrl = TextEditingController(text: ex.name);
    final setsCtrl = TextEditingController(text: ex.sets.toString());
    final repsCtrl = TextEditingController(text: ex.reps.toString());
    final weightCtrl = TextEditingController(text: ex.weight.toString());
    final urlCtrl = TextEditingController(text: ex.youtubeUrl ?? '');
    final equipCtrl = TextEditingController(text: ex.equipmentNumber ?? '');
    List<String> tempImagePaths = List.from(ex.imagePaths);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Exercício'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: equipCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nº Equipamento (Opcional)',
                  hintText: 'ex: 12 ou A-1',
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: setsCtrl,
                      decoration: const InputDecoration(labelText: 'Séries'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: repsCtrl,
                      decoration: const InputDecoration(labelText: 'Reps'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              TextField(
                controller: weightCtrl,
                decoration: const InputDecoration(labelText: 'Carga (kg)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Link YouTube (Opcional)',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Imagens',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Image Picker Area
              StatefulBuilder(
                builder: (context, setStateDialog) {
                  return Column(
                    children: [
                      if (tempImagePaths.isNotEmpty)
                        SizedBox(
                          height: 100,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: tempImagePaths.asMap().entries.map((
                                entry,
                              ) {
                                final i = entry.key;
                                final path = entry.value;
                                return Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      width: 100,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: FileImage(File(path)),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setStateDialog(() {
                                          tempImagePaths.removeAt(i);
                                        });
                                      },
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final picker = ImagePicker();
                              final List<XFile> images = await picker
                                  .pickMultiImage();
                              if (images.isNotEmpty) {
                                setStateDialog(() {
                                  tempImagePaths.addAll(
                                    images.map((e) => e.path),
                                  );
                                });
                              }
                            },
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Galeria'),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.camera,
                              );
                              if (image != null) {
                                setStateDialog(() {
                                  tempImagePaths.add(image.path);
                                });
                              }
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Câmera'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _exercises[index] = Exercise(
                  name: nameCtrl.text,
                  sets: int.tryParse(setsCtrl.text) ?? 0,
                  reps: int.tryParse(repsCtrl.text) ?? 0,
                  weight: double.tryParse(weightCtrl.text) ?? 0,
                  youtubeUrl: urlCtrl.text.isEmpty ? null : urlCtrl.text,
                  imagePaths: tempImagePaths,
                  equipmentNumber: equipCtrl.text.isEmpty
                      ? null
                      : equipCtrl.text,
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
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
                  title: Text(ex.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${ex.sets} x ${ex.reps} - ${ex.weight}kg'),
                      if (ex.equipmentNumber != null)
                        Text(
                          'Equipamento: ${ex.equipmentNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
