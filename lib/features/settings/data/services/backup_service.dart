import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import '../../../profile/data/models/user_profile_hive_model.dart';
import '../../../workout/data/models/workout_hive_model.dart';
import '../../../workout/data/models/workout_history_hive_model.dart';
import '../../../body_tracker/data/models/body_measurement_hive_model.dart';
import '../repositories/settings_repository.dart';

final backupServiceProvider = Provider((ref) => BackupService(ref));

class BackupService {
  final Ref _ref;

  BackupService(this._ref);

  Future<bool> createFullBackup() async {
    try {
      final now = DateTime.now();
      final directory = await getApplicationDocumentsDirectory();
      final dateStr = DateFormat('dd_MM_yyyy').format(now);
      final timeStr = DateFormat('HH_mm').format(now);
      final fileName = 'shapelog_backup_$dateStr - $timeStr.zip';
      final zipFilePath = '${directory.path}/$fileName';

      final encoder = ZipFileEncoder();
      encoder.create(zipFilePath);

      // 1. Collect Data from Hive
      final profileBox = Hive.box<UserProfileHiveModel>('user_profile');
      final routinesBox = Hive.box<WorkoutHiveModel>('routines');
      final historyBox = Hive.box<WorkoutHistoryHiveModel>('history_log');
      final measurementsBox = Hive.box<BodyMeasurementHiveModel>(
        'body_measurements',
      );

      final Map<String, dynamic> backupData = {
        "version": "1.1",
        "timestamp": now.toIso8601String(),
        "profile":
            profileBox.get('current_user')?.toMap() ??
            (profileBox.isNotEmpty ? profileBox.values.first.toMap() : null),
        "workouts": routinesBox.values.map((e) => e.toMap()).toList(),
        "history": historyBox.values.map((e) => e.toMap()).toList(),
        "measurements": measurementsBox.values.map((e) => e.toMap()).toList(),
      };

      // 2. Process Images and add to ZIP
      final processedFiles = <String>{};

      void processImages(List entities) {
        for (var entity in entities) {
          final List<String> imagePaths = List<String>.from(
            entity['imagePaths'] ?? [],
          );
          final List<String> relativePaths = [];

          for (var originalPath in imagePaths) {
            final file = File(originalPath);
            if (file.existsSync()) {
              final name = p.basename(originalPath);
              if (!processedFiles.contains(name)) {
                encoder.addFile(file, 'images/$name');
                processedFiles.add(name);
              }
              relativePaths.add('images/$name');
            }
          }
          entity['imagePaths'] = relativePaths;
        }
      }

      for (var workout in backupData['workouts']) {
        processImages(workout['exercises']);
      }
      for (var historyEntry in backupData['history']) {
        processImages(historyEntry['exercises']);
      }
      processImages(backupData['measurements']);

      // 3. Process Asset Library
      final libraryDir = Directory('${directory.path}/image_library');
      if (await libraryDir.exists()) {
        final libraryFiles = libraryDir.listSync();
        for (var entity in libraryFiles) {
          if (entity is File) {
            final name = p.basename(entity.path);
            encoder.addFile(entity, 'library/$name');
          }
        }
      }

      // 4. Add JSON data
      final jsonString = jsonEncode(backupData);
      final tempJsonFile = File('${directory.path}/backup_data.json');
      await tempJsonFile.writeAsString(jsonString);
      encoder.addFile(tempJsonFile, 'backup_data.json');

      encoder.close();
      await tempJsonFile.delete();

      // 5. Share
      final result = await Share.shareXFiles([
        XFile(zipFilePath, mimeType: 'application/zip', name: fileName),
      ], subject: 'Shape.log Full Backup - $dateStr $timeStr');

      if (result.status == ShareResultStatus.success) {
        await _ref.read(settingsRepositoryProvider).setLastBackupDate(now);
        return true;
      }
      return false;
    } catch (e) {
      print('Backup error: $e');
      return false;
    }
  }

