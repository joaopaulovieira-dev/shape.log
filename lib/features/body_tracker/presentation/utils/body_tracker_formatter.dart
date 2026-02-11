import 'package:intl/intl.dart';
import '../../domain/entities/body_measurement.dart';
import 'bmi_utils.dart';

class BodyTrackerFormatter {
  static String formatSummary(List<BodyMeasurement> measurements) {
    if (measurements.isEmpty) return "Sem dados para gerar relatório.";

    // Sort to ensure order
    final sorted = List<BodyMeasurement>.from(measurements)
      ..sort((a, b) => a.date.compareTo(b.date));

    final first = sorted.first;
    final last = sorted.last;
    final previous = sorted.length > 1 ? sorted[sorted.length - 2] : null;

    final dateFormat = DateFormat('dd/MM/yyyy');

    final weightDiff = last.weight - first.weight;
    final muscleDiff = (last.muscleMassKg != null && first.muscleMassKg != null)
        ? last.muscleMassKg! - first.muscleMassKg!
        : 0.0;
    final fatDiff = (last.fatPercentage != null && first.fatPercentage != null)
        ? last.fatPercentage! - first.fatPercentage!
        : 0.0;

    final sb = StringBuffer();
    sb.writeln("[🤖 Shape.log AI Context: Análise de Progresso Geral]");
    sb.writeln(
      "Instrução: Atue como um treinador e nutricionista experiente. Analise o progresso total do aluno desde o início até agora e forneça insights sobre a evolução da composição corporal.",
    );
    sb.writeln("");
    sb.writeln(
      "📅 Período: ${dateFormat.format(first.date)} até ${dateFormat.format(last.date)}",
    );
    sb.writeln("");
    sb.writeln("📊 Resumo da Evolução:");
    sb.writeln(
      "- Peso Total: ${last.weight}kg (${weightDiff >= 0 ? '+' : ''}${weightDiff.toStringAsFixed(1)}kg)",
    );
    if (first.muscleMassKg != null) {
      sb.writeln(
        "- Massa Muscular: ${last.muscleMassKg?.toStringAsFixed(1)}kg (${muscleDiff >= 0 ? '+' : ''}${muscleDiff.toStringAsFixed(1)}kg)",
      );
    }
    if (first.fatPercentage != null) {
      sb.writeln(
        "- Gordura Corporal: ${last.fatPercentage?.toStringAsFixed(1)}% (${fatDiff >= 0 ? '+' : ''}${fatDiff.toStringAsFixed(1)}%)",
      );
    }
    sb.writeln("");
    sb.writeln("📋 Última Medição (${dateFormat.format(last.date)}):");
    sb.write(_formatMeasurementDetails(last, previous));

    return sb.toString();
  }

  static String formatMeasurement(
    BodyMeasurement measurement, {
    BodyMeasurement? previous,
  }) {
    final sb = StringBuffer();
    sb.writeln("[🤖 Shape.log AI Context: Análise Pontual]");
    sb.writeln(
      "Instrução: Analise esta medição específica. Se houver dados anteriores, compare para identificar tendências de curto prazo. Sugira ajustes se necessário.",
    );
    sb.writeln("");
    sb.write(_formatMeasurementDetails(measurement, previous));
    return sb.toString();
  }

  static String _formatMeasurementDetails(
    BodyMeasurement current,
    BodyMeasurement? previous,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final sb = StringBuffer();

    // Contexto Básico
    sb.writeln("Data: ${dateFormat.format(current.date)}");

    // Peso e Variação
    String weightLine = "Peso: ${current.weight}kg";
    if (previous != null) {
      final diff = current.weight - previous.weight;
      weightLine +=
          " (Var: ${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}kg)";
    }
    sb.writeln(weightLine);

    // IMC
    if (current.bmi != null) {
      sb.writeln(
        "IMC: ${current.bmi!.toStringAsFixed(1)} (${BMIUtils.getBMIGrade(current.bmi)})",
      );
    }

    // Composição Corporal
    sb.writeln("\n🧬 Composição Corporal:");
    if (current.fatPercentage != null)
      sb.writeln("- Gordura: ${current.fatPercentage!.toStringAsFixed(1)}%");
    if (current.muscleMassKg != null)
      sb.writeln(
        "- Massa Muscular: ${current.muscleMassKg!.toStringAsFixed(1)}kg",
      );
    if (current.visceralFat != null)
      sb.writeln("- Gordura Visceral: ${current.visceralFat}");
    if (current.bmr != null)
      sb.writeln("- Taxa Metabólica Basal: ${current.bmr} kcal");
    if (current.bodyAge != null)
      sb.writeln("- Idade Corporal: ${current.bodyAge} anos");

    // Medidas
    sb.writeln("\n📏 Circunferências:");
    sb.writeln("- Cintura: ${current.waistCircumference}cm");
    sb.writeln("- Peitoral: ${current.chestCircumference}cm");
    if (current.hipsCircumference != null)
      sb.writeln("- Quadril: ${current.hipsCircumference}cm");

    sb.writeln(
      "- Braços: Dir ${current.bicepsRight}cm | Esq ${current.bicepsLeft}cm",
    );

    if (current.thighRight != null || current.thighLeft != null) {
      sb.writeln(
        "- Coxas: Dir ${current.thighRight ?? '-'}cm | Esq ${current.thighLeft ?? '-'}cm",
      );
    }

    if (current.calvesRight != null || current.calvesLeft != null) {
      sb.writeln(
        "- Panturrilhas: Dir ${current.calvesRight ?? '-'}cm | Esq ${current.calvesLeft ?? '-'}cm",
      );
    }

    if (current.shoulders != null)
      sb.writeln("- Ombros: ${current.shoulders}cm");
    if (current.neck != null) sb.writeln("- Pescoço: ${current.neck}cm");

    // Bioimpedância Segmentada
    if (current.muscleLeftArm != null ||
        current.muscleRightArm != null ||
        current.muscleLeftLeg != null ||
        current.muscleRightLeg != null) {
      sb.writeln("\n💪 Massa Muscular Segmentada:");
      if (current.muscleLeftArm != null)
        sb.writeln(
          "- Braço Esq: ${current.muscleLeftArm}kg | Dir: ${current.muscleRightArm}kg",
        );
      if (current.muscleLeftLeg != null)
        sb.writeln(
          "- Perna Esq: ${current.muscleLeftLeg}kg | Dir: ${current.muscleRightLeg}kg",
        );
      if (current.subcutaneousFat != null)
        sb.writeln("- Gordura Subcutânea: ${current.subcutaneousFat}%");
    }

    if (current.reportUrl != null && current.reportUrl!.isNotEmpty) {
      sb.writeln("\n🔗 Relatório Completo: ${current.reportUrl}");
    }

    if (current.notes.isNotEmpty) {
      sb.writeln("\n📝 Notas: ${current.notes}");
    }

    return sb.toString();
  }
}
