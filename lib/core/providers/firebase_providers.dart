import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../debug/debug_log.dart';

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
  final clientIdDisplay = clientId.isEmpty
      ? '(empty — GIDClientID read from Info.plist)'
      : '${clientId.substring(0, clientId.length.clamp(0, 28))}…';
  DebugLogService.instance
      .log('[auth] GoogleSignIn init: GOOGLE_CLIENT_ID=$clientIdDisplay');

  // Only 'email' scope is needed — image storage is now local (no Photos/Drive OAuth).
  return GoogleSignIn(
    clientId: clientId.isEmpty ? null : clientId,
    scopes: const ['email'],
  );
});
