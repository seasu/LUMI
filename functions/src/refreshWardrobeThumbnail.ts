import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { FUNCTIONS_REGION } from "./functionsRegion";

const PHOTOS_BASE_URL = "https://photoslibrary.googleapis.com/v1";

interface RefreshRequest {
  accessToken?: string;
  mediaItemId?: string;
}

interface RefreshResult {
  thumbnailUrl: string;
}

/**
 * Server-side GET mediaItems/{id} — Flutter Web cannot call Photos API directly (no CORS).
 */
export const refreshWardrobeThumbnail = onCall(
  { region: FUNCTIONS_REGION, timeoutSeconds: 60 },
  async (request): Promise<RefreshResult> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const { accessToken, mediaItemId } = request.data as RefreshRequest;
    if (!accessToken || typeof accessToken !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "accessToken is required."
      );
    }
    if (!mediaItemId || typeof mediaItemId !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "mediaItemId is required."
      );
    }

    const userId = request.auth.uid;
    const url = `${PHOTOS_BASE_URL}/mediaItems/${encodeURIComponent(mediaItemId)}`;

    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });

    if (!res.ok) {
      const body = await res.text();
      throw new HttpsError(
        "permission-denied",
        `Photos API GET mediaItems failed: ${res.status} ${body}`
      );
    }

    const data = (await res.json()) as {
      baseUrl?: string;
    };
    const thumbnailUrl = data.baseUrl;
    if (!thumbnailUrl) {
      throw new HttpsError(
        "failed-precondition",
        "Photos API returned no baseUrl."
      );
    }

    const now = admin.firestore.Timestamp.now();
    await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .collection("wardrobe")
      .doc(mediaItemId)
      .update({
        thumbnailUrl,
        thumbnailRefreshedAt: now,
      });

    return { thumbnailUrl };
  }
);
