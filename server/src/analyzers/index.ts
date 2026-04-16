import { config } from "../config.js"
import type { Analyzer } from "../types.js"
import { GoogleGenAiAnalyzer } from "./googleGenAiAnalyzer.js"
import { MockAnalyzer } from "./mockAnalyzer.js"
import { OpenRouterAnalyzer } from "./openRouterAnalyzer.js"

export function createAnalyzer(): Analyzer {
  if (config.aiProvider === "google") {
    if (!config.googleGenAiApiKey) {
      throw new Error("GOOGLE_GENAI_API_KEY is required when AI_PROVIDER=google")
    }

    return new GoogleGenAiAnalyzer(config.googleGenAiApiKey, config.googleGenAiModel)
  }

  if (config.aiProvider === "openrouter") {
    if (!config.openRouterApiKey) {
      throw new Error("OPENROUTER_API_KEY is required when AI_PROVIDER=openrouter")
    }

    return new OpenRouterAnalyzer(
      config.openRouterApiKey,
      config.openRouterModel,
      config.openRouterBaseUrl,
      config.openRouterAppUrl,
      config.openRouterAppName
    )
  }

  return new MockAnalyzer()
}
