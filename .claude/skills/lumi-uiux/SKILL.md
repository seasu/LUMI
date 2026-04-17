---
name: lumi-uiux
description: "Lumi App 專屬 Flutter UI/UX 設計 Skill。當使用者要求建立或修改任何 Flutter 畫面、Widget、佈局、導航、動畫、狀態呈現、互動設計時，自動觸發此 Skill。也在使用者提到「衣櫥」「卡片」「篩選」「Lumi-Check」「snap」「拍照」「上傳」「空狀態」「底部導航」「漸層按鈕」「AI 掃描」「光暈」「shimmer」或任何 Lumi 介面相關關鍵字時觸發。此 Skill 以 DESIGN.md（The Digital Atelier）為唯一設計來源，搭配 LumiColors / LumiSpacing / LumiRadii / LumiTypeScale 四組 token 常數。"
---

# Lumi UI/UX Designer — The Digital Atelier

你是 Lumi App 的 UI/UX 設計與開發專家，所有介面實作必須遵循本文件與 `DESIGN.md`。

---

## Design Philosophy: The Curated Canvas

Lumi 將使用者的衣櫥視為一座高端編輯策展空間。美學驅動力來自 **Scandinavian Minimalism**（功能與光）與 **Quiet Luxury**（質感與克制）。

### 1. Intentional Asymmetry
- 交錯式卡片佈局模擬實體 mood board
- 允許不對稱邊距（如左 24px、右 16px），營造雜誌感

### 2. Breathing Room
- 激進留白：衣物照片是唯一主角
- 分隔用留白，**禁止 `Divider` 線條**
- 區塊間距至少 `LumiSpacing.lg`（24px）

### 3. Tonal Depth
- 以柔和色調變化取代硬結構線
- 用背景色階差異（`base` vs `surface` vs `baseAlt`）製造層次，不用邊框

---

## Color System

所有顏色必須引用 `LumiColors` 常數，禁止 hardcode 色值。

```dart
// lib/shared/constants/lumi_colors.dart
class LumiColors {
  static const base         = Color(0xFFFAF4EE); // 暖奶油米，所有頁面主背景
  static const baseAlt      = Color(0xFFFAF9F8); // Gallery Bone，柔和背景層次
  static const surface      = Color(0xFFFFFFFF); // 純白，卡片 / Modal / Sheet 表面
  static const primary      = Color(0xFFF08630); // 暖橘，主要 CTA / 強調色
  static const primaryLight = Color(0xFFF5A855); // 橘漸層-淺端
  static const primaryDark  = Color(0xFFE06820); // 橘漸層-深端
  static const glow         = Color(0xFFF5A870); // 暖橙光暈，AI 動畫
  static const text         = Color(0xFF1C1007); // 深暖棕，主要文字
  static const subtext      = Color(0xFF7A6858); // 暖灰棕，次要文字
  static const warning      = Color(0xFFE05528); // 深橘紅，高相似度警示

  static const buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primaryDark],
  );
}
```

### The "No-Line" Rule
**禁止用邊框分隔區塊。** 改用背景色階差異：
- `surface_container_lowest`（純白）卡片 → 放在 `base`（暖米色）背景上
- 色調差就是邊界

### The "Ghost Border" Fallback
若容器必須在相似背景上定義邊緣，使用 `LumiColors.subtext` 15% opacity 的邊框——應該「被感覺到，而非被看到」。

---

## Typography

全域字體為 **Noto Sans TC**（繁體中文最佳可讀性）。
品牌 Wordmark 使用 **Dancing Script**（替代 Great Vibes）。

```dart
// lib/shared/constants/lumi_type_scale.dart
abstract class LumiTypeScale {
  static const double displayLg  = 52;   // 零狀態大標題
  static const double headlineMd = 28;   // 頁面標題（我的衣櫥）
  static const double titleLg    = 20;   // 區塊 / Modal 標題
  static const double titleSm    = 16;   // 列表項目標題
  static const double body       = 15;   // 內文、按鈕
  static const double labelMd    = 13;   // 說明文字、Tab 標籤
  static const double labelSm    = 11;   // 小型 Chip、Badge
}
```

### Font Weight 規則
- 頁面標題：`w800`（Extra Bold）
- 區塊標題 / 按鈕：`w600`（Semi Bold）
- 內文：`w400`（Regular）
- 禁止使用 `w100`–`w300`（過細，行動裝置不易閱讀）

---

## Spacing & Radii

```dart
// lib/shared/constants/lumi_spacing.dart
abstract class LumiSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;   // 頁面水平 padding 基準
  static const double lg = 24.0;
  static const double xl = 32.0;
}

// lib/shared/constants/lumi_radii.dart
abstract class LumiRadii {
  static const double sm   = 8;     // Chip、小控件
  static const double md   = 12;    // 縮圖、小卡片
  static const double lg   = 16;    // 衣物卡片
  static const double xl   = 24;    // Sheet、大卡片、底部導航
  static const double pill = 9999;  // Capsule 按鈕
}
```

---

## Elevation & Depth: Tonal Layering

不使用傳統陰影。改用 **Tonal Layering** + **Ambient Shadows**。

- **Layering 原則**：要突顯卡片，將 `surface`（白）卡片放在 `base`（暖米）背景上
- **Ambient Shadow**：浮動元素（FAB、Nav）使用 `blur: 32, spread: 0, opacity: 0.04`，shadow 色必須用 `LumiColors.text`，禁止純黑
- **Ghost Border**：`LumiColors.subtext` at 15% opacity

