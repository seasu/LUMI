import * as admin from "firebase-admin";
import { analyzeImage, generateEmbedding } from "./gemini";
import { downloadImageForGemini } from "./imageDownload";

const DEFAULT_FREE_QUOTA = 100;

export interface AnalyzeWardrobeCoreParams {
  userId: string;
  wardrobeRef: admin.firestore.DocumentReference;
  thumbnailUrl: string | undefined;
  geminiApiKey: string;
}

/**
 * Runs Gemini analysis for one wardrobe doc and updates Firestore.
 * Used by Firestore trigger and manual retry callable.
 */
export async function analyzeWardrobeItemCore(
  params: AnalyzeWardrobeCoreParams
): Promise<void> {
  const { userId, wardrobeRef, thumbnailUrl, geminiApiKey } = params;

  try {
    if (!thumbnailUrl) {
      await wardrobeRef.update({ analyzeError: "missing_url" });
      return;
    }

    const userRef = admin.firestore().doc(`users/${userId}`);
    const userDoc = await userRef.get();
    const userData = userDoc.data() ?? {};
    const analyzedCount = (userData.analyzedCount as number) ?? 0;
    const freeQuota = (userData.freeQuota as number) ?? DEFAULT_FREE_QUOTA;

    if (analyzedCount >= freeQuota) {
      await wardrobeRef.update({ analyzeError: "quota_exceeded" });
      return;
    }

    let imageBase64: string;
    let mimeType: string;

    try {
      const downloaded = await downloadImageForGemini(thumbnailUrl);
      imageBase64 = downloaded.base64;
      mimeType = downloaded.mimeType;
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      await wardrobeRef.update({ analyzeError: `download_failed:${msg}` });
      return;
    }

    try {
      const analysis = await analyzeImage(geminiApiKey, imageBase64, mimeType);
      const embedding = await generateEmbedding(geminiApiKey, analysis);

      await admin.firestore().runTransaction(async (tx) => {
        const freshUser = await tx.get(userRef);
        const freshData = freshUser.data() ?? {};
        const freshCount = (freshData.analyzedCount as number) ?? 0;
        const freshQuota =
          (freshData.freeQuota as number) ?? DEFAULT_FREE_QUOTA;

        if (freshCount >= freshQuota) {
          tx.update(wardrobeRef, { analyzeError: "quota_exceeded" });
          return;
        }

        tx.update(wardrobeRef, {
          analyzed: true,
          analyzeError: admin.firestore.FieldValue.delete(),
          category: analysis.category,
          colors: analysis.colors,
          materials: analysis.materials,
          embedding,
        });

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
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    const safe = msg.slice(0, 500);
    try {
      await wardrobeRef.update({
        analyzeError: `trigger_failed:${safe}`,
      });
    } catch {
      // Ref update failed — avoid crashing the caller
    }
  }
}
