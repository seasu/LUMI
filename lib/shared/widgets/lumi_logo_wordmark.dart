import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/lumi_colors.dart';

/// Shared Lumi wordmark to keep Welcome/Loading branding consistent.
///
/// The intrinsic design envelope is derived from [fontSize]. Wrapped in
/// [FittedBox] so when the parent is narrower, the wordmark scales down as a
/// unit. **Screen-edge breathing room should be applied by the parent**
/// (`Padding` / `SafeArea` / symmetrical horizontal insets — see `LumiSpacing`),
/// not inside this widget.
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
  /// Logical envelope for glyph + sparkle (keep sparkle math in sync with these).
  static const double _widthFactor = 4.1;
  static const double _heightFactor = 1.58;

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
    final fs = widget.fontSize;
    final boxW = fs * _widthFactor;
    final boxH = fs * _heightFactor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        return SizedBox(
          width: layoutW,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.center,
            child: SizedBox(
              width: boxW,
              height: boxH,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Text(
                    'Lumi',
                    style: GoogleFonts.dancingScript(
                      fontSize: fs,
                      fontWeight: FontWeight.w600,
                      color: LumiColors.text,
                      height: 1.0,
                    ),
                  ),
                  Positioned(
                    top: fs * 0.30,
                    right: fs * 0.52,
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
                                LumiColors.surface.withOpacity(0.95),
                                LumiColors.glow.withOpacity(0.92),
                                LumiColors.primaryLight
                                    .withOpacity(0.65 + g * 0.25),
                                LumiColors.primary
                                    .withOpacity(0.22 + g * 0.2),
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
            ),
          ),
        );
      },
    );
  }
}
