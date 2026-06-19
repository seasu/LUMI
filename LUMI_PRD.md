# Lumi 產品規格書 (Product Requirements Document)

**專案名稱：** Lumi
**口號：** *Light up your wardrobe with Google Photos.*
**前端版本 (Flutter App)：** 1.0.66+155
**後端版本 (Cloud Functions)：** 1.0.17
**開發框架：** Flutter (Cross-platform)

---

## 1. 產品定義 (Product Definition)

### 1.1 品牌願景

Lumi（源自 Luminous）旨在透過科技照亮衣櫥中被遺忘的角落。透過「相簿即資料庫」的創新概念，讓數位衣櫥的維護成本降至零，並利用 AI 協助使用者進行理性消費與高效管理。

### 1.2 核心目標

| 目標 | 說明 |
|------|------|
| 零摩擦數位化 | 利用 Google Photos API 自動同步，無需手動上傳 |
| AI 智慧導航 | 透過 Gemini 1.5 Flash 實現自動分類標籤與色彩辨識 |
| Lumi-Check | 在購物現場即時查重，防止重複購買相似款式 |

---

## 2. 功能規格 (Functional Requirements)

### 2.1 帳號與儲存系統

- **Google OAuth 2.0**：整合 Google 登入，請求 `photoslibrary` 存取範圍。
- **專屬相簿同步**：
  - App 啟動後檢測 Google 相簿中名為 `Lumi_Wardrobe` 的相簿。
  - 若不存在，則自動建立。
  - Lumi 只讀取與操作此相簿內的圖片，確保隱私與資料純淨度。
- **使用者設定**：Firebase Firestore 儲存個性化設定與衣物 metadata。

### 2.2 智慧入庫 (Lumi Snap)

- **相機整合**：內建拍照功能，拍完後立即觸發 AI 分析流程。
- **Gemini 辨識引擎**：透過 Firebase Cloud Functions 呼叫 Gemini 1.5 Flash，自動提取：
  - 顏色（主色 + 副色）
  - 材質（棉、麻、合成纖維等）
  - 種類（上衣 / 褲子 / 外套 / 配件 / 鞋子）
  - 特徵向量（用於 Lumi-Check 比對）
- **Metadata 儲存**：AI 分析結果存入 Firestore，以 Google Photos `mediaItemId` 作為關聯鍵。
- **即時上傳**：拍照完成後於背景異步上傳至 `Lumi_Wardrobe` 相簿。

### 2.3 管理與搜尋 (Lumi Search)

- **自然語言搜尋**：串接 Firestore 查詢，支援「藍色長裙」、「毛衣」等語義搜尋。
- **色彩過濾器**：提供視覺化色盤，點擊即可篩選對應色系的衣物。
- **條件組合篩選**：支援種類 + 顏色 + 材質的多維度複合篩選。

### 2.4 查重神器 (Lumi-Check)

- **觸發方式**：切換至「購物模式」後拍照。
- **比對邏輯**：透過 Firebase Cloud Functions 比對新照片特徵向量與 Firestore 中的既有特徵向量，計算餘弦相似度。
- **視覺反饋**：
  - 相似度 ≥ 80%：顯示警示橫幅，並排展示新舊衣物照片。
  - 相似度 50–79%：顯示「可能相似」提示。
  - 相似度 < 50%：顯示「衣櫥中無相似款式」。

---

## 3. 技術架構 (Technical Architecture)

### 3.1 技術堆疊

| 層級 | 技術選型 |
|------|---------|
| Frontend | Flutter 3.x + Riverpod (State Management) |
| 認證 | Firebase Auth + Google Sign-In |
| 資料庫 | Firebase Firestore（衣物 metadata、特徵向量） |
| 相片儲存 | Google Photos Library API（原始相片） |
| AI 推論 | Gemini 1.5 Flash via Firebase Cloud Functions |
| CI/CD | GitHub Actions |

### 3.2 資料模型 (Firestore Schema)

```
users/{userId}/
  └── wardrobe/{mediaItemId}/
        ├── mediaItemId: string       # Google Photos ID
        ├── category: string          # 上衣 / 褲子 / 外套 / 配件 / 鞋子
        ├── colors: string[]          # ["#3B5BDB", "#FFFFFF"]
        ├── materials: string[]       # ["棉", "聚酯纖維"]
        ├── embedding: float[]        # 特徵向量（Lumi-Check 使用）
        ├── thumbnailUrl: string      # Google Photos baseUrl
        └── createdAt: timestamp
```

### 3.3 雲端建置規範

**本專案採用 Cloud-Native Build Policy，禁止在開發者本機執行正式建置。**

- 版本控制：GitHub
- 自動版號（Auto-Versioning）：採用 Semantic Versioning，透過 GitHub Actions 偵測 Commit Message（`feat:` / `fix:`）自動更新 `pubspec.yaml` 版號。
- 所有 AI 推論邏輯須透過 Firebase Cloud Functions 執行，不得在客戶端直接呼叫 Vertex AI API（避免 API Key 暴露）。

---

## 4. CI/CD 自動化流程

所有建置與分發皆透過 **GitHub Actions** 完成。

### 4.1 iOS 部署（TestFlight）

1. **環境**：`macos-latest`
2. **憑證管理**：Fastlane Match，憑證加密存於私有 Git 倉庫
3. **觸發**：Merge 至 `main` 後自動上傳至 App Store Connect，通知 TestFlight 測試員

### 4.2 Android 部署（Firebase App Distribution）

1. **環境**：`ubuntu-latest`
2. **簽署**：GitHub Secrets 儲存 Base64 編碼的 Keystore，建置時動態還原
3. **觸發**：建置 App Bundle 後自動分發至 Firebase App Distribution

### 4.3 Workflow 觸發規則

| 分支 / 事件 | 動作 |
|------------|------|
| Push to `main` | 版號更新 → 建置 iOS + Android → 雙平台分發 |
| Push to `develop` | 執行 Flutter 測試與靜態分析 |
| Pull Request | 執行 Flutter 測試與靜態分析 |

---

## 5. UI/UX 設計準則

### 5.1 視覺風格

**Neo-Minimalism（新極簡主義）**：介面如「光影」一般輕盈，避免沉重陰影與粗線條。

### 5.2 色彩系統

