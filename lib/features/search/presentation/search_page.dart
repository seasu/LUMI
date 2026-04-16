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
      padding: const EdgeInsets.fromLTRB(16, LumiSpacing.md, 16, LumiSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Text(
              '我的衣櫥',
              style: TextStyle(fontSize: 46, fontWeight: FontWeight.w700, color: LumiColors.text, height: 1.0),
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/snap'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: const Row(
                children: [
                  Icon(Icons.add, size: 18, color: LumiColors.primary),
                  SizedBox(width: 4),
                  Text(
                    '加入新品',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: LumiColors.primary,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
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
        width: 58,
        height: 58,
        decoration: const BoxDecoration(
          gradient: LumiColors.buttonGradient,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            '似',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.70,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        children: [
          const Spacer(flex: 5),
          Icon(
            Icons.dry_cleaning_outlined,
            size: 74,
            color: LumiColors.subtext.withOpacity(0.35),
          ),
          const SizedBox(height: 22),
          const Text(
            '妳的衣櫥目前空空如也',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: LumiColors.text,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '點擊右上角的「加入新品」按鈕，\n開始建立妳的數位衣櫥吧！',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: LumiColors.subtext,
              height: 1.8,
            ),
          ),
          const Spacer(flex: 6),
        ],
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.70,
      ),
      itemCount: 8,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: LumiColors.surface,
          borderRadius: BorderRadius.circular(18),
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
