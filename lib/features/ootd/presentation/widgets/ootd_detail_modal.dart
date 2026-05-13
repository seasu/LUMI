import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/storage/local_ootd_storage.dart';
import '../../../../shared/constants/lumi_colors.dart';
import '../../../../shared/constants/lumi_radii.dart';
import '../../../../shared/constants/lumi_spacing.dart';
import '../../../../shared/constants/lumi_type_scale.dart';
import '../../data/ootd_repository.dart';
import '../../domain/ootd_item.dart';

void showOotdDetailModal(BuildContext context, OotdItem item) {
  showDialog(
    context: context,
    barrierColor: LumiColors.overlayBarrier,
    builder: (_) => _OotdDetailModal(item: item),
  );
}

class _OotdDetailModal extends ConsumerWidget {
  const _OotdDetailModal({required this.item});

  final OotdItem item;

  Future<void> _deleteItem(BuildContext context, WidgetRef ref) async {
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
        return;
      }
    }

    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: LumiSpacing.md,
        vertical: LumiSpacing.xl,
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
        decoration: BoxDecoration(
          color: LumiColors.surface,
          borderRadius: BorderRadius.circular(LumiRadii.xl),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Photo hero ──────────────────────────────────────────────
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: ColoredBox(
                    color: LumiColors.base,
                    child: _ModalImage(itemId: item.id),
                  ),
                ),

                // Gradient overlay — bottom third, makes text readable
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          LumiColors.text.withValues(alpha: 0.0),
                          LumiColors.text.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                ),

                // Caption overlaid on photo
                if (item.caption.isNotEmpty)
                  Positioned(
                    left: LumiSpacing.md,
                    right: LumiSpacing.md,
                    bottom: LumiSpacing.md,
                    child: Text(
                      item.caption,
                      style: const TextStyle(
                        fontSize: LumiTypeScale.body,
                        color: LumiColors.onPrimary,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // Date chip — top-left
                Positioned(
                  top: LumiSpacing.sm,
                  left: LumiSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LumiSpacing.sm,
                      vertical: LumiSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: LumiColors.surface.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(LumiRadii.pill),
                    ),
                    child: Text(
                      _formatDate(item.date),
                      style: const TextStyle(
                        fontSize: LumiTypeScale.labelSm,
                        color: LumiColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Close button — top-right
                Positioned(
                  top: LumiSpacing.sm,
                  right: LumiSpacing.sm,
                  child: _CloseButton(
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),

            // ── Actions ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LumiSpacing.lg,
                LumiSpacing.lg,
                LumiSpacing.lg,
                LumiSpacing.md,
              ),
              child: Column(
                children: [
                  _ShareButton(item: item),
                  const SizedBox(height: LumiSpacing.xs),
                  _DeleteButton(
                    onTap: () => _deleteItem(context, ref),
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

// ── Close Button ──────────────────────────────────────────────────────────────

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: LumiColors.surface.withValues(alpha: 0.88),
        ),
        child: const Icon(Icons.close, size: 18, color: LumiColors.text),
      ),
    );
  }
}

// ── 圖片 ──────────────────────────────────────────────────────────────────────

class _ModalImage extends StatelessWidget {
  const _ModalImage({required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: LocalOotdStorage.getImageFile(itemId),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) return const _Placeholder();
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const _Placeholder(),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.style_outlined, size: 56, color: LumiColors.subtext),
    );
  }
}

// ── 分享按鈕 ──────────────────────────────────────────────────────────────────

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.item});

  final OotdItem item;

  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;

    try {
      final file = await LocalOotdStorage.getImageFile(item.id);
      if (file == null) throw Exception('找不到圖片');

      final tmp = await getTemporaryDirectory();
      final shareFile = File('${tmp.path}/lumi_ootd_${item.id}.jpg');
      await shareFile.writeAsBytes(await file.readAsBytes());

      await Share.shareXFiles(
        [XFile(shareFile.path)],
        subject: '我的 Lumi 穿搭',
        sharePositionOrigin: origin,
      );
    } catch (_) {
      if (!context.mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('分享失敗'),
          content: const Text('無法分享此穿搭，請稍後再試。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('確定'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _share(context),
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LumiColors.buttonGradient,
          borderRadius: BorderRadius.circular(LumiRadii.pill),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.ios_share, size: 18, color: LumiColors.onPrimary),
            SizedBox(width: LumiSpacing.sm),
            Text(
              '分享穿搭',
              style: TextStyle(
                fontSize: LumiTypeScale.body,
                fontWeight: FontWeight.w600,
                color: LumiColors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 刪除按鈕 ──────────────────────────────────────────────────────────────────

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.delete_outline, size: 16),
        label: const Text('刪除這套穿搭'),
        style: TextButton.styleFrom(
          foregroundColor: LumiColors.subtext,
          textStyle: const TextStyle(
            fontSize: LumiTypeScale.labelMd,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── Helper ────────────────────────────────────────────────────────────────────

String _formatDate(DateTime dt) =>
    '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
