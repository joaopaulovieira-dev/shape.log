import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_history.dart';
import '../../domain/repositories/workout_repository.dart';
import '../models/workout_hive_model.dart';
import '../models/workout_history_hive_model.dart';

class WorkoutFirestoreDataSource implements WorkoutRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _workoutsRef => _firestore
      .collection('users')
      .doc(_userId)
      .collection('workouts');

  CollectionReference<Map<String, dynamic>> get _historyRef => _firestore
      .collection('users')
      .doc(_userId)
      .collection('history');

  @override
  Future<List<Workout>> getRoutines() async {
    if (_userId == null) return [];
    final snap = await _workoutsRef.get();
    return snap.docs
        .map((d) => WorkoutHiveModel.fromMap(d.data()).toEntity())
        .toList();
  }

  @override
  Future<void> saveRoutine(Workout workout) async {
    if (_userId == null) return;
    final stamped = workout.copyWith(updatedAt: DateTime.now().toUtc());
    final model = WorkoutHiveModel.fromEntity(stamped);
    await _workoutsRef.doc(workout.id).set(model.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteRoutine(String id) async {
    if (_userId == null) return;
    await _workoutsRef.doc(id).delete();
  }

  @override
  Future<List<WorkoutHistory>> getHistory() async {
    if (_userId == null) return [];
    final snap = await _historyRef.orderBy('completedDate', descending: true).get();
    return snap.docs
        .map((d) => WorkoutHistoryHiveModel.fromMap(d.data()).toEntity())
        .toList();
  }

  @override
  Future<void> saveHistory(WorkoutHistory history) async {
    if (_userId == null) return;
    final model = WorkoutHistoryHiveModel.fromEntity(history);
    await _historyRef.doc(history.id).set(model.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteHistory(String id) async {
    if (_userId == null) return;
    await _historyRef.doc(id).delete();
  }
}
