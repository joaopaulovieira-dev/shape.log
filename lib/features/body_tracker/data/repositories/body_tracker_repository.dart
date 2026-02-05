import 'package:hive/hive.dart';
import '../models/body_measurement_hive_model.dart';
import '../../domain/entities/body_measurement.dart';

class BodyTrackerRepository {
  final Box<BodyMeasurementHiveModel> _box;

  BodyTrackerRepository(this._box);

  Future<void> saveMeasurement(BodyMeasurement measurement) async {
    final hiveModel = BodyMeasurementHiveModel.fromEntity(measurement);
    // Use the ID as the key to make retrieval easier if needed by ID,
    // or just add it. Since we want a list sorted by date, retrieving all values is key.
    await _box.put(measurement.id, hiveModel);
  }

  Future<void> deleteMeasurement(String id) async {
    await _box.delete(id);
  }

  List<BodyMeasurement> getAllMeasurements() {
    final measurements = _box.values.map((e) => e.toEntity()).toList();
    // Sort by date descending (newest first)
    measurements.sort((a, b) => b.date.compareTo(a.date));
    return measurements;
  }
}
