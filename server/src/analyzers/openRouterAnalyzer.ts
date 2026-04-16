import { toolAiCreateInputSchema } from "../schemas.js"
import type { Analyzer, AnalyzerInput, ToolAiCreateInput } from "../types.js"
import { buildAnalyzerPrompt, extractJsonText } from "./prompt.js"

type OpenRouterResponse = {
  choices?: Array<{
    message?: {
      content?: string | Array<{ type?: string; text?: string }>
    }
  }>
}

type OpenRouterMessageContent = string | Array<{ type?: string; text?: string }> | undefined

function readContent(content: OpenRouterMessageContent): string {
  if (typeof content === "string") {
    return content
  }

  if (Array.isArray(content)) {
    return content
      .map((part) => part.text ?? "")
      .join("")
      .trim()
  }

  return ""
}

export class OpenRouterAnalyzer implements Analyzer {
  constructor(
    private readonly apiKey: string,
    private readonly model: string,
    private readonly baseUrl: string,
    private readonly appUrl: string,
    private readonly appName: string
  ) {}

  async analyze(input: AnalyzerInput): Promise<ToolAiCreateInput> {
    const headers: Record<string, string> = {
      Authorization: `Bearer ${this.apiKey}`,
      "Content-Type": "application/json"
    }

    if (this.appUrl.trim()) {
      headers["HTTP-Referer"] = this.appUrl.trim()
    }

    if (this.appName.trim()) {
      headers["X-Title"] = this.appName.trim()
    }

    const response = await fetch(`${this.baseUrl}/chat/completions`, {
      method: "POST",
      headers,
      body: JSON.stringify({
        model: this.model,
        response_format: { type: "json_object" },
        messages: [
          {
            role: "system",
            content: "You extract structured tool metadata from screenshots and ads. Output JSON only."
          },
          {
            role: "user",
            content: [
              { type: "text", text: buildAnalyzerPrompt(input.source) },
              {
                type: "image_url",
                image_url: {
                  url: `data:${input.contentType};base64,${input.imageBase64}`
                }
              }
            ]
          }
        ]
      })
    })

    if (!response.ok) {
      const body = await response.text()
      throw new Error(`OpenRouter request failed: ${response.status} ${body}`)
    }

    const data = (await response.json()) as OpenRouterResponse
    const content = readContent(data.choices?.[0]?.message?.content)

    if (!content) {
      throw new Error("OpenRouter returned an empty response")
    }

    const parsed = JSON.parse(extractJsonText(content))
    return toolAiCreateInputSchema.parse(parsed)
  }
}
