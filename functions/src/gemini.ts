import { GoogleGenerativeAI } from "@google/generative-ai";
import { HttpsError } from "firebase-functions/v2/https";

export interface GeminiAnalysis {
  category: string;
  colors: string[];
  materials: string[];
  description: string;
}

export async function analyzeImage(
  apiKey: string,
  imageBase64: string,
  mimeType: string
): Promise<GeminiAnalysis> {
  const genAI = new GoogleGenerativeAI(apiKey);
  const visionModel = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

  const visionResult = await visionModel.generateContent({
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

  const rawText = visionResult.response.text().trim();
  const jsonText = rawText
    .replace(/^```json?\s*/i, "")
    .replace(/```\s*$/i, "")
    .trim();

  try {
    return JSON.parse(jsonText) as GeminiAnalysis;
  } catch {
    throw new HttpsError("internal", "Failed to parse Gemini response.");
  }
}

export async function generateEmbedding(
  apiKey: string,
  analysis: GeminiAnalysis
): Promise<number[]> {
  const genAI = new GoogleGenerativeAI(apiKey);
  const embeddingModel = genAI.getGenerativeModel({
    model: "text-embedding-004",
  });

  const input = [
    analysis.category,
    ...analysis.colors,
    ...analysis.materials,
    analysis.description,
  ].join(" ");

  const result = await embeddingModel.embedContent(input);
  return result.embedding.values;
}
