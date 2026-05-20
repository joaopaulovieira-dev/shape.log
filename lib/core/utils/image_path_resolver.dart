import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImagePathResolver {
  static String? _documentsDirectoryPath;

  /// Inicializa o diretório de documentos para que a resolução seja síncrona.
  static Future<void> init() async {
    if (kIsWeb) return;
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

  /// Retorna o ImageProvider correto.
  /// Para URLs remotas usa CachedNetworkImageProvider (persiste offline).
  /// Para paths locais usa FileImage.
  static ImageProvider resolveToImageProvider(String pathString) {
    if (isRemote(pathString)) {
      if (kIsWeb) return NetworkImage(pathString);
      return CachedNetworkImageProvider(pathString);
    }
    if (kIsWeb) {
      // Retorna uma imagem GIF de 1x1 pixel transparente em memória para evitar erros na Web
      return MemoryImage(
        Uint8List.fromList(const [
          0x47,
          0x49,
          0x46,
          0x38,
          0x39,
          0x61,
          0x01,
          0x00,
          0x01,
          0x00,
          0x80,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0xff,
          0xff,
          0xff,
          0x21,
          0xf9,
          0x04,
          0x01,
          0x00,
          0x00,
          0x00,
          0x00,
          0x2c,
          0x00,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x01,
          0x00,
          0x00,
          0x02,
          0x02,
          0x44,
          0x01,
          0x00,
          0x3b,
        ]),
      );
    }
    return FileImage(resolveToFile(pathString));
  }
}

/// Widget unificado para carregar imagens locais e remotas.
/// URLs remotas usam cache persistente (disponível offline após 1ª carga).
class AppCachedImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final Widget? errorWidget;

  const AppCachedImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (!ImagePathResolver.isRemote(path)) {
      // Imagem local — FileImage padrão
      return Image.file(
        ImagePathResolver.resolveToFile(path),
        fit: fit,
        errorBuilder: (ctx, e, s) =>
            errorWidget ?? const _ImageFallback(),
      );
    }

    if (kIsWeb) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (ctx, e, s) =>
            errorWidget ?? const _ImageFallback(),
      );
    }

    // Imagem remota no mobile — cache persistente
    return CachedNetworkImage(
      imageUrl: path,
      fit: fit,
      placeholder: (ctx, url) => const _ImagePlaceholder(),
      errorWidget: (ctx, url, e) =>
          errorWidget ?? const _ImageFallback(),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();
  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF1A1A1A),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFCCFF00),
            ),
          ),
        ),
      );
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();
  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF1A1A1A),
        child: const Icon(Icons.fitness_center,
            color: Color(0xFFCCFF00), size: 24),
      );
}
