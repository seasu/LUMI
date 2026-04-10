import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/constants/lumi_colors.dart';
import '../../../../shared/constants/lumi_spacing.dart';
import '../providers/search_provider.dart';

const _categories = ['上衣', '褲子', '外套', '配件', '鞋子'];

class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _KeywordField(),
        const SizedBox(height: LumiSpacing.sm),
        _CategoryChips(),
        const SizedBox(height: LumiSpacing.sm),
      ],
    );
  }
}

// ── Keyword search ────────────────────────────────────────────────────────────

class _KeywordField extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LumiSpacing.md),
      child: TextField(
        onChanged: (v) =>
            ref.read(wardrobeFilterProvider.notifier).setKeyword(v),
        style: const TextStyle(fontSize: 15, color: LumiColors.text),
        decoration: InputDecoration(
          hintText: '搜尋（毛衣、藍色…）',
          hintStyle:
              const TextStyle(fontSize: 15, color: LumiColors.subtext),
          prefixIcon:
              const Icon(Icons.search, color: LumiColors.subtext, size: 20),
          filled: true,
          fillColor: LumiColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: LumiSpacing.md,
            vertical: LumiSpacing.sm,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// ── Category chips ────────────────────────────────────────────────────────────

class _CategoryChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      wardrobeFilterProvider.select((f) => f.category),
    );

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: LumiSpacing.md),
        children: [
          _Chip(
            label: '全部',
            selected: selected == null,
            onTap: () =>
                ref.read(wardrobeFilterProvider.notifier).setCategory(null),
          ),
          ..._categories.map(
            (cat) => _Chip(
              label: cat,
              selected: selected == cat,
              onTap: () => ref
                  .read(wardrobeFilterProvider.notifier)
                  .setCategory(selected == cat ? null : cat),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: LumiSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: LumiSpacing.md,
          vertical: LumiSpacing.xs,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? LumiColors.accent : LumiColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? LumiColors.surface : LumiColors.subtext,
          ),
        ),
      ),
    );
  }
}
