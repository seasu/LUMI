# CLAUDE.md — Lumi 專案 AI 工作手冊

> 每次進入此 repo 的 AI，請先完整讀完這份文件。
> 完整規格請見 [LUMI_PRD.md](./LUMI_PRD.md)。

---

## 開發方式

**本專案透過 Claude Code 開發。** 人類負責描述需求，Claude Code 負責寫程式碼、執行指令、提交 commit。開發者不直接在 terminal 輸入指令。

### 工作流程

```
使用者描述需求
  → Claude Code 讀取相關檔案
  → Claude Code 撰寫/修改程式碼
  → Claude Code 執行驗證指令（test / analyze）
  → Claude Code commit & push 至指定分支
  → GitHub Actions 接手建置與分發
```

### Claude Code 可執行的驗證指令

```bash
flutter test                                          # 執行測試
flutter analyze                                       # 靜態分析
flutter pub get                                       # 更新依賴
dart run build_runner build --delete-conflicting-outputs  # 產生 Riverpod 程式碼
firebase emulators:start --only firestore,auth,functions  # 啟動本地模擬器
```

> **禁止執行**：`flutter build ios`、`flutter build appbundle` 等正式版建置指令。
> 所有 Release 建置必須透過 GitHub Actions 觸發。

## 專案一句話

Lumi 是一款 Flutter App，讓使用者用 Google Photos 管理衣櫥，並透過 Gemini AI 實現智慧分類與購物查重。

---

## 需求處理流程

收到新需求時，依序執行：

1. **確認範圍**：對照 `LUMI_PRD.md`，確認需求是否在規格內。若超出範圍，先告知使用者再討論是否納入。
2. **架構評估**：呼叫 `/arch`，確認 ADR 合規性與資料流設計。
3. **開分支**：從 `develop` 建立 `feature/簡短描述` 分支再開始實作。
4. **同步寫測試**：實作過程中參照 `/test`，每個功能同步產出 unit test + widget test。
5. **完成後開 PR**：目標分支為 `develop`，格式見下方 PR 規範。

---

## 分支策略

| 分支 | 用途 |
|------|------|
| `main` | 正式發布，受保護，只接受 PR merge |
| `develop` | 日常開發主線 |
| `feature/*` | 新功能開發 |
| `fix/*` | Bug 修復 |

**所有 PR 須 merge 至 `develop`，`develop` 穩定後再 merge 至 `main` 觸發發布。**

### Hotfix 流程

線上緊急 bug 處理方式：

1. 從 `main` 建立 `hotfix/簡短描述` 分支
2. 修復後以 `fix:` 前綴 commit（自動觸發 Patch 版號更新）
3. 開兩個 PR：一個 merge 至 `main`，一個 merge 至 `develop`（保持同步）

---

## Commit Message 規範

本專案使用 Conventional Commits，GitHub Actions 依此自動更新版號。**格式錯誤會導致版號不更新。**

```
feat: 新增 Lumi-Check 購物模式入口
fix: 修正 Google Photos baseUrl 過期導致的圖片載入失敗
chore: 更新 firebase_core 至 2.x
docs: 補充 Firestore Security Rules 說明
refactor: 拆分 WardrobeRepository 為獨立 Provider
```

| 前綴 | 版號影響 |
|------|---------|
| `feat:` | Minor 版號 +1（1.0.0 → 1.1.0） |
| `fix:` | Patch 版號 +1（1.0.0 → 1.0.1） |
| 其他 | 不更新版號 |

---

## PR 規範

- **目標分支**：一律為 `develop`（hotfix 例外，見上方）
- **標題格式**：同 Commit Message 規範（`feat:` / `fix:` 開頭）
- **描述必填**：
  - 這個 PR 做了什麼（1–3 行）
  - 如何測試（測試步驟或截圖）
- **Merge 條件**：CI（flutter analyze + flutter test）全部通過
- **禁止**：直接 push 至 `main` 或 `develop`，一律走 PR

---

## 測試規範

