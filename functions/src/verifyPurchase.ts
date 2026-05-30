/**
 * verifyPurchase — Cloud Function
 *
 * Validates an in-app purchase receipt/token with Apple or Google, then
 * updates the Firestore user document:
 *   - lumi_extra_100  → freeQuota += 100  (consumable)
 *   - lumi_pro_yearly → plan = 'pro'      (auto-renewable subscription)
 *
 * Platform setup required (one-time, done in consoles — not in code):
 *   iOS   : App Store Connect → App Information → App-Specific Shared Secret
 *           → store as Firebase secret APPLE_SHARED_SECRET
 *   Android: Play Console → Setup → API access → link this GCP project,
 *           then grant the Cloud Functions service account the role
 *           "Service Account User" + "Android Management API" viewer in IAM.
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { GoogleAuth } from "google-auth-library";
import { FUNCTIONS_REGION } from "./functionsRegion";

// APPLE_SHARED_SECRET is injected via .env.lumi-309ff at deploy time
// (set APPLE_SHARED_SECRET in GitHub Actions Secrets → flows into .env via workflow).
// Sandbox receipts are accepted without it; production subscriptions require the real value.
const PACKAGE_NAME = "io.github.seasu.lumi";
const APPLE_VERIFY_PROD = "https://buy.itunes.apple.com/verifyReceipt";
const APPLE_VERIFY_SANDBOX = "https://sandbox.itunes.apple.com/verifyReceipt";

// ── Apple receipt validation ──────────────────────────────────────────────────

async function verifyAppleReceipt(
  receiptData: string,
  sharedSecret: string,
  useSandbox = false
): Promise<boolean> {
  if (!sharedSecret) {
    console.warn(
      "verifyAppleReceipt: APPLE_SHARED_SECRET is empty — " +
      "subscription verification will fail (status 21004). " +
      "Set APPLE_SHARED_SECRET in GitHub Secrets and redeploy."
    );
  }
  const url = useSandbox ? APPLE_VERIFY_SANDBOX : APPLE_VERIFY_PROD;
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      "receipt-data": receiptData,
      password: sharedSecret,
      "exclude-old-transactions": true,
    }),
  });
  const json = (await res.json()) as { status: number };

  // 21007 means sandbox receipt sent to production — retry against sandbox
  if (json.status === 21007) {
    return verifyAppleReceipt(receiptData, sharedSecret, true);
  }

  if (json.status !== 0) {
    console.warn(
      `verifyAppleReceipt: Apple returned status=${json.status} sandbox=${useSandbox}`
    );
  }
  return json.status === 0;
}

// ── Google Play purchase validation ──────────────────────────────────────────

async function verifyAndroidPurchase(
  productId: string,
  purchaseToken: string,
  isSubscription: boolean
): Promise<boolean> {
  const auth = new GoogleAuth({
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  const authClient = await auth.getClient();
  const accessToken = await authClient.getAccessToken();
  const token = accessToken.token;
  if (!token) return false;

  const base =
    "https://androidpublisher.googleapis.com/androidpublisher/v3/applications";

  let url: string;
  if (isSubscription) {
    // subscriptions.v2 endpoint (modern; handles base plans)
    url = `${base}/${PACKAGE_NAME}/purchases/subscriptionsv2/tokens/${purchaseToken}`;
  } else {
    url = `${base}/${PACKAGE_NAME}/purchases/products/${productId}/tokens/${purchaseToken}`;
  }

  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!res.ok) {
    console.error(
      `Android purchase verify failed ${res.status}: ${await res.text()}`
    );
    return false;
  }

  const json = (await res.json()) as Record<string, unknown>;

  if (isSubscription) {
    // subscriptionState SUBSCRIPTION_STATE_ACTIVE = active & paid
    const state = json.subscriptionState as string | undefined;
    const valid =
      state === "SUBSCRIPTION_STATE_ACTIVE" ||
      state === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD";
    if (!valid) {
      console.warn(`verifyAndroidPurchase: subscriptionState=${state}`);
    }
    return valid;
  } else {
    // purchaseState: 0 = purchased, 1 = canceled, 2 = pending
    const purchaseState = json.purchaseState as number | undefined;
    if (purchaseState !== 0) {
      console.warn(`verifyAndroidPurchase: purchaseState=${purchaseState}`);
    }
    return purchaseState === 0;
  }
}

// ── Firestore update ──────────────────────────────────────────────────────────

async function applyPurchase(uid: string, productId: string): Promise<void> {
  const db = admin.firestore();
  const userRef = db.doc(`users/${uid}`);

  if (productId === "lumi_extra_100") {
    await db.runTransaction(async (t) => {
      const snap = await t.get(userRef);
      const current = (snap.data()?.freeQuota as number | undefined) ?? 30;
      t.update(userRef, { freeQuota: current + 100 });
    });
    console.log(`verifyPurchase: +100 quota applied uid=${uid}`);
  } else if (productId === "lumi_pro_yearly") {
    await userRef.update({ plan: "pro" });
    console.log(`verifyPurchase: plan=pro applied uid=${uid}`);
  } else {
    throw new HttpsError("invalid-argument", `Unknown productId: ${productId}`);
  }
}

// ── Cloud Function ────────────────────────────────────────────────────────────

export const verifyPurchase = onCall(
  { region: FUNCTIONS_REGION },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;

    const { platform, productId, purchaseToken, receiptData } =
      request.data as {
        platform: string;       // 'ios' | 'android'
        productId: string;      // 'lumi_extra_100' | 'lumi_pro_yearly'
        purchaseToken?: string; // Android only
        receiptData?: string;   // iOS only (base64 App Store receipt)
      };

    if (!platform || !productId) {
      throw new HttpsError(
        "invalid-argument",
        "platform and productId are required."
      );
    }

    const isSubscription = productId === "lumi_pro_yearly";
    let valid = false;

    if (platform === "ios") {
      if (!receiptData) {
        throw new HttpsError("invalid-argument", "receiptData required for iOS.");
      }
      valid = await verifyAppleReceipt(
        receiptData,
        process.env.APPLE_SHARED_SECRET ?? ""
      );
    } else if (platform === "android") {
      if (!purchaseToken) {
        throw new HttpsError(
          "invalid-argument",
          "purchaseToken required for Android."
        );
      }
      valid = await verifyAndroidPurchase(productId, purchaseToken, isSubscription);
    } else {
      throw new HttpsError("invalid-argument", `Unknown platform: ${platform}`);
    }

    if (!valid) {
      console.warn(
        `verifyPurchase: INVALID receipt uid=${uid} platform=${platform} product=${productId}`
      );
      throw new HttpsError(
        "permission-denied",
        "Purchase receipt validation failed."
      );
    }

    await applyPurchase(uid, productId);
    return { success: true };
  }
);
