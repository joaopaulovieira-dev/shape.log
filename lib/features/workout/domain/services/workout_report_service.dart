import 'package:intl/intl.dart';
import 'package:shape_log/features/body_tracker/domain/entities/body_measurement.dart';
import '../../../../features/profile/domain/entities/user_profile.dart';
import 'package:shape_log/features/workout/domain/entities/exercise.dart';
import '../entities/workout_history.dart';

class WorkoutReportService {
  String generateGeneralReport(
    List<WorkoutHistory> history,
    List<BodyMeasurement> measurements,
    UserProfile? user,
  ) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('dd/MM/yyyy');

    // 1. Cabecalho
    buffer.writeln('📋 *Dossiê Geral de Treinamento e Físico*');
    buffer.writeln('Gerado em: ${dateFormat.format(DateTime.now())}');
    if (user != null) {
      buffer.writeln('Atleta: ${user.name}');
      buffer.writeln('Altura: ${user.height} cm');
      if (user.weight != null) buffer.writeln('Peso Atual: ${user.weight} kg');
    }
    buffer.writeln('');

    // 2. Resumo de Treinos Recentes (Ultimos 5)
    final recentWorkouts = history.length > 5
        ? history.take(5).toList()
        : history;
    buffer.writeln('🏋️ *Últimos 5 Treinos*');
    if (recentWorkouts.isEmpty) {
      buffer.writeln('Nenhum treino registrado recentemente.');
    } else {
      for (final h in recentWorkouts) {
        buffer.writeln(
          '- ${dateFormat.format(h.completedDate)}: ${h.workoutName} (${h.durationMinutes} min) - RPE: ${h.rpe ?? "N/A"}',
        );
      }
    }
    buffer.writeln('');

    // 3. Evolução Corporal
    buffer.writeln('📏 *Evolução Corporal (Últimas Medições)*');
    final recentMeasurements = measurements.length > 5
        ? measurements.take(5).toList()
        : measurements;
    if (recentMeasurements.isEmpty) {
      buffer.writeln('Nenhuma medição registrada.');
    } else {
      for (final m in recentMeasurements) {
        buffer.writeln(
          '- ${dateFormat.format(m.date)}: ${m.weight}kg, BF: ${m.bodyFatPercentage ?? "N/A"}%',
        );
      }
    }
    buffer.writeln('');

    // 4. Prompt para IA
    buffer.writeln('🤖 *Instruções para Análise (IA)*');
    buffer.writeln(
      'Analise este macrociclo. Identifique padrões de frequência, se há sobrecarga progressiva nos treinos recentes e correlacione com a evolução do peso corporal. Sugira ajustes na dieta ou treino se houver estagnação.',
    );

