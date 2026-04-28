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

  // Web needs explicit options; Android/iOS auto-configure from google-services.json.
  await Firebase.initializeApp(
    options: kIsWeb ? DefaultFirebaseOptions.currentPlatform : null,
  );

  if (!kIsWeb) {
    FlutterError.onError = (details) {
      DebugLogService.instance.log('FlutterError: ${details.exceptionAsString()}');
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      DebugLogService.instance.log('PlatformError: $error');
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
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
