import { GoogleGenAI } from "@google/genai/node"

import { logInfo, summarizeText } from "../logger.js"
import { toolAiCreateInputSchema } from "../schemas.js"
import type { Analyzer, AnalyzerInput, ToolAiCreateInput } from "../types.js"
import { buildAnalyzerPrompt, extractJsonText } from "./prompt.js"

export class GoogleGenAiAnalyzer implements Analyzer {
  private readonly client: GoogleGenAI

  constructor(
    apiKey: string,
    private readonly model: string
  ) {
    this.client = new GoogleGenAI({ apiKey })
  }

  async analyze(input: AnalyzerInput): Promise<ToolAiCreateInput> {
    logInfo("Google GenAI request started", {
      model: this.model,
      source: input.source,
      contentType: input.contentType,
      imageBytesApprox: Math.floor((input.imageBase64.length * 3) / 4)
    })

    const response = await this.client.models.generateContent({
      model: this.model,
      contents: [
        {
          role: "user",
          parts: [
            { text: buildAnalyzerPrompt(input.source) },
            {
              inlineData: {
                mimeType: input.contentType,
                data: input.imageBase64
              }
            }
          ]
        }
      ],
      config: {
        responseMimeType: "application/json"
      }
    })

    const text = response.text

    if (!text) {
      throw new Error("Google GenAI returned an empty response")
    }

    logInfo("Google GenAI response received", {
      model: this.model,
      textPreview: summarizeText(text)
    })

    const parsed = JSON.parse(extractJsonText(text))
    const result = toolAiCreateInputSchema.parse(parsed)

    logInfo("Google GenAI response parsed", {
      name: result.name,
      category: result.category,
      link: result.link,
      tagsCount: result.summary.tags.length,
      useCasesCount: result.summary.useCases.length
    })

    return result
  }
}
