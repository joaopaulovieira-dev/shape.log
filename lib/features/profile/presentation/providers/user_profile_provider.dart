import 'package:riverpod/riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_profile.dart';
import '../../data/repositories/user_profile_repository.dart';

// Repository Provider
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository();
});

// Notifier
class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  late final UserProfileRepository _repository;

  @override
  Future<UserProfile?> build() async {
    _repository = ref.read(userProfileRepositoryProvider);
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
