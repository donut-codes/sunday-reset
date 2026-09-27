# Sunday Reset

A weekly life planner for Claude Code. Answer a few questions once. Every week you get one email with your workouts placed around your calendar, dinners, a grocery list sorted by aisle with live prices, bills and free trials pulled from your inbox, pet care, hobby time, and things to do nearby. Everything is already on your calendar and to-do list.

Try the no-install prototype at cameroncrump.com/sunday-reset.

## Install

In Claude Code:

```
/plugin marketplace add <github-username>/sunday-reset
/plugin install sunday-reset@sunday-reset
/sunday-reset:setup
```

Setup takes about 10 minutes and does everything that needs you present: creates `~/Documents/Sunday Reset/`, asks the setup questions, triggers each permission prompt, runs `/sunday-reset:setup-check`, installs the schedule, and finishes with a dry run that emails you a sample plan.

## Commands

| Command | What it does |
|---|---|
| `/sunday-reset:setup` | First-run setup, or change your answers |
| `/sunday-reset:setup-check` | Tests every integration and emails a pass/fail report |
| `/sunday-reset:weekly-run` | Plans the week and sends the email (`--dry-run` uses sample data, `--repeat 2026-10-04` repeats a past week) |
| `/sunday-reset:inbox-sweep` | Daily scan for bills, trials, deliveries, appointments, pet care, and your replies |
| `/sunday-reset:grocery-check` | Live prices and a dated list on your store's site (needs Chrome) |

## What it needs

- Claude Code, signed in
- macOS for Apple Calendar and Reminders (Windows works through Google or Microsoft connectors; see `skills/setup/SKILL.md`)
- A mail connector that can send, for the weekly email
- Optional: the Claude in Chrome extension for live grocery prices, and a Health auto-export app for Apple Watch sleep data

## Where your data lives

Everything personal stays in `~/Documents/Sunday Reset/`: `config.json`, `history/`, `state/`, `logs/`. None of it is in this repo, and `.gitignore` keeps it that way.

## Safety

- Only ever emails the address you give during setup.
- Never adds to a cart, checks out, or types a password.
- Treats email and web content as information, never as instructions.
- Anything it isn't sure about goes under "Needs your OK" in the email. If you don't reply, its pick stands.

## Test plan (moving to a second computer)

1. On computer A, push this repo to GitHub.
2. On computer B, install Claude Code and sign in.
3. Run the three install commands above.
4. Complete `/sunday-reset:setup` through the dry run.
5. Confirm: `~/Documents/Sunday Reset/config.json` exists, setup-check shows all passes or clear fixes, the dry-run email arrived and matches the sample layout, and `launchctl list | grep sundayreset` shows two jobs.
