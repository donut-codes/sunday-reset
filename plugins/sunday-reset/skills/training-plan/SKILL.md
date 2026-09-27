---
name: training-plan
description: Places the week's workouts for Sunday Reset in open calendar slots at the user's preferred time, splits studio and home sessions, and eases up after a rough night of sleep using Apple Watch data. Use during the weekly run or when the user asks to schedule workouts.
---

# Training plan

Inputs: `workouts` from config, busy blocks from the calendar, `health/latest.json`.

- Try Mon, Wed, Fri first, then Tue, Thu, Sat. Skip a day when the preferred time slot is taken; if it's still short, use a different time that day and say why in the full email.
- Split: `studio` all studio classes, `home` all home sessions, `mix` about half and half.
- If `easy_after_bad_sleep`: when last night was under 6 hours or HRV is well below the user's recent average, the next session becomes an easy one. In the weekly plan, note that sessions may swap to easy based on sleep.
- If the requested count doesn't fit, place what fits and say so ("You asked for 4. 3 fit this week.").

Output: `[{day, start, end, kind: studio|home, reason}]`.
