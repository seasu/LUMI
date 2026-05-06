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

        // Request Photos scopes BEFORE signInWithCredential so the Firebase
        // auth-state change (and wardrobe load + background thumbnail refresh)
        // only fires after the token already carries photoslibrary.readonly.
        //
        // Old order — signInWithCredential first, requestScopes second — caused
        // a race: the wardrobe started loading while the consent sheet was still
        // on screen, background thumbnail refresh grabbed a scope-less token and
        // immediately returned 403. Moving the scope request first eliminates
        // that window entirely.
        _log('signInWithGoogle: requesting Photos scopes…');
        try {
          await _googleSignIn.requestScopes([
            kGooglePhotosAppendOnlyScope,
            kGooglePhotosReadonlyScope,
          ]);
          _log('signInWithGoogle: Photos scopes requested');
        } catch (e) {
          _log('signInWithGoogle: requestScopes failed (non-fatal) $e');
        }

        // On Android, requestScopes does not update the token on the existing
        // account object. Call signInSilently() to obtain a fresh account that
        // reflects the newly granted scopes, then clear the auth cache so the
        // next authentication call fetches a fresh access token from Google.
        GoogleSignInAccount? refreshedAccount;
        try {
          refreshedAccount = await _googleSignIn.signInSilently();
        } catch (_) {}
        final signingAccount =
            refreshedAccount ?? _googleSignIn.currentUser ?? googleUser;
        try {
          await signingAccount.clearAuthCache();
          _log('signInWithGoogle: auth cache cleared');
        } catch (e) {
          _log('signInWithGoogle: clearAuthCache failed (non-fatal) $e');
        }

        // Build Firebase credential from the fresh post-scope-grant token.
        final googleAuth = await signingAccount.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Firebase sign-in — auth state change fires HERE, after scopes are ready.
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

  /// Firebase first, then Google.
  ///
  /// Uses `disconnect()` (not `signOut()`) for the Google side so that the
  /// iOS Keychain refresh token is revoked on Google's servers. This forces
  /// a full OAuth re-authorization on the next sign-in, ensuring the new
  /// refresh token always includes all scopes currently on the consent screen.
  /// Without this, a stale refresh token from a previous session (issued
  /// before a new scope was added) would be silently reused, causing 403s.
  Future<void> signOut() async {
    _log('signOut →');
    try {
      await _auth.signOut();
      try {
        // disconnect() revokes tokens server-side AND clears local Keychain state.
        // Falls back to signOut() on Web where disconnect() may hang.
        if (kIsWeb) {
          await _googleSignIn
              .signOut()
              .timeout(const Duration(seconds: 10));
        } else {
          await _googleSignIn
              .disconnect()
              .timeout(const Duration(seconds: 10));
        }
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
