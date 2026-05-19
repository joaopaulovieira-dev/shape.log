import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../../data/repositories/user_profile_firestore_repository.dart';
import '../../../../core/services/sync_service.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  if (kIsWeb) {
    return UserProfileFirestoreRepository();
  }
  final syncService = ref.watch(syncServiceProvider);
  return UserProfileHiveRepository(syncService);
});

// Notifier
class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  UserProfileRepository get _repository =>
      ref.read(userProfileRepositoryProvider);

  @override
  Future<UserProfile?> build() async {
    return await _repository.getProfile();
  }

  Future<void> saveProfile(UserProfile profile) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.saveProfile(profile);
      return profile;
    });
  }
}

// Notifier Provider
final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(
      UserProfileNotifier.new,
    );
