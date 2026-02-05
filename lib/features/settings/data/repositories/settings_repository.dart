import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../profile/data/models/user_profile_hive_model.dart';
import '../../../workout/data/models/workout_hive_model.dart';
import '../../../workout/data/models/workout_history_hive_model.dart';
import '../../../body_tracker/data/models/body_measurement_hive_model.dart';

final settingsRepositoryProvider = Provider((ref) => SettingsRepository());

class SettingsRepository {
  static const String _settingsBoxName = 'settings';
  static const String _lastBackupKey = 'last_backup_date';

  final Box _box = Hive.box(_settingsBoxName);

  DateTime? getLastBackupDate() {
    final String? dateStr = _box.get(_lastBackupKey);
    if (dateStr == null) return null;
    return DateTime.parse(dateStr);
  }

  Future<void> setLastBackupDate(DateTime date) async {
    await _box.put(_lastBackupKey, date.toIso8601String());
  }

  Future<void> clearAllBoxes() async {
    if (Hive.isBoxOpen('user_profile')) {
      await Hive.box<UserProfileHiveModel>('user_profile').clear();
    }
    if (Hive.isBoxOpen('routines')) {
      await Hive.box<WorkoutHiveModel>('routines').clear();
    }
    if (Hive.isBoxOpen('history_log')) {
      await Hive.box<WorkoutHistoryHiveModel>('history_log').clear();
    }
    if (Hive.isBoxOpen('body_measurements')) {
      await Hive.box<BodyMeasurementHiveModel>('body_measurements').clear();
    }
  }
}
