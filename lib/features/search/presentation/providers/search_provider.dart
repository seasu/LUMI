import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../features/wardrobe/data/wardrobe_item.dart';
import '../../../../features/wardrobe/data/wardrobe_repository.dart';
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

  void toggleColor(String hex) {
    final colors = List<String>.from(state.colors);
    colors.contains(hex) ? colors.remove(hex) : colors.add(hex);
    state = state.copyWith(colors: colors);
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

// ── Raw stream from Firestore ─────────────────────────────────────────────────

final wardrobeStreamProvider = StreamProvider<List<WardrobeItem>>((ref) {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) return const Stream.empty();
  return ref.watch(wardrobeRepositoryProvider).watchWardrobe(user.uid);
});

// ── Client-side filtered list ─────────────────────────────────────────────────

final filteredWardrobeProvider = Provider<AsyncValue<List<WardrobeItem>>>((ref) {
  final stream = ref.watch(wardrobeStreamProvider);
  final filter = ref.watch(wardrobeFilterProvider);

  return stream.whenData((items) => _applyFilter(items, filter));
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

    // Category
    if (filter.category != null && item.category != filter.category) {
      return false;
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
  return ref.watch(firebaseAuthProvider).currentUser;
});