| Token | Hex | 用途 |
|-------|-----|------|
| `colorBase` | `#F5F5F7` | 霧面淺灰，主背景 |
| `colorSurface` | `#FFFFFF` | 純白，卡片表面 |
| `colorGlow` | `#AEE2FF` | 微光藍，AI 處理動畫狀態 |
| `colorText` | `#1D1D1F` | 主要文字 |
| `colorSubtext` | `#6E6E73` | 次要說明文字 |

### 5.3 互動設計原則

- AI 處理中使用 `#AEE2FF` 脈衝光暈動畫，取代傳統 loading spinner。
- 衣物卡片採用無邊框設計，以留白建立層次感。
- Lumi-Check 警示使用柔和的橘紅色漸層，而非強烈的警告紅。

---

## 6. 里程碑規劃 (Milestones)

> **開發策略：Web 優先**
> M1–M4 以 Flutter Web 為目標平台，部署至 GitHub Pages 快速驗證 UI Flow 與功能邏輯。
> UX 確認後，M5 再轉換為 iOS + Android Native，避免在未驗證的設計上投入平台申請與 build 成本。

---

### M1｜Web 骨架 + Google 登入 + GitHub Pages 自動部署

**前置條件**：Firebase 專案已建立（Web 設定）、Google OAuth Web Client ID 已申請

**任務清單**
- Flutter 專案初始化，啟用 Web 平台支援
- 依 `/style` 規範建立目錄結構
- 安裝核心依賴：`flutter_riverpod`、`go_router`、`firebase_core`、`firebase_auth`、`google_sign_in`
- Google Sign-In 實作（Web OAuth Client ID）
- Firebase Auth 整合（Web SDK 設定）
- Firestore Security Rules 初版（`request.auth.uid == userId` 隔離）
- 登入頁 → 首頁骨架導航
- GitHub Actions：PR 觸發 `flutter analyze` + `flutter test`
- GitHub Actions：push `main` 觸發 `flutter build web` → 自動部署至 GitHub Pages
- GitHub Actions：Conventional Commits 自動版號
- `.env` 設定與 `.gitignore`

**驗收標準**
- [ ] 使用者可在瀏覽器以 Google 帳號登入
- [ ] GitHub Pages URL 可正常存取
- [ ] CI 自動執行分析與測試，通過後自動部署

---

### M2｜Lumi Snap（Web 版：拍照 + AI 分析 + 上傳）

**前置條件**：M1 完成、Vertex AI 存取權限、Firebase Cloud Functions 環境就緒

**任務清單**
- Firebase Cloud Functions 專案初始化（TypeScript）
- Cloud Function `analyzeClothing`：接收圖片 → 呼叫 Gemini 1.5 Flash → 回傳 category、colors、materials、embedding
- Cloud Function `uploadToPhotos`：接收圖片 bytes → 上傳至 Google Photos `Lumi_Wardrobe` 相簿
- App 啟動時檢查並自動建立 `Lumi_Wardrobe` 相簿（若不存在）
- 瀏覽器相機整合（`image_picker_for_web`）
- 異步上傳流程 + Glow 脈衝動畫
- Firestore 寫入 metadata + embedding
- `thumbnailUrl` 55 分鐘快取與刷新邏輯
- 失敗處理：上傳失敗不寫 Firestore，保持資料一致性

**驗收標準**
- [ ] 瀏覽器相機可正常拍照
- [ ] AI 分析回傳正確的 category / colors / materials
- [ ] 相片成功上傳至 Google Photos
- [ ] Metadata 正確寫入 Firestore（含 embedding）
- [ ] 上傳失敗時顯示錯誤，Firestore 無殘缺資料

---

### M3｜Lumi Search（Web 版：衣物列表 + 篩選）

**前置條件**：M2 完成、Firestore 內有衣物資料

**任務清單**
- 衣物列表頁（響應式 Grid 佈局，適配桌面與手機瀏覽器）
- 衣物卡片 Widget（含 `thumbnailUrl` 自動刷新）
- 種類篩選（上衣 / 褲子 / 外套 / 配件 / 鞋子）
- 色彩篩選（視覺色盤）
- 多條件組合篩選（種類 + 顏色 + 材質）
- 空狀態 UI（無衣物時顯示引導畫面）
- 刷新按鈕（Web 無下拉刷新）
- Firestore cursor-based 分頁查詢
- `thumbnailUrl` 過期偵測與自動刷新

**驗收標準**
- [ ] 衣物列表正確載入並顯示
- [ ] 單一條件與多條件篩選結果正確
- [ ] 空狀態顯示引導畫面，不留空白
- [ ] 過期圖片自動刷新，不顯示壞圖

---

### M4｜Lumi-Check（Web 版：購物查重）

**前置條件**：M3 完成、Firestore 衣物資料含 `embedding` 欄位

**任務清單**
- 購物模式切換入口 UI
- Lumi-Check 專用相機頁（瀏覽器相機）
- Cloud Function `compareClothing`：新照片 → 生成 embedding → 對 Firestore 全量做 cosine similarity
- 比對結果 UI：
  - 相似度 ≥ 80%：橘紅漸層警示橫幅 + 並排對比新舊衣物
  - 相似度 50–79%：「可能相似」提示卡片
  - 相似度 < 50%：「衣櫥中無相似款式」
- 比對中顯示 Glow 動畫，UI 不凍結
- cosine similarity 邏輯 unit test

**驗收標準**
- [ ] 購物模式可正常切換
- [ ] cosine similarity 計算結果正確（unit test 通過）
- [ ] 三種相似度門檻的 UI 呈現正確
- [ ] 比對過程 UI 不凍結

---

### M5｜Native 轉換（iOS + Android）

**前置條件**：M4 完成、Web 版 UX 已確認、Apple Developer 帳號、Google Play Console 帳號

**任務清單**
- Flutter 專案啟用 iOS + Android 平台
- Google Sign-In：新增 iOS OAuth Client ID（`GoogleService-Info.plist`）
- Google Sign-In：新增 Android OAuth Client ID（`google-services.json`）
- 相機：改用 Native 實作（`image_picker` 或 `camera` 套件）
- iOS `Info.plist` 權限設定（相機、相片存取）
- Android `AndroidManifest.xml` 權限設定
- Fastlane Match 設定（iOS 憑證管理）
- Android Keystore 產生，GitHub Secrets 設定
- GitHub Actions：iOS build workflow（`macos-latest` + Fastlane）
- GitHub Actions：Android build workflow（`ubuntu-latest` + Keystore 簽署）
- Firebase iOS / Android App 設定
- 實機測試（iOS + Android）

