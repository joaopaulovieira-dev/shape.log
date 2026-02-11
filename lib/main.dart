import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'features/workout/data/models/workout_hive_model.dart';
import 'features/workout/data/models/workout_history_hive_model.dart';
import 'features/workout/data/models/exercise_model.dart';
import 'features/workout/data/models/workout_enums_adapter.dart';
import 'features/workout/data/models/exercise_set_history_hive_model.dart';
import 'features/body_tracker/data/models/body_measurement_hive_model.dart';
import 'features/profile/data/models/user_profile_hive_model.dart';

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
  Hive.registerAdapter(BodyMeasurementHiveModelAdapter());
  Hive.registerAdapter(UserProfileHiveModelAdapter());
  Hive.registerAdapter(ExerciseTypeAdapter());
  Hive.registerAdapter(ExerciseSetHistoryHiveModelAdapter());

  // Open Box
  try {
    await Hive.openBox<WorkoutHiveModel>('routines');
    await Hive.openBox<WorkoutHistoryHiveModel>('history_log');
    await Hive.openBox<BodyMeasurementHiveModel>('body_measurements');
    await Hive.openBox<UserProfileHiveModel>('user_profile');
    await Hive.openBox('settings');
  } catch (e) {
    // If opening fails (e.g. schema mismatch), delete boxes and try again
    try {
      await Hive.deleteBoxFromDisk('routines');
      await Hive.deleteBoxFromDisk('history_log');
      await Hive.deleteBoxFromDisk('body_measurements');
      await Hive.deleteBoxFromDisk('user_profile');
      await Hive.deleteBoxFromDisk('settings');
    } catch (_) {}
    await Hive.openBox<WorkoutHiveModel>('routines');
    await Hive.openBox<WorkoutHistoryHiveModel>('history_log');
    await Hive.openBox<BodyMeasurementHiveModel>('body_measurements');
    await Hive.openBox<UserProfileHiveModel>('user_profile');
    await Hive.openBox('settings');
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
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Shape.log',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFFCCFF00),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFCCFF00), // Neon Green
          secondary: Color(0xFFCCFF00),
          surface: Color(0xFF121212),
          onPrimary: Colors.black, // Text on neon green
          onSurface: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF121212),
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Color(0xFFCCFF00)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFCCFF00),
            foregroundColor: Colors.black, // Text color
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF121212),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCCFF00), width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
          hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Color(0xFFCCFF00),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF121212),
          contentTextStyle: TextStyle(color: Colors.white),
          actionTextColor: Color(0xFFCCFF00),
          behavior: SnackBarBehavior.floating,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFCCFF00),
          foregroundColor: Colors.black,
        ),
      ),
      routerConfig: router,
    );
  }
}
