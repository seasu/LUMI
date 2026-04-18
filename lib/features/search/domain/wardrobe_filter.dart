class WardrobeFilter {
  const WardrobeFilter({
    this.keyword = '',
    this.category,
    this.colors = const [],
    this.materials = const [],
  });

  /// Filter to items with **empty** `WardrobeItem.category` (未分類 / 分析中佇列).
  /// Distinct from [category] `null` which means **no** category filter (顯示全部).
  static const String uncategorizedOnly = '';

  final String keyword;
  final String? category;
  final List<String> colors;
  final List<String> materials;

  bool get isEmpty =>
      keyword.isEmpty &&
      category == null &&
      colors.isEmpty &&
      materials.isEmpty;

  WardrobeFilter copyWith({
    String? keyword,
    Object? category = _sentinel,
    List<String>? colors,
    List<String>? materials,
  }) =>
      WardrobeFilter(
        keyword: keyword ?? this.keyword,
        category: category == _sentinel ? this.category : category as String?,
        colors: colors ?? this.colors,
        materials: materials ?? this.materials,
      );

  static const _sentinel = Object();
}
