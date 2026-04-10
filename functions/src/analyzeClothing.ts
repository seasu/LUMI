import * as functions from "firebase-functions/v1";
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

export const analyzeClothing = functions
  .region(FUNCTIONS_REGION)
  .runWith({ secrets: [geminiApiKey] })
  .https.onCall(async (data, context): Promise<AnalyzeClothingResult> => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required."
      );
    }

    const { imageBase64, mimeType } = data as {
      imageBase64: string;
      mimeType: string;
    };

    if (!imageBase64 || !mimeType) {
      throw new functions.https.HttpsError(
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
  });
