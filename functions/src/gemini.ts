import { HttpsError } from "firebase-functions/v2/https";
import { defineString } from "firebase-functions/params";

export const geminiVisionModel = defineString("GEMINI_VISION_MODEL", {
  default: "gemini-3.1-flash-lite",
  description: "Gemini model for clothing image analysis",
});

export const geminiEmbeddingModel = defineString("GEMINI_EMBEDDING_MODEL", {
  default: "gemini-embedding-001",
  description: "Gemini model for generating clothing embeddings",
});

export interface GeminiAnalysis {
  category: string;
  colors: string[];
  materials: string[];
  description: string;
}

const GEMINI_BASE = "https://generativelanguage.googleapis.com/v1";

export async function analyzeImage(
  apiKey: string,
  modelId: string,
  imageBase64: string,
  mimeType: string
): Promise<GeminiAnalysis> {
  const endpoint = `${GEMINI_BASE}/models/${modelId}:generateContent?key=${apiKey}`;

  const body = {
    contents: [
      {
        role: "user",
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
    ],
  };

  const res = await fetch(endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(50000),
  });

  if (!res.ok) {
    const errText = await res.text();
    console.error(`Gemini vision error ${res.status} (model: ${modelId}):`, errText.slice(0, 500));
    throw new HttpsError(
      "internal",
      `Gemini vision API error ${res.status}: ${errText.slice(0, 300)}`
    );
  }

  const json = (await res.json()) as {
    candidates?: Array<{ content: { parts: Array<{ text?: string }> } }>;
  };

  const rawText =
    json.candidates?.[0]?.content?.parts
      ?.map((p) => p.text ?? "")
      .join("")
      .trim() ?? "";

  const jsonText = rawText
    .replace(/^```json?\s*/i, "")
    .replace(/```\s*$/i, "")
    .trim();

  try {
    return JSON.parse(jsonText) as GeminiAnalysis;
  } catch {
    console.error("Gemini vision parse error:", rawText.slice(0, 200));
    throw new HttpsError(
      "internal",
      `Failed to parse Gemini response: ${rawText.slice(0, 200)}`
    );
  }
}

export async function generateEmbedding(
  apiKey: string,
  modelId: string,
  analysis: GeminiAnalysis
): Promise<number[]> {
  const endpoint = `${GEMINI_BASE}/models/${modelId}:embedContent?key=${apiKey}`;

  const input = [
    analysis.category,
    ...analysis.colors,
    ...analysis.materials,
    analysis.description,
  ].join(" ");

  const body = {
    content: {
      parts: [{ text: input }],
    },
  };

  const res = await fetch(endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(30000),
  });

  if (!res.ok) {
    const errText = await res.text();
    console.error(`Gemini embedding error ${res.status} (model: ${modelId}):`, errText.slice(0, 500));
    throw new HttpsError(
      "internal",
      `Gemini embedding API error ${res.status}: ${errText.slice(0, 300)}`
    );
  }

  const json = (await res.json()) as {
    embedding?: { values?: number[] };
  };

  const values = json.embedding?.values;
  if (!values?.length) {
    throw new HttpsError("internal", "Gemini embedding returned no values");
  }
  return values;
}
