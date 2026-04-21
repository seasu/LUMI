import 'dart:async';
import 'dart:collection';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/auth/google_photos_oauth.dart';
import '../../../../core/logging/web_console_log.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../wardrobe/data/wardrobe_item.dart';
import '../../../wardrobe/data/wardrobe_repository.dart';
import 'thumbnail_repair_candidates.dart';

enum ThumbnailRepairPhase {
  idle,
  repairing,
  waitingForAuth,
  coolingDown,
  recentlyCompleted,
  recentlyFailed,
}

class ThumbnailRepairStatus {
  const ThumbnailRepairStatus({
    required this.phase,
    this.pendingCount = 0,
    this.runningCount = 0,
    this.lastUpdatedAt,
    this.lastRecoveredCount = 0,
    this.lastErrorMessage,
  });

  const ThumbnailRepairStatus.idle()
      : phase = ThumbnailRepairPhase.idle,
        pendingCount = 0,
        runningCount = 0,
        lastUpdatedAt = null,
        lastRecoveredCount = 0,
        lastErrorMessage = null;

  final ThumbnailRepairPhase phase;
  final int pendingCount;
  final int runningCount;
  final DateTime? lastUpdatedAt;
  final int lastRecoveredCount;
  final String? lastErrorMessage;

  ThumbnailRepairStatus copyWith({
    ThumbnailRepairPhase? phase,
    int? pendingCount,
    int? runningCount,
    DateTime? lastUpdatedAt,
    int? lastRecoveredCount,
    String? lastErrorMessage,
    bool clearError = false,
  }) {
    return ThumbnailRepairStatus(
      phase: phase ?? this.phase,
      pendingCount: pendingCount ?? this.pendingCount,
      runningCount: runningCount ?? this.runningCount,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      lastRecoveredCount: lastRecoveredCount ?? this.lastRecoveredCount,
      lastErrorMessage: clearError
          ? null
          : (lastErrorMessage ?? this.lastErrorMessage),
    );
  }
}

extension ThumbnailRepairStatusX on ThumbnailRepairStatus {
  static const Duration _recentVisibilityWindow = Duration(seconds: 8);

  bool get isVisible {
    if (phase != ThumbnailRepairPhase.idle) return true;
    final updatedAt = lastUpdatedAt;
    if (updatedAt == null) return false;
    return DateTime.now().difference(updatedAt) <= _recentVisibilityWindow &&
        (lastRecoveredCount > 0 || lastErrorMessage != null);
  }

  String get label {
    switch (phase) {
      case ThumbnailRepairPhase.repairing:
        final active = pendingCount + runningCount;
        return active > 0 ? '縮圖修復中 $active 筆' : '縮圖修復中';
      case ThumbnailRepairPhase.waitingForAuth:
        return '縮圖等待重新驗證';
      case ThumbnailRepairPhase.coolingDown:
        return '縮圖稍後重試';
      case ThumbnailRepairPhase.recentlyCompleted:
        return lastRecoveredCount > 0
            ? '縮圖已恢復 $lastRecoveredCount 筆'
            : '縮圖已恢復';
      case ThumbnailRepairPhase.recentlyFailed:
        return '部分縮圖稍後重試';
      case ThumbnailRepairPhase.idle:
        if (lastRecoveredCount > 0) {
          return '縮圖已恢復 $lastRecoveredCount 筆';
        }
        if (lastErrorMessage != null) {
          return '部分縮圖稍後重試';
        }
        return '';
    }
  }
}

final thumbnailRepairCoordinatorProvider =
    Provider.autoDispose<ThumbnailRepairCoordinator>((ref) {
      final coordinator = ThumbnailRepairCoordinator(ref);
      ref.onDispose(coordinator.dispose);
      return coordinator;
    });

final thumbnailRepairStatusProvider =
    StateProvider.autoDispose<ThumbnailRepairStatus>(
      (_) => const ThumbnailRepairStatus.idle(),
    );

class ThumbnailRepairCoordinator {
  ThumbnailRepairCoordinator(this._ref);

  static const _maxConcurrentRepairs = 2;
  static const _itemFailureCooldown = Duration(minutes: 5);
  static const _authBackoff = Duration(minutes: 2);
  static const _logFlushDelay = Duration(seconds: 2);

  final Ref _ref;
  final ListQueue<WardrobeItem> _pending = ListQueue<WardrobeItem>();
  final Set<String> _queuedIds = <String>{};
  final Set<String> _runningIds = <String>{};
  final Map<String, DateTime> _cooldownUntil = <String, DateTime>{};

