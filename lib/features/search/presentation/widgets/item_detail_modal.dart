import 'package:flutter/material.dart';
import '../../../../shared/constants/lumi_colors.dart';
import '../../../../shared/constants/lumi_spacing.dart';
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: LumiSpacing.md,
        vertical: LumiSpacing.xl,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: LumiColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 圖片區
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: LumiColors.base,
                child: Image.network(
                  item.thumbnailUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.checkroom_outlined,
                      size: 56,
                      color: LumiColors.subtext,
                    ),
                  ),
                ),
              ),
            ),
            // 右上角關閉按鈕（絕對定位）
            const SizedBox(height: LumiSpacing.md),
            // Metadata 列
            if (item.analyzed)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LumiSpacing.lg,
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: LumiSpacing.sm,
                  runSpacing: LumiSpacing.xs,
                  children: [
                    if (item.materials.isNotEmpty)
                      _MetaChip('材質：${item.materials.join('、')}'),
                    if (item.colors.isNotEmpty)
                      _MetaChip('顏色：${item.colors.first}'),
                    if (item.category.isNotEmpty)
                      _MetaChip('種類：${item.category}'),
                  ],
                ),
              ),
            const SizedBox(height: LumiSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(bottom: LumiSpacing.md),
              child: Text(
                '加入時間：${_formatDate(item.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: LumiColors.subtext,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: LumiColors.text,
        ),
      ),
    );
  }
}

String _formatDate(DateTime dt) =>
    '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
