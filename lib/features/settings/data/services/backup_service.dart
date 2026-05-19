import 'dart:convert';
import 'dart:io' show File, Directory;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import '../../../profile/data/models/user_profile_hive_model.dart';
import '../../../workout/data/models/workout_hive_model.dart';
import '../../../workout/data/models/workout_history_hive_model.dart';
import '../../../body_tracker/data/models/body_measurement_hive_model.dart';

final backupServiceProvider = Provider((ref) => BackupService(ref));

class BackupAnalysis {
  final Uint8List zipBytes;
  final Map<String, dynamic> metadata;
  final int workoutCount;
  final int historyCount;
  final int measurementCount;
  final int imageCount;

  BackupAnalysis({
    required this.zipBytes,
    required this.metadata,
    required this.workoutCount,
    required this.historyCount,
    required this.measurementCount,
    required this.imageCount,
  });

  DateTime get timestamp => DateTime.parse(metadata['timestamp']);
  String get version => metadata['version'];
}

class BackupService {
  BackupService(Ref ref);

  Future<String?> generateFullBackupZip() async {
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

      // Handle Profile Picture
      if (backupData['profile'] != null &&
          backupData['profile']['profilePicturePath'] != null) {
        final originalPath =
            backupData['profile']['profilePicturePath'] as String;
        final file = File(originalPath);
        if (file.existsSync()) {
          final name = p.basename(originalPath);
          encoder.addFile(file, 'images/$name');
          backupData['profile']['profilePicturePath'] = 'images/$name';
        }
      }

      for (var workout in backupData['workouts']) {
        processImages(workout['exercises']);
      }
      // Process newly added gallery images in history items
      processImages(backupData['history']);
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

      return zipFilePath;
    } catch (e) {
      print('Backup error: $e');
      return null;
    }
  }

  Future<BackupAnalysis?> pickAndAnalyzeBackup() async {
    try {
      FilePickerResult? pickResult = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (pickResult == null) return null;

      // Na web os bytes vêm direto do FilePicker; no mobile lemos do File.
      final Uint8List zipBytes;
      if (kIsWeb) {
        zipBytes = pickResult.files.single.bytes!;
      } else {
        zipBytes = await File(pickResult.files.single.path!).readAsBytes();
      }
      final archive = ZipDecoder().decodeBytes(zipBytes);

      // Contabiliza imagens (library + exercise images)
      int imageCount = 0;
      for (final file in archive) {
        if (file.isFile &&
            (file.name.startsWith('images/') ||
                file.name.startsWith('library/'))) {
          imageCount++;
        }
      }

      // Busca resiliente: tenta pelo path exato primeiro,
      // depois por nome de arquivo (sem depender do path completo)
      ArchiveFile? jsonEntry = archive.findFile('backup_data.json');
      if (jsonEntry == null) {
        final matches = archive.files
            .where((f) => f.isFile && p.basename(f.name) == 'backup_data.json')
            .toList();
        if (matches.isNotEmpty) jsonEntry = matches.first;
      }

      // Compatibilidade com backups antigos (somente library/, sem JSON)
      if (jsonEntry == null) {
        final hasLibraryFiles = archive.files.any(
          (f) => f.isFile && f.name.startsWith('library/'),
        );
        if (hasLibraryFiles) {
          return BackupAnalysis(
            zipBytes: zipBytes,
            metadata: {
              'version': '1.0',
              'timestamp': DateTime.now().toIso8601String(),
              'libraryOnly': true,
            },
            workoutCount: 0,
            historyCount: 0,
            measurementCount: 0,
            imageCount: imageCount,
          );
        }
        throw Exception(
          'Arquivo inválido: nenhum dado de backup encontrado.\n'
          'Arquivos presentes: ${archive.files.map((f) => f.name).join(', ')}',
        );
      }

      final jsonString = utf8.decode(jsonEntry.content as List<int>);
      final Map<String, dynamic> data = jsonDecode(jsonString);

      if (double.parse(data['version'] ?? '0') < 1.0) {
        throw Exception('Versão de backup incompatível.');
      }

      return BackupAnalysis(
        zipBytes: zipBytes,
        metadata: data,
        workoutCount: (data['workouts'] as List?)?.length ?? 0,
        historyCount: (data['history'] as List?)?.length ?? 0,
        measurementCount: (data['measurements'] as List?)?.length ?? 0,
        imageCount: imageCount,
      );
    } catch (e) {
      print('Analysis error: $e');
      rethrow; // Repropaga para o _handleRestore exibir o erro ao usuário
    }
  }

  Future<bool> restoreFromAnalysis(BackupAnalysis analysis) async {
    try {
      final data = analysis.metadata;

      // 1. Decodifica o ZIP a partir dos bytes já lidos no pickAndAnalyzeBackup
      final archive = ZipDecoder().decodeBytes(analysis.zipBytes);

      // 2. Prepara diretório de imagens
      final appDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${appDir.path}/exercise_images');
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      // 3. Extrai imagens e biblioteca
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
            await destinationFile.writeAsBytes(file.content as List<int>);
            imageMapping[file.name] = destinationFile.path;
          } else if (file.name.startsWith('library/')) {
            final fileName = p.basename(file.name);
            final destinationFile = File('${libraryDir.path}/$fileName');
            await destinationFile.writeAsBytes(file.content as List<int>);
          }
        }
      }

      // Se é um backup legado (só library), encerra após extrair as imagens
      final isLibraryOnly = data['libraryOnly'] == true;
      if (isLibraryOnly) {
        print('Backup legado: somente imagens da biblioteca restauradas.');
        return true;
      }

      // Corrige o path da foto de perfil
      if (data['profile'] != null &&
          data['profile']['profilePicturePath'] != null) {
        final relPath = data['profile']['profilePicturePath'] as String;
        if (imageMapping.containsKey(relPath)) {
          data['profile']['profilePicturePath'] = imageMapping[relPath];
        }
      }

      // Reconstrói paths absolutos nas entidades
      void fixPaths(List<dynamic> entities) {
        for (var entity in entities) {
          final List<String> currentPaths = List<String>.from(
            entity['imagePaths'] ?? [],
          );
          entity['imagePaths'] = currentPaths
              .map((rel) => imageMapping[rel] ?? rel)
              .toList();
        }
      }

      final workouts = List<dynamic>.from(data['workouts'] ?? []);
      final history = List<dynamic>.from(data['history'] ?? []);
      final measurements = List<dynamic>.from(data['measurements'] ?? []);

      for (var workout in workouts) {
        fixPaths(List<dynamic>.from(workout['exercises'] ?? []));
      }
      fixPaths(history);
      for (var historyEntry in history) {
        fixPaths(List<dynamic>.from(historyEntry['exercises'] ?? []));
      }
      fixPaths(measurements);

      // 4. Mescla incremental com o Hive (upsert por ID)
      final routinesBox = Hive.box<WorkoutHiveModel>('routines');
      for (var item in workouts) {
        final model = WorkoutHiveModel.fromMap(item as Map<String, dynamic>);
        await routinesBox.put(model.id, model);
      }

      final historyBox = Hive.box<WorkoutHistoryHiveModel>('history_log');
      for (var item in history) {
        final model = WorkoutHistoryHiveModel.fromMap(
          item as Map<String, dynamic>,
        );
        await historyBox.put(model.id, model);
      }

      final measurementsBox = Hive.box<BodyMeasurementHiveModel>(
        'body_measurements',
      );
      for (var item in measurements) {
        final model = BodyMeasurementHiveModel.fromMap(
          item as Map<String, dynamic>,
        );
        await measurementsBox.put(model.id, model);
      }

      // Perfil: só importa do backup se não houver perfil atual
      if (data['profile'] != null) {
        final profileBox = Hive.box<UserProfileHiveModel>('user_profile');
        if (!profileBox.containsKey('current_user')) {
          await profileBox.put(
            'current_user',
            UserProfileHiveModel.fromMap(
              data['profile'] as Map<String, dynamic>,
            ),
          );
          print(
            'Perfil restaurado do backup (nenhum perfil atual encontrado).',
          );
        } else {
          print('Perfil atual mantido. Dados de perfil do backup ignorados.');
        }
      }

      return true;
    } catch (e) {
      print('Restore error: $e');
      return false;
    }
  }
}
