# CLAUDE.md — Lumi 專案 AI 工作手冊（**唯一完整 AI 規範**）

> **適用對象**：在本 repo 內協作的 AI 助理（含 **Cursor Agent**、Claude Code 等）。進入任務前請先讀完本文件。  
> **Cursor**：`.cursor/rules/ui-scale.mdc` 只做路標；**本檔為唯一詳述來源**。  
> 完整產品規格見 [LUMI_PRD.md](./LUMI_PRD.md)。

---

## 開發方式

人類描述需求；**AI 助理**負責讀檔、改程式、在可執行環境下跑驗證指令、依流程提交與推送。**若工作區允許**，由 AI 透過終端機執行 `flutter` / `git` 等指令並非禁止事項。

### 建議工作流程

```
使用者描述需求
  → 讀取相關檔案（先讀後改）
  → 撰寫／修改程式碼
  → 執行驗證（flutter analyze、flutter test；依任務可加 functions build 等）
  → commit 與 push 至約定分支
  → GitHub Actions 建置、部署、CI
```

### 可執行的驗證指令（依環境調整）

```bash
flutter test                                              # 測試
flutter analyze                                           # 靜態分析
flutter pub get                                           # 依賴
dart run build_runner build --delete-conflicting-outputs # 產生 Riverpod 等程式碼
cd functions && npm run build                             # Cloud Functions TypeScript 編譯
firebase emulators:start --only firestore,auth,functions  # 本機模擬器（已安裝 firebase-tools 時）
```

**Cloud Functions — Gemini 模型名稱**（非金鑰）：預設、deprecated 清單與 vision／embedding **fallback 鏈**皆由 **`functions/scripts/generate-gemini-defaults.mjs`** 依 GitHub **Variables** 在 CI 寫入 **`geminiDefaults.generated.ts`**；**`gemini.ts`** 為唯一實際呼叫 `getGenerativeModel` 之處。執行時覆寫見 **`functions/ENV.md`**。

> **禁止**：`flutter build ios`、`flutter build appbundle` 等**正式發佈用**本機建置（專案規範由 CI 處理 Release）。  
> **Flutter Web**：本機除錯需自行帶上與 Firebase／Google 相關的 `--dart-define`（對照 `lib/core/config/firebase_options.dart`、`.env.example`）；GitHub Pages 正式站由 Actions secrets 注入。

---

## 專案一句話

Lumi 是一款 Flutter App，讓使用者用 Google Photos 管理衣櫥，並透過 Gemini AI 實現智慧分類與購物查重。

---

## 設計規範唯一來源（必讀）

- UI/UX 實作**唯一**設計規範檔為 **`DESIGN.md`**。
- **禁止**再新增或引用平行版設計規範檔（例如已移除的 `DESIGN_GUIDELINES.md`）。
- **Figma** 若與 `DESIGN.md` 不一致：先整理**差異清單**，與使用者確認後再實作。
- 未經確認不得擅自覆寫 `DESIGN.md` 既有 token（顏色、字級、間距、圓角）或互動規則。

---

## 需求處理流程

收到新需求時建議依序：

1. **確認範圍**：對照 `LUMI_PRD.md`；超出規格先說明並討論。
2. **架構與 ADR**：閱讀本文件「架構決策紀錄（ADR）」小節；必要時檢視 `functions/`、`lib/core` 資料流是否符合 ADR。
3. **分支**：依團隊約定從 **`main`** 開分支（例如 `feature/簡述`、`fix/簡述`，或 Cursor Cloud 約定的 `cursor/<名稱>-<suffix>`）；**禁止**直接 push 至 `main`。
4. **測試**：新邏輯／新 UI 在同一 PR 內附對應 **unit / widget test**（見下方測試規範）。
5. **PR**：合併目標為 **`main`**（見 PR 規範）。

---

## 分支策略

| 分支 | 用途 |
|------|------|
| `main` | 預設分支；受保護；接受 PR merge；merge 後觸發 GitHub Pages 等部署流程 |
| `feature/*`、`fix/*`、`cursor/*` 等 | 開發與修復用功能分支 |

**Hotfix**：自 `main` 開 `hotfix/簡述` → `fix:` 開頭 commit → PR 回 `main`。

---

## Commit Message 規範

使用 **Conventional Commits**；GitHub Actions 會依此自動調整版號。**格式錯誤可能導致版號不更新**。

