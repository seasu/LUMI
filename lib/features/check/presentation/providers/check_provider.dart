import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../features/snap/data/cloud_functions_service.dart';
import '../../../../features/snap/presentation/providers/snap_provider.dart';
import '../../domain/check_state.dart';

final checkProvider =
    NotifierProvider<CheckNotifier, CheckState>(CheckNotifier.new);

class CheckNotifier extends Notifier<CheckState> {
  @override
  CheckState build() => const CheckIdle();

  Future<void> check() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (file == null) return;

    try {
      state = const CheckAnalyzing();

      final bytes = await file.readAsBytes();
      final imageBase64 = base64Encode(bytes);
      final mimeType = file.mimeType ?? 'image/jpeg';

      final service = ref.read(cloudFunctionsServiceProvider);
      final result = await service.compareClothing(
        imageBase64: imageBase64,
        mimeType: mimeType,
      );

      if (result.similarity >= 0.8 &&
          result.matchedThumbnailUrl != null &&
          result.matchedCategory != null) {
        state = CheckHighSimilarity(
          similarity: result.similarity,
          matchedThumbnailUrl: result.matchedThumbnailUrl!,
          matchedCategory: result.matchedCategory!,
          newImageBytes: bytes,
        );
      } else if (result.similarity >= 0.5 && result.matchedCategory != null) {
        state = CheckMediumSimilarity(
          similarity: result.similarity,
          matchedCategory: result.matchedCategory!,
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

  void reset() => state = const CheckIdle();
}
