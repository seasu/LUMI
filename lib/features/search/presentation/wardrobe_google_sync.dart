import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/google_photos_oauth.dart';
import '../../../core/debug/debug_log.dart';
import '../../../core/photos/google_photos_api_client.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../snap/data/cloud_functions_service.dart';

void _log(String msg) => DebugLogService.instance.log('[sync] $msg');

/// Imports missing wardrobe documents from Google Photos `Lumi_Wardrobe`
/// album.
///
/// **Web**: re-authenticates via `signInWithPopup` (needed to satisfy CORS)
/// then delegates to the `syncWardrobeFromPhotos` Cloud Function, which
/// makes the Photos API calls server-side.
///
/// **Native (iOS / Android)**: calls the Photos Library API directly from
/// the device using the user's OAuth token, then batch-writes new wardrobe
/// docs to Firestore. Google rejects server-side forwarding of
/// mobile-obtained OAuth tokens, so the Cloud Function must not be used here.
Future<SyncWardrobeFromPhotosResult> syncWardrobeAlbumFromGooglePhotos(
  WidgetRef ref,
) async {
  if (kIsWeb) {
    return _webSync(ref);
  }
  return _nativeSync(ref);
}

// ---------------------------------------------------------------------------
// Web path
// ---------------------------------------------------------------------------

Future<SyncWardrobeFromPhotosResult> _webSync(WidgetRef ref) async {
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

// ---------------------------------------------------------------------------
// Native path
// ---------------------------------------------------------------------------

Future<SyncWardrobeFromPhotosResult> _nativeSync(WidgetRef ref) async {
  final googleSignIn = ref.read(googleSignInProvider);
  final account =
      googleSignIn.currentUser ?? await googleSignIn.signInSilently();

  if (account == null) {
    throw StateError(
      '尚未登入 Google。請從歡迎頁以 Google 登入 Lumi 後，再使用與相簿同步。',
    );
  }

  // Explicit user action → interactive auth is allowed.
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

  await FirebaseAuth.instance.currentUser?.getIdToken(true);

  try {
    return await _doNativeSync(token, ref);
  } catch (e) {
    if (!_is403Error(e)) rethrow;

    _log('nativeSync: Photos API 403 — signing out and forcing requestScopes');

    // The cached token either lacks photoslibrary.readonly or is from a
    // stale bundled-consent session that Photos API internally rejects.
    // Sign out first so that requestScopes triggers a fresh consent flow
    // instead of silently re-using the stale token from the iOS Keychain.
    try {
      await googleSignIn.signOut();
    } catch (_) {}
    final freshAccount = await googleSignIn.signInSilently() ?? account;

    token = await ensureGooglePhotosAccessToken(
      googleSignIn,
      freshAccount,
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
        '請登出後重新登入，並在登入時完整允許相簿存取。',
      );
    }

    await FirebaseAuth.instance.currentUser?.getIdToken(true);

    try {
      return await _doNativeSync(token, ref);
    } catch (retryError) {
      if (!_is403Error(retryError)) rethrow;
      // Two consecutive 403s mean the OAuth consent is permanently stale
      // and cannot be refreshed without a full sign-out / sign-in cycle.
      throw StateError(
        'Google 相簿存取授權已失效。\n'
        '請從「個人檔案」頁登出後重新登入 Google，然後再試一次同步。',
      );
    }
  }
}

/// Performs the actual Photos API calls and Firestore batch write.
Future<SyncWardrobeFromPhotosResult> _doNativeSync(
    String accessToken, WidgetRef ref) async {
  // Log the client ID this binary was compiled with so it can be compared
  // against the token's `aud` field logged by GooglePhotosApiClient.logTokenInfo.
  const compiledClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  _log('nativeSync: compiledClientId='
      '${compiledClientId.isEmpty ? "(empty — using GIDClientID from Info.plist)" : "${compiledClientId.substring(0, compiledClientId.length.clamp(0, 28))}…"}');

  final firestore = ref.read(firestoreProvider);
  final userId = FirebaseAuth.instance.currentUser!.uid;
  final photosClient = GooglePhotosApiClient();

  final userRef = firestore.collection('users').doc(userId);
  final wardrobeRef = userRef.collection('wardrobe');

  // Use cached album ID when available; fall back to a full album search.
  final userSnap = await userRef.get();
  String? albumId =
      userSnap.data()?['lumiWardrobeAlbumId'] as String?;

  List<PhotosMediaItem>? mediaItems;

  if (albumId != null) {
    try {
      mediaItems =
          await photosClient.listAlbumMediaItems(accessToken, albumId);
    } catch (_) {
      // Cached ID may be stale (album deleted/recreated); search fresh.
      albumId = null;
    }
  }

  if (albumId == null) {
    albumId = await photosClient.findAlbumId(
        accessToken, kLumiWardrobeAlbumTitle);
    if (albumId == null) {
      throw StateError(
        'Google Photos 裡找不到 "$kLumiWardrobeAlbumTitle" 相簿。'
        '請先用 Lumi Snap 拍照上傳一件衣物建立相簿後再試。',
      );
    }
    try {
      await userRef
          .set({'lumiWardrobeAlbumId': albumId}, SetOptions(merge: true));
    } catch (_) {}
    mediaItems =
        await photosClient.listAlbumMediaItems(accessToken, albumId);
  }

  // Fetch existing media item IDs to skip duplicates.
  final existingSnap = await wardrobeRef.get();
  final existingIds = existingSnap.docs.map((d) => d.id).toSet();

  int created = 0;
  int skipped = 0;
  int skippedNoPreview = 0;

  WriteBatch batch = firestore.batch();
  int ops = 0;
  const batchLimit = 400;

  for (final item in mediaItems!) {
    if (existingIds.contains(item.id)) {
      skipped++;
      continue;
    }
    if (item.baseUrl.isEmpty) {
      skippedNoPreview++;
      continue;
    }

    batch.set(wardrobeRef.doc(item.id), {
      'mediaItemId': item.id,
      'category': '',
      'colors': [],
      'materials': [],
      'embedding': [],
      'thumbnailUrl': item.baseUrl,
      'createdAt': Timestamp.fromDate(item.creationTime),
      'thumbnailRefreshedAt': Timestamp.now(),
      'analyzed': false,
    });
    ops++;
    created++;
    existingIds.add(item.id);

    if (ops >= batchLimit) {
      await batch.commit();
      batch = firestore.batch();
      ops = 0;
    }
  }

  if (ops > 0) await batch.commit();

  _log('nativeSync ← albumId=$albumId'
      ' total=${mediaItems.length} created=$created skipped=$skipped'
      ' noPreview=$skippedNoPreview');

  return SyncWardrobeFromPhotosResult(
    albumId: albumId,
    created: created,
    skipped: skipped,
    skippedNoPreview: skippedNoPreview,
    totalInAlbum: mediaItems.length,
  );
}

/// Returns true when [e] looks like a Google Photos API 403 Insufficient Scopes.
bool _is403Error(Object e) {
  final msg = e.toString().toLowerCase();
  return msg.contains('403') &&
      (msg.contains('insufficient') ||
          msg.contains('permission_denied') ||
          msg.contains('photos api'));
}
