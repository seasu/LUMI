import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { FUNCTIONS_REGION } from "./functionsRegion";

const PHOTOS_BASE_URL = "https://photoslibrary.googleapis.com/v1";
const ALBUM_TITLE = "Lumi_Wardrobe";

interface UploadToPhotosData {
  imageBase64: string;
  mimeType: string;
  filename: string;
  accessToken: string;
}

interface UploadToPhotosResult {
  mediaItemId: string;
  thumbnailUrl: string;
}

// ── Helpers ──────────────────────────────────────────────────────────────────

async function photosPost(
  path: string,
  accessToken: string,
  body: unknown
): Promise<unknown> {
  const res = await fetch(`${PHOTOS_BASE_URL}${path}`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`POST ${path} failed: ${res.status} – ${err}`);
  }
  return res.json();
}

async function photosGet(path: string, accessToken: string): Promise<unknown> {
  const res = await fetch(`${PHOTOS_BASE_URL}${path}`, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`GET ${path} failed: ${res.status} – ${err}`);
  }
  return res.json();
}

// ── Album management ──────────────────────────────────────────────────────────

async function createAlbum(accessToken: string): Promise<string> {
  const data = (await photosPost("/albums", accessToken, {
    album: { title: ALBUM_TITLE },
  })) as { id: string };
  return data.id;
}

async function cacheAlbumId(userId: string, albumId: string): Promise<void> {
  try {
    const db = admin.firestore();
    await db.collection("users").doc(userId).set(
      { lumiWardrobeAlbumId: albumId },
      { merge: true }
    );
  } catch {
    // Caching is best-effort only.
  }
}

/**
 * Returns the Lumi_Wardrobe albumId.
 * Uses Firestore as a cache. On cache miss, creates a new album via the
 * Photos API (requires only photoslibrary.appendonly scope — no GET /albums).
 */
async function getOrCreateAlbum(
  accessToken: string,
  userId: string
): Promise<string> {
  // ── Try Firestore cache ───────────────────────────────────────────────────
  let firestoreRef: admin.firestore.DocumentReference | undefined;
  try {
    const db = admin.firestore();
    firestoreRef = db.collection("users").doc(userId);
    const snap = await firestoreRef.get();
    const cachedAlbumId = snap.data()?.lumiWardrobeAlbumId as
      | string
      | undefined;

    if (cachedAlbumId) {
      // Trust the cached ID — app-created albums persist until the user
      // manually deletes them. Avoid a GET /albums call which requires
      // photoslibrary.readonly; appendonly is the only scope we request.
      return cachedAlbumId;
    }
  } catch {
    // Firestore not accessible — continue without cache
    firestoreRef = undefined;
  }

  // ── Create album via Photos API (appendonly scope is sufficient) ──────────
  const albumId = await createAlbum(accessToken);

  // ── Write cache (best-effort) ─────────────────────────────────────────────
  if (firestoreRef) {
    try {
      await firestoreRef.set({ lumiWardrobeAlbumId: albumId }, { merge: true });
    } catch {
      // Silently ignore — caching is an optimisation, not a requirement
    }
  }

  return albumId;
}

// ── Upload logic ──────────────────────────────────────────────────────────────

async function uploadBytes(
  accessToken: string,
  imageBase64: string,
  mimeType: string,
  filename: string
): Promise<string> {
  const imageBuffer = Buffer.from(imageBase64, "base64");

  const res = await fetch(`${PHOTOS_BASE_URL}/uploads`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/octet-stream",
      "X-Goog-Upload-Protocol": "raw",
      "X-Goog-Upload-File-Name": filename,
      "X-Goog-Upload-Content-Type": mimeType,
    },
    body: imageBuffer,
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Upload bytes failed: ${res.status} – ${err}`);
  }

  return res.text(); // uploadToken
}

async function createMediaItem(
  accessToken: string,
  uploadToken: string,
  albumId: string,
  filename: string
): Promise<{ mediaItemId: string; thumbnailUrl: string }> {
  const data = (await photosPost("/mediaItems:batchCreate", accessToken, {
    albumId,
    newMediaItems: [
      {
        description: filename,
        simpleMediaItem: { uploadToken, fileName: filename },
      },
    ],
  })  ) as {
    newMediaItemResults: {
      status: { message: string };
      mediaItem?: {
        id: string;
        baseUrl?: string;
        productUrl?: string;
      };
    }[];
  };

  const result = data.newMediaItemResults?.[0];
  if (!result?.mediaItem) {
    throw new Error(
      `createMediaItem failed: ${result?.status?.message ?? "unknown error"}`
    );
  }

  const { id, baseUrl } = result.mediaItem;
  let thumbnailUrl = baseUrl ?? "";
  if (!thumbnailUrl) {
    const mediaItem = (await photosGet(
      `/mediaItems/${encodeURIComponent(id)}`,
      accessToken
    )) as {
      baseUrl?: string;
    };
    thumbnailUrl = mediaItem.baseUrl ?? "";
  }
  if (!thumbnailUrl) {
    throw new Error(
      `createMediaItem missing baseUrl for ${id} (Photos browser productUrl is not usable as an image source)`
    );
  }

  return {
    mediaItemId: id,
    thumbnailUrl,
  };
}

// ── Callable Function ─────────────────────────────────────────────────────────

export const uploadToPhotos = onCall(
  { region: FUNCTIONS_REGION },
  async (request): Promise<UploadToPhotosResult> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const { imageBase64, mimeType, filename, accessToken } =
      request.data as UploadToPhotosData;

    if (!imageBase64 || !mimeType || !filename || !accessToken) {
      throw new HttpsError(
        "invalid-argument",
        "imageBase64, mimeType, filename, and accessToken are required."
      );
    }

    const userId = request.auth.uid;

    try {
      const albumId = await getOrCreateAlbum(accessToken, userId);
      const uploadToken = await uploadBytes(
        accessToken,
        imageBase64,
        mimeType,
        filename
      );
      return await createMediaItem(accessToken, uploadToken, albumId, filename);
    } catch (err) {
      // Recovery path:
      // If cached albumId became stale (e.g. user deleted the album manually),
      // recreate album and retry once end-to-end.
      const msg = err instanceof Error ? err.message : String(err);
      const albumGone =
        msg.includes("Album not found") ||
        msg.includes("NOT_FOUND") ||
        msg.includes("createMediaItem failed");

      if (albumGone) {
        try {
          const freshAlbumId = await createAlbum(accessToken);
          await cacheAlbumId(userId, freshAlbumId);
          const retryUploadToken = await uploadBytes(
            accessToken,
            imageBase64,
            mimeType,
            filename
          );
          return await createMediaItem(
            accessToken,
            retryUploadToken,
            freshAlbumId,
            filename
          );
        } catch (retryErr) {
          const retryMsg =
            retryErr instanceof Error ? retryErr.message : String(retryErr);
          throw new HttpsError("internal", `Upload failed after retry: ${retryMsg}`);
        }
      }

      throw new HttpsError("internal", `Upload failed: ${msg}`);
    }
  }
);
