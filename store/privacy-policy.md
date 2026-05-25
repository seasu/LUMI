# Lumi 隱私權政策 / Privacy Policy

**最後更新日期 / Last Updated:** 2026-05-25

**適用版本 / Applicable Version:** Lumi 1.0 及以上版本

---

## 中文版本

### 概覽

Lumi（「本應用程式」）由個人開發者（「我們」）開發。本隱私權政策說明我們如何收集、使用與保護您使用本應用程式時的相關資訊。

我們重視您的隱私。Lumi 採用**本機優先（Local-First）**架構：您的衣物照片與 AI 分析結果儲存在您的裝置上，不會上傳或永久儲存至我們的伺服器。

---

### 我們收集哪些資料

#### 1. 帳戶資訊（Google 登入）

當您使用 Google 帳戶登入時，我們會取得：
- 您的 Google 帳戶電子郵件地址
- 您的顯示名稱
- 您的 Google 帳戶 ID（用於身份識別）

這些資訊用於建立您的 Lumi 帳戶，並儲存在 Firebase Authentication 與 Google Firestore（僅帳戶基本資料）。

#### 2. 衣物照片

- 您拍攝或從相簿選取的衣物照片**僅儲存在您的裝置本機**。
- 照片不會上傳至我們的伺服器或任何第三方雲端儲存服務。
- 您可隨時刪除應用程式及所有本機資料。

#### 3. AI 分析（Gemini）

- 當您新增衣物時，照片會透過 Google Cloud Functions 傳送至 **Google Gemini AI** 進行分析。
- Gemini AI 會識別衣物的類型、顏色與材質，並產生向量嵌入（用於相似度比對）。
- **分析完成後，照片不會永久保留在 Google 伺服器上**；分析結果（類型、顏色、材質、向量）儲存在您的裝置本機。
- Google 的 API 服務條款適用於此處理過程，詳見 Google 的隱私權政策。

#### 4. 崩潰報告（Firebase Crashlytics）

- 本應用程式使用 **Firebase Crashlytics** 收集崩潰報告，以協助我們改善應用程式穩定性。
- 崩潰報告包含裝置型號、作業系統版本、應用程式版本及錯誤堆疊追蹤。
- **不包含**個人識別資訊或您的衣物資料。
- 您可在裝置設定中停用崩潰報告。

---

### 我們不收集的資料

- ❌ 精確或模糊的地理位置
- ❌ 裝置廣告 ID（IDFA / GAID）
- ❌ 瀏覽歷史或第三方 App 使用紀錄
- ❌ 聯絡人或通話紀錄
- ❌ 生物特徵資料
- ❌ 信用卡或金融資訊

---

### 資料如何儲存與保護

| 資料類型 | 儲存位置 | 保留期間 |
|---------|---------|---------|
| 帳戶資訊 | Google Firebase（加密） | 帳戶存在期間 |
| 衣物照片 | 裝置本機 | 您刪除前 |
| AI 分析結果 | 裝置本機 | 您刪除前 |
| 崩潰報告 | Firebase Crashlytics | 90 天 |

---

### 第三方服務

本應用程式使用以下第三方服務：

