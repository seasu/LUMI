import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (defaultTargetPlatform == TargetPlatform.iOS) return ios;
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    appId: String.fromEnvironment('FIREBASE_APP_ID'),
  );

  // iOS options are injected at CI build time via --dart-define extracted from
  // GoogleService-Info.plist. In local dev, leave these empty to fall back to
  // plist auto-discovery (options: null in Firebase.initializeApp).
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_IOS_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_IOS_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    iosClientId: String.fromEnvironment('FIREBASE_IOS_CLIENT_ID'),
    iosBundleId: 'io.github.seasu.lumi',
  );
}
