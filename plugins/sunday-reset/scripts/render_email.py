#!/usr/bin/env python3
"""Render the Sunday Reset weekly email from a plan JSON. Email-safe HTML (tables, inline styles).

Usage: render_email.py plan.json out.html

plan.json keys
  full            bool   show the reason under each item
  emoji           bool   add emojis to section titles, aisles, and week items
  greeting, intro str
  test_notes      [str]  optional box at the top listing what is real vs sample (use for tests and dry runs)
  oks             [[text, choice_a, choice_b]]   numbered automatically
  reply_by        str    e.g. "10:00 AM"; replies before this are applied the same day
  days            [[Day, "Oct 4", [[kind, text, why|null, tag|null]]]]   kinds: meal move admin pet ok fun busy
  week_title?, week_note?, dinners? [str]
  list_note       str
  stores          [[store, note, [[aisle, [[item, price|null, why|null, tag|null]]]]]]
  list_after?, events_title?, events_note?, events? [html str], hobbies? [html str]
  saved           str, saved_tag? str
  footer?         str
tag: a short honesty label such as "sample" or "not connected yet"; shown as a small gray pill.
"""
import html, json, sys

C = dict(ink="#1D2A2B", muted="#5B6967", line="#D3DBD2", paper="#EFF2EC", herb="#2D6A56",
         meal=("#2D6A56", "#D6EADF"), move=("#2F5D8A", "#DCE7F3"), admin=("#B4472F", "#F6DDD5"),
         pet=("#B4472F", "#F6DDD5"), ok=("#B97414", "#F7E8CF"), fun=("#7A3F7A", "#EEDDEE"),
         busy=("#9AA5A2", "#E6E9E4"))
F = "font-family:Helvetica,Arial,sans-serif;"
e = html.escape

SECTION_EMOJI = {"Needs your OK": "✋", "The week": "📅", "Dinners": "🍽️", "Grocery list": "🛒",
                 "Live a little": "🎸", "Saved": "💾", "What's real in this test": "🧪"}
AISLE_EMOJI = {"produce": "🥦", "bakery": "🍞", "meat and seafood": "🥩", "meat": "🥩", "seafood": "🐟",
               "dairy and fridge": "🥛", "dairy": "🥛", "pantry": "🥫", "snacks": "🍪", "frozen": "🧊",
               "household": "🧻", "other": "🧺"}
KIND_EMOJI = {"meal": "🍳", "move": "🏃", "admin": "📬", "pet": "🐶", "fun": "🎉", "ok": "✋", "busy": ""}


def tag_html(tag):
    if not tag:
        return ""
    return (f' <span style="display:inline-block;{F}font-size:11px;line-height:1;color:{C["muted"]};'
            f'background:#EEF0EC;border:1px solid {C["line"]};border-radius:10px;padding:3px 7px;'
            f'vertical-align:1px;white-space:nowrap">{e(tag)}</span>')


def section(title, inner, emoji=False, title_emoji=None):
    em = (title_emoji or SECTION_EMOJI.get(title, "")) if emoji else ""
    t = f"{em} {e(title)}" if em else e(title)
    return f'''<tr><td style="padding:22px 0 4px">
      <div style="{F}font-size:17px;font-weight:bold;color:{C["ink"]};padding-bottom:6px;border-bottom:2px solid {C["ink"]}">{t}</div>
      {inner}</td></tr>'''


def note(t):
    return f'<div style="{F}font-size:13px;color:{C["muted"]};margin:8px 0">{t}</div>'


def test_box(items):
    lis = "".join(f'<li style="margin:3px 0">{i}</li>' for i in items)
    return (f'<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:18px 0 0"><tr>'
            f'<td style="border:1px dashed {C["muted"]};border-radius:8px;padding:12px 14px;{F}font-size:13px;color:{C["ink"]};background:#F7F8F5">'
            f'<b>What\'s real in this test</b><ul style="margin:6px 0 0 18px;padding:0">{lis}</ul></td></tr></table>')


