import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImagePathResolver {
  static String? _documentsDirectoryPath;

  /// Inicializa o diretório de documentos para que a resolução seja síncrona.
  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _documentsDirectoryPath = dir.path;
  }

  /// Resolve caminhos de arquivo locais no iOS/Android, ajustando o diretório
  /// do Container da aplicação caso mude (comportamento padrão do iOS a cada build/update).
  static String resolve(String pathString) {
    if (pathString.isEmpty) return pathString;

    // Se for uma URL web ou Firebase Storage (http/https/gs), retorna sem alterar
    if (pathString.startsWith('http://') ||
        pathString.startsWith('https://') ||
        pathString.startsWith('gs://')) {
      return pathString;
    }

    // Se contiver o marcador '/Documents/' (iOS) ou '/app_flutter/' (Android/iOS)
    final documentsMarker = '/Documents/';
    final appFlutterMarker = '/app_flutter/';

    String? relativePath;
    if (pathString.contains(documentsMarker)) {
      relativePath = pathString.substring(
        pathString.indexOf(documentsMarker) + documentsMarker.length,
      );
    } else if (pathString.contains(appFlutterMarker)) {
      relativePath = pathString.substring(
        pathString.indexOf(appFlutterMarker) + appFlutterMarker.length,
      );
    }

    if (relativePath != null && _documentsDirectoryPath != null) {
      return p.join(_documentsDirectoryPath!, relativePath);
    }

    return pathString;
  }

  /// Retorna um objeto File com o caminho resolvido.
  static File resolveToFile(String pathString) {
    return File(resolve(pathString));
  }

  /// Retorna true se o path é uma URL remota (Firebase Storage, http, etc.)
  static bool isRemote(String pathString) {
    return pathString.startsWith('http://') ||
        pathString.startsWith('https://') ||
        pathString.startsWith('gs://');
  }

  /// Retorna o ImageProvider correto: NetworkImage para URLs, FileImage para locais.
  static ImageProvider resolveToImageProvider(String pathString) {
    if (isRemote(pathString)) return NetworkImage(pathString);
    return FileImage(resolveToFile(pathString));
  }
}
