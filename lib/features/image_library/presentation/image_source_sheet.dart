import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shape_log/features/image_library/presentation/library_picker_page.dart';

class ImageSourceSheet extends StatelessWidget {
  final bool showLibrary;

  const ImageSourceSheet({super.key, this.showLibrary = true});

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    if (source == ImageSource.gallery) {
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty && context.mounted) {
        Navigator.pop(context, images.map((e) => File(e.path)).toList());
      }
    } else {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null && context.mounted) {
        Navigator.pop(context, [File(pickedFile.path)]);
      }
    }
  }

  Future<void> _pickFromLibrary(BuildContext context) async {
    final File? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LibraryPickerPage()),
    );

    if (result != null && context.mounted) {
      Navigator.pop(context, [result]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 250, // Fixed height for 3 options
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Selecionar Imagem',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _OptionButton(
                icon: Icons.camera_alt,
                label: 'Câmera',
                onTap: () => _pickImage(context, ImageSource.camera),
              ),
              _OptionButton(
                icon: Icons.photo_library,
                label: 'Galeria',
                onTap: () => _pickImage(context, ImageSource.gallery),
              ),
              if (showLibrary)
                _OptionButton(
                  icon: Icons.fitness_center, // Icon for equipment/library
                  label: 'Biblioteca',
                  onTap: () => _pickFromLibrary(context),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
