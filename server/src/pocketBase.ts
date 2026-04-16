import { logInfo } from "./logger.js"
import { toolAiRecordSchema } from "./schemas.js"
import type { ToolAiCreateInput, ToolAiRecord } from "./types.js"

export class PocketBaseClient {
  constructor(
    private readonly baseUrl: string,
    private readonly collection: string
  ) {}

  async createToolRecord(input: ToolAiCreateInput): Promise<ToolAiRecord> {
    logInfo("PocketBase create started", {
      baseUrl: this.baseUrl,
      collection: this.collection,
      name: input.name,
      category: input.category,
      source: input.source,
      link: input.link
    })

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
    const record = toolAiRecordSchema.parse(data)

    logInfo("PocketBase create completed", {
      collection: record.collectionName,
      id: record.id,
      name: record.name,
      created: record.created
    })

    return record
  }
}
