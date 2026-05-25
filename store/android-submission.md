# Android Google Play 外部測試送審指南

本文件說明如何將 Lumi 發佈至 **Google Play 外部測試（Open Testing）**，供外部使用者測試。

---

## 前置作業

### 1. Google Play Console 帳號與 App

- 確認擁有 **Google Play Developer** 帳號（一次性 $25 USD 註冊費）
- 登入 [Google Play Console](https://play.google.com/console)
- 確認已建立 App：**Package name = `io.github.seasu.lumi`**
  - 若尚未建立：Play Console → 建立應用程式 → 填入應用程式名稱與 Package name

### 2. Firebase App Distribution（目前 CI 使用的管道）

Lumi 目前的 Android CI（`.github/workflows/mobile-firebase-app-distribution.yml`）使用 **Firebase App Distribution** 發佈，而非直接上傳至 Google Play。

若要改用 **Google Play 外部測試**，有兩種方案：

| 方案 | 說明 | 建議 |
|------|------|------|
| **Firebase App Distribution**（現有） | 直接發 APK 給指定測試者 | 快速、彈性，適合早期測試 |
| **Google Play Open Testing**（本指南） | 上傳 AAB 至 Play Console，公開外部測試 | 適合接近正式上架前的測試 |

> 本指南主要說明 **Google Play 外部測試**路徑。若使用 Firebase App Distribution，請見本文末尾的補充說明。

---

## GitHub Secrets 清單

### Firebase App Distribution（現有 CI）

在 GitHub → Settings → Secrets and variables → Actions 確認以下 Secrets 已設定：

| Secret 名稱 | 說明 | 取得方式 |
|-------------|------|---------|
| `ANDROID_KEYSTORE_BASE64` | Android 簽名 Keystore（.jks）的 Base64 | `base64 -w 0 upload-keystore.jks` |
| `ANDROID_STORE_PASSWORD` | Keystore 密碼 | 建立 Keystore 時設定 |
| `ANDROID_KEY_ALIAS` | Key Alias | 建立 Keystore 時設定 |
| `ANDROID_KEY_PASSWORD` | Key 密碼 | 建立 Keystore 時設定 |
| `FIREBASE_ANDROID_GOOGLE_SERVICES_JSON_BASE64` | Firebase Android 設定檔的 Base64 | Firebase Console → 專案設定 → Android App → 下載 google-services.json → `base64 -w 0 google-services.json` |
| `FIREBASE_TOKEN` | Firebase CLI Token | `firebase login:ci` 取得 |

### 若改用 Google Play CI（需新增）

| Secret 名稱 | 說明 |
|-------------|------|
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Google Play API 服務帳號 JSON（Base64）|

---

## 方案 A：使用現有 Firebase App Distribution

### 觸發方式

**自動觸發**：push 至 `main` 分支，且修改了以下路徑的檔案：
- `lib/**`
- `android/**`
- `pubspec.yaml`
- `pubspec.lock`

**手動觸發**：
1. GitHub → Actions → **Android Deploy to Firebase App Distribution**
2. **Run workflow** → 填入：
   - `tester_groups`：測試者群組名稱（需預先在 Firebase App Distribution 建立，預設 `testers`）
   - `release_notes`：本次更新說明
3. 點擊 **Run workflow**

### 邀請測試者

1. 前往 [Firebase Console](https://console.firebase.google.com) → App Distribution
2. 建立群組（Testers）→ 輸入測試者 Email 邀請
3. 測試者會收到 Email，引導安裝 Firebase App Tester（或直接下載 APK）

---

## 方案 B：Google Play 外部測試（Open Testing）

### 步驟 1：準備 AAB 建置

Google Play 需要 **Android App Bundle（AAB）**，而非 APK。

> **目前 CI 輸出 APK**。若要上傳至 Play Console，需修改 Workflow 或手動建置。

本機建置 AAB（僅供參考，不建議在本機進行正式建置）：
```bash
# 不要直接執行 —— 正式建置由 CI 處理
flutter build appbundle --release
# 輸出：build/app/outputs/bundle/release/app-release.aab
```

### 步驟 2：上傳至 Play Console

1. Play Console → 你的 App → **測試** → **公開測試（Open Testing）**
2. 點擊 **建立新版本**
3. 上傳 `app-release.aab`
4. 填寫版本資訊：
   - **版本名稱**：`1.0.56`
   - **版本代碼**：`145`
   - **版本新功能**（需為繁體中文 + 英文）

### 步驟 3：設定外部測試

1. 設定國家/地區（建議先從台灣開始）
2. 選擇開放測試方式：
   - **公開連結**：任何人都可加入測試
   - **電子郵件**：僅受邀者可測試
3. 提交審查

---

## Google Play Console 必填資訊

> 以下欄位需在首次提交前完成，Play Console 會有進度提示。

### 商店資訊

| 欄位 | 內容 |
|------|------|
| 應用程式名稱 | `Lumi` |
| 簡短說明 | 見 `app-listing-copy.md` |
| 完整說明 | 見 `app-listing-copy.md` |
| 螢幕截圖 | 見 `screenshots-spec.md` |
| 應用程式圖示 | 512 × 512 px PNG（需上傳） |
| 特色圖片（Feature Graphic） | 1024 × 500 px PNG/JPG（可選） |
| 類別 | 生活品味（Lifestyle）|
| 內容分級 | 填寫問卷後取得（預期：Everyone）|
| 聯絡電子郵件 | `seasuwang@gmail.com` |
| 隱私權政策 | `https://seasu.github.io/LUMI/privacy-policy.html` |

### 資料安全問卷（Data Safety）

| 問題 | 回答 |
|------|------|
| 是否收集或分享使用者資料？ | 是 |
| 帳戶資訊（Google 登入用） | 是，收集；不分享給第三方 |
| 照片 | 否（照片僅存裝置，不收集至伺服器）|
| 崩潰日誌 | 是，收集（Firebase Crashlytics）；不分享 |
| 資料傳輸加密 | 是（使用 HTTPS）|
| 可要求刪除資料 | 是（聯絡信箱） |

### 應用程式內容

| 問題 | 回答 |
|------|------|
| 是否包含廣告？ | 否 |
| 目標對象年齡 | 18 歲以上（一般成人）|
| 是否提供購買項目？ | 否（目前版本） |

---

## 內容分級問卷（IARC）

**預期分級：Everyone（全年齡）**

- 暴力：無
- 成人內容：無
- 恐怖：無
- 賭博：無
- 毒品或酒精：無
- 仇恨言論：無

---

## 常見問題排解

### APK 安裝失敗（版本代碼衝突）

- 確認新 Build 的 `versionCode` 大於已發佈版本
- 目前版本代碼：`145`（下次最少需為 `146`）

### Firebase App Distribution 未收到通知

1. 確認測試者已接受 Firebase App Distribution 邀請 Email
2. 確認 `FIREBASE_TOKEN` Secret 尚未過期
3. 重新執行：`firebase login:ci` 取得新 Token 並更新 Secret

### Google Play 說 API 存取遭拒

- 確認 Google Play API 服務帳號有 **Release Manager** 或以上權限
- 確認服務帳號已在 Play Console → 使用者與權限中授權

---

## 補充：建立 Android 簽名 Keystore

若尚未建立 Keystore：

```bash
# 在本機執行（一次性操作，妥善保管 .jks 檔案！）
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload \
  -dname "CN=Lumi, O=Lumi, C=TW"

# 轉換為 Base64 以設定至 GitHub Secrets
base64 -w 0 upload-keystore.jks
```

> ⚠️ **重要**：`upload-keystore.jks` 絕對不能 commit 至 Git repo。請加入 `.gitignore`（已加入）。
