import 'dart:io' show Platform;

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

/// Thrown when the server reports the user has exhausted their AI analysis quota.
class QuotaExceededException implements Exception {
  const QuotaExceededException();
  @override
  String toString() => 'quota_exceeded';
}

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

      // CF returns { skipped: true, reason: 'quota_exceeded' } when over quota
      if (data['skipped'] == true) {
        final reason = data['reason'] as String? ?? 'quota_exceeded';
        _log('analyzeClothing: skipped (reason=$reason) ${sw.elapsedMilliseconds}ms');
        throw const QuotaExceededException();
      }

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
      if (e is QuotaExceededException) rethrow;
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

  /// Validates a platform purchase with the backend (App Store Server API / Play API)
  /// and updates the user's Firestore quota / plan.
  ///
  /// [productId]     one of: `lumi_extra_100`, `lumi_pro_yearly_v2`
  /// [transactionId] iOS StoreKit transactionIdentifier (iOS only)
  /// [purchaseToken] Google Play purchase token (Android only)
  Future<void> verifyPurchase({
    required String productId,
    String? transactionId,
    String? purchaseToken,
  }) async {
    _log('verifyPurchase → product=$productId');
    final sw = Stopwatch()..start();
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      final callable = _functions.httpsCallable('verifyPurchase');
      await callable.call<Map<dynamic, dynamic>>({
        'platform': platform,
        'productId': productId,
        if (transactionId != null) 'transactionId': transactionId,
        if (purchaseToken != null) 'purchaseToken': purchaseToken,
      });
      _log('verifyPurchase ← ok ${sw.elapsedMilliseconds}ms');
    } catch (e) {
      if (e is FirebaseFunctionsException) {
        _log('verifyPurchase ✗ ${sw.elapsedMilliseconds}ms'
            ' code=${e.code} msg=${e.message}');
      } else {
        _log('verifyPurchase ✗ ${sw.elapsedMilliseconds}ms $e');
      }
      rethrow;
    }
  }

  Future<String> getServerVersion() async {
    try {
      final callable = _functions.httpsCallable('getServerInfo');
      final result = await callable.call<Map<dynamic, dynamic>>();
      final data = _asStringKeyedMap(result.data);
      return data['version'] as String? ?? 'unknown';
    } catch (e) {
      _log('getServerVersion ✗ $e');
      return 'error';
    }
  }

  /// Permanently deletes the current user's Firestore document and Auth record.
  /// After this call the Firebase Auth session is gone; caller must sign out locally.
  Future<void> deleteAccount() async {
    _log('deleteAccount →');
    final sw = Stopwatch()..start();
    try {
      final callable = _functions.httpsCallable('deleteAccount');
      await callable.call<Map<dynamic, dynamic>>({});
      _log('deleteAccount ← ok ${sw.elapsedMilliseconds}ms');
    } catch (e) {
      if (e is FirebaseFunctionsException) {
        _log('deleteAccount ✗ ${sw.elapsedMilliseconds}ms'
            ' code=${e.code} msg=${e.message}');
      } else {
        _log('deleteAccount ✗ ${sw.elapsedMilliseconds}ms $e');
      }
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
