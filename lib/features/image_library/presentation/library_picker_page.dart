import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shape_log/features/image_library/application/image_library_service.dart';
import 'package:path/path.dart' as path;

class LibraryPickerPage extends ConsumerStatefulWidget {
  const LibraryPickerPage({super.key});

  @override
  ConsumerState<LibraryPickerPage> createState() => _LibraryPickerPageState();
}

class _LibraryPickerPageState extends ConsumerState<LibraryPickerPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final imagesAsync = ref.watch(libraryImagesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Selecionar Equipamento')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar por nome',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: imagesAsync.when(
              data: (images) {
                final filtered = images.where((file) {
                  final name = path
                      .basenameWithoutExtension(file.path)
                      .toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma imagem encontrada.'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final image = filtered[index];
                    final name = path.basenameWithoutExtension(image.path);

                    return InkWell(
                      onTap: () {
                        Navigator.pop(context, image);
                      },
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Image.file(image, fit: BoxFit.cover),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
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
