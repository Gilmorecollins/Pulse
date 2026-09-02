# Pulse — Roadmap

Phases are sequential. Do not start a phase before the previous one works
end-to-end on a real device, per the project's Definition of Done (a
feature isn't done because it compiles — it's done when it works, persists,
handles errors, and is navigable).

## Phase 1 — Foundation ✅
- Project scaffold, Material 3 theme, GoRouter shell with 4 nav
  destinations (Today / History / Insights / Settings — Insights, History
  and Settings are stubs for now; a 5th, Week, was added in Phase 10)
- Drift database + v1 tables (see DATABASE.md)
- Repository layer for tasks & daily plans

## Phase 2 — Onboarding ✅
- Welcome screen
- Name, check-in time, report time
- Persist preferences locally (`shared_preferences`)
- GoRouter redirect gates first launch to onboarding until complete

## Phase 3 — Today ✅ (manual entry, ahead of Phase 2)
- Today screen: view plan, progress %
- Add task (manual entry only — no AI yet)
- Mark task complete, delete task
- Empty/loading/error states

Built alongside Phase 1 rather than after Phase 2, so there was a working
screen to run/test against immediately. The "Good morning" greeting is
static until onboarding captures a name.

## Phase 4 — Single Check-in ✅
- Schedule one local notification/day at the configured time
  (`flutter_local_notifications` + `timezone`, exact alarm, Android 12+
  permission requested during onboarding)
- Check-in screen: still working / completed / paused / didn't start
- Update task status from response
- Verified live on-device: exact alarm fires at the scheduled wall-clock
  time, tap opens the check-in screen, and it self-reschedules for the
  next day

## Phase 5 — Daily Reflection ✅
- Mood selector + biggest win + carry-forward note
- Scheduled at the report time captured during onboarding, same pattern
  as Phase 4's check-in (second notification, own channel, own payload)
- Verified live on-device: correct notification content posted, correct
  screen opened on tap, data persisted correctly (`daily_reflections`
  row confirmed via direct DB pull)

