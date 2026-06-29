/**
 * verifyPurchase — Cloud Function
 *
 * Validates an in-app purchase with the platform's official server-side API,
 * then updates the Firestore user document:
 *   - lumi_extra_100  → freeQuota += 100  (consumable)
 *   - lumi_pro_yearly_v2 → plan = 'pro'   (auto-renewable subscription)
 *
 * iOS uses the App Store Server API via Apple's official Node.js library:
 *   https://github.com/apple/app-store-server-library-node
 *
 * Required one-time setup (project owner, NOT CI — run locally with your own credentials):
 *   firebase functions:secrets:set APPLE_API_KEY_ID      --project lumi-309ff
 *   firebase functions:secrets:set APPLE_API_ISSUER_ID   --project lumi-309ff
 *   firebase functions:secrets:set APPLE_API_PRIVATE_KEY --project lumi-309ff
 *
 *   APPLE_API_KEY_ID      — Key ID from App Store Connect → Users & Access → Integrations → In-App Purchase Keys
 *   APPLE_API_ISSUER_ID   — Issuer ID from the same page (UUID)
 *   APPLE_API_PRIVATE_KEY — raw content of the downloaded .p8 file (paste PEM as-is, newlines as \n or literal)
 *
 * Android uses the Google Play Developer API (unchanged).
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import * as crypto from "node:crypto";
import { GoogleAuth } from "google-auth-library";
import {
  AppStoreServerAPIClient,
  Environment,
  APIException,
  APIError,
} from "@apple/app-store-server-library";
import { FUNCTIONS_REGION } from "./functionsRegion";

const appleApiKeyId = defineSecret("APPLE_API_KEY_ID");
const appleApiIssuerId = defineSecret("APPLE_API_ISSUER_ID");
const appleApiPrivateKey = defineSecret("APPLE_API_PRIVATE_KEY");

const BUNDLE_ID = "io.github.seasu.lumi";
const PACKAGE_NAME = "io.github.seasu.lumi";

// ── App Store Server API — transaction verification ───────────────────────────

interface AppStoreTransactionPayload {
  bundleId: string;
  productId: string;
  transactionId: string;
  originalTransactionId: string;
  /** 'Consumable' | 'Non-Consumable' | 'Auto-Renewable Subscription' | … */
  type: string;
  /** Subscription expiry — Unix epoch ms. Only present for subscriptions. */
  expiresDate?: number;
}

async function verifyAppStoreTransaction(
  transactionId: string,
  expectedProductId: string,
  environment: Environment = Environment.PRODUCTION
): Promise<AppStoreTransactionPayload> {
  const keyId = appleApiKeyId.value();
  const issuerId = appleApiIssuerId.value();
  // Secret Manager may store literal \n — normalise to real newlines for PEM.
  const rawPem = appleApiPrivateKey.value().replace(/\\n/g, "\n");

  if (!keyId || !issuerId || !rawPem) {
    throw new HttpsError(
      "failed-precondition",
      "Apple IAP not configured. " +
        "Run: firebase functions:secrets:set APPLE_API_KEY_ID / APPLE_API_ISSUER_ID / APPLE_API_PRIVATE_KEY --project lumi-309ff"
    );
  }

  let pubkeyFingerprint = "unknown";
  try {
    const privKey = crypto.createPrivateKey(rawPem);
    const pubKey = crypto.createPublicKey(privKey);
    const der = pubKey.export({ type: "spki", format: "der" }) as Buffer;
    pubkeyFingerprint = crypto.createHash("sha256").update(der).digest("hex");
  } catch { /* non-fatal */ }

  console.log(
    `verifyPurchase: Apple credentials — keyId=${keyId} ` +
    `issuerId=${issuerId} ` +
    `pemBytes=${rawPem.length} pemHeader="${rawPem.split("\n")[0]}" ` +
    `pubkeyFingerprint=${pubkeyFingerprint} ` +
    `environment=${environment}`
  );

  const client = new AppStoreServerAPIClient(
    rawPem,
    keyId,
    issuerId,
    BUNDLE_ID,
    environment
  );

  let signedTransactionInfo: string;
  try {
    const response = await client.getTransactionInfo(transactionId);
    if (!response.signedTransactionInfo) {
      console.error("verifyPurchase: response missing signedTransactionInfo", response);
      throw new HttpsError("internal", "App Store Server API response missing signedTransactionInfo.");
    }
    signedTransactionInfo = response.signedTransactionInfo;
  } catch (err) {
    if (err instanceof HttpsError) throw err;

    if (err instanceof APIException) {
      console.warn(
        `verifyPurchase: APIException httpStatus=${err.httpStatusCode} ` +
        `apiError=${err.apiError} message="${err.errorMessage}" environment=${environment}`
      );
      // TestFlight/sandbox transactions don't exist in the Production environment.
      // Production may reject them with TRANSACTION_ID_NOT_FOUND — or, while the app
      // has no App Store release yet, reject auth outright with 401 (the Production
      // App Store Server API doesn't recognise the app). In both cases the real
      // transaction lives in Sandbox, so retry there. Verified out-of-band: these
      // credentials authenticate successfully against Sandbox; Production 401s only
      // because the app isn't live on the App Store yet.
      if (
        environment === Environment.PRODUCTION &&
        (err.apiError === APIError.TRANSACTION_ID_NOT_FOUND ||
          err.httpStatusCode === 401)
      ) {
        console.log(
          `verifyPurchase: production failed (httpStatus=${err.httpStatusCode}), retrying sandbox`
        );
        return verifyAppStoreTransaction(transactionId, expectedProductId, Environment.SANDBOX);
      }
      // A 401 from Sandbox (i.e. after the retry above) means the credentials
      // themselves are wrong — not just an environment mismatch.
      if (err.httpStatusCode === 401) {
        throw new HttpsError(
          "internal",
          "Apple API authentication failed (401) in sandbox. Check APPLE_API_KEY_ID, APPLE_API_ISSUER_ID, and APPLE_API_PRIVATE_KEY secrets — ensure APPLE_API_KEY_ID is an In-App Purchase key (not an App Store Connect API key)."
        );
      }
      throw new HttpsError("permission-denied", "Transaction not found or invalid.");
    }

    const msg = err instanceof Error ? err.message : String(err);
    console.error("verifyPurchase: unexpected error from AppStoreServerAPIClient:", msg);
    throw new HttpsError("internal", `App Store Server API error: ${msg}`);
  }

  // Decode the JWS payload (parts[1] is base64url-encoded JSON).
  // The response originated from Apple's authenticated API endpoint; we trust it.
  const parts = signedTransactionInfo.split(".");
  if (parts.length !== 3) {
    throw new HttpsError("internal", "Malformed JWS from App Store Server API.");
  }

  let payload: AppStoreTransactionPayload;
  try {
    payload = JSON.parse(
      Buffer.from(parts[1], "base64url").toString("utf8")
    ) as AppStoreTransactionPayload;
  } catch {
    throw new HttpsError("internal", "Failed to decode JWS payload from App Store Server API.");
  }

  if (payload.bundleId !== BUNDLE_ID) {
    console.error(`verifyPurchase: bundle ID mismatch — got ${payload.bundleId}`);
    throw new HttpsError("permission-denied", "Transaction bundle ID mismatch.");
  }
  if (payload.productId !== expectedProductId) {
    console.error(
      `verifyPurchase: product ID mismatch — got ${payload.productId}, expected ${expectedProductId}`
    );
    throw new HttpsError("permission-denied", "Transaction product ID mismatch.");
  }

  console.log(
    `verifyPurchase: Apple confirmed transactionId=${payload.transactionId} ` +
    `productId=${payload.productId} type=${payload.type} environment=${environment}`
  );
  return payload;
}

