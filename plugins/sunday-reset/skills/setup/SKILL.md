---
name: setup
description: First-run setup for Sunday Reset. Use when the user installs Sunday Reset, says "set up Sunday Reset", "get started", "change my settings", or when ~/Documents/Sunday Reset/config.json does not exist yet. Creates the folder, runs the setup interview, writes the config, triggers every permission prompt while the user is present, runs setup-check, installs the schedule, and finishes with a dry run.
---

# Sunday Reset setup

Everything that needs the user present happens here, so scheduled runs never stop to ask for permission when nobody is at the computer. Keep a running progress file at `~/Documents/Sunday Reset/state/setup-progress.json` (`{"completed_steps": [...]}`) so that if a step fails, the next `/sunday-reset:setup` resumes from that step instead of starting over.

Plugin files live in `${CLAUDE_PLUGIN_ROOT}`. Scripts are in `${CLAUDE_PLUGIN_ROOT}/scripts`.

## Rules
- Never overwrite an existing `config.json` without asking. If one exists, offer: keep it, edit specific answers, or start over.
- Ask a few questions at a time (use the question tool when available). Every question except the email address is optional; a blank answer means "use the default" and must never break a later step.
- Write only facts the user gave. Do not invent brands, stores, pets, or hobbies.
- Never type passwords, card numbers, or API keys. If a site needs a sign-in, the user does it themselves.

## Step 1: Create the folder (first, because everything else lives in it)
Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/check_folder.sh`. On a Mac this triggers the Documents permission prompt. Tell the user to click Allow. Expect `WRITE_OK`.
If the output shows `OFFLOADED_FILES`, or the user has iCloud Desktop & Documents turned on, ask them to right-click `Documents/Sunday Reset` in Finder and choose **Keep Downloaded**, then rerun the script and confirm `NO_OFFLOADED_FILES`.

## Step 2: Interview
Ask in this order. Defaults in brackets.
1. **Basics:** name [blank, greeting drops the name], email address for the plan (required), which day and time the plan arrives [Sunday 7:00 AM; allow any day and any time], short, full, or both email versions [both].
2. **Your setup:** computer [detect from `uname`], calendar app (Apple Calendar, Google Calendar, Outlook), to-do app (Apple Reminders, Google Tasks, Microsoft To Do, Todoist), where weekly history lives (Documents folder, Google Drive, OneDrive).
3. **Household:** how many people you shop and cook for [1], anything about who's eating (kids' favorites, a healthy skew).
4. **How you shop:** main store, up to two other stores, how to split across stores (main first / cheapest / by category), pickup, delivery, or in store, sizes (best price per ounce / usual size / best per ounce but ask), produce (always organic / conventional / organic unless it costs more than X%, where X is 0 to 100 [50]), price sensitivity (value / balanced / premium) and whether to confirm new brands [yes].
5. **Usuals:** items bought most weeks, each with brand(s) and a rule: only this brand, this brand but swap if out, whichever is on sale, cheapest. Bundles of items always bought together (for example pasta night: penne, arrabbiata, onion, garlic). Offer to read the user's purchase history on the store site in Chrome and suggest rules to confirm.
6. **Meals:** proteins to rotate, rotate or ask each week, how dinner happens (one batch cook / a few cook nights plus leftovers / cook every night), number of dinners to plan.
7. **Pets:** name, type, monthly meds, vet or vaccine dates, food brand and bag size, and what grooming involves and how often (for example bath and brush at home every 4 weeks, or groomer every 6 weeks).
8. **Workouts:** per week, studio vs home, time of day, go easier after a rough night of sleep.
9. **Extras (optional):** local events (city, interests, how far), hobbies with how often (weekly, every other week, monthly).

Save answers to `~/Documents/Sunday Reset/config.json` using the shape in `${CLAUDE_PLUGIN_ROOT}/config.example.json`. Show the user a short summary and let them correct it.

## Step 3: Permissions (one at a time, user clicks Allow)
- Calendar: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/mac/calendar.sh list-calendars`. Ask which calendar to write to and save it as `platform.calendar_name`.
- Reminders: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/mac/reminders.sh list-lists`. Ask which list to use and save it as `platform.reminders_list`.
- Windows or non-Apple apps: use the matching connector tools instead and confirm they respond.

## Step 4: Connections
- **Email:** find a Gmail (or other mail) tool that can send. If none exists, tell the user which connector to add, then continue. Sunday Reset only ever emails `user.email`.
- **Chrome:** check that the Claude in Chrome extension is connected. For each store in the config, open its site and ask the user to sign in themselves if lists need an account. Record what works in `grocery.store_support`.
- **Health data (optional):** ask the user to set up a Health auto-export app that writes a daily JSON to `~/Documents/Sunday Reset/health/latest.json`.

## Step 5: Run `/sunday-reset:setup-check`
Fix anything it reports as failed before moving on.

## Step 6: Schedule
Mac: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/install_schedule.sh <weekday 0-6> <HH:MM> <daily sweep HH:MM>` (0 = Sunday). Windows: create two Task Scheduler tasks that run `claude -p "/sunday-reset:weekly-run"` and `claude -p "/sunday-reset:inbox-sweep"` at the same times.
Remind the user that unattended runs need the email-send tool allowed in Claude Code's permission settings for this folder; otherwise the run falls back to saving a draft.

## Step 7: Dry run
Run `/sunday-reset:weekly-run --dry-run`. It uses sample data, writes the plan to history, and sends the test email. Mark setup complete in the progress file.
