import '../entities/body_measurement.dart';

abstract class BodyTrackerRepository {
  Future<void> saveMeasurement(BodyMeasurement measurement);
  Future<void> deleteMeasurement(String id);
  List<BodyMeasurement> getAllMeasurements();
  /// Busca assíncrona — necessária na web onde não há box local em memória.
  Future<List<BodyMeasurement>> fetchAll();
}
