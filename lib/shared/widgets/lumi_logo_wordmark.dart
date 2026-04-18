import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Lumi wordmark as a single SVG (script + sparkle) for consistent lockup
/// across Welcome and Loading. Update [assets/branding/lumi_wordmark.svg] from
/// Figma/Illustrator for a perfect match; [fontSize] controls overall height.
class LumiLogoWordmark extends StatelessWidget {
  const LumiLogoWordmark({
    super.key,
    this.fontSize = 56,
  });

  final double fontSize;

  /// viewBox 260×72 in [lumi_wordmark.svg]
  static const double _viewBoxW = 260;
  static const double _viewBoxH = 72;

  @override
  Widget build(BuildContext context) {
    // `fontSize` is the effective cap height; viewBox is 260×72.
    final boxH = fontSize;
    final boxW = fontSize * (_viewBoxW / _viewBoxH);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        return Semantics(
          label: 'Lumi',
          child: SizedBox(
            width: maxW,
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/branding/lumi_wordmark.svg',
                width: boxW,
                height: boxH,
                alignment: Alignment.center,
              ),
            ),
          ),
        );
      },
    );
  }
}
