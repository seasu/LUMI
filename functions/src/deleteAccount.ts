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

    console.log(`deleteAccount: start uid=${uid}`);

    const db = admin.firestore();

    // Step 1: Delete Firestore user document.
    try {
      await db.doc(`users/${uid}`).delete();
      console.log(`deleteAccount: Firestore doc deleted uid=${uid}`);
    } catch (err) {
      console.error(`deleteAccount: Firestore delete failed uid=${uid}`, err);
      throw new HttpsError("internal", "Failed to delete user data.");
    }

    // Step 2: Delete Firebase Auth record — must be last so the CF stays authorized.
    try {
      await admin.auth().deleteUser(uid);
      console.log(`deleteAccount: Auth user deleted uid=${uid}`);
    } catch (err) {
      console.error(`deleteAccount: Auth delete failed uid=${uid}`, err);
      throw new HttpsError("internal", "Failed to delete auth account.");
    }

    console.log(`deleteAccount: complete uid=${uid}`);
    return { success: true };
  }
);
