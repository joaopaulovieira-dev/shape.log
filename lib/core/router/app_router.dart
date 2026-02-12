import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shape_log/core/constants/app_colors.dart';
import '../../features/dashboard/home_page.dart';
import '../../features/workout/presentation/pages/workout_list_page.dart';
import '../../features/workout/presentation/pages/workout_edit_page.dart';
import '../../features/workout/presentation/pages/workout_details_page.dart';
import '../../features/workout/presentation/pages/exercise_details_page.dart';
import '../../features/workout/presentation/pages/exercise_edit_page.dart';
import '../../features/body_tracker/domain/entities/body_measurement.dart';
import '../../features/body_tracker/presentation/pages/body_tracker_page.dart';
import '../../features/body_tracker/presentation/pages/body_measurement_entry_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/splash/presentation/pages/welcome_page.dart';
import '../../features/workout/presentation/pages/workout_session_page.dart';
import '../../features/workout/domain/entities/workout.dart';
import '../../features/reports/presentation/pages/reports_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithBottomNavBar(child: child);
        },
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/workouts',
            builder: (context, state) => const WorkoutListPage(),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const WorkoutEditPage(),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) =>
                    WorkoutDetailsPage(workoutId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        WorkoutEditPage(workoutId: state.pathParameters['id']),
                  ),
                  GoRoute(
                    path: 'exercises/:exerciseIndex',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final workoutId = state.pathParameters['id']!;
                      final index = int.parse(
                        state.pathParameters['exerciseIndex']!,
                      );
                      return ExerciseDetailsPage(
                        workoutId: workoutId,
                        exerciseIndex: index,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) {
                          final workoutId = state.pathParameters['id']!;
                          final index = int.parse(
                            state.pathParameters['exerciseIndex']!,
                          );
                          return ExerciseEditPage(
                            workoutId: workoutId,
                            exerciseIndex: index,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/body-tracker',
            builder: (context, state) => const BodyTrackerPage(),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  // Check if an object was passed for editing
                  final measurement = state.extra as BodyMeasurement?;
                  return BodyMeasurementEntryPage(
                    measurementToEdit: measurement,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) {
              return const ReportsPage();
            },
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/profile/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfilePage(isFirstRun: true),
      ),
      GoRoute(
        path: '/session',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final workout = state.extra as Workout;
          return WorkoutSessionPage(workout: workout);
        },
      ),
    ],
  );
});

class ScaffoldWithBottomNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithBottomNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _calculateSelectedIndex(context),
          onTap: (int idx) => _onItemTapped(idx, context),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.black, // Dark background
          selectedItemColor: AppColors.primary, // Neon Green
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Início', // Renamed from Home
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_outlined),
              activeIcon: Icon(Icons.fitness_center),
              label: 'Treinos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.monitor_weight_outlined),
              activeIcon: Icon(Icons.monitor_weight),
              label: 'Medidas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assessment_outlined),
              activeIcon: Icon(Icons.assessment),
              label: 'Hub', // Renamed from Relatórios
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/workouts')) {
      return 1;
    }
    if (location.startsWith('/body-tracker')) {
      return 2;
    }
    if (location.startsWith('/reports')) {
      return 3;
    }
    if (location.startsWith('/settings')) {
      return 4;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/');
        break;
      case 1:
        GoRouter.of(context).go('/workouts');
        break;
      case 2:
        GoRouter.of(context).go('/body-tracker');
        break;
      case 3:
        GoRouter.of(context).go('/reports');
        break;
      case 4:
        GoRouter.of(context).go('/settings');
        break;
    }
  }
}
