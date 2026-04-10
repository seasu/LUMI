sealed class CheckState {
  const CheckState();
}

class CheckIdle extends CheckState {
  const CheckIdle();
}

class CheckAnalyzing extends CheckState {
  const CheckAnalyzing();
}

/// similarity >= 0.8
class CheckHighSimilarity extends CheckState {
  const CheckHighSimilarity({
    required this.similarity,
    required this.matchedThumbnailUrl,
    required this.matchedCategory,
    required this.newImageBytes,
  });

  final double similarity;
  final String matchedThumbnailUrl;
  final String matchedCategory;
  final List<int> newImageBytes;
}

/// 0.5 <= similarity < 0.8
class CheckMediumSimilarity extends CheckState {
  const CheckMediumSimilarity({
    required this.similarity,
    required this.matchedCategory,
  });

  final double similarity;
  final String matchedCategory;
}

/// similarity < 0.5
class CheckNone extends CheckState {
  const CheckNone();
}

class CheckError extends CheckState {
  const CheckError(this.message);

  final String message;
}
