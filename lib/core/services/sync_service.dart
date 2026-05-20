import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive_ce/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../utils/image_path_resolver.dart';

import '../../features/workout/data/models/workout_hive_model.dart';
import '../../features/workout/data/models/exercise_model.dart';
import '../../features/workout/data/models/workout_history_hive_model.dart';
import '../../features/body_tracker/data/models/body_measurement_hive_model.dart';
import '../../features/profile/data/models/user_profile_hive_model.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  /// Retorna true se há um usuário autenticado (Firebase/Google)
  bool get isUserAuthenticated => _auth.currentUser != null;

  // Habilitar persistência offline nativa do Firestore
  Future<void> enableOfflinePersistence() async {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Envia um batch com no máximo [_batchLimit] writes e retorna um novo batch.
  static const int _batchLimit = 400;

  Future<WriteBatch> _commitAndRenew(WriteBatch batch, int count) async {
    if (count > 0 && count % _batchLimit == 0) {
      await batch.commit();
      return _firestore.batch();
    }
    return batch;
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

    // 1. Perfil
    if (profileBox.isNotEmpty) {
      try {
        final profile = profileBox.values.first;
        String? remoteProfilePictureUrl = profile.profilePicturePath;
        if (profile.profilePicturePath != null &&
            !profile.profilePicturePath!.startsWith('http')) {
          remoteProfilePictureUrl = await uploadFile(
            profile.profilePicturePath!,
            'profile_picture.png',
          );
        }
        await _firestore.collection('users').doc(userId).set({
          ...profile.toMap(),
          'profilePicturePath': remoteProfilePictureUrl,
        }, SetOptions(merge: true));
      } catch (e) {
        print('Sync: erro ao salvar perfil: $e');
      }
    }

    // 2. Treinos (cada batch independente para não misturar com outros dados)
    try {
      var batch = _firestore.batch();
      int count = 0;
      for (var workout in routinesBox.values) {
        final updatedWorkout = await _uploadWorkoutImages(workout);
        final doc = _firestore
            .collection('users')
            .doc(userId)
            .collection('workouts')
            .doc(updatedWorkout.id);
        batch.set(doc, updatedWorkout.toMap(), SetOptions(merge: true));
        count++;
        batch = await _commitAndRenew(batch, count);
      }
      if (count % _batchLimit != 0) await batch.commit();
      print('Sync: ${routinesBox.length} treinos salvos no Firestore.');
    } catch (e) {
      print('Sync: erro ao salvar treinos: $e');
    }

    // 3. Histórico
    try {
      var batch = _firestore.batch();
      int count = 0;
      for (var history in historyBox.values) {
        List<String> remoteImagePaths = [];
        if (history.imagePaths != null) {
          for (var i = 0; i < history.imagePaths!.length; i++) {
            final localPath = history.imagePaths![i];
            if (localPath.startsWith('http')) {
              remoteImagePaths.add(localPath);
            } else {
              final url = await uploadFile(
                localPath,
                'history/${history.id}_$i.png',
              );
              if (url != null) remoteImagePaths.add(url);
            }
          }
        }
        final doc = _firestore
            .collection('users')
            .doc(userId)
            .collection('history')
            .doc(history.id);
        batch.set(doc, {
          ...history.toMap(),
          'imagePaths': remoteImagePaths,
        }, SetOptions(merge: true));
        count++;
        batch = await _commitAndRenew(batch, count);
      }
      if (count % _batchLimit != 0) await batch.commit();
      print('Sync: ${historyBox.length} históricos salvos no Firestore.');
    } catch (e) {
      print('Sync: erro ao salvar histórico: $e');
    }

    // 4. Medidas Corporais
    try {
      var batch = _firestore.batch();
      int count = 0;
      for (var measurement in measurementsBox.values) {
        List<String> remoteImagePaths = [];
        for (var i = 0; i < measurement.imagePaths.length; i++) {
          final localPath = measurement.imagePaths[i];
          if (localPath.startsWith('http')) {
            remoteImagePaths.add(localPath);
          } else {
            final url = await uploadFile(
              localPath,
              'measurements/${measurement.id}_$i.png',
            );
            if (url != null) remoteImagePaths.add(url);
          }
        }
        final doc = _firestore
            .collection('users')
            .doc(userId)
            .collection('measurements')
            .doc(measurement.id);
        batch.set(doc, {
          ...measurement.toMap(),
          'imagePaths': remoteImagePaths,
        }, SetOptions(merge: true));
        count++;
        batch = await _commitAndRenew(batch, count);
      }
      if (count % _batchLimit != 0) await batch.commit();
      print('Sync: ${measurementsBox.length} medidas salvas no Firestore.');
    } catch (e) {
      print('Sync: erro ao salvar medidas: $e');
    }
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

    const timeoutDuration = Duration(seconds: 6);

    // 1. Baixar Perfil
    final profileSnap = await _firestore
        .collection('users')
        .doc(userId)
        .get()
        .timeout(timeoutDuration);
    if (profileSnap.exists && profileSnap.data() != null) {
      await profileBox.clear();
      final model = UserProfileHiveModel.fromMap(profileSnap.data()!);
      await profileBox.put('current_user', model);
    }

    // 2. Baixar Treinos (Workouts)
    final workoutsSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .get()
        .timeout(timeoutDuration);
    // Merge: adiciona/atualiza registros da nuvem sem apagar registros locais
    // que ainda não chegaram ao Firebase (salvo offline).
    for (var doc in workoutsSnap.docs) {
      final model = WorkoutHiveModel.fromMap(doc.data());
      await routinesBox.put(model.id, model);
    }

    // 3. Baixar Histórico (merge)
    final historySnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('history')
        .get()
        .timeout(timeoutDuration);
    for (var doc in historySnap.docs) {
      final model = WorkoutHistoryHiveModel.fromMap(doc.data());
      await historyBox.put(model.id, model);
    }

    // 4. Baixar Medidas (merge)
    final measurementsSnap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('measurements')
        .get()
        .timeout(timeoutDuration);
    for (var doc in measurementsSnap.docs) {
      final model = BodyMeasurementHiveModel.fromMap(doc.data());
      await measurementsBox.put(model.id, model);
    }
  }

  /// Sincronização completa do histórico: substitui o Hive pelo estado atual
  /// do Firebase (inclusive remove registros apagados remotamente).
  /// Usado no pull-to-refresh da tela de logs.
  Future<void> syncHistoryFromFirestore() async {
    final userId = _userId;
    if (userId == null) return;

    final historyBox = Hive.box<WorkoutHistoryHiveModel>('history_log');
    const timeout = Duration(seconds: 10);

    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('history')
        .get()
        .timeout(timeout);

    // IDs que existem no Firebase
    final remoteIds = snap.docs.map((d) => d.id).toSet();

    // Remove do Hive registros que não existem mais no Firebase
    final localIds = historyBox.keys.cast<String>().toSet();
    for (final id in localIds.difference(remoteIds)) {
      await historyBox.delete(id);
    }

    // Adiciona/atualiza com dados do Firebase
    for (final doc in snap.docs) {
      final model = WorkoutHistoryHiveModel.fromMap(doc.data());
      await historyBox.put(model.id, model);
    }
  }

  // Salvar/Atualizar item individualmente (Firestore espelha em tempo real com fila offline)
  Future<void> saveWorkout(WorkoutHiveModel workout) async {
    final userId = _userId;
    if (userId == null) return;
    final updatedWorkout = await _uploadWorkoutImages(workout);
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(updatedWorkout.id)
        .set(updatedWorkout.toMap(), SetOptions(merge: true));
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

  Future<void> deleteHistory(String id) async {
    final userId = _userId;
    if (userId == null) return;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('history')
        .doc(id)
        .delete();
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

  Future<void> deleteMeasurement(String id) async {
    final userId = _userId;
    if (userId == null) return;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('measurements')
        .doc(id)
        .delete();
  }

  Future<void> saveProfile(UserProfileHiveModel profile) async {
    final userId = _userId;
    if (userId == null) return;
    await _firestore
        .collection('users')
        .doc(userId)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  // Sobe toda a image_library local para users/{uid}/library/ no Storage
  Future<void> uploadLibraryToStorage() async {
    final userId = _userId;
    if (userId == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final libraryDir = Directory(p.join(appDir.path, 'image_library'));
    if (!await libraryDir.exists()) return;

    final files = libraryDir.listSync().whereType<File>().toList();
    for (final file in files) {
      try {
        final name = p.basename(file.path);
        final ref = _storage.ref().child('users/$userId/library/$name');
        // putData evita problemas com security-scoped URLs do iOS
        final bytes = await file.readAsBytes();
        await ref.putData(bytes);
      } catch (e) {
        print('Erro ao enviar biblioteca para o Storage: $e');
      }
    }
  }

  // Baixa toda a users/{uid}/library/ do Storage para a image_library local
  Future<void> downloadLibraryFromStorage() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final libraryDir = Directory(p.join(appDir.path, 'image_library'));
      if (!await libraryDir.exists()) {
        await libraryDir.create(recursive: true);
      }

      ListResult listResult;
      try {
        listResult = await _storage
            .ref()
            .child('users/$userId/library')
            .listAll();
      } on FirebaseException catch (e) {
        // Path não existe ainda (usuário novo ou biblioteca vazia no Storage)
        if (e.code == 'object-not-found') return;
        rethrow;
      }

      for (final item in listResult.items) {
        try {
          final localFile = File(p.join(libraryDir.path, item.name));
          if (!await localFile.exists()) {
            final url = await item.getDownloadURL();
            final client = HttpClient();
            final request = await client.getUrl(Uri.parse(url));
            final response = await request.close();
            final bytes = await response.expand((b) => b).toList();
            await localFile.writeAsBytes(bytes);
            client.close();
          }
        } catch (e) {
          print('Erro ao baixar arquivo da biblioteca: $e');
        }
      }
    } catch (e) {
      print('Erro ao baixar biblioteca do Storage: $e');
    }
  }

  Future<WorkoutHiveModel> _uploadWorkoutImages(
    WorkoutHiveModel workout,
  ) async {
    if (kIsWeb) return workout;
    final userId = _userId;
    if (userId == null) return workout;

    List<ExerciseModel> updatedExercises = [];
    bool hasChanges = false;

    for (var exercise in workout.exercises) {
      List<String> remoteImagePaths = [];
      bool exerciseChanged = false;

      for (var i = 0; i < exercise.imagePaths.length; i++) {
        final path = exercise.imagePaths[i];
        if (ImagePathResolver.isRemote(path)) {
          remoteImagePaths.add(path);
        } else {
          // Nome seguro do arquivo para evitar caracteres incompatíveis no path de Storage
          final safeExerciseName = exercise.name
              .replaceAll(RegExp(r'[^\w\s\-]'), '')
              .trim();
          final filename = 'workouts/${workout.id}/${safeExerciseName}_$i.png';
          final url = await uploadFile(path, filename);
          if (url != null) {
            remoteImagePaths.add(url);
            exerciseChanged = true;
          } else {
            remoteImagePaths.add(path);
          }
        }
      }

      if (exerciseChanged) {
        updatedExercises.add(exercise.copyWith(imagePaths: remoteImagePaths));
        hasChanges = true;
      } else {
        updatedExercises.add(exercise);
      }
    }

    if (hasChanges) {
      final updatedWorkout = workout.copyWith(exercises: updatedExercises);
      final routinesBox = Hive.box<WorkoutHiveModel>('routines');
      await routinesBox.put(updatedWorkout.id, updatedWorkout);
      return updatedWorkout;
    }

    return workout;
  }

  // Upload genérico de arquivo local para o Firebase Storage
  Future<String?> uploadFile(String localPath, String storagePath) async {
    if (kIsWeb) return null;
    final file = ImagePathResolver.resolveToFile(localPath);
    if (!file.existsSync()) return null;

    try {
      final userId = _userId;
      if (userId == null) return null;

      final ref = _storage.ref().child('users/$userId/$storagePath');
      await ref.putFile(file);
      return await ref.getDownloadURL();
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
