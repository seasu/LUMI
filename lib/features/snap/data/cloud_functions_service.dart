import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/debug/debug_log.dart';
import '../../../core/providers/firebase_providers.dart' show cloudFunctionsProvider;

/// Callable responses can omit keys or send null on Web (JS interop); never use `as String` blindly.
String _requireString(Map<String, dynamic> data, String key) {
  final v = data[key];
  if (v == null) {
    throw FormatException('Missing field "$key" in Cloud Function response');
  }
  if (v is String) return v;
  throw FormatException(
    'Field "$key" has unexpected type ${v.runtimeType}',
  );
}

void _log(String msg) => DebugLogService.instance.log('[fn] $msg');

/// Shared [CloudFunctionsService] for Snap, Check, and wardrobe sync.
final cloudFunctionsServiceProvider = Provider<CloudFunctionsService>((ref) {
  return CloudFunctionsService(ref.watch(cloudFunctionsProvider));
});

class CloudFunctionsService {
  CloudFunctionsService(this._functions);

  final FirebaseFunctions _functions;

  Future<AnalyzeClothingResult> analyzeClothing({
    required String imageBase64,
    required String mimeType,
  }) async {
    _log('analyzeClothing → mime=$mimeType');
    final sw = Stopwatch()..start();
    try {
      final callable = _functions.httpsCallable('analyzeClothing');
      final result = await callable.call<Map<dynamic, dynamic>>({
        'imageBase64': imageBase64,
        'mimeType': mimeType,
      });

      final data = _asStringKeyedMap(result.data);
      final r = AnalyzeClothingResult(
        category: _requireString(data, 'category'),
        colors: List<String>.from(data['colors'] as List),
        materials: List<String>.from(data['materials'] as List),
        embedding: List<double>.from(
          (data['embedding'] as List).map((e) => (e as num).toDouble()),
        ),
      );
      _log('analyzeClothing ← ok ${sw.elapsedMilliseconds}ms'
          ' category=${r.category} colors=${r.colors} materials=${r.materials}');
      return r;
    } catch (e) {
      _log('analyzeClothing ✗ ${sw.elapsedMilliseconds}ms $e');
      rethrow;
    }
  }

  Future<UploadToPhotosResult> uploadToPhotos({
    required String imageBase64,
    required String mimeType,
    required String filename,
    required String accessToken,
  }) async {
    _log('uploadToPhotos → file=$filename mime=$mimeType');
    final sw = Stopwatch()..start();
    try {
      final callable = _functions.httpsCallable(
        'uploadToPhotos',
        options: HttpsCallableOptions(timeout: const Duration(minutes: 5)),
      );
      final result = await callable.call<Map<dynamic, dynamic>>({
        'imageBase64': imageBase64,
        'mimeType': mimeType,
        'filename': filename,
        'accessToken': accessToken,
      });

      final data = _asStringKeyedMap(result.data);
      final r = UploadToPhotosResult(
        mediaItemId: _requireString(data, 'mediaItemId'),
        // thumbnailUrl may be empty when Photos API omits baseUrl from
        // batchCreate; the wardrobe thumbnail-refresh flow fills it in later.
        thumbnailUrl: (data['thumbnailUrl'] as String?) ?? '',
      );
      _log('uploadToPhotos ← ok ${sw.elapsedMilliseconds}ms'
          ' mediaItemId=${r.mediaItemId}');
      return r;
    } catch (e) {
      _log('uploadToPhotos ✗ ${sw.elapsedMilliseconds}ms $e');
      rethrow;
    }
  }

