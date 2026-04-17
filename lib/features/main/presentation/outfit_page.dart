import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../ootd/domain/ootd_item.dart';
import '../../ootd/data/ootd_repository.dart';

class OutfitPage extends ConsumerWidget {
  const OutfitPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();

    final itemsAsync = ref.watch(ootdItemsProvider(user.uid));

    return Scaffold(
      backgroundColor: LumiColors.base,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Header(),
                Expanded(
                  child: itemsAsync.when(
                    data: (items) => items.isEmpty
                        ? const _EmptyState()
                        : _OotdGrid(items: items),
                    loading: () => const _LoadingSkeleton(),
                    error: (e, _) => _ErrorState(message: e.toString()),
                  ),
                ),
              ],
            ),
            // Camera FAB
            Positioned(
              bottom: 24,
              right: 16,
              child: _CameraFab(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        LumiSpacing.md,
        16,
        LumiSpacing.sm,
      ),
      child: Text(
        '我的穿搭',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: LumiColors.text,
        ),
      ),
    );
  }
}

// ── Camera FAB ────────────────────────────────────────────────────────────────

class _CameraFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/ootd/add'),
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          gradient: LumiColors.brandGradient,
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

// ── OOTD Grid ─────────────────────────────────────────────────────────────────

class _OotdGrid extends StatelessWidget {
  const _OotdGrid({required this.items});
  final List<OotdItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        LumiSpacing.md,
        LumiSpacing.xs,
        LumiSpacing.md,
        80,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: LumiSpacing.sm,
        mainAxisSpacing: LumiSpacing.sm,
        childAspectRatio: 0.72,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _OotdCard(item: items[index]),
    );
  }
}

class _OotdCard extends StatelessWidget {
  const _OotdCard({required this.item});
  final OotdItem item;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${item.date.year}.${item.date.month.toString().padLeft(2, '0')}.${item.date.day.toString().padLeft(2, '0')}';

    Uint8List? bytes;
    try {
      if (item.imageBase64.isNotEmpty) bytes = base64Decode(item.imageBase64);
    } catch (_) {}

    return Container(
      decoration: BoxDecoration(
        color: LumiColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: bytes != null
                ? Image.memory(bytes,
                    fit: BoxFit.cover, width: double.infinity)
                : Container(color: LumiColors.base),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                LumiSpacing.sm, LumiSpacing.sm, LumiSpacing.sm, LumiSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.caption.isEmpty ? '無備註' : item.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: LumiColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 11, color: LumiColors.subtext),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

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
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: LumiColors.glow.withOpacity(0.2),
                  ),
                ),
                const Icon(
                  Icons.camera_alt_outlined,
                  size: 60,
                  color: LumiColors.primary,
                ),
              ],
            ),
            const SizedBox(height: LumiSpacing.lg),
            const Text(
              '尚未記錄任何穿搭',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: LumiColors.text,
              ),
            ),
            const SizedBox(height: LumiSpacing.sm),
            const Text(
              '點擊右下角的按鈕，\n開始記錄妳的每日時尚風格吧！',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: LumiColors.subtext, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loading Skeleton ──────────────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(LumiSpacing.md),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
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

// ── Error State ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '載入失敗：$message',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, color: LumiColors.warning),
      ),
    );
  }
}
