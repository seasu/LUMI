import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/auth/google_photos_oauth.dart';
import '../../../core/providers/firebase_providers.dart'
    show
        firebaseAuthProvider,
        googleSignInProvider,
        kGooglePhotosAppendOnlyScope,
        kGooglePhotosReadonlyScope;
import '../../user/data/user_repository.dart';

class AuthRepository {
  AuthRepository(this._auth, this._googleSignIn, this._userRepository);

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final UserRepository _userRepository;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google Sign-In cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    // Upsert Firestore profile — creates on first login, refreshes name/email later.
    await _userRepository.ensureProfile(userCredential.user!);
    // Prompt for Google Photos (append-only) in the same session as first Google login
    // so users are not asked again at Snap upload when possible.
    await ensureGooglePhotosAccessToken(
      _googleSignIn,
      googleUser,
      scopes: const [
        kGooglePhotosAppendOnlyScope,
        kGooglePhotosReadonlyScope,
      ],
    );
    return userCredential;
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
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
