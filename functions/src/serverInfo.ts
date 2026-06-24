import { onCall } from "firebase-functions/v2/https";
import { FUNCTIONS_REGION } from "./functionsRegion";

// Injected at deploy time by functions-deploy.yml from package.json.
export const FUNCTIONS_VERSION = "1.0.25";

export const getServerInfo = onCall(
  { region: FUNCTIONS_REGION },
  async (_request) => {
    return { version: FUNCTIONS_VERSION };
  }
);
