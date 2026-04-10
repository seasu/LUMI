import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../../features/wardrobe/data/wardrobe_item.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'providers/search_provider.dart';
import 'widgets/wardrobe_card.dart';
import 'widgets/filter_bar.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = ref.watch(filteredWardrobeProvider);
    final filter = ref.watch(wardrobeFilterProvider);

    return Scaffold(
      backgroundColor: LumiColors.base,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/snap'),
        backgroundColor: LumiColors.text,
        foregroundColor: LumiColors.surface,
        label: const Text('Lumi Snap'),
        icon: const Icon(Icons.camera_alt_outlined),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SearchHeader(hasActiveFilter: !filter.isEmpty),
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
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _SearchHeader extends ConsumerWidget {
  const _SearchHeader({required this.hasActiveFilter});

  final bool hasActiveFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LumiSpacing.md,
        LumiSpacing.md,
        LumiSpacing.md,
        LumiSpacing.sm,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '我的衣櫥',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: LumiColors.text,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (hasActiveFilter)
            TextButton(
              onPressed: () =>
                  ref.read(wardrobeFilterProvider.notifier).clearAll(),
              child: const Text(
                '清除篩選',
                style: TextStyle(fontSize: 13, color: LumiColors.subtext),
              ),
            ),
          IconButton(
            onPressed: () => signOut(ref),
            icon: const Icon(Icons.logout, color: LumiColors.subtext),
          ),
        ],
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
    final width = MediaQuery.sizeOf(context).width;
    // Responsive: 2 columns on mobile, 3 on tablet, 4 on desktop
    final crossAxisCount = switch (width) {
      < 600 => 2,
      < 900 => 3,
      _ => 4,
    };

    return RefreshIndicator(
      onRefresh: () async {}, // Firestore stream handles real-time updates
      child: GridView.builder(
        padding: const EdgeInsets.all(LumiSpacing.md),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: LumiSpacing.sm,
          mainAxisSpacing: LumiSpacing.sm,
          childAspectRatio: 0.72,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => WardrobeCard(item: items[index]),
      ),
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
            Icon(
              Icons.checkroom_outlined,
              size: 64,
              color: LumiColors.subtext.withOpacity(0.4),
            ),
            const SizedBox(height: LumiSpacing.md),
            const Text(
              '衣櫥是空的',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: LumiColors.text,
              ),
            ),
            const SizedBox(height: LumiSpacing.sm),
            const Text(
              '點擊 Lumi Snap 拍照入庫，\n開始建立你的數位衣櫥。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: LumiColors.subtext,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loading skeleton grid ─────────────────────────────────────────────────────

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = switch (width) {
      < 600 => 2,
      < 900 => 3,
      _ => 4,
    };

    return GridView.builder(
      padding: const EdgeInsets.all(LumiSpacing.md),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: LumiSpacing.sm,
        mainAxisSpacing: LumiSpacing.sm,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: LumiColors.surface,
          borderRadius: BorderRadius.circular(16),
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
            fontSize: 15,
            color: LumiColors.warning,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
