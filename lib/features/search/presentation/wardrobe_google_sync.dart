import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
  if (kIsWeb) {
    final auth = FirebaseAuth.instance;
    final firebaseUser = auth.currentUser;
    if (firebaseUser == null) {
      throw StateError('登入狀態已失效，請重新登入後再試。');
    }

    final provider = GoogleAuthProvider()
      ..addScope(kGooglePhotosAppendOnlyScope)
      ..addScope(kGooglePhotosReadonlyScope)
      ..setCustomParameters({'prompt': 'consent'});

    final userCredential = await auth.signInWithPopup(provider);
    final credential = userCredential.credential;
    final token =
        credential is OAuthCredential ? credential.accessToken : null;

    if (token == null || token.isEmpty) {
      throw StateError(
        '需要讀取 Google 相簿的授權 token 才能同步。請按一次「同步」重新授權後再試。',
      );
    }

    await auth.currentUser?.getIdToken(true);
    return ref.read(cloudFunctionsServiceProvider).syncWardrobeFromPhotos(
          accessToken: token,
        );
  }

  final googleSignIn = ref.read(googleSignInProvider);

  // Use currentUser first (no network call), then signInSilently() as fallback.
  // Never call signIn() here: on iOS it always shows the account-picker UI,
  // which would trigger an unexpected login screen on every wardrobe refresh.
  final account =
      googleSignIn.currentUser ?? await googleSignIn.signInSilently();

  if (account == null) {
    throw StateError(
      '尚未登入 Google。請從歡迎頁以 Google 登入 Lumi 後，再使用與相簿同步。',
    );
  }

  // Manual sync button = explicit user action, so interactive OAuth is allowed.
  var token = await ensureGooglePhotosAccessToken(
    googleSignIn,
    account,
    scopes: const [
      kGooglePhotosAppendOnlyScope,
      kGooglePhotosReadonlyScope,
    ],
    interactive: true,
    clearCacheFirst: true,
  );

  if (token == null) {
    throw StateError('需要讀取 Google 相簿的授權才能同步。請完成授權後重新按一次「同步」。');
  }

  // Callable runs as Firebase Auth user — refresh ID token after OAuth so it is not stale.
  await FirebaseAuth.instance.currentUser?.getIdToken(true);

  try {
    return await ref.read(cloudFunctionsServiceProvider).syncWardrobeFromPhotos(
          accessToken: token,
        );
  } on FirebaseFunctionsException catch (e) {
    if (!_isMissingReadonlyScope(e)) rethrow;

    // The API confirmed the token lacks photoslibrary.readonly.
    // canAccessScopes often throws on iOS so we cannot check scopes pre-call;
    // use the 403 response as the definitive signal to force requestScopes.
    token = await ensureGooglePhotosAccessToken(
      googleSignIn,
      account,
      scopes: const [
        kGooglePhotosAppendOnlyScope,
        kGooglePhotosReadonlyScope,
      ],
      interactive: true,
      clearCacheFirst: true,
      forceRequestScopes: true,
    );

    if (token == null) {
      throw StateError(
        '讀取 Google 相簿的授權失敗（requestScopes 未成功）。'
        '請登出後重新登入，並在登入時完整允許相簿存取；'
        '若問題持續，請確認 Google Cloud Console → OAuth 同意畫面已加入 '
        'photoslibrary.readonly 範圍，且此帳號已列為測試用戶。',
      );
    }

    await FirebaseAuth.instance.currentUser?.getIdToken(true);
    return ref.read(cloudFunctionsServiceProvider).syncWardrobeFromPhotos(
          accessToken: token,
        );
  }
}

/// Returns true when [e] signals that the Photos API rejected the token due
/// to a missing photoslibrary.readonly scope (HTTP 403 PERMISSION_DENIED).
bool _isMissingReadonlyScope(FirebaseFunctionsException e) {
  final code = e.code.toLowerCase();
  final raw = '${e.message ?? ''} ${e.details ?? ''}'.toLowerCase();
  return code == 'permission-denied' &&
      (raw.contains('insufficient authentication scopes') ||
          raw.contains('photoslibrary.readonly') ||
          raw.contains('request had insufficient authentication scopes'));
}
