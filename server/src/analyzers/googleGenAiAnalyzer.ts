import { GoogleGenAI } from "@google/genai/node"

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

    const parsed = JSON.parse(extractJsonText(text))
    return toolAiCreateInputSchema.parse(parsed)
  }
}
