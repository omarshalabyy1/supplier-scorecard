# 07 · Interactions, drill-through and filters

## Report setting (once)

**File → Options and settings → Options → Current file → Report settings:** tick **Change default
visual interaction from cross highlighting to cross filtering**.

Why: a click on a bar then filters the other visuals to it instead of greying out part of each bar, so
every card shows the selected department's or month's real numbers.

## How to set a cell

Select the source visual (the one you click), then **Format → Edit interactions**. Every other visual
shows icons in its top-right corner: **Filter** (funnel) or **None** (circle with a line). Click the one
the table says. Click **Edit interactions** again to finish. Numbers are the visual `#` in
`04-pages.md`; text boxes take no part.

`weekly_summary` has no relationship, so no click and no slicer changes the summary table; it is set to
None everywhere to make that explicit. Only security filters it.

## Page 1 · Scorecard

| Source (click) | Dept slicer #2 | Date slicer #3 | Cards #4-9 | Month line #10 | Dept bar #11 | Summary #12 |
|---|---|---|---|---|---|---|
| Dept slicer #2 | | Filter | Filter | Filter | Filter | None |
| Date slicer #3 | Filter | | Filter | Filter | Filter | None |
| Month line #10 | None | None | Filter | | Filter | None |
| Dept bar #11 | None | None | Filter | Filter | | None |
| Summary #12 | None | None | None | None | None | |

What a click changes: a department in #11 sets every card and the month line to that department (the
watch-list card then uses that department's own threshold); a month in #10 sets the cards and the bar
to that month. Cards are never a source. The slicers are never filtered by a chart click, so every
department and date stays pickable.

## Page 2 · Suppliers

| Source (click) | Dept slicer #2 | Date slicer #3 | Cards #4-7 | Supplier table #8 | Scatter #9 |
|---|---|---|---|---|---|
| Dept slicer #2 | | Filter | Filter | Filter | Filter |
| Date slicer #3 | Filter | | Filter | Filter | Filter |
| Supplier table #8 | None | None | None | | Filter |
| Scatter #9 | None | None | None | Filter | |

Why None on the cards: they describe the whole watch list, so a click on one supplier leaves them as
they are. A click on a supplier row shows its single dot in the scatter, and a click on a dot shows its
row in the table.

## Page 3 · Why late

| Source (click) | Dept slicer #2 | Date slicer #3 | Cards #4-7 | Hand-over bar #8 | Dept column #9 | Month lines #10 |
|---|---|---|---|---|---|---|
| Dept slicer #2 | | Filter | Filter | Filter | Filter | Filter |
| Date slicer #3 | Filter | | Filter | Filter | Filter | Filter |
| Hand-over bar #8 | None | None | None | | None | None |
| Dept column #9 | None | None | Filter | Filter | | Filter |
| Month lines #10 | None | None | Filter | Filter | Filter | |

Why #8 filters nothing: it compares the two kinds of hand-over side by side; filtering the page to one
of them would turn the other visuals' shares into 0% or 100%.

## Page 4 · Supplier detail

| Source (click) | Cards #2-6 | Month line #7 | Lines table #8 |
|---|---|---|---|
| Month line #7 | Filter | | Filter |
| Lines table #8 | None | None | |

A month in #7 narrows the cards and the table to that month's lines. A row in #8 changes nothing: the
table is a list to read.

## Drill-through

| Setting | Value |
|---|---|
| Target page | Supplier detail (hidden) |
| Drill-through field | `dim_supplier[supplier]` |
| Keep all filters | On (the department and date slicers carry over) |
| Cross-report | Off |
| Start from | right-click a supplier in page 2 #8 or #9 → Drill through → Supplier detail |
| Back | the back button, page 4 #1 |

## Filters

| Level | Where | Filter | Why |
|---|---|---|---|
| Visual | page 1 #10, page 3 #10 | `dim_date[date]` on or after 1 March 2017 and on or before 31 August 2018 | the months with at least 1,000 deliveries; the first and last months are too thin to judge |
| Visual | page 1 #12 | `weekly_summary[week_start]` Top 1 by Latest | show only the newest week's summaries |
| Visual | page 2 #8 | `Delivered Lines` is greater than or equal to 1 | list only suppliers that delivered something |
| Visual | page 3 #8 | `Handover` is Late hand-over or On-time hand-over | lines never handed over have no hand-over to judge |
| Page | page 4 | drill-through on `dim_supplier[supplier]` | set by the drill-through |
| Report | none | | |

## Not used

- Bookmarks and buttons: none, apart from the drill-through back button.
- Tooltip pages: none; the default tooltips carry the extra fields listed in `04-pages.md`.
