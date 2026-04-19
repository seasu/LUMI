import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google Photos Library API — upload/create (Lumi Snap).
const kGooglePhotosAppendOnlyScope =
    'https://www.googleapis.com/auth/photoslibrary.appendonly';

/// Google Photos Library API — list albums / media (wardrobe sync from cloud).
const kGooglePhotosReadonlyScope =
    'https://www.googleapis.com/auth/photoslibrary.readonly';

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
  return GoogleSignIn(
    clientId: const String.fromEnvironment('GOOGLE_CLIENT_ID'),
    scopes: [
      'email',
      kGooglePhotosAppendOnlyScope,
      kGooglePhotosReadonlyScope,
    ],
  );
});
