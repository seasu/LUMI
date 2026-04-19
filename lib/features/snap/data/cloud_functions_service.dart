import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final callable = _functions.httpsCallable('analyzeClothing');
    final result = await callable.call<Map<dynamic, dynamic>>({
      'imageBase64': imageBase64,
      'mimeType': mimeType,
    });

    final data = _asStringKeyedMap(result.data);
    return AnalyzeClothingResult(
      category: _requireString(data, 'category'),
      colors: List<String>.from(data['colors'] as List),
      materials: List<String>.from(data['materials'] as List),
      embedding: List<double>.from(
        (data['embedding'] as List).map((e) => (e as num).toDouble()),
      ),
    );
  }

  Future<UploadToPhotosResult> uploadToPhotos({
    required String imageBase64,
    required String mimeType,
    required String filename,
    required String accessToken,
  }) async {
    final callable = _functions.httpsCallable('uploadToPhotos');
    final result = await callable.call<Map<dynamic, dynamic>>({
      'imageBase64': imageBase64,
      'mimeType': mimeType,
      'filename': filename,
      'accessToken': accessToken,
    });

    final data = _asStringKeyedMap(result.data);
    return UploadToPhotosResult(
      mediaItemId: _requireString(data, 'mediaItemId'),
      thumbnailUrl: _requireString(data, 'thumbnailUrl'),
    );
  }

  Future<CompareClothingResult> compareClothing({
    required String imageBase64,
    required String mimeType,
  }) async {
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

    return CompareClothingResult(topMatches: topMatches);
  }

  /// Re-run Gemini wardrobe analysis when Firestore trigger did not complete.
  Future<void> retryAnalyzeWardrobeItem({
    required String mediaItemId,
  }) async {
    final callable = _functions.httpsCallable('retryAnalyzeWardrobeItem');
    await callable.call<Map<dynamic, dynamic>>({
      'mediaItemId': mediaItemId,
    });
  }

  /// Import missing `users/{uid}/wardrobe/{mediaItemId}` docs from Google Photos
  /// `Lumi_Wardrobe` album (requires `photoslibrary.readonly` token).
  Future<SyncWardrobeFromPhotosResult> syncWardrobeFromPhotos({
    required String accessToken,
  }) async {
    final callable = _functions.httpsCallable('syncWardrobeFromPhotos');
    final result = await callable.call<Map<dynamic, dynamic>>({
      'accessToken': accessToken,
    });
    final data = _asStringKeyedMap(result.data);
    return SyncWardrobeFromPhotosResult(
      albumId: _requireString(data, 'albumId'),
      created: (data['created'] as num?)?.toInt() ?? 0,
      skipped: (data['skipped'] as num?)?.toInt() ?? 0,
      skippedNoPreview: (data['skippedNoPreview'] as num?)?.toInt() ?? 0,
      totalInAlbum: (data['totalInAlbum'] as num?)?.toInt() ?? 0,
    );
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