// ── Google Play Developer API — purchase validation ───────────────────────────

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

  const url = isSubscription
    ? `${base}/${PACKAGE_NAME}/purchases/subscriptionsv2/tokens/${purchaseToken}`
    : `${base}/${PACKAGE_NAME}/purchases/products/${productId}/tokens/${purchaseToken}`;

  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  });

  if (!res.ok) {
    console.error(
      `verifyPurchase: Android API ${res.status}: ${await res.text()}`
    );
    return false;
  }

  const json = (await res.json()) as Record<string, unknown>;

  if (isSubscription) {
    const state = json.subscriptionState as string | undefined;
    const valid =
      state === "SUBSCRIPTION_STATE_ACTIVE" ||
      state === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD";
    if (!valid) console.warn(`verifyPurchase: Android subscriptionState=${state}`);
    return valid;
  } else {
    const purchaseState = json.purchaseState as number | undefined;
    if (purchaseState !== 0)
      console.warn(`verifyPurchase: Android purchaseState=${purchaseState}`);
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
      t.set(userRef, { freeQuota: current + 100 }, { merge: true });
    });
    console.log(`verifyPurchase: +100 quota applied uid=${uid}`);
  } else if (productId === "lumi_pro_yearly_v2") {
    await userRef.set({ plan: "pro" }, { merge: true });
    console.log(`verifyPurchase: plan=pro applied uid=${uid}`);
  } else {
    throw new HttpsError("invalid-argument", `Unknown productId: ${productId}`);
  }
}

// ── Cloud Function ────────────────────────────────────────────────────────────

export const verifyPurchase = onCall(
  {
    region: FUNCTIONS_REGION,
    secrets: [appleApiKeyId, appleApiIssuerId, appleApiPrivateKey],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;

    const { platform, productId, transactionId, purchaseToken } =
      request.data as {
        platform: string;        // 'ios' | 'android'
        productId: string;       // 'lumi_extra_100' | 'lumi_pro_yearly_v2'
        transactionId?: string;  // iOS: StoreKit transactionIdentifier
        purchaseToken?: string;  // Android: Play purchase token
      };

    if (!platform || !productId) {
      throw new HttpsError("invalid-argument", "platform and productId are required.");
    }

    const isSubscription = productId === "lumi_pro_yearly_v2";
    console.log(
      `verifyPurchase: start uid=${uid} platform=${platform} product=${productId}`
    );

    if (platform === "ios") {
      if (!transactionId) {
        throw new HttpsError("invalid-argument", "transactionId required for iOS.");
      }

      const tx = await verifyAppStoreTransaction(transactionId, productId);

      // Reject expired subscriptions — but not consumables (no expiresDate).
      if (isSubscription && tx.expiresDate != null && tx.expiresDate < Date.now()) {
        console.warn(
          `verifyPurchase: subscription expired uid=${uid} expiresDate=${new Date(tx.expiresDate).toISOString()}`
        );
        throw new HttpsError(
          "failed-precondition",
          "Subscription has expired. Please renew to continue."
        );
      }
    } else if (platform === "android") {
      if (!purchaseToken) {
        throw new HttpsError("invalid-argument", "purchaseToken required for Android.");
      }
      const valid = await verifyAndroidPurchase(productId, purchaseToken, isSubscription);
      if (!valid) {
        throw new HttpsError("permission-denied", "Purchase receipt validation failed.");
      }
    } else {
      throw new HttpsError("invalid-argument", `Unknown platform: ${platform}`);
    }

    await applyPurchase(uid, productId);
    console.log(`verifyPurchase: complete uid=${uid} product=${productId}`);
    return { success: true };
  }
);
