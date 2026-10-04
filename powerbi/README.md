# The Power BI report

Everything needed to build the supplier scorecard in Power BI Desktop from nothing, by copy and paste.

## What it answers

- How are deliveries doing: on time and in full, fill rate and late rate, by month and department?
- Which suppliers make deliveries late, and which belong on the watch list?
- Did a late delivery start with the supplier (a late hand-over to the carrier) or after it?
- What changed this week, in two or three sentences per department?
- And each buyer sees only their own department.

## Pages

1. **Scorecard**: the headline cards, the late rate by month and by department, and this week's summaries.
2. **Suppliers**: the watch list, the supplier table and volume against late rate.
3. **Why late**: the supplier's hand-over against the customer's delivery.
4. **Supplier detail**: one supplier's lines, opened by drill-through from page 2.

## Build it in this order

| Step | File | You do |
|---|---|---|
| 0 | the main README, "Run it" | start PostgreSQL, run `load.py` and `summarize.py` |
| 1 | `01-power-query.md` | create the connection and the six queries |
| 2 | `02-model.md` | relationships, date table, sort order, hidden columns, security role |
| 3 | `03-measures.dax` | add the two calculated columns, then every measure with its format and folder |
| 4 | `05-theme.json` | View → Themes → Browse for themes → this file |
| 5 | `04-pages.md` | build the four pages, visual by visual |
| 6 | `06-checks.md` | compare every card with the expected numbers, and test the security |
| 7 | `screenshots/` | save `Supplier_Scorecard.pbix` here in `powerbi/`, and one screenshot per page |
