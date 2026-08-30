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

## Phase 10 — Per-task Check-ins ⏳ (implemented, on-device verification in progress)

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
- **Not yet marked done** — implemented, `flutter analyze`/`flutter test`
  clean (17 tests), but needs the on-device walkthrough (edit, carry
  forward with a time, explain → transfer/end, Week tab, report/WhatsApp
  showing an explanation) before this gets a ✅, per the project's
  Definition of Done.

## Phase 11 — WhatsApp Delivery ⏳ (tap-to-send shipped; full Business API still deferred)

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
