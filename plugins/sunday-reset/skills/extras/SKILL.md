---
name: extras
description: The optional fun sections of Sunday Reset. Finds local events (concerts, theater, family events, new movies and TV seasons, markets, museums) near the user for the next month with web search, and schedules hobby time based on how often the user wants each hobby, nudging when one slips. Use during the weekly run or when the user asks what's happening nearby or wants time for hobbies.
---

# Extras

## Local events (if enabled)
- Web search for the configured area and interests, next 30 days. Prefer official venue, city, and event pages.
- Keep 3 to 5, each with a date and a one-line description. Say "confirm the date" when a source only gives a usual timeframe. Never invent an event.
- Skip anything already shown in the last two emails (`state/events-shown.json`).
- If one lands in the coming week and the evening is open, add it under Needs your OK: "Want it on your calendar?"

## Hobbies (if enabled)
- Weekly: an open evening at 7 PM that doesn't clash with plans or evening workouts.
- Every other week: weekend afternoon on its week (track in `state/hobbies.json`).
- Monthly: if it's been longer than the target since the last time, add under Needs your OK with a specific open slot. Mark done when the user replies or the calendar block wasn't deleted.
- Hobby blocks move instead of disappearing when something bumps them.
