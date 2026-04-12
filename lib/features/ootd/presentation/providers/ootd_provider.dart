import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../data/ootd_repository.dart';
import '../../domain/ootd_item.dart';
import '../../domain/ootd_state.dart';

final ootdAddProvider =
    NotifierProvider<OotdAddNotifier, OotdAddState>(OotdAddNotifier.new);

class OotdAddNotifier extends Notifier<OotdAddState> {
  @override
  OotdAddState build() => const OotdAddIdle();

  Future<void> pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (file == null) {
      state = const OotdAddIdle();
      return;
    }

    final bytes = await file.readAsBytes();
    state = OotdAddEditing(
      photoBytes: bytes,
      date: DateTime.now(),
      caption: '',
    );
  }

  void updateCaption(String caption) {
    final current = state;
    if (current is! OotdAddEditing) return;
    state = current.copyWith(caption: caption);
  }

  Future<void> save() async {
    final current = state;
    if (current is! OotdAddEditing) return;

    state = const OotdAddSaving();

    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) throw Exception('未登入');

      // Compress for Firestore storage (base64)
      final imageBase64 = base64Encode(current.photoBytes);

      final now = DateTime.now();
      final draft = OotdItem(
        id: '',
        imageBase64: imageBase64,
        caption: current.caption,
        date: current.date,
        createdAt: now,
      );

      final saved = await ref
          .read(ootdRepositoryProvider)
          .addItem(user.uid, draft);

      state = OotdAddResult(item: saved, photoBytes: current.photoBytes);
    } catch (e) {
      state = OotdAddError(e.toString());
    }
  }

  void retake() {
    final current = state;
    if (current is! OotdAddEditing) return;
    state = const OotdAddIdle();
  }

  void reset() => state = const OotdAddIdle();
}
