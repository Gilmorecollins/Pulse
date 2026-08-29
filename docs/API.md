# Pulse — API

## v1 (Phases 1-8): no external API

Fully local. No network layer, no backend.

## Phase 9 — AI: direct-from-app Gemini calls

Originally planned as a backend proxy so the Gemini key would never ship
inside the app (see git history of this file for that version). Revisited
at implementation time: Pulse is a single personal install that never
leaves the user's own device, so the "key recoverable from the APK" risk
that justified a proxy doesn't really apply here — nobody else ever gets
the APK to decompile. Hosting a backend for a few calls a day added real
complexity (a deployed service, its own auth, its own uptime) for a risk
that's near-zero in this specific context, so v1 calls the Gemini REST
API directly from the app instead. Revisit this if Pulse is ever
distributed beyond one device.

- Key entry: Settings screen, stored via `flutter_secure_storage`
  (Android Keystore-backed), never in `shared_preferences` or the
  database, never logged.
- Model: `gemini-flash-latest` (free tier).
- Client: `lib/core/ai/gemini_client.dart` calls `generateContent` with
  `responseMimeType: application/json` + an explicit `responseSchema`, so
  responses are structured JSON, not parsed prose.
- Feature-level calls live in `lib/core/ai/gemini_service.dart`:
  - `extractTasks(text)` — splits a free-text plan into multiple tasks
    (Today screen's "Split with AI").
  - `interpretActivity(text)` — cleans up a free-text check-in log before
    the user confirms it (Check-in screen's "Did something else come up?").
  - `summarizeDay(...)` — a short 2-3 sentence recap grounded only in that
    day's actual data, generated after a reflection is saved.
- Every call site follows the same rule (see ARCHITECTURE.md's AI flow):
  input → AI → structured response → user confirmation where the AI is
  adding data → database. `summarizeDay` is the one exception that writes
  without a confirmation step, since it's display-only text, not a task
  or status change.
- Every AI call is wrapped in try/catch and falls back to the pre-AI
  behavior on failure (no key configured, no network, bad response) — AI
  is additive, never a dependency of the core loop.

## Planned: WhatsApp delivery (deferred well past v1)

Only via the official WhatsApp Business Platform API, once report
generation is stable and actually being used daily via in-app/push
delivery. Architected behind a `NotificationChannel` abstraction (see
original spec §16) so adding it later doesn't touch the report generation
logic at all.