```
feat: 新增 Lumi-Check 購物模式入口
fix: 修正 Google Photos baseUrl 過期導致的圖片載入失敗
chore: 更新 firebase_core 至 2.x
docs: 補充 Firestore Security Rules 說明
refactor: 拆分 WardrobeRepository 為獨立 Provider
```

| 前綴 | 版號影響 |
|------|---------|
| `feat:` | Minor +1 |
| `fix:` | Patch +1 |
| 其他 | 通常不升版號 |

---

## PR 規範

- **目標分支**：**`main`**
- **標題**：與 Commit 規範一致（例如 `feat:`、`fix:` 開頭）
- **描述**：做了什麼（精簡）＋如何驗證
- **Merge 條件**：CI（如 `flutter analyze`、`flutter test`）通過
- **禁止**：略過 PR 直接 push `main`

若環境提供 **PR／CI 管理工具**，於 push 後建立或更新對應 PR；否則在回覆中給出手動建 PR 的**分支名稱、標題、描述**。

---

## 測試規範

新功能應在**同一 PR** 內包含測試，避免「先合併再補」。

| 類型 | 測試 |
|------|------|
| Repository / Service | Unit test |
| Widget / Page | Widget test |
| 完整使用者流程 | Integration test（里程碑需要時） |

細節可對照專案內測試檔與里程碑驗收標準。

---

## 架構決策紀錄（ADR）

未經討論不得推翻。

### ADR-001：Google Photos 只存圖，Metadata 存 Firestore

AI 分析結果（顏色、材質、embedding 等）存 **Firestore**，以 `mediaItemId` 關聯；Google Photos 僅存圖。

### ADR-002：AI 推論必須走 Firebase Cloud Functions

Gemini 等呼叫經 **Cloud Functions**；客戶端不內嵌 Vertex AI 憑證。

### ADR-003：Google Photos API 範圍

第三方 App 僅能可靠讀取**透過本 App 上傳**的媒體；入庫以 Lumi Snap／上傳流程為準。

### ADR-004：Lumi-Check 比對

初版於 Functions 端做相似度；規模大可再評估 Vector Search。

---

## Firestore Schema（摘要）

```
users/{userId}/
  └── wardrobe/{mediaItemId}/
        ├── mediaItemId, category, colors, materials, embedding,
        ├── thumbnailUrl, createdAt, …
```

詳細欄位以程式與規格為準。

### Google Photos：Firestore／App 該存哪種「路徑」（對齊官方）

