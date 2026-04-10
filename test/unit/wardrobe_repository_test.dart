import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lumi/features/wardrobe/data/wardrobe_item.dart';
import 'package:lumi/features/wardrobe/data/wardrobe_repository.dart';

void main() {
  const userId = 'test-user-123';

  WardrobeItem _makeItem({
    String mediaItemId = 'item-001',
    DateTime? thumbnailRefreshedAt,
  }) {
    final now = DateTime.now();
    return WardrobeItem(
      mediaItemId: mediaItemId,
      category: '上衣',
      colors: const ['#FFFFFF', '#3B5BDB'],
      materials: const ['棉'],
      embedding: List.generate(10, (i) => i.toDouble()),
      thumbnailUrl: 'https://photos.example.com/thumb',
      createdAt: now,
      thumbnailRefreshedAt: thumbnailRefreshedAt ?? now,
    );
  }

  group('WardrobeRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late WardrobeRepository repo;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repo = WardrobeRepository(fakeFirestore);
    });

    test('addItem writes correct data to Firestore', () async {
      final item = _makeItem();
      await repo.addItem(userId, item);

      final doc = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('wardrobe')
          .doc(item.mediaItemId)
          .get();

      expect(doc.exists, isTrue);
      expect(doc['category'], equals('上衣'));
      expect(doc['colors'], equals(['#FFFFFF', '#3B5BDB']));
      expect(doc['materials'], equals(['棉']));
      expect(doc['embedding'], hasLength(10));
    });

    test('getItem returns null for non-existent mediaItemId', () async {
      final result = await repo.getItem(userId, 'does-not-exist');
      expect(result, isNull);
    });

    test('getItem returns correct item after addItem', () async {
      final item = _makeItem();
      await repo.addItem(userId, item);

      final result = await repo.getItem(userId, item.mediaItemId);
      expect(result, isNotNull);
      expect(result!.category, equals('上衣'));
      expect(result.colors, equals(['#FFFFFF', '#3B5BDB']));
    });

    test('watchWardrobe emits items in descending createdAt order', () async {
      final older = _makeItem(
        mediaItemId: 'item-old',
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final newer = _makeItem(
        mediaItemId: 'item-new',
      );

      await repo.addItem(userId, older);
      await repo.addItem(userId, newer);

      final items = await repo.watchWardrobe(userId).first;
      expect(items.first.mediaItemId, equals('item-new'));
      expect(items.last.mediaItemId, equals('item-old'));
    });

    test('refreshThumbnailUrl updates Firestore with fresh URL', () async {
      final item = _makeItem();
      await repo.addItem(userId, item);

      const freshUrl = 'https://photos.example.com/fresh-thumb';
      final mockClient = MockClient((request) async {
        expect(
          request.headers['Authorization'],
          equals('Bearer test-access-token'),
        );
        return http.Response(
          '{"baseUrl": "$freshUrl"}',
          200,
        );
      });

      final repoWithMock = WardrobeRepository(fakeFirestore, httpClient: mockClient);
      final result = await repoWithMock.refreshThumbnailUrl(
        userId: userId,
        mediaItemId: item.mediaItemId,
        accessToken: 'test-access-token',
      );

      expect(result, equals(freshUrl));

      final updated = await repo.getItem(userId, item.mediaItemId);
      expect(updated!.thumbnailUrl, equals(freshUrl));
    });
  });

  group('WardrobeItem.isThumbnailStale', () {
    test('returns false when refreshed less than 55 minutes ago', () {
      final item = _makeItem(
        thumbnailRefreshedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );
      expect(item.isThumbnailStale, isFalse);
    });

    test('returns true when refreshed exactly 55 minutes ago', () {
      final item = _makeItem(
        thumbnailRefreshedAt: DateTime.now().subtract(const Duration(minutes: 55)),
      );
      expect(item.isThumbnailStale, isTrue);
    });

    test('returns true when refreshed more than 55 minutes ago', () {
      final item = _makeItem(
        thumbnailRefreshedAt: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(item.isThumbnailStale, isTrue);
    });
  });
}