**驗收標準**
- [ ] App 在 iOS 實機可正常運行所有功能
- [ ] App 在 Android 實機可正常運行所有功能
- [ ] Google Sign-In 在兩個平台均正常，含正確 scope
- [ ] CI 可成功 build 雙平台

---

### M6｜UI 精修、效能優化、Beta 發布

**前置條件**：M5 完成

**任務清單**
- 全 UI 一致性稽核（逐頁對照 `/ui` Skill 設計規範）
- 首次使用者 Onboarding 流程
- Firestore index 優化
- 圖片快取策略優化
- Firebase Crashlytics 整合（iOS + Android）
- Integration test 補齊
- TestFlight 首次發布（iOS）
- Firebase App Distribution 首次發布（Android）
- App Store 截圖準備

**驗收標準**
- [ ] 無明顯 UI 不一致
- [ ] 核心流程無 crash
- [ ] TestFlight build 成功分發給測試員
- [ ] Android beta 透過 Firebase App Distribution 分發

---

## 版本歷史（Changelog）

> 本章節固定置於 PRD **最後一節**。  
> 每次程式碼更新需同步新增一筆，前後端版本分開管理。

| 日期 | 前端版本 | 後端版本 | 變更摘要 | 影響範圍 |
|------|---------|---------|---------|---------|
| 2026-06-19 | 1.0.66+155 | 1.0.17 | 遷移 iOS IAP 驗證至 App Store Server API：移除廢棄的 `verifyReceipt` 端點與 `APPLE_SHARED_SECRET`；改用 App Store Server API（API 私鑰 JWT 認證）+ StoreKit `transactionId` 驗證；刪除所有旁路邏輯（21004 旁路、isRestore 旁路）；Flutter 端改送 `transactionId`（`details.purchaseID`）取代整張 receipt；更新 deploy workflow 注入 `APPLE_API_KEY_ID`/`APPLE_API_ISSUER_ID`/`APPLE_API_PRIVATE_KEY` | Purchase / IAP / Cloud Functions |
| 2026-06-16 | 1.0.65+154 | 1.0.16 | 修正「購買已持有商品」流程：使用者點擊購買時，若 StoreKit 回傳 `PurchaseStatus.restored`（代表該商品已在帳戶中），原本因 `_isRestoreAction=false` 傳送 `isRestore=false` 給後端，導致 CF 的 StoreKit 信任旁路未觸發而出現 `permission-denied`；現改為 `PurchaseStatus.restored` 永遠傳送 `isRestore=true`，符合 StoreKit 語意（已持有 = 恢復），讓後端旁路正確生效 | Purchase / IAP |
| 2026-06-16 | 1.0.64+153 | 1.0.16 | 修正帳號刪除後 Profile 頁面卡住問題：當 Firestore 用戶文件不存在但使用者仍處於登入狀態時（如刪帳流程中途失敗），Profile 頁以前顯示無限轉圈；現改為 `_OrphanedProfileState` widget，顯示「找不到帳號資料，即將為您登出…」並在 3 秒後自動呼叫 `signOut()`，同時提供手動登出按鈕，讓使用者可立即脫離卡住狀態 | Auth / Profile / UI |
| 2026-06-16 | 1.0.63+152 | 1.0.16 | 診斷 / 日誌改善：(1) `deleteAccount.ts` 新增 `console.log` 記錄每個步驟（CF 呼叫開始、Firestore 刪除、Auth 刪除、完成）及 `console.error` 記錄錯誤，讓 Firebase Console 可見執行過程；(2) `DebugLogService` 新增 SharedPreferences 持久化（debounce 1s 寫入，最多保留 300 筆）；(3) `main.dart` 啟動時 `loadPersisted()` 載入上一 session 的 log，讓重開 App 後仍可看到刪帳錯誤訊息 | Auth / Cloud Functions / Debug |
| 2026-06-16 | 1.0.62+151 | 1.0.15 | Paywall 還原購買 UX：按下「還原購買」後，sheet 整體內容替換為 _RestoreOverlay（Glow Orb 動畫 + 「正在還原購買…」文字），讓使用者清楚知道正在處理；新增 `paywallRestoringPurchases` l10n key（繁/簡中、英、日） | Purchase / IAP / UI / i18n |
| 2026-06-10 | 1.0.61+150 | 1.0.15 | 修正帳號刪除流程三個 bug：(1) catch block 未呼叫 `signOut()` — CF 若在刪除 Firebase Auth 前報錯，使用者仍留在登入狀態但 Firestore 資料已不存在，導致白畫面；(2) dialog 未必在 GoRouter 導航前關閉 — 改用 try/finally 確保 `navigator.pop()` 永遠在 signOut 之前執行；(3) 無論 CF 成功或失敗，現在都呼叫 `signOut()` 確保 `auth.currentUser` 清空，讓 Router redirect 正確跳回登入頁 | Auth / Profile / UI |
| 2026-06-10 | 1.0.60+149 | 1.0.15 | 修正 iOS 購買與恢復購買流程三個 bug：(1) **後端** `verifyPurchase.ts`：`verifyAppleReceipt` 改回傳 `{ valid, status }`，Apple 狀態 21004（APPLE_SHARED_SECRET 設定錯誤，屬後端 config 問題）時信任 StoreKit 並直接套用購買；21006（訂閱已過期）改拋 `failed-precondition` 供前端顯示明確訊息；(2) **前端** `purchase_provider.dart`：新增 `_isRestoreAction` 旗標，區分 `buy()` 與 `restore()` 動作——StoreKit 可能對 `buy()` 回傳 `restored` 狀態（沙盒環境），不再一律視為 restore；(3) 移除舊有「restore 失敗也 silent PurchaseDone」邏輯，改為正確顯示錯誤訊息，避免使用者看到假成功但 Firestore 未更新 | Purchase / IAP / Cloud Functions |
| 2026-05-29 | 1.0.59+148 | 1.0.14 | 多國語系（i18n）完整實作：使用 Flutter `gen-l10n`，支援 English / 繁體中文 / 简体中文 / 日本語；新增 `l10n.yaml`、5 個 ARB 檔（`app_en.arb`、`app_zh_TW.arb`、`app_zh_CN.arb`、`app_ja.arb`、`app_zh.arb`）含 ~320 個字串 key；替換全 App 29 個 UI 檔硬編碼中文字串；新增 `LocaleNotifier`（Riverpod + SharedPreferences）與 Profile 頁語言切換 UI；新增 `translateCategory`/`translateColor` helper | UI / i18n / Auth / Profile / Wardrobe / OOTD / Check |
| 2026-05-28 | 1.0.58+147 | 1.0.14 | 新增帳號刪除功能（Apple App Store Guideline 5.1.1(v)）：(1) CF `deleteAccount`：刪除 Firestore `users/{uid}` 文件後刪除 Firebase Auth 記錄；(2) 個人頁新增「刪除帳號」文字按鈕，點擊後彈出確認 Dialog；(3) `auth_provider.dart` 新增 `deleteAccount()`；(4) `CloudFunctionsService.deleteAccount()` 呼叫 CF | Auth / Profile / Cloud Functions |
| 2026-05-25 | 1.0.57+146 | 1.0.13 | (1) Paywall Sheet UI（`paywall_sheet.dart`）：底部升級 Sheet，Pro 年費方案卡＋補充包卡（decoy 效果）、Glow Orb 購買中動畫、成功自動關閉；(2) 個人頁配額進度條（`profile_page.dart`）：顯示 AI 分析配額使用量、linear progress bar、剩餘 ≤5 件橘色警示、升級按鈕；(3) Snap 頁配額警示 Banner（`snap_page.dart`）：SnapPreviewing 狀態且剩餘 ≤5 件時顯示橘色 Banner，quota_exceeded 錯誤自動彈出 Paywall | Purchase / IAP / UI / Profile / Snap |
| 2026-05-21 | 1.0.56+145 | 1.0.12 | (1) 衣櫥與穿搭 Detail Modal 新增左右滑動瀏覽（`PageView.builder` + `ClampingScrollPhysics`，編輯模式鎖定滑動）；(2) 篩選列「我的最愛」Tab 文字高度對齊修正（改用 `Text.rich` + `WidgetSpan(alignment: PlaceholderAlignment.middle)`）；(3) 分享圖片與本機存圖均先壓縮（`flutter_image_compress` Q90 / 4096px 保高解析度）；(4) 衣櫥頁標題「加入新品」改為右下角 FAB，與「似曾相識」雙 FAB 垂直排列，操作流程統一為 bottom sheet 選相機／相簿；(5) SnapPage 帶 `autoSource` 時隱藏閒置 UI 並在取消後自動返回；(6) 移除「加入完成」全頁畫面，改為立即返回衣櫥 + 浮動 SnackBar 提示 | Wardrobe / OOTD / UI / Snap / Share |
| 2026-05-20 | 1.0.50+139 | 1.0.12 | 精簡 OOTD 新增流程：(1) `ootd_add_page.dart` 移除中間編輯畫面，選完照片後直接 auto-save 並 slide-from-bottom 跳至分享頁；(2) `ootd_share_page.dart` 改為滿版（edge-to-edge）呈現，移除 16px 水平 padding，照片填滿全屏，底部 overlay 浮層加入說明文字輸入（即時更新卡片內 caption），修正 `_OutlinedButton` label hardcode 問題；(3) 「似曾相識」入口改為 bottom sheet 統一入口，選照片後全滿版 AI 分析動畫（照片背景 + sonar rings） | OOTD / Lumi-Check / UI / Share |
| 2026-05-13 | 1.0.42+131 | 1.0.12 | UI/UX 全面重設計：(1) OOTD Detail Modal — caption 疊圖底部漸層、日期改 pill chip、分享按鈕改 gradient、刪除改低調文字；(2) Post-save 流程改兩段式：儲存成功預覽頁（亮色 base）顯示卡片縮圖與 hint，按「分享穿搭」才進入暗色互動編輯器（可縮放旋轉照片、拖拉文字），增加 `_EditorHintChip` 提示操作 | OOTD / UI / Share |
| 2026-05-12 | 1.0.41+130 | 1.0.12 | 完成 OOTD 本地儲存遷移：`ootd_detail_modal.dart` 移除 `imageBase64`/`base64Decode`/`authStateProvider`/`ootdRepositoryProvider`，改用 `LocalOotdStorage.getImageFile(id)` + `FutureBuilder<File?>` 顯示圖片，刪除功能改為 `ootdLocalProvider.notifier.delete(id)`；OOTD 圖片壓縮改為 800×1200 Q70；衣櫥 Snap 圖片壓縮改為 1280×1280 Q75 | OOTD / Storage / Snap |
| 2026-05-12 | 1.0.40+129 | 1.0.12 | 重寫穿搭分享畫面：以 `SizedBox(4:3)` + `RepaintBoundary` 修正超長照片破版；照片支援雙指縮放/旋轉（`GestureDetector onScaleUpdate` + `Matrix4 Transform`）；文字疊層可拖拉至任意位置；Lumi watermark 固定右下角；分享時以 `boundary.toImage(pixelRatio:3)` 合成 PNG 後透過 `Share.shareXFiles` 輸出 | OOTD / UI / Share |
| 2026-05-12 | 1.0.39+128 | 1.0.12 | 修正分享穿搭畫面「分享一段話吧...」無法輸入：將 `_ResultView` 改為 `StatefulWidget`，新增 `TextEditingController`，靜態 `Text` 改為 `TextField`；使用者輸入的文字會隨圖片一起帶入 `Share.shareXFiles` 的 `text` 參數 | OOTD / UI |
| 2026-05-11 | 1.0.38+127 | 1.0.12 | 登入頁新增使用條款與隱私政策文字連結（`_TosFooter`）；新增 `url_launcher` 依賴與 `lib/shared/constants/app_urls.dart` URL 常數 | Auth / UI / Login |
| 2026-05-11 | 1.0.37+126 | 1.0.12 | 穿搭新增 FAB 改為「新增」並彈出選單（拍照 / 從相簿選取）；修復新增流程 `_EditView` TextField 失焦問題（加 persistent `FocusNode`）；修復 `_ResultView` 分享壞掉（加 `sharePositionOrigin` + `Builder`）；衣櫥卡片下方以色塊取代 hex 碼字串 | OOTD / Wardrobe / UI / Share |
| 2026-05-11 | 1.0.36+125 | 1.0.12 | 修正衣櫥顏色篩選完全無效的問題：改用 HSL 分桶模糊比對（`_colorBucket`），解決 Gemini 回傳精確 hex（如 `#C62828`）與篩選預設色票 hex（如 `#e53935`）不一致導致永遠篩不到結果；同步擴大顏色色點 tap target 至 48×48px 並增強已選取視覺效果（白色外框 + primary 外環） | Wardrobe / UI / Filter |
| 2026-05-10 | 1.0.35+124 | 1.0.12 | 修正 `GEMINI_EMBEDDING_MODEL` GitHub Variable 設為 `text-embedding-004`（v1beta 不支援）導致 embedding 步驟持續 404；更新 Variable 為 `gemini-embedding-2`；bump 後端版本確認部署一致性 | Cloud Functions / Gemini / Deployment |
| 2026-05-09 | 1.0.35+124 | 1.0.11 | 新增 OOTD 穿搭卡片點擊 Detail Modal（顯示圖片 3:4、日期、備註、分享按鈕，樣式與衣櫥 Detail 一致）；修復新增穿搭完成後「分享穿搭」按鈕無法喚起系統分享：改用 temp 檔寫入後以 `XFile(path)` 分享，解決 iOS `XFile.fromData` 不可靠問題 | OOTD / UI / Share |
| 2026-05-09 | 1.0.34+123 | 1.0.11 | 換用 `gemini-embedding-2`（GA，multimodal）取代 `gemini-embedding-001`（text-only）；`generateEmbedding` 改為直接嵌入衣物圖片（`inlineData` image），提升 Lumi-Check cosine similarity 的視覺準確度；`analyzeClothing` CF 傳入 `imageBase64`/`mimeType` 給 embedding 步驟 | Cloud Functions / Gemini / Lumi-Check |
| 2026-05-08 | 1.0.30+119 | 1.0.4 | 修正 `signOut` / `signInWithGoogle` / `signInWithApple` 在 iOS 上觸發 `Bad state: Cannot use "ref" after the widget was disposed` 崩潰：Firebase 在 iOS 同步觸發 auth state change，GoRouter 在 `finally` 執行前就銷毀 ProfilePage，導致後續 `ref.read()` 拋出；修正方式：在第一個 `await` 前先讀取所有 providers，`finally` 只使用直接物件參考 | Auth / iOS |
| 2026-05-09 | 1.0.30+119 | 1.0.7 | 參考 Magic-Sticker 架構，將 `@google/generative-ai` SDK 替換為直接呼叫 Gemini REST API（native `fetch`），模型名稱改用 `defineString` 參數（`GEMINI_VISION_MODEL` / `GEMINI_EMBEDDING_MODEL`）；刪除 codegen 腳本、generated 檔、死碼（`analyzeWardrobeCore`、`imageDownload`）；`package.json` 移除 SDK 依賴，build 簡化為純 `tsc` | Cloud Functions / Architecture |
| 2026-05-09 | 1.0.30+119 | 1.0.6 | 修正 embedding 模型：`text-embedding-004` 僅存在於 Vertex AI（`aiplatform.googleapis.com`），透過 `GEMINI_API_KEY`（Gemini Developer API）呼叫 `generativelanguage.googleapis.com` 時 v1/v1beta 皆回傳 404；改為使用 `gemini-embedding-exp-03-07`（Developer API 可用），同時還原不必要的 `apiVersion:"v1"` 覆寫，並將 `text-embedding-004` 加入 deprecated 清單 | Cloud Functions / Gemini / Embedding |
| 2026-05-08 | 1.0.30+119 | 1.0.5 | 修正 embedding 步驟 404 錯誤：`text-embedding-004` 只存在於 v1 stable API，SDK 預設為 v1beta，導致 `embedContent` 每次回傳 404；修正方式：`getGenerativeModel` 嵌入時傳入 `{ apiVersion: "v1" }`。同時將 `text-embedding-001`/`embedding-001` 加入 deprecated 清單並從 fallback chain 移除，新增 fallback 警告日誌 | Cloud Functions / Gemini / Embedding |
| 2026-05-08 | 1.0.30+119 | 1.0.4 | 修正 `analyzeClothing` Cloud Function 每次回傳 HTTP 500 的根本原因：`@google/generative-ai` `^0.15.0` 的 semver 0.x 語意鎖定在 0.15.x，舊 SDK 無法解析 `gemini-2.5-flash`（2025）回應格式，導致 Cloud Run 返回未封裝的 HTTP 500；升級至 `^0.24.0`（已安裝 0.24.1）。同時修正 fallback chain 中無效的模型名稱 `gemini-flash-latest` → `gemini-2.0-flash`；在 `analyzeClothing.ts` 與 `gemini.ts` catch block 加入 `console.error` 以利後續 Cloud Logging 診斷 | Cloud Functions / Gemini / analyzeClothing |
| 2026-05-09 | 1.0.34+123 | 1.0.10 | 修正 Gemini embedding API endpoint：`gemini-embedding-001` 只存在於 `v1beta`（非 `v1`）；上個 commit 錯誤地切換到 `v1`，改回 `v1beta` 後 embedding 呼叫應正常運作；視覺模型 `gemini-3.1-flash-lite` 在 `v1beta` 同樣可用 | Cloud Functions / Gemini |
| 2026-05-09 | 1.0.34+123 | 1.0.9 | 修正相機 crash 根本原因：`Info.plist` 缺少 `NSCameraUsageDescription`，iOS TCC 在呼叫相機時直接 SIGKILL App；新增三個 Privacy Usage 說明（Camera、PhotoLibrary、PhotoLibraryAdd）；CI workflow 補 dSYM 自動上傳步驟，未來 crash 可在 App Store Connect 被符號化 | iOS / Privacy / CI |
| 2026-05-09 | 1.0.33+122 | 1.0.9 | 更新 Gemini 模型：視覺分析改用 `gemini-3.1-flash-lite`（GA，multimodal）；embedding 改用 `gemini-embedding-001`；API endpoint 由 `v1beta` 改為 `v1`（修正 embedding 404 根本原因）；恢復 `analyzeClothing` 的 embedding 步驟，Lumi-Check cosine similarity 重新生效 | Cloud Functions / Gemini / Lumi-Check |
| 2026-05-09 | 1.0.33+122 | 1.0.8 | 修正兩個 crash：（1）移除 `analyzeClothing` CF 中的 embedding 步驟（`text-embedding-004` v1beta 404 錯誤），改回傳空 embedding；（2）`SnapPage.initState()` 與 `OotdAddPage.initState()` 補 `reset()` 呼叫，防止跨 session 殘留狀態（`SnapDone`／`OotdAddResult`）導致頁面開啟後立即自動返回；`OotdAddNotifier.pickPhoto()` 加入 try-catch 防止相機不可用時 Future 拋出未捕捉例外 | Snap / OOTD / Cloud Functions |
| 2026-05-09 | 1.0.32+121 | 1.0.8 | 全面本地化衣櫥資料：移除 Firestore wardrobe 集合，改以 JSON sidecar 檔案（`{uuid}.json`）與圖片並排存於 `lumi_wardrobe/`，由 iCloud/Google Auto Backup 自動備份；新增 `LocalWardrobeStore`（AsyncNotifier）、`WardrobeItem.toJson/fromJson`、`LocalImageStorage` JSON 方法；刪除 `WardrobeRepository`（Firestore）；Lumi-Check 改為 client 端 cosine similarity（新增 `similarity.dart`）取代 `compareClothing` CF；下拉重新整理觸發失敗項目重新分析；移除 `compareClothing` Cloud Function | Architecture / Storage / Check / Cloud Functions |
| 2026-05-09 | 1.0.31+120 | 1.0.7 | 新增 `getServerInfo` Cloud Function（回傳 `version`）；新增 `CloudFunctionsService.getServerVersion()`；Debug Log 頁面改為 `ConsumerStatefulWidget`，AppBar 標題下方顯示 Server 版本號（頁面開啟後非同步載入）；新增 `functions/src/serverInfo.ts`；移除 `@google/generative-ai` SDK 改以直接 REST 呼叫 Gemini Developer API（`gemini-2.5-flash` / `gemini-embedding-exp-03-07`）；`defineString` 管理模型名稱，修正 `text-embedding-001`/`text-embedding-004` 404 根本原因；修正 iOS 登出時 `ref-after-disposed` crash | Cloud Functions / Debug / Auth |
| 2026-05-19 | 1.0.49+138 | 1.0.12 | 似曾相識比較結果改為側並側照片比較：新增 `_CompareView` 統一 ≥80% 與 50-79% 兩個結果畫面；左側顯示「想買的」新品照片，右側顯示「衣櫥最相似」含 scrim 漸層、類別文字與相似度徽章（≥80% 用 warning 色，50-79% 用 primary 色）；次要相似衣物顯示為水平捲動縮圖列；底部提示橫幅 + 「已經有了」＋「加入新品」雙按鈕 | Lumi-Check / UI |
| 2026-05-18 | 1.0.48+137 | 1.0.12 | 衣櫥空狀態智慧分流：依「真空衣櫥 / AI 辨識後移至分類 / 其他篩選無結果」三種情境顯示不同提示與 CTA 按鈕（gradient「查看全部衣物」），解決使用者在「未分類」tab 看到空畫面後迷惘的問題 | Wardrobe / UX |
| 2026-05-18 | 1.0.47+136 | 1.0.12 | 穿搭 detail modal 改為 showGeneralDialog 全幅佈局（同衣櫥 detail）：slide-from-bottom 轉場、下滑關閉、照片滿版、操作按鈕壓在圖上。Share page 移除獨立 header bar，改為浮動「← 返回」膠囊按鈕；進入動畫也換成 slide-from-bottom 保持一致 | OOTD / UI |
| 2026-05-18 | 1.0.46+135 | 1.0.12 | 衣物 detail modal 改為全幅 showGeneralDialog（slide-from-bottom）；下滑手勢關閉；編輯模式亦全幅佈局（比例式照片 header + 表單 Expanded）。OOTD 分享卡 ClipRRect 移至 RepaintBoundary 外側，修正分享圖片圓角白邊問題 | Wardrobe / OOTD / UI |
| 2026-05-17 | 1.0.45+134 | 1.0.12 | 衣物 detail modal UI 重新設計：移除圖片下方白色資訊區塊，改以漸層 scrim 將類型、顏色、材質資訊疊壓在圖片上；編輯按鈕改為圖片右下角半透明鉛筆圓圈；Dialog 呈現全幅 3:4 照片 | Wardrobe / UI |
| 2026-05-16 | 1.0.44+133 | 1.0.12 | 衣物 detail modal 新增行內編輯模式：可調整種類（6個預設選項 pill 選擇）、顏色（12色桶圓形色票多選）、材質（12種常用材質多選）；儲存後即時更新本機 JSON sidecar；AI 顏色自動對應最近色桶預選 | Wardrobe / UI |
| 2026-05-15 | 1.0.43+132 | 1.0.12 | 新增統一分享頁 `OotdSharePage`：兩卡 PageView（原圖 + Lumi 品牌卡），品牌卡含漸層 Lumi chip、caption、日期浮水印、底部品牌條；分享時截圖品牌卡並呼叫 `Share.shareXFiles`；新增/詳情兩個入口皆導向此頁，移除原本分散的分享邏輯與互動式編輯器 | OOTD / Share / UI |
| 2026-05-08 | 1.0.29+118 | 1.0.3 | 新增 Apple ID 登入：`sign_in_with_apple` + `crypto` 套件；`signInWithApple()` 含 SHA-256 nonce 防重放；iOS `Runner.entitlements` + `project.pbxproj` 三組 build config 加 `CODE_SIGN_ENTITLEMENTS`；`signInLoadingProvider` 改為 `SignInMethod` enum 區分 Google / Apple；登入頁改為雙按鈕垂直排列（Apple 在上），subtitle 更新為「用 AI 點亮妳的衣櫥」 | Auth / iOS |
| 2026-05-07 | 1.0.28+117 | 1.0.3 | 後續清理：移除 `lib/core/photos/` 空目錄；清除 `auth_repository.dart` 中已廢棄的 Google Photos scope 歷史說明 comments | Auth / Cleanup |
| 2026-05-07 | 1.0.27+116 | 1.0.3 | 修正衣物卡片點擊無反應（`GestureDetector(onTap)` 外包 `InkWell(onLongPress)` 造成 gesture arena 衝突，改為 `onTap` 直接放在 `InkWell`）；改善 Cloud Functions 錯誤日誌（`analyzeClothing`/`compareClothing` catch block 改用 `formatFirebaseCallableError` 展開 `code`/`message`/`details`） | Search / Wardrobe / Snap |
| 2026-05-07 | 1.0.26+115 | 1.0.3 | 重新設計 Snap（加入新品）流程：新增相機拍攝入口、圖庫新增採合併模式（可累積至上限）、預覽頁每張縮圖加 X 移除按鈕、「＋ 新增」補位磚、更新所有 copy 至本地儲存語意（移除 Google Photos 上傳語言） | Snap |
| 2026-05-07 | 1.0.25+114 | 1.0.3 | 架構遷移至本地儲存（Local-First）：圖片存於手機 `lumi_wardrobe/` 目錄，iOS 由 iCloud Backup 自動備份，Android 新增 `backup_rules.xml` 及 `data_extraction_rules.xml` 設定 Google Auto Backup。移除所有 Google Photos OAuth / Drive 依賴（`google_photos_oauth.dart`、`google_photos_api_client.dart`、`wardrobe_google_sync.dart`、`thumbnail_repair_provider.dart`）；新增 `LocalImageStorage`；Snap 改為本地存圖 → Firestore doc（`analyzed: false`）→ 背景呼叫 `analyzeClothing` CF 寫回分析結果；顯示層改用 `Image.file`；`compareClothing` CF 回傳 `docId` + `localFileName`（移除 `mediaItemId` + `thumbnailUrl`）；刪除 CF：`uploadToPhotos`、`syncWardrobeFromPhotos`、`refreshWardrobeThumbnail`、`analyzeWardrobeItemOnCreate`、`retryAnalyzeWardrobeItem` | Architecture / Auth / Snap / Wardrobe / Search / Check / Cloud Functions / Android Backup |
| 2026-05-07 | 1.0.24+113 | 1.0.2 | 修正 Photos API 403 根本原因：`photoslibrary.readonly` scope 已於 2024 年底對未審核 app 停止授予；Google OAuth 實際回傳 `photoslibrary.readonly.appcreateddata`（子字串 match 造成 `hasReadonly=true` 偽陽性）。將 `kGooglePhotosReadonlyScope` 改為 `photoslibrary.readonly.appcreateddata`；`logTokenInfo` 及 `refreshThumbnailUrl` 新增 `hasAppCreated` flag 與完整 scopes 欄位以便後續診斷 | Auth / OAuth / Wardrobe Sync / Diagnostics |
| 2026-05-07 | 1.0.23+112 | 1.0.2 | 修正 nativeSync 403 retry 中 `signOut()` 導致的連環崩潰：`signOut()` 後 iOS `GIDSignIn.currentUser` 變 nil，`requestScopes` 拋出 `sign_in_required`，後續 sync 因 `account=null` 顯示「尚未登入 Google」；移除 retry 中的 `signOut()` 呼叫，直接對現有 session 執行 `forceRequestScopes: true`，讓 iOS consent dialog 正常彈出 | Auth / OAuth / Wardrobe Sync |
| 2026-05-07 | 1.0.22+111 | 1.0.2 | 修正 nativeSync 在 Photos API 連續兩次 403 時顯示 raw exception 的問題：第二次重試亦加 try/catch，403 → 友善的 StateError 引導使用者登出重新登入；重試前先 `signOut()` 以清除 in-memory 過時 session；`thumbnail_repair_provider` 新增 `_isPhotos403()` helper，讓背景縮圖修復對 native iOS 直接呼叫 Photos API 拋出的 `Exception` 403 正確觸發 auth backoff | Auth / OAuth / Wardrobe Sync / Thumbnail Repair |
| 2026-05-06 | 1.0.21+110 | 1.0.2 | 新增 OAuth client ID 診斷 log：GoogleSignIn 初始化時印 GOOGLE_CLIENT_ID dart-define；Photos API 呼叫前（refreshThumbnailUrl、sync）呼叫 tokeninfo 並印 aud（哪個 client 簽出 token）、azp、email、exp、hasReadonly，讓 aud vs GOOGLE_CLIENT_ID 比對可見 | Auth / Diagnostics |
| 2026-05-06 | 1.0.20+109 | 1.0.2 | native 衣櫥同步（syncWardrobeAlbumFromGooglePhotos）從 Cloud Function 轉移至 Flutter client 端：新建 `GooglePhotosApiClient`（GET /albums、POST /mediaItems:search）；native 路徑直接呼叫 Photos API 並以 Firestore batch write 寫入衣物 doc，不再把 access token 轉發給 CF（Google 拒絕 server-side token forwarding）；Web 路徑保持使用 CF（瀏覽器 CORS 限制） | Wardrobe Sync / Architecture |
| 2026-05-06 | 1.0.19+108 | 1.0.2 | CI 注入 `GIDClientID` 到 `Info.plist`（google_sign_in_ios 的 `requestScopes()` 需要此 plist key，純靠 Dart constructor `clientId` 不足）；`google_photos_oauth.dart` 對 `requestScopes` 加 `PlatformException` catch，避免 "No active configuration" crash 直接崩潰，改為回傳 null 讓 caller 顯示重新登入提示 | Auth / OAuth / CI |
| 2026-05-06 | 1.0.18+107 | 1.0.2 | 修正 Google OAuth「Unbundled Consent」政策違規：移除 GoogleSignIn constructor 及 signInWithPopup 中的 Photos scopes，改為僅在使用者明確觸發 Photos 相關功能時增量授權；這是導致 photoslibrary.readonly 即使使用者同意仍未寫入 token 的根本原因 | Auth / OAuth |
| 2026-05-06 | 1.0.17+106 | 1.0.2 | 移除 signInWithGoogle 中的 requestScopes 呼叫（iOS WKWebView completion timing 導致 token 未正確取得 photoslibrary.readonly）；改由 signIn() 一次取得所有 constructor scopes；wardrobe refreshThumbnailUrl 加入 tokeninfo 診斷 log，確認 token 實際帶的 scope | Auth / Wardrobe Thumbnail / Diagnostics |
| 2026-05-06 | 1.0.16+105 | 1.0.2 | 架構修正：iOS 縮圖刷新改為直接呼叫 Photos API（`kIsWeb` 判斷），不再經由 Cloud Function 轉發 token — Google 會拒絕 server-side token forwarding 並回 403，即使 token 確實帶有 `photoslibrary.readonly`；Web 仍走 Cloud Function（CORS 限制） | Wardrobe Thumbnail / Architecture |
| 2026-05-02 | 1.0.15+104 | 1.0.2 | 修正 iOS 上 photoslibrary.readonly scope 永遠無法取得的根本原因：`ensureGooglePhotosAccessToken` 新增 `forceRequestScopes` 參數；sync 流程在收到 403 後以 `forceRequestScopes: true` 重試，強制顯示授權同意畫面讓使用者補授 readonly scope；補對應單元測試 | Auth / OAuth / Wardrobe Sync / Tests |
| 2026-05-02 | 1.0.14+103 | 1.0.2 | 修正縮圖 403 永久 loop：`_repairOne` 收到 readonly scope 不足時先嘗試 clearCacheFirst 取新 token，不再直接進入 backoff；snap_provider 上傳 token 同時申請 appendonly+readonly scope；新增衣物刪除功能（Repository `deleteItem` + 衣物卡片長按確認刪除）；補 `deleteItem` 單元測試 | Auth / Wardrobe Thumbnail / Snap / UI / Tests |
| 2026-05-01 | 1.0.13+102 | 1.0.2 | 底部導航改為浮動 Glassmorphic pill：LumiColors.base 70% opacity + BackdropFilter blur、xl 圓角、primaryFixed 圓形光暈指示 active tab、text/subtext icon 色，符合 DESIGN.md Bottom Navigation 規範 | UI / Navigation |
| 2026-05-01 | 1.0.12+101 | 1.0.2 | 全 App 設計 token 審查：所有畫面的 hardcode fontSize、BorderRadius、Padding 替換為 LumiTypeScale / LumiRadii / LumiSpacing token；修正 onboarding/check/ootd_add 缺少 lumi_radii & lumi_type_scale import；snap 上傳進度圓圈改為 116×116 顯式尺寸 | UI / Design System（所有頁面）|
| 2026-04-30 | 1.0.11+100 | 1.0.2 | 修正 uploadToPhotos INTERNAL 錯誤：移除依賴 readonly scope 的 baseUrl fallback GET，batchCreate 無 baseUrl 時改回傳空字串（由縮圖刷新補填）；加 console.error 保留 CF log；客戶端設定 5 分鐘 timeout；thumbnailUrl 空字串不再觸發 FormatException | Snap / Upload / Cloud Functions |
| 2026-04-30 | 1.0.11+99 | 1.0.1 | 上傳前偵測 JPEG magic bytes（FF D8），若 image_picker 已轉為 JPEG（HEIC/PNG 等），自動使用 image/jpeg MIME type 與 .jpg 副檔名，減少上傳大小並避免 Photos API HEIC 相容問題 | Snap / Upload |
| 2026-04-30 | 1.0.11+98 | 1.0.1 | 修正衣櫥重新整理按鈕在 iOS 會彈出 Google 帳號選擇器的登入循環（改用 currentUser/signInSilently 取代 signIn()）；uploadToPhotos Cloud Function 加上 300s timeout 與 512MiB 記憶體，修正大圖上傳逾時導致的「伺服器忙碌中」錯誤 | Auth / Snap / iOS / Cloud Functions |
| 2026-04-21 | 1.0.11+93 | 1.0.0 | 互動授權流程強制刷新 Google Photos token 並重新驗 scope；背景縮圖修復把 scope 不足視為等待下一次互動授權，避免進衣櫥就大量 403；同步失敗時補上瀏覽器阻擋 popup 的中文提示 | Auth / Wardrobe Thumbnail / OAuth / UX |
| 2026-04-21 | 1.0.10+91 | 1.0.0 | 互動授權流程強制刷新 Google Photos token 並重新驗 scope；背景縮圖修復把 scope 不足視為等待下一次互動授權，避免進衣櫥就大量 403 | Auth / Wardrobe Thumbnail / OAuth |
| 2026-04-20 | 1.0.9+90 | 1.0.0 | 將 GitHub Actions / Deploy workflow 的 Flutter 版本升級到 3.29.1，讓 CI 與程式碼使用的新版 Flutter API 對齊；補充 repo 級與 skill 級規範，統一未來處理方式 | CI / Tooling / Process |
| 2026-04-20 | 1.0.8+89 | 1.0.0 | 清理 Flutter analyze 舊版 API 與 node_modules 掃描問題；新增 Search 頁縮圖修復狀態指示；補直接依賴 web 套件 | Tooling / Search / Logging / Tests |
| 2026-04-20 | 1.0.7+88 | 1.0.0 | 將縮圖修復改為 Search 頁集中批次協調、去重與限流；console log 改為批次摘要；卡片舊縮圖先顯示 placeholder；補候選判定測試 | Wardrobe Thumbnail / Search / Logging / Tests |
| 2026-04-20 | 1.0.6+87 | 1.0.0 | 背景縮圖刷新遇到 Google Photos 401 時先清除快取 token 並靜默重抓一次；Cloud Function 將 401 映射為 unauthenticated；補 OAuth 測試 | Auth / Wardrobe Thumbnail / Functions / Tests |
| 2026-04-20 | 1.0.5+86 | 1.0.0 | 禁止把 Google Photos `productUrl` / `photos.google.com` 連結寫入縮圖欄位；UI 對舊資料改顯示 placeholder；補 repository 測試 | Wardrobe Thumbnail / UI / Tests |
| 2026-04-20 | 1.0.4+85 | 1.0.0 | 修正 Google Photos token scope 驗證，避免背景縮圖刷新誤送 appendonly token；補 OAuth 單元測試；同步對齊前端版本號 | Auth / Wardrobe Thumbnail / Tests |
| 2026-04-20 | 1.0.3+83 | 1.0.0 | 建立前後端分離版本欄位；新增 PRD 版本歷史章節並規範固定置底 | PRD / Process |
