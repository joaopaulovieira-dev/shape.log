import 'dart:io';
import 'package:flutter/material.dart';
import '../../../image_library/presentation/image_source_sheet.dart';
import '../../domain/entities/exercise.dart';

class ExerciseFormPage extends StatefulWidget {
  final Exercise? initialExercise;

  const ExerciseFormPage({super.key, this.initialExercise});

  @override
  State<ExerciseFormPage> createState() => _ExerciseFormPageState();
}

class _ExerciseFormPageState extends State<ExerciseFormPage> {
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

  ExerciseTypeEntity _selectedType = ExerciseTypeEntity.weight;
  late TextEditingController _cardioDurationController;
  late TextEditingController _cardioIntensityController;

  @override
  void initState() {
    super.initState();
    final ex = widget.initialExercise;
    _selectedType = ex?.type ?? ExerciseTypeEntity.weight;
    _nameController = TextEditingController(text: ex?.name ?? '');

    // Weight specific
    _setsController = TextEditingController(text: ex?.sets.toString() ?? '3');
    _repsController = TextEditingController(text: ex?.reps.toString() ?? '10');
    _weightController = TextEditingController(
      text: ex?.weight.toString() ?? '0',
    );

    // Cardio specific
    _cardioDurationController = TextEditingController(
      text: ex?.cardioDurationMinutes?.toString() ?? '30',
    );
    _cardioIntensityController = TextEditingController(
      text: ex?.cardioIntensity ?? '',
    );

    _urlController = TextEditingController(text: ex?.youtubeUrl ?? '');
    _equipController = TextEditingController(text: ex?.equipmentNumber ?? '');
    _techniqueController = TextEditingController(text: ex?.technique ?? '');
    _restTime = ex?.restTimeSeconds ?? 60;
    _imagePaths = ex != null ? List.from(ex.imagePaths) : [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _cardioDurationController.dispose();
    _cardioIntensityController.dispose();
    _urlController.dispose();
    _equipController.dispose();
    _techniqueController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final exercise = Exercise(
      name: _nameController.text,
      type: _selectedType,
      // Common fields
      youtubeUrl: _urlController.text.isEmpty ? null : _urlController.text,
      imagePaths: _imagePaths,
      equipmentNumber: _equipController.text.isEmpty
          ? null
          : _equipController.text,
      technique: _techniqueController.text.isEmpty
          ? null
          : _techniqueController.text,
      isCompleted: widget.initialExercise?.isCompleted ?? false,
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

    Navigator.pop(context, exercise);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialExercise == null
              ? 'Novo Exercício'
              : 'Editar Exercício',
        ),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type Selector
            SegmentedButton<ExerciseTypeEntity>(
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
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Exercício',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Informe um nome' : null,
            ),
            const SizedBox(height: 16),

            if (_selectedType == ExerciseTypeEntity.weight) ...[
              // WEIGHT INPUTS
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
            ] else ...[
              // CARDIO INPUTS
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller:
                          _setsController, // Reuse sets for Cardio? Or maybe hide it? User req: "sets: 1"
                      decoration: const InputDecoration(
                        labelText: 'Séries (Tiros?)',
                        border: OutlineInputBorder(),
                        helperText: 'Geralmente 1',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cardioDurationController,
                      decoration: const InputDecoration(
                        labelText: 'Tempo (min)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cardioIntensityController,
                decoration: const InputDecoration(
                  labelText: 'Intensidade / Velocidade',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: 8-10km/h ou Moderado',
                ),
              ),
            ],

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
                hintText: 'ex: Postura ereta...',
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
