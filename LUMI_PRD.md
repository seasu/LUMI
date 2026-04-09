# Lumi 產品規格書 (Product Requirements Document)

**專案名稱：** Lumi
**口號：** *Light up your wardrobe with Google Photos.*
**版本：** 1.0.0
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

| 階段 | 功能 | 目標 |
|------|------|------|
| M1 | 專案初始化、Google 登入、CI/CD 骨架 | 可登入、可建置 |
| M2 | Lumi Snap（拍照 + AI 分析 + 上傳） | 核心入庫流程跑通 |
| M3 | Lumi Search（衣物列表 + 色彩篩選） | 可瀏覽衣櫥 |
| M4 | Lumi-Check（查重比對） | 主打功能上線 |
| M5 | UI 精修、效能優化、TestFlight Beta | 對外測試 |