  Future<CompareClothingResult> compareClothing({
    required String imageBase64,
    required String mimeType,
  }) async {
    _log('compareClothing → mime=$mimeType');
    final sw = Stopwatch()..start();
    try {
      final callable = _functions.httpsCallable('compareClothing');
      final result = await callable.call<Map<dynamic, dynamic>>({
        'imageBase64': imageBase64,
        'mimeType': mimeType,
      });

      final data = _asStringKeyedMap(result.data);
      final rawMatches = data['topMatches'] as List? ?? [];
      final topMatches = rawMatches.map((e) {
        final m = _asStringKeyedMap(e);
        return MatchedClothingItem(
          similarity: (m['similarity'] as num).toDouble(),
          mediaItemId: _requireString(m, 'mediaItemId'),
          thumbnailUrl: _requireString(m, 'thumbnailUrl'),
          category: m['category'] as String? ?? '',
          colors: List<String>.from(m['colors'] as List? ?? []),
        );
      }).toList();

      final r = CompareClothingResult(topMatches: topMatches);
      _log('compareClothing ← ok ${sw.elapsedMilliseconds}ms'
          ' matches=${r.topMatches.length}');
      return r;
    } catch (e) {
      _log('compareClothing ✗ ${sw.elapsedMilliseconds}ms $e');
      rethrow;
    }
  }

  /// Re-run Gemini wardrobe analysis when Firestore trigger did not complete.
  Future<void> retryAnalyzeWardrobeItem({
    required String mediaItemId,
  }) async {
    _log('retryAnalyzeWardrobeItem → mediaItemId=$mediaItemId');
    final sw = Stopwatch()..start();
    try {
      final callable = _functions.httpsCallable('retryAnalyzeWardrobeItem');
      await callable.call<Map<dynamic, dynamic>>({
        'mediaItemId': mediaItemId,
      });
      _log('retryAnalyzeWardrobeItem ← ok ${sw.elapsedMilliseconds}ms');
    } catch (e) {
      _log('retryAnalyzeWardrobeItem ✗ ${sw.elapsedMilliseconds}ms $e');
      rethrow;
    }
  }

  /// Import missing `users/{uid}/wardrobe/{mediaItemId}` docs from Google Photos
  /// `Lumi_Wardrobe` album (requires `photoslibrary.readonly` token).
  Future<SyncWardrobeFromPhotosResult> syncWardrobeFromPhotos({
    required String accessToken,
  }) async {
    _log('syncWardrobeFromPhotos →');
    final sw = Stopwatch()..start();
    try {
      final callable = _functions.httpsCallable('syncWardrobeFromPhotos');
      final result = await callable.call<Map<dynamic, dynamic>>({
        'accessToken': accessToken,
      });
      final data = _asStringKeyedMap(result.data);
      final r = SyncWardrobeFromPhotosResult(
        albumId: _requireString(data, 'albumId'),
        created: (data['created'] as num?)?.toInt() ?? 0,
        skipped: (data['skipped'] as num?)?.toInt() ?? 0,
        skippedNoPreview: (data['skippedNoPreview'] as num?)?.toInt() ?? 0,
        totalInAlbum: (data['totalInAlbum'] as num?)?.toInt() ?? 0,
      );
      _log('syncWardrobeFromPhotos ← ok ${sw.elapsedMilliseconds}ms'
          ' total=${r.totalInAlbum} created=${r.created}'
          ' skipped=${r.skipped} noPreview=${r.skippedNoPreview}');
      return r;
    } catch (e) {
      _log('syncWardrobeFromPhotos ✗ ${sw.elapsedMilliseconds}ms $e');
      rethrow;
    }
  }

  /// Web: Photos Library API has no browser CORS — server proxies GET mediaItems + Firestore update.
  Future<String> refreshWardrobeThumbnail({
    required String accessToken,
    required String mediaItemId,
  }) async {
    _log('refreshWardrobeThumbnail → mediaItemId=$mediaItemId');
    final sw = Stopwatch()..start();
    try {
      final callable = _functions.httpsCallable('refreshWardrobeThumbnail');
      final result = await callable.call<Map<dynamic, dynamic>>({
        'accessToken': accessToken,
        'mediaItemId': mediaItemId,
      });
      final data = _asStringKeyedMap(result.data);
      final url = _requireString(data, 'thumbnailUrl');
      _log('refreshWardrobeThumbnail ← ok ${sw.elapsedMilliseconds}ms');
      return url;
    } catch (e) {
      _log('refreshWardrobeThumbnail ✗ ${sw.elapsedMilliseconds}ms $e');
      rethrow;
    }
  }
}

class AnalyzeClothingResult {
  const AnalyzeClothingResult({
    required this.category,
    required this.colors,
    required this.materials,
    required this.embedding,
  });

