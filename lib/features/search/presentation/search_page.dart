import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/local_wardrobe_store.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_radii.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../../shared/constants/lumi_type_scale.dart';
import '../../snap/presentation/providers/snap_provider.dart';
import '../../wardrobe/data/wardrobe_item.dart';
import '../domain/wardrobe_filter.dart';
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
                  child: RefreshIndicator(
                    color: LumiColors.primary,
                    onRefresh: () => _onRefresh(ref),
                    child: filtered.when(
                      data: (items) {
                        if (items.isEmpty) {
                          return const CustomScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _EmptyState(),
                              ),
                            ],
                          );
                        }
                        return _WardrobeGrid(items: items);
                      },
                      loading: () => const CustomScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _LoadingGrid(),
                          ),
                        ],
                      ),
                      error: (e, _) => CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _ErrorState(message: e.toString()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: LumiSpacing.lg,
              right: LumiSpacing.md,
              child: _SnapFab(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onRefresh(WidgetRef ref) async {
    // Capture failed items before reload clears them from state.
    final current = ref.read(localWardrobeProvider).valueOrNull ?? [];
    final failed =
        current.where((i) => !i.analyzed && i.analyzeError != null).toList();

    await ref.read(localWardrobeProvider.notifier).reload();

    if (failed.isNotEmpty) {
      unawaited(ref.read(snapProvider.notifier).retryFailedAnalyses(failed));
    }
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _WardrobeHeader extends StatelessWidget {
  const _WardrobeHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LumiSpacing.md,
        LumiSpacing.sm + LumiSpacing.xs, // 12 — visual top margin
        LumiSpacing.md,
        LumiSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Text(
              '我的衣櫥',
              style: TextStyle(
                fontSize: LumiTypeScale.headlineMd,
                fontWeight: FontWeight.w800,
                color: LumiColors.text,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => context.push('/snap'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.add, size: 18, color: LumiColors.primary),
            label: const Text(
              '加入新品',
              style: TextStyle(
                fontSize: LumiTypeScale.labelMd,
                fontWeight: FontWeight.w600,
                color: LumiColors.primary,
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
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          gradient: LumiColors.buttonGradient,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            '似',
            style: TextStyle(
              color: LumiColors.onPrimary,
              fontSize: LumiTypeScale.titleSm,
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
      padding: const EdgeInsets.fromLTRB(
        LumiSpacing.md,
        0,
        LumiSpacing.md,
        96,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: LumiSpacing.sm,
        mainAxisSpacing: LumiSpacing.md,
        childAspectRatio: 0.74,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return WardrobeCard(
          item: item,
          onTap: () => showItemDetailModal(context, item),
        );
      },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allItems = ref.watch(localWardrobeProvider).valueOrNull ?? [];
    final filter = ref.watch(wardrobeFilterProvider);

    // 真空衣櫥
    if (allItems.isEmpty) {
      return const _TrueEmptyState();
    }

    // 在「未分類」tab，但衣物已被 AI 移至各分類
    if (filter.category == WardrobeFilter.uncategorizedOnly) {
      return _FilteredEmptyState(
        icon: Icons.auto_awesome_outlined,
        iconColor: LumiColors.primary,
        title: 'AI 辨識完成！',
        subtitle: '衣物已歸類到對應分類\n快點擊下方按鈕去看看吧',
        ctaLabel: '查看全部衣物',
        onCta: () =>
            ref.read(wardrobeFilterProvider.notifier).setCategory(null),
      );
    }

    // 其他篩選條件無結果
    return _FilteredEmptyState(
      icon: Icons.search_off_outlined,
      iconColor: LumiColors.subtext,
      title: '這個分類目前沒有衣物',
      subtitle: '換個分類看看，或清除篩選條件',
      ctaLabel: '查看全部衣物',
      onCta: () => ref.read(wardrobeFilterProvider.notifier).clearAll(),
    );
  }
}

class _TrueEmptyState extends StatelessWidget {
  const _TrueEmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dry_cleaning_outlined,
            size: 76,
            color: LumiColors.subtext.withValues(alpha: 0.35),
          ),
          const SizedBox(height: LumiSpacing.md + LumiSpacing.xs),
          const Text(
            '妳的衣櫥目前空空如也',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: LumiTypeScale.titleSm,
              fontWeight: FontWeight.w800,
              color: LumiColors.text,
            ),
          ),
          const SizedBox(height: LumiSpacing.sm),
          const Text(
            '點擊右上角的「加入新品」按鈕，\n開始建立妳的數位衣櫥吧！',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: LumiTypeScale.labelMd,
              color: LumiColors.subtext,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onCta,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 68,
            color: iconColor.withValues(alpha: 0.40),
          ),
          const SizedBox(height: LumiSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: LumiTypeScale.titleSm,
              fontWeight: FontWeight.w800,
              color: LumiColors.text,
            ),
          ),
          const SizedBox(height: LumiSpacing.sm),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: LumiTypeScale.labelMd,
              color: LumiColors.subtext,
              height: 1.7,
            ),
          ),
          const SizedBox(height: LumiSpacing.xl),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(LumiRadii.pill),
            child: InkWell(
              onTap: onCta,
              borderRadius: BorderRadius.circular(LumiRadii.pill),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LumiColors.buttonGradient,
                  borderRadius: BorderRadius.circular(LumiRadii.pill),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LumiSpacing.xl,
                    vertical: LumiSpacing.sm + 2,
                  ),
                  child: Text(
                    ctaLabel,
                    style: const TextStyle(
                      fontSize: LumiTypeScale.body,
                      fontWeight: FontWeight.w600,
                      color: LumiColors.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
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
      padding: const EdgeInsets.fromLTRB(
        LumiSpacing.md,
        0,
        LumiSpacing.md,
        96,
      ),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: LumiSpacing.sm,
        mainAxisSpacing: LumiSpacing.md,
        childAspectRatio: 0.74,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: LumiColors.surface,
                borderRadius: BorderRadius.circular(LumiRadii.lg),
              ),
            ),
          ),
          const SizedBox(height: LumiSpacing.sm),
          Container(
            width: 72,
            height: 8,
            decoration: BoxDecoration(
              color: LumiColors.subtext.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(LumiRadii.pill),
            ),
          ),
          const SizedBox(height: LumiSpacing.xs),
          Container(
            width: 88,
            height: 6,
            decoration: BoxDecoration(
              color: LumiColors.subtext.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(LumiRadii.pill),
            ),
          ),
        ],
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
            fontSize: LumiTypeScale.labelMd,
            color: LumiColors.warning,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
