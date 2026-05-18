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
  final _brandedCardKey = GlobalKey();

  String get _dateStr {
    final d = widget.date;
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _share(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final screenSize = MediaQuery.sizeOf(context);

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
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: LumiColors.overlayDark,
      body: Stack(
        children: [
          // ── Main layout ────────────────────────────────────────────────
          Positioned.fill(
            child: Column(
              children: [
                // Space for floating header
                SizedBox(height: topPad + LumiSpacing.xl + LumiSpacing.sm),

                // Branded card
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LumiSpacing.md,
                    ),
                    // ClipRRect is OUTSIDE RepaintBoundary — visual only on screen.
                    // Captured PNG stays rectangular (no white-corner artifact on share).
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(LumiRadii.xl),
                      child: RepaintBoundary(
                        key: _brandedCardKey,
                        child: _BrandedCard(
                          photoBytes: widget.photoBytes,
                          caption: widget.caption,
                          dateStr: _dateStr,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: LumiSpacing.md),

                // Action buttons
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    LumiSpacing.md,
                    0,
                    LumiSpacing.md,
                    LumiSpacing.md + botPad,
                  ),
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
              ],
            ),
          ),

          // ── Floating header ────────────────────────────────────────────
          Positioned(
            top: topPad + LumiSpacing.xs,
            left: LumiSpacing.md,
            right: LumiSpacing.md,
            child: Row(
              children: [
                // 返回按鈕（icon + 文字，符合 Lumi 設計規範）
                Material(
                  color: LumiColors.onPrimary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(LumiRadii.pill),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(LumiRadii.pill),
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: LumiSpacing.sm,
                        vertical: LumiSpacing.xs + 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_ios_new,
                            size: 13,
                            color: LumiColors.onPrimary.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: LumiSpacing.xs),
                          Text(
                            '返回',
                            style: TextStyle(
                              fontSize: LumiTypeScale.labelMd,
                              fontWeight: FontWeight.w600,
                              color:
                                  LumiColors.onPrimary.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // 頁面標題
                Text(
                  '分享穿搭',
                  style: TextStyle(
                    fontSize: LumiTypeScale.titleSm,
                    fontWeight: FontWeight.w600,
                    color: LumiColors.onPrimary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
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
  });

  final Uint8List photoBytes;
  final String caption;
  final String dateStr;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Photo area — fills remaining space
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(photoBytes, fit: BoxFit.cover),
              // Bottom gradient for legibility
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
                        LumiColors.text.withValues(alpha: 0.60),
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
              // Caption + date at bottom
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
                        color: LumiColors.onPrimary.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Branding strip — always part of exported image
        Container(
          height: 40,
          decoration: const BoxDecoration(
            gradient: LumiColors.buttonGradient,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: LumiColors.onPrimary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'L',
                    style: TextStyle(
                      fontSize: 11,
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
                height: 12,
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
                size: 11,
                color: LumiColors.onPrimary.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ],
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
        child: const Center(
          child: Text(
            '分享穿搭',
            style: TextStyle(
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
