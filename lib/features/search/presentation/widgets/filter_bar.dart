import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/constants/lumi_colors.dart';
import '../../domain/wardrobe_filter.dart';
import '../providers/search_provider.dart';

// 分類與 Gemini 輸出對應
const _categories = <_CategoryTab>[
  _CategoryTab('全部', null),
  _CategoryTab('未分類', WardrobeFilter.uncategorizedOnly),
  _CategoryTab('連身裙', '連身裙'),
  _CategoryTab('上衣', '上衣'),
  _CategoryTab('下身', '下身'),
  _CategoryTab('鞋履', '鞋履'),
  _CategoryTab('包款', '包款'),
  _CategoryTab('配件', '配件'),
];

// 顏色篩選選項（近似色）
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

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, i) {
          final tab = _categories[i];
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
                        ? LumiColors.primary
                        : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                tab.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? LumiColors.primary : LumiColors.subtext,
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
      height: 36,
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
              if (isSelected) {
                notifier.removeColor(hexStr);
              } else {
                notifier.addColor(hexStr);
              }
            },
            child: Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: opt.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? LumiColors.primary
                      : opt.color.computeLuminance() > 0.9
                          ? LumiColors.subtext.withOpacity(0.15)
                          : Colors.transparent,
                  width: isSelected ? 2.2 : 1.0,
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
  return '#${color.red.toRadixString(16).padLeft(2, '0')}'
         '${color.green.toRadixString(16).padLeft(2, '0')}'
         '${color.blue.toRadixString(16).padLeft(2, '0')}';
}

class _CategoryTab {
  const _CategoryTab(this.label, this.category);
  final String label;
  /// `null` = 全部；[WardrobeFilter.uncategorizedOnly] = 僅空分類；其餘為 Gemini 分類名。
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
