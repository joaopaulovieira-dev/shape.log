import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Versão definida aqui como fonte de verdade para a web (debug e release).
/// Atualizar junto com pubspec.yaml.
const String kAppVersion = '1.4.0';

final appVersionProvider = FutureProvider<String>((ref) async {
  if (kIsWeb) return kAppVersion;
  try {
    final info = await PackageInfo.fromPlatform();
    return info.version.isNotEmpty ? info.version : kAppVersion;
  } catch (_) {
    return kAppVersion;
  }
});
