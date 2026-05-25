import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import { FUNCTIONS_REGION } from "./functionsRegion";
import { analyzeImage, generateEmbedding, geminiVisionModel, geminiEmbeddingModel } from "./gemini";

const geminiApiKey = defineSecret("GEMINI_API_KEY");

interface AnalyzeClothingResult {
  category: string;
  colors: string[];
  materials: string[];
  embedding: number[];
}

interface SkippedResult {
  skipped: true;
  reason: string;
}

export const analyzeClothing = onCall(
  {
    region: FUNCTIONS_REGION,
    secrets: [geminiApiKey],
  },
  async (request): Promise<AnalyzeClothingResult | SkippedResult> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const uid = request.auth.uid;

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

    // ── Quota check ───────────────────────────────────────────────────────────
    const db = admin.firestore();
    const userRef = db.doc(`users/${uid}`);
    const userSnap = await userRef.get();
    const userData = userSnap.data() ?? {};

    const analyzedCount = (userData.analyzedCount as number | undefined) ?? 0;
    const freeQuota = (userData.freeQuota as number | undefined) ?? 30;
    const plan = (userData.plan as string | undefined) ?? "free";

    if (plan !== "pro" && analyzedCount >= freeQuota) {
      console.log(
        `analyzeClothing: quota exceeded uid=${uid} (${analyzedCount}/${freeQuota})`
      );
      return { skipped: true, reason: "quota_exceeded" };
    }

    // ── AI Analysis ───────────────────────────────────────────────────────────
    try {
      const apiKey = geminiApiKey.value();
      const analysis = await analyzeImage(
        apiKey,
        geminiVisionModel.value(),
        imageBase64,
        mimeType
      );
      const embedding = await generateEmbedding(
        apiKey,
        geminiEmbeddingModel.value(),
        imageBase64,
        mimeType
      );

      // ── Increment analyzedCount (transaction-safe) ─────────────────────────
      await db.runTransaction(async (t) => {
        const snap = await t.get(userRef);
        const current =
          (snap.data()?.analyzedCount as number | undefined) ?? 0;
        t.update(userRef, { analyzedCount: current + 1 });
      });

      console.log(
        `analyzeClothing: ok uid=${uid} analyzedCount=${analyzedCount + 1} category=${analysis.category}`
      );

      return {
        category: analysis.category,
        colors: analysis.colors,
        materials: analysis.materials,
        embedding,
      };
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      const msg = err instanceof Error ? err.message : String(err);
      console.error("analyzeClothing unhandled error:", msg, err);
      throw new HttpsError("internal", `analyzeClothing failed: ${msg}`);
    }
  }
);
