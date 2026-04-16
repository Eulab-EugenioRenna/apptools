type LogLevel = "INFO" | "ERROR"

function formatValue(value: unknown): string {
  if (value === undefined) {
    return "undefined"
  }

  if (typeof value === "string") {
    return value
  }

  try {
    return JSON.stringify(value)
  } catch {
    return String(value)
  }
}

function writeLog(level: LogLevel, message: string, details?: Record<string, unknown>): void {
  const timestamp = new Date().toISOString()
  const suffix = details && Object.keys(details).length > 0
    ? ` ${Object.entries(details)
      .map(([key, value]) => `${key}=${formatValue(value)}`)
      .join(" ")}`
    : ""

  console.log(`[${timestamp}] [${level}] ${message}${suffix}`)
}

export function logInfo(message: string, details?: Record<string, unknown>): void {
  writeLog("INFO", message, details)
}

export function logError(message: string, details?: Record<string, unknown>): void {
  writeLog("ERROR", message, details)
}

export function summarizeText(text: string, maxLength = 160): string {
  const normalized = text.replace(/\s+/g, " ").trim()

  if (normalized.length <= maxLength) {
    return normalized
  }

  return `${normalized.slice(0, maxLength - 3)}...`
}
