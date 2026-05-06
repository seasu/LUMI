import 'dart:convert';

import 'package:http/http.dart' as http;

const _photosBase = 'https://photoslibrary.googleapis.com/v1';

/// Album title Lumi creates and syncs from.
const kLumiWardrobeAlbumTitle = 'Lumi_Wardrobe';

/// A media item entry returned by the Google Photos Library API.
class PhotosMediaItem {
  const PhotosMediaItem({
    required this.id,
    required this.baseUrl,
    required this.creationTime,
  });

  final String id;
  final String baseUrl;
  final DateTime creationTime;
}

/// Wraps Google Photos Library REST API calls made directly from the device.
///
/// Google rejects server-side forwarding of mobile-obtained OAuth tokens to
/// the Photos Library API (403 "insufficient authentication scopes" even when
/// the token genuinely has the required scopes). All Photos API calls must
/// originate from the device that obtained the token.
class GooglePhotosApiClient {
  GooglePhotosApiClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  Map<String, String> _authHeaders(String accessToken) =>
      {'Authorization': 'Bearer $accessToken'};

  /// Finds the album matching [title] in the user's Google Photos library.
  /// Paginates through all albums (50 per page) until found.
  /// Returns `null` when no matching album exists.
  Future<String?> findAlbumId(String accessToken, String title) async {
    String? pageToken;
    do {
      final q = <String, String>{'pageSize': '50'};
      if (pageToken != null) q['pageToken'] = pageToken;
      final uri =
          Uri.parse('$_photosBase/albums').replace(queryParameters: q);
      final res =
          await _http.get(uri, headers: _authHeaders(accessToken));
      if (res.statusCode != 200) {
        throw Exception(
            'Photos API GET /albums ${res.statusCode}: ${res.body}');
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final albums = (body['albums'] as List<dynamic>?) ?? [];
      for (final a in albums) {
        final m = a as Map<String, dynamic>;
        if (m['title'] == title) return m['id'] as String;
      }
      pageToken = body['nextPageToken'] as String?;
    } while (pageToken != null);
    return null;
  }

  /// Lists all media items in [albumId], paginating until exhausted.
  /// Items without a `baseUrl` (no preview available) are skipped.
  Future<List<PhotosMediaItem>> listAlbumMediaItems(
      String accessToken, String albumId) async {
    final out = <PhotosMediaItem>[];
    String? pageToken;
    do {
      final bodyMap = <String, dynamic>{
        'albumId': albumId,
        'pageSize': 100,
        if (pageToken != null) 'pageToken': pageToken,
      };
      final res = await _http.post(
        Uri.parse('$_photosBase/mediaItems:search'),
        headers: {
          ..._authHeaders(accessToken),
          'Content-Type': 'application/json',
        },
        body: jsonEncode(bodyMap),
      );
      if (res.statusCode != 200) {
        throw Exception(
            'Photos API POST /mediaItems:search ${res.statusCode}: ${res.body}');
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      for (final item in (data['mediaItems'] as List<dynamic>?) ?? []) {
        final m = item as Map<String, dynamic>;
        final baseUrl = m['baseUrl'] as String? ?? '';
        if (baseUrl.isEmpty) continue;
        final meta = m['mediaMetadata'] as Map<String, dynamic>?;
        final creationTimeStr = meta?['creationTime'] as String?;
        out.add(PhotosMediaItem(
          id: m['id'] as String,
          baseUrl: baseUrl,
          creationTime: creationTimeStr != null
              ? DateTime.tryParse(creationTimeStr) ?? DateTime.now()
              : DateTime.now(),
        ));
      }
      pageToken = data['nextPageToken'] as String?;
    } while (pageToken != null);
    return out;
  }
}
