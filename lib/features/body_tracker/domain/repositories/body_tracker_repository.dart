import '../entities/body_measurement.dart';

abstract class BodyTrackerRepository {
  Future<void> saveMeasurement(BodyMeasurement measurement);
  Future<void> deleteMeasurement(String id);
  List<BodyMeasurement> getAllMeasurements();
}
