import 'dart:convert';

import 'package:web/web.dart';

/// Writes one line to the browser console (DevTools → Console).
void webConsoleInfo(String tag, String message, [Map<String, Object?>? data]) {
  try {
    final payload = <String, Object?>{
      'tag': tag,
      'msg': message,
      if (data != null && data.isNotEmpty) 'data': data,
      'at': DateTime.now().toUtc().toIso8601String(),
    };
    console.log(jsonEncode(payload));
  } catch (_) {
    console.log('[Lumi][$tag] $message');
  }
}
