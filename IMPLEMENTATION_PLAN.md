# Wnovel Translation Application Plan

This plan outlines the architecture and implementation steps for the Wnovel translation application, integrating advanced continuity features while keeping heavy project state strictly on the frontend.

## 1. Goal Description

Create a local-first application to assist users in translating serialized fiction (like Chinese web novels) using LLMs.
The app focuses on **continuity**. As it translates, the AI extracts chapter summaries and character glossaries. These are fed into the prompt for subsequent chapters, allowing the LLM to remember plot points and terminology.

- **Frontend (`wnovel/`)**: A Flutter application (initially Web) that manages all project data (`chapters`, `characters`, `relations`) locally. It handles file importing, batch queues, and UI.
- **Backend (`backend/`)**: A PocketBase server acting purely as an Auth provider, credit manager, and a secure stateless LLM proxy.
- **Design (`design/`)**: Contains generated UI/UX designs to guide the frontend development.

## 2. User Review Required

> [!IMPORTANT]
> Please review and approve the following technology choices and architectural decisions before we begin implementation.

- **Frontend-Heavy State**: As requested, all novel data (`chapters`, `characters`, `relations`) will be stored exclusively in the frontend (e.g., in-memory and persisted via a local database like Hive, Isar, or local storage).
- **Stateless Backend Proxy**: The Flutter frontend will send structured data (raw text, glossary array, previous summaries array) to the backend. The backend will take this structured data, generate the final complex prompt, attach the API key, call the LLM, and deduct credits.
- **Compact API Logs**: The `apiLogs` collection in PocketBase will be minimal (e.g., user ID, timestamp, token usage, cost, and status) without saving the heavy raw text payloads, keeping the database size small.
- **Export Format**: We will support exporting project state to a custom `.wnovel` JSON format so users can resume work across devices, as well as exporting to final **TXT** or **EPUB** formats.

## 3. Proposed Architecture & Workflows

### Backend (`backend/`)

A **PocketBase** server with custom JavaScript logic.

- **Database Schema (`pb_migrations/`)**: We'll write JS migration scripts to auto-create collections on startup:
  - `users` (built-in, customized to add `credits`)
  - `settings` (to securely store LLM API keys on the server)
  - `apiLogs` (Compact version: `userId`, `tokensUsed`, `cost`, `provider`, `status`). No raw text stored.
- **Translation Proxy (`pb_hooks/translate.pb.js`)**: A custom endpoint (`POST /api/translate`) that:
  1.  **Receives Structured Data**: Takes JSON payloads (raw text, glossary array, previous summaries array) from the frontend.
  2.  **Prompt Generation**: Assembles the structured data into the final LLM prompt on the server side.
  3.  **LLM Execution**: Securely calls the LLM (e.g., Gemini, OpenRouter), strictly requesting JSON output.
  4.  **Data Persistence**: Calculates exact token costs, creates a compact log entry in `apiLogs`, and deducts credits from the user.
  5.  **Returns Response**: Sends the JSON (`translatedText`, `summary`, `newCharacters`, `newRelations`) directly back to the frontend.

### Frontend (`wnovel/`)

We will expand the existing Flutter project.

- **Lazy Authentication**: The app is accessible without an account. Users can import files, read, and manage local data. A login popup is only triggered when initiating an API-related action (like starting a translation).
- **Local State Management (Riverpod + Local DB)**: `chapters`, `characters`, and `relations` will be managed using Riverpod and persisted locally (e.g., using Hive or standard JSON serialization).
- **Context Assembly**: Before requesting a translation, the frontend fetches the local character glossary and the summaries of the last 2 translated chapters, and sends them as a structured JSON payload to the backend.
- **Data Ingestion (Importing)**: Parse local `.epub` or `.txt` files in-memory and insert chapters into the local frontend state.
- **Batch Processing**: A local queue system that iterates through `pending` chapters sequentially, respecting Requests Per Minute (RPM) limits.
- **Reader & Post-Editing View**: A dual-pane interface (raw source on the left, translated draft on the right). Manual edits are auto-saved to local state on blur.
- **Exporting/Importing**:
  - Export raw text/EPUB for the final output.
  - Export/Import the entire local project state (`.wnovel` JSON) to resume sessions.

## 4. Development Phases

**Phase 1: PocketBase Backend Setup**

- Initialize PocketBase.
- Write `pb_migrations` scripts to generate the compact database schema (`settings`, `apiLogs`).
- Develop the `pb_hooks/translate.pb.js` hook to act as a secure proxy and token tracker.

**Phase 2: Flutter Local State & Data Ingestion**

- Set up Flutter with Riverpod.
- Implement local storage logic for the project state (`chapters`, `characters`, `relations`).
- Implement EPUB parsing and state export/import (`.wnovel` files).

**Phase 3: Translation UI & Batch Queue**

- Build the side-by-side Reader View and the Glossary UI.
- Develop the Batch Translation logic in Riverpod, assembling context and calling `/api/translate`.

**Phase 4: Export Polish**

- Implement TXT and EPUB export functionality.
- Final UI/UX polish.

## 5. Verification Plan

### Automated Tests

- **Backend**: Test the `translate.pb.js` hook with mocked payloads, verifying it correctly calculates costs and updates compact logs without storing payload data.
- **Frontend**: Write unit tests for local state serialization, context assembly, and EPUB parsing/export.

### Manual Verification

- Upload an `.epub` file and verify it populates the local state.
- Trigger a translation and verify the frontend correctly sends the context and glossary.
- Verify the backend proxies the request successfully and logs a compact entry.
- Export the session, clear local data, and import the session to ensure all progress is restored.