| 服務 | 用途 | 隱私權政策 |
|------|------|-----------|
| Google Firebase Authentication | 帳戶登入 | [firebase.google.com/support/privacy](https://firebase.google.com/support/privacy) |
| Google Cloud Firestore | 帳戶資料儲存 | 同上 |
| Google Cloud Functions | AI 分析中介 | 同上 |
| Google Gemini AI | 衣物圖像分析 | [ai.google.dev/terms](https://ai.google.dev/terms) |
| Firebase Crashlytics | 崩潰報告 | [firebase.google.com/support/privacy](https://firebase.google.com/support/privacy) |

---

### 您的權利

您可以：
- **存取**：要求查看我們持有的您的帳戶資料
- **刪除**：刪除應用程式即可移除裝置上所有本機資料；如需刪除 Firebase 帳戶資料，請聯絡我們
- **撤回同意**：隨時登出帳戶或刪除應用程式

---

### 兒童隱私

本應用程式不針對 13 歲以下兒童，亦不故意收集兒童的個人資訊。

---

### 政策更新

如本政策有重大變更，我們將在應用程式內或本頁面通知您。繼續使用本應用程式即表示您接受更新後的政策。

---

### 聯絡我們

如有任何隱私相關疑問，請聯絡：

**電子郵件：** seasuwang@gmail.com

---

---

## English Version

### Overview

Lumi (the "App") is developed by an individual developer ("we," "us," or "our"). This Privacy Policy explains how we collect, use, and protect information when you use our App.

We value your privacy. Lumi uses a **Local-First** architecture: your clothing photos and AI analysis results are stored on your device and are not uploaded or permanently stored on our servers.

---

### Information We Collect

#### 1. Account Information (Google Sign-In)

When you sign in with your Google account, we receive:
- Your Google account email address
- Your display name
- Your Google account ID (for identification purposes)

This information is used to create your Lumi account and is stored in Firebase Authentication and Google Firestore (basic profile data only).

#### 2. Clothing Photos

- Photos you take or select from your library are **stored locally on your device only**.
- Photos are NOT uploaded to our servers or any third-party cloud storage.
- You can delete the app and all local data at any time.

#### 3. AI Analysis (Gemini)

- When you add a clothing item, the photo is sent via Google Cloud Functions to **Google Gemini AI** for analysis.
- Gemini AI identifies the item's type, color, and material, and generates vector embeddings (for similarity matching).
- **Photos are not permanently retained on Google servers** after analysis; results (type, color, material, vectors) are stored locally on your device.
- Google's API Terms of Service apply to this processing. See Google's Privacy Policy for details.

#### 4. Crash Reports (Firebase Crashlytics)

- The App uses **Firebase Crashlytics** to collect crash reports to help us improve stability.
- Crash reports include device model, OS version, app version, and error stack traces.
- They do **NOT** include personally identifiable information or your clothing data.
- You may disable crash reporting in device settings.

---

### Information We Do NOT Collect

- ❌ Precise or approximate location
- ❌ Device advertising IDs (IDFA / GAID)
- ❌ Browsing history or third-party app usage
- ❌ Contacts or call logs
- ❌ Biometric data
- ❌ Payment or financial information

---

### Data Storage and Security

| Data Type | Storage Location | Retention |
|-----------|-----------------|-----------|
| Account information | Google Firebase (encrypted) | While account exists |
| Clothing photos | Device local storage | Until you delete them |
| AI analysis results | Device local storage | Until you delete them |
| Crash reports | Firebase Crashlytics | 90 days |

---

### Third-Party Services

| Service | Purpose | Privacy Policy |
|---------|---------|---------------|
| Google Firebase Authentication | Account sign-in | [firebase.google.com/support/privacy](https://firebase.google.com/support/privacy) |
| Google Cloud Firestore | Account data storage | Same as above |
| Google Cloud Functions | AI analysis intermediary | Same as above |
| Google Gemini AI | Clothing image analysis | [ai.google.dev/terms](https://ai.google.dev/terms) |
| Firebase Crashlytics | Crash reporting | [firebase.google.com/support/privacy](https://firebase.google.com/support/privacy) |

---

### Your Rights

You may:
- **Access**: Request to see the account data we hold about you
- **Delete**: Delete the app to remove all local data; contact us to delete Firebase account data
- **Withdraw consent**: Sign out or delete the app at any time

---

### Children's Privacy

The App is not directed at children under 13, and we do not knowingly collect personal information from children under 13.

---

### Changes to This Policy

If we make material changes to this policy, we will notify you within the App or on this page. Continued use of the App constitutes acceptance of the updated policy.

---

### Contact Us

For privacy-related inquiries, please contact:

**Email:** seasuwang@gmail.com
