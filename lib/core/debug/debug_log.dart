import 'package:flutter/foundation.dart';

class DebugLogEntry {
  DebugLogEntry(this.message) : time = DateTime.now();
  final DateTime time;
  final String message;

  String get formatted {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    final ms = time.millisecond.toString().padLeft(3, '0');
    return '[$h:$m:$s.$ms] $message';
  }
}

class DebugLogService {
  DebugLogService._();
  static final instance = DebugLogService._();

  static const _maxEntries = 500;

  final _entries = <DebugLogEntry>[];
  final _listeners = <void Function()>[];

  List<DebugLogEntry> get entries => List.unmodifiable(_entries);

  void install() {
    final original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      original(message, wrapWidth: wrapWidth);
      if (message != null && message.isNotEmpty) log(message);
    };
  }

  void log(String message) {
    if (_entries.length >= _maxEntries) _entries.removeAt(0);
    _entries.add(DebugLogEntry(message));
    for (final l in _listeners) {
      l();
    }
  }

  void clear() {
    _entries.clear();
    for (final l in _listeners) {
      l();
    }
  }

  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);

  String exportAll() => _entries.map((e) => e.formatted).join('\n');
}
