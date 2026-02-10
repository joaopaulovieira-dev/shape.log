import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';

class ImageStorageService {
  static const String _subDirName = 'workout_photos';

  Future<String> saveImage(XFile imageFile) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(path.join(docsDir.path, _subDirName));

    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final String fileName = path.basename(imageFile.path);
    // Ensure unique name to avoid conflicts if needed, or trust UUIDs from picker
    final String uniqueName =
        '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final String permanentPath = path.join(photosDir.path, uniqueName);

    await imageFile.saveTo(permanentPath);
    return permanentPath;
  }

  Future<void> deleteImage(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<List<String>> saveImages(List<XFile> images) async {
    List<String> savedPaths = [];
    for (var image in images) {
      final savedPath = await saveImage(image);
      savedPaths.add(savedPath);
    }
    return savedPaths;
  }
}
