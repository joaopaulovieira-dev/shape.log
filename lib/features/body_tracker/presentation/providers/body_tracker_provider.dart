import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/body_measurement_hive_model.dart';
import '../../data/repositories/body_tracker_repository.dart';
import '../../domain/entities/body_measurement.dart';

// Access the Hive Box
final bodymeasurementsBoxProvider = Provider<Box<BodyMeasurementHiveModel>>((
  ref,
) {
  return Hive.box<BodyMeasurementHiveModel>('body_measurements');
});

// Access the Repository
final bodyTrackerRepositoryProvider = Provider<BodyTrackerRepository>((ref) {
  final box = ref.watch(bodymeasurementsBoxProvider);
  return BodyTrackerRepository(box);
});

// Notifier to manage the list of measurements
class BodyTrackerNotifier extends Notifier<List<BodyMeasurement>> {
  late BodyTrackerRepository _repository;

  @override
  List<BodyMeasurement> build() {
    _repository = ref.watch(bodyTrackerRepositoryProvider);
    return _repository.getAllMeasurements();
  }

  Future<void> addMeasurement(BodyMeasurement measurement) async {
    await _repository.saveMeasurement(measurement);
    state = _repository.getAllMeasurements();
  }

  Future<void> deleteMeasurement(String id) async {
    await _repository.deleteMeasurement(id);
    state = _repository.getAllMeasurements();
  }
}

// Provider for the list of measurements
final bodyTrackerProvider =
    NotifierProvider<BodyTrackerNotifier, List<BodyMeasurement>>(() {
      return BodyTrackerNotifier();
    });
