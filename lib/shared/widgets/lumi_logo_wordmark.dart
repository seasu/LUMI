import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/lumi_colors.dart';

/// Shared Lumi wordmark to keep Welcome/Loading branding consistent.
class LumiLogoWordmark extends StatefulWidget {
  const LumiLogoWordmark({
    super.key,
    this.fontSize = 56,
  });

  final double fontSize;

  @override
  State<LumiLogoWordmark> createState() => _LumiLogoWordmarkState();
}

class _LumiLogoWordmarkState extends State<LumiLogoWordmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sparkleController;
  late final Animation<double> _sparkleSizeAnimation;
  late final Animation<double> _sparkleGlowAnimation;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _sparkleSizeAnimation = TweenSequence<double>([
      // 快閃：快速放大再收回
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.25).chain(
          CurveTween(curve: Curves.easeInCubic),
        ),
        weight: 15,
      ),
      // 慢呼吸：長時間柔和起伏
      TweenSequenceItem(
        tween: Tween(begin: 0.25, end: 0.75).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.75, end: 0.35).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 35,
      ),
    ]).animate(_sparkleController);
    _sparkleGlowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.35), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.35, end: 0.72), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.72, end: 0.4), weight: 35),
    ]).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.fontSize * 4.1,
      height: widget.fontSize * 1.58,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Text(
            'Lumi',
            style: GoogleFonts.dancingScript(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w600,
              color: LumiColors.text,
              height: 1.0,
            ),
          ),
          // i 上方閃爍橘光（依字體大小動態定位）
          Positioned(
            top: widget.fontSize * 0.30,
            right: widget.fontSize * 0.52,
            child: AnimatedBuilder(
              animation: _sparkleController,
              builder: (_, __) {
                final t = _sparkleSizeAnimation.value;
                final g = _sparkleGlowAnimation.value;
                return Container(
                  width: 18 + (t * 8),
                  height: 18 + (t * 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.95),
                        LumiColors.glow.withOpacity(0.92),
                        LumiColors.primaryLight.withOpacity(0.65 + g * 0.25),
                        LumiColors.primary.withOpacity(0.22 + g * 0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.22, 0.5, 0.72, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
