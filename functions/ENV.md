# Cloud Functions 環境變數（Gemini 模型）

衣櫥 AI 分析等流程使用的模型 ID 可**不改程式**就調整，讀取順序如下：

| 變數 | 說明 | 未設定時的預設 |
|------|------|----------------|
| `GEMINI_VISION_MODEL` | `generateContent` 圖像分析用模型 | `gemini-2.0-flash` |
| `GEMINI_EMBEDDING_MODEL` | 文字 embedding 用模型 | `text-embedding-004` |

若主要模型對你的 API Key 回傳 **404**，後端會自動依序嘗試（不重複）：`GEMINI_VISION_MODEL`（已正規化）→ `gemini-2.0-flash` → `gemini-flash-latest` → `gemini-2.5-flash`。

> **已下線的模型**（如 `gemini-1.5-flash`）在 API 上會回 404。若你曾在 GitHub Variable 或 `.env` 裡寫入舊名稱，部署後程式會**自動改以** `gemini-2.0-flash` 作為主模型；建議手動把變數改成目前 [文件](https://ai.google.dev/gemini-api/docs/models) 列出的 `generateContent` 模型 id。

## 方式一：GitHub Actions 部署（`functions-deploy` workflow）

在該 repository 設定 **Repository variables**（名稱需一致）：

- `GEMINI_VISION_MODEL`
- `GEMINI_EMBEDDING_MODEL`

部署步驟會把變數匯出成環境變數再執行 `firebase deploy --only functions`，寫入的 `lib` 即帶入當次建置的模型名稱。

> 可當成非敏感設定用 **Variables**；若你希望連名稱都不出現在設定列表，仍可改用 **Secrets**（效果相同）。

## 方式二：Firebase 部署（本機或 CI）

在 **`functions/`** 目錄放置 **`.env.<PROJECT_ID>`**（例如 `.env.lumi-309ff`），內容例如：

```
GEMINI_VISION_MODEL=gemini-2.0-flash
GEMINI_EMBEDDING_MODEL=text-embedding-004
```

Firebase CLI 會在部署時載入。（此檔已預設被 `.gitignore` 忽略，勿將金鑰與環境檔提交至 Git。）

## API 金鑰（與模型不同）

Gemini API Key 仍請用 Firebase **Secret**：`GEMINI_API_KEY`（見專案主 README / `SECURITY.md`）。
