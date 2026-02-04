import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'features/workout/data/models/workout_hive_model.dart';
import 'features/workout/data/models/workout_history_hive_model.dart';
import 'features/workout/data/models/exercise_model.dart';
import 'features/workout/data/models/workout_enums_adapter.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  await Hive.initFlutter();
  await initializeDateFormatting('pt_BR', null);

  // Register Adapters
  Hive.registerAdapter(WorkoutTypeHiveAdapter());
  Hive.registerAdapter(WorkoutStatusHiveAdapter());
  Hive.registerAdapter(ExerciseModelAdapter());
  Hive.registerAdapter(WorkoutHiveModelAdapter());
  Hive.registerAdapter(WorkoutHistoryHiveModelAdapter());

  // Open Box
  try {
    await Hive.openBox<WorkoutHiveModel>('routines');
    await Hive.openBox<WorkoutHistoryHiveModel>('history_log');
  } catch (e) {
    // If opening fails (e.g. schema mismatch), delete boxes and try again
    try {
      await Hive.deleteBoxFromDisk('routines');
      await Hive.deleteBoxFromDisk('history_log');
    } catch (_) {}
    await Hive.openBox<WorkoutHiveModel>('routines');
    await Hive.openBox<WorkoutHistoryHiveModel>('history_log');
  }

  runApp(
    ProviderScope(
      overrides: [
        // We can override here or just use a global access in provider, but override is cleaner if we had the instance.
        // For now, let's keep it simple and access the box via a Provider that reads the opened box,
        // OR passing it to the root widget if we setup DI there.
        // Actually, Riverpod provider can just call Hive.box('workouts') since it's open.
      ],
      child: const ShapeLogApp(),
    ),
  );
}

class ShapeLogApp extends ConsumerWidget {
  const ShapeLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Shape.log',
      debugShowCheckedModeBanner: false,
      theme: appTheme.themeData,
      routerConfig: router,
    );
  }
}