    return buffer.toString();
  }

  String generateClipboardReport(WorkoutHistory history, UserProfile? user) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('dd/MM/yyyy - HH:mm');

    buffer.writeln('RELATÓRIO DE TREINO - SHAPE.LOG');
    buffer.writeln('-------------------------------------');

    if (user != null) {
      buffer.writeln(
        'PERFIL: ${user.name}, ${user.age} anos, ${user.targetWeight}kg (meta)',
      );
    } else {
      buffer.writeln('PERFIL: Usuário não identificado');
    }

    buffer.writeln('DATA: ${dateFormat.format(history.completedDate)}');
    buffer.writeln('TREINO: ${history.workoutName}');
    buffer.writeln('DURAÇÃO: ${history.durationMinutes} min');

    final rpe = history.rpe;
    String rpeEmoji = '';
    if (rpe != null) {
      if (rpe <= 2) {
        rpeEmoji = '🟢 (Fácil)';
      } else if (rpe <= 3)
        rpeEmoji = '🟡 (Moderado)';
      else if (rpe <= 4)
        rpeEmoji = '🟠 (Difícil)';
      else
        rpeEmoji = '🔴 (Exaustivo)';
    }
    buffer.writeln('INTENSIDADE (RPE 1-5): ${rpe ?? "N/A"} $rpeEmoji');

    buffer.writeln('-------------------------------------');
    buffer.writeln('DETALHAMENTO:');
    buffer.writeln('');

    int index = 1;
    for (final exercise in history.exercises) {
      buffer.writeln('$index. ${exercise.name}');
      if (exercise.sets > 0 || exercise.reps > 0) {
        buffer.writeln(
          '   Meta: ${exercise.sets} séries x ${exercise.reps} reps',
        );
      }

      final sets = exercise.setsHistory;
      if (sets != null && sets.isNotEmpty) {
        for (final set in sets) {
          String warmupLabel = set.isWarmup ? ' (Aquecimento)' : '';
          buffer.writeln(
            '   > Série ${set.setNumber}: ${set.weight}kg x ${set.reps} reps$warmupLabel',
          );
        }
      } else {
        // Fallback for old history without granular sets
        buffer.writeln(
          '   > Registro simplificado: ${exercise.weight}kg x ${exercise.reps} reps',
        );
      }
      buffer.writeln('');
      index++;
    }

    buffer.writeln('-------------------------------------');
    buffer.writeln(
      'OBS: Gere uma análise sobre progressão de carga e sugira ajustes para o próximo treino.',
    );

    return buffer.toString();
  }

  String generateDetailedReport(WorkoutHistory history, UserProfile? user) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('dd/MM/yyyy - HH:mm');

    buffer.writeln('RELATÓRIO DE TREINO - SHAPE.LOG');
    buffer.writeln('-------------------------------------');

    if (user != null) {
      buffer.writeln(
        'PERFIL: ${user.name}, ${user.age} anos, ${user.targetWeight}kg (meta)',
      );
    } else {
      buffer.writeln('PERFIL: Usuário não identificado');
    }

    buffer.writeln('DATA: ${dateFormat.format(history.completedDate)}');
    buffer.writeln('TREINO: ${history.workoutName}');
    buffer.writeln('DURAÇÃO: ${history.durationMinutes} min');

    final rpe = history.rpe;
    String rpeEmoji = '';
    if (rpe != null) {
      if (rpe <= 2) {
        rpeEmoji = '🟢 (Fácil)';
      } else if (rpe <= 3) {
        rpeEmoji = '🟡 (Moderado)';
      } else if (rpe <= 4) {
        rpeEmoji = '🟠 (Difícil)';
      } else {
        rpeEmoji = '🔴 (Exaustivo)';
      }
    }
    buffer.writeln('INTENSIDADE (RPE 1-5): ${rpe ?? "N/A"} $rpeEmoji');

    buffer.writeln('-------------------------------------');
    buffer.writeln('DETALHAMENTO:');
    buffer.writeln('');

    int index = 1;
    for (final exercise in history.exercises) {
      buffer.writeln('$index. ${exercise.name}');

      if (exercise.type == ExerciseTypeEntity.cardio) {
        // Cardio Formatting
        buffer.writeln('   Tempo: ${exercise.cardioDurationMinutes ?? 0} min');
        if (exercise.cardioIntensity != null &&
            exercise.cardioIntensity!.isNotEmpty) {
          buffer.writeln('   Intensidade: ${exercise.cardioIntensity}');
        }
      } else {
        // Weight Training Formatting
        if (exercise.sets > 0 || exercise.reps > 0) {
          buffer.writeln(
            '   Meta: ${exercise.sets} séries x ${exercise.reps} reps',
          );
        }

        final sets = exercise.setsHistory;
        if (sets != null && sets.isNotEmpty) {
          for (final set in sets) {
            String warmupLabel = set.isWarmup ? ' (Aquecimento)' : '';
            buffer.writeln(
              '   > Série ${set.setNumber}: ${set.weight}kg x ${set.reps} reps$warmupLabel',
            );
          }
        } else {
          // Fallback
          buffer.writeln(
            '   > Registro simplificado: ${exercise.weight}kg x ${exercise.reps} reps',
          );
        }
      }

      // Common: Rest Time
      if (exercise.restTimeSeconds > 0) {
        buffer.writeln('   Descanso: ${exercise.restTimeSeconds}s');
      }

      buffer.writeln('');
      index++;
    }

    buffer.writeln('-------------------------------------');
    // No generic footer instructions as requested

    return buffer.toString();
  }
}
