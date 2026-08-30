# Pulse — Database

v1 uses a single local Drift (SQLite) database on-device. No server-side
database in v1 — see ARCHITECTURE.md for why.

## Tables (v1 subset)

Trimmed from the full original spec (`users`, `notification_preferences`,
etc. deferred until they're needed — no `users` table makes sense before
there's more than one user).

### daily_plans
```
id            text (uuid), primary key
date          date, unique                -- one plan per calendar day
createdAt     datetime
```

### tasks
```
id                text (uuid), primary key
dailyPlanId       text, FK -> daily_plans.id
title             text
description       text, nullable
status            text   -- planned | in_progress | completed | cancelled | carried_forward
priority          text   -- low | medium | high | critical, default medium
createdAt         datetime
completedAt       datetime, nullable
plannedFor        date
estimatedDuration integer, nullable   -- minutes
actualDuration    integer, nullable   -- minutes
source            text   -- morning_plan | user_added | pulse_checkin | ai_suggested
```

### check_ins
```
id            text (uuid), primary key
dailyPlanId   text, FK -> daily_plans.id
scheduledFor  datetime
respondedAt   datetime, nullable
status        text   -- pending | responded | skipped
```

### daily_reflections
```
id              text (uuid), primary key
dailyPlanId     text, FK -> daily_plans.id, unique
mood            text   -- excellent | good | okay | difficult | unproductive
biggestWin      text, nullable
carryForward    text, nullable   -- freeform note; carried tasks are tracked via task.status
createdAt       datetime
```

### daily_reports
```
id              text (uuid), primary key
dailyPlanId     text, FK -> daily_plans.id, unique
completionRate  real          -- computed at generation time, stored for history
generatedAt     datetime
```

## Deferred tables (post-v1)

- `activities` — added with free-text activity discovery (Phase: activity
  timeline). Until then, "new activities" are just tasks with
  `source = pulse_checkin`.
- `task_updates` — added if/when task history needs to be audited
  separately from the task row itself. Not needed while there's one user
  and no sync conflicts to resolve.
- `users`, `notification_preferences` — added if Pulse ever supports more
  than one user. In v1, preferences live in local key-value storage
  (`shared_preferences`), not a table.

## Relationships (v1)

```
daily_plans (1) ── (many) tasks
daily_plans (1) ── (many) check_ins
daily_plans (1) ── (1) daily_reflections
daily_plans (1) ── (1) daily_reports
```

## Migrations

Drift's schema versioning handles migrations. Every schema change bumps
`schemaVersion` in the database class and adds an explicit migration step
— never a destructive drop-and-recreate, even in v1, since it's still real
personal data on a real device.
