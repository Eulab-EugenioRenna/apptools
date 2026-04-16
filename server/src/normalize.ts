import type { ToolAiCreateInput, ToolAiSummary } from "./types.js"

function dedupe(items: string[]): string[] {
  return Array.from(new Set(items.map((item) => item.trim()).filter(Boolean)))
}

function normalizeName(name: string): string {
  return name.replace(/\s+/g, " ").trim()
}

function normalizeLink(link: string): string {
  const trimmed = link.trim()
  if (!trimmed) {
    return ""
  }

  if (/^https?:\/\//i.test(trimmed)) {
    return trimmed
  }

  return `https://${trimmed}`
}

function normalizeSummary(summary: ToolAiSummary, category: string, link: string): ToolAiSummary {
  return {
    apiAvailable: Boolean(summary.apiAvailable),
    category,
    concepts: dedupe(summary.concepts),
    derivedLink: link || summary.derivedLink.trim(),
    name: summary.name.trim(),
    normalizedName: normalizeName(summary.normalizedName || summary.name),
    summary: summary.summary.trim(),
    tags: dedupe(summary.tags),
    useCases: dedupe(summary.useCases)
  }
}

export function normalizeToolAiCreateInput(input: ToolAiCreateInput, sourceDefault: string): ToolAiCreateInput {
  const category = input.category.trim()
  const link = normalizeLink(input.link)
  const name = normalizeName(input.name)
  const brand = normalizeName(input.brand || input.name)
  const source = input.source.trim() || sourceDefault

  return {
    brand,
    category,
    link,
    name,
    source,
    summary: normalizeSummary(input.summary, category, link)
  }
}
