# Lumi 產品規格書 (Product Requirements Document)

**專案名稱：** Lumi
**口號：** *Light up your wardrobe with Google Photos.*
**前端版本 (Flutter App)：** 1.0.28+117
**後端版本 (Cloud Functions)：** 1.0.3
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
