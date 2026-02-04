import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  List<String> _imagePaths = [];

  @override
  void initState() {
    super.initState();
    final ex = widget.initialExercise;
    _nameController = TextEditingController(text: ex?.name ?? '');
    _setsController = TextEditingController(text: ex?.sets.toString() ?? '3');
    _repsController = TextEditingController(text: ex?.reps.toString() ?? '10');
    _weightController = TextEditingController(
      text: ex?.weight.toString() ?? '0',
    );
    _urlController = TextEditingController(text: ex?.youtubeUrl ?? '');
    _equipController = TextEditingController(text: ex?.equipmentNumber ?? '');
    _techniqueController = TextEditingController(text: ex?.technique ?? '');
    _imagePaths = ex != null ? List.from(ex.imagePaths) : [];
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

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final exercise = Exercise(
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
      isCompleted: widget.initialExercise?.isCompleted ?? false,
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
                hintText: 'ex: Drop-set na última série...',
              ),
              maxLines: 3,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final List<XFile> images = await picker.pickMultiImage();
                    if (images.isNotEmpty) {
                      setState(() {
                        _imagePaths.addAll(images.map((e) => e.path));
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
                      setState(() {
                        _imagePaths.add(image.path);
                      });
                    }
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Câmera'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
