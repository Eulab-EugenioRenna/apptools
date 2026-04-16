# AppSendTool

App iPhone per salvare rapidamente ads, screenshot e immagini di SaaS/tool AI trovati online.

Flusso MVP:

1. Condividi una foto verso la Share Extension iOS.
2. L'estensione invia l'immagine al backend `Node.js`.
3. Il backend analizza la foto con un modello vision, costruisce un payload tipizzato e salva il record in PocketBase.
4. L'app mostra l'ultimo record salvato.

## Struttura

- `server/`: backend TypeScript con upload immagine, analisi e salvataggio PocketBase
- `ios/`: app `SwiftUI` e `Share Extension`

## Backend

1. Copia `server/.env.example` in `server/.env`.
2. Configura almeno:
   - `POCKETBASE_URL=https://pocketabase.eulab.cloud`
   - `POCKETBASE_COLLECTION=tools_ai`
   - `AI_PROVIDER=google`, `openrouter` oppure `mock`
3. Installa le dipendenze e avvia:

```bash
cd server
npm install
npm run dev
```

Endpoint principali:

- `GET /health`
- `POST /analyze-and-save` con `multipart/form-data` e campo `image`

## iOS

Apri `ios/AppSendTool.xcodeproj` in Xcode.

Prima di buildare aggiorna questi valori nei Build Settings o nel file `project.pbxproj`:

- `PRODUCT_BUNDLE_IDENTIFIER`
- `APP_GROUP_IDENTIFIER`
- Team di signing

L'app principale salva il backend URL in `UserDefaults` condivisi tramite App Group.
La Share Extension legge la stessa configurazione e invia la foto al backend.
Il default configurato nell'app e' `https://appsend.eulab.cloud`.

## Variabili backend supportate

- `PORT`
- `POCKETBASE_URL`
- `POCKETBASE_COLLECTION`
- `AI_PROVIDER`
- `GOOGLE_GENAI_API_KEY`
- `GOOGLE_GENAI_MODEL`
- `OPENROUTER_API_KEY`
- `OPENROUTER_MODEL`
- `OPENROUTER_BASE_URL`
- `OPENROUTER_APP_URL`
- `OPENROUTER_APP_NAME`
- `SOURCE_DEFAULT`
- `MAX_UPLOAD_MB`

## Output

Il backend salva in PocketBase un record con questa shape di dominio:

```ts
type ToolAiSummary = {
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

type ToolAiCreateInput = {
  brand: string
  category: string
  link: string
  name: string
  source: string
  summary: ToolAiSummary
}

type ToolAiRecord = {
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
```
