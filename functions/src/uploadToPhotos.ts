import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

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

async function photosGet(path: string, accessToken: string): Promise<unknown> {
  const res = await fetch(`${PHOTOS_BASE_URL}${path}`, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!res.ok) throw new Error(`GET ${path} failed: ${res.status}`);
  return res.json();
}

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

// ── Album management ──────────────────────────────────────────────────────────

async function findAlbum(accessToken: string): Promise<string | null> {
  let pageToken: string | undefined;

  do {
    const url =
      `/albums?pageSize=50` + (pageToken ? `&pageToken=${pageToken}` : "");
    const data = (await photosGet(url, accessToken)) as {
      albums?: { id: string; title: string }[];
      nextPageToken?: string;
    };

    const match = data.albums?.find((a) => a.title === ALBUM_TITLE);
    if (match) return match.id;

    pageToken = data.nextPageToken;
  } while (pageToken);

  return null;
}

async function createAlbum(accessToken: string): Promise<string> {
  const data = (await photosPost("/albums", accessToken, {
    album: { title: ALBUM_TITLE },
  })) as { id: string };
  return data.id;
}

/**
 * Returns the Lumi_Wardrobe albumId, using Firestore as cache.
 * Validates the cached albumId before returning it.
 */
async function getOrCreateAlbum(
  accessToken: string,
  userId: string
): Promise<string> {
  const db = admin.firestore();
  const ref = db.collection("users").doc(userId);
  const snap = await ref.get();
  const cachedAlbumId = snap.data()?.lumiWardrobeAlbumId as string | undefined;

  // Validate cached albumId
  if (cachedAlbumId) {
    try {
      await photosGet(`/albums/${cachedAlbumId}`, accessToken);
      return cachedAlbumId;
    } catch {
      // Cached ID is invalid, fall through to search
    }
  }

  // Search existing albums
  let albumId = await findAlbum(accessToken);

  // Create if not found
  if (!albumId) {
    albumId = await createAlbum(accessToken);
  }

  // Cache the albumId in Firestore
  await ref.set({ lumiWardrobeAlbumId: albumId }, { merge: true });

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
  })) as {
    newMediaItemResults: {
      status: { message: string };
      mediaItem?: { id: string; baseUrl: string };
    }[];
  };

  const result = data.newMediaItemResults?.[0];
  if (!result?.mediaItem) {
    throw new Error(
      `createMediaItem failed: ${result?.status?.message ?? "unknown error"}`
    );
  }

  return {
    mediaItemId: result.mediaItem.id,
    thumbnailUrl: result.mediaItem.baseUrl,
  };
}

// ── Callable Function ─────────────────────────────────────────────────────────

export const uploadToPhotos = onCall(
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
      const msg = err instanceof Error ? err.message : String(err);
      throw new HttpsError("internal", `Upload failed: ${msg}`);
    }
  }
);
