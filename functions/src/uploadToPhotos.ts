import { onCall, HttpsError } from "firebase-functions/v2/https";

// Implemented in segment 2/4
export const uploadToPhotos = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  throw new HttpsError("unimplemented", "uploadToPhotos not yet implemented.");
});
