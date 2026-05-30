import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/constants/lumi_colors.dart';
import '../../../../shared/utils/category_translator.dart';
import '../../domain/wardrobe_filter.dart';
import '../providers/search_provider.dart';

// Raw category data values (Gemini-returned Chinese strings used as filter keys).
// Display labels are translated at runtime in _CategoryTabs.
const _categoryDataKeys = <String?>[
  null,                              // 全部
  WardrobeFilter.favoritesFilter,    // 我的最愛
  WardrobeFilter.uncategorizedOnly,  // 未分類
  '連身裙',
  '上衣',
  '下身',
  '鞋履',
  '包款',
  '配件',
];

// 顏色篩選選項（近似色）— color values are data swatches, not UI colors
const _colorOptions = <_ColorOption>[
  _ColorOption('紅', Color(0xFFE53935)),
  _ColorOption('橘', Color(0xFFF57C00)),
  _ColorOption('黃', Color(0xFFFDD835)),
  _ColorOption('綠', Color(0xFF43A047)),
  _ColorOption('藍', Color(0xFF1E88E5)),
  _ColorOption('紫', Color(0xFF8E24AA)),
  _ColorOption('粉', Color(0xFFEC407A)),
  _ColorOption('棕', Color(0xFF6D4C41)),
  _ColorOption('米', Color(0xFFD7CCC8)),
  _ColorOption('黑', Color(0xFF212121)),
  _ColorOption('白', Color(0xFFF5F5F5)),
  _ColorOption('灰', Color(0xFF9E9E9E)),
];

class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CategoryTabs(),
        const SizedBox(height: 14),
        _ColorDotRow(),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── 分類 Tabs ─────────────────────────────────────────────────────────────────

class _CategoryTabs extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      wardrobeFilterProvider.select((f) => f.category),
    );
    final l10n = AppLocalizations.of(context);

    // Build translated display labels at runtime
    final categories = _categoryDataKeys.map((key) {
      final String label;
      if (key == null) {
        label = l10n.searchFilterAll;
      } else if (key == WardrobeFilter.favoritesFilter) {
        label = l10n.searchFilterFavorites;
      } else if (key == WardrobeFilter.uncategorizedOnly) {
        label = l10n.searchFilterUncategorized;
      } else {
        label = translateCategory(key, l10n);
      }
      return _CategoryTab(label: label, category: key);
    }).toList();

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final tab = categories[i];
          final isSelected = _categoryTabMatches(selected, tab);
          return GestureDetector(
            onTap: () => ref
                .read(wardrobeFilterProvider.notifier)
                .setCategory(isSelected ? null : tab.category),
            child: Container(
              margin: const EdgeInsets.only(right: 22),
              padding: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? (tab.category == WardrobeFilter.favoritesFilter
                            ? LumiColors.warning
                            : LumiColors.primary)
                        : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: tab.category == WardrobeFilter.favoritesFilter
                  ? Text.rich(
                      TextSpan(
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                isSelected
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 13,
                                color: isSelected
                                    ? LumiColors.warning
                                    : LumiColors.subtext,
                              ),
                            ),
                          ),
                          TextSpan(
                            text: tab.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? LumiColors.warning
                                  : LumiColors.subtext,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? LumiColors.primary
                            : LumiColors.subtext,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

// ── 顏色圓形色票列 ─────────────────────────────────────────────────────────────

class _ColorDotRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedColors = ref.watch(
      wardrobeFilterProvider.select((f) => f.colors),
    );

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _colorOptions.length,
        itemBuilder: (context, i) {
          final opt = _colorOptions[i];
          final hexStr = _colorToHex(opt.color);
          final isSelected = selectedColors.contains(hexStr);

          return GestureDetector(
            onTap: () {
              final notifier = ref.read(wardrobeFilterProvider.notifier);
              isSelected
                  ? notifier.removeColor(hexStr)
                  : notifier.addColor(hexStr);
            },
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: isSelected ? 34 : 30,
                  height: isSelected ? 34 : 30,
                  decoration: BoxDecoration(
                    color: opt.color,
                    shape: BoxShape.circle,
                    border: (!isSelected &&
                            opt.color.computeLuminance() > 0.85)
                        ? Border.all(
                            color: LumiColors.subtext.withValues(alpha: 0.20),
                          )
                        : null,
                    boxShadow: isSelected
                        ? [
                            const BoxShadow(
                              color: LumiColors.surface,
                              blurRadius: 0,
                              spreadRadius: 2.5,
                            ),
                            const BoxShadow(
                              color: LumiColors.primary,
                              blurRadius: 0,
                              spreadRadius: 4.5,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _colorToHex(Color color) {
  final argb = color.toARGB32();
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  return '#${r.toRadixString(16).padLeft(2, '0')}'
      '${g.toRadixString(16).padLeft(2, '0')}'
      '${b.toRadixString(16).padLeft(2, '0')}';
}

class _CategoryTab {
  const _CategoryTab({required this.label, required this.category});
  final String label;
  /// `null` = all；[WardrobeFilter.uncategorizedOnly] = uncategorized only；else Gemini category key.
  final String? category;
}

bool _categoryTabMatches(String? selected, _CategoryTab tab) {
  if (tab.category == null) return selected == null;
  if (tab.category!.isEmpty) {
    return selected != null && selected.isEmpty;
  }
  return selected == tab.category;
}

class _ColorOption {
  const _ColorOption(this.name, this.color);
  final String name;
  final Color color;
}
