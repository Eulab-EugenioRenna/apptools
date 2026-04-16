import dotenv from "dotenv"

dotenv.config()

const port = Number(process.env.PORT ?? "8787")
const maxUploadMb = Number(process.env.MAX_UPLOAD_MB ?? "8")

if (!Number.isFinite(port) || port <= 0) {
  throw new Error("Invalid PORT configuration")
}

if (!Number.isFinite(maxUploadMb) || maxUploadMb <= 0) {
  throw new Error("Invalid MAX_UPLOAD_MB configuration")
}

export const config = {
  port,
  maxUploadBytes: Math.floor(maxUploadMb * 1024 * 1024),
  pocketBaseUrl: (process.env.POCKETBASE_URL ?? "https://pocketbase.eulab.cloud").replace(/\/$/, ""),
  pocketBaseCollection: process.env.POCKETBASE_COLLECTION ?? "tools_ai",
  aiProvider: process.env.AI_PROVIDER ?? "mock",
  googleGenAiApiKey: process.env.GOOGLE_GENAI_API_KEY ?? "",
  googleGenAiModel: process.env.GOOGLE_GENAI_MODEL ?? "gemini-2.5-flash",
  openRouterApiKey: process.env.OPENROUTER_API_KEY ?? "",
  openRouterModel: process.env.OPENROUTER_MODEL ?? "google/gemini-2.5-flash",
  openRouterBaseUrl: (process.env.OPENROUTER_BASE_URL ?? "https://openrouter.ai/api/v1").replace(/\/$/, ""),
  openRouterAppUrl: process.env.OPENROUTER_APP_URL ?? "",
  openRouterAppName: process.env.OPENROUTER_APP_NAME ?? "AppSendTool",
  sourceDefault: process.env.SOURCE_DEFAULT ?? "ios-share-extension"
} as const
