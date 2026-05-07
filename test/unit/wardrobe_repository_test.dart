import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumi/features/wardrobe/data/wardrobe_repository.dart';

void main() {
  const userId = 'test-user-123';
  const localFileName = 'abc123.jpg';
  const docId = 'abc123';

  group('WardrobeRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late WardrobeRepository repo;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repo = WardrobeRepository(fakeFirestore);
    });

    test('addItemLocal creates Firestore doc with analyzed=false', () async {
      final id = await repo.addItemLocal(
        userId,
        localFileName: localFileName,
        createdAt: DateTime(2024, 1, 15),
      );

      expect(id, equals(docId));

      final doc = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('wardrobe')
          .doc(docId)
          .get();

      expect(doc.exists, isTrue);
      expect(doc['localFileName'], equals(localFileName));
      expect(doc['analyzed'], isFalse);
    });

    test('updateAnalysis sets analyzed=true and populates fields', () async {
      await repo.addItemLocal(
        userId,
        localFileName: localFileName,
        createdAt: DateTime(2024, 1, 15),
      );

      await repo.updateAnalysis(
        userId,
        docId,
        category: '上衣',
        colors: ['#FFFFFF'],
        materials: ['棉'],
        embedding: [0.1, 0.2, 0.3],
      );

      final item = await repo.getItem(userId, docId);
      expect(item, isNotNull);
      expect(item!.analyzed, isTrue);
      expect(item.category, equals('上衣'));
      expect(item.colors, equals(['#FFFFFF']));
      expect(item.materials, equals(['棉']));
      expect(item.embedding, equals([0.1, 0.2, 0.3]));
    });

    test('markAnalyzeFailed sets analyzeError and keeps analyzed=false', () async {
      await repo.addItemLocal(
        userId,
        localFileName: localFileName,
        createdAt: DateTime.now(),
      );

      await repo.markAnalyzeFailed(userId, docId, 'analysis_failed:timeout');

      final item = await repo.getItem(userId, docId);
      expect(item!.analyzed, isFalse);
      expect(item.analyzeError, contains('analysis_failed'));
    });

    test('getItem returns null for non-existent docId', () async {
      final result = await repo.getItem(userId, 'does-not-exist');
      expect(result, isNull);
    });

    test('getItem returns correct item after addItemLocal', () async {
      await repo.addItemLocal(
        userId,
        localFileName: localFileName,
        createdAt: DateTime.now(),
      );

      final result = await repo.getItem(userId, docId);
      expect(result, isNotNull);
      expect(result!.localFileName, equals(localFileName));
    });

    test('deleteItem removes document from Firestore', () async {
      await repo.addItemLocal(
        userId,
        localFileName: localFileName,
        createdAt: DateTime.now(),
      );

      final before = await repo.getItem(userId, docId);
      expect(before, isNotNull);

      await repo.deleteItem(userId, docId, localFileName: localFileName);

      final after = await repo.getItem(userId, docId);
      expect(after, isNull);
    });

    test('watchWardrobe emits items in descending createdAt order', () async {
      await repo.addItemLocal(
        userId,
        localFileName: 'old.jpg',
        createdAt: DateTime(2024, 1, 1),
      );
      await repo.addItemLocal(
        userId,
        localFileName: 'new.jpg',
        createdAt: DateTime(2024, 6, 1),
      );

      final items = await repo.watchWardrobe(userId).first;
      expect(items.first.localFileName, equals('new.jpg'));
      expect(items.last.localFileName, equals('old.jpg'));
    });

    test('prefetchWardrobeFromServer completes without error', () async {
      await repo.addItemLocal(
        userId,
        localFileName: localFileName,
        createdAt: DateTime.now(),
      );
      await expectLater(repo.prefetchWardrobeFromServer(userId), completes);
    });
  });
}
