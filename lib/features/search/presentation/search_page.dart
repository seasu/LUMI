import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../../../core/providers/firebase_providers.dart'
    show cloudFunctionsProvider;
import '../../snap/data/cloud_functions_service.dart';
import '../../wardrobe/data/wardrobe_item.dart';
import '../../wardrobe/data/wardrobe_repository.dart';
import 'providers/search_provider.dart';
import 'widgets/filter_bar.dart';
import 'widgets/wardrobe_card.dart';
import 'widgets/item_detail_modal.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  Future<void> _onRefresh() async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return;

    await ref.read(wardrobeRepositoryProvider).prefetchWardrobeFromServer(uid);
    // Force stream resubscribe so UI pulls latest snapshot after server read updates cache.
    ref.invalidate(wardrobeStreamProvider);

    // If items stay [analyzed]=false with no error, the Firestore trigger may have
    // never run (e.g. created before deploy). Nudge analysis via callable per pending item.
    final snapshot = ref.read(wardrobeStreamProvider);
    final items = snapshot.valueOrNull;
    if (items != null && items.isNotEmpty) {
      final cf = CloudFunctionsService(ref.read(cloudFunctionsProvider));
      var retried = 0;
      const maxRetriesPerPull = 20;
      for (final item in items) {
        if (!item.isPending) continue;
        if (retried >= maxRetriesPerPull) break;
        retried++;
        try {
          await cf.retryAnalyzeWardrobeItem(mediaItemId: item.mediaItemId);
        } catch (_) {
          // Errors land in Firestore analyzeError; ignore network noise here.
        }
      }
      if (retried > 0) {
        ref.invalidate(wardrobeStreamProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    onRefresh: _onRefresh,
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Text(
              '我的衣櫥',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: LumiColors.text,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => context.push('/snap'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.add, size: 18, color: LumiColors.primary),
            label: const Text(
              '加入新品',
              style: TextStyle(
                fontSize: 14,
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
              fontSize: 16,
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
        crossAxisSpacing: 10,
        mainAxisSpacing: 16,
        childAspectRatio: 0.74,
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
    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dry_cleaning_outlined,
            size: 76,
            color: LumiColors.subtext.withOpacity(0.35),
          ),
          const SizedBox(height: 18),
          const Text(
            '妳的衣櫥目前空空如也',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: LumiColors.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '點擊右上角的「加入新品」按鈕，\n開始建立妳的數位衣櫥吧！',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: LumiColors.subtext,
              height: 1.7,
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 16,
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
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 72,
            height: 8,
            decoration: BoxDecoration(
              color: LumiColors.subtext.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 88,
            height: 6,
            decoration: BoxDecoration(
              color: LumiColors.subtext.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
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
            fontSize: 14,
            color: LumiColors.warning,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
