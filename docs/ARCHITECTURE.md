# Pulse — Architecture

## Stack

- **Flutter + Dart**, Material 3
- **Riverpod** for state management
- **GoRouter** for navigation
- **Drift** (SQLite) for local persistence — source of truth for v1
- Backend: none. AI (Phase 9+) calls Gemini directly from the app — see
  docs/API.md for why that's the right call for a single personal
  install, and why that could change if Pulse is ever distributed.

## Why local-first

v1 is single-user, so there is no multi-device sync problem to solve yet.
The local Drift database is the source of truth. This keeps the app fully
functional offline by construction, rather than as a feature bolted on
later (see original spec §29 — offline-first was already a stated
requirement, and local-first as the *default* architecture is the simplest
way to satisfy it).

When AI features are added, the app will call a small proxy backend
(stateless, holds only the API key) — it forwards a prompt and returns a
structured result. It does not store tasks, reports, or reflections. The
phone stays the database.

## Layering

Lightweight clean-architecture split, per feature:

```
lib/
  core/
    theme/
    router/
    database/          (Drift database + generated code)
    utils/
  features/
    onboarding/
      domain/           (models, if feature-specific)
      data/             (repositories)
      presentation/     (screens, widgets, providers)
    today/
      domain/
      data/
      presentation/
    checkin/
    reflection/
    report/
    history/
    insights/
    settings/
  app.dart
  main.dart
```

Rules:
- `presentation/` never talks to Drift directly — it goes through a
  repository in `data/`.
- Shared models (Task, DailyPlan, CheckIn, etc.) live in `core/models/`
  since multiple features read them.
- No feature imports another feature's `presentation/` layer directly;
  cross-feature communication goes through Riverpod providers exposing
  domain data.

This is intentionally not a full DDD/hexagonal setup — that's overkill for
an MVP with one developer. The goal is just: UI code and persistence code
don't get tangled, so either can change independently.

## Navigation

Bottom nav, 4 destinations, matching the original spec:

```
Today | History | Insights | Settings
```

`Insights` ships as a stub in v1 (see ROADMAP) but stays in the nav shell
from the start so the IA doesn't shift later.

## Notifications / check-in scheduling

v1 ships exactly **one** scheduled local notification per day (the
check-in), using `flutter_local_notifications` + `workmanager`. Android
12+ restricts exact alarms, so:
- Request `SCHEDULE_EXACT_ALARM` for the check-in and daily report time.
- Treat a few minutes of drift as acceptable — Pulse is not a stopwatch.

Multiple check-ins/day (original spec §9) is deferred until this single
check-in is proven reliable across Doze/battery-optimization states on a
real device — that's a scheduling reliability problem worth its own spike,
not something to assume works.

## AI (Phase 9+)

Gemini (free tier, `gemini-flash-latest`) called directly from the app —
see docs/API.md. Flow always follows the original spec's rule (§18):

```
User input → AI interpretation → structured response → validation →
user confirmation where necessary → database
```

AI never writes to the local database directly.

## Error handling

Every async operation (even local DB calls) surfaces four states in the
UI layer: loading, success, empty, error — with a retry action on error.
No infinite spinners.
