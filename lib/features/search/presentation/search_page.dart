import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/local_wardrobe_store.dart';
import '../../../l10n/generated/app_localizations.dart';
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
              child: _AddFab(),
            ),
            Positioned(
              bottom: LumiSpacing.lg + 56 + 12,
              right: LumiSpacing.md + 4, // center 48px over 56px FAB
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
        LumiSpacing.sm + LumiSpacing.xs,
        LumiSpacing.md,
        LumiSpacing.sm,
      ),
      child: Text(
        AppLocalizations.of(context).searchTitle,
        style: const TextStyle(
          fontSize: LumiTypeScale.headlineMd,
          fontWeight: FontWeight.w800,
          color: LumiColors.text,
        ),
      ),
    );
  }
}

// ── Add FAB (主動作) ───────────────────────────────────────────────────────────

class _AddFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddSheet(context),
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          gradient: LumiColors.buttonGradient,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: LumiColors.onPrimary, size: 28),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: LumiColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LumiRadii.xl),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            LumiSpacing.lg,
            LumiSpacing.md,
            LumiSpacing.lg,
            LumiSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).homeAddItem,
                style: const TextStyle(
                  fontSize: LumiTypeScale.titleLg,
                  fontWeight: FontWeight.w700,
                  color: LumiColors.text,
                ),
              ),
              const SizedBox(height: LumiSpacing.xs),
              Text(
                AppLocalizations.of(context).snapIdleSubtitle,
                style: const TextStyle(
                  fontSize: LumiTypeScale.labelMd,
                  color: LumiColors.subtext,
                ),
              ),
              const SizedBox(height: LumiSpacing.sm),
              _CheckSourceOption(
                icon: Icons.camera_alt_outlined,
                label: AppLocalizations.of(context).snapCamera,
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push('/snap?source=camera');
                },
              ),
              _CheckSourceOption(
                icon: Icons.photo_library_outlined,
                label: AppLocalizations.of(context).snapLibrary,
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push('/snap?source=gallery');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Snap FAB (副動作) ──────────────────────────────────────────────────────────

class _SnapFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCheckSheet(context),
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          gradient: LumiColors.buttonGradient,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            '似',
            style: TextStyle(
              color: LumiColors.onPrimary,
              fontSize: LumiTypeScale.labelMd,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  void _showCheckSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: LumiColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LumiRadii.xl),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            LumiSpacing.lg,
            LumiSpacing.md,
            LumiSpacing.lg,
            LumiSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).checkTitle,
                style: const TextStyle(
                  fontSize: LumiTypeScale.titleLg,
                  fontWeight: FontWeight.w700,
                  color: LumiColors.text,
                ),
              ),
              const SizedBox(height: LumiSpacing.xs),
              Text(
                AppLocalizations.of(context).checkSubtitle,
                style: const TextStyle(
                  fontSize: LumiTypeScale.labelMd,
                  color: LumiColors.subtext,
                ),
              ),
              const SizedBox(height: LumiSpacing.sm),
              _CheckSourceOption(
                icon: Icons.camera_alt_outlined,
                label: AppLocalizations.of(context).snapCamera,
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push('/check?source=camera');
                },
              ),
              _CheckSourceOption(
                icon: Icons.photo_library_outlined,
                label: AppLocalizations.of(context).snapLibrary,
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push('/check?source=gallery');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckSourceOption extends StatelessWidget {
  const _CheckSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LumiRadii.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: LumiSpacing.md,
          horizontal: LumiSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, color: LumiColors.primary, size: 24),
            const SizedBox(width: LumiSpacing.md),
            Text(
              label,
              style: const TextStyle(
                fontSize: LumiTypeScale.body,
                fontWeight: FontWeight.w500,
                color: LumiColors.text,
              ),
            ),
          ],
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
          onTap: () => showItemDetailModal(context, items, index),
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

    final l10n = AppLocalizations.of(context);

    // 在「我的最愛」tab 但尚未收藏任何衣物
    if (filter.category == WardrobeFilter.favoritesFilter) {
      return _FilteredEmptyState(
        icon: Icons.favorite_border,
        iconColor: LumiColors.warning,
        title: l10n.searchFavoritesEmptyTitle,
        subtitle: l10n.searchFavoritesEmptyHint,
        ctaLabel: l10n.searchViewAll,
        onCta: () =>
            ref.read(wardrobeFilterProvider.notifier).setCategory(null),
      );
    }

    // 在「未分類」tab，但衣物已被 AI 移至各分類
    if (filter.category == WardrobeFilter.uncategorizedOnly) {
      return _FilteredEmptyState(
        icon: Icons.auto_awesome_outlined,
        iconColor: LumiColors.primary,
        title: l10n.searchAiDoneTitle,
        subtitle: l10n.searchAiDoneHint,
        ctaLabel: l10n.searchViewAll,
        onCta: () =>
            ref.read(wardrobeFilterProvider.notifier).setCategory(null),
      );
    }

    // 其他篩選條件無結果
    return _FilteredEmptyState(
      icon: Icons.search_off_outlined,
      iconColor: LumiColors.subtext,
      title: l10n.searchFilterEmptyTitle,
      subtitle: l10n.searchFilterEmptyHint,
      ctaLabel: l10n.searchViewAll,
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
          Text(
            AppLocalizations.of(context).homeEmpty,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: LumiTypeScale.titleSm,
              fontWeight: FontWeight.w800,
              color: LumiColors.text,
            ),
          ),
          const SizedBox(height: LumiSpacing.sm),
          Text(
            AppLocalizations.of(context).searchEmptyHint,
            textAlign: TextAlign.center,
            style: const TextStyle(
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
          '${AppLocalizations.of(context).error}: $message',
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
