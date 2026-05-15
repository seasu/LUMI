import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_radii.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../../shared/constants/lumi_type_scale.dart';

class OotdSharePage extends StatefulWidget {
  const OotdSharePage({
    super.key,
    required this.photoBytes,
    required this.caption,
    required this.date,
  });

  final Uint8List photoBytes;
  final String caption;
  final DateTime date;

  @override
  State<OotdSharePage> createState() => _OotdSharePageState();
}

class _OotdSharePageState extends State<OotdSharePage> {
  final _pageController = PageController();
  final _brandedCardKey = GlobalKey();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String get _dateStr {
    final d = widget.date;
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _share(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final screenSize = MediaQuery.sizeOf(context);

    // Ensure branded card page is rendered on screen before capture
    if (_currentPage != 1) {
      await _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;

    try {
      final boundary = _brandedCardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('截圖初始化失敗');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('截圖轉換失敗');

      final bytes = byteData.buffer.asUint8List();
      final tmp = await getTemporaryDirectory();
      final file = File('${tmp.path}/lumi_ootd_share.png');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      final shareOrigin = Rect.fromCenter(
        center: Offset(screenSize.width / 2, screenSize.height / 2),
        width: 1,
        height: 1,
      );
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '我的 Lumi 穿搭',
        sharePositionOrigin: shareOrigin,
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('分享失敗：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final cardW = screenW - LumiSpacing.xl * 2;
    final cardH = cardW * 4 / 3;

    return Scaffold(
      backgroundColor: LumiColors.overlayDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LumiSpacing.sm,
                LumiSpacing.sm,
                LumiSpacing.md,
                0,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: LumiColors.onPrimary,
                    ),
                  ),
                  Text(
                    '分享穿搭',
                    style: TextStyle(
                      fontSize: LumiTypeScale.titleSm,
                      fontWeight: FontWeight.w600,
                      color: LumiColors.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: LumiSpacing.sm),

            // ── Cards PageView ───────────────────────────────────────────
            SizedBox(
              height: cardH,
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  // Page 0: Original photo
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LumiSpacing.xl,
                    ),
                    child: _OriginalCard(
                      photoBytes: widget.photoBytes,
                      cardW: cardW,
                      cardH: cardH,
                    ),
                  ),
                  // Page 1: Branded share card (captured for export)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LumiSpacing.xl,
                    ),
                    child: RepaintBoundary(
                      key: _brandedCardKey,
                      child: _BrandedCard(
                        photoBytes: widget.photoBytes,
                        caption: widget.caption,
                        dateStr: _dateStr,
                        cardW: cardW,
                        cardH: cardH,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: LumiSpacing.md),

            // ── Page indicator dots ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (i) {
                final active = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: active ? LumiColors.buttonGradient : null,
                    color: active
                        ? null
                        : LumiColors.onPrimary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(LumiRadii.pill),
                  ),
                );
              }),
            ),

            const SizedBox(height: LumiSpacing.xs),
            Text(
              _currentPage == 0 ? '← 滑動查看分享卡片' : '分享時將使用此卡片',
              style: TextStyle(
                fontSize: LumiTypeScale.labelSm,
                color: LumiColors.onPrimary.withValues(alpha: 0.45),
              ),
            ),

            const Spacer(),

            // ── Action buttons ───────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: LumiSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: _OutlinedButton(
                      label: '分享穿搭',
                      onTap: () => _share(context),
                    ),
                  ),
                  const SizedBox(width: LumiSpacing.sm),
                  Expanded(
                    child: _GradientButton(
                      label: '完成',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: LumiSpacing.lg),
          ],
        ),
      ),
    );
  }
}

// ── Original card ─────────────────────────────────────────────────────────────

class _OriginalCard extends StatelessWidget {
  const _OriginalCard({
    required this.photoBytes,
    required this.cardW,
    required this.cardH,
  });

