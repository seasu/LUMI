import * as admin from "firebase-admin";

admin.initializeApp();

export { analyzeClothing } from "./analyzeClothing";
export { compareClothing } from "./compareClothing";
export { getServerInfo } from "./serverInfo";
