import 'package:flutter/material.dart';

/// Lumi 品牌色彩 — 數值與 [DESIGN.md] §2、§5 一致；禁止在 Widget 中 hardcode 顏色值。
/// 全 App 與 `lumi_theme.dart` 的 [buildLumiTheme] 一併使用；具 `context` 的材質元件優先讀 [Theme]。
class LumiColors {
  LumiColors._();

  // --- Neutrals (DESIGN.md §2) ---
  /// Background — Gallery Bone (`#faf9f8`). App scaffold / tonal base.
  static const base = Color(0xFFFAF9F8);

  /// Subtle layer for gradients between bone and white (approx. surface step).
  static const baseAlt = Color(0xFFF5F3F1);

  /// `surface_container_lowest` — cards, sheets, modals.
  static const surface = Color(0xFFFFFFFF);

  /// Text / icons on primary-colored surfaces (must match [ColorScheme.onPrimary] in theme).
  static const onPrimary = Color(0xFFFFFFFF);

  /// `on_surface` — headlines & primary UI text.
  static const text = Color(0xFF1A1C1C);

  /// `on_surface_variant` — secondary / supporting text.
  static const subtext = Color(0xFF564334);

  // --- Brand & CTA (DESIGN.md §5 Primary capsule: primary → secondary) ---
  /// Primary anchor (`#904d00`) — CTA gradient start, key emphasis.
  static const primary = Color(0xFF904D00);

  /// Gradient end / rust companion (`#934a2a`).
  static const primaryDark = Color(0xFF934A2A);

  /// Golden-hour highlight (`#ff8c00`) — primary_container; glows, warm accents.
  static const primaryLight = Color(0xFFFF8C00);

  /// Soft peach (`#fd9e78`) — secondary_container; AI orb / soft highlights.
  static const glow = Color(0xFFFD9E78);

  /// Nav “primary_fixed” glow (#ffdcc3) — active icon halo, subtle fills.
  static const primaryFixed = Color(0xFFFFDCC3);

  /// Duplicate / high-similarity emphasis — warm orange-red (not pure red).
  static const warning = Color(0xFFC2410C);

  /// Modal / bottom-sheet barrier — warm scrim from `on_surface`, not pure black.
  static const overlayBarrier = Color(0x801A1C1C);

  /// Fullscreen dark chrome (e.g. camera preview) — near-black warm tone.
  static const overlayDark = Color(0xDD1A1C1C);

  /// Primary capsule gradient (“Liquid Gold”).
  static const buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
}
