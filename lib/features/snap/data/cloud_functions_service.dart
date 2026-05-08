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
          ' category=${r.category}');
      return r;
    } catch (e) {
      if (e is FirebaseFunctionsException) {
        _log('analyzeClothing ✗ ${sw.elapsedMilliseconds}ms'
            ' code=${e.code}'
            ' msg=${e.message}'
            ' details=${e.details}');
      } else {
        _log('analyzeClothing ✗ ${sw.elapsedMilliseconds}ms $e');
      }
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
          docId: _requireString(m, 'docId'),
          localFileName: m['localFileName'] as String?,
          category: m['category'] as String? ?? '',
          colors: List<String>.from(m['colors'] as List? ?? []),
        );
      }).toList();

      final r = CompareClothingResult(topMatches: topMatches);
      _log('compareClothing ← ok ${sw.elapsedMilliseconds}ms'
          ' matches=${r.topMatches.length}');
      return r;
    } catch (e) {
      _log('compareClothing ✗ ${sw.elapsedMilliseconds}ms ${formatFirebaseCallableError(e)}');
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

class MatchedClothingItem {
  const MatchedClothingItem({
    required this.similarity,
    required this.docId,
    required this.category,
    required this.colors,
    this.localFileName,
  });

  final double similarity;
  final String docId;
  final String? localFileName;
  final String category;
  final List<String> colors;
}

class CompareClothingResult {
  const CompareClothingResult({required this.topMatches});

  final List<MatchedClothingItem> topMatches;
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
