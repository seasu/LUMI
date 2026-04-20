import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/providers/firebase_providers.dart';
import '../../snap/data/cloud_functions_service.dart';
import 'wardrobe_item.dart';

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

  Future<void> addItem(String userId, WardrobeItem item) =>
      _col(userId).doc(item.mediaItemId).set(item.toFirestore());

  Future<WardrobeItem?> getItem(String userId, String mediaItemId) async {
    final doc = await _col(userId).doc(mediaItemId).get();
    if (!doc.exists) return null;
    return WardrobeItem.fromFirestore(doc);
  }

  Stream<List<WardrobeItem>> watchWardrobe(String userId) =>
      _col(userId).orderBy('createdAt', descending: true).snapshots().map(
            (snap) => snap.docs.map(WardrobeItem.fromFirestore).toList(),
          );

  /// One-shot read from the Firestore server so local cache and listeners catch up.
  /// Use after pull-to-refresh when the UI feels stale.
  Future<void> prefetchWardrobeFromServer(String userId) async {
    await _col(userId)
        .orderBy('createdAt', descending: true)
        .get(const GetOptions(source: Source.server));
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
    final cf = _cloudFunctions;
    if (cf != null) {
      return cf.refreshWardrobeThumbnail(
        accessToken: accessToken,
        mediaItemId: mediaItemId,
      );
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
    final productUrl = data['productUrl'] as String?;
    final freshUrl = baseUrl ?? productUrl;
    if (freshUrl == null || freshUrl.isEmpty) {
      throw Exception(
        'Photos API: no baseUrl or productUrl for media item',
      );
    }
    final now = DateTime.now();

    await _col(userId).doc(mediaItemId).update({
      'thumbnailUrl': freshUrl,
      'thumbnailRefreshedAt': Timestamp.fromDate(now),
    });

    return freshUrl;
  }
}

final wardrobeRepositoryProvider = Provider<WardrobeRepository>((ref) {
  return WardrobeRepository(
    ref.watch(firestoreProvider),
    cloudFunctions: ref.watch(cloudFunctionsServiceProvider),
  );
});
