import 'package:flutter/material.dart';

/// Lumi 品牌色彩系統
/// 依據 DESIGN.md 定義，禁止在 Widget 中 hardcode 顏色值。
class LumiColors {
  LumiColors._();

  static const base         = Color(0xFFFAF4EE); // 暖奶油米，所有頁面主背景
  static const baseAlt      = Color(0xFFFAF9F8); // Gallery Bone，柔和背景層次
  static const surface      = Color(0xFFFFFFFF); // 純白，卡片 / Modal / Sheet 表面
  static const primary      = Color(0xFFF08630); // 暖橘，主要 CTA 按鈕／強調色／選中狀態
  static const primaryLight = Color(0xFFF5A855); // 橘漸層-淺端（按鈕漸層起點）
  static const primaryDark  = Color(0xFFE06820); // 橘漸層-深端（按鈕漸層終點）
  static const glow         = Color(0xFFF5A870); // 暖橙光暈，AI 處理動畫 / Loading Orb
  static const text         = Color(0xFF1C1007); // 深暖棕，頁面標題／主要文字
  static const subtext      = Color(0xFF7A6858); // 暖灰棕，說明文字／次要資訊
  static const warning      = Color(0xFFE05528); // 深橘紅，似曾相識高相似度警示（≥ 80%）

  /// 主按鈕漸層（primaryLight → primaryDark）
  static const buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primaryDark],
  );
}
