import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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
  late String _caption;
  late final TextEditingController _captionController;

  @override
  void initState() {
    super.initState();
    _caption = widget.caption;
    _captionController = TextEditingController(text: _caption);
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

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
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('截圖轉換失敗');

      final pngBytes = byteData.buffer.asUint8List();
      final compressed = await FlutterImageCompress.compressWithList(
        pngBytes,
        minWidth: 1080,
        minHeight: 1920,
        quality: 85,
        format: CompressFormat.jpeg,
      );

      final tmp = await getTemporaryDirectory();
      final file = File('${tmp.path}/lumi_ootd_share.jpg');
      await file.writeAsBytes(compressed);

      if (!mounted) return;
      final shareOrigin = Rect.fromCenter(
        center: Offset(screenSize.width / 2, screenSize.height / 2),
        width: 1,
        height: 1,
      );
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        subject: '我的 Lumi 穿搭',
        sharePositionOrigin: shareOrigin,
      );

      if (!mounted) return;
      if (result.status == ShareResultStatus.success) {
        messenger.showSnackBar(
          SnackBar(
            content: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: LumiColors.onPrimary,
                  size: 18,
                ),
                SizedBox(width: LumiSpacing.xs),
                Text(
                  '穿搭已成功分享！',
                  style: TextStyle(
                    fontSize: LumiTypeScale.body,
                    fontWeight: FontWeight.w600,
                    color: LumiColors.onPrimary,
                  ),
                ),
              ],
            ),
            backgroundColor: LumiColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LumiRadii.pill),
            ),
            margin: const EdgeInsets.fromLTRB(
              LumiSpacing.xl,
              0,
              LumiSpacing.xl,
              LumiSpacing.xl,
            ),
            duration: const Duration(seconds: 2),
            elevation: 0,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('分享失敗：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;
    final keyboardUp = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: LumiColors.overlayDark,
      // Let Scaffold shrink body when keyboard appears — most reliable approach.
      // The photo card (Expanded) absorbs the height change; the input row
      // stays pinned directly above the keyboard at all times.
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Main column layout ─────────────────────────────────────────
          Column(
            children: [
              // Photo card — fills available space, shrinks when keyboard up
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(
                      key: _brandedCardKey,
                      child: _BrandedCard(
                        photoBytes: widget.photoBytes,
                        caption: _caption,
                        dateStr: _dateStr,
                      ),
                    ),
                    // Gradient scrim at card bottom (screen-only, not captured)
                    if (!keyboardUp)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                LumiColors.overlayDark.withValues(alpha: 0.0),
                                LumiColors.overlayDark.withValues(alpha: 0.92),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Caption input — always visible above keyboard
              ColoredBox(
                color: LumiColors.overlayDark,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    LumiSpacing.md,
                    LumiSpacing.sm,
                    LumiSpacing.md,
                    LumiSpacing.sm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: LumiColors.onPrimary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: LumiSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: _captionController,
                          style: const TextStyle(
                            fontSize: LumiTypeScale.body,
                            color: LumiColors.onPrimary,
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            hintText: '新增說明文字...',
                            hintStyle: TextStyle(
                              fontSize: LumiTypeScale.body,
                              color:
                                  LumiColors.onPrimary.withValues(alpha: 0.35),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          maxLines: 2,
                          minLines: 1,
                          onChanged: (v) => setState(() => _caption = v),
                          cursorColor: LumiColors.glow,
                        ),
                      ),
                      // Inline dismiss when keyboard is up
                      if (keyboardUp) ...[
                        const SizedBox(width: LumiSpacing.sm),
                        GestureDetector(
                          onTap: () => FocusScope.of(context).unfocus(),
                          child: const Text(
                            '完成',
                            style: TextStyle(
                              fontSize: LumiTypeScale.labelMd,
                              fontWeight: FontWeight.w600,
                              color: LumiColors.glow,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Action buttons — hidden while keyboard is up
              if (!keyboardUp)
                ColoredBox(
                  color: LumiColors.overlayDark,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      LumiSpacing.md,
                      LumiSpacing.xs,
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
                ),
            ],
          ),

          // ── Floating header overlay ────────────────────────────────────
          Positioned(
            top: topPad + LumiSpacing.xs,
            left: LumiSpacing.md,
            right: LumiSpacing.md,
            child: Row(
              children: [
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
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        LumiColors.text.withValues(alpha: 0.0),
                        LumiColors.text.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                ),
              ),
              // "Lumi" gradient chip — top-left (respects status bar)
              Positioned(
                top: MediaQuery.of(context).padding.top + LumiSpacing.sm,
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
              // Caption + date at bottom of photo
              Positioned(
                left: LumiSpacing.md,
                right: LumiSpacing.md,
                bottom: LumiSpacing.md,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (caption.isNotEmpty) ...[
                      Text(
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
                margin: const EdgeInsets.symmetric(horizontal: LumiSpacing.sm),
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
