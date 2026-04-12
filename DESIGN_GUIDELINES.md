# Lumi Design Guidelines

> 本文件依據 `stitch_lumi_mockup/` 目錄的 Stitch Mockup 製作，作為所有 UI 開發的唯一設計標準。
> 程式碼實作必須對照本文件，顏色值一律從 `LumiColors` 引用，禁止 hardcode。

---

## 設計語言

**風格**：溫暖極簡（Warm Minimalism）
- 大量留白建立視覺層次，不依賴邊框或陰影
- 主色調為暖橘色，代表「點亮」的品牌個性
- 卡片以純白呈現，讓衣物照片成為視覺主角
- 圓角設計貫穿全站，柔和而不銳利

---

## 色彩系統

### 品牌色板

| 常數 | Hex | 用途 |
|------|-----|------|
| `LumiColors.base` | `#FAF4EE` | 暖奶油米，所有頁面主背景 |
| `LumiColors.surface` | `#FFFFFF` | 純白，卡片 / Modal / 底部 Sheet 表面 |
| `LumiColors.primary` | `#F08630` | 暖橘，主要 CTA 按鈕、強調色、選中狀態 |
| `LumiColors.primaryLight` | `#F5A855` | 橘漸層-淺端（按鈕漸層起點） |
| `LumiColors.primaryDark` | `#E06820` | 橘漸層-深端（按鈕漸層終點） |
| `LumiColors.glow` | `#F5A870` | 暖橙光暈，AI 處理動畫、Loading Orb |
| `LumiColors.text` | `#1C1007` | 深暖棕，頁面標題 / 主要文字 |
| `LumiColors.subtext` | `#7A6858` | 暖灰棕，說明文字 / 次要資訊 |
| `LumiColors.warning` | `#E05528` | 深橘紅，Lumi-Check 高相似度警示（≥ 80%） |

### 主按鈕漸層

```dart
const lumiButtonGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [LumiColors.primaryLight, LumiColors.primaryDark],
);
```

### 使用原則

- 禁止 hardcode 顏色值，一律使用 `LumiColors` 常數
- `primary`（橘色）僅用於主要動作；次要動作用文字按鈕或外框按鈕
- `warning` 僅在 Lumi-Check 相似度 ≥ 80% 時使用，不作為一般錯誤色
- 一般錯誤訊息用 `text` 色搭配紅色 icon，不用純紅 `Colors.red`

---

## 字體系統

### 字體分級

| 層級 | 大小 | 粗細 | 顏色 | 用途 |
|------|------|------|------|------|
| Display | 32px | w700 | `primary` | Onboarding 主標題（橘色大字） |
| H1 | 28px | w700 | `text` | 頁面主標題（我的衣櫥、似曾相識） |
| H2 | 20px | w600 | `text` | 區塊標題、Modal 標題 |
| Body | 15px | w400 | `text` | 內文、說明文字 |
| Caption | 13px | w400 | `subtext` | 輔助說明、時間戳、Metadata |
| Button | 16px | w600 | `#FFFFFF` | 主要按鈕文字 |
| Link | 15px | w400 | `primary` | 文字按鈕（取消、下一步文字版） |

### Logo 字型

Lumi Logo 使用英文手寫草書（Script）字型，搭配右上角橘橙色星光 sparkle icon。
- 深暖棕色 `#3A2010` 字色
- sparkle 為 `#F5A870`（暖橘光暈）

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

- 頁面水平 padding：`16px`
- 卡片內部 padding：`12–16px`
- 元件間垂直間距：`8px` 的倍數

---

## 圓角系統

| 元素 | borderRadius |
|------|-------------|
| 主要按鈕（Pill） | `28px`（全圓角） |
| 衣物卡片 | `16px` |
| Modal / Bottom Sheet 頂部 | `24px` |
| 分類 Tab 選中底線 | 無圓角，2px 線條 |
| 標籤 Badge / Chip | `20px` |
| Dialog | `20px` |
| 圖片縮圖 | `12px` |

---

## 元件規範

### 主要按鈕（Primary Button）

```dart
Container(
  width: double.infinity,
  height: 56,
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [LumiColors.primaryLight, LumiColors.primaryDark],
    ),
    borderRadius: BorderRadius.circular(28),
  ),
  child: Center(
    child: Text(
      '按鈕文字',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  ),
)
```

