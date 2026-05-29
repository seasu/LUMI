import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/local_image_storage.dart';
import '../../../../core/storage/local_wardrobe_store.dart';
import '../../../../l10n/generated/app_localizations.dart';
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

void showItemDetailModal(
  BuildContext context,
  List<WardrobeItem> items,
  int initialIndex,
) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 360),
    pageBuilder: (ctx, _, __) => _ItemDetailModal(
      items: items,
      initialIndex: initialIndex,
    ),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

// ── Modal (manages PageView + edit state) ─────────────────────────────────────

class _ItemDetailModal extends ConsumerStatefulWidget {
  const _ItemDetailModal({required this.items, required this.initialIndex});
  final List<WardrobeItem> items;
  final int initialIndex;

  @override
  ConsumerState<_ItemDetailModal> createState() => _ItemDetailModalState();
}

class _ItemDetailModalState extends ConsumerState<_ItemDetailModal> {
  late final PageController _pageController;
  late final List<WardrobeItem> _items;
  late int _currentIndex;
  bool _editing = false;
  bool _saving = false;
  late String _editCategory;
  late Set<String> _editColors;
  late List<String> _editMaterials;

  WardrobeItem get _currentItem => _items[_currentIndex];

  @override
  void initState() {
    super.initState();
    _items = List<WardrobeItem>.from(widget.items);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _resetEdit(_items[widget.initialIndex]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
            _currentItem.docId,
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
    final liveStore = ref.watch(localWardrobeProvider).valueOrNull ?? [];

    return Material(
      color: LumiColors.base,
      child: PageView.builder(
        controller: _pageController,
        physics: _editing
            ? const NeverScrollableScrollPhysics()
            : const ClampingScrollPhysics(),
        onPageChanged: (index) => setState(() {
          _currentIndex = index;
          _editing = false;
          _resetEdit(_items[index]);
        }),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final liveItem = liveStore.firstWhere(
            (i) => i.docId == _items[index].docId,
            orElse: () => _items[index],
          );

          if (index == _currentIndex && _editing) {
            return _buildEditLayout(context, liveItem);
          }
          return _buildViewLayout(context, liveItem);
        },
      ),
    );
  }

  // ── 檢視模式：滿版照片 + gradient overlay ─────────────────────────────────

