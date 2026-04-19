import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { defineSecret } from "firebase-functions/params";
import { FUNCTIONS_REGION } from "./functionsRegion";
import { analyzeWardrobeItemCore } from "./analyzeWardrobeCore";

const geminiApiKey = defineSecret("GEMINI_API_KEY");

export const analyzeWardrobeItemOnCreate = onDocumentCreated(
  {
    document: "users/{userId}/wardrobe/{mediaItemId}",
    region: FUNCTIONS_REGION,
    secrets: [geminiApiKey],
    timeoutSeconds: 300,
  },
  async (event) => {
    const data = event.data?.data();

    // Only process new items that are pending analysis
    if (!data || data.analyzed !== false) return;

    const { userId } = event.params;
    const thumbnailUrl = data.thumbnailUrl as string | undefined;
    const wardrobeRef = event.data!.ref;

    await analyzeWardrobeItemCore({
      userId,
      wardrobeRef,
      thumbnailUrl,
      geminiApiKey: geminiApiKey.value(),
    });
  }
);
