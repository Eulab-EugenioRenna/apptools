import cors from "cors"
import express, { type NextFunction, type Request, type Response } from "express"
import multer from "multer"
import { randomUUID } from "node:crypto"

import { createAnalyzer } from "./analyzers/index.js"
import { config } from "./config.js"
import { logError, logInfo } from "./logger.js"
import { normalizeToolAiCreateInput } from "./normalize.js"
import { PocketBaseClient } from "./pocketBase.js"
import { toolAiCreateInputSchema } from "./schemas.js"

const app = express()
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: config.maxUploadBytes,
    files: 1
  }
})

const analyzer = createAnalyzer()
const pocketBase = new PocketBaseClient(config.pocketBaseUrl, config.pocketBaseCollection)

logInfo("Server configuration loaded", {
  port: config.port,
  maxUploadBytes: config.maxUploadBytes,
  pocketBaseUrl: config.pocketBaseUrl,
  pocketBaseCollection: config.pocketBaseCollection,
  aiProvider: config.aiProvider,
  sourceDefault: config.sourceDefault
})

app.use(cors())
app.use(express.json({ limit: "5mb" }))

app.use((request, response, next) => {
  const requestId = randomUUID()
  const startedAt = Date.now()

  response.on("finish", () => {
    logInfo("HTTP request completed", {
      requestId,
      method: request.method,
      path: request.path,
      statusCode: response.statusCode,
      durationMs: Date.now() - startedAt,
      ip: request.ip
    })
  })

  logInfo("HTTP request started", {
    requestId,
    method: request.method,
    path: request.path,
    contentType: request.get("content-type") ?? "",
    contentLength: request.get("content-length") ?? "",
    ip: request.ip
  })

  response.locals.requestId = requestId
  next()
})

app.get("/health", (_request, response) => {
  logInfo("Health check requested", {
    requestId: response.locals.requestId,
    aiProvider: config.aiProvider,
    pocketBaseCollection: config.pocketBaseCollection
  })

  response.json({
    ok: true,
    pocketBaseUrl: config.pocketBaseUrl,
    pocketBaseCollection: config.pocketBaseCollection,
    aiProvider: config.aiProvider
  })
})

app.post("/analyze-and-save", upload.single("image"), async (request, response) => {
  try {
    const file = request.file

    if (!file) {
      logError("Analyze request missing image", {
        requestId: response.locals.requestId,
        source: request.body.source ?? null
      })

      response.status(400).json({ success: false, error: "Missing image field" })
      return
    }

    const source = String(request.body.source ?? config.sourceDefault).trim() || config.sourceDefault
    logInfo("Analyze request accepted", {
      requestId: response.locals.requestId,
      source,
      fileName: file.originalname,
      mimeType: file.mimetype,
      bytes: file.size
    })

    const analyzed = await analyzer.analyze({
      contentType: file.mimetype || "image/jpeg",
      imageBase64: file.buffer.toString("base64"),
      source
    })

    logInfo("Analyzer returned payload", {
      requestId: response.locals.requestId,
      name: analyzed.name,
      category: analyzed.category,
      link: analyzed.link,
      source: analyzed.source
    })

    const parsed = toolAiCreateInputSchema.parse(analyzed)
    const normalized = normalizeToolAiCreateInput(parsed, config.sourceDefault)
    logInfo("Payload normalized", {
      requestId: response.locals.requestId,
      name: normalized.name,
      normalizedSource: normalized.source,
      tagCount: normalized.summary.tags.length,
      conceptCount: normalized.summary.concepts.length
    })

    const record = await pocketBase.createToolRecord(normalized)

    logInfo("Analyze request completed successfully", {
      requestId: response.locals.requestId,
      recordId: record.id,
      recordName: record.name,
      recordCategory: record.category
    })

    response.json({
      success: true,
      record
    })
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown error"
    logError("Analyze request failed", {
      requestId: response.locals.requestId,
      error: message
    })
    response.status(500).json({ success: false, error: message })
  }
})

app.use((error: unknown, _request: Request, response: Response, _next: NextFunction) => {
  if (error instanceof multer.MulterError) {
    logError("Upload rejected by multer", {
      requestId: response.locals.requestId,
      code: error.code,
      message: error.message
    })

    response.status(400).json({
      success: false,
      error: error.code === "LIMIT_FILE_SIZE"
        ? `Image exceeds ${Math.round(config.maxUploadBytes / (1024 * 1024))}MB limit`
        : error.message
    })
    return
  }

  const message = error instanceof Error ? error.message : "Unknown error"
  logError("Unhandled server error", {
    requestId: response.locals.requestId,
    error: message
  })
  response.status(500).json({ success: false, error: message })
})

app.listen(config.port, () => {
  logInfo("AppSendTool server listening", {
    url: `http://localhost:${config.port}`
  })
})