  List<WardrobeItem> _latestItems = const [];
  DateTime? _authBackoffUntil;
  Timer? _authBackoffTimer;
  Timer? _logFlushTimer;
  bool _disposed = false;

  int _successCount = 0;
  int _authSkippedCount = 0;
  int _failureCount = 0;
  final Set<String> _successSamples = <String>{};
  final Set<String> _authSkippedSamples = <String>{};
  final Set<String> _failureSamples = <String>{};
  String? _lastFailureMessage;
  String? _lastAuthReason;
  int _lastBatchRecoveredCount = 0;

  void scheduleRepair(List<WardrobeItem> items) {
    if (_disposed) return;
    _latestItems = items;
    _pruneCooldowns();

    for (final item in items) {
      if (!thumbnailRepairNeeded(item)) continue;
      final mediaItemId = item.mediaItemId;
      if (_queuedIds.contains(mediaItemId) || _runningIds.contains(mediaItemId)) {
        continue;
      }
      final cooldown = _cooldownUntil[mediaItemId];
      if (cooldown != null && cooldown.isAfter(DateTime.now())) continue;
      _pending.add(item);
      _queuedIds.add(mediaItemId);
    }

    _publishStatus();
    _drain();
  }

  void dispose() {
    _disposed = true;
    _authBackoffTimer?.cancel();
    _logFlushTimer?.cancel();
  }

  void _drain() {
    if (_disposed) return;
    if (_authBackoffUntil case final until? when until.isAfter(DateTime.now())) {
      _publishStatus();
      return;
    }

    while (_runningIds.length < _maxConcurrentRepairs && _pending.isNotEmpty) {
      final item = _pending.removeFirst();
      final mediaItemId = item.mediaItemId;
      _queuedIds.remove(mediaItemId);

      final cooldown = _cooldownUntil[mediaItemId];
      if (cooldown != null && cooldown.isAfter(DateTime.now())) {
        continue;
      }

      _runningIds.add(mediaItemId);
      unawaited(_repairOne(item));
    }

    _publishStatus();
  }

  Future<void> _repairOne(WardrobeItem item) async {
    final mediaItemId = item.mediaItemId;
    try {
      final user = _ref.read(firebaseAuthProvider).currentUser;
      if (user == null) return;

      var token = await _readToken();
      if (token == null) {
        _startAuthBackoff(item, reason: 'silent_token_unavailable');
        return;
      }

      try {
        await _refreshThumbnail(user.uid, mediaItemId, token);
        _recordSuccess(mediaItemId);
      } on FirebaseFunctionsException catch (error) {
        if (!_isInvalidAuth(error)) rethrow;

        token = await _readToken(clearCacheFirst: true);
        if (token == null) {
          _startAuthBackoff(item, reason: 'oauth_token_expired');
          return;
        }

        try {
          await _refreshThumbnail(user.uid, mediaItemId, token);
          _recordSuccess(mediaItemId);
        } on FirebaseFunctionsException catch (retryError) {
          if (_isInvalidAuth(retryError)) {
            _startAuthBackoff(item, reason: 'oauth_retry_failed');
            return;
          }
          rethrow;
        }
      }
    } catch (error) {
      _cooldownUntil[mediaItemId] =
          DateTime.now().add(_itemFailureCooldown);
      _recordFailure(mediaItemId, error);
    } finally {
      _runningIds.remove(mediaItemId);
      _publishStatus();
      _drain();
    }
  }

  Future<void> _refreshThumbnail(
    String userId,
    String mediaItemId,
    String accessToken,
  ) {
    return _ref.read(wardrobeRepositoryProvider).refreshThumbnailUrl(
          userId: userId,
          mediaItemId: mediaItemId,
          accessToken: accessToken,
        );
  }

  Future<String?> _readToken({bool clearCacheFirst = false}) async {
    final googleSignIn = _ref.read(googleSignInProvider);
    final GoogleSignInAccount? googleUser =
        googleSignIn.currentUser ?? await googleSignIn.signInSilently();
    return ensureGooglePhotosAccessToken(
      googleSignIn,
      googleUser,
      scopes: const [
        kGooglePhotosAppendOnlyScope,
        kGooglePhotosReadonlyScope,
      ],
      interactive: false,
      clearCacheFirst: clearCacheFirst,
    );
  }

  bool _isInvalidAuth(FirebaseFunctionsException error) {
    final fnCode = error.code.toLowerCase();
    final raw = '${error.message ?? ''} ${error.details ?? ''}'.toLowerCase();
    return fnCode == 'unauthenticated' ||
        raw.contains('401') ||
        raw.contains('unauthenticated') ||
        raw.contains('invalid authentication credentials');
  }

