import 'package:riverpod/riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_profile.dart';
import '../../data/repositories/user_profile_repository.dart';

import '../../../../core/services/sync_service.dart';

// Repository Provider
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return UserProfileRepository(syncService);
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