### 次要按鈕（Outline Button）

```dart
OutlinedButton(
  style: OutlinedButton.styleFrom(
    side: BorderSide(color: LumiColors.primary),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    minimumSize: const Size(double.infinity, 56),
  ),
  onPressed: () {},
  child: Text('取消', style: TextStyle(color: LumiColors.primary)),
)
```

### 文字按鈕（Text Button）

```dart
TextButton(
  onPressed: () {},
  child: Text(
    '取消',
    style: TextStyle(
      fontSize: 15,
      color: LumiColors.primary,
      fontWeight: FontWeight.w400,
    ),
  ),
)
```

### 衣物卡片

```dart
Container(
  decoration: BoxDecoration(
    color: LumiColors.surface,
    borderRadius: BorderRadius.circular(16),
    // 無 boxShadow，靠 margin 與 base 背景色差製造層次
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Image.network(item.thumbnailUrl, fit: BoxFit.cover),
  ),
)
```

衣物列表使用 4 欄 Grid，不顯示類別標籤（圖片說話）。

### 分類篩選 Tab

```dart
// 橫向可滾動，選中 Tab 顯示橘色底線
TabBar(
  isScrollable: true,
  labelColor: LumiColors.primary,
  unselectedLabelColor: LumiColors.subtext,
  indicatorColor: LumiColors.primary,
  indicatorWeight: 2.5,
  tabs: [...],
)
```

### 顏色篩選器

水平排列的圓形色票，直徑 `28px`，選中時顯示橘色外框。色票顏色代表衣物的實際顏色，不使用品牌色系。

### FAB（浮動動作按鈕）

```dart
FloatingActionButton(
  backgroundColor: LumiColors.primary,
  onPressed: () {},
  child: const Icon(Icons.camera_alt_outlined, color: Colors.white),
)
```

位置：右下角，`bottom: 24, right: 16`。

### Bottom Navigation Bar

3 個項目：我的衣櫥 ／ 我的穿搭 ／ 個人檔案

```dart
BottomNavigationBar(
  selectedItemColor: LumiColors.text,
  unselectedItemColor: LumiColors.subtext,
  backgroundColor: LumiColors.surface,
  // 無分隔線，靠背景色與 elevation 區分
)
```

### Modal / 衣物詳情

衣物詳情以「非全螢幕浮動卡片」呈現，不是全頁路由：
- 背景衣物列表半透明模糊（`BackdropFilter`）
- 白色卡片，`borderRadius: 24`，最大高度 75% 螢幕
- 左右箭頭切換衣物
- 右上角 X 關閉按鈕

---

## 頁面結構

### Welcome（歡迎頁）

```
[全螢幕衣櫥情境照片]
[Logo 草書字「Lumi」，置中偏上]
[副標「用 Google 相片點亮妳的衣櫥」]
[底部固定：Google 登入橘色按鈕]
```

### Loading（載入動畫）

```
[暖奶油米背景]
[Lumi Logo，金/暖棕色]
[中央：暖橘脈衝光暈 Orb，持續 opacity 0.3 → 1.0 循環]
[底部文字：「Lumi 正在為妳點亮衣櫥...」]
```

禁止使用 `CircularProgressIndicator`，一律使用光暈脈衝動畫。

### Onboarding（3 頁）

```
[上半：情境照片（全寬）]
[下半：白色圓角卡片]
  [橘色大標題]
  [說明插圖]
  [灰色說明文字]
  [橘色主按鈕（下一步 / 開始使用）]
```

Step 1：零摩擦數位化衣櫥
Step 2：AI 智慧分析
Step 3：聰明消費不重複

### 我的衣櫥（主頁）

```
[狀態列]
[「我的衣櫥」 H1 + 右側「+ 加入新品」文字按鈕]
[分類 Tab 橫向捲動：連身裙 上衣 下身 鞋履 包款 配件]
[顏色圓形色票篩選列]
[4 欄衣物卡片 Grid]
[右下：橘色 FAB 相機]
[底部 Navigation Bar]
```

#### 空狀態

```
[中央置中：衣架插圖]
[「妳的衣櫥目前空空如也」H2]
[「點擊右上角的「加入新品」按鈕...」Caption]
[右下：橘色 FAB（仍顯示，引導操作）]
```

### 上傳流程

