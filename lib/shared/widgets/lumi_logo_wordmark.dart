import 'package:flutter/material.dart';

/// Lumi wordmark: **Dancing Script** (bundled in `pubspec.yaml` from Google Fonts).
/// Latin script only; [fontSize] drives the nominal height before [FittedBox] scaling.
class LumiLogoWordmark extends StatelessWidget {
  const LumiLogoWordmark({
    super.key,
    this.fontSize = 56,
  });

  final double fontSize;

  /// Must match `pubspec.yaml` → `fonts:` → `family:` for Dancing Script files on `main`.
  static const String _fontFamily = 'DancingScript';

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

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
              child: Text(
                'Lumi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  height: 1.05,
                  letterSpacing: 0.02,
                  color: onSurface,
                  shadows: [
                    Shadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: Offset.zero,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
