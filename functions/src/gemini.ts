import { GoogleGenerativeAI } from "@google/generative-ai";
import { HttpsError } from "firebase-functions/v2/https";

export interface GeminiAnalysis {
  category: string;
  colors: string[];
  materials: string[];
  description: string;
}

/**
 * Model IDs — override via `GEMINI_VISION_MODEL` / `GEMINI_EMBEDDING_MODEL`
 * (GitHub Actions vars → `.env.<project>` or `.env`).
 * Defaults target models that resolve for most Gemini API keys; if API returns 404,
 * vision falls through a short compatibility list automatically.
 */
const DEFAULT_VISION_MODEL = "gemini-2.0-flash";
const DEFAULT_EMBEDDING_MODEL = "text-embedding-004";

/**
 * Models removed from the Gemini API for `generateContent` (404 forever).
 * If env still uses one of these, we substitute [DEFAULT_VISION_MODEL].
 */
const DEPRECATED_VISION_MODEL_IDS = new Set([
  "gemini-1.5-flash",
  "gemini-1.5-flash-8b",
  "gemini-1.5-pro",
]);

/** Ordered fallbacks when the primary vision model returns 404 (API key / tier differences). */
const VISION_FALLBACK_CHAIN = [
  DEFAULT_VISION_MODEL,
  "gemini-flash-latest",
  "gemini-2.5-flash",
] as const;

function geminiVisionModelId(): string {
  const raw = process.env.GEMINI_VISION_MODEL?.trim();
  if (!raw || raw.length === 0) return DEFAULT_VISION_MODEL;
  const lower = raw.toLowerCase();
  if (DEPRECATED_VISION_MODEL_IDS.has(lower)) return DEFAULT_VISION_MODEL;
  return raw;
}

function geminiEmbeddingModelId(): string {
  const v = process.env.GEMINI_EMBEDDING_MODEL?.trim();
  return v && v.length > 0 ? v : DEFAULT_EMBEDDING_MODEL;
}

function isLikelyModelNotFoundMessage(msg: string): boolean {
  const m = msg.toLowerCase();
  return (
    /\b404\b/.test(msg) ||
    m.includes("not found") ||
    m.includes("not_supported") ||
    m.includes("was not found")
  );
}

/** Unique ordered list: env primary first, then built-in compatibility chain (no duplicates). */
function visionModelCandidates(): string[] {
  const primary = geminiVisionModelId();
  const ordered = [primary, ...VISION_FALLBACK_CHAIN];
  const seen = new Set<string>();
  const out: string[] = [];
  for (const id of ordered) {
    const t = id.trim();
    if (!t || seen.has(t)) continue;
    seen.add(t);
    out.push(t);
  }
  return out;
}

export async function analyzeImage(
  apiKey: string,
  imageBase64: string,
  mimeType: string
): Promise<GeminiAnalysis> {
  if (!apiKey) {
    throw new HttpsError("internal", "GEMINI_API_KEY is not configured.");
  }

  const genAI = new GoogleGenerativeAI(apiKey);
  const contents = [
    {
      role: "user" as const,
      parts: [
        { inlineData: { data: imageBase64, mimeType } },
        {
          text: `Analyze this clothing item. Return ONLY a valid JSON object with no markdown:
{
  "category": one of ["上衣","褲子","外套","配件","鞋子"],
  "colors": array of 1-3 dominant hex color codes (e.g. ["#3B5BDB","#FFFFFF"]),
  "materials": array of material names in Chinese (e.g. ["棉","聚酯纖維"]),
  "description": brief English description of the clothing item (used for similarity matching)
}`,
        },
      ],
    },
  ];

  const candidates = visionModelCandidates();
  let visionResult;
  let lastErr = "";

  for (let i = 0; i < candidates.length; i++) {
    const modelId = candidates[i];
    try {
      const visionModel = genAI.getGenerativeModel({ model: modelId });
      visionResult = await visionModel.generateContent({ contents });
      break;
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      lastErr = msg;
      const canRetry =
        i < candidates.length - 1 && isLikelyModelNotFoundMessage(msg);
      if (!canRetry) {
        throw new HttpsError(
          "internal",
          `Gemini vision API error (model: ${modelId}): ${msg}`
        );
      }
    }
  }

  if (!visionResult) {
    throw new HttpsError(
      "internal",
      `Gemini vision API error (tried ${candidates.join(", ")}): ${lastErr}`
    );
  }

  const rawText = visionResult.response.text().trim();
  const jsonText = rawText
    .replace(/^```json?\s*/i, "")
    .replace(/```\s*$/i, "")
    .trim();

  try {
    return JSON.parse(jsonText) as GeminiAnalysis;
  } catch {
    throw new HttpsError(
      "internal",
      `Failed to parse Gemini response: ${rawText.slice(0, 200)}`
    );
  }
}

export async function generateEmbedding(
  apiKey: string,
  analysis: GeminiAnalysis
): Promise<number[]> {
  const genAI = new GoogleGenerativeAI(apiKey);
  const embeddingModel = genAI.getGenerativeModel({
    model: geminiEmbeddingModelId(),
  });

  const input = [
    analysis.category,
    ...analysis.colors,
    ...analysis.materials,
    analysis.description,
  ].join(" ");

  try {
    const result = await embeddingModel.embedContent(input);
    return result.embedding.values;
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    throw new HttpsError("internal", `Gemini embedding API error: ${msg}`);
  }
}
