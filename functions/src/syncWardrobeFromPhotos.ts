import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { FUNCTIONS_REGION } from "./functionsRegion";

const PHOTOS_BASE_URL = "https://photoslibrary.googleapis.com/v1";
const ALBUM_TITLE = "Lumi_Wardrobe";

interface SyncRequest {
  accessToken?: string;
}

interface SyncResult {
  albumId: string;
  created: number;
  skipped: number;
  skippedNoPreview: number;
  totalInAlbum: number;
}

async function photosGetJson(
  path: string,
  accessToken: string,
  query: Record<string, string>
): Promise<unknown> {
  const url = new URL(`${PHOTOS_BASE_URL}${path}`);
  for (const [k, v] of Object.entries(query)) {
    url.searchParams.set(k, v);
  }
  const res = await fetch(url.toString(), {
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

async function photosPostJson(
  path: string,
  accessToken: string,
  body: Record<string, unknown>
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

interface AlbumRow {
  id: string;
  title: string;
}

async function findLumiAlbumId(accessToken: string): Promise<string | null> {
  let pageToken: string | undefined;
  do {
    const q: Record<string, string> = { pageSize: "50" };
    if (pageToken) q.pageToken = pageToken;

    const data = (await photosGetJson("/albums", accessToken, q)) as {
      albums?: AlbumRow[];
      nextPageToken?: string;
    };
    const hit = data.albums?.find((a) => a.title === ALBUM_TITLE);
    if (hit) return hit.id;
    pageToken = data.nextPageToken;
  } while (pageToken);
  return null;
}

interface MediaRow {
  id: string;
  baseUrl?: string;
  mediaMetadata?: { creationTime?: string };
}

async function listAllMediaInAlbum(
  accessToken: string,
  albumId: string
): Promise<MediaRow[]> {
  const out: MediaRow[] = [];
  let pageToken: string | undefined;
  do {
    const data = (await photosPostJson("/mediaItems:search", accessToken, {
      albumId,
      pageSize: 100,
      pageToken,
    })) as {
      mediaItems?: MediaRow[];
      nextPageToken?: string;
    };
    if (data.mediaItems?.length) {
      out.push(...data.mediaItems);
    }
    pageToken = data.nextPageToken;
  } while (pageToken);
  return out;
}

function parseCreationTime(iso?: string): admin.firestore.Timestamp {
  if (!iso) return admin.firestore.Timestamp.now();
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return admin.firestore.Timestamp.now();
  return admin.firestore.Timestamp.fromDate(d);
}

/**
 * Lists media in the user's `Lumi_Wardrobe` album and creates Firestore wardrobe
 * docs for items missing locally (matched by Google Photos mediaItem id).
 * Requires OAuth scope `photoslibrary.readonly`.
 */
export const syncWardrobeFromPhotos = onCall(
  { region: FUNCTIONS_REGION, timeoutSeconds: 540 },
  async (request): Promise<SyncResult> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const { accessToken } = request.data as SyncRequest;
    if (!accessToken || typeof accessToken !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "accessToken is required for album sync."
      );
    }

    try {
      const userId = request.auth.uid;
      const db = admin.firestore();
      const userRef = db.collection("users").doc(userId);

      const userSnap = await userRef.get();
      let resolvedAlbumId =
        (userSnap.data()?.lumiWardrobeAlbumId as string | undefined) ?? null;

      if (resolvedAlbumId) {
        try {
          await photosPostJson("/mediaItems:search", accessToken, {
            albumId: resolvedAlbumId,
            pageSize: 1,
          });
        } catch {
          resolvedAlbumId = null;
        }
      }

      if (!resolvedAlbumId) {
        const found = await findLumiAlbumId(accessToken);
        if (!found) {
          throw new HttpsError(
            "not-found",
            `No album titled "${ALBUM_TITLE}" was found in Google Photos.`
          );
        }
        resolvedAlbumId = found;
        try {
          await userRef.set({ lumiWardrobeAlbumId: found }, { merge: true });
        } catch {
          // best-effort cache
        }
      }

      const mediaList = await listAllMediaInAlbum(
        accessToken,
        resolvedAlbumId
      );

      const existingSnap = await userRef.collection("wardrobe").get();
      const existingIds = new Set(existingSnap.docs.map((d) => d.id));

      let created = 0;
      let skipped = 0;
      let skippedNoPreview = 0;

      const batchSize = 400;
      let batch = db.batch();
      let ops = 0;

      const flush = async () => {
        if (ops === 0) return;
        await batch.commit();
        batch = db.batch();
        ops = 0;
      };

      for (const m of mediaList) {
        const mediaItemId = m.id;
        if (existingIds.has(mediaItemId)) {
          skipped++;
          continue;
        }

        const thumbnailUrl = m.baseUrl ?? "";
        if (!thumbnailUrl) {
          skippedNoPreview++;
          continue;
        }

        const wardRef = userRef.collection("wardrobe").doc(mediaItemId);
        const createdAt = parseCreationTime(m.mediaMetadata?.creationTime);
        const now = admin.firestore.Timestamp.now();

        batch.set(wardRef, {
          mediaItemId,
          category: "",
          colors: [],
          materials: [],
          embedding: [],
          thumbnailUrl,
          createdAt,
          thumbnailRefreshedAt: now,
          analyzed: false,
        });
        ops++;
        created++;
        existingIds.add(mediaItemId);

        if (ops >= batchSize) {
          await flush();
        }
      }

      await flush();

      return {
        albumId: resolvedAlbumId,
        created,
        skipped,
        skippedNoPreview,
        totalInAlbum: mediaList.length,
      };
    } catch (err) {
      if (err instanceof HttpsError) throw err;

      const raw = err instanceof Error ? err.message : String(err);
      const msg = raw.length > 900 ? `${raw.slice(0, 897)}…` : raw;

      // Callable surfaces generic "INTERNAL" if we throw plain Error — map HTTP hints.
      if (/\b403\b/.test(msg) || /PERMISSION_DENIED/i.test(msg)) {
        throw new HttpsError(
          "permission-denied",
          `Google Photos denied access (often missing photoslibrary.readonly). Sign out/in and accept Photos permissions. Details: ${msg}`
        );
      }
      if (/\b401\b/.test(msg) || /UNAUTHENTICATED/i.test(msg)) {
        throw new HttpsError(
          "unauthenticated",
          `Google access token expired or invalid. Sign in again. Details: ${msg}`
        );
      }

      throw new HttpsError(
        "failed-precondition",
        `syncWardrobeFromPhotos failed: ${msg}`
      );
    }
  }
);
