import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/debug/debug_log.dart';
import '../../../core/providers/firebase_providers.dart'
    show
        firebaseAuthProvider,
        googleSignInProvider,
        kGooglePhotosAppendOnlyScope,
        kGooglePhotosReadonlyScope;
import '../../user/data/user_repository.dart';

void _log(String msg) => DebugLogService.instance.log('[auth] $msg');

class AuthRepository {
  AuthRepository(this._auth, this._googleSignIn, this._userRepository);

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final UserRepository _userRepository;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithGoogle() async {
    const platform = kIsWeb ? 'web' : 'native';
    _log('signInWithGoogle → platform=$platform');
    final sw = Stopwatch()..start();
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope(kGooglePhotosAppendOnlyScope)
          ..addScope(kGooglePhotosReadonlyScope)
          ..setCustomParameters({'prompt': 'select_account'});

        userCredential = await _auth.signInWithPopup(provider);
        await _userRepository.ensureProfile(userCredential.user!);
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) throw Exception('Google Sign-In cancelled');

        _log('signInWithGoogle: Google account=${googleUser.email}');

        // NOTE: Photos scope consent is handled lazily by each feature
        // (snap, sync, thumbnail refresh) via ensureGooglePhotosAccessToken.
        // Calling it here immediately after signIn() caused a spurious second
        // consent dialog on iOS — canAccessScopes throws right after signIn()
        // and the catch path triggered requestScopes unnecessarily.
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
        // Upsert Firestore profile — creates on first login, refreshes name/email later.
        await _userRepository.ensureProfile(userCredential.user!);
      }

      _log('signInWithGoogle ← ok ${sw.elapsedMilliseconds}ms'
          ' uid=${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      _log('signInWithGoogle ✗ ${sw.elapsedMilliseconds}ms $e');
      rethrow;
    }
  }

  /// Firebase first, then Google; `GoogleSignIn.signOut` is given a timeout on Web
  /// it can otherwise hang and block returning to the login screen.
  Future<void> signOut() async {
    _log('signOut →');
    try {
      await _auth.signOut();
      try {
        await _googleSignIn
            .signOut()
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        // Best-effort: user is already signed out of Firebase; continue
      }
      _log('signOut ← ok');
    } catch (e) {
      _log('signOut ✗ $e');
      rethrow;
    }
  }

  User? get currentUser => _auth.currentUser;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(googleSignInProvider),
    ref.watch(userRepositoryProvider),
  );
});
