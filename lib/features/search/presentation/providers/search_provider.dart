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

    // Colors: item must contain ALL selected colors
    if (filter.colors.isNotEmpty) {
      final hasAll =
          filter.colors.every((fc) => item.colors.contains(fc));
      if (!hasAll) return false;
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

// ── Current user uid helper ───────────────────────────────────────────────────

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});
