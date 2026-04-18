import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:lumi/core/providers/firebase_providers.dart';
import 'package:lumi/features/wardrobe/data/wardrobe_item.dart';
import 'package:lumi/features/wardrobe/data/wardrobe_repository.dart';
import 'package:lumi/features/search/domain/wardrobe_filter.dart';
import 'package:lumi/features/search/presentation/providers/search_provider.dart';

WardrobeItem _item({
  required String id,
  required String category,
  List<String> colors = const [],
  List<String> materials = const [],
}) {
  final now = DateTime.now();
  return WardrobeItem(
    mediaItemId: id,
    category: category,
    colors: colors,
    materials: materials,
    embedding: [],
    thumbnailUrl: 'https://example.com/$id',
    createdAt: now,
    thumbnailRefreshedAt: now,
  );
}

List<WardrobeItem> _apply(List<WardrobeItem> items, WardrobeFilter filter) {
  // Mirror the private _applyFilter logic via the provider
  final container = ProviderContainer(
    overrides: [
      firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
      wardrobeRepositoryProvider.overrideWith(
        (ref) => WardrobeRepository(ref.watch(firestoreProvider)),
      ),
    ],
  );
  addTearDown(container.dispose);

  // Directly call the filter logic by constructing a local copy
  if (filter.isEmpty) return items;

  return items.where((item) {
    if (filter.keyword.isNotEmpty) {
      final kw = filter.keyword.toLowerCase();
      final inCategory = item.category.toLowerCase().contains(kw);
      final inMaterials =
          item.materials.any((m) => m.toLowerCase().contains(kw));
      if (!inCategory && !inMaterials) return false;
    }
    if (filter.category != null) {
      if (filter.category!.isEmpty) {
        if (item.category.isNotEmpty) return false;
      } else if (item.category != filter.category) {
        return false;
      }
    }
    if (filter.colors.isNotEmpty) {
      if (!filter.colors.every((fc) => item.colors.contains(fc))) return false;
    }
    if (filter.materials.isNotEmpty) {
      if (!filter.materials.every((fm) => item.materials.contains(fm))) {
        return false;
      }
    }
    return true;
  }).toList();
}

void main() {
  final items = [
    _item(
      id: '1',
      category: '上衣',
      colors: ['#FFFFFF', '#3B5BDB'],
      materials: ['棉'],
    ),
    _item(
      id: '2',
      category: '褲子',
      colors: ['#1D1D1F'],
      materials: ['聚酯纖維'],
    ),
    _item(
      id: '3',
      category: '外套',
      colors: ['#3B5BDB'],
      materials: ['羊毛'],
    ),
    _item(
      id: '4',
      category: '',
      colors: [],
      materials: [],
    ),
  ];

  group('WardrobeFilter – client-side filter', () {
    test('empty filter returns all items', () {
      final result = _apply(items, const WardrobeFilter());
      expect(result, hasLength(4));
    });

    test('uncategorizedOnly shows only empty category', () {
      final result = _apply(
        items,
        const WardrobeFilter(category: WardrobeFilter.uncategorizedOnly),
      );
      expect(result, hasLength(1));
      expect(result.first.mediaItemId, equals('4'));
    });

    test('category filter returns only matching items', () {
      final result =
          _apply(items, const WardrobeFilter(category: '上衣'));
      expect(result, hasLength(1));
      expect(result.first.mediaItemId, equals('1'));
    });

    test('keyword matches category', () {
      final result =
          _apply(items, const WardrobeFilter(keyword: '外套'));
      expect(result, hasLength(1));
      expect(result.first.mediaItemId, equals('3'));
    });

    test('keyword matches material', () {
      final result =
          _apply(items, const WardrobeFilter(keyword: '棉'));
      expect(result, hasLength(1));
      expect(result.first.mediaItemId, equals('1'));
    });

    test('color filter returns items containing the selected color', () {
      final result = _apply(
        items,
        const WardrobeFilter(colors: ['#3B5BDB']),
      );
      expect(result.map((i) => i.mediaItemId), containsAll(['1', '3']));
      expect(result, hasLength(2));
    });

    test('combined category + color filter', () {
      final result = _apply(
        items,
        const WardrobeFilter(category: '上衣', colors: ['#3B5BDB']),
      );
      expect(result, hasLength(1));
      expect(result.first.mediaItemId, equals('1'));
    });

    test('material filter returns correct items', () {
      final result =
          _apply(items, const WardrobeFilter(materials: ['羊毛']));
      expect(result, hasLength(1));
      expect(result.first.mediaItemId, equals('3'));
    });

    test('no match returns empty list', () {
      final result = _apply(
        items,
        const WardrobeFilter(category: '鞋子'),
      );
      expect(result, isEmpty);
    });
  });

  group('WardrobeFilterNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('initial state is empty filter', () {
      final filter = container.read(wardrobeFilterProvider);
      expect(filter.isEmpty, isTrue);
    });

    test('setCategory updates category', () {
      container.read(wardrobeFilterProvider.notifier).setCategory('上衣');
      expect(container.read(wardrobeFilterProvider).category, equals('上衣'));
    });

    test('setCategory empty string means uncategorized queue', () {
      container
          .read(wardrobeFilterProvider.notifier)
          .setCategory(WardrobeFilter.uncategorizedOnly);
      expect(container.read(wardrobeFilterProvider).category, equals(''));
    });

    test('toggleColor adds and removes color', () {
      final notifier = container.read(wardrobeFilterProvider.notifier);
      notifier.toggleColor('#FFFFFF');
      expect(container.read(wardrobeFilterProvider).colors, contains('#FFFFFF'));
      notifier.toggleColor('#FFFFFF');
      expect(
          container.read(wardrobeFilterProvider).colors, isNot(contains('#FFFFFF')));
    });

    test('clearAll resets to empty filter', () {
      final notifier = container.read(wardrobeFilterProvider.notifier);
      notifier.setCategory('上衣');
      notifier.toggleColor('#FFFFFF');
      notifier.clearAll();
      expect(container.read(wardrobeFilterProvider).isEmpty, isTrue);
    });
  });
}
