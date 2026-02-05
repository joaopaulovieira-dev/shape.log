import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/user_profile.dart';
import '../models/user_profile_hive_model.dart';

class UserProfileRepository {
  static const String boxName = 'user_profile';

  Future<Box<UserProfileHiveModel>> _openBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<UserProfileHiveModel>(boxName);
    }
    return Hive.box<UserProfileHiveModel>(boxName);
  }

  Future<void> saveProfile(UserProfile profile) async {
    final box = await _openBox();
    final model = UserProfileHiveModel.fromEntity(profile);
    // We only need one profile, so we can use a fixed key 'current_user'
    await box.put('current_user', model);
  }

  Future<UserProfile?> getProfile() async {
    final box = await _openBox();
    final model = box.get('current_user');
    return model?.toEntity();
  }

  Future<void> deleteProfile() async {
    final box = await _openBox();
    await box.delete('current_user');
  }
}