  final Uint8List photoBytes;
  final double cardW;
  final double cardH;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(LumiRadii.xl),
      child: SizedBox(
        width: cardW,
        height: cardH,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(photoBytes, fit: BoxFit.cover),
            // "原圖" label chip
            Positioned(
              top: LumiSpacing.sm,
              left: LumiSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LumiSpacing.sm,
                  vertical: LumiSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: LumiColors.surface.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(LumiRadii.pill),
                ),
                child: const Text(
                  '原圖',
                  style: TextStyle(
                    fontSize: LumiTypeScale.labelSm,
                    fontWeight: FontWeight.w600,
                    color: LumiColors.text,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Branded share card ────────────────────────────────────────────────────────

class _BrandedCard extends StatelessWidget {
  const _BrandedCard({
    required this.photoBytes,
    required this.caption,
    required this.dateStr,
    required this.cardW,
    required this.cardH,
  });

  final Uint8List photoBytes;
  final String caption;
  final String dateStr;
  final double cardW;
  final double cardH;

  @override
  Widget build(BuildContext context) {
    const brandingH = 44.0;
    final photoH = cardH - brandingH;

    return ClipRRect(
      borderRadius: BorderRadius.circular(LumiRadii.xl),
      child: SizedBox(
        width: cardW,
        height: cardH,
        child: Column(
          children: [
            // Photo area with overlays
            SizedBox(
              width: cardW,
              height: photoH,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(photoBytes, fit: BoxFit.cover),
                  // Bottom gradient for text legibility
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: photoH * 0.45,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            LumiColors.text.withValues(alpha: 0.0),
                            LumiColors.text.withValues(alpha: 0.58),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // "Lumi" gradient chip — top-left
                  Positioned(
                    top: LumiSpacing.sm,
                    left: LumiSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: LumiSpacing.sm,
                        vertical: LumiSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        gradient: LumiColors.buttonGradient,
                        borderRadius: BorderRadius.circular(LumiRadii.pill),
                      ),
                      child: const Text(
                        'Lumi',
                        style: TextStyle(
                          fontSize: LumiTypeScale.labelSm,
                          fontWeight: FontWeight.w700,
                          color: LumiColors.onPrimary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                  // Caption + date stacked at bottom
                  Positioned(
                    left: LumiSpacing.md,
                    right: LumiSpacing.sm,
                    bottom: LumiSpacing.xs,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (caption.isNotEmpty) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              caption,
                              style: const TextStyle(
                                fontSize: LumiTypeScale.body,
                                color: LumiColors.onPrimary,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: LumiSpacing.xs),
                        ],
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: LumiTypeScale.labelSm,
                            color:
                                LumiColors.onPrimary.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Branding strip
            Container(
              width: cardW,
              height: brandingH,
              decoration: const BoxDecoration(
                gradient: LumiColors.buttonGradient,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: LumiColors.onPrimary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'L',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: LumiColors.onPrimary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: LumiSpacing.xs),
                  const Text(
                    'Lumi',
                    style: TextStyle(
                      fontSize: LumiTypeScale.labelMd,
                      fontWeight: FontWeight.w700,
                      color: LumiColors.onPrimary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Container(
                    height: 14,
                    width: 1,
                    margin: const EdgeInsets.symmetric(
                      horizontal: LumiSpacing.sm,
                    ),
                    color: LumiColors.onPrimary.withValues(alpha: 0.3),
                  ),
                  const Text(
                    '用AI記錄每日穿搭風格',
                    style: TextStyle(
                      fontSize: LumiTypeScale.labelSm,
                      color: LumiColors.onPrimary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: LumiSpacing.xs),
                  Icon(
                    Icons.arrow_forward,
                    size: 12,
                    color: LumiColors.onPrimary.withValues(alpha: 0.8),
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

// ── Buttons ───────────────────────────────────────────────────────────────────

class _OutlinedButton extends StatelessWidget {
  const _OutlinedButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          border: Border.all(
            color: LumiColors.onPrimary.withValues(alpha: 0.45),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(LumiRadii.pill),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: LumiTypeScale.body,
              fontWeight: FontWeight.w600,
              color: LumiColors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: LumiColors.buttonGradient,
          borderRadius: BorderRadius.circular(LumiRadii.pill),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: LumiTypeScale.body,
              fontWeight: FontWeight.w600,
              color: LumiColors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
