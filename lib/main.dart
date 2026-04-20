import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/config/firebase_options.dart';
import 'core/logging/web_console_log.dart';
import 'shared/constants/app_version.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
