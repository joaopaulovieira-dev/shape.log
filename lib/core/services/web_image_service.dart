import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class WebImageService {
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Abre o seletor de arquivo do browser, faz upload para Firebase Storage
  /// e retorna a URL pública de download. Retorna null se cancelado ou falhar.
  ///
  /// Cada chamada gera um path único via UUID para evitar colisões — essencial
  /// quando múltiplos exercícios são criados sem ID definitivo ainda.
  static Future<String?> pickAndUpload(String folder) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.single.bytes == null) return null;

      final bytes = result.files.single.bytes!;
      final uid = _uid ?? 'unknown';
      // UUID garante path único por upload — evita sobrescrita entre exercícios
      final uniqueName = const Uuid().v4();
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/$uid/$folder/$uniqueName.png');
      await ref.putData(bytes);
      return await ref.getDownloadURL();
    } catch (e) {
      print('WebImageService.pickAndUpload error: $e');
      return null;
    }
  }

  /// Folders padrão por tipo de entidade
  static const String folderExercises = 'exercises';
  static const String folderMeasurements = 'measurements';
  static const String folderHistory = 'history';
}
