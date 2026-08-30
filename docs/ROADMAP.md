# Pulse — Roadmap

Phases are sequential. Do not start a phase before the previous one works
end-to-end on a real device, per the project's Definition of Done (a
feature isn't done because it compiles — it's done when it works, persists,
handles errors, and is navigable).

## Phase 1 — Foundation ✅
- Project scaffold, Material 3 theme, GoRouter shell with 4 nav
  destinations (Today / History / Insights / Settings — Insights, History
  and Settings are stubs for now)
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

## Phase 10 — Multiple Check-ins
- Configurable check-in frequency/quiet hours
- Revisit Android scheduling reliability at this point specifically —
  this is harder than Phase 4's single check-in and deserves its own
  testing pass on a real device under battery optimization.

## Phase 11 — WhatsApp Delivery
- Official WhatsApp Business API integration behind the
  `NotificationChannel` abstraction
- Only after report generation (Phase 6) has been used daily for a while
