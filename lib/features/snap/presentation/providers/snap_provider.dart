import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
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

    for (var i = 0; i < total; i++) {
      state = SnapUploading(current: i + 1, total: total);
      try {
        await _uploadOne(files[i], i);
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

  Future<void> _uploadOne(XFile file, int index) async {
    final bytes = await file.readAsBytes();
    final imageBase64 = base64Encode(bytes);
    final mimeType = file.mimeType ?? 'image/jpeg';
    final filename = 'lumi_${DateTime.now().millisecondsSinceEpoch}_$index.jpg';

    final accessToken = await _getAccessToken();
    if (accessToken == null) throw Exception('無法取得 Google 授權，請重新登入。');

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
    final googleSignIn = ref.read(googleSignInProvider);

    // If not signed in at all, return null immediately.
    final user = googleSignIn.currentUser ?? await googleSignIn.signInSilently();
    if (user == null) return null;

    // On Flutter web with GIS (google_sign_in 6.x), authentication.accessToken
    // is null after the basic sign-in flow — GIS separates authentication
    // (idToken) from API authorisation (accessToken).
    // If we already have a token, use it.
    final auth = await user.authentication;
    if (auth.accessToken != null) return auth.accessToken;

    // Request authorisation for the Photos API scopes.
    // requestScopes() uses GIS TokenClient (OAuth2 popup) — NOT One Tap,
    // so it is unaffected by FedCM migration and will not hang.
    final granted = await googleSignIn.requestScopes([
      'https://www.googleapis.com/auth/photoslibrary.appendonly',
      'https://www.googleapis.com/auth/photoslibrary.readonly',
    ]);
    if (!granted) return null;

    final freshAuth = await googleSignIn.currentUser?.authentication;
    return freshAuth?.accessToken;
  }

  void reset() => state = const SnapIdle();
}
