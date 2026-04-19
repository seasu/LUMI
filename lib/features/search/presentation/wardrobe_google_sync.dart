import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/auth/google_photos_oauth.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../snap/data/cloud_functions_service.dart';

/// Imports missing wardrobe documents from Google Photos `Lumi_Wardrobe`
/// album (callable `syncWardrobeFromPhotos`).
///
/// Throws [StateError] with message if OAuth token cannot be obtained.
Future<SyncWardrobeFromPhotosResult> syncWardrobeAlbumFromGooglePhotos(
  WidgetRef ref,
) async {
  final googleSignIn = ref.read(googleSignInProvider);

  GoogleSignInAccount? account =
      googleSignIn.currentUser ?? await googleSignIn.signInSilently();

  final token = await ensureGooglePhotosAccessToken(
    googleSignIn,
    account,
    scopes: const [
      kGooglePhotosAppendOnlyScope,
      kGooglePhotosReadonlyScope,
    ],
  );

  if (token == null) {
    account ??= await googleSignIn.signIn();
    final retry = await ensureGooglePhotosAccessToken(
      googleSignIn,
      account,
      scopes: const [
        kGooglePhotosAppendOnlyScope,
        kGooglePhotosReadonlyScope,
      ],
    );
    if (retry == null) {
      throw StateError(
        '無法取得 Google 相簿授權（需要讀取相簿以同步）。請重新登入並允許相簿存取。',
      );
    }
    return ref.read(cloudFunctionsServiceProvider).syncWardrobeFromPhotos(
          accessToken: retry,
        );
  }

  return ref.read(cloudFunctionsServiceProvider).syncWardrobeFromPhotos(
        accessToken: token,
      );
}
