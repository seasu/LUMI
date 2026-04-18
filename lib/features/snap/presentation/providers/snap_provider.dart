import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/firebase_providers.dart'
    show cloudFunctionsServiceProvider, firebaseAuthProvider,
        googleSignInProvider, kGooglePhotosAppendOnlyScope;
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

    state = SnapUploading(current: 0, total: total);

    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      state = const SnapError(
        '無法取得 Google 授權，請重新登入後再試。\n'
        '錯誤代號：LUMI-SNAP-AUTH-TOKEN-EMPTY',
      );
      return;
    }

    for (var i = 0; i < total; i++) {
      state = SnapUploading(current: i + 1, total: total);
      try {
        await _uploadOne(files[i], i, accessToken);
      } on FirebaseFunctionsException catch (e) {
        state = SnapError(_mapFunctionsError(e));
        return;
      } on FormatException catch (e) {
        state = SnapError(
          '上傳結果格式異常，請再試一次；若重複發生請聯絡開發者。\n'
          '錯誤代號：LUMI-SNAP-BAD-RESPONSE\n'
          '技術訊息：$e',
        );
        return;
      } catch (e) {
        state = SnapError(
          '上傳過程發生未預期錯誤，請稍後再試。\n'
          '錯誤代號：LUMI-SNAP-UNKNOWN\n'
          '技術訊息：$e',
        );
        return;
      }
    }

    state = SnapDone(count: total);
  }

  Future<void> _uploadOne(XFile file, int index, String accessToken) async {
    final bytes = await file.readAsBytes();
    final imageBase64 = base64Encode(bytes);
    final mimeType = _effectiveMimeType(file);
    final filename =
        'lumi_${DateTime.now().millisecondsSinceEpoch}_$index${_extForMime(mimeType)}';

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

  /// Gets the Google Photos access token from the existing GoogleSignIn session.
  ///
  /// Since [googleSignInProvider] already requests [photoslibrary.appendonly]
  /// during initial login, we first try to reuse that token silently.
  /// On Web, the access token can still be missing after a restored session,
  /// so we fall back to an explicit sign-in prompt to re-grant Photos scope.
  Future<String?> _getAccessToken() async {
    // Return cached token if still valid (with 5-minute safety buffer).
    if (_cachedPhotosToken != null &&
        _tokenExpiry != null &&
        DateTime.now()
            .isBefore(_tokenExpiry!.subtract(const Duration(minutes: 5)))) {
      return _cachedPhotosToken;
    }

    final googleSignIn = ref.read(googleSignInProvider);
    final photosScope = kGooglePhotosAppendOnlyScope;

    /// On Web / iOS GIS, [GoogleSignInAuthentication.accessToken] is often null
    /// until [GoogleSignIn.requestScopes] is completed for incremental auth.
    Future<String?> readToken(GoogleSignInAccount? account) async {
      if (account == null) return null;
      var auth = await account.authentication;
      var token = auth.accessToken;
      if (token != null) return token;

      final granted = await googleSignIn.requestScopes([photosScope]);
      if (!granted) return null;

      auth = await account.authentication;
      return auth.accessToken;
    }

    try {
      GoogleSignInAccount? googleUser =
          googleSignIn.currentUser ?? await googleSignIn.signInSilently();

      var token = await readToken(googleUser);
      if (token != null) {
        _cachedPhotosToken = token;
        _tokenExpiry = DateTime.now().add(const Duration(hours: 1));
        return token;
      }

      googleUser = await googleSignIn.signIn();
      token = await readToken(googleUser);
      if (token != null) {
        _cachedPhotosToken = token;
        _tokenExpiry = DateTime.now().add(const Duration(hours: 1));
        return token;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  String _mapFunctionsError(FirebaseFunctionsException e) {
    final raw = '${e.message ?? ''} ${e.details ?? ''}'.toLowerCase();
    final fnCode = e.code.toLowerCase();

    if (raw.contains('batchcreate') &&
        (raw.contains('album') ||
            raw.contains('not found') ||
            raw.contains('invalid argument'))) {
      return '上傳相簿資料失效，請重試一次。\n'
          '錯誤代號：LUMI-SNAP-ALBUM-STALE';
    }

    if (raw.contains('upload bytes failed') ||
        raw.contains('/uploads') ||
        raw.contains('permission denied')) {
      return 'Google 相簿上傳失敗，請確認授權後重試。\n'
          '錯誤代號：LUMI-SNAP-PHOTOS-UPLOAD';
    }

    if (fnCode == 'unauthenticated') {
      return '登入狀態已失效，請重新登入後再試。\n'
          '錯誤代號：LUMI-SNAP-FN-UNAUTH';
    }

    if (fnCode == 'internal') {
      if (raw.contains('missing preview url')) {
        return 'Google 相簿尚未產生縮圖連結（常見於 HEIC）。請改用「相機」 JPEG 或在相簿將照片轉成 JPEG 後再上傳。\n'
            '錯誤代號：LUMI-SNAP-NO-PREVIEW-URL';
      }
      return '伺服器暫時忙碌，請稍後再試。\n'
          '錯誤代號：LUMI-SNAP-FN-INTERNAL';
    }

    return '上傳失敗，請再試一次。\n'
        '錯誤代號：LUMI-SNAP-FN-${fnCode.toUpperCase()}';
  }

  void reset() => state = const SnapIdle();
}

/// Web/iOS may omit [XFile.mimeType]; match bytes & path so HEIC is not mislabeled as JPEG.
String _effectiveMimeType(XFile file) {
  final fromPicker = file.mimeType;
  if (fromPicker != null &&
      fromPicker.isNotEmpty &&
      fromPicker != 'application/octet-stream') {
    return fromPicker;
  }
  final ext = _fileExtension(file.path).toLowerCase();
  switch (ext) {
    case '.heic':
    case '.heif':
      return 'image/heic';
    case '.png':
      return 'image/png';
    case '.webp':
      return 'image/webp';
    case '.gif':
      return 'image/gif';
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    default:
      return 'image/jpeg';
  }
}

/// Best-effort extension from picker path/name (handles `IMG_1234.HEIC`).
String _fileExtension(String filepath) {
  final i = filepath.lastIndexOf('.');
  if (i < 0 || i >= filepath.length - 1) return '';
  return filepath.substring(i);
}

String _extForMime(String mime) {
  switch (mime) {
    case 'image/heic':
    case 'image/heif':
      return '.heic';
    case 'image/png':
      return '.png';
    case 'image/webp':
      return '.webp';
    case 'image/gif':
      return '.gif';
    default:
      return '.jpg';
  }
}
