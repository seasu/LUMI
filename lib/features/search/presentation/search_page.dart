import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../../features/wardrobe/data/wardrobe_item.dart';
import 'providers/search_provider.dart';
import 'widgets/filter_bar.dart';
import 'widgets/wardrobe_card.dart';
import 'widgets/item_detail_modal.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = ref.watch(filteredWardrobeProvider);

    return Scaffold(
      backgroundColor: LumiColors.base,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _WardrobeHeader(),
                const FilterBar(),
                Expanded(
                  child: filtered.when(
                    data: (items) => items.isEmpty
                        ? const _EmptyState()
                        : _WardrobeGrid(items: items),
                    loading: () => const _LoadingGrid(),
                    error: (e, _) => _ErrorState(message: e.toString()),
                  ),
                ),
              ],
            ),
            // 右下角 FAB
            Positioned(
              bottom: 24,
              right: 16,
              child: _SnapFab(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _WardrobeHeader extends ConsumerWidget {
  const _WardrobeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, LumiSpacing.md, 16, LumiSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Text(
              '我的衣櫥',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: LumiColors.text),
            ),
          ),
          TextButton.icon(
            onPressed: () => context.push('/snap'),
            icon: const Icon(Icons.add, size: 18, color: LumiColors.primary),
            label: const Text(
              '加入新品',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: LumiColors.primary,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: LumiSpacing.sm, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Snap FAB ──────────────────────────────────────────────────────────────────

class _SnapFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/check'),
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          gradient: LumiColors.buttonGradient,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.camera_alt_outlined,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

// ── Grid ──────────────────────────────────────────────────────────────────────

class _WardrobeGrid extends StatelessWidget {
  const _WardrobeGrid({required this.items});

  final List<WardrobeItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(LumiSpacing.md, LumiSpacing.sm, LumiSpacing.md, 92),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: LumiSpacing.sm,
        mainAxisSpacing: LumiSpacing.sm,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => showItemDetailModal(context, item),
          child: WardrobeCard(item: item),
        );
      },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LumiSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 衣架插圖（用 icon 模擬）
            Icon(
              Icons.dry_cleaning_outlined,
              size: 72,
              color: LumiColors.subtext.withOpacity(0.4),
            ),
            const SizedBox(height: LumiSpacing.md),
            const Text(
              '妳的衣櫥目前空空如也',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: LumiColors.text,
              ),
            ),
            const SizedBox(height: LumiSpacing.sm),
            const Text(
              '點擊右上角的「加入新品」按鈕，\n開始建立妳的數位衣櫥吧！',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: LumiColors.subtext,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loading skeleton ──────────────────────────────────────────────────────────

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(LumiSpacing.md),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: LumiSpacing.sm,
        mainAxisSpacing: LumiSpacing.sm,
        childAspectRatio: 0.75,
      ),
      itemCount: 12,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: LumiColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LumiSpacing.lg),
        child: Text(
          '載入失敗：$message',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: LumiColors.warning,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
