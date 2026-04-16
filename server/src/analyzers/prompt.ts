export function buildAnalyzerPrompt(source: string): string {
  return [
    "Analyze the screenshot or ad image for a SaaS or AI tool.",
    "Return only valid JSON matching this exact TypeScript type:",
    "{",
    '  "brand": string,',
    '  "category": string,',
    '  "link": string,',
    '  "name": string,',
    '  "source": string,',
    '  "summary": {',
    '    "apiAvailable": boolean,',
    '    "category": string,',
    '    "concepts": string[],',
    '    "derivedLink": string,',
    '    "name": string,',
    '    "normalizedName": string,',
    '    "summary": string,',
    '    "tags": string[],',
    '    "useCases": string[]',
    "  }",
    "}",
    "Rules:",
    "- The root object and summary object must contain all listed keys.",
    "- summary.category must equal category.",
    "- summary.derivedLink must equal link when link is known.",
    "- source must be exactly the provided source string.",
    "- Infer the tool name from branding if needed.",
    "- Infer the link only if highly plausible; otherwise return an empty string.",
    "- The image is usually an ad, landing page, or screenshot for a software product.",
    "- Focus on AI and SaaS products; if uncertain, return the best conservative guess.",
    `- Use this exact source value: ${source}`
  ].join("\n")
}

export function extractJsonText(content: string): string {
  const trimmed = content.trim()

  if (!trimmed.startsWith("```") && !trimmed.endsWith("```")) {
    return trimmed
  }

  return trimmed.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/, "").trim()
}
