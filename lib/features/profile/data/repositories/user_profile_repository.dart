import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../../../../core/services/sync_service.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../models/user_profile_hive_model.dart';

class UserProfileHiveRepository implements UserProfileRepository {
  static const String boxName = 'user_profile';
  final SyncService? _syncService;

  UserProfileHiveRepository([this._syncService]);

  Future<Box<UserProfileHiveModel>> _openBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<UserProfileHiveModel>(boxName);
    }
    return Hive.box<UserProfileHiveModel>(boxName);
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    final box = await _openBox();
    final model = UserProfileHiveModel.fromEntity(profile);
    // We only need one profile, so we can use a fixed key 'current_user'
    await box.put('current_user', model);
    if (_syncService != null) {
      _syncService.saveProfile(model);
    }
  }

  @override
  Future<UserProfile?> getProfile() async {
    final box = await _openBox();
    final model = box.get('current_user');
    return model?.toEntity();
  }

  @override
  Future<void> deleteProfile() async {
    final box = await _openBox();
    await box.delete('current_user');
  }
}
