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
      category: data['category'] as String,
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

    final data = Map<String, dynamic>.from(result.data);
    return UploadToPhotosResult(
      mediaItemId: data['mediaItemId'] as String,
      thumbnailUrl: data['thumbnailUrl'] as String,
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
