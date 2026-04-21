import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/google_photos_oauth.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../snap/data/cloud_functions_service.dart';

/// Imports missing wardrobe documents from Google Photos `Lumi_Wardrobe`
/// album (callable `syncWardrobeFromPhotos`).
///
/// Uses the existing Google session when available; otherwise, because this is
/// an explicit user action, it may open Google Sign-In UI first and then
/// request Photos scopes.
///
/// Refreshes Firebase ID token before calling the callable so auth matches
/// Google session.
///
/// Throws [StateError] if Photos token cannot be obtained (user denied scope).
Future<SyncWardrobeFromPhotosResult> syncWardrobeAlbumFromGooglePhotos(
  WidgetRef ref,
) async {
  final googleSignIn = ref.read(googleSignInProvider);

  final account = googleSignIn.currentUser ?? await googleSignIn.signIn();

  if (account == null) {
    throw StateError(
      '尚未登入 Google。請從歡迎頁以 Google 登入 Lumi 後，再使用與相簿同步。',
    );
  }

  // Manual sync button = explicit user action, so interactive OAuth is allowed.
  final token = await ensureGooglePhotosAccessToken(
    googleSignIn,
    account,
    scopes: const [
      kGooglePhotosAppendOnlyScope,
      kGooglePhotosReadonlyScope,
    ],
    interactive: true,
  );

  if (token == null) {
    throw StateError(
      '需要讀取 Google 相簿的權限才能同步。若剛才關閉了授權視窗，請再按一次「同步」並允許存取。',
    );
  }

  // Callable runs as Firebase Auth user — refresh ID token after OAuth so it is not stale.
  final firebaseUser = FirebaseAuth.instance.currentUser;
  if (firebaseUser != null) {
    await firebaseUser.getIdToken(true);
  }

  return ref.read(cloudFunctionsServiceProvider).syncWardrobeFromPhotos(
        accessToken: token,
      );
}
