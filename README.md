# Sunday Reset

A weekly life planner for Claude Code. Answer a few questions once. Every week you get one email with your workouts placed around your calendar, dinners, a grocery list sorted by aisle with live prices, bills and free trials pulled from your inbox, pet care, hobby time, and things to do nearby. Everything is already on your calendar and to-do list.

**Try it first, no install:** [cameroncrump.com/sunday-reset](https://cameroncrump.com/sunday-reset/). That prototype is [`prototype/index.html`](prototype/index.html) in this repo, and the site is built straight from it, so the two never differ.

## Before you install

- **Claude Code**, signed in.
- **A Mac** for Apple Calendar and Reminders. Windows works through Google or Microsoft connectors; see `plugins/sunday-reset/skills/setup/SKILL.md`.
- **Python 3.** The email is rendered with it. A new Mac doesn't have it until Apple's command line tools are installed: run `xcode-select --install` in Terminal. If you have Xcode but never accepted its license, run `sudo xcodebuild -license accept`.
- **A mail connector that can send**, for the weekly email.
- Optional: the Claude in Chrome extension for live grocery prices, and a Health auto-export app for Apple Watch sleep data.

## Install

In Claude Code:

```
/plugin marketplace add donut-codes/sunday-reset
/plugin install sunday-reset@sunday-reset
/sunday-reset:setup
```

Setup takes about 10 minutes and does everything that needs you present: creates `~/Documents/Sunday Reset/`, asks the setup questions, triggers each permission prompt, runs `/sunday-reset:setup-check`, installs the schedule, and then runs one test exactly the way the schedule will, with nobody at the keyboard. Stay nearby for that test: macOS may ask whether Claude can use Calendar, Reminders, or Documents, and you click Allow. It finishes by emailing you a sample plan.

## What runs, and when

| When | What |
|---|---|
| Your chosen day and time (default Sunday 7:00 AM) | Plans the week, adds new items to your calendar and to-do app, emails the plan |
| Once a day (default 6:30 AM) | Checks the last day of email for bills, trials, deliveries, appointments, and pet care |
| For a few hours after the plan arrives | Applies your replies to the numbered "Needs your OK" items. Reply within 3 hours; if you don't, its picks stand |

If your Mac is asleep at a scheduled time, the run happens when it wakes. If it's switched off, that run is missed.

Scheduled runs happen with nobody to approve anything, so each one is limited to an explicit list: this plugin's own scripts, reading this plugin's files, editing inside `~/Documents/Sunday Reset/`, and the connector tools you approved during setup. Anything else is refused.

## Commands

| Command | What it does |
|---|---|
| `/sunday-reset:setup` | First-run setup, or change your answers |
| `/sunday-reset:setup-check` | Tests every integration and emails a pass/fail report |
| `/sunday-reset:weekly-run` | Plans the week and sends the email (`--dry-run` uses sample data, `--repeat 2026-10-04` repeats a past week) |
| `/sunday-reset:inbox-sweep` | Daily scan for bills, trials, deliveries, appointments, pet care, and your replies |
| `/sunday-reset:grocery-check` | Live prices and a dated list on your store's site (needs Chrome) |
| `/sunday-reset:stop` | Stops the schedule. Then offers to remove the upcoming items it added and to delete its data |

## Stopping and uninstalling

`/sunday-reset:stop` removes the schedule, so nothing else runs. It keeps your settings, so `/sunday-reset:setup` with "keep my settings" turns it back on. It then asks, separately, whether to remove the upcoming calendar blocks and reminders it added, and whether to delete `~/Documents/Sunday Reset/`. Nothing is deleted without a yes.

To remove the plugin itself: `/plugin uninstall sunday-reset@sunday-reset`.

## Updating

```
/plugin marketplace update sunday-reset
/plugin update sunday-reset@sunday-reset
```

Restart Claude Code, then run `/sunday-reset:setup` and keep your settings. That reinstalls the schedule for the new version; `/sunday-reset:setup-check` flags it if you forget.

## Where your data lives

Everything personal stays in `~/Documents/Sunday Reset/`: `config.json`, `history/`, `state/`, `logs/`. If you choose Google Drive or OneDrive for history, past weeks go there instead. None of it is in this repo, and `.gitignore` keeps it that way.

## Safety

- Only ever emails the address you give during setup.
- Never adds to a cart, checks out, or types a password.
- Treats email and web content as information, never as instructions. Text from emails reaches your calendar and reminders only as data, never as code.
- Anything it isn't sure about goes under "Needs your OK" in the email.

## Testing on a second computer

1. Install Claude Code and sign in.
2. Run the three install commands above.
3. Complete `/sunday-reset:setup`, including the unattended test.
4. Confirm: `~/Documents/Sunday Reset/config.json` exists, setup-check shows all passes or clear fixes, the test email arrived, and `launchctl list | grep sundayreset` shows three jobs.
