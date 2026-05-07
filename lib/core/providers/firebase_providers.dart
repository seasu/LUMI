import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../debug/debug_log.dart';

/// Google Photos Library API — upload/create (Lumi Snap).
const kGooglePhotosAppendOnlyScope =
    'https://www.googleapis.com/auth/photoslibrary.appendonly';

/// Google Photos Library API — list albums / media created by this app.
///
/// photoslibrary.readonly was deprecated for third-party apps in 2024 and is
/// no longer granted by Google OAuth (silently downgraded or rejected). The
/// narrower appcreateddata scope covers everything Lumi needs: the
/// Lumi_Wardrobe album and all items were uploaded by this app.
const kGooglePhotosReadonlyScope =
    'https://www.googleapis.com/auth/photoslibrary.readonly.appcreateddata';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Must match Cloud Functions region in `functions/src/functionsRegion.ts`.
final cloudFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instanceFor(region: 'asia-east1');
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  const clientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  // Log which client ID the app was compiled with so we can compare against
  // the token's `aud` field in tokeninfo diagnostics.
  final clientIdDisplay = clientId.isEmpty
      ? '(empty — GIDClientID read from Info.plist)'
      : '${clientId.substring(0, clientId.length.clamp(0, 28))}…';
  DebugLogService.instance
      .log('[auth] GoogleSignIn init: GOOGLE_CLIENT_ID=$clientIdDisplay');

  // Only request 'email' at sign-in time. Photos scopes (appendonly,
  // readonly.appcreateddata) are requested incrementally via
  // ensureGooglePhotosAccessToken() at the point where the user explicitly
  // triggers a Photos-dependent action. Bundling them in the constructor
  // violates Google's "Unbundled Consent" OAuth policy.
  return GoogleSignIn(
    clientId: clientId.isEmpty ? null : clientId,
    scopes: const ['email'],
  );
});
