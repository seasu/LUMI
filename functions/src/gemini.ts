import { GoogleGenerativeAI } from "@google/generative-ai";
import { HttpsError } from "firebase-functions/v2/https";

import { geminiGeneratedDefaults } from "./geminiDefaults.generated";

export interface GeminiAnalysis {
  category: string;
  colors: string[];
  materials: string[];
  description: string;
}

/**
 * Model IDs: defaults + fallback chains from `geminiDefaults.generated.ts`
 * (`npm run codegen:gemini` — CI injects GitHub Variables).
 * Runtime overrides: `GEMINI_VISION_MODEL`, `GEMINI_EMBEDDING_MODEL`.
 * Vision and embedding use the same resolution pattern (primary → deprecated remap → fallback chain).
 */
function defaultVisionModel(): string {
  return geminiGeneratedDefaults.defaultVisionModel;
}

function defaultEmbeddingModel(): string {
  return geminiGeneratedDefaults.defaultEmbeddingModel;
}

const DEPRECATED_VISION_MODEL_IDS = new Set(
  geminiGeneratedDefaults.deprecatedVisionModelIds.map((id) => id.toLowerCase())
);

const DEPRECATED_EMBEDDING_MODEL_IDS = new Set(
  Array.from(
    geminiGeneratedDefaults.deprecatedEmbeddingModelIds as readonly string[]
  ).map((id) => id.toLowerCase())
);

const VISION_FALLBACK_CHAIN = [...geminiGeneratedDefaults.visionFallbackChain];
const EMBEDDING_FALLBACK_CHAIN = [
  ...geminiGeneratedDefaults.embeddingFallbackChain,
];

function geminiVisionModelId(): string {
  const raw = process.env.GEMINI_VISION_MODEL?.trim();
  if (!raw || raw.length === 0) return defaultVisionModel();
  const lower = raw.toLowerCase();
  if (DEPRECATED_VISION_MODEL_IDS.has(lower)) return defaultVisionModel();
  return raw;
}

function geminiEmbeddingModelId(): string {
  const raw = process.env.GEMINI_EMBEDDING_MODEL?.trim();
  if (!raw || raw.length === 0) return defaultEmbeddingModel();
  const lower = raw.toLowerCase();
  if (DEPRECATED_EMBEDDING_MODEL_IDS.has(lower)) return defaultEmbeddingModel();
  return raw;
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

/** Unique ordered list: env primary first, then codegen fallback chain (no duplicates). */
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

function embeddingModelCandidates(): string[] {
  const primary = geminiEmbeddingModelId();
  const ordered = [primary, ...EMBEDDING_FALLBACK_CHAIN];
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

  const input = [
    analysis.category,
    ...analysis.colors,
    ...analysis.materials,
    analysis.description,
  ].join(" ");

  const candidates = embeddingModelCandidates();
  let lastErr = "";

  for (let i = 0; i < candidates.length; i++) {
    const modelId = candidates[i];
    try {
      const embeddingModel = genAI.getGenerativeModel({ model: modelId });
      const result = await embeddingModel.embedContent(input);
      return result.embedding.values;
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      lastErr = msg;
      const canRetry =
        i < candidates.length - 1 && isLikelyModelNotFoundMessage(msg);
      if (!canRetry) {
        throw new HttpsError(
          "internal",
          `Gemini embedding API error (model: ${modelId}): ${msg}`
        );
      }
    }
  }

  throw new HttpsError(
    "internal",
    `Gemini embedding API error (tried ${candidates.join(", ")}): ${lastErr}`
  );
}
