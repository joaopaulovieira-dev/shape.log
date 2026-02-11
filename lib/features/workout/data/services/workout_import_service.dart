import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/workout_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout.dart';

final workoutImportServiceProvider = Provider(
  (ref) => WorkoutImportService(ref),
);

class WorkoutImportService {
  final Ref _ref;
  final _uuid = const Uuid();

  WorkoutImportService(this._ref);

  Future<int?> importFromFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return null;
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      return importFromText(jsonString);
    } catch (e) {
      debugPrint('Erro na importação por arquivo: $e');
      rethrow;
    }
  }

  Future<int?> importFromText(String jsonText) async {
    try {
      final dynamic jsonData = jsonDecode(jsonText);

      List<dynamic> workoutsJson = [];
      if (jsonData is Map<String, dynamic> &&
          jsonData.containsKey('workouts')) {
        workoutsJson = jsonData['workouts'];
      } else if (jsonData is List) {
        workoutsJson = jsonData;
      } else {
        throw const FormatException('Formato de JSON inválido');
      }

      return _parseAndSaveWorkouts(workoutsJson);
    } catch (e) {
      debugPrint('Erro na importação por texto: $e');
      rethrow;
    }
  }

  Future<int> _parseAndSaveWorkouts(List<dynamic> workoutsJson) async {
    int count = 0;
    final workoutRepository = _ref.read(workoutRepositoryProvider);

    for (var workoutData in workoutsJson) {
      if (workoutData is! Map<String, dynamic>) continue;

      final List<Exercise> exercises = [];
      final exercisesData = workoutData['exercises'] as List? ?? [];

      for (var exData in exercisesData) {
        if (exData is! Map<String, dynamic>) continue;

        final typeStr = exData['type'] as String?;
        final type = typeStr == 'cardio'
            ? ExerciseTypeEntity.cardio
            : ExerciseTypeEntity.weight;

        exercises.add(
          Exercise(
            name: exData['name'] ?? 'Exercício sem nome',
            type: type,
            sets: _toInt(exData['sets']),
            // Cardio: durationMinutes replaces reps
            // Weight: reps
            reps: type == ExerciseTypeEntity.weight
                ? _toInt(exData['reps'])
                : 0,
            cardioDurationMinutes: type == ExerciseTypeEntity.cardio
                ? (_toDouble(exData['durationMinutes'] ?? exData['reps']))
                : null,
            // Cardio: intensity replaces weight
            // Weight: weight
            weight: type == ExerciseTypeEntity.weight
                ? _toDouble(exData['weight'])
                : 0.0,
            cardioIntensity: type == ExerciseTypeEntity.cardio
                ? (exData['intensity'] as String? ??
                      exData['weight']?.toString())
                : null,

            youtubeUrl: exData['youtubeUrl'],
            imagePaths:
                const [], // Sanitização: limpar caminhos de imagem externos
            equipmentNumber: exData['equipmentNumber'],
            technique: exData['technique'],
            isCompleted: false,
            restTimeSeconds: _toInt(
              exData['restTime'] ?? exData['restSeconds'] ?? 60,
            ),
          ),
        );
      }

      final workout = Workout(
        id: _uuid.v4(), // Gerar NOVO UUID
        name: workoutData['name'] ?? 'Novo Treino Importado',
        scheduledDays: List<int>.from(workoutData['scheduledDays'] ?? []),
        targetDurationMinutes: _toInt(workoutData['targetDurationMinutes']),
        notes: workoutData['notes'] ?? '',
        exercises: exercises,
        activeStartTime: null, // Sanitização: treino nunca realizado
        expiryDate: workoutData['expiryDate'] != null
            ? DateTime.tryParse(workoutData['expiryDate'])
            : null,
      );

      await workoutRepository.saveRoutine(workout);
      count++;
    }

    // Invalida o provider para atualizar a lista na UI
    _ref.invalidate(routineListProvider);

    return count;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      // Tentar pegar o primeiro número se for um range como "10-12"
      final match = RegExp(r'\d+').firstMatch(value);
      if (match != null) {
        return int.tryParse(match.group(0)!) ?? 0;
      }
    }
    return 0;
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
