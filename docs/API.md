# Pulse — API

## v1: no external API

v1 is fully local. There is no network layer, no backend, and nothing in
this file yet describes a deployed service — this doc is a placeholder
that gets filled in at Phase 9 (AI).

## Planned: AI proxy (Phase 9+)

A minimal stateless backend, added only when AI features are implemented.
Its only job is to hold the Gemini API key so it never ships inside the
compiled Android app (an embedded key is recoverable from the APK, so it
cannot live client-side).

Planned shape:

```
POST /extract-tasks
  body: { "text": "finish my portfolio and spend two hours on the watch app" }
  returns: { "tasks": [ { "title": "...", "estimatedDuration": 120 }, ... ] }

POST /interpret-activity
  body: { "text": "had a meeting with Eric about the application" }
  returns: { "title": "Meeting with Eric", "category": "work", "status": "completed" }

POST /daily-summary
  body: { "plan": {...}, "activities": [...], "reflection": {...} }
  returns: { "summary": "..." }
```

Rules that apply once this exists:
- The proxy is stateless — no database, no logging of prompt content
  beyond what's needed for debugging errors.
- The app treats every response as a **suggestion**, never a direct write
  — see ARCHITECTURE.md's AI flow (input → AI → structured response →
  validation → user confirmation → database).
- Hosting: a low/no-idle-cost option (e.g. Supabase Edge Function or Cloud
  Run) since usage is a single user, a few calls a day.

## Planned: WhatsApp delivery (deferred well past v1)

Only via the official WhatsApp Business Platform API, once report
generation is stable and actually being used daily via in-app/push
delivery. Architected behind a `NotificationChannel` abstraction (see
original spec §16) so adding it later doesn't touch the report generation
logic at all.
