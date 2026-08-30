# Pulse — API

## v1: no external API

v1 is fully local. There is no network layer, no backend.

## AI: attempted, reverted (see ROADMAP.md Phase 9)

A full implementation (Gemini called directly from the app, no backend
proxy — key stored via `flutter_secure_storage`) was built and code-level
verified working, but pulled back out after it reliably failed on the
primary test phone specifically (almost certainly a Samsung security
restriction on sideloaded apps, not a bug — see ROADMAP.md for the full
debugging trail). Revisit if there's appetite to chase the phone-side
restriction down, or to test AI on a device without it.

## Planned: WhatsApp delivery (deferred well past v1)

Only via the official WhatsApp Business Platform API, once report
generation is stable and actually being used daily via in-app/push
delivery. Architected behind a `NotificationChannel` abstraction (see
original spec §16) so adding it later doesn't touch the report generation
logic at all.
