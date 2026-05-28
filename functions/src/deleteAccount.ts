/**
 * deleteAccount — Cloud Function
 *
 * Permanently deletes the caller's account:
 *   1. Removes Firestore user document  (users/{uid})
 *   2. Deletes the Firebase Auth record
 *
 * Called from the Flutter profile page "刪除帳號" flow.
 * Apple App Store Guideline 5.1.1(v) requires in-app account deletion.
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { FUNCTIONS_REGION } from "./functionsRegion";

export const deleteAccount = onCall(
  { region: FUNCTIONS_REGION },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Must be signed in.");
    }

    const db = admin.firestore();

    // Delete Firestore user document.
    await db.doc(`users/${uid}`).delete();

    // Delete Firebase Auth record — must be last so the CF stays authorized.
    await admin.auth().deleteUser(uid);

    return { success: true };
  }
);
