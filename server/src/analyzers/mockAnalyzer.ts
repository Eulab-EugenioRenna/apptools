import type { Analyzer, AnalyzerInput, ToolAiCreateInput } from "../types.js"

export class MockAnalyzer implements Analyzer {
  async analyze(input: AnalyzerInput): Promise<ToolAiCreateInput> {
    const source = input.source.trim() || "ios-share-extension"

    return {
      brand: "Mock SaaS",
      category: "RAG",
      link: "https://example.com",
      name: "Mock SaaS",
      source,
      summary: {
        apiAvailable: true,
        category: "RAG",
        concepts: ["LLM", "RAG", "Knowledge Base"],
        derivedLink: "https://example.com",
        name: "Mock SaaS",
        normalizedName: "Mock SaaS",
        summary: "Mock analyzer result used because no live AI provider is configured.",
        tags: ["Mock", "RAG", "AI"],
        useCases: ["Manual testing", "Pipeline verification"]
      }
    }
  }
}
