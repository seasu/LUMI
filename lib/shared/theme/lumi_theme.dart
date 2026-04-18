import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/lumi_colors.dart';

/// Single [ThemeData] for the whole app — tokens mirror [DESIGN.md]; widgets
/// should prefer `Theme.of(context).colorScheme` over ad-hoc [LumiColors] for
/// text/icons on surfaces so light/dark rules stay consistent.
ThemeData buildLumiTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: LumiColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: LumiColors.primary,
    onPrimary: LumiColors.onPrimary,
    secondary: LumiColors.primaryDark,
    onSecondary: LumiColors.onPrimary,
    tertiary: LumiColors.glow,
    surface: LumiColors.surface,
    onSurface: LumiColors.text,
    onSurfaceVariant: LumiColors.subtext,
    error: LumiColors.warning,
    onError: LumiColors.onPrimary,
    outline: LumiColors.subtext.withOpacity(0.35),
    surfaceContainerLowest: LumiColors.base,
    surfaceContainerLow: LumiColors.baseAlt,
    surfaceTint: Colors.transparent,
  );

  final baseText = GoogleFonts.notoSansTcTextTheme();

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: LumiColors.base,
    highlightColor: LumiColors.primaryFixed.withOpacity(0.35),
    splashColor: LumiColors.primaryFixed.withOpacity(0.45),
    textTheme: baseText.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: LumiColors.base,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: baseText.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: scheme.surface.withOpacity(0.92),
      selectedItemColor: scheme.primary,
      unselectedItemColor: scheme.onSurfaceVariant,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: scheme.error,
      contentTextStyle: baseText.bodyMedium?.copyWith(color: scheme.onError),
      behavior: SnackBarBehavior.floating,
    ),
    dialogBackgroundColor: scheme.surface,
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