---

## Component Patterns

### Buttons: The Capsule Aesthetic
- 形狀一律 `pill`（`BorderRadius.circular(LumiRadii.pill)`）
- 主按鈕：`buttonGradient` 漸層，白色文字
- 次要按鈕：透明背景 + Ghost Border + `text` 色文字
- 互動回饋：按壓時 `scale: 0.96`

### Wardrobe Cards
- **禁止 Divider**：用 `LumiSpacing.md`（16px）間距分隔
- 圓角 `LumiRadii.lg`（16px），或依設計稿用 20px
- 圖片填滿容器寬度
- 卡片下方：材質名稱 + 分類代碼，右側愛心 icon
- 禁止 `boxShadow`（上傳光暈除外）

### Bottom Navigation
- Glassmorphic：`surface` at 92% opacity
- 3 Tab：我的衣櫥 / 我的穿搭 / 個人檔案
- Active 使用 `text` 色，inactive 使用 `subtext` 色
- 無 elevation

### Filter Bar
- 水平可捲動分類 Tab：active 用 `primary` 色底線 underline
- 顏色篩選：圓形 chip 實心填色，active 加白色外框 2px

### FAB（似曾相識入口）
- 右下角定位（`bottom: 24, right: 16`）
- 56x56 圓形，`buttonGradient` 漸層背景
- 白色「似」字或 search icon

---

## State Presentations

| 狀態 | 呈現方式 | 禁止 |
|------|---------|------|
| 資料載入中 | Shimmer 骨架佔位 | `CircularProgressIndicator` |
| AI 處理中 | Glow Orb（`glow` 色，opacity 0.3→1.0 循環） | Spinner |
| 上傳進度 | 圓形進度條 + 橘光暈 + 百分比 | 線性進度條 |
| 上傳完成 | 橘色大勾 + glow 擴散 | Dialog |
| 空狀態 | 衣架 icon + 引導文字 + 置中 | 空白頁 |
| 錯誤 | 行內橘色文字 + 重試按鈕 | Alert Dialog |
| Lumi-Check ≥80% | `warning` 色 Badge + 橘色卡片外框 | 全頁警告 |
| Lumi-Check 50–79% | 灰色 Badge + 中性提示 | — |

---

## Page Layout Guidelines

- Safe Area：不壓縮，尊重瀏海與狀態列
- 頁面水平 padding：`16px`（`LumiSpacing.md`）
- Header：標題左對齊（`w800`），右側放 TextButton（加入新品）
- 背景色一律 `LumiColors.base`
- 卡片表面一律 `LumiColors.surface`

---

## Navigation

- 使用 **GoRouter** + **ShellRoute**
- 返回按鈕：左箭頭 + 文字（如「< 回衣櫥」），不單獨用 icon
- Modal / Sheet：底部滑入，不開新頁
- Onboarding 轉場：水平滑入（`SlideTransition`）

---

## Do's and Don'ts

### Do:
- **Do** 使用不對稱邊距營造雜誌感
- **Do** 讓衣物照片成為畫面主角（佔 70%+ 區域）
- **Do** 用 `surface_bright` / `baseAlt` 標記「新入庫」通知
- **Do** 使用 `const` constructor
- **Do** 禁止 magic number，一律用 token 常數

### Don't:
- **Don't** 使用 1px solid divider，用留白
- **Don't** 使用純黑 `#000000`，用 `LumiColors.text`
- **Don't** 使用 90 度直角，最小 `LumiRadii.sm`（8px）
- **Don't** 使用 `CircularProgressIndicator`，用 Glow Orb
- **Don't** 使用 `boxShadow`（上傳光暈例外）
- **Don't** 使用 `Colors.red`，用 `LumiColors.warning`
- **Don't** 使用 `GestureDetector`（無視覺回饋），用 `InkWell`

---

## Screen-by-Screen Checklist

建立或修改任何畫面時，逐項驗證：

- [ ] 全部使用 `LumiColors` / `LumiSpacing` / `LumiRadii` / `LumiTypeScale`，無 magic number
- [ ] 有 loading state（shimmer skeleton，非 spinner）
- [ ] 有 empty state（icon + 引導文字 + CTA）
- [ ] 有 error state（行內訊息 + 重試按鈕）
- [ ] 響應式佈局（`MediaQuery` 或 `LayoutBuilder`）
- [ ] 底部 safe area padding
- [ ] 鍵盤感知（輸入框捲入視野）
- [ ] 無 hardcode 顏色、無純黑、無直角、無邊框分隔
- [ ] 動畫 60fps（避免在動畫中重建整棵 Widget tree）
- [ ] 無障礙：圖片有 semantic label，對比度足夠

---

## How to Use This Skill

1. **釐清畫面/功能** — 確認要建什麼（衣櫥列表？篩選？Lumi-Check？）
2. **先設計再實作** — 描述佈局、色彩、互動，確認後再寫 code
3. **用 token 系統** — 一律使用 `LumiColors`、`LumiTypeScale`、`LumiSpacing`、`LumiRadii`
4. **包含狀態處理** — 每個畫面至少有 loading / empty / error 三態
5. **完整檔案** — 提供可執行的完整 Dart 檔案，不留 `// TODO`
6. **建議下一步** — 自然銜接的下一個畫面或元件

元件實作範本：見 `references/components.md`
動畫食譜：見 `references/animations.md`
