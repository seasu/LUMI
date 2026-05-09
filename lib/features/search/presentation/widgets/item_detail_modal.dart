import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../core/storage/local_image_storage.dart';
import '../../../../shared/constants/lumi_colors.dart';
import '../../../../shared/constants/lumi_radii.dart';
import '../../../../shared/constants/lumi_spacing.dart';
import '../../../../shared/constants/lumi_type_scale.dart';
import '../../../wardrobe/data/wardrobe_item.dart';

void showItemDetailModal(BuildContext context, WardrobeItem item) {
  showDialog(
    context: context,
    barrierColor: LumiColors.overlayBarrier,
    builder: (_) => _ItemDetailModal(item: item),
  );
}

class _ItemDetailModal extends StatelessWidget {
  const _ItemDetailModal({required this.item});

  final WardrobeItem item;

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
            // ── 圖片區（3:4 直幅） ─────────────────────────────────
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: ColoredBox(
                    color: LumiColors.base,
                    child: _ModalImage(localFileName: item.localFileName),
                  ),
                ),
                // 關閉按鈕
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

            // ── 資訊區（可捲動，內容多時不 overflow） ─────────────
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
                    if (item.analyzed) ...[
                      if (item.category.isNotEmpty) ...[
                        const _SectionLabel('種類'),
                        const SizedBox(height: LumiSpacing.xs),
                        _MetaChip(item.category),
                        const SizedBox(height: LumiSpacing.md),
                      ],
                      if (item.materials.isNotEmpty) ...[
                        const _SectionLabel('材質'),
                        const SizedBox(height: LumiSpacing.xs),
                        Wrap(
                          spacing: LumiSpacing.xs,
                          runSpacing: LumiSpacing.xs,
                          children: item.materials
                              .map((m) => _MetaChip(m))
                              .toList(),
                        ),
                        const SizedBox(height: LumiSpacing.md),
                      ],
                      if (item.colors.isNotEmpty) ...[
                        const _SectionLabel('顏色'),
                        const SizedBox(height: LumiSpacing.xs),
                        Wrap(
                          spacing: LumiSpacing.sm,
                          runSpacing: LumiSpacing.sm,
                          children: item.colors
                              .map((c) => _ColorSwatch(c))
                              .toList(),
                        ),
                        const SizedBox(height: LumiSpacing.md),
                      ],
                    ] else ...[
                      // 未分析完成
                      Text(
                        item.analyzeError != null ? '分析失敗，可下拉重試' : '分析中…',
                        style: const TextStyle(
                          fontSize: LumiTypeScale.labelMd,
                          color: LumiColors.subtext,
                        ),
                      ),
                      const SizedBox(height: LumiSpacing.md),
                    ],
                    Text(
                      '加入：${_formatDate(item.createdAt)}',
                      style: const TextStyle(
                        fontSize: LumiTypeScale.labelSm,
                        color: LumiColors.subtext,
                      ),
                    ),
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
  const _ModalImage({required this.localFileName});

  final String localFileName;

  @override
  Widget build(BuildContext context) {
    if (localFileName.isEmpty) return const _Placeholder();
    return FutureBuilder<File?>(
      future: LocalImageStorage.getFile(localFileName),
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
      child: Icon(Icons.checkroom_outlined, size: 56, color: LumiColors.subtext),
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

// ── 文字 Chip ─────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  const _MetaChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LumiSpacing.md,
        vertical: LumiSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: LumiColors.base,
        borderRadius: BorderRadius.circular(LumiRadii.pill),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: LumiTypeScale.labelMd,
          color: LumiColors.text,
        ),
      ),
    );
  }
}

// ── 顏色色票 ──────────────────────────────────────────────────────────────────

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch(this.hex);
  final String hex;

  @override
  Widget build(BuildContext context) {
    final color = _parseHex(hex);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: LumiColors.subtext.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
    );
  }

  Color _parseHex(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
    } catch (_) {}
    return LumiColors.base;
  }
}

// ── Helper ────────────────────────────────────────────────────────────────────

String _formatDate(DateTime dt) =>
    '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
