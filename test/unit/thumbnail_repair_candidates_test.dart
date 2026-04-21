import 'package:flutter_test/flutter_test.dart';
import 'package:lumi/features/search/presentation/providers/thumbnail_repair_candidates.dart';
import 'package:lumi/features/wardrobe/data/wardrobe_item.dart';

void main() {
  WardrobeItem makeItem({
    required String mediaItemId,
    required String thumbnailUrl,
    DateTime? thumbnailRefreshedAt,
  }) {
    final now = DateTime.now();
    return WardrobeItem(
      mediaItemId: mediaItemId,
      category: '上衣',
      colors: const ['#FFFFFF'],
      materials: const ['棉'],
      embedding: const [0.1, 0.2],
      thumbnailUrl: thumbnailUrl,
      createdAt: now,
      thumbnailRefreshedAt: thumbnailRefreshedAt ?? now,
    );
  }

  test('collectThumbnailRepairCandidates keeps only stale or invalid thumbnails', () {
    final now = DateTime.now();
    final items = [
      makeItem(
        mediaItemId: 'fresh-cdn',
        thumbnailUrl: 'https://lh3.googleusercontent.com/fresh=s512',
        thumbnailRefreshedAt: now.subtract(const Duration(minutes: 10)),
      ),
      makeItem(
        mediaItemId: 'stale-cdn',
        thumbnailUrl: 'https://lh3.googleusercontent.com/stale=s512',
        thumbnailRefreshedAt: now.subtract(const Duration(hours: 2)),
      ),
      makeItem(
        mediaItemId: 'legacy-product',
        thumbnailUrl: 'https://photos.google.com/lr/album/x/photo/y',
        thumbnailRefreshedAt: now,
      ),
      makeItem(
        mediaItemId: 'empty-thumb',
        thumbnailUrl: '',
        thumbnailRefreshedAt: now,
      ),
    ];

    final candidates = collectThumbnailRepairCandidates(items);

    expect(
      candidates.map((item) => item.mediaItemId).toList(),
      equals(['stale-cdn', 'legacy-product', 'empty-thumb']),
    );
  });
}
