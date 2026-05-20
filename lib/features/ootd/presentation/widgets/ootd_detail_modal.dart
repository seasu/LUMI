import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/local_ootd_storage.dart';
import '../../../../shared/constants/lumi_colors.dart';
import '../../../../shared/constants/lumi_radii.dart';
import '../../../../shared/constants/lumi_spacing.dart';
import '../../../../shared/constants/lumi_type_scale.dart';
import '../../data/ootd_repository.dart';
import '../../domain/ootd_item.dart';
import '../ootd_share_page.dart';

// ── 進入點 ────────────────────────────────────────────────────────────────────

void showOotdDetailModal(
  BuildContext context,
  List<OotdItem> items,
  int initialIndex,
) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 360),
    pageBuilder: (ctx, _, __) => _OotdDetailModal(
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

// ── Modal (manages PageView + deletion) ───────────────────────────────────────

class _OotdDetailModal extends ConsumerStatefulWidget {
  const _OotdDetailModal({required this.items, required this.initialIndex});
  final List<OotdItem> items;
  final int initialIndex;

  @override
  ConsumerState<_OotdDetailModal> createState() => _OotdDetailModalState();
}

class _OotdDetailModalState extends ConsumerState<_OotdDetailModal> {
  late final PageController _pageController;
  late final List<OotdItem> _items;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _items = List<OotdItem>.from(widget.items);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _deleteItem(int index) async {
    final item = _items[index];
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
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(ootdLocalProvider.notifier).delete(item.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('刪除失敗，請再試一次')));
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _items.removeAt(index);
      if (_currentIndex >= _items.length) {
        _currentIndex = _items.isEmpty ? 0 : _items.length - 1;
      }
    });

    if (_items.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    _pageController.jumpToPage(_currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LumiColors.overlayDark,
      child: PageView.builder(
        controller: _pageController,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemCount: _items.length,
        itemBuilder: (context, index) => _OotdDetailPage(
          item: _items[index],
          onDelete: () => _deleteItem(index),
        ),
      ),
    );
  }
}

// ── Single outfit page ────────────────────────────────────────────────────────

class _OotdDetailPage extends StatelessWidget {
  const _OotdDetailPage({required this.item, required this.onDelete});
  final OotdItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
          _ModalImage(itemId: item.id),

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
              height: botPad + 280,
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
                _formatDate(item.date),
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

          // 下方 overlay：文案 + 操作
          Positioned(
            bottom: botPad + LumiSpacing.lg,
            left: LumiSpacing.md,
            right: LumiSpacing.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.caption.isNotEmpty) ...[
                  Text(
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
                  const SizedBox(height: LumiSpacing.md),
                ],
                _ShareButton(item: item),
                const SizedBox(height: LumiSpacing.xs),
                _DeleteButton(onTap: onDelete),
              ],
            ),
          ),
        ],
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
    return const ColoredBox(
      color: LumiColors.base,
      child: Center(
        child: Icon(Icons.style_outlined, size: 64, color: LumiColors.subtext),
      ),
    );
  }
}

// ── 分享按鈕 ──────────────────────────────────────────────────────────────────

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.item});
  final OotdItem item;

  Future<void> _share(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      final file = await LocalOotdStorage.getImageFile(item.id);
      if (file == null) throw Exception('找不到圖片');
      final bytes = await file.readAsBytes();

      nav.pop();
      nav.push(
        PageRouteBuilder<void>(
          pageBuilder: (_, __, ___) => OotdSharePage(
            photoBytes: bytes,
            caption: item.caption,
            date: item.date,
          ),
          transitionDuration: const Duration(milliseconds: 360),
          transitionsBuilder: (_, anim, __, child) {
            final curved =
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            );
          },
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('無法開啟分享，找不到圖片')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(LumiRadii.pill),
      child: InkWell(
        onTap: () => _share(context),
        borderRadius: BorderRadius.circular(LumiRadii.pill),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LumiColors.buttonGradient,
            borderRadius: BorderRadius.circular(LumiRadii.pill),
          ),
          child: const SizedBox(
            height: 52,
            child: Row(
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
        icon: Icon(
          Icons.delete_outline,
          size: 16,
          color: LumiColors.onPrimary.withValues(alpha: 0.55),
        ),
        label: Text(
          '刪除這套穿搭',
          style: TextStyle(
            color: LumiColors.onPrimary.withValues(alpha: 0.55),
          ),
        ),
        style: TextButton.styleFrom(
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
