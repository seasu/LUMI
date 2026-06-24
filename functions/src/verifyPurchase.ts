/**
 * verifyPurchase — Cloud Function
 *
 * Validates an in-app purchase with the platform's official server-side API,
 * then updates the Firestore user document:
 *   - lumi_extra_100  → freeQuota += 100  (consumable)
 *   - lumi_pro_yearly → plan = 'pro'      (auto-renewable subscription)
 *
 * iOS uses the App Store Server API (not the deprecated verifyReceipt endpoint):
 *   https://developer.apple.com/documentation/appstoreserverapi
 *
 * Required one-time setup (project owner, NOT CI — run locally with your own credentials):
 *   firebase functions:secrets:set APPLE_API_KEY_ID      --project lumi-309ff
 *   firebase functions:secrets:set APPLE_API_ISSUER_ID   --project lumi-309ff
 *   firebase functions:secrets:set APPLE_API_PRIVATE_KEY --project lumi-309ff
 *
 *   APPLE_API_KEY_ID      — Key ID from App Store Connect → Users & Access → Integrations → In-App Purchase Keys
 *   APPLE_API_ISSUER_ID   — Issuer ID from the same page (UUID)
 *   APPLE_API_PRIVATE_KEY — raw content of the downloaded .p8 file (paste PEM as-is, no base64 needed)
 *
 * Android uses the Google Play Developer API (unchanged).
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import * as crypto from "node:crypto";
import { GoogleAuth } from "google-auth-library";
import { FUNCTIONS_REGION } from "./functionsRegion";

const appleApiKeyId = defineSecret("APPLE_API_KEY_ID");
const appleApiIssuerId = defineSecret("APPLE_API_ISSUER_ID");
const appleApiPrivateKey = defineSecret("APPLE_API_PRIVATE_KEY");

const BUNDLE_ID = "io.github.seasu.lumi";
const PACKAGE_NAME = "io.github.seasu.lumi";
const APP_STORE_API_PROD = "https://api.storekit.itunes.apple.com";
const APP_STORE_API_SANDBOX = "https://api.storekit-sandbox.itunes.apple.com";

// ── App Store Server API — JWT authentication ─────────────────────────────────

function generateAppStoreJWT(): string {
  const now = Math.floor(Date.now() / 1000);
  const keyId = appleApiKeyId.value();
  const issuerId = appleApiIssuerId.value();
  // Secret Manager 中可能以字面 \n 儲存（GitHub Actions env 注入常見），
  // 先將字面 \n 轉為真正的換行符，確保 PEM 格式正確。
  const rawPem = appleApiPrivateKey.value().replace(/\\n/g, "\n");

  if (!keyId || !issuerId || !rawPem) {
    throw new HttpsError(
      "failed-precondition",
      "Apple IAP not configured. " +
        "Run: firebase functions:secrets:set APPLE_API_KEY_ID / APPLE_API_ISSUER_ID / APPLE_API_PRIVATE_KEY --project lumi-309ff"
    );
  }

  // Diagnostic: log credential metadata (never log actual key values).
  console.log(
    `verifyPurchase: Apple credentials — keyId=${keyId} ` +
    `issuerId=${issuerId} ` +
    `pemBytes=${rawPem.length} pemHeader="${rawPem.split("\n")[0]}"`
  );

  const header = Buffer.from(
    JSON.stringify({ alg: "ES256", kid: keyId, typ: "JWT" })
  ).toString("base64url");
  const payload = Buffer.from(
    JSON.stringify({
      iss: issuerId,
      iat: now,
      exp: now + 900,
      aud: "appstoreconnect-v1",
      bid: BUNDLE_ID,
    })
  ).toString("base64url");

  const signingInput = `${header}.${payload}`;
  const privateKey = crypto.createPrivateKey(rawPem);
  // IEEE P1363 format (R||S fixed-length) is required by JWS ES256 spec.
  const sig = crypto.sign("sha256", Buffer.from(signingInput), {
    key: privateKey,
    dsaEncoding: "ieee-p1363",
  });
  return `${signingInput}.${sig.toString("base64url")}`;
}

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
  useSandbox = false
): Promise<AppStoreTransactionPayload> {
  const baseUrl = useSandbox ? APP_STORE_API_SANDBOX : APP_STORE_API_PROD;

  let token: string;
  try {
    token = generateAppStoreJWT();
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    const msg = err instanceof Error ? err.message : String(err);
    console.error("verifyPurchase: JWT generation failed:", msg);
    throw new HttpsError("internal", "Failed to generate App Store JWT. Check APPLE_API_PRIVATE_KEY format.");
  }

  let res: Response;
  try {
    res = await fetch(
      `${baseUrl}/inApps/v1/transactions/${transactionId}`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error("verifyPurchase: network error reaching App Store API:", msg);
    throw new HttpsError("internal", "Network error reaching App Store Server API.");
  }

  if (res.status === 401) {
    console.error("verifyPurchase: App Store Server API 401 — check API key credentials");
    throw new HttpsError("internal", "Apple API authentication failed. Check APPLE_API_* secrets.");
  }

  if (!res.ok) {
    let errBody: { errorCode?: number; errorMessage?: string };
    try {
      errBody = (await res.json()) as { errorCode?: number; errorMessage?: string };
    } catch {
      throw new HttpsError(
        "internal",
        `App Store Server API returned HTTP ${res.status} with non-JSON body.`
      );
    }
    console.warn(
      `verifyPurchase: App Store API HTTP ${res.status} sandbox=${useSandbox}`,
      errBody
    );
    // 4040010 = TRANSACTION_ID_NOT_FOUND on production → transaction is from sandbox
    if (!useSandbox && errBody.errorCode === 4040010) {
      console.log(`verifyPurchase: not on production, retrying sandbox`);
      return verifyAppStoreTransaction(transactionId, expectedProductId, true);
    }
    throw new HttpsError("permission-denied", "Transaction not found or invalid.");
  }

  let okBody: { signedTransactionInfo?: string };
  try {
    okBody = (await res.json()) as { signedTransactionInfo?: string };
  } catch {
    throw new HttpsError("internal", "App Store Server API returned non-JSON success response.");
  }

  if (!okBody.signedTransactionInfo) {
    console.error("verifyPurchase: response missing signedTransactionInfo field", okBody);
    throw new HttpsError("internal", "App Store Server API response missing signedTransactionInfo.");
  }

  // Decode the JWS payload. The response originated from Apple's authenticated
  // API endpoint — signature verification is redundant here.
  const parts = okBody.signedTransactionInfo.split(".");
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
      // Use set+merge so this works even if the user document does not yet exist.
      t.set(userRef, { freeQuota: current + 100 }, { merge: true });
    });
    console.log(`verifyPurchase: +100 quota applied uid=${uid}`);
  } else if (productId === "lumi_pro_yearly") {
    // Use set+merge so this works even if the user document does not yet exist.
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
        productId: string;       // 'lumi_extra_100' | 'lumi_pro_yearly'
        transactionId?: string;  // iOS: StoreKit transactionIdentifier
        purchaseToken?: string;  // Android: Play purchase token
      };

    if (!platform || !productId) {
      throw new HttpsError("invalid-argument", "platform and productId are required.");
    }

    const isSubscription = productId === "lumi_pro_yearly";
    console.log(
      `verifyPurchase: start uid=${uid} platform=${platform} product=${productId}`
    );

    if (platform === "ios") {
      if (!transactionId) {
        throw new HttpsError("invalid-argument", "transactionId required for iOS.");
      }

      const tx = await verifyAppStoreTransaction(transactionId, productId);
      console.log(
        `verifyPurchase: Apple confirmed transactionId=${transactionId} type=${tx.type}`
      );

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
