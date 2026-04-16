import { toolAiRecordSchema } from "./schemas.js"
import type { ToolAiCreateInput, ToolAiRecord } from "./types.js"

export class PocketBaseClient {
  constructor(
    private readonly baseUrl: string,
    private readonly collection: string
  ) {}

  async createToolRecord(input: ToolAiCreateInput): Promise<ToolAiRecord> {
    const response = await fetch(`${this.baseUrl}/api/collections/${this.collection}/records`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        brand: input.brand,
        category: input.category,
        link: input.link,
        name: input.name,
        source: input.source,
        summary: input.summary
      })
    })

    if (!response.ok) {
      const body = await response.text()
      throw new Error(`PocketBase create failed: ${response.status} ${body}`)
    }

    const data = await response.json()
    return toolAiRecordSchema.parse(data)
  }
}