## Phase 6 — Daily Report ✅
- Report generated automatically when a reflection is saved (completion
  rate computed from that day's tasks, stored in `daily_reports`)
- Report screen: productivity %, completed/not-completed task lists, the
  user's own reflection (mood/win/carry-forward) — no AI-generated
  summary text yet, since that's Phase 9 and nothing should imply it
  exists before it does
- Report history backs the History tab (list of past days → tap for
  that day's report); same screen renders both "just generated today"
  and any past day, parameterized by plan id
- Verified live on-device: reflection save → auto-navigates to the
  report → correct completion rate, tasks, and reflection confirmed via
  direct DB pull

**^ Everything above this line is v1 / MVP — and as of Phase 6, the full
PLAN → PULSE → REFLECT loop works end-to-end on a real device.**

---

## Phase 7 — Activity Discovery ✅ (trimmed)
- "Did something else come up?" free-text logging, added to the
  check-in screen — creates an already-completed task sourced from
  `pulse_checkin` rather than the morning plan
- Distinguished from planned tasks: shown with a "Logged during
  check-in" marker on Today, listed under a separate "New activities"
  section on the report (rather than mixed into "Completed")
- Productivity % (Today and Report) now explicitly excludes logged
  activities from the denominator — they're real, but they shouldn't
  inflate planned-completion just by being created already-done
- Verified live on-device: logged activity appears correctly marked,
  progress ratio unaffected
- **Trimmed**: no add/ignore confirmation step (doc's original two-step
  "Should I add X?" flow) — v1 adds directly, since there's no AI
  interpretation step yet to confirm *before*. No dedicated activity
  timeline view — the Today list + report's "New activities" section
  cover the same need without a new screen; revisit if that turns out
  to be insufficient with real use.

## Phase 8 — Insights ✅
- Average completion, best day so far, average daily tasks, and
  check-in consistency — computed from `daily_reports`/`tasks`/
  `check_ins`, nothing fabricated
- Honest with sparse data by construction: numbers reflect however many
  days are actually tracked (shown as "Based on N days tracked so
  far"), and check-in consistency shows "No check-ins yet" rather than
  a misleading 0% when there's no track record either way
- Empty state (zero reports) still shows the original stub message
  rather than a wall of zeroes
- Verified live on-device: 1 day tracked, 4 planned tasks/1 completed →
  correctly showed 25% average completion, matching best day, and the
  correct null-state for check-in consistency

## Phase 9 — AI ❌ (attempted, reverted)

Built in full — Gemini called directly from the app (Settings API key
entry via `flutter_secure_storage`, "Split with AI" on Today, AI
clean-up + confirm on check-in activity logging, an AI daily summary on
the report) — and code-verified working via a throwaway integration test
against a fresh Android 16 emulator (`Pulse_Test_A16`), which reached
Gemini's real servers cleanly. But the exact same code reliably failed
on the primary test phone across three independent networking
implementations (`dart:io` sockets, a hand-forced-IPv4 variant, and
`cronet_http`/Android's own Cronet stack), which — combined with the
emulator success — points to a phone-side restriction (most likely
Samsung's Auto Blocker, which restricts sideloaded/unverified apps by
default on newer One UI) rather than a code bug. Given that, the AI code
was pulled back out entirely rather than shipped half-working. Full
debugging trail preserved in git history (see the commits around this
phase) if revisited later.

**Incident, for the record**: an early version of the failure-logging
code interpolated the caught network exception directly, which for
`ClientException` embeds the full request URI — including the API key
as a query parameter. It reached `adb logcat`, and once, chat. Both
exposed keys were revoked immediately. Moot now that the AI code is
gone, but worth remembering if AI is ever re-added: never log a
request's URI/exception object when it can carry a secret in the query
string — log an extracted, known-safe field instead.

Also fixed while this was in and being debugged (kept — genuine
correctness fixes, unrelated to AI): the reflection screen's completion
rate calculation (which feeds `daily_reports` → History → Insights)
wasn't excluding logged activities from the denominator the way
Today/Report already did, so it could slightly overstate stored
completion. Now consistent everywhere.

A reusable Android 16 emulator (`Pulse_Test_A16`) came out of this
investigation and stays available locally for fast iteration without
wireless-ADB flakiness — see the "Emulator" note in ARCHITECTURE.md.

## Phase 10 — Per-task Check-ins ✅

Redesigned from the original "configurable frequency/quiet hours"
placeholder into something more useful, driven by real usage/feedback:
check-ins are per-task, not one fixed daily prompt.

- Onboarding's single daily check-in time is replaced with a short
  explainer step — there's no one time to configure anymore, it's set
  per task.
- Add Task gains an optional target day (today by default, up to +30
  days) and an optional expected-finish time; setting a time schedules a
  one-time check-in 5 minutes before it.
- The check-in screen is task-specific (`/checkin/:taskId`, not a
  generic list) with four responses: mark done, ask for more time (same
  day), carry to tomorrow (now asks what time tomorrow), or explain
  what's going on.
- An explanation is a **live, resolvable task state**
  (`tasks.explanationNote`), not a log entry — a task carrying one
  renders as an expandable card on Today/Week (`TaskTile`) with options
  to transfer it to another day or end it (status → `cancelled`,
  explanation preserved so it shows on that day's report).
- Any task is now editable in place (title/day/time) by tapping it —
  `AddEditTaskSheet`, shared between Today and Week. Moving a task to a
  different day is just editing its day (`updateTaskDetails`/
  `moveTaskToDay`); no separate "move" action.
- New **Week** tab (5th nav destination, today through +6 days) — tasks
  planned for a future day were previously invisible until that day's
  Today screen; Week makes them visible and fully manageable (view, add,
  edit, resolve an explanation) ahead of time.
- Editing/rescheduling a task before its check-in ever fires marks that
  `check_ins` row `skipped` rather than leaving it permanently `pending`
  — Insights' consistency metric excludes `skipped` from both sides of
  the ratio, since a proactive reschedule isn't a missed check-in.
- Scheduling reliability under Doze/battery-optimization (the original
  Phase 10 goal) hasn't had a dedicated real-world stress test yet —
  each individual alarm uses the same `exactAllowWhileIdle` scheduling
  already verified working in Phases 4-5, but a task-level alarm can sit
  scheduled for hours/days rather than firing same-day, which is untested
  territory. Worth a dedicated pass once this is in regular use.
- **Verified live on-device**: `flutter analyze`/`flutter test` clean
  (18 tests), plus a direct DB pull confirming real data — pending,
  responded, *and* skipped check-ins all present (skipped proving an
  edit-before-fire correctly supersedes a pending check-in rather than
  leaving it dangling), and a task ended via "explain → end task" showing
  up exactly as designed: `status: cancelled`,
  `explanation_note: "i got an injured toe"`. Editing, carry-forward with
  a time, the Week tab, and the In Progress/Completed grouping were all
  walked through live on the device as well.

## Phase 11 — WhatsApp Delivery ✅ (tap-to-send; full Business API still deferred)

Built as part of Phase 10's work, in trimmed form: a "Send to WhatsApp"
button on the Report screen opens WhatsApp (via the phone-number-less
`wa.me` deep link) with a pre-filled, formatted summary of that day —
productivity, completed/not-completed tasks (with any explanation
attached), new activities, and the reflection — the user picks who to
send it to and taps send.

Deliberately **not** the original full WhatsApp Business Platform API —
see docs/API.md: that needs a Meta Business account, a dedicated
business phone number, and Meta-approved message templates, real
setup/verification cost for what is here one person messaging
themselves. Revisit the full API only if this is ever used by more than
one person, or automatic (no-tap) delivery becomes a real requirement.

## Phase 12 — Google Drive Backup ✅

Manual backup/restore of the whole local database to the user's own
Google Drive (App Data folder scope), triggered by the testing-device
switch (S25 → secondary phone) exposing that there was previously no way
to carry data across devices. See docs/ARCHITECTURE.md's "Backup"
section for the design (`VACUUM INTO` snapshot, not per-table export;
manual only, no background sync, no auto-restore).

Google Cloud Console setup: OAuth consent screen (External, Testing
status) + an Android OAuth client registered against the debug
keystore's SHA-1 (see build.gradle.kts's signing-config note — release
builds currently sign with the same debug keystore, so this covers both
for now). The "Google hasn't verified this app" interstitial on sign-in
is expected or Testing-status apps and not a misconfiguration — the
project owner's own account gets implicit test access without needing
to be added to the test-users list explicitly.

**Verified live on-device**: sign-in completes through the unverified-app
interstitial; Settings shows the connected account; "Back up now"
succeeds; a task added after a backup, then a restore from that backup,
correctly removed the post-backup task on relaunch while preserving
everything that existed at backup time — confirming the file-replace +
restart flow works end-to-end, not just that the upload/download calls
succeed.

## Phase 13 — Recurring Tasks ✅

Schema v4 (`RecurrenceRules` table, `Tasks.recurrenceRuleId`) — a rule is
a template; occurrences are ordinary Tasks rows materialized lazily on
app open (see docs/ARCHITECTURE.md), so every existing feature
(Today/Week/Report/Insights) handles them for free. Add Task gained a
Repeat picker (None/Daily/Weekdays); v1 scope trim: editing a
materialized occurrence only ever edits that single day, never the
series — the only way to change a series is delete-and-recreate it
("Stop repeating" on the task's overflow menu).

**Verified live on-device**: a daily rule appeared on Today and every
Week day; a single-weekday rule only appeared on its matching day;
"Stop repeating" removed the not-yet-done occurrences; editing a
materialized occurrence showed the "part of a repeating series" banner
instead of the Repeat picker (a layout overflow found here on a
narrower device was fixed by wrapping the banner text in `Expanded`);
Insights correctly still showed its original empty state rather than a
premature/broken trend chart, since no day had a generated report yet.

## Phase 14 — Insights Trend View ✅

A hand-rolled bar chart of daily completion rate (`InsightsRepository
.computeCompletionTrend`, 60-day window) added above the existing stat
cards — see docs/ARCHITECTURE.md. No charting package added; not needed
at this data volume.

**Verified live on-device**: forced a same-day reflection/report cycle
(temporarily setting the report time a couple minutes out), confirmed
the report generated, and confirmed a single trend bar appeared above
the stat cards on Insights matching that day's completion rate.

## Phase 15 — GitHub Releases Distribution + Update Check 🚧 (v1.0.1 pending publish)

First tagged release, `v1.0.0`, published to GitHub Releases
(`github.com/Gilmorecollins/Pulse/releases/tag/v1.0.0`) as a downloadable
release APK — Pulse's actual distribution channel, since it isn't on the
Play Store. See docs/ARCHITECTURE.md's "Distribution and update check"
section. Repo was briefly made private mid-session (to scope who could
download the first release) and switched back to public, since the
update check below needs the unauthenticated releases API to work.

**Bug found in `v1.0.0` itself**: `flutter build apk --release` enables
R8 resource shrinking by default, which silently dropped the custom
check-in notification sound (only referenced as a string from Dart,
invisible to the shrinker's static analysis) from the release APK —
debug builds were unaffected. Onboarding's "Start using Pulse" then
threw an uncaught exception scheduling the reflection notification and
hung forever with no error shown, since that call wasn't guarded.
Fixed with a `res/raw/keep.xml` keep-rule plus defensively wrapping
onboarding's notification setup so a future failure there can never
block getting into the app again. Ships in `v1.0.1` along with an app
icon update (the "Group 4" design, refined from the Navy Mirage-themed
icon work).

Paired with an in-app update check: a dismissible banner on Today when a
newer GitHub release exists than the installed version. "Update"
downloads the release's `.apk` asset in-app (progress shown inline) and
hands it to Android's package installer (`open_filex`) — falls back to
opening the release page in the browser if a release has no `.apk`
asset. Android still requires the user's own tap to confirm the install;
true silent self-update isn't possible for a sideloaded app on Android,
by design of the platform.

Code lands with a new `test/version_compare_test.dart` (the tag/version
comparison logic) — not yet exercised live against a real second release
(needs `v1.0.1` to actually publish to confirm the banner appears on a
`v1.0.0` install, downloads, installs, dismisses correctly, and
reappears for a further release after a prior one was dismissed).

## Deferred — App lock screen (on hold, pending design)

A local PIN/password gate on app open — not a real account system. No
email, no registration, no backend: confirmed with the user this is
purely a "someone else picks up my phone" lock, which keeps it
consistent with Pulse's local-only, single-user architecture (a full
email+password *account* system was considered and explicitly rejected —
see docs/ARCHITECTURE.md's local-first reasoning, which a backend-auth
system would contradict for no real benefit here).

**Update, Phase 12:** the "no accounts, no backend" precedent cited above
has since been superseded — Pulse added Google Drive backup, which does
require a Google sign-in. That doesn't change the reasoning here, though:
Drive sign-in delegates entirely to Google's own OAuth (no Pulse-owned
credentials, no Pulse-owned backend server), which is materially
different from the email+password account system this section was
rejecting. The lock-screen decision stands on its own.

On hold specifically waiting on the user's own visual design/animation
reference (they want a particular look, to be supplied as screenshots —
a TikTok link alone isn't fetchable for its visual content, screenshots
of key animation frames are needed instead). Open functional questions
for when this resumes: PIN vs. full password, recovery behavior (no
email exists to reset via — a "reset the lock without wiping data"
path was floated), and whether it re-locks every time the app leaves
the foreground (more secure) or only once per full app close.
