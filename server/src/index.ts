import cors from "cors"
import express, { type NextFunction, type Request, type Response } from "express"
import multer from "multer"

import { createAnalyzer } from "./analyzers/index.js"
import { config } from "./config.js"
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

app.use(cors())
app.use(express.json({ limit: "5mb" }))

app.get("/health", (_request, response) => {
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
      response.status(400).json({ success: false, error: "Missing image field" })
      return
    }

    const source = String(request.body.source ?? config.sourceDefault).trim() || config.sourceDefault
    const analyzed = await analyzer.analyze({
      contentType: file.mimetype || "image/jpeg",
      imageBase64: file.buffer.toString("base64"),
      source
    })

    const parsed = toolAiCreateInputSchema.parse(analyzed)
    const normalized = normalizeToolAiCreateInput(parsed, config.sourceDefault)
    const record = await pocketBase.createToolRecord(normalized)

    response.json({
      success: true,
      record
    })
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown error"
    response.status(500).json({ success: false, error: message })
  }
})

app.use((error: unknown, _request: Request, response: Response, _next: NextFunction) => {
  if (error instanceof multer.MulterError) {
    response.status(400).json({
      success: false,
      error: error.code === "LIMIT_FILE_SIZE"
        ? `Image exceeds ${Math.round(config.maxUploadBytes / (1024 * 1024))}MB limit`
        : error.message
    })
    return
  }

  const message = error instanceof Error ? error.message : "Unknown error"
  response.status(500).json({ success: false, error: message })
})

app.listen(config.port, () => {
  console.log(`AppSendTool server listening on http://localhost:${config.port}`)
})
