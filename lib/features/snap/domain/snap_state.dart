sealed class SnapState {
  const SnapState();
}

class SnapIdle extends SnapState {
  const SnapIdle();
}

class SnapAnalyzing extends SnapState {
  const SnapAnalyzing();
}

class SnapUploading extends SnapState {
  const SnapUploading();
}

class SnapDone extends SnapState {
  const SnapDone({
    required this.category,
    required this.colors,
    required this.materials,
  });

  final String category;
  final List<String> colors;
  final List<String> materials;
}

class SnapError extends SnapState {
  const SnapError(this.message);

  final String message;
}
