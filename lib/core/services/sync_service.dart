import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive_ce/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/image_path_resolver.dart';

import '../../features/workout/data/models/workout_hive_model.dart';
import '../../features/workout/data/models/workout_history_hive_model.dart';
import '../../features/body_tracker/data/models/body_measurement_hive_model.dart';
import '../../features/profile/data/models/user_profile_hive_model.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Habilitar persistência offline nativa do Firestore
  Future<void> enableOfflinePersistence() async {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Enviar todos os dados locais do Hive para o Firestore (Merge pós-login)
  Future<void> uploadLocalDataToFirestore() async {
    final userId = _userId;
    if (userId == null) return;

    final routinesBox = Hive.box<WorkoutHiveModel>('routines');
    final historyBox = Hive.box<WorkoutHistoryHiveModel>('history_log');
    final measurementsBox = Hive.box<BodyMeasurementHiveModel>(
      'body_measurements',
    );
    final profileBox = Hive.box<UserProfileHiveModel>('user_profile');

    final batch = _firestore.batch();

    // 1. Sincronizar Perfil
    if (profileBox.isNotEmpty) {
      final profile = profileBox.values.first;

      // Upload da foto de perfil se for um arquivo local
      String? remoteProfilePictureUrl = profile.profilePicturePath;
      if (profile.profilePicturePath != null &&
          !profile.profilePicturePath!.startsWith('http')) {
        remoteProfilePictureUrl = await uploadFile(
          profile.profilePicturePath!,
          'profile_picture.png',
        );
      }

      final profileDoc = _firestore.collection('users').doc(userId);
      batch.set(profileDoc, {
        ...profile.toMap(),
        'profilePicturePath': remoteProfilePictureUrl,
      }, SetOptions(merge: true));
    }

    // 2. Sincronizar Treinos (Routines)
    for (var workout in routinesBox.values) {
      final workoutDoc = _firestore
          .collection('users')
          .doc(userId)
          .collection('workouts')
          .doc(workout.id);
      batch.set(workoutDoc, workout.toMap(), SetOptions(merge: true));
    }

    // 3. Sincronizar Histórico
    for (var history in historyBox.values) {
      // Tratar imagens do histórico de treino
      List<String> remoteImagePaths = [];
      if (history.imagePaths != null) {
        for (var i = 0; i < history.imagePaths!.length; i++) {
          final localPath = history.imagePaths![i];
          if (localPath.startsWith('http')) {
            remoteImagePaths.add(localPath);
          } else {
            final remoteUrl = await uploadFile(
              localPath,
              'history/${history.id}_$i.png',
            );
            if (remoteUrl != null) remoteImagePaths.add(remoteUrl);
          }
        }
      }

      final historyDoc = _firestore
          .collection('users')
          .doc(userId)
          .collection('history')
          .doc(history.id);

      batch.set(historyDoc, {
        ...history.toMap(),
        'imagePaths': remoteImagePaths,
      }, SetOptions(merge: true));
    }

    // 4. Sincronizar Medidas Corporais
    for (var measurement in measurementsBox.values) {
      // Tratar imagens da medida
      List<String> remoteImagePaths = [];
      for (var i = 0; i < measurement.imagePaths.length; i++) {
        final localPath = measurement.imagePaths[i];
        if (localPath.startsWith('http')) {
          remoteImagePaths.add(localPath);
        } else {
          final remoteUrl = await uploadFile(
            localPath,
            'measurements/${measurement.id}_$i.png',
          );
          if (remoteUrl != null) remoteImagePaths.add(remoteUrl);
        }
      }

      final measurementDoc = _firestore
          .collection('users')
          .doc(userId)
          .collection('measurements')
          .doc(measurement.id);

      batch.set(measurementDoc, {
        ...measurement.toMap(),
        'imagePaths': remoteImagePaths,
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  // Baixar dados do Firestore para o Hive local (Restore após login em novo dispositivo)
  Future<void> downloadDataFromFirestore() async {
    final userId = _userId;
    if (userId == null) return;

    final routinesBox = Hive.box<WorkoutHiveModel>('routines');
    final historyBox = Hive.box<WorkoutHistoryHiveModel>('history_log');
    final measurementsBox = Hive.box<BodyMeasurementHiveModel>(
      'body_measurements',
    );
    final profileBox = Hive.box<UserProfileHiveModel>('user_profile');

    // 1. Baixar Perfil
    final profileSnap = await _firestore.collection('users').doc(userId).get();
    if (profileSnap.exists && profileSnap.data() != null) {
      await profileBox.clear();
      final model = UserProfileHiveModel.fromMap(profileSnap.data()!);
      await profileBox.add(model);
    }

    // 2. Baixar Treinos (Workouts)
    final workoutsSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .get();
    if (workoutsSnap.docs.isNotEmpty) {
      await routinesBox.clear();
      for (var doc in workoutsSnap.docs) {
        final model = WorkoutHiveModel.fromMap(doc.data());
        await routinesBox.put(model.id, model);
      }
    }

    // 3. Baixar Histórico
    final historySnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('history')
        .get();
    if (historySnap.docs.isNotEmpty) {
      await historyBox.clear();
      for (var doc in historySnap.docs) {
        final model = WorkoutHistoryHiveModel.fromMap(doc.data());
        await historyBox.put(model.id, model);
      }
    }

    // 4. Baixar Medidas
    final measurementsSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('measurements')
        .get();
    if (measurementsSnap.docs.isNotEmpty) {
      await measurementsBox.clear();
      for (var doc in measurementsSnap.docs) {
        final model = BodyMeasurementHiveModel.fromMap(doc.data());
        await measurementsBox.put(model.id, model);
      }
    }
  }

  // Salvar/Atualizar item individualmente (Firestore espelha em tempo real com fila offline)
  Future<void> saveWorkout(WorkoutHiveModel workout) async {
    final userId = _userId;
    if (userId == null) return;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workout.id)
        .set(workout.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteWorkout(String id) async {
    final userId = _userId;
    if (userId == null) return;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(id)
        .delete();
  }

  Future<void> saveHistory(WorkoutHistoryHiveModel history) async {
    final userId = _userId;
    if (userId == null) return;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('history')
        .doc(history.id)
        .set(history.toMap(), SetOptions(merge: true));
  }

  Future<void> saveMeasurement(BodyMeasurementHiveModel measurement) async {
    final userId = _userId;
    if (userId == null) return;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('measurements')
        .doc(measurement.id)
        .set(measurement.toMap(), SetOptions(merge: true));
  }

  Future<void> saveProfile(UserProfileHiveModel profile) async {
    final userId = _userId;
    if (userId == null) return;
    await _firestore
        .collection('users')
        .doc(userId)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  // Upload genérico de arquivo local para o Firebase Storage
  Future<String?> uploadFile(String localPath, String storagePath) async {
    final file = ImagePathResolver.resolveToFile(localPath);
    if (!file.existsSync()) return null;

    try {
      final userId = _userId;
      if (userId == null) return null;

      final ref = _storage.ref().child('users/$userId/$storagePath');
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Erro ao enviar arquivo para o Storage: $e');
      return null;
    }
  }
}

// Provider do Riverpod
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});
