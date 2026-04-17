import 'package:cloud_functions/cloud_functions.dart';

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

    final data = Map<String, dynamic>.from(result.data);
    return AnalyzeClothingResult(
      category: data['category'] as String? ?? '',
      colors: List<String>.from(data['colors'] as List? ?? []),
      materials: List<String>.from(data['materials'] as List? ?? []),
      embedding: List<double>.from(
        (data['embedding'] as List? ?? []).map((e) => (e as num).toDouble()),
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

    final data = Map<String, dynamic>.from(result.data);
    final mediaItemId = data['mediaItemId'] as String?;
    final thumbnailUrl = data['thumbnailUrl'] as String?;

    if (mediaItemId == null || mediaItemId.isEmpty) {
      throw Exception(
        'Cloud Function 未回傳 mediaItemId，'
        'response keys: ${data.keys.toList()}',
      );
    }

    return UploadToPhotosResult(
      mediaItemId: mediaItemId,
      thumbnailUrl: thumbnailUrl ?? '',
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

    final data = Map<String, dynamic>.from(result.data);
    final rawMatches = data['topMatches'] as List? ?? [];
    final topMatches = rawMatches.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return MatchedClothingItem(
        similarity: (m['similarity'] as num?)?.toDouble() ?? 0.0,
        mediaItemId: m['mediaItemId'] as String? ?? '',
        thumbnailUrl: m['thumbnailUrl'] as String? ?? '',
        category: m['category'] as String? ?? '',
        colors: List<String>.from(m['colors'] as List? ?? []),
      );
    }).toList();

    return CompareClothingResult(topMatches: topMatches);
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
