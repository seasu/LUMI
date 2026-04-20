/**
 * Fetch image bytes from a URL (e.g. Google Photos baseUrl) for Gemini vision.
 * Handles HTML error pages (wrong content-type), charset in Content-Type header,
 * and retries without Google Photos size suffix when transform returns HTML.
 */

const ALLOWED_IMAGE_MIME = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
  "image/heic",
  "image/heif",
]);

function stripCharset(contentType: string): string {
  const main = contentType.split(";")[0]?.trim().toLowerCase() ?? "";
  return main;
}

/** Sniff JPEG / PNG / WebP from first bytes when Content-Type is wrong. */
function sniffImageMime(buffer: ArrayBuffer): string | null {
  const u = new Uint8Array(buffer);
  if (u.length < 12) return null;
  if (u[0] === 0xff && u[1] === 0xd8 && u[2] === 0xff) return "image/jpeg";
  if (
    u[0] === 0x89 &&
    u[1] === 0x50 &&
    u[2] === 0x4e &&
    u[3] === 0x47
  ) {
    return "image/png";
  }
  if (
    u[0] === 0x52 &&
    u[1] === 0x49 &&
    u[2] === 0x46 &&
    u[3] === 0x46 &&
    u.length >= 12
  ) {
    const tag = String.fromCharCode(u[8], u[9], u[10], u[11]);
    if (tag === "WEBP") return "image/webp";
  }
  return null;
}

function isHtmlMime(ct: string): boolean {
  return ct.startsWith("text/html") || ct === "application/xhtml+xml";
}

export interface DownloadedImage {
  base64: string;
  mimeType: string;
}

/**
 * Downloads image for Gemini inlineData. Retries without `=w*h*` suffix if body is HTML.
 */
export async function downloadImageForGemini(
  thumbnailUrl: string
): Promise<DownloadedImage> {
  const trimmed = thumbnailUrl.trim();
  if (!trimmed) {
    throw new Error("empty thumbnail URL");
  }

  const candidates = [`${trimmed}=w2048-h2048`, trimmed];
  let lastErr = "";

  for (let i = 0; i < candidates.length; i++) {
    const url = candidates[i];
    try {
      const response = await fetch(url);
      if (!response.ok) {
        lastErr = `HTTP ${response.status} ${response.statusText}`;
        continue;
      }

      const buffer = await response.arrayBuffer();
      const rawCt = response.headers.get("content-type") ?? "";
      let mimeType = stripCharset(rawCt);

      if (mimeType === "application/octet-stream" || mimeType === "") {
        const sniffed = sniffImageMime(buffer);
        if (sniffed) mimeType = sniffed;
      }

      if (isHtmlMime(mimeType) || mimeType === "text/plain") {
        lastErr = `Got ${mimeType || "unknown"} instead of image (possible expired URL)`;
        continue;
      }

      if (!mimeType.startsWith("image/")) {
        const sniffed = sniffImageMime(buffer);
        if (sniffed) {
          mimeType = sniffed;
        } else {
          lastErr = `Unsupported Content-Type: ${mimeType}`;
          continue;
        }
      }

      if (!ALLOWED_IMAGE_MIME.has(mimeType)) {
        const sniffed = sniffImageMime(buffer);
        mimeType = sniffed ?? "image/jpeg";
      }

      return {
        base64: Buffer.from(buffer).toString("base64"),
        mimeType,
      };
    } catch (err) {
      lastErr = err instanceof Error ? err.message : String(err);
    }
  }

  throw new Error(lastErr || "failed to download image");
}
