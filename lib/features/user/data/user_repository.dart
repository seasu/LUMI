import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/debug/debug_log.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'user_profile.dart';

void _log(String msg) => DebugLogService.instance.log('[fs:user] $msg');

class UserRepository {
  UserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _ref(String userId) =>
      _firestore.collection('users').doc(userId);

  /// Called on every sign-in.
  /// Creates a full profile on first login; updates only volatile fields later.
  Future<void> ensureProfile(User user) async {
    _log('ensureProfile → uid=${user.uid}');
    final sw = Stopwatch()..start();
    try {
      final ref = _ref(user.uid);
      final doc = await ref.get();

      // 'plan' field distinguishes a proper profile from a legacy doc
      // that only has lumiWardrobeAlbumId.
      final hasProfile = doc.exists && doc.data()?['plan'] != null;

      if (!hasProfile) {
        // First login (or migration from pre-profile era).
        // merge:true preserves any existing lumiWardrobeAlbumId.
        _log('ensureProfile: first login → set()');
        await ref.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'displayName': user.displayName ?? '',
          'photoUrl': user.photoURL,
          'plan': 'free',
          'freeQuota': 30,
          'analyzedCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        _log('ensureProfile ← created ${sw.elapsedMilliseconds}ms');
      } else {
        // Subsequent logins — refresh fields that can change on the Google account.
        _log('ensureProfile: returning user → update()');
        await ref.update({
          'email': user.email ?? '',
          'displayName': user.displayName ?? '',
          'photoUrl': user.photoURL,
        });
        _log('ensureProfile ← updated ${sw.elapsedMilliseconds}ms');
      }
    } catch (e) {
      _log('ensureProfile ✗ ${sw.elapsedMilliseconds}ms $e');
      rethrow;
    }
  }

  Future<void> markOnboardingComplete(String userId) {
    _log('markOnboardingComplete → uid=$userId');
    return _ref(userId).update({'onboardingCompleted': true});
  }

  /// Updates a single body measurement field (e.g. 'heightCm', 'weightKg').
  Future<void> updateMeasurement(
      String userId, String field, dynamic value) {
    _log('updateMeasurement → uid=$userId field=$field value=$value');
    return _ref(userId).update({field: value});
  }

  Stream<UserProfile?> watchProfile(String userId) =>
      _ref(userId).snapshots().map(
            (doc) => doc.exists ? UserProfile.fromFirestore(doc) : null,
          );
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(firestoreProvider));
});

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  // Watch authStateProvider (reactive) so this provider rebuilds when auth
  // state changes, rather than reading FirebaseAuth.currentUser once and
  // never reacting to sign-in / sign-out events.
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  return ref.watch(userRepositoryProvider).watchProfile(user.uid);
});
