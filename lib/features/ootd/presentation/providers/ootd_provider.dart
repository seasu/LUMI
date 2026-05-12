import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/ootd_repository.dart';
import '../../domain/ootd_state.dart';

final ootdAddProvider =
    NotifierProvider<OotdAddNotifier, OotdAddState>(OotdAddNotifier.new);

class OotdAddNotifier extends Notifier<OotdAddState> {
  @override
  OotdAddState build() => const OotdAddIdle();

  Future<void> pickPhoto({ImageSource source = ImageSource.camera}) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 1200,
        imageQuality: 70,
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
    } catch (_) {
      state = const OotdAddIdle();
    }
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
      final item = await ref.read(ootdLocalProvider.notifier).save(
            caption: current.caption,
            date: current.date,
            imageBytes: current.photoBytes,
          );
      state = OotdAddResult(item: item, photoBytes: current.photoBytes);
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
