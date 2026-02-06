import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_log/features/image_library/application/image_library_service.dart';
import 'package:path/path.dart' as path;

class ImageLibrarySettingsPage extends ConsumerStatefulWidget {
  const ImageLibrarySettingsPage({super.key});

  @override
  ConsumerState<ImageLibrarySettingsPage> createState() =>
      _ImageLibrarySettingsPageState();
}

class _ImageLibrarySettingsPageState
    extends ConsumerState<ImageLibrarySettingsPage> {
  Future<void> _pickAndImportZip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      try {
        final count = await ref
            .read(imageLibraryServiceProvider)
            .importZip(file);

        // Refresh the list
        ref.invalidate(libraryImagesProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$count imagens importadas com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao importar: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagesAsync = ref.watch(libraryImagesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca de Ativos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickAndImportZip,
                icon: const Icon(Icons.folder_zip),
                label: const Text('Importar Pacote de Imagens (ZIP)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          Expanded(
            child: imagesAsync.when(
              data: (images) {
                if (images.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma imagem na biblioteca.'),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final image = images[index];
                    return GridTile(
                      footer: GridTileBar(
                        backgroundColor: Colors.black54,
                        title: Text(
                          path.basenameWithoutExtension(image.path),
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      child: Image.file(image, fit: BoxFit.cover),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Erro: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
