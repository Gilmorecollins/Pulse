# Pulse — Product

## What it is

Pulse is a personal AI-assisted daily accountability app. It is not a to-do
list. The product loop is:

**PLAN → PULSE → REFLECT**

Every morning you say what you intend to do. During the day Pulse checks in
on you once and lets you log things you actually did, planned or not. At
night it reflects with you and produces a short report of the day.

The core question Pulse keeps asking is:

> "You said you wanted to do this today. How is it going?"

## Who it's for

v1 is single-user: just the person running the app on their own phone. No
accounts, no multi-tenant backend, no login screen. This can change later,
but nothing in v1 should assume it will.

## Non-goals

Pulse is explicitly **not**:
- A generic to-do app
- A calendar
- A project management tool
- A habit tracker with streaks/gamification

## MVP scope (v1)

Trimmed from the original spec to the smallest loop that's usable daily:

1. Onboarding — name, check-in time, report time
2. Today screen — add tasks, mark complete, see progress
3. One check-in per day (not a multi-interval engine yet)
4. Evening reflection — mood + biggest win
5. Generated daily report (on-device, not sent anywhere yet)

Explicitly deferred past v1 (see ROADMAP.md for order):
- Free-text activity discovery ("I had a meeting with...")
- Multiple check-ins/day with configurable scheduling
- AI natural-language task extraction & daily summaries
- Insights/analytics screen
- WhatsApp report delivery
- Offline sync engine (v1 is local-only, so there's nothing to sync yet)

## Design principles

Modern, minimal, calm, premium. Generous spacing, rounded cards, subtle
shadows, large readable numbers, restrained color (deep navy primary,
electric blue/violet accent). Do not overload the Today screen — it should
answer "what am I supposed to do today" in one glance.

## Product principle to protect

Pulse is an accountability layer between intention and action, not a task
database. Every feature decision should be checked against whether it
strengthens that loop or just adds surface area.
