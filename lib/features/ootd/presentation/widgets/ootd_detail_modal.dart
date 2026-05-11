import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../shared/constants/lumi_colors.dart';
import '../../../../shared/constants/lumi_radii.dart';
import '../../../../shared/constants/lumi_spacing.dart';
import '../../../../shared/constants/lumi_type_scale.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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
        backgroundColor: LumiColors.surface,
        title: const Text(
          '刪除穿搭',
          style: TextStyle(fontSize: LumiTypeScale.titleSm, color: LumiColors.text),
        ),
        content: const Text(
          '確定要刪除這筆穿搭記錄嗎？',
          style: TextStyle(fontSize: LumiTypeScale.labelMd, color: LumiColors.subtext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              '取消',
              style: TextStyle(color: LumiColors.subtext),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: LumiColors.warning),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (userId == null) return;

    try {
      await ref.read(ootdRepositoryProvider).deleteItem(userId, item.id);
    } catch (_) {}

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
        constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
        decoration: BoxDecoration(
          color: LumiColors.surface,
          borderRadius: BorderRadius.circular(LumiRadii.xl),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: ColoredBox(
                    color: LumiColors.base,
                    child: _ModalImage(imageBase64: item.imageBase64),
                  ),
                ),
                Positioned(
                  top: LumiSpacing.sm,
                  right: LumiSpacing.sm,
                  child: Material(
                    color: LumiColors.surface.withValues(alpha: 0.82),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(LumiSpacing.xs),
                        child: Icon(Icons.close, size: 20, color: LumiColors.text),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  LumiSpacing.lg,
                  LumiSpacing.md,
                  LumiSpacing.lg,
                  LumiSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('日期'),
                    const SizedBox(height: LumiSpacing.xs),
                    Text(
                      _formatDate(item.date),
                      style: const TextStyle(
                        fontSize: LumiTypeScale.labelMd,
                        color: LumiColors.text,
                      ),
                    ),
                    if (item.caption.isNotEmpty) ...[
                      const SizedBox(height: LumiSpacing.md),
                      const _SectionLabel('備註'),
                      const SizedBox(height: LumiSpacing.xs),
                      Text(
                        item.caption,
                        style: const TextStyle(
                          fontSize: LumiTypeScale.labelMd,
                          color: LumiColors.text,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: LumiSpacing.lg),
                    _ShareButton(item: item),
                    const SizedBox(height: LumiSpacing.sm),
                    _DeleteButton(onTap: () => _deleteItem(context, ref)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 圖片 ──────────────────────────────────────────────────────────────────────

class _ModalImage extends StatelessWidget {
  const _ModalImage({required this.imageBase64});

  final String imageBase64;

  @override
  Widget build(BuildContext context) {
    if (imageBase64.isEmpty) return const _Placeholder();
    Uint8List? bytes;
    try {
      bytes = base64Decode(imageBase64);
    } catch (_) {}
    if (bytes == null) return const _Placeholder();
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _Placeholder(),
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

// ── 區塊標籤 ──────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: LumiTypeScale.labelMd,
        fontWeight: FontWeight.w600,
        color: LumiColors.subtext,
        letterSpacing: 0.4,
      ),
    );
  }
}

// ── 分享按鈕 ──────────────────────────────────────────────────────────────────

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.item});

  final OotdItem item;

  Future<void> _share(BuildContext context) async {
    try {
      final bytes = base64Decode(item.imageBase64);
      final tmp = await getTemporaryDirectory();
      final file = File('${tmp.path}/lumi_ootd_${item.id}.jpg');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], subject: '我的 Lumi 穿搭');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('此裝置不支援分享功能')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _share(context),
        icon: const Icon(Icons.ios_share, size: 18),
        label: const Text('分享穿搭'),
        style: OutlinedButton.styleFrom(
          foregroundColor: LumiColors.primary,
          side: BorderSide(color: LumiColors.primary.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LumiRadii.pill),
          ),
          textStyle: const TextStyle(
            fontSize: LumiTypeScale.labelMd,
            fontWeight: FontWeight.w600,
          ),
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
      height: 48,
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.delete_outline, size: 18),
        label: const Text('刪除穿搭'),
        style: TextButton.styleFrom(
          foregroundColor: LumiColors.warning,
          textStyle: const TextStyle(
            fontSize: LumiTypeScale.labelMd,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Helper ────────────────────────────────────────────────────────────────────

String _formatDate(DateTime dt) =>
    '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
