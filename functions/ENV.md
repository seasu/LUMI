# Cloud Functions — Gemini 模型設定

模型名稱透過 **Firebase Functions `defineString` 參數**設定，在 **`functions/src/gemini.ts`** 頂部定義。

---

## 設定方式

模型名稱以 `defineString` 宣告，有內建預設值，無需 codegen：

| 參數名稱 | 預設值 | 說明 |
|----------|--------|------|
| `GEMINI_VISION_MODEL` | `gemini-2.5-flash` | 衣物圖片分析模型 |
| `GEMINI_EMBEDDING_MODEL` | `gemini-embedding-exp-03-07` | 衣物 embedding 模型 |

---

## 執行時覆寫（選用）

Deploy workflow 可寫入 **`functions/.env.lumi-309ff`** 覆寫預設值：

```
GEMINI_VISION_MODEL=gemini-2.5-flash
GEMINI_EMBEDDING_MODEL=gemini-embedding-exp-03-07
```

對應 GitHub Actions Repository Variables：`GEMINI_VISION_MODEL`、`GEMINI_EMBEDDING_MODEL`。

---

## API 金鑰

Firebase Secret：**`GEMINI_API_KEY`**

---

## 本機

```bash
cd functions && npm ci && npm run build   # tsc only，無需 codegen
```
