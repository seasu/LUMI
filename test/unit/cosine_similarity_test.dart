import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

// Mirror of the TypeScript cosineSimilarity in compareClothing.ts
double cosineSimilarity(List<double> a, List<double> b) {
  if (a.length != b.length || a.isEmpty) return 0;

  double dot = 0;
  double normA = 0;
  double normB = 0;

  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }

  final denom = sqrt(normA) * sqrt(normB);
  return denom == 0 ? 0 : dot / denom;
}

void main() {
  group('cosineSimilarity', () {
    test('identical vectors → 1.0', () {
      final v = [1.0, 2.0, 3.0];
      expect(cosineSimilarity(v, v), closeTo(1.0, 1e-9));
    });

    test('orthogonal vectors → 0.0', () {
      expect(
        cosineSimilarity([1.0, 0.0], [0.0, 1.0]),
        closeTo(0.0, 1e-9),
      );
    });

    test('opposite vectors → -1.0', () {
      expect(
        cosineSimilarity([1.0, 0.0], [-1.0, 0.0]),
        closeTo(-1.0, 1e-9),
      );
    });

    test('empty vectors → 0.0', () {
      expect(cosineSimilarity([], []), equals(0.0));
    });

    test('length mismatch → 0.0', () {
      expect(cosineSimilarity([1.0, 2.0], [1.0]), equals(0.0));
    });

    test('zero vector → 0.0', () {
      expect(cosineSimilarity([0.0, 0.0], [1.0, 2.0]), equals(0.0));
    });

    test('similar vectors returns value close to 1.0', () {
      final a = [1.0, 2.0, 3.0];
      final b = [1.1, 1.9, 3.1];
      final result = cosineSimilarity(a, b);
      expect(result, greaterThan(0.99));
      expect(result, lessThanOrEqualTo(1.0));
    });

    test('≥80% threshold: nearly identical direction vectors', () {
      final a = [1.0, 0.0, 0.0];
      final b = [0.9, 0.1, 0.0];
      expect(cosineSimilarity(a, b), greaterThanOrEqualTo(0.8));
    });

    test('<50% threshold: orthogonal-ish vectors', () {
      final a = [1.0, 0.0, 0.0, 0.0];
      final b = [0.0, 0.0, 1.0, 0.0];
      expect(cosineSimilarity(a, b), lessThan(0.5));
    });
  });
}
