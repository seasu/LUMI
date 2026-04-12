import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import { FUNCTIONS_REGION } from "./functionsRegion";
import { analyzeImage, generateEmbedding } from "./gemini";

const geminiApiKey = defineSecret("GEMINI_API_KEY");

interface MatchedItem {
  similarity: number;
  mediaItemId: string;
  thumbnailUrl: string;
  category: string;
  colors: string[];
}

interface CompareClothingResult {
  topMatches: MatchedItem[];
}

interface WardrobeDoc {
  mediaItemId: string;
  embedding: number[];
  thumbnailUrl: string;
  category: string;
  colors: string[];
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
        .select("mediaItemId", "embedding", "thumbnailUrl", "category", "colors")
        .get();

      if (snapshot.empty) {
        return { topMatches: [] };
      }

      // Step 3: Brute-force cosine similarity (ADR-004)
      const scored: Array<{ sim: number; doc: WardrobeDoc }> = [];

      for (const doc of snapshot.docs) {
        const data = doc.data() as WardrobeDoc;
        if (!data.embedding?.length) continue;

        const sim = cosineSimilarity(queryEmbedding, data.embedding);
        scored.push({ sim, doc: data });
      }

      // Sort descending by similarity, return top 5
      scored.sort((a, b) => b.sim - a.sim);
      const topMatches: MatchedItem[] = scored.slice(0, 5).map(({ sim, doc }) => ({
        similarity: sim,
        mediaItemId: doc.mediaItemId,
        thumbnailUrl: doc.thumbnailUrl,
        category: doc.category ?? "",
        colors: doc.colors ?? [],
      }));

      return { topMatches };
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      const msg = err instanceof Error ? err.message : String(err);
      throw new HttpsError("internal", `compareClothing failed: ${msg}`);
    }
  }
);
