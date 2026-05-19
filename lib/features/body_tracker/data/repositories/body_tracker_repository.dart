import 'dart:io';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/body_measurement_hive_model.dart';
import '../../domain/entities/body_measurement.dart';

import '../../../../core/services/sync_service.dart';
import '../../domain/repositories/body_tracker_repository.dart';

class BodyTrackerHiveRepository implements BodyTrackerRepository {
  final Box<BodyMeasurementHiveModel> _box;
  final SyncService? _syncService;

  BodyTrackerHiveRepository(this._box, [this._syncService]);

  @override
  Future<void> saveMeasurement(BodyMeasurement measurement) async {
    // handled in the provider or UI, but let's robustify it here.
    // actually, best practice: Logic here.

    // 1. Get App Docs Path
    final directory = await getApplicationDocumentsDirectory();
    final imagesBaseDir = Directory('${directory.path}/body_images');

    if (!await imagesBaseDir.exists()) {
      await imagesBaseDir.create(recursive: true);
    }

    final measurementDir = Directory('${imagesBaseDir.path}/${measurement.id}');
    if (!await measurementDir.exists()) {
      await measurementDir.create(recursive: true);
    }

    List<String> persistentPaths = [];

    for (String path in measurement.imagePaths) {
      final file = File(path);
      if (!file.existsSync()) continue;

      // Check if already in our persistent dir
      if (path.contains(measurementDir.path)) {
        persistentPaths.add(path);
        continue;
      }

      // It's a new or temp file (from picker)
      final fileName = path.split(Platform.pathSeparator).last;
      final newPath = '${measurementDir.path}/$fileName';

      try {
        await file.copy(newPath);
        persistentPaths.add(newPath);
      } catch (e) {
        print("Error copying image: $e");
        // Fallback: keep original path if copy fails?
        // Or skip? detailed logging is better.
      }
    }

    final updatedMeasurement = measurement.copyWith(
      imagePaths: persistentPaths,
    );

    final hiveModel = BodyMeasurementHiveModel.fromEntity(updatedMeasurement);
    await _box.put(updatedMeasurement.id, hiveModel);
    if (_syncService != null) {
      await _syncService.saveMeasurement(hiveModel);
    }
  }

  @override
  Future<void> deleteMeasurement(String id) async {
    final directory = await getApplicationDocumentsDirectory();
    final measurementDir = Directory('${directory.path}/body_images/$id');

    if (await measurementDir.exists()) {
      await measurementDir.delete(recursive: true);
    }

    await _box.delete(id);

    if (_syncService != null) {
      await _syncService.deleteMeasurement(id);
    }
  }

  @override
  List<BodyMeasurement> getAllMeasurements() {
    final measurements = _box.values.map((e) => e.toEntity()).toList();
    // Sort by date descending (newest first)
    measurements.sort((a, b) => b.date.compareTo(a.date));
    return measurements;
  }
}
