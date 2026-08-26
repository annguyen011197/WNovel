# V-Novel Translator: Project Handoff

## Overview
**V-Novel Translator** is a specialized, local-first application designed to translate serialized fiction (specifically Chinese xianxia/wuxia web novels) into a target language (default: Vietnamese) using LLMs (Google Gemini or OpenRouter).

Unlike standard translation tools, it is built to **maintain continuity**. As it translates a chapter, the AI simultaneously extracts chapter summaries and character glossaries, which are then fed into the prompt for the *next* chapter. This ensures the LLM remembers plot points, character pronouns, and relationships across hundreds of chapters.

## Architecture
The project is structured as a monorepo containing a React frontend and a PocketBase backend.

### 1. Frontend (`/frontend`)
- **Stack:** React 19, Vite, TypeScript, Tailwind CSS.
- **Role:** Handles the UI, file parsing, and batch translation queuing.
- **State Management:** Relies heavily on the PocketBase JS SDK (`pb.ts`) to fetch data and listen to real-time database subscriptions (via custom hooks like `usePBQuery`).

### 2. Backend (`/backend`)
- **Stack:** PocketBase (Go binary with an embedded SQLite database).
- **Role:** Acts as the database and securely proxies API calls to LLM providers.
- **Extensions:** We utilize PocketBase's Javascript engine (`goja`) to write custom backend logic.
  - **`pb_migrations/`:** Contains a JS script that automatically spins up the required database schema (`settings`, `chapters`, `characters`, `relations`, `apiLogs`) when the server boots.
  - **`pb_hooks/translate.pb.js`:** The core engine of the app. It exposes a custom endpoint (`POST /api/translate`) which handles the LLM negotiation securely.

## Core Workflows

### 1. Data Ingestion (Importing)
Users can upload `.epub` or raw `.txt` files in the **Library** sidebar.
- The `EpubParser.tsx` component parses the file, detects chapter breaks, and inserts each chapter into the PocketBase `chapters` collection with a `pending` status.

### 2. The Translation Engine (`pb_hooks/translate.pb.js`)
When a translation is triggered, the frontend calls `/api/translate` with a `chapterId`. The backend hook takes over:
1. **Context Gathering:** It queries PocketBase for the character glossary and the summaries of the *previous 2* completed chapters.
2. **Prompt Assembly:** It builds a complex prompt injecting the raw chapter text, custom translation rules, the character list, and the previous summaries.
3. **LLM Execution:** It securely fetches API keys from the `settings` collection and uses `$http.send()` to call either Google Gemini or OpenRouter. The prompt strictly demands a JSON output containing: `translatedText`, `summary`, `newCharacters`, and `newRelations`.
4. **Data Persistence:** It parses the LLM's JSON response, updates the chapter record, inserts any newly discovered characters/relations into the database, calculates the exact token cost in VND, and logs the raw API payloads for debugging.

### 3. Batch Processing
To translate an entire book hands-free, the user can start a **Batch Translation**.
- Handled in `ReaderView.tsx`, the frontend fetches all `pending` chapters and iterates through them sequentially.
- It respects a configurable **Requests Per Minute (RPM)** limit to prevent hitting API rate limits, sleeping appropriately between `/api/translate` calls.

### 4. Reading & Post-Editing
- The **Reader View** provides a side-by-side interface. The left pane shows the raw source text, and the right pane shows the AI's translated draft.
- The translated text is rendered inside a `<textarea>`. If the user spots a hallucination or error, they can manually edit the text. The `onBlur` event silently saves their manual edits back to PocketBase.

### 5. Exporting
Once translation is complete, the `export.ts` utility allows the user to download the final product.
- **TXT Export:** Concatenates all chapters sequentially.
- **EPUB Export:** Uses `JSZip` to generate a valid, structured EPUB package (complete with `container.xml`, `content.opf`, `toc.ncx`, and individual `.xhtml` chapters) that can be loaded directly onto an e-reader.

## Getting Started for Developers
To run the full stack locally:
```bash
# At the root of the project
npm install
npm run dev
```
This script will concurrently launch the PocketBase server on `http://127.0.0.1:8090` and the Vite frontend on `http://localhost:3000`.

