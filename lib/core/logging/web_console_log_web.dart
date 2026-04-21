import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Writes one line to the browser console (DevTools → Console).
void webConsoleInfo(String tag, String message, [Map<String, Object?>? data]) {
  try {
    final payload = <String, Object?>{
      'tag': tag,
      'msg': message,
      if (data != null && data.isNotEmpty) 'data': data,
      'at': DateTime.now().toUtc().toIso8601String(),
    };
    web.console.log(jsonEncode(payload).toJS);
  } catch (_) {
    web.console.log('[Lumi][$tag] $message'.toJS);
  }
}
