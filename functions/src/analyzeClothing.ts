import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { GoogleGenerativeAI } from "@google/generative-ai";

const geminiApiKey = defineSecret("GEMINI_API_KEY");

interface AnalyzeClothingData {
  imageBase64: string;
  mimeType: string;
}

interface AnalyzeClothingResult {
  category: string;
  colors: string[];
  materials: string[];
  embedding: number[];
}

interface GeminiAnalysis {
  category: string;
  colors: string[];
  materials: string[];
  description: string;
}

export const analyzeClothing = onCall(
  { secrets: [geminiApiKey] },
  async (request): Promise<AnalyzeClothingResult> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const { imageBase64, mimeType } = request.data as AnalyzeClothingData;

    if (!imageBase64 || !mimeType) {
      throw new HttpsError("invalid-argument", "imageBase64 and mimeType are required.");
    }

    const genAI = new GoogleGenerativeAI(geminiApiKey.value());

    // Step 1: Analyze clothing image
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
    // Strip markdown code blocks if Gemini adds them
    const jsonText = rawText.replace(/^```json?\s*/i, "").replace(/```\s*$/i, "").trim();

    let analysis: GeminiAnalysis;
    try {
      analysis = JSON.parse(jsonText) as GeminiAnalysis;
    } catch {
      throw new HttpsError("internal", "Failed to parse Gemini response.");
    }

    // Step 2: Generate embedding from description + metadata
    const embeddingModel = genAI.getGenerativeModel({ model: "text-embedding-004" });
    const embeddingInput = [
      analysis.category,
      ...analysis.colors,
      ...analysis.materials,
      analysis.description,
    ].join(" ");

    const embeddingResult = await embeddingModel.embedContent(embeddingInput);

    return {
      category: analysis.category,
      colors: analysis.colors,
      materials: analysis.materials,
      embedding: embeddingResult.embedding.values,
    };
  }
);