  Future<bool> restoreFullBackup() async {
    try {
      FilePickerResult? pickResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (pickResult == null) return false;

      final zipFile = File(pickResult.files.single.path!);

      // 1. Decode ZIP using buffer to save memory
      final inputStream = InputFileStream(zipFile.path);
      final archive = ZipDecoder().decodeBuffer(inputStream);

      // 2. Find and Parse JSON
      final jsonFile = archive.findFile('backup_data.json');
      if (jsonFile == null) {
        throw Exception('Arquivo de dados não encontrado no ZIP');
      }

      final jsonString = utf8.decode(jsonFile.content);
      final Map<String, dynamic> data = jsonDecode(jsonString);

      if (double.parse(data['version'] ?? '0') < 1.0) {
        throw Exception('Versão de backup incompatível');
      }

      // 3. Prepare Image Directory
      final appDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${appDir.path}/exercise_images');
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      // 5. Extract Images & Library
      final libraryDir = Directory('${appDir.path}/image_library');
      if (!await libraryDir.exists()) {
        await libraryDir.create(recursive: true);
      }

      final imageMapping = <String, String>{};
      for (final file in archive) {
        if (file.isFile) {
          if (file.name.startsWith('images/')) {
            final fileName = p.basename(file.name);
            final destinationFile = File('${imageDir.path}/$fileName');
            final content = file.content;
            if (content is List<int>) {
              await destinationFile.writeAsBytes(content);
            } else if (content is InputStreamBase) {
              final bytes = content.toUint8List();
              await destinationFile.writeAsBytes(bytes);
            }
            imageMapping[file.name] = destinationFile.path;
          } else if (file.name.startsWith('library/')) {
            final fileName = p.basename(file.name);
            final destinationFile = File('${libraryDir.path}/$fileName');
            final content = file.content;
            if (content is List<int>) {
              await destinationFile.writeAsBytes(content);
            } else if (content is InputStreamBase) {
              final bytes = content.toUint8List();
              await destinationFile.writeAsBytes(bytes);
            }
          }
        }
      }
      inputStream.close();

      // 6. Reconstruct Absolute Paths in JSON
      void fixPaths(List entities) {
        for (var entity in entities) {
          final List<String> currentPaths = List<String>.from(
            entity['imagePaths'] ?? [],
          );
          entity['imagePaths'] = currentPaths
              .map((rel) => imageMapping[rel] ?? rel)
              .toList();
        }
      }

      for (var workout in data['workouts']) {
        fixPaths(workout['exercises']);
      }
      for (var historyEntry in data['history']) {
        fixPaths(historyEntry['exercises']);
      }
      fixPaths(data['measurements']);

      // 6. Persist to Hive
      final settingsRepo = _ref.read(settingsRepositoryProvider);
      await settingsRepo.clearAllBoxes();

      if (data['profile'] != null) {
        final profileBox = Hive.box<UserProfileHiveModel>('user_profile');
        // Use a fixed key for profile to ensure there's only one, matching UserProfileRepository
        await profileBox.put(
          'current_user',
          UserProfileHiveModel.fromMap(data['profile']),
        );
        print('Profile restored successfully into user_profile box.');
      }

      final routinesBox = Hive.box<WorkoutHiveModel>('routines');
      for (var item in (data['workouts'] as List? ?? [])) {
        final model = WorkoutHiveModel.fromMap(item);
        await routinesBox.put(model.id, model);
      }

      final historyBox = Hive.box<WorkoutHistoryHiveModel>('history_log');
      for (var item in (data['history'] as List? ?? [])) {
        final model = WorkoutHistoryHiveModel.fromMap(item);
        await historyBox.put(model.id, model);
      }

      final measurementsBox = Hive.box<BodyMeasurementHiveModel>(
        'body_measurements',
      );
      for (var item in (data['measurements'] as List? ?? [])) {
        final model = BodyMeasurementHiveModel.fromMap(item);
        await measurementsBox.put(model.id, model);
      }

      return true;
    } catch (e) {
      print('Restore error: $e');
      return false;
    }
  }
}
