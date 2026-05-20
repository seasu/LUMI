import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/local_ootd_storage.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_radii.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../../shared/constants/lumi_type_scale.dart';
import '../../ootd/data/ootd_repository.dart';
import '../../ootd/domain/ootd_item.dart';
import '../../ootd/presentation/widgets/ootd_detail_modal.dart';

class OutfitPage extends ConsumerWidget {
  const OutfitPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(ootdLocalProvider);

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
            Positioned(
              bottom: LumiSpacing.lg,
              right: LumiSpacing.md,
              child: _AddFab(),
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
        LumiSpacing.lg,
        LumiSpacing.md,
        LumiSpacing.md,
        LumiSpacing.sm,
      ),
      child: Text(
        '我的穿搭',
        style: TextStyle(
          fontSize: LumiTypeScale.headlineMd,
          fontWeight: FontWeight.w700,
          color: LumiColors.text,
        ),
      ),
    );
  }
}

// ── Add FAB ───────────────────────────────────────────────────────────────────

class _AddFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSourceSheet(context),
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

  void _showSourceSheet(BuildContext context) {
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
              const Text(
                '新增穿搭',
                style: TextStyle(
                  fontSize: LumiTypeScale.titleLg,
                  fontWeight: FontWeight.w700,
                  color: LumiColors.text,
                ),
              ),
              const SizedBox(height: LumiSpacing.md),
              _SourceOption(
                icon: Icons.camera_alt_outlined,
                label: '拍照',
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push('/ootd/add?source=camera');
                },
              ),
              _SourceOption(
                icon: Icons.photo_library_outlined,
                label: '從相簿選取',
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push('/ootd/add?source=gallery');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({
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
      itemBuilder: (context, index) =>
          _OotdCard(item: items[index], allItems: items, index: index),
    );
  }
}

class _OotdCard extends ConsumerWidget {
  const _OotdCard({
    required this.item,
    required this.allItems,
    required this.index,
  });
  final OotdItem item;
  final List<OotdItem> allItems;
  final int index;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除穿搭'),
        content: const Text('確定要刪除這筆穿搭記錄嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              '刪除',
              style: TextStyle(color: LumiColors.warning),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(ootdLocalProvider.notifier).delete(item.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('刪除失敗，請再試一次')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr =
        '${item.date.year}.${item.date.month.toString().padLeft(2, '0')}.${item.date.day.toString().padLeft(2, '0')}';

    return InkWell(
      borderRadius: BorderRadius.circular(LumiRadii.lg),
      onTap: () => showOotdDetailModal(context, allItems, index),
      onLongPress: () => _confirmDelete(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: LumiColors.surface,
          borderRadius: BorderRadius.circular(LumiRadii.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FutureBuilder<File?>(
                future: LocalOotdStorage.getImageFile(item.id),
                builder: (context, snapshot) {
                  final file = snapshot.data;
                  if (file == null) {
                    return Container(color: LumiColors.base);
                  }
                  return Image.file(
                    file,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) =>
                        Container(color: LumiColors.base),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(LumiSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.caption.isEmpty ? '無備註' : item.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: LumiTypeScale.labelMd,
                      fontWeight: FontWeight.w500,
                      color: LumiColors.text,
                    ),
                  ),
                  const SizedBox(height: LumiSpacing.xs),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: LumiTypeScale.labelSm,
                      color: LumiColors.subtext,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                    color: LumiColors.glow.withValues(alpha: 0.2),
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
                fontSize: LumiTypeScale.titleLg,
                fontWeight: FontWeight.w600,
                color: LumiColors.text,
              ),
            ),
            const SizedBox(height: LumiSpacing.sm),
            const Text(
              '點擊右下角的按鈕，\n開始記錄妳的每日時尚風格吧！',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: LumiTypeScale.labelMd,
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
          borderRadius: BorderRadius.circular(LumiRadii.lg),
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
        style: const TextStyle(
          fontSize: LumiTypeScale.labelMd,
          color: LumiColors.warning,
        ),
      ),
    );
  }
}
