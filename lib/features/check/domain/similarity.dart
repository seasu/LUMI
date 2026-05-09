import 'dart:math';

import '../../snap/data/cloud_functions_service.dart';
import '../../wardrobe/data/wardrobe_item.dart';

double cosineSimilarity(List<double> a, List<double> b) {
  if (a.length != b.length || a.isEmpty) return 0;
  double dot = 0, normA = 0, normB = 0;
  for (int i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  final denom = sqrt(normA) * sqrt(normB);
  return denom == 0 ? 0 : dot / denom;
}

/// Returns the top [topK] wardrobe items most similar to [queryEmbedding].
/// Items without embeddings are skipped.
List<MatchedClothingItem> findTopMatches(
  List<double> queryEmbedding,
  List<WardrobeItem> wardrobe, {
  int topK = 5,
}) {
  if (queryEmbedding.isEmpty) return const [];

  final scored = <({double sim, WardrobeItem item})>[];
  for (final item in wardrobe) {
    if (item.embedding.isEmpty) continue;
    scored.add((sim: cosineSimilarity(queryEmbedding, item.embedding), item: item));
  }

  scored.sort((a, b) => b.sim.compareTo(a.sim));

  return scored.take(topK).map((e) => MatchedClothingItem(
        similarity: e.sim,
        docId: e.item.docId,
        localFileName: e.item.localFileName,
        category: e.item.category,
        colors: e.item.colors,
      )).toList();
}
