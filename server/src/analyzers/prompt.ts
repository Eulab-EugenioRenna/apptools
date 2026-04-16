export function buildAnalyzerPrompt(source: string): string {
  return [
    "Analizza lo screenshot o l'immagine pubblicitaria di un tool SaaS o AI.",
    "Restituisci solo JSON valido che rispetti esattamente questo tipo TypeScript:",
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
    "Regole:",
    "- L'oggetto root e l'oggetto summary devono contenere tutte le chiavi elencate.",
    "- summary.category deve essere uguale a category.",
    "- summary.derivedLink deve essere uguale a link quando il link e' noto.",
    "- source deve essere esattamente il valore source fornito.",
    "- Se necessario, deduci il nome del tool dal branding.",
    "- Deduci il link solo se e' altamente plausibile; altrimenti restituisci una stringa vuota.",
    "- L'immagine di solito e' una pubblicita', landing page o schermata di un prodotto software.",
    "- Concentrati su prodotti AI e SaaS; se non sei sicuro, restituisci la migliore ipotesi conservativa.",
    "- Tutti i valori testuali descrittivi devono essere scritti solo in italiano.",
    "- In particolare summary.summary, summary.tags, summary.useCases, summary.concepts e category devono essere in italiano.",
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
