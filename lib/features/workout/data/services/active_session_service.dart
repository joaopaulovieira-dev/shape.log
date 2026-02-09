import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/exercise_set_history.dart';
import '../models/exercise_set_history_hive_model.dart';

final activeSessionServiceProvider = Provider((ref) => ActiveSessionService());

class ActiveSessionService {
  static const String _keyWorkoutId = 'active_session_workout_id';
  static const String _keyExerciseIndex = 'active_session_exercise_index';
  static const String _keyStartTime = 'active_session_start_time';
  static const String _keySetsRecords = 'active_session_sets_records';
  static const String _keyCompletedExercises =
      'active_session_completed_exercises';

  Future<void> saveSession({
    required String workoutId,
    required int exerciseIndex,
    required DateTime startTime,
    required Map<String, List<ExerciseSetHistory>> setsRecords,
    required Set<String> completedExerciseNames,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_keyWorkoutId, workoutId);
    await prefs.setInt(_keyExerciseIndex, exerciseIndex);
    await prefs.setString(_keyStartTime, startTime.toIso8601String());

    // Serialize setsRecords
    final setsMap = setsRecords.map((key, value) {
      final list = value
          .map((e) => ExerciseSetHistoryHiveModel.fromEntity(e).toMap())
          .toList();
      return MapEntry(key, list);
    });
    await prefs.setString(_keySetsRecords, jsonEncode(setsMap));

    await prefs.setStringList(
      _keyCompletedExercises,
      completedExerciseNames.toList(),
    );
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyWorkoutId);
    await prefs.remove(_keyExerciseIndex);
    await prefs.remove(_keyStartTime);
    await prefs.remove(_keySetsRecords);
    await prefs.remove(_keyCompletedExercises);
  }

  Future<bool> hasActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyWorkoutId);
  }

  Future<Map<String, dynamic>?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyWorkoutId)) return null;

    final workoutId = prefs.getString(_keyWorkoutId);
    final exerciseIndex = prefs.getInt(_keyExerciseIndex) ?? 0;
    final startTimeStr = prefs.getString(_keyStartTime);
    final setsRecordsStr = prefs.getString(_keySetsRecords);
    final completedExercisesList =
        prefs.getStringList(_keyCompletedExercises) ?? [];

    if (workoutId == null || startTimeStr == null) return null;

    Map<String, List<ExerciseSetHistory>> setsRecords = {};
    if (setsRecordsStr != null) {
      try {
        final decoded = jsonDecode(setsRecordsStr) as Map<String, dynamic>;
        setsRecords = decoded.map((key, value) {
          final list = (value as List).map((e) {
            return ExerciseSetHistoryHiveModel.fromMap(
              e as Map<String, dynamic>,
            ).toEntity();
          }).toList();
          return MapEntry(key, list);
        });
      } catch (e) {
        // Handle corruption
        print('Error decoding sets records: $e');
      }
    }

    return {
      'workoutId': workoutId,
      'exerciseIndex': exerciseIndex,
      'startTime': DateTime.parse(startTimeStr),
      'setsRecords': setsRecords,
      'completedExerciseNames': completedExercisesList.toSet(),
    };
  }
}
