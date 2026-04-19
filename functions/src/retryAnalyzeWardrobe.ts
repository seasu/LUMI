import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import { FUNCTIONS_REGION } from "./functionsRegion";
import { analyzeWardrobeItemCore } from "./analyzeWardrobeCore";

const geminiApiKey = defineSecret("GEMINI_API_KEY");

interface RetryRequest {
  mediaItemId?: string;
}

/**
 * Manually re-run wardrobe analysis when the Firestore trigger did not fire
 * (e.g. items created before deploy) or left [analyzed]=false without analyzeError.
 */
export const retryAnalyzeWardrobeItem = onCall(
  {
    region: FUNCTIONS_REGION,
    secrets: [geminiApiKey],
    timeoutSeconds: 300,
  },
  async (request): Promise<{ ok: boolean; alreadyAnalyzed?: boolean }> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const { mediaItemId } = request.data as RetryRequest;
    if (!mediaItemId || typeof mediaItemId !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "mediaItemId is required."
      );
    }

    const userId = request.auth.uid;
    const wardrobeRef = admin
      .firestore()
      .doc(`users/${userId}/wardrobe/${mediaItemId}`);

    const snap = await wardrobeRef.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "Wardrobe item not found.");
    }

    const data = snap.data()!;
    if (data.analyzed === true) {
      return { ok: true, alreadyAnalyzed: true };
    }

    const thumbnailUrl = data.thumbnailUrl as string | undefined;

    await analyzeWardrobeItemCore({
      userId,
      wardrobeRef,
      thumbnailUrl,
      geminiApiKey: geminiApiKey.value(),
    });

    return { ok: true };
  }
);
