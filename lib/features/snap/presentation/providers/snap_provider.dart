import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../wardrobe/data/wardrobe_item.dart';
import '../../../wardrobe/data/wardrobe_repository.dart';
import '../../data/cloud_functions_service.dart';
import '../../domain/snap_state.dart';

final cloudFunctionsServiceProvider = Provider<CloudFunctionsService>((ref) {
  return CloudFunctionsService(ref.watch(cloudFunctionsProvider));
});

final snapProvider = NotifierProvider<SnapNotifier, SnapState>(SnapNotifier.new);

class SnapNotifier extends Notifier<SnapState> {
  @override
  SnapState build() => const SnapIdle();

  Future<void> snap() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (file == null) return; // User cancelled

    try {
      // ── Step 1: Analyze ───────────────────────────────────────────────────
      state = const SnapAnalyzing();
      final bytes = await file.readAsBytes();
      final imageBase64 = _toBase64(bytes);
      final mimeType = file.mimeType ?? 'image/jpeg';

      final service = ref.read(cloudFunctionsServiceProvider);
      final analysis = await service.analyzeClothing(
        imageBase64: imageBase64,
        mimeType: mimeType,
      );

      // ── Step 2: Get Google Photos access token ────────────────────────────
      state = const SnapUploading();
      final accessToken = await _getAccessToken();
      if (accessToken == null) throw Exception('Failed to get Google access token.');

      // ── Step 3: Upload to Google Photos ───────────────────────────────────
      final filename =
          'lumi_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final upload = await service.uploadToPhotos(
        imageBase64: imageBase64,
        mimeType: mimeType,
        filename: filename,
        accessToken: accessToken,
      );

      // ── Step 4: Write to Firestore (segment 4/4) ──────────────────────────
      await _writeToFirestore(
        mediaItemId: upload.mediaItemId,
        thumbnailUrl: upload.thumbnailUrl,
        analysis: analysis,
      );

      state = SnapDone(
        category: analysis.category,
        colors: analysis.colors,
        materials: analysis.materials,
      );
    } on FirebaseFunctionsException catch (e) {
      state = SnapError(e.message ?? '雲端處理失敗，請再試一次。');
    } catch (e) {
      state = SnapError(e.toString());
    }
  }

  void reset() => state = const SnapIdle();

  Future<String?> _getAccessToken() async {
    final googleSignIn = ref.read(googleSignInProvider);
    final user =
        googleSignIn.currentUser ?? await googleSignIn.signInSilently();
    final auth = await user?.authentication;
    return auth?.accessToken;
  }

  Future<void> _writeToFirestore({
    required String mediaItemId,
    required String thumbnailUrl,
    required AnalyzeClothingResult analysis,
  }) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) throw Exception('User not authenticated.');

    final now = DateTime.now();
    final item = WardrobeItem(
      mediaItemId: mediaItemId,
      category: analysis.category,
      colors: analysis.colors,
      materials: analysis.materials,
      embedding: analysis.embedding,
      thumbnailUrl: thumbnailUrl,
      createdAt: now,
      thumbnailRefreshedAt: now,
    );

    await ref.read(wardrobeRepositoryProvider).addItem(user.uid, item);
  }

  String _toBase64(List<int> bytes) => base64Encode(bytes);
}