每個新功能必須在**同一個 PR**內包含對應測試，不得事後補寫。

| 功能類型 | 必寫測試 |
|---------|---------|
| Repository / Service | Unit test |
| Widget / Page | Widget test |
| 完整使用者流程 | Integration test（M2 起） |

詳細測試模板與各里程碑驗收標準，參照 `/test` Skill。

---

## 架構決策紀錄（ADR）

這些是已確認的架構決策，不得在未討論的情況下推翻。

### ADR-001：Google Photos 只存圖，Metadata 存 Firestore

**決策**：所有 AI 分析結果（顏色、材質、特徵向量）存於 Firestore，以 `mediaItemId` 作為關聯鍵。Google Photos 僅作為相片儲存媒介。

**原因**：Google Photos API 的 `description` 欄位為唯讀（App 無法更新），且無法儲存特徵向量這類結構化資料。

### ADR-002：AI 推論必須走 Firebase Cloud Functions

**決策**：所有 Gemini API 呼叫必須透過 Firebase Cloud Functions，客戶端不持有 Vertex AI 憑證。

**原因**：Flutter 打包後 APK/IPA 可被反編譯，直接嵌入 API Key 會造成金鑰外洩。

### ADR-003：Google Photos API 範圍限制

**決策**：Lumi 只能存取 App 自己上傳的相片（非使用者整個 Google Photos 相簿）。

**原因**：Google Photos Library API 自 2021 年起，第三方 App 只能讀取透過該 App 上傳的媒體。入庫必須透過 Lumi Snap 拍照，不支援匯入現有相片。

### ADR-004：Lumi-Check 特徵向量比對（M4 前暴力比對）

**決策**：M4 初版使用 Cloud Functions 全量 cosine similarity 計算。衣物超過 200 件後，評估遷移至 Vertex AI Vector Search。

---

## Firestore Schema

```
users/{userId}/
  └── wardrobe/{mediaItemId}/
        ├── mediaItemId: string       # Google Photos mediaItem ID
        ├── category: string          # "上衣" | "褲子" | "外套" | "配件" | "鞋子"
        ├── colors: string[]          # ["#3B5BDB", "#FFFFFF"]
        ├── materials: string[]       # ["棉", "聚酯纖維"]
        ├── embedding: float[]        # Gemini 產生的特徵向量，用於 Lumi-Check
        ├── thumbnailUrl: string      # Google Photos baseUrl（60 分鐘有效，需動態刷新）
        └── createdAt: timestamp
```

---

## 安全性規範

產生或修改程式碼時，必須遵守以下規則：

1. **禁止在 Flutter 端 hardcode 任何 API Key、Secret 或 Service Account**。
2. **所有 Firestore 操作須受 Security Rules 保護**，規則必須驗證 `request.auth.uid == userId`。
3. **Cloud Functions 的所有端點須驗證 Firebase Auth ID Token**，拒絕未認證請求。
4. **Google OAuth scope 最小化原則**：只申請實際需要的 scope，目前為 `photoslibrary.appendonly`（上傳）與 `photoslibrary.readonly`（讀取 Lumi 上傳的內容）。
5. **`thumbnailUrl` 不可持久化至本機快取超過 55 分鐘**，需在過期前向 Google Photos API 刷新。

---

## UI/UX 快速參考

**設計風格**：Neo-Minimalism，輕盈如光影，無粗線條與沉重陰影。

```dart
// 色彩常數（統一從這裡引用，不得 hardcode 顏色值）
static const colorBase    = Color(0xFFF5F5F7); // 主背景
static const colorSurface = Color(0xFFFFFFFF); // 卡片
static const colorGlow    = Color(0xFFAEE2FF); // AI 處理動畫
static const colorText    = Color(0xFF1D1D1F); // 主文字
static const colorSubtext = Color(0xFF6E6E73); // 次要文字
static const colorWarning = Color(0xFFFF6B35); // Lumi-Check 警示（橘紅，非純紅）
```