def oks(items, reply_by):
    out = ""
    for n, (t, a, b) in enumerate(items, 1):
        out += f'''<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:10px 0"><tr>
          <td valign="top" style="width:34px;background:{C["ok"][0]};border-radius:8px 0 0 8px;{F}font-size:18px;font-weight:bold;color:#FFFFFF;text-align:center;padding-top:11px">{n}</td>
          <td style="background:{C["ok"][1]};padding:12px 14px;{F}font-size:15px;color:{C["ink"]};border-radius:0 8px 8px 0">
          {t}<div style="margin-top:8px;font-size:13px;color:{C["muted"]}">Reply <b style="color:{C["ink"]}">{n} {e(a.lower())}</b> or <b style="color:{C["ink"]}">{n} {e(b.lower())}</b></div></td></tr></table>'''
    when = (f"Replies by <b style=\"color:{C['ink']}\">{e(reply_by)}</b> are applied before you shop today. Later replies are applied tomorrow morning."
            if reply_by else "Replies are applied the next morning.")
    head = note(f"Reply with the number and your choice, like <b style=\"color:{C['ink']}\">1 {e(items[0][2].lower())}</b>. "
                f"Answer several at once: <b style=\"color:{C['ink']}\">1 {e(items[0][1].lower())}, 2 {e(items[min(1, len(items)-1)][2].lower())}</b>. "
                f"{when} No reply means my picks stand.")
    return head + out


def week(days, full, emoji):
    rows = ""
    for d, date, evs in days:
        cells = ""
        for ev in evs:
            kind, text, why = ev[0], ev[1], ev[2] if len(ev) > 2 else None
            tag = ev[3] if len(ev) > 3 else None
            col, bg = C[kind]
            em = KIND_EMOJI.get(kind, "") if emoji else ""
            label = f"{em} {e(text)}" if em else e(text)
            w = f'<div style="font-size:12px;color:{C["muted"]};margin-top:2px">{e(why)}</div>' if (full and why) else ""
            busy = " (already on your calendar)" if kind == "busy" else ""
            cells += (f'<div style="border-left:4px solid {col};background:{bg};padding:6px 9px;margin:0 0 5px;border-radius:0 6px 6px 0;'
                      f'{F}font-size:14px;color:{C["ink"] if kind != "busy" else C["muted"]}">{label}{busy}{tag_html(tag)}{w}</div>')
        if not cells:
            cells = f'<div style="{F}font-size:14px;color:{C["muted"]}">Open day</div>'
        rows += f'''<tr><td valign="top" style="width:58px;padding:9px 8px 9px 0;border-bottom:1px solid {C["line"]};{F}">
          <div style="font-weight:bold;font-size:15px;color:{C["herb"] if d == "Sun" else C["ink"]}">{d}</div><div style="font-size:12px;color:{C["muted"]}">{date}</div></td>
          <td valign="top" style="padding:9px 0;border-bottom:1px solid {C["line"]}">{cells}</td></tr>'''
    return f'<table role="presentation" width="100%" cellpadding="0" cellspacing="0">{rows}</table>'


