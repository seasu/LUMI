# Lumi — 商店送審文件索引

本目錄包含 Lumi App 上架至 Apple App Store（TestFlight 外部測試）與 Google Play Store（外部測試）所需的全部文件。

---

## App 基本資訊

| 欄位 | 值 |
|------|----|
| App 名稱 | Lumi |
| Bundle ID（iOS） | `io.github.seasu.lumi` |
| Application ID（Android） | `io.github.seasu.lumi` |
| 版本名稱 | 1.0.56 |
| 版本號（Build） | 145 |
| iOS 最低版本 | iOS 12.0 |
| Android 最低版本 | Android 6.0（API 23） |
| 語言 | 繁體中文（主）、英文 |
| 類別 | 生活風格（iOS）／生活品味（Android） |
| 聯絡信箱 | seasuwang@gmail.com |

---

## 隱私權政策

- 原始文字：[`store/privacy-policy.md`](./privacy-policy.md)
- 公開網址：`https://seasu.github.io/LUMI/privacy-policy.html`（GitHub Pages 自動部署）

> **重要**：送審前請確認隱私權政策頁面可正常存取。push 後約 3–5 分鐘由 GitHub Actions 部署。

---

## 文件清單

| 檔案 | 用途 |
|------|------|
| [app-listing-copy.md](./app-listing-copy.md) | App 名稱、描述、關鍵字、更新說明等上架文案（繁中 ＋ 英文） |
| [privacy-policy.md](./privacy-policy.md) | 隱私權政策完整文字 |
| [ios-submission.md](./ios-submission.md) | iOS TestFlight 外部測試送審逐步指南 |
| [android-submission.md](./android-submission.md) | Google Play 外部測試送審逐步指南 |
| [screenshots-spec.md](./screenshots-spec.md) | 截圖規格與需拍攝的畫面說明 |

---

## 送審前快速檢查

- [ ] GitHub Secrets 全部設定完成（見各平台指南）
- [ ] `https://seasu.github.io/LUMI/privacy-policy.html` 可正常存取
- [ ] App Store Connect 已建立 App（Bundle ID 綁定）
- [ ] Google Play Console 已建立 App（Package name 綁定）
- [ ] 截圖準備完成（參考 `screenshots-spec.md`）
- [ ] iOS TestFlight workflow 已在 GitHub Actions 啟用
- [ ] Android Firebase App Distribution workflow 正常運作
