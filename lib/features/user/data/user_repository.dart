import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import 'user_profile.dart';

class UserRepository {
  UserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _ref(String userId) =>
      _firestore.collection('users').doc(userId);

  /// Called on every sign-in.
  /// Creates a full profile on first login; updates only volatile fields later.
  Future<void> ensureProfile(User user) async {
    final ref = _ref(user.uid);
    final doc = await ref.get();

    // 'plan' field distinguishes a proper profile from a legacy doc
    // that only has lumiWardrobeAlbumId.
    final hasProfile = doc.exists && doc.data()?['plan'] != null;

    if (!hasProfile) {
      // First login (or migration from pre-profile era).
      // merge:true preserves any existing lumiWardrobeAlbumId.
      await ref.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoUrl': user.photoURL,
        'plan': 'free',
        'freeQuota': 100,
        'analyzedCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      // Subsequent logins — refresh fields that can change on the Google account.
      await ref.update({
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoUrl': user.photoURL,
      });
    }
  }

  Future<void> markOnboardingComplete(String userId) =>
      _ref(userId).update({'onboardingCompleted': true});

  /// Updates a single body measurement field (e.g. 'heightCm', 'weightKg').
  Future<void> updateMeasurement(
          String userId, String field, dynamic value) =>
      _ref(userId).update({field: value});

  Stream<UserProfile?> watchProfile(String userId) =>
      _ref(userId).snapshots().map(
            (doc) => doc.exists ? UserProfile.fromFirestore(doc) : null,
          );
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(firestoreProvider));
});

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return const Stream.empty();
  return ref.watch(userRepositoryProvider).watchProfile(user.uid);
});
