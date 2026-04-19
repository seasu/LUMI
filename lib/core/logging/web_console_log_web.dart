// Conditional web implementation for `web_console_log.dart`; `dart:html` is only
// compiled on web — see https://dart.dev/tools/linter-rules/avoid_web_libraries_in_flutter
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;

/// Writes one line to the browser console (DevTools → Console).
void webConsoleInfo(String tag, String message, [Map<String, Object?>? data]) {
  try {
    final payload = <String, Object?>{
      'tag': tag,
      'msg': message,
      if (data != null && data.isNotEmpty) 'data': data,
      'at': DateTime.now().toUtc().toIso8601String(),
    };
    html.window.console.log(jsonEncode(payload));
  } catch (_) {
    html.window.console.log('[Lumi][$tag] $message');
  }
}
