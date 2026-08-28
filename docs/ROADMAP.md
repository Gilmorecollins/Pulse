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

## Phase 2 — Onboarding (next up)
- Welcome screen
- Name, check-in time, report time
- Persist preferences locally (`shared_preferences`)

## Phase 3 — Today ✅ (manual entry, ahead of Phase 2)
- Today screen: view plan, progress %
- Add task (manual entry only — no AI yet)
- Mark task complete, delete task
- Empty/loading/error states

Built alongside Phase 1 rather than after Phase 2, so there was a working
screen to run/test against immediately. The "Good morning" greeting is
static until onboarding captures a name.

## Phase 4 — Single Check-in
- Schedule one local notification/day at the configured time
- Check-in screen: still working / completed / paused / didn't start
- Update task status from response

## Phase 5 — Daily Reflection
- Mood selector + biggest win
- Carry-forward note

## Phase 6 — Daily Report
- Generate report from the day's plan/tasks/reflection
- Report screen (on-device only, no delivery channel yet)
- Report history (backs the History tab)

**^ Everything above this line is v1 / MVP.**

---

## Phase 7 — Activity Discovery
- Free-text "I had a meeting with..." → suggested task, add/ignore
- Activity timeline view

## Phase 8 — Insights
- Replace the Insights stub with real trends once there's enough report
  history to make them meaningful (completion average, consistency, etc.)

## Phase 9 — AI
- Proxy backend (Gemini, see API.md)
- Natural-language task extraction on the Today screen
- AI-assisted activity interpretation
- AI-generated daily reflection summary

## Phase 10 — Multiple Check-ins
- Configurable check-in frequency/quiet hours
- Revisit Android scheduling reliability at this point specifically —
  this is harder than Phase 4's single check-in and deserves its own
  testing pass on a real device under battery optimization.

## Phase 11 — WhatsApp Delivery
- Official WhatsApp Business API integration behind the
  `NotificationChannel` abstraction
- Only after report generation (Phase 6) has been used daily for a while
