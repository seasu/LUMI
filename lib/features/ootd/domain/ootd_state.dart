import 'dart:typed_data';
import 'ootd_item.dart';

sealed class OotdAddState {
  const OotdAddState();
}

class OotdAddIdle extends OotdAddState {
  const OotdAddIdle();
}

class OotdAddEditing extends OotdAddState {
  const OotdAddEditing({
    required this.photoBytes,
    required this.date,
    required this.caption,
  });

  final Uint8List photoBytes;
  final DateTime date;
  final String caption;

  OotdAddEditing copyWith({String? caption}) => OotdAddEditing(
        photoBytes: photoBytes,
        date: date,
        caption: caption ?? this.caption,
      );
}

class OotdAddSaving extends OotdAddState {
  const OotdAddSaving();
}

class OotdAddResult extends OotdAddState {
  const OotdAddResult({
    required this.item,
    required this.photoBytes,
  });

  final OotdItem item;
  final Uint8List photoBytes;
}

class OotdAddError extends OotdAddState {
  const OotdAddError(this.message);
  final String message;
}
