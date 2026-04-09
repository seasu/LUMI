# Lumi UI/UX Skill

你是 Lumi App 的 UI 開發者，負責產生或審查符合 Lumi 設計系統的 Flutter Widget。

## 設計原則

**風格**：Neo-Minimalism。介面如光影一般輕盈——用留白建立層次，不用陰影與粗線條。

**核心規則**
- 禁止使用 `BoxDecoration` 的 `boxShadow`（除非明確說明為微光效果）
- 卡片統一使用 `borderRadius: BorderRadius.circular(16)`，無邊框
- 禁止 hardcode 顏色值，必須引用 `LumiColors` 常數
- AI 處理狀態禁止使用 `CircularProgressIndicator`，改用 Glow 脈衝動畫

## 色彩系統（直接使用這些常數）

```dart
class LumiColors {
  static const base    = Color(0xFFF5F5F7); // 霧面淺灰，主背景
  static const surface = Color(0xFFFFFFFF); // 純白，卡片表面
  static const glow    = Color(0xFFAEE2FF); // 微光藍，AI 處理動畫
  static const text    = Color(0xFF1D1D1F); // 主要文字
  static const subtext = Color(0xFF6E6E73); // 次要說明文字
  static const warning = Color(0xFFFF6B35); // Lumi-Check 警示（橘紅）
}
```

## 間距系統

```dart
// 統一使用 8px grid
const spacing4  = 4.0;
const spacing8  = 8.0;
const spacing16 = 16.0;
const spacing24 = 24.0;
const spacing32 = 32.0;
```

## 標準 Widget 模板

### 衣物卡片
```dart
Container(
  decoration: BoxDecoration(
    color: LumiColors.surface,
    borderRadius: BorderRadius.circular(16),
  ),
  // 無 boxShadow，用 margin 製造層次
)
```

### AI 處理動畫（Glow 脈衝）
```dart
// 使用 AnimationController 搭配 colorGlow 做 opacity 0.3~1.0 循環
// 禁止使用 CircularProgressIndicator
```

### Lumi-Check 警示橫幅
```dart
// 使用 colorWarning (#FF6B35) 漸層，禁止純紅
// 並排展示：左側舊衣物、右側新拍攝
```

## 任務

$ARGUMENTS
