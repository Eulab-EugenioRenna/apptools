export type ToolAiSummary = {
  apiAvailable: boolean
  category: string
  concepts: string[]
  derivedLink: string
  name: string
  normalizedName: string
  summary: string
  tags: string[]
  useCases: string[]
}

export type ToolAiCreateInput = {
  brand: string
  category: string
  link: string
  name: string
  source: string
  summary: ToolAiSummary
}

export type ToolAiRecord = {
  brand: string
  category: string
  collectionId: string
  collectionName: "tools_ai"
  created: string
  deleted: boolean
  id: string
  link: string
  name: string
  source: string
  summary: ToolAiSummary
  updated: string
}

export type AnalyzerInput = {
  contentType: string
  imageBase64: string
  source: string
}

export interface Analyzer {
  analyze(input: AnalyzerInput): Promise<ToolAiCreateInput>
}
