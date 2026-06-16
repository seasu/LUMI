import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DebugLogEntry {
  DebugLogEntry(this.message) : time = DateTime.now();
  DebugLogEntry._restore(this.time, this.message);

  final DateTime time;
  final String message;

  String get formatted {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    final ms = time.millisecond.toString().padLeft(3, '0');
    return '[$h:$m:$s.$ms] $message';
  }

  String _serialise() => '${time.millisecondsSinceEpoch}|$message';

  static DebugLogEntry? _deserialise(String raw) {
    final sep = raw.indexOf('|');
    if (sep < 0) return null;
    final ms = int.tryParse(raw.substring(0, sep));
    if (ms == null) return null;
    return DebugLogEntry._restore(
      DateTime.fromMillisecondsSinceEpoch(ms),
      raw.substring(sep + 1),
    );
  }
}

class DebugLogService {
  DebugLogService._();
  static final instance = DebugLogService._();

  static const _persistKey = 'debug_log_v1';
  static const _maxEntries = 500;
  static const _maxPersisted = 300;
  // Throttle: write to SharedPreferences at most once per second.
  static const _persistDebounce = Duration(seconds: 1);

  final _entries = <DebugLogEntry>[];
  final _listeners = <void Function()>[];
  Timer? _persistTimer;

  List<DebugLogEntry> get entries => List.unmodifiable(_entries);

  // ── Startup ───────────────────────────────────────────────────────────────

  /// Call once in main() before install(). Loads the previous session's
  /// entries from SharedPreferences so errors that occurred before an app
  /// restart remain visible in the debug log.
  Future<void> loadPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_persistKey) ?? [];
      if (saved.isEmpty) return;

      _entries.add(DebugLogEntry._restore(DateTime.now(), '── previous session ──'));
      for (final raw in saved) {
        final entry = DebugLogEntry._deserialise(raw);
        if (entry != null) _entries.add(entry);
      }
      _entries.add(DebugLogEntry._restore(DateTime.now(), '── current session ──'));
    } catch (_) {}
  }

  // ── Intercept debugPrint ──────────────────────────────────────────────────

  void install() {
    final original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      original(message, wrapWidth: wrapWidth);
      if (message != null && message.isNotEmpty) log(message);
    };
  }

  // ── Core ──────────────────────────────────────────────────────────────────

  void log(String message) {
    if (_entries.length >= _maxEntries) _entries.removeAt(0);
    _entries.add(DebugLogEntry(message));
    for (final l in _listeners) {
      l();
    }
    _schedulePersist();
  }

  void clear() {
    _entries.clear();
    _persistTimer?.cancel();
    _doPersist(); // Persist empty list immediately on manual clear.
    for (final l in _listeners) {
      l();
    }
  }

  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);

  String exportAll() => _entries.map((e) => e.formatted).join('\n');

  // ── Persistence ───────────────────────────────────────────────────────────

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(_persistDebounce, _doPersist);
  }

  Future<void> _doPersist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final toSave = _entries.length > _maxPersisted
          ? _entries.sublist(_entries.length - _maxPersisted)
          : List<DebugLogEntry>.from(_entries);
      await prefs.setStringList(
        _persistKey,
        toSave.map((e) => e._serialise()).toList(),
      );
    } catch (_) {}
  }
}
