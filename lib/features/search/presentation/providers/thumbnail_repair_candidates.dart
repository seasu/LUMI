import '../../../wardrobe/data/wardrobe_item.dart';
import '../../../wardrobe/utils/wardrobe_thumbnail_url.dart';

bool wardrobeThumbnailNeedsRepair(WardrobeItem item) {
  final thumbnailUrl = item.thumbnailUrl.trim();
  return thumbnailUrl.isEmpty ||
      item.isThumbnailStale ||
      wardrobeThumbnailNeedsApiRefresh(thumbnailUrl);
}
