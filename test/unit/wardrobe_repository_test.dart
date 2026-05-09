import 'package:flutter_test/flutter_test.dart';
import 'package:lumi/features/wardrobe/data/wardrobe_item.dart';
import 'package:lumi/features/check/domain/similarity.dart';

void main() {
  group('WardrobeItem JSON serialization', () {
    test('toJson/fromJson roundtrip preserves all fields', () {
      final original = WardrobeItem(
        docId: 'abc123',
        localFileName: 'abc123.jpg',
        category: '上衣',
        colors: ['#FFFFFF', '#3B5BDB'],
        materials: ['棉'],
        embedding: [0.1, 0.2, 0.3],
        createdAt: DateTime.utc(2026, 5, 9, 10, 0),
        analyzed: true,
      );

      final restored = WardrobeItem.fromJson(original.toJson());

      expect(restored.docId, equals(original.docId));
      expect(restored.localFileName, equals(original.localFileName));
      expect(restored.category, equals(original.category));
      expect(restored.colors, equals(original.colors));
      expect(restored.materials, equals(original.materials));
      expect(restored.embedding, equals(original.embedding));
      expect(restored.analyzed, isTrue);
      expect(restored.analyzeError, isNull);
    });

    test('analyzeError is preserved in JSON', () {
      final item = WardrobeItem(
        docId: 'abc',
        localFileName: 'abc.jpg',
        category: '',
        colors: const [],
        materials: const [],
        embedding: const [],
        createdAt: DateTime.utc(2026, 1, 1),
        analyzed: false,
        analyzeError: 'analysis_failed:timeout',
      );

      final restored = WardrobeItem.fromJson(item.toJson());
      expect(restored.analyzeError, equals('analysis_failed:timeout'));
      expect(restored.analyzed, isFalse);
    });

    test('analyzed: false survives roundtrip', () {
      final item = WardrobeItem(
        docId: 'pending',
        localFileName: 'pending.jpg',
        category: '',
        colors: const [],
        materials: const [],
        embedding: const [],
        createdAt: DateTime.utc(2026, 1, 1),
        analyzed: false,
      );

      final restored = WardrobeItem.fromJson(item.toJson());
      expect(restored.analyzed, isFalse);
      expect(restored.analyzeError, isNull);
    });

    test('embedding list is correctly encoded/decoded as floats', () {
      final item = WardrobeItem(
        docId: 'e',
        localFileName: 'e.jpg',
        category: '',
        colors: const [],
        materials: const [],
        embedding: [0.5, -0.25, 1.0],
        createdAt: DateTime.utc(2026, 1, 1),
        analyzed: true,
      );

      final restored = WardrobeItem.fromJson(item.toJson());
      expect(restored.embedding, equals([0.5, -0.25, 1.0]));
    });
  });

  group('cosineSimilarity', () {
    test('identical vectors return 1.0', () {
      expect(cosineSimilarity([1.0, 0.0, 0.0], [1.0, 0.0, 0.0]),
          closeTo(1.0, 1e-9));
    });

    test('orthogonal vectors return 0.0', () {
      expect(cosineSimilarity([1.0, 0.0], [0.0, 1.0]), closeTo(0.0, 1e-9));
    });

    test('opposite vectors return -1.0', () {
      expect(cosineSimilarity([1.0, 0.0], [-1.0, 0.0]), closeTo(-1.0, 1e-9));
    });

    test('empty vectors return 0.0', () {
      expect(cosineSimilarity([], []), equals(0.0));
    });
  });

  group('findTopMatches', () {
    WardrobeItem makeItem(String id, List<double> embedding) => WardrobeItem(
          docId: id,
          localFileName: '$id.jpg',
          category: id,
          colors: const [],
          materials: const [],
          embedding: embedding,
          createdAt: DateTime.utc(2026, 1, 1),
          analyzed: true,
        );

    final wardrobe = [
      makeItem('a', [1.0, 0.0, 0.0]),
      makeItem('b', [0.0, 1.0, 0.0]),
      makeItem('c', [1.0, 0.0, 0.0]), // same direction as 'a'
    ];

    test('returns top-k sorted by similarity', () {
      final matches = findTopMatches([1.0, 0.0, 0.0], wardrobe, topK: 2);
      expect(matches.length, equals(2));
      expect(matches.first.similarity, closeTo(1.0, 1e-9));
    });

    test('skips items with empty embedding', () {
      final noEmb = makeItem('empty', const []);
      final result = findTopMatches([1.0, 0.0, 0.0], [noEmb]);
      expect(result, isEmpty);
    });

    test('empty query embedding returns empty', () {
      final result = findTopMatches([], wardrobe);
      expect(result, isEmpty);
    });

    test('top match is most similar item', () {
      final matches = findTopMatches([0.0, 1.0, 0.0], wardrobe, topK: 1);
      expect(matches.first.docId, equals('b'));
    });
  });
}
