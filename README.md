# Pulse

Pulse is a personal, single-user accountability app for Android, built
with Flutter. It is not a to-do list. It is an accountability layer
between what you intend to do and what you actually do, built around one
loop:

**Plan → Check in → Reflect → Report**

Every task can carry the moment you expect to finish it. Pulse checks in
shortly before that moment and asks how it is going. At the end of the
day, a reflection turns into a report of what actually happened,
shareable straight to WhatsApp.

## Why

Most to-do apps track *what* you planned. Pulse tracks whether the plan
held up, honestly. It never inflates a completion percentage, never
invents a capability it doesn't have yet, and never claims something is
done when it wasn't. If a task didn't get finished, Pulse wants to know
why, and keeps that reason on the record.

## Status

Actively developed, running daily on one device. See
[`docs/ROADMAP.md`](docs/ROADMAP.md) for the full phase-by-phase history,
including a phase that was implemented, tested, and deliberately reverted
(AI task assistance, rolled back after failing on the primary test
device — full writeup in the roadmap).

## Features

- **Planning** — add tasks for today or any day in the next month; each
  task can carry an expected finish time.
- **Per-task check-ins** — a scheduled local notification five minutes
  before a task's expected finish time, asking how it's going. Respond
  by marking it done, asking for more time, carrying it to tomorrow (with
  a new time), or explaining what's going on.
- **Resolvable explanations** — an explanation is a live state on the
  task, not a log entry. A task carrying one shows as an expandable card
  with options to transfer it to another day or end it, and the
  explanation carries through to that day's report.
- **Task editing** — change a task's title, day, or finish time at any
  point; moving it to a different day is just editing its day.
- **Week view** — today through the next six days at a glance, so tasks
  planned ahead of time are visible and manageable before that day
  arrives, not hidden until it does.
- **Activity discovery** — log something that happened outside the
  morning plan directly from Today, without inflating your planned
  completion rate.
- **Daily reflection and report** — a short end-of-day mood, biggest win,
  and carry-forward note, turned into a report with an honest completion
  percentage, completed and not-completed tasks, and anything logged
  along the way.
- **WhatsApp sharing** — send any day's report to WhatsApp as a
  pre-filled message, one tap.
- **Insights** — average completion, best day, average daily task count,
  and check-in consistency, computed only from real data and never shown
  with false precision when there isn't enough of it yet.

## Screens

Today, Week, History, Insights, and Settings, reached from a persistent
bottom navigation bar. Onboarding runs once, on first launch.

## Tech stack

| Layer         | Choice                                  |
| ------------- | ---------------------------------------- |
| Framework     | Flutter (Dart)                          |
| State         | Riverpod                                |
| Navigation    | go_router                               |
| Persistence   | Drift (SQLite), fully local, no backend |
| Notifications | flutter_local_notifications + timezone  |
| Sharing       | url_launcher (WhatsApp deep link)       |

Pulse is local-first by construction: the on-device database is the
single source of truth, and the app is fully functional offline. There
is no server, no account system, and no sync — see
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the reasoning.

## Project structure

```text
lib/
  core/           theme, router, database, notifications, preferences
  features/
    onboarding/
    today/
    checkin/
    reflection/
    report/
    history/
    week/
    insights/
    settings/
  app.dart
  main.dart
```

Each feature follows a light `data/` (repositories) and `presentation/`
(screens, widgets, providers) split. Presentation code never talks to the
database directly; it goes through a repository. See
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full layering
rules.

## Getting started

Requirements: Flutter SDK (Dart 3.13+), an Android device or emulator.

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

The `build_runner` step generates Drift's database code
(`lib/core/database/database.g.dart`) and needs to be re-run after any
change to the table definitions in `lib/core/database/database.dart`.

To build a debug APK directly:

```bash
flutter build apk --debug
```

## Documentation

- [`docs/PRODUCT.md`](docs/PRODUCT.md) — what Pulse is, who it's for, and
  what it deliberately isn't
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — stack, layering rules,
  notification scheduling, navigation
- [`docs/DATABASE.md`](docs/DATABASE.md) — schema, relationships,
  migration history
- [`docs/API.md`](docs/API.md) — external integrations (WhatsApp sharing;
  notes on the AI attempt and why it was reverted)
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — phase-by-phase build history and
  what's next

## Project scope

Pulse is built for one person, on their own phone. There are no
accounts, no multi-tenant backend, and no login screen. Nothing in the
codebase should assume otherwise unless that changes deliberately.