def glist(stores, full, emoji):
    out = ""
    total = 0
    for sname, snote, aisles in stores:
        if sname:
            out += (f'<div style="{F}font-size:15px;font-weight:bold;color:{C["ink"]};margin:14px 0 2px">{e(sname)} '
                    f'<span style="font-weight:normal;font-size:12px;color:{C["muted"]}">{e(snote)}</span></div>')
        for aisle, items in aisles:
            em = AISLE_EMOJI.get(aisle.lower(), "") if emoji else ""
            a = f"{em} {e(aisle)}" if em else e(aisle)
            out += (f'<div style="{F}font-size:13px;font-weight:bold;color:{C["meal"][0]};margin:12px 0 2px;text-transform:uppercase;letter-spacing:.04em">{a}</div>'
                    f'<table role="presentation" width="100%" cellpadding="0" cellspacing="0">')
            for it in items:
                name, price = it[0], it[1]
                why = it[2] if len(it) > 2 else None
                tag = it[3] if len(it) > 3 else None
                total += price or 0
                w = f'<div style="font-size:12px;color:{C["muted"]}">{e(why)}</div>' if (full and why) else ""
                p = "" if price is None else f"${price:.2f}"
                out += (f'<tr><td style="{F}font-size:14px;color:{C["ink"]};padding:4px 0;border-bottom:1px dotted {C["line"]}">{e(name)}{tag_html(tag)}{w}</td>'
                        f'<td align="right" valign="top" style="{F}font-size:14px;color:{C["ink"]};padding:4px 0;border-bottom:1px dotted {C["line"]};white-space:nowrap">{p}</td></tr>')
            out += "</table>"
    if total:
        out += (f'<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin-top:6px;border-top:2px solid {C["ink"]}"><tr>'
                f'<td style="{F}font-size:15px;font-weight:bold;padding-top:8px">Estimated total</td>'
                f'<td align="right" style="{F}font-size:15px;font-weight:bold;padding-top:8px">${total:.2f}</td></tr></table>')
    return out


def plain_list(items, kind="fun"):
    col = C[kind][0]
    return "".join(f'<div style="{F}font-size:14px;color:{C["ink"]};padding:7px 0 7px 10px;border-left:3px solid {col};margin:6px 0">{i}</div>' for i in items)


def email(p):
    full, emoji = p.get("full", False), p.get("emoji", False)
    footer = e(p.get("footer", "Sent by Sunday Reset. Reply to this email to answer anything under Needs your OK."))
    head = f'''<div style="{F}font-size:12px;letter-spacing:.08em;text-transform:uppercase;color:#CFE3DA">Sunday Reset{" &middot; full version" if full else ""}</div>
      <div style="{F}font-size:26px;font-weight:bold;color:#F3F6F1;margin:6px 0 4px">{e(p["greeting"])}</div>
      <div style="{F}font-size:15px;color:#E3EDE7">{p["intro"]}</div>'''
    body = ""
    if p.get("test_notes"):
        body += f"<tr><td>{test_box(p['test_notes'])}</td></tr>"
    if p.get("oks"):
        body += section("Needs your OK", oks(p["oks"], p.get("reply_by")), emoji)
    body += section(p.get("week_title", "The week"), week(p["days"], full, emoji) + (note(p["week_note"]) if p.get("week_note") else ""), emoji, "📅")
    if p.get("dinners"):
        body += section("Dinners", plain_list(p["dinners"], "meal"), emoji)
    body += section("Grocery list", note(p["list_note"]) + glist(p["stores"], full, emoji) + (note(p["list_after"]) if p.get("list_after") else ""), emoji)
    if p.get("events"):
        body += section(p["events_title"], (note(p["events_note"]) if p.get("events_note") else "") + plain_list(p["events"]), emoji, "🎟️")
    if p.get("hobbies"):
        body += section("Live a little", plain_list(p["hobbies"]), emoji)
    body += section("Saved", note(e(p["saved"]) + tag_html(p.get("saved_tag"))), emoji)
    return f'''<!doctype html><html><body style="margin:0;padding:0;background:{C["paper"]}">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:{C["paper"]}"><tr><td align="center" style="padding:20px 10px">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:620px;background:#FFFFFF;border-radius:10px;overflow:hidden">
<tr><td style="background:#1F4A3E;padding:24px 24px 22px">{head}</td></tr>
<tr><td style="padding:4px 24px 28px"><table role="presentation" width="100%" cellpadding="0" cellspacing="0">{body}</table>
<div style="{F}font-size:12px;color:{C["muted"]};margin-top:24px;padding-top:12px;border-top:1px solid {C["line"]}">{footer}</div>
</td></tr></table></td></tr></table></body></html>'''


def main():
    plan = json.load(open(sys.argv[1]))
    open(sys.argv[2], "w").write(email(plan))
    print(sys.argv[2])


if __name__ == "__main__":
    main()
