---
name: grocery-check
description: Checks live prices, sales, and stock for the Sunday Reset grocery list at the user's stores using the Claude in Chrome extension, applies their brand, size, organic, and price rules, and saves a dated list on the store site. Never adds to a cart and never checks out. Use during the weekly run, or when the user says "check grocery prices", "build my grocery list", or runs /sunday-reset:grocery-check by hand.
---

# Grocery check

If the Claude in Chrome extension isn't connected, stop and return the list without prices, plus the line "Run /sunday-reset:grocery-check when Chrome is open for live prices."

## Never
- Add to cart, check out, or click "Repeat this item" or any subscribe option.
- Type passwords. If a page asks the user to sign in, stop that store and report it.
- Accept non-essential cookies; choose the most private option on consent banners.

## Store support (tested Sept 2026)
| Store | Prices | Stock | Saved list |
|---|---|---|---|
| Whole Foods (Amazon) | yes, sales, price per ounce | yes | yes: product page, Add to List, Create a List. Viewing a list needs a fresh sign-in, so keep your own copy in history |
| Target | yes, price per ounce | yes, per store | favorites button, untested |
| Andronico's (and likely Safeway) | yes, sales, price per ounce, no sign-in | no | needs sign-in, untested |
| Trader Joe's | some; the site doesn't show every product | no | on-site list, untested |

Anything else: try search; if no prices, fall back to a list sorted by aisle. Limit: main store plus two others. Each extra store is another full pass.

## Rules, in order
1. Store split: `main_first` checks the main store and only uses the others for items that are out; `cheapest` compares each item across stores; `category` assigns aisles to stores.
2. Brand rule per item: `brand_locked`, `flexible` (swap if out, flag it), `whichever_on_sale` (compare the listed brands, pick the sale), `cheapest`.
3. Size: `best_per_ounce` compares unit prices of the same item; `usual` keeps last week's size; `best_per_ounce_flag` asks when the size changes. Price per ounce never switches flavors.
4. Organic produce: organic unless it costs more than `max_premium_pct` above conventional. At 0, organic only at the same price.
5. Sales on a different flavor or brand than the usual: flag under Needs your OK, don't swap.
6. Low stock: pick it, and name a backup.

## Saving the list
Whole Foods: open each product, use Add to List, and create `Groceries {Mon D}` on the first item (a new dated list each week; never delete old ones). Other stores: use their list feature only if it was marked working in `grocery.store_support`.
Take screenshots instead of reading full page text; it's much faster.

Output `grocery-list.json`: `[{store, aisle, item, price, unit_price, rule, reason, backup}]`, sorted in the order the user walks the store (produce, bakery, meat and seafood, dairy, pantry, snacks, frozen, household).
