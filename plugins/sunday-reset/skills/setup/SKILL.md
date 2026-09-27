---
name: setup
description: First-run setup for Sunday Reset. Use when the user installs Sunday Reset, says "set up Sunday Reset", "get started", "change my settings", or when ~/Documents/Sunday Reset/config.json does not exist yet. Creates the folder, opens the setup page in the browser (or asks the questions in the terminal), saves the config, triggers every permission prompt while the user is present, runs setup-check, installs the schedule, and finishes with a dry run.
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
Then run `python3 --version`. The weekly email is rendered with Python. On a Mac without Apple's command line tools this fails or opens an install prompt: have the user run `xcode-select --install`, wait for it to finish, and rerun. If they have Xcode but never accepted its license, `sudo xcodebuild -license accept` fixes it (they type their own password).

## Step 2: Setup page (answers happen in the browser)
The questions live in one page, `${CLAUDE_PLUGIN_ROOT}/web/index.html`. It's the same page as the public prototype, so the questions can't drift apart.

1. If `~/Documents/Sunday Reset/config.json` already exists, ask first: keep it (skip to Step 3), change some answers, or start over. For "change" or "start over", continue below; the page saves to `config.new.json` so nothing is overwritten.
2. If the user has a `config.json` downloaded from the public prototype (for example in Downloads), offer to use it: move it to `~/Documents/Sunday Reset/config.json` (or `config.new.json`), then ask only for what's missing, which is always `user.email`.
3. Otherwise start the page in the background (use the Bash tool's background option, because it waits for the user):
   `python3 ${CLAUDE_PLUGIN_ROOT}/scripts/setup_server.py`
   It prints `SETUP_URL <url>` and opens the browser. Tell the user: "Your setup page just opened in your browser. Answer the questions there and click Save and finish. I'll pick up as soon as it's saved." If the browser didn't open, give them the URL.
4. Wait for the output line `SAVED <path>` (check every 30 seconds). `SAVED ... EXISTING` means it went to `config.new.json`: show the user what changed between the two files, ask which to keep, and rename the chosen one to `config.json`. `TIMEOUT` (45 minutes) means nobody finished: ask whether to reopen the page or answer here instead.
5. Read the saved config and show a short summary. Then ask, in the terminal, the few things the page doesn't cover yet, all optional: pet vet or vaccine dates, pet food brand and bag size.

If the user would rather answer in the terminal, or the page can't open (no browser, remote session), ask the same questions here instead, a few at a time, defaults in brackets:
1. **Basics:** name [blank, greeting drops the name], email address for the plan (required), which day and time the plan arrives [Sunday 7:00 AM; allow any day and any time], short, full, or both email versions [both], emojis on sections, grocery aisles, and the week [yes].
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
- **Record the tools scheduled runs may use.** Scheduled runs have nobody to approve anything, so they can only use tools on an explicit list. Save the exact tool names you verified above to `platform.allowed_tools` in config.json: the mail send tool, the mail search/read tool, any non-Apple calendar or to-do connector tools, and `mcp__claude-in-chrome` if Chrome is connected. Nothing else. Tell the user in one line that this is the complete list of what the schedule can touch.

## Step 5: Run `/sunday-reset:setup-check`
Fix anything it reports as failed before moving on.

## Step 6: Schedule, then prove it works unattended
Mac:
1. `bash ${CLAUDE_PLUGIN_ROOT}/scripts/install_schedule.sh <weekday 0-6> <HH:MM> <daily sweep HH:MM>` (0 = Sunday). It installs the weekly run, the daily inbox sweep, and the reply watcher, each limited to the tools in the allow-list.
2. `bash ${CLAUDE_PLUGIN_ROOT}/scripts/install_schedule.sh --test`. This runs one dry run right now through the exact path the schedule uses, with nobody approving anything. Before it starts, tell the user to stay nearby: macOS may ask whether Claude can use Calendar, Reminders, or Documents, and those prompts only appear for a background run. They click Allow. Expect `TEST_PASSED` and the dry-run email in their inbox. On `TEST_FAILED`, read the log lines it prints, fix the cause (usually a missing tool in `platform.allowed_tools` or a declined macOS prompt), and rerun the test.

Windows: create two Task Scheduler tasks named exactly `Sunday Reset weekly` and `Sunday Reset daily`, starting in the Sunday Reset folder, that run `claude -p "/sunday-reset:weekly-run" --permission-mode dontAsk --allowedTools <rules>` and the same with `"/sunday-reset:inbox-sweep"`, where `<rules>` are the same entries `install_schedule.sh` builds (plugin scripts, reading plugin files, `Edit(./**)`, `Skill`, and `platform.allowed_tools`). Then run the weekly task once by hand with `--dry-run` added and confirm the email arrives.

After a plugin update, run setup again and keep the settings: the allow-list names the plugin version's folder, so the schedule has to be reinstalled.

## Step 7: Finish
Confirm the dry-run email from Step 6 arrived. If the user wants to see it again interactively, run `/sunday-reset:weekly-run --dry-run`. Mark setup complete in the progress file, then tell the user, in plain words:
- **What happens:** every {weekly day} at {time} it plans the week, adds new items to their calendar and to-do app, and emails the plan. It also checks the inbox once a day at {daily sweep time} for bills, trials, deliveries, and appointments.
- **Replies:** answer the numbered "Needs your OK" items by replying within 3 hours of the email. If they don't, the picks stand.
- **If the Mac is asleep** at the scheduled time, the run happens when it wakes. If it's switched off, that week's run is missed.
- **To stop:** `/sunday-reset:stop`.
