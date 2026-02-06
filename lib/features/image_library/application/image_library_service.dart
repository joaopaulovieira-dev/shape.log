import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImageLibraryService {
  Future<String> get _libraryPath async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final libraryDir = Directory(path.join(appDocDir.path, 'image_library'));
    if (!await libraryDir.exists()) {
      await libraryDir.create(recursive: true);
    }
    return libraryDir.path;
  }

  Future<int> importZip(File zipFile) async {
    final libraryPath = await _libraryPath;
    int importedCount = 0;

    try {
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        if (file.isFile) {
          final filename = file.name;
          // Filter for image extensions if needed, for now accept all files in zip
          // or strictly check for jpg/png/jpeg.
          final lowerName = filename.toLowerCase();
          if (lowerName.endsWith('.jpg') ||
              lowerName.endsWith('.jpeg') ||
              lowerName.endsWith('.png') ||
              lowerName.endsWith('.webp')) {
            final outputStream = OutputFileStream(
              path.join(libraryPath, filename),
            );
            file.writeContent(outputStream);
            outputStream.close();
            importedCount++;
          }
        }
      }
    } catch (e) {
      // Handle or rethrow error
      print('Error importing zip: $e');
      rethrow;
    }

    return importedCount;
  }

  Future<List<File>> getLibraryImages() async {
    final libraryPath = await _libraryPath;
    final dir = Directory(libraryPath);
    if (!await dir.exists()) {
      return [];
    }

    final List<File> images = [];
    await for (final entity in dir.list()) {
      if (entity is File) {
        final lowerName = path.basename(entity.path).toLowerCase();
        if (lowerName.endsWith('.jpg') ||
            lowerName.endsWith('.jpeg') ||
            lowerName.endsWith('.png') ||
            lowerName.endsWith('.webp')) {
          images.add(entity);
        }
      }
    }

    // Sort alphabetically by filename
    images.sort((a, b) {
      return path
          .basename(a.path)
          .toLowerCase()
          .compareTo(path.basename(b.path).toLowerCase());
    });

    return images;
  }

  Future<void> deleteImage(File image) async {
    if (await image.exists()) {
      await image.delete();
    }
  }
}

final imageLibraryServiceProvider = Provider<ImageLibraryService>((ref) {
  return ImageLibraryService();
});

final libraryImagesProvider = FutureProvider<List<File>>((ref) async {
  final service = ref.watch(imageLibraryServiceProvider);
  return service.getLibraryImages();
});
