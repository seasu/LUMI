import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { FUNCTIONS_REGION } from "./functionsRegion";
import { analyzeImage, generateEmbedding } from "./gemini";

const geminiApiKey = defineSecret("GEMINI_API_KEY");

interface AnalyzeClothingResult {
  category: string;
  colors: string[];
  materials: string[];
  embedding: number[];
}

export const analyzeClothing = onCall(
  {
    region: FUNCTIONS_REGION,
    secrets: [geminiApiKey],
  },
  async (request): Promise<AnalyzeClothingResult> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const { imageBase64, mimeType } = request.data as {
      imageBase64: string;
      mimeType: string;
    };

    if (!imageBase64 || !mimeType) {
      throw new HttpsError(
        "invalid-argument",
        "imageBase64 and mimeType are required."
      );
    }

    const apiKey = geminiApiKey.value();
    const analysis = await analyzeImage(apiKey, imageBase64, mimeType);
    const embedding = await generateEmbedding(apiKey, analysis);

    return {
      category: analysis.category,
      colors: analysis.colors,
      materials: analysis.materials,
      embedding,
    };
  }
);
