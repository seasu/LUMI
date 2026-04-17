# SECURITY.md — Lumi API Key 安全設定清單

本文件提供 Lumi 專案在 Web / iOS / Android 的 API key 安全設定標準，目標是：

- 降低 key 外洩風險
- 讓 key 發生問題時可快速定位平台
- 避免以「前端 key」承載後端權限

---

## 1. 核心原則

1. **平台分離**：Web、iOS、Android 使用不同 key，不共用。
2. **最小權限**：每把 key 只開必要 API（API restrictions）。
3. **來源限制**：每把 key 都必須設 Application restrictions。
4. **禁用服務帳戶綁定（前端 key）**：
   - 對 Web / iOS / Android 前端 key，**不要勾選**「Authenticate API calls through a service account」。
5. **前端 key 不是 secret**：
   - Browser / mobile key 可以被看到，但必須有完善限制。
   - 真正敏感資訊（service account JSON、私鑰）禁止放入 repo。

---

## 2. Lumi 目前平台對應

| 平台 | Key 名稱建議 | Application restrictions |
|------|--------------|--------------------------|
| Web | `lumi-web-browser-key` | HTTP referrers |
| Android | `lumi-android-key` | Android apps（package + SHA） |
| iOS | `lumi-ios-key` | iOS apps（Bundle ID） |

---

## 3. Web key（GitHub Pages）設定

### 3.1 Application restrictions

選擇：`HTTP referrers (web sites)`

至少加入：

- `https://seasu.github.io/LUMI/*`
- `http://localhost:*/*`（本地開發）

如果有自訂網域，再加入對應網域 pattern。

### 3.2 API restrictions（Lumi Web 建議最小集合）

先開以下 API：

1. `Identity Toolkit API`
2. `Token Service`（有些介面顯示為 Secure Token 能力）
3. `Cloud Firestore API`
4. `Firebase Installations API`

若功能測試出現 `API_KEY_SERVICE_BLOCKED` 或 `REQUEST_DENIED`，再補缺少 API。

---

## 4. iOS / Android key 設定

### Android

- Application restrictions：`Android apps`
- 綁定：
  - package name
  - SHA-1 / SHA-256 指紋（依實際簽章）

### iOS

- Application restrictions：`iOS apps`
- 綁定：
  - Bundle ID

### API restrictions

依實際 Firebase 功能開放，原則同 Web：最小集合開始，缺什麼補什麼。

---

## 5. GitHub 與 CI 設定

Lumi Web 部署目前使用：

- GitHub Actions secret：`FIREBASE_API_KEY`
- 由 workflow 注入：`--dart-define=FIREBASE_API_KEY=...`

變更 key 後，請同步更新 repo secrets，並重新部署。

---

## 6. Key 洩漏事件處理（Runbook）

當 GitHub Secret Scanning 或人工發現 key 外洩時：

1. **先在 GCP 停用/刪除舊 key**（止血）
2. **建立新 key 並重設限制**
3. **更新 GitHub Actions secrets**
4. **觸發重新部署**
5. **在 GitHub 關閉 alert**
   - 若確認是 Firebase Browser key 且受限可控，可標註為 false positive / resolved（依團隊流程）
6. 事後檢討：
   - 確認是否有 build 產物誤提交
   - 檢查是否有人放入真正敏感金鑰

---

## 7. 禁止事項（Checklist）

- [ ] 前端 key 未設 Application restrictions
- [ ] 前端 key 未設 API restrictions
- [ ] Web / iOS / Android 共用同一把 key
- [ ] 對前端 key 勾選 service account 綁定
- [ ] 把 service account JSON 或私鑰提交到 repo

---

## 8. 週期性檢查建議

- 每月檢查一次 key 限制是否仍符合目前網域/包名
- 每次平台擴張（新增網域、Android 簽章調整、iOS bundle 調整）同步更新 restrictions
- 每次安全事件後更新本文件

