import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import { FUNCTIONS_REGION } from "./functionsRegion";
import { analyzeImage, generateEmbedding } from "./gemini";

const geminiApiKey = defineSecret("GEMINI_API_KEY");

const DEFAULT_FREE_QUOTA = 100;

export const analyzeWardrobeItemOnCreate = onDocumentCreated(
  {
    document: "users/{userId}/wardrobe/{mediaItemId}",
    region: FUNCTIONS_REGION,
    secrets: [geminiApiKey],
    timeoutSeconds: 300,
  },
  async (event) => {
    const data = event.data?.data();

    // Only process new items that are pending analysis
    if (!data || data.analyzed !== false) return;

    const { userId } = event.params;
    const thumbnailUrl = data.thumbnailUrl as string | undefined;
    const wardrobeRef = event.data!.ref;

    if (!thumbnailUrl) {
      await wardrobeRef.update({ analyzeError: "missing_url" });
      return;
    }

    // ── Check quota ────────────────────────────────────────────────────────────
    const userRef = admin.firestore().doc(`users/${userId}`);
    const userDoc = await userRef.get();
    const userData = userDoc.data() ?? {};
    const analyzedCount = (userData.analyzedCount as number) ?? 0;
    const freeQuota = (userData.freeQuota as number) ?? DEFAULT_FREE_QUOTA;

    if (analyzedCount >= freeQuota) {
      await wardrobeRef.update({ analyzeError: "quota_exceeded" });
      return;
    }

    // ── Download image from Google Photos ──────────────────────────────────────
    // baseUrl is a public CDN URL valid for ~60 min; no OAuth needed.
    // Appending =w2048-h2048 requests the image at up to 2048×2048px.
    const imageUrl = `${thumbnailUrl}=w2048-h2048`;
    let imageBase64: string;
    let mimeType: string;

    try {
      const response = await fetch(imageUrl);
      if (!response.ok) {
        throw new Error(`HTTP ${response.status} ${response.statusText}`);
      }
      const buffer = await response.arrayBuffer();
      imageBase64 = Buffer.from(buffer).toString("base64");
      mimeType = response.headers.get("content-type") ?? "image/jpeg";
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      await wardrobeRef.update({ analyzeError: `download_failed:${msg}` });
      return;
    }

    // ── Analyze with Gemini + write results atomically ─────────────────────────
    try {
      const apiKey = geminiApiKey.value();
      const analysis = await analyzeImage(apiKey, imageBase64, mimeType);
      const embedding = await generateEmbedding(apiKey, analysis);

      await admin.firestore().runTransaction(async (tx) => {
        // Re-read quota inside transaction to guard against race conditions
        const freshUser = await tx.get(userRef);
        const freshData = freshUser.data() ?? {};
        const freshCount = (freshData.analyzedCount as number) ?? 0;
        const freshQuota =
          (freshData.freeQuota as number) ?? DEFAULT_FREE_QUOTA;

        if (freshCount >= freshQuota) {
          tx.update(wardrobeRef, { analyzeError: "quota_exceeded" });
          return;
        }

        // Update the wardrobe item with analysis results
        tx.update(wardrobeRef, {
          analyzed: true,
          analyzeError: admin.firestore.FieldValue.delete(),
          category: analysis.category,
          colors: analysis.colors,
          materials: analysis.materials,
          embedding,
        });

        // Upsert user document — preserve existing fields, increment count
        tx.set(
          userRef,
          {
            plan: freshData.plan ?? "free",
            freeQuota: freshQuota,
            analyzedCount: freshCount + 1,
          },
          { merge: true }
        );
      });
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      await wardrobeRef.update({ analyzeError: `analysis_failed:${msg}` });
    }
  }
);
