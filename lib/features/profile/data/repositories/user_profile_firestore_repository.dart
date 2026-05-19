import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../models/user_profile_hive_model.dart';

class UserProfileFirestoreRepository implements UserProfileRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get _ref =>
      _firestore.collection('users').doc(_userId);

  @override
  Future<void> saveProfile(UserProfile profile) async {
    if (_userId == null) return;
    final model = UserProfileHiveModel.fromEntity(profile);
    await _ref.set(model.toMap(), SetOptions(merge: true));
  }

  @override
  Future<UserProfile?> getProfile() async {
    if (_userId == null) return null;
    final snap = await _ref.get();
    if (!snap.exists || snap.data() == null) return null;
    return UserProfileHiveModel.fromMap(snap.data()!).toEntity();
  }

  @override
  Future<void> deleteProfile() async {
    if (_userId == null) return;
    await _ref.delete();
  }
}