以下對齊 [Photos API Best practices — Caching](https://developers.google.com/photos/overview/best-practices)、[Access app-created media items](https://developers.google.com/photos/library/guides/access-media-items)（含 MediaItem 欄位、`baseUrl`／`productUrl`、`Base URLs`）。

| 做法 | 說明 |
|------|------|
| **長期保存** | **`mediaItemId`**（以及必要時 album id）— 官方明確允許長期存放，用來呼叫 `mediaItems.get` / `batchGet` **重新取得**最新 `MediaItem`。 |
| **不要當永久真相** | **`baseUrl`** — 官方約 **60 分鐘**過期（Library API）；Best practices 亦寫不宜依賴長期快取 **`baseUrl`**。若要在 Firestore 存 **`thumbnailUrl`**（快取）：視為 **短期**，並在過期前用 **`mediaItemId` + OAuth** 呼叫 API 刷新（見 `wardrobe_repository.refreshThumbnailUrl`、`thumbnailRefreshedAt`）。 |
| **顯示縮圖／下載像素** | 使用 API 回傳的 **`baseUrl`**，並依 [Base URLs — Image](https://developers.google.com/photos/library/guides/access-media-items#base-urls) **加上維度等參數**（例如 `=w2048-h2048`）；CDN 主機通常為 **`lh3.googleusercontent.com`** 這類形態。 |
| **禁止當 Flutter 圖檔來源** | **`productUrl`** 以及 **`https://photos.google.com/...`** 這類 **相簿／相片網頁連結** — 官方：`productUrl` 是「在 Google 相簿 UI 裡開給使用者看的連結」，**不是**開發者用來抓 raw bytes 的網址；網頁 URL 回傳 **HTML**，`Image.network` 無法解成圖。 |

**AI 修改衣櫥縮圖／同步／寫入 Firestore 時**：不得以瀏覽器複製的 `photos.google.com/album/.../photo/...` 取代 **`baseUrl`**；新建或修資料時以 **`mediaItemId` + API** 為準。

---

## 安全性規範

1. **禁止**在 Flutter 端 hardcode API Key、Secret、Service Account JSON。
2. Firestore 依 **Security Rules**；寫入規則應綁定 `request.auth.uid`。
3. Cloud Functions 應驗證 **Firebase Auth**，拒絕未認證請求。
4. Google OAuth **最小 scope**；實際請求 scope 見 `lib/core/providers/firebase_providers.dart`。
5. **`thumbnailUrl`** 須為 API 之 **`baseUrl`（含尺寸參數之快取）**，約 60 分鐘內依設計刷新；見上方「Google Photos：Firestore／App 該存哪種路徑」。

細部 checklist 見 [SECURITY.md](./SECURITY.md)。

---

## UI/UX 快速參考

（可選）**版面參考圖**（Stitch mockup，repo 內 `design/`）：

- `design/lumi_welcome_screen.png` — 登入頁
- `design/lumi_wardrobe_dashboard.png` — 衣櫥主頁
- `design/lumi_check_shopping_mode.png` — Lumi-Check 購物模式

實作仍以 **`DESIGN.md`** 與程式 token 為準；參考圖僅供構圖／層次對照，若與 `DESIGN.md` 不一致，以 **`DESIGN.md`** 為優先。

設計語言與 token 以 **`DESIGN.md`** 為準；程式中請優先使用：

- `lib/shared/constants/lumi_colors.dart` — `LumiColors`
- `lib/shared/constants/lumi_spacing.dart` — `LumiSpacing`
- `lib/shared/constants/lumi_radii.dart` — `LumiRadii`
- `lib/shared/constants/lumi_type_scale.dart` — `LumiTypeScale`

### Flutter UI 刻度（修改 `lib/**/*.dart` 時）

1. **Spacing** — 使用 `LumiSpacing`；以 8px 為主；頁面水平留白常見 `md`／`lg`，非對稱邊距可照 `DESIGN.md`。
2. **Radius** — 使用 `LumiRadii`，避免到處 `BorderRadius.circular(…)` 魔數（除非與既有元件一致）。
3. **字級** — 使用 `LumiTypeScale`；全 App 內文透過 Theme 使用 **Noto Sans TC**；草寫字標僅限 logo widget。
4. **驗證** — 實質修改 UI 後執行 `flutter analyze`；行為變更時加跑相關測試。

色票與 Theme 的硬性規則見下一節。

---

## 色票與 Theme（AI 必守 — 禁止在畫面上 hardcode 顏色）

目標：**全 App 視覺與 `DESIGN.md`、`LumiColors`、`ThemeData` 一致**，避免在各 Widget 散落 `Colors.white`、`Color(0x…)`。

### 規則

1. **數值來源**：品牌色只看 **`DESIGN.md`** → 實作對應 **`lib/shared/constants/lumi_colors.dart`**（`LumiColors`）。調色時**優先改 `LumiColors`**，不要在新畫面再寫一組 hex。
2. **Theme 為中心**：全域語意（主色、背景、標題／內文、錯誤）必須經 **`lib/shared/theme/lumi_theme.dart`** 的 **`buildLumiTheme()`**；`MaterialApp` 已套用，**在有 `context` 的 Widget 優先使用**：
   - `Theme.of(context).colorScheme.primary` / `onPrimary` / `surface` / `onSurface` / `onSurfaceVariant` / `error` / …
   - `Theme.of(context).textTheme`（字型階層已由 Noto Sans TC 設定）
3. **禁止**在 `lib/**/*.dart`（一般 UI）使用：
   - `Colors.white`、`Colors.black`、`Colors.grey`、`Colors.blue` 等 Material 調色板當**畫面色**
   - 任意 **`Color(0xFFxxxxxx)`**（**例外**：僅限 **`lumi_colors.dart`**、**`lumi_theme.dart`**；以及 **衣物顏色篩選用的色票資料**，見 `filter_bar.dart`）
4. **常用對照**：主色／漸層按鈕上的文字與 loading → **`colorScheme.onPrimary`** 或 **`LumiColors.onPrimary`**（與 theme 同步）；對話筐遮罩 → **`LumiColors.overlayBarrier`**；全暗拍攝頁底色 → **`LumiColors.overlayDark`**。
5. **`Material` 透明度**：請用 **`LumiColors.xxx.withOpacity(...)`** 或 **`colorScheme` 已有角色**，不要用硬編碼 rgba。
6. **例外**：`Colors.transparent`、`debug` 用途、**篩選器色票**（代表實際衣物顏色）可維持獨立常數區塊；若新增類似「資料用色票」請集中註明為 **data swatch**，不要與品牌 UI 混淆。

AI 修改任何 Flutter UI 時，應預設遵守以上條款；若有合理例外，在同一 PR **註解說明原因**。

---

## 環境變數與 Secrets

- **本機**：可自行維護 `.env`（未追蹤 git）作為數值參考；Flutter Web 仍以 **`--dart-define`** 注入為準。
- **GitHub Actions**：`FIREBASE_*`、`GOOGLE_CLIENT_ID` 等由 repo **Secrets** 設定；AI **不得**假設能替使用者寫入 GitHub Secrets。

---

## 里程碑現況（摘要）

Web 優先完成 M1–M4；Native（M5+）待後續階段。詳見 `LUMI_PRD.md`。

---

## Cursor／IDE 規則檔

**`.cursor/rules/ui-scale.mdc`** 僅提醒編輯 `lib/**/*.dart` 時要先讀 **本檔（CLAUDE.md）**，不重複貼規則全文。若任何 `.mdc` 與本檔或 **`DESIGN.md`**、**ADR** 衝突，以 **`DESIGN.md`**、**ADR**、**本檔** 為準。

---

## 語言規範

- 對使用者的說明、討論：**繁體中文**。
- 程式碼、指令、變數名、**commit message**：英文。

---

## Session 恢復流程

新對話開始處理任務前，若可執行 git，建議快速確認：

1. `git status`
2. `git log --oneline -5`
3. `git branch --show-current`

若有未提交變更或明顯進行中任務，先向使用者簡述狀態再繼續。

---

## 長任務分段策略

範圍大時拆段執行：每段有意義的進度即 **commit**（可用 `[1/3]` 這類標記），避免單一巨大 diff、利於中斷恢復。

---

## 卡住時的處理規則

`flutter analyze` / `flutter test`（或 functions `npm run build`）失敗時：

- 先分析錯誤與修正，**有限次**重試（避免無限迴圈與消耗 context）。
- 若多次仍失敗：條列錯誤摘要、已嘗試作法、可能原因與 2–3 個可行方向，交給使用者決策。

---

## 給 AI 助理的工作原則

1. **先讀後改**：改檔前先讀既有內容與呼叫點。
2. **最小修改**：只做任務需要的變更，避免無關重構。
3. **驗證再提交**：修改後盡量跑 `flutter analyze` 與 `flutter test`（及相關 build）；通過再 commit。
4. **安全與 ADR**：違反安全或 ADR 時先指出或修正；需推翻 ADR 時必須與人類確認。
5. **色與 Theme**：遵守上方「色票與 Theme」；**禁止**在一般 UI 程式碼 hardcode `Colors.*` 或 `Color(0x…)`（見該節例外列表）。
6. **Conventional Commits**：維持版號與 CI 習慣一致。
7. **不自己做 Release 建置**：正式 `flutter build` 發佈交由 CI／人類流程。
8. **做完要回報**：commit / push 後簡述**做了什麼**、**動了哪些路徑**、**後續建議**。

---

## 舊版「Slash Skills」對照（本環境無指令時）

舊文件中的 `/ui`、`/arch`、`/test` 等：**沒有**內建指令引擎時，改為實際行為：

| 舊標記 | 改做什麼 |
|--------|----------|
| `/ui` | 讀 **`CLAUDE.md`**（含 DESIGN、token、色票 Theme）與 `DESIGN.md` |
| `/style` | 對照既有 `lib/` 命名、Riverpod 用法與 **`CLAUDE.md`** |
| `/arch` | 對照本文件 ADR 與相關 `lib/`、`functions/` 資料流 |
| `/security` | 對照本文件安全性與 `SECURITY.md` |
| `/google-photos` | 對照 ADR、Photos API 與 `functions/` 實作 |
| `/test` | 撰寫／更新測試並跑 `flutter test` |

---

本文件沿用檔名 **CLAUDE.md** 以利既有工具與連結；內容已通用化為 **Lumi repo 內所有 AI 助理**的共用規範。
