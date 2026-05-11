import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/local_wardrobe_store.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/wardrobe/data/wardrobe_item.dart';
import '../../domain/wardrobe_filter.dart';

// ── Filter state ──────────────────────────────────────────────────────────────

final wardrobeFilterProvider =
    NotifierProvider<WardrobeFilterNotifier, WardrobeFilter>(
  WardrobeFilterNotifier.new,
);

class WardrobeFilterNotifier extends Notifier<WardrobeFilter> {
  @override
  WardrobeFilter build() => const WardrobeFilter();

  void setKeyword(String keyword) =>
      state = state.copyWith(keyword: keyword.trim());

  void setCategory(String? category) =>
      state = state.copyWith(category: category);

  void addColor(String hex) {
    if (state.colors.contains(hex)) return;
    state = state.copyWith(colors: [...state.colors, hex]);
  }

  void removeColor(String hex) {
    state = state.copyWith(
      colors: state.colors.where((c) => c != hex).toList(),
    );
  }

  void toggleColor(String hex) {
    state.colors.contains(hex) ? removeColor(hex) : addColor(hex);
  }

  void toggleMaterial(String material) {
    final materials = List<String>.from(state.materials);
    materials.contains(material)
        ? materials.remove(material)
        : materials.add(material);
    state = state.copyWith(materials: materials);
  }

  void clearAll() => state = const WardrobeFilter();
}

// ── Client-side filtered list ─────────────────────────────────────────────────

final filteredWardrobeProvider = Provider<AsyncValue<List<WardrobeItem>>>((ref) {
  final wardrobe = ref.watch(localWardrobeProvider);
  final filter = ref.watch(wardrobeFilterProvider);

  return wardrobe.whenData((items) => _applyFilter(items, filter));
});

List<WardrobeItem> _applyFilter(
  List<WardrobeItem> items,
  WardrobeFilter filter,
) {
  if (filter.isEmpty) return items;

  return items.where((item) {
    // Keyword: match category or materials
    if (filter.keyword.isNotEmpty) {
      final kw = filter.keyword.toLowerCase();
      final inCategory = item.category.toLowerCase().contains(kw);
      final inMaterials =
          item.materials.any((m) => m.toLowerCase().contains(kw));
      if (!inCategory && !inMaterials) return false;
    }

    // Category: null = no filter; '' = only empty category (未分類 / 待分析)
    if (filter.category != null) {
      if (filter.category!.isEmpty) {
        if (item.category.isNotEmpty) return false;
      } else if (item.category != filter.category) {
        return false;
      }
    }

    // Colors: fuzzy bucket matching — both filter hex and item hex are
    // classified into named buckets (紅/橘/黃/…) so Gemini's per-item
    // hex codes (e.g. #C62828) still match the fixed filter swatches.
    if (filter.colors.isNotEmpty) {
      final filterBuckets = filter.colors.map(_colorBucket).toSet();
      final itemBuckets = item.colors.map(_colorBucket).toSet();
      if (!filterBuckets.every(itemBuckets.contains)) return false;
    }

    // Materials: item must contain ALL selected materials
    if (filter.materials.isNotEmpty) {
      final hasAll =
          filter.materials.every((fm) => item.materials.contains(fm));
      if (!hasAll) return false;
    }

    return true;
  }).toList();
}

// ── Color bucket classifier ───────────────────────────────────────────────────

/// Maps any hex color string (e.g. "#C62828" or "#e53935") to one of the
/// 12 named buckets used by the filter UI (紅/橘/黃/綠/藍/紫/粉/棕/米/黑/白/灰).
/// Returns '' on parse failure so it never matches a valid bucket.
String _colorBucket(String hexInput) {
  try {
    final h = hexInput.replaceAll('#', '').toLowerCase().trim();
    if (h.length < 6) return '';
    final r = int.parse(h.substring(0, 2), radix: 16) / 255.0;
    final g = int.parse(h.substring(2, 4), radix: 16) / 255.0;
    final b = int.parse(h.substring(4, 6), radix: 16) / 255.0;

    final max = r > g ? (r > b ? r : b) : (g > b ? g : b);
    final min = r < g ? (r < b ? r : b) : (g < b ? g : b);
    final delta = max - min;
    final l = (max + min) / 2.0;
    final s = delta < 0.001 ? 0.0 : delta / (1.0 - (2 * l - 1).abs());

    double hue = 0;
    if (delta > 0.001) {
      if (max == r) {
        hue = ((g - b) / delta) % 6.0;
      } else if (max == g) {
        hue = (b - r) / delta + 2.0;
      } else {
        hue = (r - g) / delta + 4.0;
      }
      hue = (hue * 60 + 360) % 360;
    }

    // Achromatic checks first (order matters)
    if (l < 0.20) return '黑';
    if (l > 0.82 && s < 0.18) return '白';
    if (s < 0.18) return '灰';

    // Warm neutrals (low-saturation hues in warm zone)
    if (l > 0.65 && s < 0.35) return '米';
    if (l < 0.50 && s < 0.40 && (hue < 50 || hue > 330)) return '棕';

    // Chromatic by hue
    if (hue >= 350 || hue < 15) return '紅';
    if (hue < 45) return '橘';
    if (hue < 75) return '黃';
    if (hue < 165) return '綠';
    if (hue < 255) return '藍';
    if (hue < 300) return '紫';
    return '粉'; // 300-350
  } catch (_) {
    return '';
  }
}

// ── Current user uid helper ───────────────────────────────────────────────────

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});