  void _startAuthBackoff(WardrobeItem item, {required String reason}) {
    _lastAuthReason = reason;
    _authBackoffUntil = DateTime.now().add(_authBackoff);
    _authBackoffTimer?.cancel();
    _authBackoffTimer = Timer(_authBackoff, () {
      _authBackoffUntil = null;
      _publishStatus();
      scheduleRepair(_latestItems);
    });

    _pending.clear();
    _queuedIds.clear();
    _recordAuthSkip(item.mediaItemId);
    _publishStatus();
  }

  void _recordSuccess(String mediaItemId) {
    _successCount++;
    _successSamples.add(_mediaItemPrefix(mediaItemId));
    _scheduleLogFlush();
  }

  void _recordAuthSkip(String mediaItemId) {
    _authSkippedCount++;
    _authSkippedSamples.add(_mediaItemPrefix(mediaItemId));
    _scheduleLogFlush();
  }

  void _recordFailure(String mediaItemId, Object error) {
    _failureCount++;
    _failureSamples.add(_mediaItemPrefix(mediaItemId));
    _lastFailureMessage = error.toString();
    _scheduleLogFlush();
  }

  void _scheduleLogFlush() {
    _logFlushTimer ??= Timer(_logFlushDelay, _flushLogs);
  }

  void _flushLogs() {
    _logFlushTimer = null;
    if (_disposed) return;

    if (_successCount > 0) {
      _lastBatchRecoveredCount = _successCount;
      webConsoleInfo('thumbnail', 'refresh_thumbnail_batch_ok', {
        'count': _successCount,
        'sampleMediaItemPrefixes': _successSamples.take(3).toList(),
      });
    }

    if (_authSkippedCount > 0) {
      webConsoleInfo('thumbnail', 'refresh_thumbnail_batch_skipped', {
        'count': _authSkippedCount,
        'reason': _lastAuthReason ?? 'auth_backoff',
        'sampleMediaItemPrefixes': _authSkippedSamples.take(3).toList(),
      });
    }

    if (_failureCount > 0) {
      webConsoleInfo('thumbnail', 'refresh_thumbnail_batch_failed', {
        'count': _failureCount,
        'sampleMediaItemPrefixes': _failureSamples.take(3).toList(),
        if (_lastFailureMessage != null)
          'lastError': _truncate(_lastFailureMessage!, maxChars: 220),
      });
    }

    _successCount = 0;
    _authSkippedCount = 0;
    _failureCount = 0;
    _successSamples.clear();
    _authSkippedSamples.clear();
    _failureSamples.clear();
    _lastFailureMessage = null;
    _lastAuthReason = null;
    _publishStatus();
  }

  void _pruneCooldowns() {
    final now = DateTime.now();
    final expired = _cooldownUntil.entries
        .where((entry) => !entry.value.isAfter(now))
        .map((entry) => entry.key)
        .toList();
    for (final key in expired) {
      _cooldownUntil.remove(key);
    }
  }

  String _mediaItemPrefix(String mediaItemId) {
    if (mediaItemId.length <= 8) return mediaItemId;
    return '${mediaItemId.substring(0, 8)}…';
  }

  void _publishStatus() {
    final now = DateTime.now();
    final status = _ref.read(thumbnailRepairStatusProvider);

    ThumbnailRepairPhase phase = ThumbnailRepairPhase.idle;
    if (_authBackoffUntil case final until? when until.isAfter(now)) {
      phase = ThumbnailRepairPhase.waitingForAuth;
    } else if (_runningIds.isNotEmpty || _pending.isNotEmpty) {
      phase = ThumbnailRepairPhase.repairing;
    } else if (_cooldownUntil.isNotEmpty) {
      phase = ThumbnailRepairPhase.coolingDown;
    } else if (_lastFailureMessage != null) {
      phase = ThumbnailRepairPhase.recentlyFailed;
    } else if (_lastBatchRecoveredCount > 0) {
      phase = ThumbnailRepairPhase.recentlyCompleted;
    }

    _ref.read(thumbnailRepairStatusProvider.notifier).state = status.copyWith(
      phase: phase,
      pendingCount: _pending.length,
      runningCount: _runningIds.length,
      lastUpdatedAt: now,
      lastRecoveredCount: _lastBatchRecoveredCount,
      lastErrorMessage: _lastFailureMessage,
      clearError: _lastFailureMessage == null,
    );
  }
}

String _truncate(String value, {required int maxChars}) {
  if (value.length <= maxChars) return value;
  return '${value.substring(0, maxChars - 1)}…';
}
