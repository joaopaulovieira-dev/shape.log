import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class WebImageService {
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Abre o seletor de arquivo do browser, faz upload para Firebase Storage
  /// e retorna a URL pública de download. Retorna null se cancelado ou falhar.
  static Future<String?> pickAndUpload(String storagePath) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.single.bytes == null) return null;

      final bytes = result.files.single.bytes!;
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      await ref.putData(bytes);
      return await ref.getDownloadURL();
    } catch (e) {
      print('WebImageService.pickAndUpload error: $e');
      return null;
    }
  }

  /// Gera um storagePath padrão para imagem de exercício.
  static String exercisePath(String exerciseId, int index) {
    final uid = _uid ?? 'unknown';
    return 'users/$uid/exercises/${exerciseId}_$index.png';
  }

  /// Gera um storagePath padrão para imagem de medida corporal.
  static String measurementPath(String measurementId, int index) {
    final uid = _uid ?? 'unknown';
    return 'users/$uid/measurements/${measurementId}_$index.png';
  }

  /// Gera um storagePath padrão para foto de perfil.
  static String profilePicturePath() {
    final uid = _uid ?? 'unknown';
    return 'users/$uid/profile_picture.png';
  }

  /// Gera um storagePath padrão para imagem de histórico.
  static String historyPath(String historyId, int index) {
    final uid = _uid ?? 'unknown';
    return 'users/$uid/history/${historyId}_$index.png';
  }
}