1. **選擇照片**：系統 Photo Picker，最多 20 張，橘色勾選圓圈
2. **確認上傳**：Grid 預覽 + 橘色「開始上傳」按鈕 + 文字「取消」
3. **上傳中**：環形進度條（橘色 stroke + 光暈）+ 百分比 + 說明文字
4. **完成**：橘色大勾 + 光暈 + 「上傳完成！」+ 橘色「回到衣櫥」按鈕
5. **中斷確認 Dialog**：白色圓角卡片 + 外框「中斷並退出」+ 橘色「繼續上傳」

#### 上傳進度動畫

```dart
// 圓形進度條：橘色 stroke，內圓發散光暈
CircularProgressIndicator(
  value: progress,       // 0.0 ~ 1.0
  color: LumiColors.primary,
  backgroundColor: LumiColors.primary.withOpacity(0.15),
  strokeWidth: 6,
)
// 搭配外層 Container 的橘色 glow（BoxDecoration + boxShadow 僅此處例外允許）
```

### Lumi-Check（似曾相識）

#### 入口頁

```
[< 回衣櫥]
[「似曾相識」H1]
[上半：購物情境照片]
[下半：白色圓角卡片]
  [「開始比對」H2]
  [說明文字]
  [相機插圖（橘橙色 sparkle 裝飾）]
  [橘色「開始拍照」按鈕]
  [文字「取消」]
```

#### 比對結果

```
[< 上一步]
[上方：新品照片（白色大卡片）+ 「新品」標籤]
[下方：衣物相似度橫向列表（可滑動）]
  - 最高相似者：橘色外框 + 「XX% 相似」橘色 Badge
  - 其餘：無框，灰色 Badge
  - 每項顯示：類別 + 顏色
[底部兩按鈕：外框「已經有了」＋ 橘色「加入新品」]
```

相似度呈現規則：
- ≥ 80%：橘色 Badge + 橘色外框卡片 + `warning` 色標示
- 50–79%：灰色 Badge，中性提示
- < 50%：不顯示

---

## 動畫規範

| 情境 | 動畫方式 |
|------|---------|
| AI 載入 / 分析中 | 暖橘光暈 Orb，opacity 0.3 → 1.0，`Curves.easeInOut`，`repeat(reverse: true)` |
| 上傳進度 | 圓形進度條 + 百分比數字，實時更新 |
| 上傳完成 | 橘色大勾淡入 + glow 擴散 |
| 頁面轉場（Onboarding） | 水平滑入（`SlideTransition`） |
| Modal 出現 | 底部滑入（`BottomSheet` 或 `showModalBottomSheet`） |
| 衣物卡片 Tap | `InkWell` ripple，`borderRadius: 16` |

禁止使用：
- `CircularProgressIndicator`（AI 處理狀態）
- `BoxShadow`（一般卡片，上傳進度光暈除外）
- 純紅色 `Colors.red`（任何警示狀態）

---

## 導航架構

```
Welcome
  └→ Loading（首次登入）
       └→ Onboarding Step1 → Step2 → Step3
            └→ 我的衣櫥（主頁）
                 ├── 上傳流程（底部 Sheet → 全頁進度）
                 ├── 衣物詳情（浮動卡片 Modal）
                 ├── 似曾相識（全頁）
                 │     └── 比對結果（全頁）
                 └── 個人檔案（底部 Tab）
```

- 返回：左箭頭 + 文字（`< 上一步` / `< 回衣櫥`），不單獨用 icon
- Modal 關閉：右上角 `×`（衣物詳情）或文字「取消」（其他）
- 底部導航：3 Tab，無動態效果，圖示 + 文字

---

## 禁止事項

| 禁止 | 替代方案 |
|------|---------|
| hardcode 顏色值（如 `Color(0xFF...)` 直接寫在 Widget） | 使用 `LumiColors` 常數 |
| `CircularProgressIndicator` 於 AI 處理狀態 | 光暈 Orb 動畫 |
| 一般卡片使用 `BoxShadow` | 靠 `LumiColors.base` 背景與白色卡片色差製造層次 |
| 警示使用純紅 `Colors.red` | `LumiColors.warning`（深橘紅） |
| `Divider` 分隔線 | 留白間距 |
| 全頁 Dialog 取代 Modal | 使用底部 Sheet 或浮動卡片 |
| 按鈕文字使用橘色以外顏色 | 主按鈕白字；文字按鈕橘色 |
