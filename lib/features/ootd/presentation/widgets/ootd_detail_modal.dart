import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../shared/constants/lumi_colors.dart';
import '../../../../shared/constants/lumi_radii.dart';
import '../../../../shared/constants/lumi_spacing.dart';
import '../../../../shared/constants/lumi_type_scale.dart';
import '../../domain/ootd_item.dart';

void showOotdDetailModal(BuildContext context, OotdItem item) {
  showDialog(
    context: context,
    barrierColor: LumiColors.overlayBarrier,
    builder: (_) => _OotdDetailModal(item: item),
  );
}

class _OotdDetailModal extends StatelessWidget {
  const _OotdDetailModal({required this.item});

  final OotdItem item;

  @override
  Widget build(BuildContext context) {
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
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: LumiColors.text,
                        ),
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
                    _ShareButton(item: item, context: context),
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
  const _ShareButton({required this.item, required this.context});

  final OotdItem item;
  final BuildContext context;

  Future<void> _share() async {
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
        onPressed: _share,
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

// ── Helper ────────────────────────────────────────────────────────────────────

String _formatDate(DateTime dt) =>
    '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
