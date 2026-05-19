import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/body_measurement.dart';
import '../../domain/repositories/body_tracker_repository.dart';
import '../models/body_measurement_hive_model.dart';

class BodyTrackerFirestoreRepository implements BodyTrackerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _ref => _firestore
      .collection('users')
      .doc(_userId)
      .collection('measurements');

  // Cache em memória para getAllMeasurements() ser síncrono como a versão Hive
  List<BodyMeasurement> _cache = [];
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    if (_userId == null) return;
    final snap = await _ref.orderBy('date', descending: true).get();
    _cache = snap.docs
        .map((d) => BodyMeasurementHiveModel.fromMap(d.data()).toEntity())
        .toList();
    _loaded = true;
  }

  @override
  List<BodyMeasurement> getAllMeasurements() {
    return List.unmodifiable(_cache);
  }

  @override
  Future<List<BodyMeasurement>> fetchAll() async {
    await _ensureLoaded();
    return getAllMeasurements();
  }

  @override
  Future<void> saveMeasurement(BodyMeasurement measurement) async {
    if (_userId == null) return;
    final model = BodyMeasurementHiveModel.fromEntity(measurement);
    await _ref.doc(measurement.id).set(model.toMap(), SetOptions(merge: true));
    // Atualiza cache
    _cache.removeWhere((m) => m.id == measurement.id);
    _cache.insert(0, measurement);
  }

  @override
  Future<void> deleteMeasurement(String id) async {
    if (_userId == null) return;
    await _ref.doc(id).delete();
    _cache.removeWhere((m) => m.id == id);
  }
}