  Widget _buildViewLayout(BuildContext context, WardrobeItem item) {
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    return GestureDetector(
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 400) Navigator.of(context).pop();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 全幅照片
          _ModalImage(localFileName: item.localFileName),

          // 上方暗 scrim
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: topPad + 130,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    LumiColors.text.withValues(alpha: 0.68),
                    LumiColors.text.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // 下方暗 scrim
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: botPad + 320,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    LumiColors.text.withValues(alpha: 0.0),
                    LumiColors.text.withValues(alpha: 0.88),
                  ],
                ),
              ),
            ),
          ),

          // 日期 chip — 左上
          Positioned(
            top: topPad + LumiSpacing.sm,
            left: LumiSpacing.md,
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
                _formatDate(item.createdAt),
                style: const TextStyle(
                  fontSize: LumiTypeScale.labelSm,
                  fontWeight: FontWeight.w600,
                  color: LumiColors.text,
                ),
              ),
            ),
          ),

          // 關閉按鈕 — 右上
          Positioned(
            top: topPad + LumiSpacing.xs,
            right: LumiSpacing.md,
            child: Material(
              color: LumiColors.surface.withValues(alpha: 0.82),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.all(LumiSpacing.sm),
                  child: Icon(Icons.close, size: 20, color: LumiColors.text),
                ),
              ),
            ),
          ),

          // 下方資訊 overlay
          Positioned(
            bottom: botPad + LumiSpacing.xl,
            left: LumiSpacing.md,
            right: LumiSpacing.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!item.analyzed) ...[
                  _InfoPill(
                    item.analyzeError != null
                        ? AppLocalizations.of(context).itemDetailAnalyzeFailed
                        : AppLocalizations.of(context).itemDetailAnalyzing,
                  ),
                  const SizedBox(height: LumiSpacing.sm),
                ],

                if (item.analyzed && item.materials.isNotEmpty) ...[
                  Wrap(
                    spacing: LumiSpacing.xs,
                    runSpacing: LumiSpacing.xs,
                    children: item.materials
                        .map((m) => _InfoPill(m))
                        .toList(),
                  ),
                  const SizedBox(height: LumiSpacing.sm),
                ],

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (item.analyzed && item.category.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: LumiSpacing.md,
                          vertical: LumiSpacing.xs + 2,
                        ),
                        decoration: BoxDecoration(
                          color: LumiColors.onPrimary.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(LumiRadii.pill),
                        ),
                        child: Text(
                          item.category,
                          style: const TextStyle(
                            fontSize: LumiTypeScale.labelMd,
                            fontWeight: FontWeight.w600,
                            color: LumiColors.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: LumiSpacing.xs),
                    ],
                    if (item.analyzed)
                      ...item.colors.take(5).map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: _parseHex(c),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: LumiColors.onPrimary
                                        .withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                    const Spacer(),
                    if (item.analyzed)
                      Material(
                        color: LumiColors.onPrimary.withValues(alpha: 0.18),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            _resetEdit(item);
                            setState(() => _editing = true);
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: LumiColors.onPrimary
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: LumiColors.onPrimary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 編輯模式：滿版佈局 ─────────────────────────────────────────────────────

  Widget _buildEditLayout(BuildContext context, WardrobeItem item) {
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;
    final screenH = MediaQuery.of(context).size.height;
    final photoH = (screenH * 0.30).clamp(220.0, 320.0);

    return Column(
      children: [
        SizedBox(
          height: photoH + topPad,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _ModalImage(localFileName: item.localFileName),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        LumiColors.text.withValues(alpha: 0.0),
                        LumiColors.text.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                top: topPad + LumiSpacing.sm,
                left: LumiSpacing.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LumiSpacing.sm,
                    vertical: LumiSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    gradient: LumiColors.buttonGradient,
                    borderRadius: BorderRadius.circular(LumiRadii.pill),
                  ),
                  child: Text(
                    AppLocalizations.of(context).itemDetailEditBadge,
                    style: const TextStyle(
                      fontSize: LumiTypeScale.labelSm,
                      fontWeight: FontWeight.w600,
                      color: LumiColors.onPrimary,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: topPad + LumiSpacing.xs,
                right: LumiSpacing.md,
                child: Material(
                  color: LumiColors.surface.withValues(alpha: 0.82),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(LumiSpacing.sm),
                      child: Icon(Icons.close, size: 20, color: LumiColors.text),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ColoredBox(
            color: LumiColors.surface,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                LumiSpacing.lg,
                LumiSpacing.lg,
                LumiSpacing.lg,
                LumiSpacing.lg + botPad,
              ),
              child: _buildEditSection(),
            ),
          ),
        ),
      ],
    );
  }

  // ── 編輯表單內容 ──────────────────────────────────────────────────────────

  Widget _buildEditSection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(l10n.itemDetailCategory),
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
                      gradient: active ? LumiColors.buttonGradient : null,
                      color: active ? null : LumiColors.base,
                      borderRadius: BorderRadius.circular(LumiRadii.pill),
                    ),
                    child: Text(
                      cat,
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
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: LumiSpacing.lg),

        _SectionLabel(l10n.itemDetailColors),
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

        const SizedBox(height: LumiSpacing.lg),

        _SectionLabel(l10n.itemDetailMaterials),
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
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? LumiColors.onPrimary : LumiColors.text,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: LumiSpacing.xl),

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
                  padding: const EdgeInsets.symmetric(
                    vertical: LumiSpacing.sm + 2,
                  ),
                ),
                child: Text(l10n.cancel),
              ),
            ),
            const SizedBox(width: LumiSpacing.sm),
            Expanded(
              child: GestureDetector(
                onTap: _saving ? null : _save,
                child: Container(
                  height: 44,
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
                        : Text(
                            l10n.save,
                            style: const TextStyle(
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
    return const ColoredBox(
      color: LumiColors.base,
      child: Center(
        child: Icon(Icons.checkroom_outlined, size: 64, color: LumiColors.subtext),
      ),
    );
  }
}

// ── 資訊 Pill ─────────────────────────────────────────────────────────────────

class _InfoPill extends StatelessWidget {
  const _InfoPill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LumiSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: LumiColors.onPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(LumiRadii.pill),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: LumiTypeScale.labelSm,
          color: LumiColors.onPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
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
    (0.299 * color.r + 0.587 * color.g + 0.114 * color.b) > 0.5;

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
  String? nearest;
  double minDist = double.infinity;
  for (final (_, bHex) in _kColorOptions) {
    final b = _parseHex(bHex);
    final dr = ai.r - b.r;
    final dg = ai.g - b.g;
    final db = ai.b - b.b;
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
