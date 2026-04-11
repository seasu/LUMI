import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import { FUNCTIONS_REGION } from "./functionsRegion";
import { analyzeImage, generateEmbedding } from "./gemini";

const geminiApiKey = defineSecret("GEMINI_API_KEY");

interface CompareClothingResult {
  similarity: number;
  matchedMediaItemId: string | null;
  matchedThumbnailUrl: string | null;
  matchedCategory: string | null;
}

interface WardrobeDoc {
  mediaItemId: string;
  embedding: number[];
  thumbnailUrl: string;
  category: string;
}

function cosineSimilarity(a: number[], b: number[]): number {
  if (a.length !== b.length || a.length === 0) return 0;

  let dot = 0;
  let normA = 0;
  let normB = 0;

  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }

  const denom = Math.sqrt(normA) * Math.sqrt(normB);
  return denom === 0 ? 0 : dot / denom;
}

export const compareClothing = onCall(
  {
    region: FUNCTIONS_REGION,
    secrets: [geminiApiKey],
  },
  async (request): Promise<CompareClothingResult> => {
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

    const userId = request.auth.uid;

    try {
      const apiKey = geminiApiKey.value();

      // Step 1: Generate embedding for the new photo
      const analysis = await analyzeImage(apiKey, imageBase64, mimeType);
      const queryEmbedding = await generateEmbedding(apiKey, analysis);

      // Step 2: Read all wardrobe items via Admin SDK
      const snapshot = await admin
        .firestore()
        .collection("users")
        .doc(userId)
        .collection("wardrobe")
        .select("mediaItemId", "embedding", "thumbnailUrl", "category")
        .get();

      if (snapshot.empty) {
        return {
          similarity: 0,
          matchedMediaItemId: null,
          matchedThumbnailUrl: null,
          matchedCategory: null,
        };
      }

      // Step 3: Brute-force cosine similarity (ADR-004)
      let bestSimilarity = 0;
      let bestDoc: WardrobeDoc | null = null;

      for (const doc of snapshot.docs) {
        const data = doc.data() as WardrobeDoc;
        if (!data.embedding?.length) continue;

        const sim = cosineSimilarity(queryEmbedding, data.embedding);
        if (sim > bestSimilarity) {
          bestSimilarity = sim;
          bestDoc = data;
        }
      }

      return {
        similarity: bestSimilarity,
        matchedMediaItemId: bestDoc?.mediaItemId ?? null,
        matchedThumbnailUrl: bestDoc?.thumbnailUrl ?? null,
        matchedCategory: bestDoc?.category ?? null,
      };
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      const msg = err instanceof Error ? err.message : String(err);
      throw new HttpsError("internal", `compareClothing failed: ${msg}`);
    }
  }
);
