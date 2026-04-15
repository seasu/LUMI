import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/constants/lumi_colors.dart';
import '../../../../shared/constants/lumi_spacing.dart';
import '../providers/search_provider.dart';

// 分類與 Gemini 輸出對應
const _categories = <_CategoryTab>[
  _CategoryTab('全部', null),
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
        const SizedBox(height: LumiSpacing.sm),
        _ColorDotRow(),
        const SizedBox(height: LumiSpacing.sm),
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
        padding: const EdgeInsets.symmetric(horizontal: LumiSpacing.md),
        itemCount: _categories.length,
        itemBuilder: (context, i) {
          final tab = _categories[i];
          final isSelected = selected == tab.category;
          return GestureDetector(
            onTap: () => ref
                .read(wardrobeFilterProvider.notifier)
                .setCategory(isSelected ? null : tab.category),
            child: Container(
              margin: const EdgeInsets.only(right: LumiSpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? LumiColors.primary
                    : LumiColors.subtext.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                tab.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : LumiColors.subtext,
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
        padding: const EdgeInsets.symmetric(horizontal: LumiSpacing.md),
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
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: LumiSpacing.sm),
              decoration: BoxDecoration(
                color: opt.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? LumiColors.primary
                      : Colors.black.withOpacity(0.06),
                  width: isSelected ? 2.5 : 1.0,
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
  final String? category;
}

class _ColorOption {
  const _ColorOption(this.name, this.color);
  final String name;
  final Color color;
}
