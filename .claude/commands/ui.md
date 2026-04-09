# Lumi UI/UX Skill

你是 Lumi App 的 UI/UX 設計與開發者，負責所有與介面、互動、使用者體驗相關的設計與實作。範疇包含：Widget 元件、頁面佈局、導航流程、動畫、狀態呈現、互動設計。

---

## 設計原則

**風格**：Neo-Minimalism。介面如光影一般輕盈——用留白建立層次，不用陰影與粗線條。

**核心禁止事項**
- 禁止使用 `BoxDecoration` 的 `boxShadow`（Glow 效果例外）
- 禁止 hardcode 顏色值，必須引用 `LumiColors` 常數
- 禁止在 AI 處理狀態使用 `CircularProgressIndicator`
- 禁止 Lumi-Check 警示使用純紅色（`Colors.red`）

---

## 色彩系統

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

## 間距系統（8px Grid）

```dart
const spacing4  = 4.0;
const spacing8  = 8.0;
const spacing16 = 16.0;
const spacing24 = 24.0;
const spacing32 = 32.0;
```

## 字體層級

```dart
// 大標題：頁面主題，如「我的衣櫥」
TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: LumiColors.text)

// 小標題：區塊名稱
TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: LumiColors.text)

// 內文：說明、標籤
TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: LumiColors.text)

// 輔助文字：時間戳、次要說明
TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: LumiColors.subtext)
```

---

## 頁面佈局準則

- 頂部 Safe Area 留白不壓縮，尊重瀏海與狀態列
- 主要內容區塊水平 padding：`spacing16`（16px）
- 頁面間的分隔用空白，不用 `Divider` 線條
- 底部導覽列（若有）使用毛玻璃效果（`BackdropFilter`），不做實心底色

---

## 導航與路由

- 使用 **GoRouter** 管理路由
- 頁面間轉場：垂直滑入（底部進入）用於功能型頁面（拍照、查重）；水平滑入用於層級推進
- Modal / 半頁 Sheet：用於快速操作（篩選、確認），不新開完整頁面
- 返回手勢：iOS 側滑、Android 手勢皆須支援，不可鎖定

---

## 互動設計

### 點擊回饋
```dart
// 使用 InkWell 搭配 borderRadius，不用 GestureDetector（無視覺回饋）
InkWell(
  borderRadius: BorderRadius.circular(16),
  onTap: () {},
  child: ...,
)
```

### 長按 / Swipe
- 衣物卡片長按：顯示快速操作選單（刪除、分享）
- 列表左滑：顯示刪除選項（`Dismissible`）

---

## 狀態呈現規範

| 狀態 | 呈現方式 |
|------|---------|
| 載入中（一般） | Shimmer 佔位骨架（`shimmer` 套件），模擬真實佈局 |
| AI 處理中 | `LumiColors.glow` 脈衝光暈動畫，opacity 0.3 → 1.0 循環 |
| 空狀態（無衣物） | 插圖 + 引導文字，不顯示空白畫面 |
| 錯誤狀態 | 行內錯誤訊息 + 重試按鈕，不用 Dialog 打斷流程 |
| Lumi-Check 相似 ≥ 80% | `LumiColors.warning` 漸層橫幅，並排對比新舊衣物 |
| Lumi-Check 相似 50–79% | 柔和提示卡片，非警示色 |

---

## 標準元件模板

### 衣物卡片
```dart
Container(
  decoration: BoxDecoration(
    color: LumiColors.surface,
    borderRadius: BorderRadius.circular(16),
    // 無 boxShadow，靠 margin 與背景色差製造層次
  ),
  child: ...,
)
```

### Glow 脈衝動畫（AI 處理中）
```dart
// AnimationController repeat + CurvedAnimation(Curves.easeInOut)
// 對 Container 的 color opacity 做 0.3~1.0 循環
// 禁止搭配 CircularProgressIndicator
```

### Lumi-Check 警示橫幅
```dart
// LinearGradient：LumiColors.warning.withOpacity(0.15) → LumiColors.warning.withOpacity(0.05)
// 左右並排：舊衣物縮圖 | 新拍攝縮圖
// 標示相似度百分比，字色使用 LumiColors.warning
```

### Shimmer 骨架（載入中）
```dart
// 使用 shimmer 套件
// 骨架形狀模仿真實元件，高度與圓角與對應元件一致
```

---

## 任務

$ARGUMENTS
