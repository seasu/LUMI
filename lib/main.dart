import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/config/firebase_options.dart';
import 'core/debug/debug_log.dart';
import 'core/logging/web_console_log.dart';
import 'shared/constants/app_version.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  DebugLogService.instance.install();

  // Install error handlers early so Firebase-init errors are also captured.
  if (!kIsWeb) {
    FlutterError.onError = (details) {
      DebugLogService.instance.log('FlutterError: ${details.exceptionAsString()}');
      // Crashlytics may not be initialised yet; guard with try-catch.
      try {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      } catch (_) {}
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      DebugLogService.instance.log('PlatformError: $error');
      try {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (_) {}
      return true;
    };
  }

  // Web needs explicit options; Android/iOS auto-configure from GoogleService-Info.plist.
  try {
    await Firebase.initializeApp(
      options: kIsWeb ? DefaultFirebaseOptions.currentPlatform : null,
    );
  } catch (e, stack) {
    // Firebase failed — most likely GoogleService-Info.plist is missing or invalid.
    // Show a minimal branded screen so the user sees something instead of white.
    debugPrint('Firebase.initializeApp failed: $e\n$stack');
    runApp(const _FirebaseErrorApp());
    return;
  }

  webConsoleInfo(
    'bootstrap',
    'Lumi starting',
    {
      'version': appVersionLabel,
      'firebaseProject': DefaultFirebaseOptions.web.projectId,
      'hint':
          'Filter DevTools Console by {"tag":"…"} JSON or search Lumi.bootstrap',
    },
  );

  runApp(
    const ProviderScope(
      child: LumiApp(),
    ),
  );
}

/// Shown only when Firebase fails to initialise (e.g. missing plist in CI build).
/// Displays a non-white screen so the failure is immediately obvious.
class _FirebaseErrorApp extends StatelessWidget {
  const _FirebaseErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFFFF8C00), // Lumi primary-light — clearly non-white
        body: Center(
          child: Text(
            'Firebase init failed\nCheck GoogleService-Info.plist',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