**互動規則**
- AI 處理中：使用 `colorGlow` 脈衝光暈動畫，**不使用** CircularProgressIndicator。
- 衣物卡片：無邊框，用留白建立層次，`borderRadius: 16`。
- Lumi-Check 警示：橘紅漸層橫幅，**不使用**純紅色警告。

---

## 環境變數與 Secrets

**開發環境**：在專案根目錄建立 `.env`（已加入 `.gitignore`），格式如下：

```
FIREBASE_PROJECT_ID=lumi-app-dev
GOOGLE_CLIENT_ID_IOS=xxx.apps.googleusercontent.com
GOOGLE_CLIENT_ID_ANDROID=xxx.apps.googleusercontent.com
```

**GitHub Actions Secrets**（由 repo 管理員設定，AI 不可修改）：

| Secret 名稱 | 用途 |
|------------|------|
| `ANDROID_KEYSTORE_BASE64` | Android 簽署用 Keystore（Base64） |
| `ANDROID_KEY_ALIAS` | Keystore alias |
| `ANDROID_KEY_PASSWORD` | Key 密碼 |
| `ANDROID_STORE_PASSWORD` | Store 密碼 |
| `MATCH_PASSWORD` | Fastlane Match 憑證加密密碼 |
| `MATCH_GIT_URL` | Fastlane Match 憑證私有 repo URL |
| `FIREBASE_SERVICE_ACCOUNT` | Firebase App Distribution 服務帳戶 JSON |

---

## 里程碑現況

| 階段 | 功能 | 狀態 |
|------|------|------|
| M1 | 專案初始化、Google 登入、CI/CD 骨架 | 進行中 |
| M2 | Lumi Snap（拍照 + AI 分析 + 上傳） | 待開始 |
| M3 | Lumi Search（衣物列表 + 色彩篩選） | 待開始 |
| M4 | Lumi-Check（查重比對） | 待開始 |
| M5 | UI 精修、效能優化、TestFlight Beta | 待開始 |

---

## 可用 Skills（AI 應主動判斷時機呼叫）

| Skill | 呼叫時機 |
|-------|---------|
| `/ui` | 建立或修改任何 Flutter 介面相關程式碼時（Widget、頁面佈局、導航、動畫、狀態呈現、互動設計），主動參照設計規範 |
| `/style` | 撰寫任何 Dart 程式碼時，主動參照命名規範、目錄結構、Riverpod 模式 |
| `/arch` | 實作新功能前，先評估架構可行性與 ADR 合規性 |
| `/security` | 每次 commit 前，對本次改動執行安全掃描 |
| `/google-photos` | 任何涉及 Google Photos API 的程式碼，主動參照 API 限制與正確用法 |
| `/test` | 實作新功能時，同步撰寫對應測試；或需要查閱各里程碑驗收標準時 |
| `/marketing` | 使用者要求撰寫 App Store 說明、版本更新說明、社群文案時 |

---

## 語言規範

**所有回覆必須使用繁體中文。** 包含說明、提問、錯誤訊息解讀、commit message 以外的所有文字溝通。
程式碼、指令、變數名稱、commit message 本身維持英文。

---

## 給 Claude Code 的工作原則

1. **先讀後改**：修改任何檔案前，先用 Read 工具讀取現有內容。
2. **最小修改原則**：只改任務要求的部分，不順手重構無關程式碼。
3. **驗證後再 commit**：每次程式碼修改後，先執行 `flutter analyze` 與 `flutter test` 確認無誤，再 commit。
4. **安全第一**：發現任何違反上方安全規範的程式碼，立即標記並修正，不等使用者提出。
5. **ADR 優先**：若新需求與 ADR 衝突，先向使用者提出討論，不自行推翻已確認的架構決策。
6. **Commit 格式**：所有 commit 必須符合 Conventional Commits 規範（見上方），確保自動版號正常運作。
7. **不建 Release**：禁止執行 `flutter build` 正式版建置，一律由 GitHub Actions 負責。
