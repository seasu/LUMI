import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/local_image_storage.dart';
import '../../../../core/storage/local_wardrobe_store.dart';
import '../../../../shared/constants/lumi_colors.dart';
import '../../../../shared/constants/lumi_radii.dart';
import '../../../../shared/constants/lumi_spacing.dart';
import '../../../../shared/constants/lumi_type_scale.dart';
import '../../../wardrobe/data/wardrobe_item.dart';

// ── 編輯選項常數 ──────────────────────────────────────────────────────────────

const _kCategories = ['連身裙', '上衣', '下身', '鞋履', '包款', '配件'];

const _kColorOptions = <(String, String)>[
  ('紅', '#E53935'), ('橘', '#F57C00'), ('黃', '#FDD835'), ('綠', '#43A047'),
  ('藍', '#1E88E5'), ('紫', '#8E24AA'), ('粉', '#EC407A'), ('棕', '#6D4C41'),
  ('米', '#D7CCC8'), ('黑', '#212121'), ('白', '#F5F5F5'), ('灰', '#9E9E9E'),
];

const _kMaterials = [
  '棉', '麻', '羊毛', '蠶絲', '聚酯纖維', '尼龍',
  '牛仔', '皮革', '絲絨', '針織', '雪紡', '亞麻',
];

// ── 進入點 ────────────────────────────────────────────────────────────────────

void showItemDetailModal(BuildContext context, WardrobeItem item) {
  showDialog(
    context: context,
    barrierColor: LumiColors.overlayBarrier,
    builder: (_) => _ItemDetailModal(item: item),
  );
}

// ── Modal ─────────────────────────────────────────────────────────────────────

class _ItemDetailModal extends ConsumerStatefulWidget {
  const _ItemDetailModal({required this.item});
  final WardrobeItem item;

  @override
  ConsumerState<_ItemDetailModal> createState() => _ItemDetailModalState();
}

class _ItemDetailModalState extends ConsumerState<_ItemDetailModal> {
  bool _editing = false;
  bool _saving = false;
  late String _editCategory;
  late Set<String> _editColors;
  late List<String> _editMaterials;

  @override
  void initState() {
    super.initState();
    _resetEdit(widget.item);
  }

