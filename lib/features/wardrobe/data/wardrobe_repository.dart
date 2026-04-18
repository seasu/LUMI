import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/providers/firebase_providers.dart';
import 'wardrobe_item.dart';

class WardrobeRepository {
  WardrobeRepository(this._firestore, {http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final FirebaseFirestore _firestore;
  final http.Client _http;

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
  Future<String> refreshThumbnailUrl({
    required String userId,
    required String mediaItemId,
    required String accessToken,
  }) async {
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
    final freshUrl = data['baseUrl'] as String;
    final now = DateTime.now();

    await _col(userId).doc(mediaItemId).update({
      'thumbnailUrl': freshUrl,
      'thumbnailRefreshedAt': Timestamp.fromDate(now),
    });

    return freshUrl;
  }
}

final wardrobeRepositoryProvider = Provider<WardrobeRepository>((ref) {
  return WardrobeRepository(ref.watch(firestoreProvider));
});
