import { GoogleGenerativeAI } from "@google/generative-ai";
import { HttpsError } from "firebase-functions/v2/https";

export interface GeminiAnalysis {
  category: string;
  colors: string[];
  materials: string[];
  description: string;
}

/**
 * Model IDs — override without code changes:
 * - GitHub Actions: set repo Variables `GEMINI_VISION_MODEL` / `GEMINI_EMBEDDING_MODEL`
 *   (workflow exports them before `firebase deploy`).
 * - Firebase / local: `functions/.env.<PROJECT_ID>` e.g. `.env.lumi-309ff`
 * - Shell: `export GEMINI_VISION_MODEL=gemini-2.5-flash` before deploy
 */
function geminiVisionModelId(): string {
  const v = process.env.GEMINI_VISION_MODEL?.trim();
  return v && v.length > 0 ? v : "gemini-2.5-flash";
}

function geminiEmbeddingModelId(): string {
  const v = process.env.GEMINI_EMBEDDING_MODEL?.trim();
  return v && v.length > 0 ? v : "text-embedding-004";
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
  const visionModel = genAI.getGenerativeModel({
    model: geminiVisionModelId(),
  });

  let visionResult;
  try {
    visionResult = await visionModel.generateContent({
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
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    throw new HttpsError("internal", `Gemini vision API error: ${msg}`);
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
