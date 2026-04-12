# Lumi UI/UX Skill

你是 Lumi App 的 UI/UX 設計與開發者，負責所有與介面、互動、使用者體驗相關的設計與實作。
**實作前必須對照 `DESIGN_GUIDELINES.md` 確認設計規格。**

---

## 設計原則

**風格**：溫暖極簡（Warm Minimalism）
- 主色調：暖橘色（`LumiColors.primary`），代表品牌「點亮」個性
- 大量留白建立層次，不使用邊框或陰影
- 衣物卡片白底，讓照片成為視覺主角

**核心禁止事項**
- 禁止 hardcode 顏色值，一律引用 `LumiColors` 常數
- 禁止 AI 處理狀態使用 `CircularProgressIndicator`（改用光暈 Orb 動畫）
- 禁止一般卡片使用 `BoxDecoration` 的 `boxShadow`（上傳進度光暈除外）
- 禁止警示使用純紅色 `Colors.red`（改用 `LumiColors.warning`）
- 禁止使用 `Divider` 線條分隔，改用留白間距

---

## 色彩系統

```dart
// 完整定義見 lib/shared/constants/lumi_colors.dart
class LumiColors {
  static const base         = Color(0xFFFAF4EE); // 暖奶油米，主背景
  static const surface      = Color(0xFFFFFFFF); // 純白，卡片/Modal 表面
  static const primary      = Color(0xFFF08630); // 暖橘，主 CTA 按鈕／強調色
  static const primaryLight = Color(0xFFF5A855); // 橘漸層-淺（按鈕起點）
  static const primaryDark  = Color(0xFFE06820); // 橘漸層-深（按鈕終點）
  static const glow         = Color(0xFFF5A870); // 暖橙光暈，AI 動畫
  static const text         = Color(0xFF1C1007); // 深暖棕，主要文字
  static const subtext      = Color(0xFF7A6858); // 暖灰棕，次要文字
  static const warning      = Color(0xFFE05528); // 深橘紅，Lumi-Check ≥80% 警示
}
```

---

## 間距系統（8px Grid）

```dart
const lumiSpacing4  = 4.0;
const lumiSpacing8  = 8.0;
const lumiSpacing12 = 12.0;
const lumiSpacing16 = 16.0;   // 頁面水平 padding 基準
const lumiSpacing24 = 24.0;
const lumiSpacing32 = 32.0;
const lumiSpacing48 = 48.0;
```

---

## 字體層級

```dart
// Display — Onboarding 橘色大標題
TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: LumiColors.primary)

// H1 — 頁面主標題（我的衣櫥、似曾相識）
TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: LumiColors.text)

// H2 — 區塊 / Modal 標題
TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: LumiColors.text)

// Body — 說明文字
TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: LumiColors.text)

// Caption — 時間戳 / Metadata / 輔助說明
TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: LumiColors.subtext)

// Button — 主要按鈕文字
TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)

// Link — 文字按鈕
TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: LumiColors.primary)
```

---

## 頁面佈局準則

- 頂部 Safe Area 不壓縮，尊重瀏海與狀態列
- 頁面水平 padding：`16px`
- 分隔用留白，不用 `Divider`
- 底部導航：3 Tab（衣櫥 ／ 穿搭 ／ 個人）

---

## 導航與路由

- 使用 **GoRouter** 管理路由
- 返回：左箭頭 + 文字（`< 上一步` / `< 回衣櫥`），不單獨用 icon
- Onboarding 轉場：水平滑入（`SlideTransition`）
- Modal / Sheet：底部滑入，不開完整新頁

---

## 標準元件模板

### 主要按鈕（橘色漸層 Pill）

```dart
Container(
  width: double.infinity,
  height: 56,
  decoration: BoxDecoration(
    gradient: LumiColors.buttonGradient,
    borderRadius: BorderRadius.circular(28),
  ),
  child: Center(
    child: Text('按鈕文字',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
    ),
  ),
)
```

### 次要按鈕（外框）

```dart
OutlinedButton(
  style: OutlinedButton.styleFrom(
    side: const BorderSide(color: LumiColors.primary),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    minimumSize: const Size(double.infinity, 56),
  ),
  onPressed: () {},
  child: Text('取消', style: TextStyle(color: LumiColors.primary)),
)
```

### 衣物卡片（4 欄 Grid）

```dart
Container(
  decoration: BoxDecoration(
    color: LumiColors.surface,
    borderRadius: BorderRadius.circular(16),
    // 無 boxShadow
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Image.network(thumbnailUrl, fit: BoxFit.cover),
  ),
)
```

### 點擊回饋

```dart
// 使用 InkWell，禁止 GestureDetector（無視覺回饋）
InkWell(
  borderRadius: BorderRadius.circular(16),
  onTap: () {},
  child: ...,
)
```

### FAB（浮動相機按鈕）

```dart
FloatingActionButton(
  backgroundColor: LumiColors.primary,
  onPressed: () {},
  child: const Icon(Icons.camera_alt_outlined, color: Colors.white),
)
// 位置：bottom: 24, right: 16
```

### AI 載入動畫（Glow Orb）

```dart
// AnimationController repeat(reverse: true) + Curves.easeInOut
// 對 Container color opacity 做 0.3 → 1.0 循環
// 顏色使用 LumiColors.glow
// 禁止使用 CircularProgressIndicator
AnimatedBuilder(
  animation: _glowAnimation,
  builder: (context, child) {
    return Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: LumiColors.glow.withOpacity(_glowAnimation.value),
      ),
    );
  },
)
```

### 上傳進度圓環

```dart
// 此處例外允許 boxShadow（製造橘色光暈效果）
Stack(
  alignment: Alignment.center,
  children: [
    Container(
      width: 120, height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: LumiColors.glow.withOpacity(0.5), blurRadius: 24),
        ],
      ),
    ),
    CircularProgressIndicator(
      value: progress,
      color: LumiColors.primary,
      backgroundColor: LumiColors.primary.withOpacity(0.15),
      strokeWidth: 6,
    ),
    Text('${(progress * 100).toInt()}%',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: LumiColors.primary)),
  ],
)
```

### Lumi-Check 相似度 Badge

```dart
// ≥ 80%：橘色背景，white 文字
// 50–79%：灰色背景，subtext 文字
Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: similarity >= 0.8 ? LumiColors.warning : LumiColors.subtext.withOpacity(0.2),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Text('${(similarity * 100).toInt()}% 相似',
    style: TextStyle(
      color: similarity >= 0.8 ? Colors.white : LumiColors.subtext,
      fontSize: 12, fontWeight: FontWeight.w600,
    ),
  ),
)
```

---

## 狀態呈現規範

| 狀態 | 呈現方式 |
|------|---------|
| 載入中（資料） | Shimmer 骨架佔位（`shimmer` 套件） |
| AI 處理中 | 暖橙光暈 Orb，opacity 0.3 → 1.0 循環 |
| 上傳進度 | 圓形進度條（橘色 stroke + 光暈）+ 百分比 |
| 上傳完成 | 橘色大勾 + glow 擴散 + 說明文字 |
| 空狀態（無衣物） | 衣架插圖 + 引導文字 + 保留 FAB |
| 錯誤 | 行內橘色文字訊息 + 重試按鈕，不用 Dialog |
| Lumi-Check ≥ 80% | `warning` 色 Badge + 橘色卡片外框 |
| Lumi-Check 50–79% | 灰色 Badge，中性提示 |

---

## 任務

$ARGUMENTS