  void _resetEdit(WardrobeItem item) {
    _editCategory = item.category;
    _editColors = _nearestBuckets(item.colors).toSet();
    _editMaterials =
        item.materials.where((m) => _kMaterials.contains(m)).toList();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(localWardrobeProvider.notifier).updateUserEdit(
            widget.item.docId,
            category: _editCategory,
            colors: _editColors.toList(),
            materials: _editMaterials,
          );
      if (mounted) setState(() => _editing = false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final items = ref.watch(localWardrobeProvider).valueOrNull ?? [];
    final item = items.firstWhere(
      (i) => i.docId == widget.item.docId,
      orElse: () => widget.item,
    );

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
            // ── 圖片區 ────────────────────────────────────────────────
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: ColoredBox(
                    color: LumiColors.base,
                    child: _ModalImage(localFileName: item.localFileName),
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

            // ── 資訊 / 編輯區 ─────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  LumiSpacing.lg,
                  LumiSpacing.md,
                  LumiSpacing.lg,
                  LumiSpacing.lg,
                ),
                child: _editing
                    ? _buildEditSection()
                    : _buildViewSection(item),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 檢視模式 ──────────────────────────────────────────────────────────────

  Widget _buildViewSection(WardrobeItem item) {
    return Column(
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
              children: item.materials.map((m) => _MetaChip(m)).toList(),
            ),
            const SizedBox(height: LumiSpacing.md),
          ],
          if (item.colors.isNotEmpty) ...[
            const _SectionLabel('顏色'),
            const SizedBox(height: LumiSpacing.xs),
            Wrap(
              spacing: LumiSpacing.sm,
              runSpacing: LumiSpacing.sm,
              children: item.colors.map((c) => _ColorSwatch(c)).toList(),
            ),
            const SizedBox(height: LumiSpacing.md),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                _resetEdit(item);
                setState(() => _editing = true);
              },
              icon: const Icon(Icons.edit_outlined, size: 14),
              label: const Text('編輯辨識結果'),
              style: TextButton.styleFrom(
                foregroundColor: LumiColors.subtext,
                textStyle: const TextStyle(
                  fontSize: LumiTypeScale.labelMd,
                  fontWeight: FontWeight.w400,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: LumiSpacing.sm,
                  vertical: LumiSpacing.xs,
                ),
              ),
            ),
          ),
        ] else ...[
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
    );
  }

  // ── 編輯模式 ──────────────────────────────────────────────────────────────

  Widget _buildEditSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 種類 ────────────────────────────────────────────────────
        const _SectionLabel('種類'),
        const SizedBox(height: LumiSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _kCategories.map((cat) {
              final active = cat == _editCategory;
              return Padding(
                padding: const EdgeInsets.only(right: LumiSpacing.xs),
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _editCategory = active ? '' : cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: LumiSpacing.md,
                      vertical: LumiSpacing.xs + 2,
                    ),
                    decoration: BoxDecoration(
                      gradient:
                          active ? LumiColors.buttonGradient : null,
                      color: active ? null : LumiColors.base,
                      borderRadius:
                          BorderRadius.circular(LumiRadii.pill),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: LumiTypeScale.labelMd,
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: active
                            ? LumiColors.onPrimary
                            : LumiColors.text,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: LumiSpacing.md),

        // ── 顏色 ────────────────────────────────────────────────────
        const _SectionLabel('顏色'),
        const SizedBox(height: LumiSpacing.xs),
        Wrap(
          spacing: LumiSpacing.sm,
          runSpacing: LumiSpacing.md,
          children: _kColorOptions.map((opt) {
            final (name, hex) = opt;
            final selected = _editColors.contains(hex);
            final color = _parseHex(hex);
            return GestureDetector(
              onTap: () => setState(() {
                if (selected) {
                  _editColors.remove(hex);
                } else {
                  _editColors.add(hex);
                }
              }),
              child: SizedBox(
                width: 40,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? LumiColors.primary
                              : LumiColors.subtext.withValues(alpha: 0.2),
                          width: selected ? 2.5 : 1,
                        ),
                      ),
                      child: selected
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: _isLight(color)
                                  ? LumiColors.text
                                  : LumiColors.onPrimary,
                            )
                          : null,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: LumiTypeScale.labelSm,
                        color: LumiColors.subtext.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: LumiSpacing.md),

        // ── 材質 ────────────────────────────────────────────────────
        const _SectionLabel('材質'),
        const SizedBox(height: LumiSpacing.xs),
        Wrap(
          spacing: LumiSpacing.xs,
          runSpacing: LumiSpacing.xs,
          children: _kMaterials.map((mat) {
            final active = _editMaterials.contains(mat);
            return GestureDetector(
              onTap: () => setState(() {
                if (active) {
                  _editMaterials.remove(mat);
                } else {
                  _editMaterials.add(mat);
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: LumiSpacing.md,
                  vertical: LumiSpacing.xs + 2,
                ),
                decoration: BoxDecoration(
                  gradient: active ? LumiColors.buttonGradient : null,
                  color: active ? null : LumiColors.base,
                  borderRadius: BorderRadius.circular(LumiRadii.pill),
                ),
                child: Text(
                  mat,
                  style: TextStyle(
                    fontSize: LumiTypeScale.labelMd,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.w400,
                    color: active
                        ? LumiColors.onPrimary
                        : LumiColors.text,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: LumiSpacing.lg),

        // ── 操作按鈕 ─────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed:
                    _saving ? null : () => setState(() => _editing = false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: LumiColors.subtext,
                  side: BorderSide(
                    color: LumiColors.subtext.withValues(alpha: 0.25),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(LumiRadii.pill),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: LumiSpacing.sm),
                ),
                child: const Text('取消'),
              ),
            ),
            const SizedBox(width: LumiSpacing.sm),
            Expanded(
              child: GestureDetector(
                onTap: _saving ? null : _save,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LumiColors.buttonGradient,
                    borderRadius: BorderRadius.circular(LumiRadii.pill),
                  ),
                  child: Center(
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: LumiColors.onPrimary,
                            ),
                          )
                        : const Text(
                            '儲存',
                            style: TextStyle(
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
      ],
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
      child: Icon(
          Icons.checkroom_outlined, size: 56, color: LumiColors.subtext),
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

// ── 顏色色票（檢視模式）──────────────────────────────────────────────────────

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch(this.hex);
  final String hex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _parseHex(hex),
        shape: BoxShape.circle,
        border: Border.all(
          color: LumiColors.subtext.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _parseHex(String hex) {
  try {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
  } catch (_) {}
  return LumiColors.base;
}

bool _isLight(Color color) =>
    (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) > 127;

/// Maps each AI-generated hex to the nearest bucket hex from [_kColorOptions].
List<String> _nearestBuckets(List<String> aiColors) {
  final result = <String>{};
  for (final hex in aiColors) {
    final nearest = _nearestBucket(hex);
    if (nearest != null) result.add(nearest);
  }
  return result.toList();
}

String? _nearestBucket(String hex) {
  final ai = _parseHex(hex);
  if (ai == LumiColors.base && !hex.toUpperCase().contains('FAF9F8')) {
    return null; // parse failed
  }
  String? nearest;
  double minDist = double.infinity;
  for (final (_, bHex) in _kColorOptions) {
    final b = _parseHex(bHex);
    final dr = (ai.red - b.red).toDouble();
    final dg = (ai.green - b.green).toDouble();
    final db = (ai.blue - b.blue).toDouble();
    final dist = dr * dr + dg * dg + db * db;
    if (dist < minDist) {
      minDist = dist;
      nearest = bHex;
    }
  }
  return nearest;
}

String _formatDate(DateTime dt) =>
    '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
