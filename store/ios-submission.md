# iOS TestFlight 外部測試送審指南

本文件說明如何將 Lumi 發佈至 **TestFlight 外部測試**，供外部使用者測試。

---

## 前置作業

### 1. Apple 帳號與 App Store Connect

- 確認擁有 **Apple Developer Program** 帳號（年費 $99 USD）
- 登入 [App Store Connect](https://appstoreconnect.apple.com)
- 確認已建立 App：**Bundle ID = `io.github.seasu.lumi`**
  - 若尚未建立：App Store Connect → 我的 App → ＋ → 新增 App → 填入 Bundle ID

### 2. 啟用 iOS GitHub Actions Workflow

> ⚠️ iOS 部署 Workflow 目前可能已停用，需手動重新啟用。

1. 前往 GitHub → 本 Repo → **Actions**
2. 左側找到 **「iOS Deploy to TestFlight」**
3. 若出現 **「This workflow is disabled」** → 點擊 **「Enable workflow」**
4. 啟用後可點擊 **「Run workflow」** 手動觸發，或 push 到 `main` 自動觸發

---

## GitHub Secrets 清單

在 GitHub → Settings → Secrets and variables → Actions 確認以下 Secrets 已設定：

| Secret 名稱 | 說明 | 取得方式 |
|-------------|------|---------|
| `IOS_DISTRIBUTION_CERT_BASE64` | Apple Distribution 憑證（.p12）的 Base64 | Keychain Access 匯出 .p12 → `base64 -i cert.p12 -o cert.txt` |
| `IOS_DISTRIBUTION_CERT_PASSWORD` | .p12 憑證密碼 | 匯出時設定的密碼 |
| `IOS_PROVISIONING_PROFILE_BASE64` | App Store Distribution Provisioning Profile 的 Base64 | Developer Portal 下載 .mobileprovision → `base64 -i app.mobileprovision -o profile.txt` |
| `IOS_PROVISIONING_PROFILE_NAME` | Provisioning Profile 名稱（精確字串） | Developer Portal 上的 Profile 名稱 |
| `IOS_TEAM_ID` | Apple Developer Team ID | Developer Portal → Membership → Team ID |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect API Issuer ID | App Store Connect → 使用者與存取 → 整合 → App Store Connect API |
| `APP_STORE_CONNECT_KEY_ID` | API 金鑰 ID | 同上 |
| `APP_STORE_CONNECT_PRIVATE_KEY` | API 私鑰內容（.p8 全文） | 下載 .p8 → 複製完整內容（包含 `-----BEGIN PRIVATE KEY-----` 行）|
| `GOOGLE_SERVICE_INFO_PLIST` | Firebase iOS 設定 | Firebase Console → 專案設定 → iOS App → 下載 GoogleService-Info.plist → 複製全文貼入 |

### 檢查 Secrets 設定是否正確

```bash
# 若要測試 base64 編碼是否正確（本機驗證）
base64 -d <<< "$IOS_DISTRIBUTION_CERT_BASE64" | file -
# 應輸出：data（p12 二進位檔）

base64 -d <<< "$IOS_PROVISIONING_PROFILE_BASE64" | file -
# 應輸出：data（mobileprovision 二進位檔）
```

---

## 建置與上傳流程

### 自動觸發（推薦）

push 至 `main` 分支，GitHub Actions 自動執行：
1. 設定 Flutter 環境
2. 安裝依賴套件
3. 注入 Firebase 設定與簽名憑證
4. `flutter build ipa --release`
5. 上傳至 TestFlight

### 手動觸發

GitHub → Actions → **iOS Deploy to TestFlight** → **Run workflow** → 輸入 release_notes → **Run workflow**

---

## App Store Connect 必填資訊

### TestFlight 外部測試

1. 登入 App Store Connect → 你的 App → **TestFlight**
2. 等待 build 出現（自動上傳約 5–10 分鐘）
3. 點擊 build → 填寫：
   - **What to Test**（測試重點說明）
   - **Test Information**（測試者需知）

### 外部測試群組

外部測試需通過 **Apple 審查**（Beta App Review，通常 1–2 個工作天）。

1. TestFlight → **外部測試** → **＋** → 建立新群組（例如：`External Testers`）
2. 選擇要測試的 build → 加入群組
3. 提交審查：
   - **加密：** 選「否」（App 不使用受出口管制的加密，`ITSAppUsesNonExemptEncryption = false` 已設定）
   - **隱私權政策 URL：** `https://seasu.github.io/LUMI/privacy-policy.html`
4. 等待 Apple Beta App Review 通過

### 邀請測試者

審查通過後，可以：
- **電子郵件邀請**：TestFlight → 群組 → 測試人員 → 輸入 Email
- **公開連結**：TestFlight → 群組 → 啟用公開連結 → 分享連結（最多 10,000 人）

---

## App Store Connect 其他必填欄位

> 這些欄位在提交正式審查前需要填寫，但外部 TestFlight 不強制要求全部完成。

| 欄位 | 建議內容 |
|------|---------|
| 隱私權政策 URL | `https://seasu.github.io/LUMI/privacy-policy.html` |
| 支援 URL | `https://seasu.github.io/LUMI/` |
| 行銷 URL（選填） | `https://seasu.github.io/LUMI/` |
| 版權 | `© 2026 Lumi` |
| 聯絡信箱 | `seasuwang@gmail.com` |

---

## App 隱私問卷（App Privacy）

正式上架需填寫，外部 TestFlight 不強制。填寫參考：

| 問題 | 答案 |
|------|------|
| 是否收集資料？ | 是 |
| 帳戶資訊 | 是（用於登入） |
| 用途（帳戶資訊） | App 功能 |
| 是否與第三方分享帳戶資訊？ | 否 |
| 照片 | 否（本機儲存，不上傳） |
| 診斷資料（Crashlytics） | 是 |
| 與第三方分享診斷資料？ | 是（Firebase Crashlytics，匿名） |

---

## 審查人員帳號（Review Notes）

Beta App Review 需提供測試帳號：

```
審查說明：
本 App 使用 Google Sign-In 登入。請使用以下 Demo Google 帳號，
或任何 Google 帳號登入即可使用完整功能。

主要測試流程：
1. 登入頁 → 點擊「Continue with Google」
2. 授權 Google 帳號登入
3. 我的衣櫥頁面 → 點擊右下角相機按鈕新增衣物
4. 拍照或選取照片 → 點擊「加入」
5. 等待 AI 分析完成（約 5–10 秒）
6. 點擊右下角「似」字按鈕進入 Lumi-Check

加密說明：
本 App 不使用非豁免加密（ITSAppUsesNonExemptEncryption = false）。
```

---

## 內容分級問卷

**預期分級：4+（適合所有年齡）**

| 問題 | 回答 |
|------|------|
| 卡通或幻想暴力？ | 無 |
| 真實暴力？ | 無 |
| 成人或情色內容？ | 無 |
| 恐怖內容？ | 無 |
| 賭博？ | 無 |
| 菸酒藥物提及？ | 無 |
| 侮辱性用語？ | 無 |
| 可分享使用者生成內容？ | 無 |

---

## 常見問題排解

### Build 在 GitHub Actions 失敗

1. 確認所有 Secrets 已正確設定（特別是 `GOOGLE_SERVICE_INFO_PLIST`）
2. 檢查 Provisioning Profile 是否已包含正確的 Bundle ID（`io.github.seasu.lumi`）
3. 檢查 Distribution Certificate 是否在有效期內
4. 查看 GitHub Actions 日誌中的具體錯誤訊息

### TestFlight 未收到 Build

- Build 上傳後通常 5–10 分鐘內出現在 App Store Connect
- 確認 App Store Connect API 金鑰有足夠權限（需要 App Manager 或 Developer 角色）

### Beta App Review 被拒

常見原因：
- 缺少隱私權政策 URL
- App 在審查時無法正常登入（提供 Demo 帳號或說明）
- App 描述與實際功能不符
