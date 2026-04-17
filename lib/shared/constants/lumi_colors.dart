import 'package:flutter/material.dart';

/// Lumi 品牌色彩系統
/// 依據 DESIGN.md 定義，禁止在 Widget 中 hardcode 顏色值。
class LumiColors {
  LumiColors._();

  // ── Surfaces ──────────────────────────────────────────────────────────────
  static const base         = Color(0xFFFAF9F8); // Gallery Bone，所有頁面主背景
  static const baseAlt      = Color(0xFFF5F4F2); // 微暖灰，背景漸層用（Tonal Depth）
  static const surface      = Color(0xFFFFFFFF); // 純白，卡片 / Modal / Sheet 表面

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const primary      = Color(0xFFFF8C00); // primary_container，品牌主色
  static const primaryLight = Color(0xFFFD9E78); // secondary_container，品牌漸層淺端
  static const primaryFixed = Color(0xFFFFDCC3); // 底部導航 active icon 光暈

  // ── Button "Liquid Gold" gradient ─────────────────────────────────────────
  static const buttonStart  = Color(0xFF904D00); // 按鈕漸層起點
  static const buttonEnd    = Color(0xFF934A2A); // 按鈕漸層終點

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const glow         = Color(0xFFF5A870); // 暖橙光暈，AI 處理動畫
  static const text         = Color(0xFF1A1C1C); // on_surface，主要文字
  static const subtext      = Color(0xFF564334); // on_surface_variant，次要文字
  static const warning      = Color(0xFFE05528); // 深橘紅，高相似度警示（≥ 80%）

  // ── Gradients ─────────────────────────────────────────────────────────────
  /// 主按鈕漸層 — Liquid Gold（#904D00 → #934A2A）
  static const buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [buttonStart, buttonEnd],
  );

  /// 品牌漸層 — Golden Hour（#FF8C00 → #FD9E78）
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
}
