import * as admin from "firebase-admin";

admin.initializeApp();

export { analyzeClothing } from "./analyzeClothing";
export { deleteAccount } from "./deleteAccount";
export { getServerInfo } from "./serverInfo";
export { verifyPurchase } from "./verifyPurchase";
