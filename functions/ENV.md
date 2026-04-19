# Cloud Functions — Gemini 模型設定

所有 Gemini 呼叫（視覺分析與 embedding）都只在 **`functions/src/gemini.ts`** 組 model id，並共用同一套規則：

1. **Codegen 預設**：`npm run codegen:gemini` 依環境變數產生 **`src/geminiDefaults.generated.ts`**（編譯進 `lib/`）。
2. **執行時覆寫**：`GEMINI_VISION_MODEL` / `GEMINI_EMBEDDING_MODEL`（Firebase `.env.<PROJECT_ID>` 或由 workflow 寫入）。
3. **棄用對照**：若覆寫值落在 codegen 的 deprecated 清單，會改回預設。
4. **404 時降級**：依 codegen 的 **fallback chain** 依序換模型（vision / embedding 各自一條鏈）。

---

## GitHub Actions Repository Variables（CI 寫入 codegen）

Deploy workflow 在 build 前會跑 codegen。可設定：

| GitHub Variable | 說明 |
|-----------------|------|
| `GEMINI_DEFAULT_VISION_MODEL` | 預設視覺模型（腳本內建預設：`gemini-2.5-flash`） |
| `GEMINI_DEFAULT_EMBEDDING_MODEL` | 預設 embedding（腳本內建預設：`text-embedding-004`） |
| `GEMINI_DEPRECATED_VISION_MODELS` | **逗號分隔**，覆寫為這些 id 時改回預設視覺模型 |
| `GEMINI_DEPRECATED_EMBEDDING_MODELS` | **逗號分隔**，embedding 棄用 id（可留空） |
| `GEMINI_VISION_FALLBACK_CHAIN` | **逗號分隔**，vision 404 時備援順序（預設不含已淘汰的 `gemini-2.0-flash`） |
| `GEMINI_EMBEDDING_FALLBACK_CHAIN` | **逗號分隔**，embedding 404 時備援順序（腳本內建含 `text-embedding-004,text-embedding-001`） |

---

## 執行時覆寫（選用）

部署時 workflow 可寫入 **`functions/.env.lumi-309ff`**：

| 變數 | 說明 |
|------|------|
| `GEMINI_VISION_MODEL` | 覆寫主視覺模型（仍會走 vision fallback 鏈） |
| `GEMINI_EMBEDDING_MODEL` | 覆寫主 embedding 模型（仍會走 embedding fallback 鏈） |

---

## API 金鑰

Firebase Secret：**`GEMINI_API_KEY`**

---

## 本機

```bash
cd functions && npm ci && npm run build   # codegen + tsc
```
