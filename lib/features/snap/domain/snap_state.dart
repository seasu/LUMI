import 'package:image_picker/image_picker.dart';

sealed class SnapState {
  const SnapState();
}

class SnapIdle extends SnapState {
  const SnapIdle();
}

/// User has selected photos and is previewing before upload.
class SnapPreviewing extends SnapState {
  const SnapPreviewing({required this.files});
  final List<XFile> files;
}

/// Uploading batch — [current] is 1-based index of the photo being uploaded.
class SnapUploading extends SnapState {
  const SnapUploading({required this.current, required this.total});
  final int current;
  final int total;
}

/// All photos uploaded successfully; AI analysis is running server-side.
class SnapDone extends SnapState {
  const SnapDone({required this.count});
  final int count;
}

class SnapError extends SnapState {
  const SnapError(this.message);
  final String message;
}
