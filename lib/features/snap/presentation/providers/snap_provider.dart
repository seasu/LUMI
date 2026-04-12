import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../wardrobe/data/wardrobe_item.dart';
import '../../../wardrobe/data/wardrobe_repository.dart';
import '../../data/cloud_functions_service.dart';
import '../../domain/snap_state.dart';

const _maxPhotos = 10;

final cloudFunctionsServiceProvider = Provider<CloudFunctionsService>((ref) {
  return CloudFunctionsService(ref.watch(cloudFunctionsProvider));
});

final snapProvider = NotifierProvider<SnapNotifier, SnapState>(SnapNotifier.new);

class SnapNotifier extends Notifier<SnapState> {
  // Cache the Google Photos access token within the current app session.
  // Google OAuth2 tokens expire in 1 hour; we treat them as stale 5 min early.
  String? _cachedPhotosToken;
  DateTime? _tokenExpiry;

  @override
  SnapState build() => const SnapIdle();

  // ── Photo selection ───────────────────────────────────────────────────────────

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (files.isEmpty) return;
    state = SnapPreviewing(files: files.take(_maxPhotos).toList());
  }

  void removeFile(int index) {
    final current = state;
    if (current is! SnapPreviewing) return;
    final updated = List<XFile>.from(current.files)..removeAt(index);
    state = updated.isEmpty ? const SnapIdle() : SnapPreviewing(files: updated);
  }

  // ── Upload ────────────────────────────────────────────────────────────────────

  Future<void> uploadAll() async {
    final current = state;
    if (current is! SnapPreviewing) return;

    final files = current.files;
    final total = files.length;

    // Show a transitional state immediately so the button is disabled and the
    // user sees feedback.  Riverpod state assignment is synchronous — it does
    // NOT consume the browser's transient user-activation window.
    state = SnapUploading(current: 0, total: total);

    // Obtain the Google Photos access token BEFORE any file I/O.
    // requestScopes() must open a browser popup, which requires transient user
    // activation.  Chrome's window expires ~5 s after the click; calling this
    // first (before potentially slow readAsBytes calls) keeps us well inside
    // that window.
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      state = const SnapError('無法取得 Google 授權，請重新登入。');
      return;
    }

    for (var i = 0; i < total; i++) {
      state = SnapUploading(current: i + 1, total: total);
      try {
        await _uploadOne(files[i], i, accessToken);
      } on FirebaseFunctionsException catch (e) {
        final detail = e.details?.toString();
        final base = e.message ?? '上傳失敗，請再試一次。';
        state = SnapError(detail != null ? '$base\n($detail)' : base);
        return;
      } catch (e) {
        state = SnapError(e.toString());
        return;
      }
    }

    state = SnapDone(count: total);
  }

  Future<void> _uploadOne(XFile file, int index, String accessToken) async {
    final bytes = await file.readAsBytes();
    final imageBase64 = base64Encode(bytes);
    final mimeType = file.mimeType ?? 'image/jpeg';
    final filename = 'lumi_${DateTime.now().millisecondsSinceEpoch}_$index.jpg';

    final service = ref.read(cloudFunctionsServiceProvider);
    final upload = await service.uploadToPhotos(
      imageBase64: imageBase64,
      mimeType: mimeType,
      filename: filename,
      accessToken: accessToken,
    );

    await _writePendingItem(
      mediaItemId: upload.mediaItemId,
      thumbnailUrl: upload.thumbnailUrl,
    );
  }

  Future<void> _writePendingItem({
    required String mediaItemId,
    required String thumbnailUrl,
  }) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception('User not authenticated.');

    final now = DateTime.now();
    final item = WardrobeItem(
      mediaItemId: mediaItemId,
      category: '',
      colors: const [],
      materials: const [],
      embedding: const [],
      thumbnailUrl: thumbnailUrl,
      createdAt: now,
      thumbnailRefreshedAt: now,
      analyzed: false,
    );

    await ref.read(wardrobeRepositoryProvider).addItem(user.uid, item);
  }

  Future<String?> _getAccessToken() async {
    // Return cached token if still valid (with 5-minute safety buffer).
    if (_cachedPhotosToken != null &&
        _tokenExpiry != null &&
        DateTime.now()
            .isBefore(_tokenExpiry!.subtract(const Duration(minutes: 5)))) {
      return _cachedPhotosToken;
    }

    final firebaseAuth = ref.read(firebaseAuthProvider);
    if (firebaseAuth.currentUser == null) return null;

    // Use signInWithPopup with prompt:'consent' to force Google to show the
    // full scope consent screen every time.  Without this, Google may return
    // a cached token that only has the basic email/profile scopes from the
    // initial login — resulting in a 403 "insufficient authentication scopes"
    // error when calling the Photos Library API.
    final provider = GoogleAuthProvider()
      ..addScope('https://www.googleapis.com/auth/photoslibrary.appendonly')
      ..addScope('https://www.googleapis.com/auth/photoslibrary.readonly')
      ..setCustomParameters({
        'prompt': 'consent',
        'access_type': 'online',
      });

    try {
      final result = await firebaseAuth.signInWithPopup(provider);
      final credential = result.credential as OAuthCredential?;
      final accessToken = credential?.accessToken;
      if (accessToken != null) {
        _cachedPhotosToken = accessToken;
        _tokenExpiry = DateTime.now().add(const Duration(hours: 1));
      }
      return accessToken;
    } catch (_) {
      return null;
    }
  }

  void reset() => state = const SnapIdle();
}