  final String category;
  final List<String> colors;
  final List<String> materials;
  final List<double> embedding;
}

class UploadToPhotosResult {
  const UploadToPhotosResult({
    required this.mediaItemId,
    required this.thumbnailUrl,
  });

  final String mediaItemId;
  final String thumbnailUrl;
}

class MatchedClothingItem {
  const MatchedClothingItem({
    required this.similarity,
    required this.mediaItemId,
    required this.thumbnailUrl,
    required this.category,
    required this.colors,
  });

  final double similarity;
  final String mediaItemId;
  final String thumbnailUrl;
  final String category;
  final List<String> colors;
}

class CompareClothingResult {
  const CompareClothingResult({required this.topMatches});

  final List<MatchedClothingItem> topMatches;
}

class SyncWardrobeFromPhotosResult {
  const SyncWardrobeFromPhotosResult({
    required this.albumId,
    required this.created,
    required this.skipped,
    required this.skippedNoPreview,
    required this.totalInAlbum,
  });

  final String albumId;
  final int created;
  final int skipped;
  final int skippedNoPreview;
  final int totalInAlbum;
}

Map<String, dynamic> _asStringKeyedMap(Object? raw) {
  if (raw == null) {
    throw const FormatException('Cloud Function returned null payload');
  }
  if (raw is! Map) {
    throw FormatException(
      'Cloud Function returned ${raw.runtimeType}, expected Map',
    );
  }
  return Map<String, dynamic>.from(raw);
}

/// Snackbar-safe copy for callable failures (includes `details` when SDK sends it).
String formatFirebaseCallableError(Object error) {
  if (error is FirebaseFunctionsException) {
    final parts = <String>[];
    final m = error.message?.trim();
    if (m != null && m.isNotEmpty) parts.add(m);
    final d = error.details;
    if (d != null) {
      final ds = d.toString().trim();
      if (ds.isNotEmpty && ds != m) parts.add(ds);
    }
    if (parts.isEmpty) parts.add(error.code);
    return parts.join('\n');
  }
  return error.toString();
}

/// Shorter, user-oriented copy for wardrobe → Google Photos sync failures.
String formatWardrobeSyncErrorForUser(Object error) {
  if (error is StateError) {
    final message = error.message;
    final lower = message.toLowerCase();
    if (lower.contains('授權視窗') ||
        lower.contains('popup') ||
        lower.contains('瀏覽器封鎖')) {
      return '瀏覽器阻擋了 Google 授權視窗。請允許本站彈出視窗後，再按一次「同步」完成 Google 相簿授權。';
    }
    return message;
  }
  if (error is FormatException) {
    return '與雲端同步時回傳格式異常。請更新 App 或稍後再試；若持續發生請聯絡開發者。';
  }
  if (error is FirebaseFunctionsException) {
    final code = error.code;
    final raw = formatFirebaseCallableError(error);
    final lower = raw.toLowerCase();
    switch (code) {
      case 'unauthenticated':
        return '登入已失效，請重新登入後再按同步。';
      case 'permission-denied':
        if (lower.contains('readonly') ||
            lower.contains('photos') ||
            lower.contains('insufficient authentication scopes')) {
          return 'Google 相簿 API 拒絕存取（常見：OAuth 存取權杖仍缺少「讀取相簿」範圍）。'
              '請再按一次「同步」並完成授權；若仍失敗，請登出後再登入。'
              '開發者請確認 Google Cloud → OAuth 同意畫面／用戶端已納入 '
              'https://www.googleapis.com/auth/photoslibrary.readonly'
              '（與 appendonly），且已發布或測試使用者已加入。';
        }
        return '沒有權限執行同步。$raw';
      case 'not-found':
        if (lower.contains('lumi_wardrobe') || lower.contains('album')) {
          return '在 Google 相簿找不到名為 Lumi_Wardrobe 的相簿。請確認相簿仍存在，或由 App 上傳新品建立相簿後再試。';
        }
        return '找不到資料：$raw';
      case 'failed-precondition':
      case 'internal':
        return '同步失敗：$raw';
      default:
        return '同步失敗（$code）：$raw';
    }
  }
  return error.toString();
}
