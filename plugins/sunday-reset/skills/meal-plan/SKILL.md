---
name: meal-plan
description: Plans the week's dinners and the ingredient list for Sunday Reset, scaled to household size, rotating the user's proteins, following their cooking style (batch cook, cook nights plus leftovers, or nightly), and expanding bundles so nothing gets forgotten. Use during the weekly run or when the user asks to plan meals or dinners for the week.
---

# Meal plan

Inputs: `meals`, `household`, `grocery.items`, `grocery.bundles` from config; open evenings from the calendar.

- Scale every quantity to `household.size`. A double batch for four is roughly 8 portions.
- Styles: `batch_cook` = one session (Sunday by default) producing the planned portions; `cook_nights_leftovers` = about four cook nights with double batches, leftovers the following night; `nightly` = a dinner every night.
- Rotate proteins in order across weeks (store the last one used in `state/meal-rotation.json`), or put the pick under Needs your OK if `protein_mode` is `ask`.
- Fish is cooked fresh, never planned as a leftover.
- Cook nights avoid evenings that already have plans.
- Expand bundles into full ingredient lists. If a bundle item matches a usual item (penne and the pasta rule), merge them instead of listing twice.
- Respect household notes (kids' favorites, a healthy skew: whole grains and fruit alongside the carbs they like).

Output: dinners by day (for the email's "Dinners" section and calendar cook blocks) and an ingredient list `[{item, quantity, aisle, reason}]` for grocery-check.
