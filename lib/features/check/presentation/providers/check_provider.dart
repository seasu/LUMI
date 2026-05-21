import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/storage/local_image_storage.dart';
import '../../../../core/storage/local_wardrobe_store.dart';
import '../../../../features/snap/data/cloud_functions_service.dart';
import '../../domain/check_state.dart';
import '../../domain/similarity.dart';

final checkProvider =
    NotifierProvider<CheckNotifier, CheckState>(CheckNotifier.new);

class CheckNotifier extends Notifier<CheckState> {
  @override
  CheckState build() => const CheckIdle();

  Future<void> check({ImageSource source = ImageSource.camera}) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (file == null) return;

    try {
      final bytes = await file.readAsBytes();
      state = CheckAnalyzing(imageBytes: bytes);

      final imageBase64 = base64Encode(bytes);
      final mimeType = file.mimeType ?? 'image/jpeg';

      // 1. Analyze the new item to get its embedding.
      final service = ref.read(cloudFunctionsServiceProvider);
      final result = await service.analyzeClothing(
        imageBase64: imageBase64,
        mimeType: mimeType,
      );

      // 2. Compare against all local wardrobe items on-device.
      final wardrobe = ref.read(localWardrobeProvider).valueOrNull ?? [];
      final matches = findTopMatches(result.embedding, wardrobe);

      final topSimilarity = matches.isNotEmpty ? matches.first.similarity : 0.0;

      if (topSimilarity >= 0.8) {
        state = CheckHighSimilarity(
          topMatches: matches,
          newImageBytes: bytes,
          analysisResult: result,
        );
      } else if (topSimilarity >= 0.5) {
        state = CheckMediumSimilarity(
          topMatches: matches,
          newImageBytes: bytes,
          analysisResult: result,
        );
      } else {
        state = const CheckNone();
      }
    } on FirebaseFunctionsException catch (e) {
      state = CheckError(e.message ?? '比對失敗，請再試一次。');
    } catch (e) {
      state = CheckError(e.toString());
    }
  }

  /// Saves the already-analyzed photo directly to the local wardrobe.
  /// Reuses the AI result from the current check state — no extra Cloud
  /// Function call needed.
  Future<void> addToWardrobe() async {
    final s = state;
    final List<int> bytes;
    final AnalyzeClothingResult result;
    switch (s) {
      case CheckHighSimilarity(:final newImageBytes, :final analysisResult):
        bytes = newImageBytes;
        result = analysisResult;
      case CheckMediumSimilarity(:final newImageBytes, :final analysisResult):
        bytes = newImageBytes;
        result = analysisResult;
      default:
        return;
    }

    final fileName = await LocalImageStorage.saveImage(bytes);
    final docId = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;
    final store = ref.read(localWardrobeProvider.notifier);
    await store.addItem(localFileName: fileName, createdAt: DateTime.now());
    await store.updateAnalysis(
      docId,
      category: result.category,
      colors: result.colors,
      materials: result.materials,
      embedding: result.embedding,
    );
    state = const CheckIdle();
  }

  void reset() => state = const CheckIdle();
}
