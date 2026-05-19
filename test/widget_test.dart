// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:shape_log/main.dart';
import 'package:shape_log/core/services/auth_service.dart';
import 'package:shape_log/core/services/sync_service.dart';
import 'package:shape_log/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:shape_log/features/profile/data/repositories/user_profile_repository.dart';
import 'package:shape_log/features/profile/domain/entities/user_profile.dart';

class MockAuthService implements AuthService {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  Future<UserCredential?> signInWithGoogle() async => null;

  @override
  Future<void> signOut() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSyncService implements SyncService {
  @override
  Future<void> enableOfflinePersistence() async {}

  @override
  Future<void> uploadLocalDataToFirestore() async {}

  @override
  Future<void> downloadDataFromFirestore() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUserProfileRepository implements UserProfileRepository {
  @override
  Future<UserProfile?> getProfile() async => null;

  @override
  Future<void> saveProfile(UserProfile profile) async {}

  @override
  Future<void> deleteProfile() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app with mocked providers and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService()),
          syncServiceProvider.overrideWithValue(MockSyncService()),
          userProfileRepositoryProvider.overrideWithValue(MockUserProfileRepository()),
        ],
        child: const ShapeLogApp(),
      ),
    );

    // Verify that our app starts and shows the title in Splash screen.
    expect(find.text('Shape.log'), findsOneWidget);

    // Fast-forward past the splash duration (3.5 seconds)
    await tester.pumpAndSettle(const Duration(milliseconds: 4000));

    // Verify that we are on the Welcome screen now, showing login options
    expect(find.text('ENTRAR COM O GOOGLE'), findsOneWidget);
    expect(find.text('USAR MODO CONVIDADO (OFFLINE)'), findsOneWidget);
  });
}
