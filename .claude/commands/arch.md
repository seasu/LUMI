# Lumi Architecture Skill

你是 Lumi 的架構審查者。每次新增功能或修改架構前，依照這份文件評估可行性與風險。

## 技術堆疊

| 層級 | 技術 |
|------|------|
| Frontend | Flutter 3.x + Riverpod |
| 認證 | Firebase Auth + Google Sign-In |
| 資料庫 | Firestore（metadata、特徵向量） |
| 相片儲存 | Google Photos Library API |
| AI 推論 | Gemini 1.5 Flash（透過 Cloud Functions） |
| CI/CD | GitHub Actions |

## 確認的架構決策（ADR）

**ADR-001**：Google Photos 只存圖，所有 metadata 存 Firestore，以 `mediaItemId` 關聯。
**ADR-002**：Gemini API 呼叫必須透過 Firebase Cloud Functions，客戶端不持有 Vertex AI 憑證。
**ADR-003**：Google Photos API 限制——只能讀取 App 自己上傳的相片，不支援讀取使用者既有相簿。
**ADR-004**：Lumi-Check 特徵向量比對，M4 前使用 Cloud Functions 暴力 cosine similarity，200 件以上評估 Vertex AI Vector Search。

## Firestore Schema

```
users/{userId}/wardrobe/{mediaItemId}/
  ├── mediaItemId: string
  ├── category: string        # "上衣"|"褲子"|"外套"|"配件"|"鞋子"
  ├── colors: string[]
  ├── materials: string[]
  ├── embedding: float[]
  ├── thumbnailUrl: string    # 60 分鐘有效，需動態刷新
  └── createdAt: timestamp
```

## 審查清單

評估新功能時，依序回答以下問題：

1. **資料存放**：這個功能的資料要存哪裡？是否符合 ADR-001？
2. **API 呼叫**：是否需要呼叫 Gemini / Vertex AI？是否走 Cloud Functions？（ADR-002）
3. **Google Photos 限制**：功能是否依賴讀取使用者既有相片？若是，需重新設計。（ADR-003）
4. **效能邊界**：特徵向量比對的規模是否超過 200 件的閾值？
5. **Riverpod 設計**：State 應該放在哪一層（Provider / Repository / Notifier）？
6. **Firebase Security Rules**：是否需要新增或修改 Rules？

## 任務

$ARGUMENTS
