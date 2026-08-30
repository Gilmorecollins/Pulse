# Pulse — Architecture

## Stack

- **Flutter + Dart**, Material 3
- **Riverpod** for state management
- **GoRouter** for navigation
- **Drift** (SQLite) for local persistence — source of truth for v1
- Backend: none in v1. AI was attempted (see docs/API.md, ROADMAP.md
  Phase 9) but reverted after failing on the test device specifically.

## Why local-first

v1 is single-user, so there is no multi-device sync problem to solve yet.
The local Drift database is the source of truth. This keeps the app fully
functional offline by construction, rather than as a feature bolted on
later (see original spec §29 — offline-first was already a stated
requirement, and local-first as the *default* architecture is the simplest
way to satisfy it).

AI is not part of v1 (see docs/API.md, ROADMAP.md Phase 9). Whatever
form it takes if revisited, it should not store tasks, reports, or
reflections — the phone stays the database.

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

## AI (attempted, reverted — see docs/API.md and ROADMAP.md Phase 9)

If revisited, the flow should still follow the original spec's rule
(§18):

```
User input → AI interpretation → structured response → validation →
user confirmation where necessary → database
```

AI should never write to the local database directly.

## Error handling

Every async operation (even local DB calls) surfaces four states in the
UI layer: loading, success, empty, error — with a retry action on error.
No infinite spinners.

## Emulator (local dev tooling)

An Android 16 AVD (`Pulse_Test_A16`, Pixel 10 hardware profile, matching
the primary test phone's OS version) is set up locally for fast
iteration without wireless-ADB flakiness. It came out of the Phase 9 AI
debugging saga (see ROADMAP.md) as a way to test app networking code in
isolation from that specific phone's environment. Notes for reuse:

- Boot headless (`-no-window`) — the windowed mode's Qt renderer doesn't
  work in this non-interactive environment and silently breaks touch
  input, which is a nasty failure mode (screenshots still work, so it
  looks fine until you notice taps do nothing).
- `adb shell input tap`/`swipe` requires real screen-pixel coordinates,
  not the coordinates of a resized screenshot — scale both X *and* Y by
  the same factor (a bug here silently taps the wrong element rather than
  erroring).
