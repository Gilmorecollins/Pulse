# Pulse — Architecture

## Stack

- **Flutter + Dart**, Material 3
- **Riverpod** for state management
- **GoRouter** for navigation
- **Drift** (SQLite) for local persistence — source of truth for v1
- Backend: none in v1. AI was attempted (see docs/API.md, ROADMAP.md
  Phase 9) but reverted after failing on the test device specifically.

## Why local-first

The local Drift database is the source of truth. This keeps the app fully
functional offline by construction, rather than as a feature bolted on
later (see original spec §29 — offline-first was already a stated
requirement, and local-first as the *default* architecture is the simplest
way to satisfy it). Google Drive backup (below) doesn't change this: it's
a backup target, not a second source of truth. There's still no
conflict-resolution engine, and still no assumption that more than one
device is active at a time — the app is used from one phone, backed up,
and (if the phone changes) restored onto the next one.

AI is not part of v1 (see docs/API.md, ROADMAP.md Phase 9). Whatever
form it takes if revisited, it should not store tasks, reports, or
reflections — the phone stays the database.

## Backup

Manual Google Drive backup/restore (`lib/core/backup/`,
`lib/features/backup/`) — not a live sync engine. A backup is a
whole-file SQLite snapshot, not a per-table export: `VACUUM INTO` a temp
file (atomic and consistent even mid-write, unlike a raw `File.copy`),
uploaded to the signed-in user's Drive **App Data folder**
(`drive.appdata` scope — hidden from their normal Drive UI, avoids the
OAuth-verification burden broader scopes trigger). Because it's a raw
file, this stays correct across future schema changes automatically — no
per-table exporter to update when a table is added.

Explicit only: a "Back up now" / "Restore" action the user triggers
themselves, plus a silent (no-prompt) sign-in check on launch. No
continuous background sync, no conflict resolution — not needed for one
person using one device at a time — and never a silent restore, since
that overwrites local data. Restoring replaces `pulse.sqlite` on disk
after validating the downloaded file's SQLite header and saving the
previous file as `pulse.sqlite.bak`; the live database connection is
closed first and the app asks to be restarted afterward rather than
attempting a hot-swap of a connection other screens may still be
streaming from.

## Distribution and update check

No Play Store listing — Pulse is sideloaded from GitHub Releases
(`github.com/Gilmorecollins/Pulse/releases`), tagged `vMAJOR.MINOR.PATCH`
matching `pubspec.yaml`'s `version:`. Release builds sign with the debug
keystore (see `android/app/build.gradle.kts`'s `TODO`) — fine for
personal/sideloaded distribution, but note this if a dedicated release
signing key is ever added later.

**Every release must bump the build number** (the part after `+` in
`version:` — Android's `versionCode`), not just the version name.
v1.0.0 and v1.0.1 both shipped as `+1`, which Android's package
installer (Samsung's especially) treats as "not a valid update" over an
already-installed app with the same `versionCode` — it fails with a bare
"App not installed" and no explanation, even though the content
genuinely differs and the signing key matches. A fresh install (nothing
already on the device) is unaffected; this only bites anyone updating
in place. Bump both numbers together going forward, e.g. `1.0.1+1` →
`1.0.2+2`.

`lib/core/update/` checks GitHub's public releases API
(`/repos/.../releases/latest`, no auth) once per app session and shows a
dismissible banner on Today (`_UpdateBanner`) if a newer tag exists than
the installed version (`package_info_plus`). **This depends on the repo
staying public**: a private repo's releases API requires auth this app
doesn't carry, so the check would silently find nothing (fails closed,
not with an error — see `UpdateCheckService.fetchLatestRelease`'s error
handling).

"Update" downloads the release's `.apk` asset in-app
(`UpdateCheckService.downloadApk`, with progress shown inline on the
banner) and hands it to Android's package installer via the `open_filex`
plugin (`installApk`) — falls back to opening the release page in the
browser if a release has no `.apk` asset attached. Android still
requires the user's own tap to confirm the install (and, the first
time, a tap through "allow installs from this app" — the OS shows this
automatically, not something Pulse's code drives); **no Android app can
silently self-update**, sideloaded or not, so this is the most direct
flow the platform allows, not a fully automatic one.

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
    week/
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

Bottom nav, 5 destinations:

```
Today | Week | History | Insights | Settings
```

Ordered present → near future → past → analysis → config. `Week` shows
today through the next 6 days — tasks planned for a future day are
otherwise invisible until that day's Today screen. `Insights` ships as a
stub in v1 (see ROADMAP) but stays in the nav shell from the start so the
IA doesn't shift later.

## Notifications / check-in scheduling

Check-ins are **per-task**, not one fixed daily prompt: a task with an
expected completion time gets its own one-time
`flutter_local_notifications` alarm 5 minutes before that time
(`NotificationService.scheduleTaskCheckIn`), cancelled/rescheduled
whenever the task is edited, completed, deleted, or moved. Android 12+
restricts exact alarms, so:
- Request `SCHEDULE_EXACT_ALARM` at onboarding.
- Treat a few minutes of drift as acceptable — Pulse is not a stopwatch.

The daily reflection notification stays a single fixed daily time (set
at onboarding), unrelated to task check-ins.

Responding to a check-in is one of: mark done, ask for more time (same
day), carry to tomorrow (asks what time tomorrow), or explain why it
isn't done — an explanation is a live, resolvable state on the task
itself (`tasks.explanationNote`), not a log entry; a task carrying one
renders as an expandable card (`TaskTile`) on Today/Week with options to
transfer it to another day or end it. Every check-in is recorded as a
`check_ins` row at *schedule* time (not tap time), so an ignored
notification still counts as "due" for Insights' consistency metric —
except when superseded by an edit before it ever fired, which marks it
`skipped` instead of leaving it permanently `pending`.

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
  work in this non-interactive environment at all (breaks touch input
  outright, "System UI isn't responding" ANRs).
- `adb shell input tap`/`swipe` requires real screen-pixel coordinates,
  not the coordinates of a resized screenshot — scale both X *and* Y by
  the same factor (a bug here silently taps the wrong element rather than
  erroring).
- Even headless, `adb`-driven tap/swipe injection has proven unreliable
  in this environment across an entire session of attempts (window focus
  and app state both check out fine via `dumpsys`, taps still don't
  register) — cause never fully isolated, not worth more time chasing.
  Don't rely on it for UI walkthroughs; use the emulator only for
  non-touch verification (`dumpsys alarm`, DB pulls, a Dart
  `integration_test` calling app code directly) and do actual UI
  walkthroughs on the real device.
