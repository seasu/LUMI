import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/debug/debug_log.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../snap/data/cloud_functions_service.dart';
import 'wardrobe_item.dart';

void _log(String msg) => DebugLogService.instance.log('[fs:wardrobe] $msg');

class WardrobeRepository {
  WardrobeRepository(
    this._firestore, {
    http.Client? httpClient,
    CloudFunctionsService? cloudFunctions,
  })  : _http = httpClient ?? http.Client(),
        _cloudFunctions = cloudFunctions;

  final FirebaseFirestore _firestore;
  final http.Client _http;
  final CloudFunctionsService? _cloudFunctions;

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _firestore.collection('users').doc(userId).collection('wardrobe');

  Future<void> addItem(String userId, WardrobeItem item) {
    _log('addItem → uid=$userId mediaItemId=${item.mediaItemId}');
    return _col(userId).doc(item.mediaItemId).set(item.toFirestore());
  }

  Future<WardrobeItem?> getItem(String userId, String mediaItemId) async {
    _log('getItem → uid=$userId mediaItemId=$mediaItemId');
    final doc = await _col(userId).doc(mediaItemId).get();
    if (!doc.exists) {
      _log('getItem ← null (not found)');
      return null;
    }
    return WardrobeItem.fromFirestore(doc);
  }

  Stream<List<WardrobeItem>> watchWardrobe(String userId) =>
      _col(userId).orderBy('createdAt', descending: true).snapshots().map(
            (snap) => snap.docs.map(WardrobeItem.fromFirestore).toList(),
          );

  /// One-shot read from the Firestore server so local cache and listeners catch up.
  /// Use after pull-to-refresh when the UI feels stale.
  Future<void> prefetchWardrobeFromServer(String userId) async {
    _log('prefetchFromServer → uid=$userId');
    final sw = Stopwatch()..start();
    try {
      final snap = await _col(userId)
          .orderBy('createdAt', descending: true)
          .get(const GetOptions(source: Source.server));
      _log('prefetchFromServer ← ok ${sw.elapsedMilliseconds}ms'
          ' count=${snap.docs.length}');
    } catch (e) {
      _log('prefetchFromServer ✗ ${sw.elapsedMilliseconds}ms $e');
      rethrow;
    }
  }

  /// Fetches a fresh thumbnailUrl from Google Photos and updates Firestore.
  /// Should be called when [WardrobeItem.isThumbnailStale] is true.
  ///
  /// Prefer [CloudFunctionsService.refreshWardrobeThumbnail]: the Photos Library
  /// REST API is not callable from Flutter **Web** browsers (no CORS); direct
  /// `GET photoslibrary.googleapis.com` surfaces as **403** in DevTools even when
  /// OAuth scopes are correct. When [cloudFunctions] is injected (production app),
  /// always proxy via Cloud Functions.
  Future<String> refreshThumbnailUrl({
    required String userId,
    required String mediaItemId,
    required String accessToken,
  }) async {
    final via = _cloudFunctions != null ? 'functions' : 'http';
    _log('refreshThumbnailUrl → via=$via mediaItemId=$mediaItemId');
    final sw = Stopwatch()..start();
    try {
      final cf = _cloudFunctions;
      if (cf != null) {
        final url = await cf.refreshWardrobeThumbnail(
          accessToken: accessToken,
          mediaItemId: mediaItemId,
        );
        _log('refreshThumbnailUrl ← ok ${sw.elapsedMilliseconds}ms (functions)');
        return url;
      }

      final uri = Uri.parse(
        'https://photoslibrary.googleapis.com/v1/mediaItems/$mediaItemId',
      );
      final response = await _http.get(
        uri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode != 200) {
        throw Exception('Photos API ${response.statusCode}: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final baseUrl = data['baseUrl'] as String?;
      final freshUrl = baseUrl;
      if (freshUrl == null || freshUrl.isEmpty) {
        throw Exception('Photos API: no baseUrl for media item');
      }
      final now = DateTime.now();

      await _col(userId).doc(mediaItemId).update({
        'thumbnailUrl': freshUrl,
        'thumbnailRefreshedAt': Timestamp.fromDate(now),
      });

      _log('refreshThumbnailUrl ← ok ${sw.elapsedMilliseconds}ms (http)');
      return freshUrl;
    } catch (e) {
      _log('refreshThumbnailUrl ✗ ${sw.elapsedMilliseconds}ms $e');
      rethrow;
    }
  }
}

final wardrobeRepositoryProvider = Provider<WardrobeRepository>((ref) {
  return WardrobeRepository(
    ref.watch(firestoreProvider),
    cloudFunctions: ref.watch(cloudFunctionsServiceProvider),
  );
});
