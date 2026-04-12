import '../../../features/snap/data/cloud_functions_service.dart';

sealed class CheckState {
  const CheckState();
}

class CheckIdle extends CheckState {
  const CheckIdle();
}

class CheckAnalyzing extends CheckState {
  const CheckAnalyzing();
}

/// similarity >= 0.8 for the top match
class CheckHighSimilarity extends CheckState {
  const CheckHighSimilarity({
    required this.topMatches,
    required this.newImageBytes,
  });

  final List<MatchedClothingItem> topMatches;
  final List<int> newImageBytes;
}

/// 0.5 <= similarity < 0.8 for the top match
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
