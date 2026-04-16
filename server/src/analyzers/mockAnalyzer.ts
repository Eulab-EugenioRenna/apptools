import { logInfo } from "../logger.js"
import type { Analyzer, AnalyzerInput, ToolAiCreateInput } from "../types.js"

export class MockAnalyzer implements Analyzer {
  async analyze(input: AnalyzerInput): Promise<ToolAiCreateInput> {
    const source = input.source.trim() || "ios-share-extension"

    logInfo("Mock analyzer used", {
      source,
      contentType: input.contentType,
      imageBytesApprox: Math.floor((input.imageBase64.length * 3) / 4)
    })

    return {
      brand: "Mock SaaS",
      category: "RAG",
      link: "https://example.com",
      name: "Mock SaaS",
      source,
      summary: {
        apiAvailable: true,
        category: "RAG",
        concepts: ["LLM", "RAG", "base di conoscenza"],
        derivedLink: "https://example.com",
        name: "Mock SaaS",
        normalizedName: "Mock SaaS",
        summary: "Risultato del mock analyzer usato perche' non e' configurato un provider AI reale.",
        tags: ["mock", "RAG", "AI"],
        useCases: ["test manuale", "verifica della pipeline"]
      }
    }
  }
}
