# The Power BI report

Everything needed to build the supplier scorecard in Power BI Desktop from nothing, by copy and paste,
click by click. Nothing is left to choose: every query, column, relationship, measure, visual, colour,
interaction and filter is written down, with the number to check at each step.

## What it answers

- How are deliveries doing: on time and in full, fill rate and late rate, by month and department?
- Which suppliers make deliveries late, and which belong on the watch list?
- Did a late delivery start with the supplier (a late hand-over to the carrier) or after it?
- What changed this week, in two or three sentences per department?
- And each buyer sees only their own department.

## Pages

4 pages, 39 visuals, 19 measures, 2 calculated columns, 1 security role.

1. **Scorecard** (12 visuals): the headline cards, the late rate by month and by department, and this
   week's summaries.
2. **Suppliers** (9): the watch list, the supplier table and volume against late rate.
3. **Why late** (10): the supplier's hand-over against the customer's delivery.
4. **Supplier detail** (8): one supplier's lines, opened by drill-through from page 2.

## The files

| File | What it holds |
|---|---|
| `01-power-query.md` | the connection and the seven queries: M code, columns, types, which load |
| `02-model.md` | tables and grain, relationships, the date table, sort, formats, hidden columns, display folders, security, each with its reason |
| `03-measures.dax` | the two calculated columns and the 19 measures, grouped by page, each with its format and folder |
| `04-pages.md` | every page and visual in build order: fields, titles, sort, colours, positions, slicers |
| `05-theme.json` | the theme shared by all the portfolio reports, written by `python theme.py` from `report.colours` |
| `06-checks.md` | the number every card, chart and table must show, including the view as one buyer |
| `07-interactions.md` | what each click filters, the drill-through, and every filter |
| `08-build-checklist.md` | the whole build as 38 numbered steps, from `docker compose up -d` to the last screenshot |
| `screenshots/` | one image per finished page |

## Start here

Follow `08-build-checklist.md` from step 1; it points into the other files at each stage.
