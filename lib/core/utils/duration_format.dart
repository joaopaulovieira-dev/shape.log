/// Formata uma duração de cardio em minutos (double) para exibição legível.
/// Exemplos:
///   0.5   → "30s"
///   1.0   → "1min"
///   1.5   → "1min 30s"
///   30.0  → "30min"
String formatCardioDuration(double? minutes) {
  if (minutes == null || minutes <= 0) return '0s';
  final totalSeconds = (minutes * 60).round();
  final mins = totalSeconds ~/ 60;
  final secs = totalSeconds % 60;
  if (mins == 0) return '${secs}s';
  if (secs == 0) return '${mins}min';
  return '${mins}min ${secs}s';
}
