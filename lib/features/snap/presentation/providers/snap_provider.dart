import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/providers/firebase_providers.dart'
    show firebaseAuthProvider;
import '../../../../core/storage/local_image_storage.dart';
import '../../../wardrobe/data/wardrobe_repository.dart';
import '../../data/cloud_functions_service.dart';
import '../../domain/snap_state.dart';

const _maxPhotos = 10;

typedef _AnalysisTask = ({
  String docId,
  List<int> bytes,
  String mimeType,
  String userId,
});

final snapProvider = NotifierProvider<SnapNotifier, SnapState>(SnapNotifier.new);

class SnapNotifier extends Notifier<SnapState> {
  @override
  SnapState build() => const SnapIdle();

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final current = state;
    final existing = current is SnapPreviewing ? current.files : <XFile>[];
    final remaining = _maxPhotos - existing.length;
    if (remaining <= 0) return;

    final files = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (files.isEmpty) return;
    final merged = [...existing, ...files.take(remaining)];
    state = SnapPreviewing(files: merged);
  }

  Future<void> takePhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (file == null) return;
    final current = state;
    if (current is SnapPreviewing && current.files.length < _maxPhotos) {
      state = SnapPreviewing(files: [...current.files, file]);
    } else {
      state = SnapPreviewing(files: [file]);
    }
  }

  void removeFile(int index) {
    final current = state;
    if (current is! SnapPreviewing) return;
    final updated = List<XFile>.from(current.files)..removeAt(index);
    state = updated.isEmpty ? const SnapIdle() : SnapPreviewing(files: updated);
  }

  Future<void> uploadAll() async {
    final current = state;
    if (current is! SnapPreviewing) return;

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      state = const SnapError('請先登入再加入衣物。');
      return;
    }

    final files = current.files;
    final total = files.length;
    final tasks = <_AnalysisTask>[];

    for (var i = 0; i < total; i++) {
      state = SnapUploading(current: i + 1, total: total);
      try {
        final task = await _saveOne(files[i], user.uid);
        tasks.add(task);
      } catch (e) {
        state = SnapError(
          '儲存失敗，請再試一次。\n'
          '技術訊息：$e',
        );
        return;
      }
    }

    state = SnapDone(count: total);

    // Analyze sequentially in background — prevents concurrent Gemini API calls
    // that would trigger rate-limit errors when uploading multiple photos.
    unawaited(_runAnalysesSequentially(tasks));
  }

  Future<_AnalysisTask> _saveOne(XFile file, String userId) async {
    final bytes = await file.readAsBytes();

    // image_picker with imageQuality: 85 converts HEIC/PNG → JPEG on iOS.
    // Detect actual format by magic bytes (FF D8 = JPEG).
    final isActuallyJpeg =
        bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;
    final mimeType = isActuallyJpeg ? 'image/jpeg' : _effectiveMimeType(file);
    final ext = isActuallyJpeg ? 'jpg' : _extForMime(_effectiveMimeType(file));

    // 1. Persist to device storage.
    final fileName = await LocalImageStorage.saveImage(bytes, extension: ext);

    // 2. Create Firestore doc (analyzed: false) — visible immediately in wardrobe.
    final repo = ref.read(wardrobeRepositoryProvider);
    final docId = await repo.addItemLocal(
      userId,
      localFileName: fileName,
      createdAt: DateTime.now(),
    );

    return (docId: docId, bytes: bytes, mimeType: mimeType, userId: userId);
  }

  Future<void> _runAnalysesSequentially(List<_AnalysisTask> tasks) async {
    for (final task in tasks) {
      await _analyzeInBackground(
        task.docId,
        task.bytes,
        task.mimeType,
        task.userId,
      );
    }
  }

  Future<void> _analyzeInBackground(
    String docId,
    List<int> bytes,
    String mimeType,
    String userId,
  ) async {
    final repo = ref.read(wardrobeRepositoryProvider);
    try {
      final service = ref.read(cloudFunctionsServiceProvider);
      final imageBase64 = base64Encode(bytes);
      final result = await service.analyzeClothing(
        imageBase64: imageBase64,
        mimeType: mimeType,
      );
      await repo.updateAnalysis(
        userId,
        docId,
        category: result.category,
        colors: result.colors,
        materials: result.materials,
        embedding: result.embedding,
      );
    } catch (e) {
      final msg = 'analysis_failed:${formatFirebaseCallableError(e)}';
      try {
        await repo.markAnalyzeFailed(userId, docId, msg);
      } catch (_) {}
    }
  }

  void reset() => state = const SnapIdle();
}

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
    default:
      return 'image/jpeg';
  }
}

String _fileExtension(String filepath) {
  final i = filepath.lastIndexOf('.');
  if (i < 0 || i >= filepath.length - 1) return '';
  return filepath.substring(i);
}

String _extForMime(String mime) {
  switch (mime) {
    case 'image/heic':
    case 'image/heif':
      return 'heic';
    case 'image/png':
      return 'png';
    case 'image/webp':
      return 'webp';
    case 'image/gif':
      return 'gif';
    default:
      return 'jpg';
  }
}
