# 04 · Pages and visuals

Canvas: 16:9, 1280 × 720 (View → Page view → Actual size). Positions are `x, y, width, height` in
pixels: select the visual → Format → General → Properties → Size and Position. Titles go in Format →
General → Title. Apply the theme first (`05-theme.json`).

Four pages: **Scorecard**, **Suppliers**, **Why late**, and **Supplier detail** (drill-through).

## Shared slicers (pages 1 to 3)

Build them on page 1, then copy-paste them to pages 2 and 3 and choose **Sync** when Power BI asks.

| Slicer | Field | Style | Position |
|---|---|---|---|
| Department | `dim_product[department]` | Dropdown, multi-select with Ctrl, "Select all" on | 840, 16, 200, 56 |
| Promised date | `dim_date[date]` | Between (date range) | 1056, 16, 200, 56 |

View → **Sync slicers**: both slicers synced and visible on Scorecard, Suppliers and Why late; not on
Supplier detail (the drill-through carries the filters).

## Page 1 · Scorecard

The question: how are deliveries doing, and where?

| Visual | Fields | Position | Settings |
|---|---|---|---|
| Text box | "Supplier scorecard" (20 pt, bold) and below it "Order lines by the date promised to the customer" (11 pt) | 24, 16, 700, 56 | |
| Card | `[Orders]` | 24, 88, 196, 96 | Title "Orders" |
| Card | `[Order Lines]` | 232, 88, 196, 96 | Title "Order lines" |
| Card | `[OTIF %]` | 440, 88, 196, 96 | Title "On time, in full" |
| Card | `[Fill Rate %]` | 648, 88, 196, 96 | Title "Fill rate" |
| Card | `[Late Rate %]` | 856, 88, 196, 96 | Title "Late rate" |
| Card | `[Watch List Suppliers]` | 1064, 88, 192, 96 | Title "Suppliers on the watch list" |
| Line chart | X axis `dim_date[month]`, Y axis `[Late Rate %]` | 24, 200, 616, 260 | Title "Late rate by promised month"; X axis type Categorical, sorted by `month` ascending (it uses `month_sort`); markers on; data labels off; Filters on this visual: `Delivered Lines` is greater than or equal to 1000, and `dim_date[date]` is on or before 31/08/2018 (months with enough deliveries to judge; the history thins out after August 2018) |
| Clustered bar chart | Y axis `dim_product[department]`, X axis `[Late Rate %]` | 656, 200, 600, 260 | Title "Late rate by department"; sort by Late Rate % descending; data labels on (0.0%); one colour (the theme accent) |
| Table | `weekly_summary[department]`, `weekly_summary[summary]` | 24, 476, 1232, 228 | Title "This week's summary"; Filters on this visual: `week_start` → Filter type **Top N** → Top 1 by **Latest** of `week_start`; Column headers: department, summary; Values → Text wrap on; column width: department 200 |

Interactions (Format → Edit interactions): the bar chart filters the line chart and the cards (default);
the summary table is not filtered by the bar chart (click the "none" icon on it), so clicking a
department does not hide the other summaries.

## Page 2 · Suppliers

The question: which suppliers make deliveries late?

| Visual | Fields | Position | Settings |
|---|---|---|---|
| Text box | "Suppliers" (20 pt, bold) and "Watch list: 30+ delivered lines and a late rate at least twice the rate of all suppliers" (11 pt) | 24, 16, 780, 56 | |
| Card | `[Watch List Suppliers]` | 24, 88, 300, 96 | Title "Suppliers on the watch list" |
| Card | `[Watch List Share of Delivered %]` | 336, 88, 300, 96 | Title "Their share of deliveries" |
| Card | `[Watch List Share of Late %]` | 648, 88, 300, 96 | Title "Their share of late deliveries" |
| Card | `[Watch List Threshold %]` | 960, 88, 296, 96 | Title "Watch-list late rate" |
| Table | `dim_supplier[supplier]`, `dim_supplier[state]`, `[Delivered Lines]`, `[Late Lines]`, `[Late Rate %]`, `[OTIF %]`, `[Late Hand-over Rate %]`, `[Share of Late Deliveries %]`, `[On Watch List]` | 24, 200, 776, 504 | Title "Supplier scorecard"; sort by Late Lines descending; Filters on this visual: `Delivered Lines` is greater than or equal to 1; Cell elements → `Late Lines` → Data bars on (accent colour); `On Watch List` → Icons on → Rules: if value = 1 then the flag icon, else no icon; Totals on |
| Scatter chart | Values `dim_supplier[supplier]`, X axis `[Delivered Lines]`, Y axis `[Late Rate %]` | 816, 200, 440, 504 | Title "Volume against late rate"; X axis scale type **Log**; Markers → Color → fx → Rules on `[On Watch List]`: = 1 accent `#2563EB`, = 0 grey `#CBD5E1`; Analytics → Y-axis constant line → Value fx `[Watch List Threshold %]`, label "watch list"; Analytics → X-axis constant line → 30 |

Drill-through: right-click a supplier in the table or the scatter → Drill through → Supplier detail.

## Page 3 · Why late

The question: did it start with the supplier or with the carrier?

| Visual | Fields | Position | Settings |
|---|---|---|---|
| Text box | "Why late" (20 pt, bold) and "Each line has two promises: the supplier's hand-over deadline and the customer's date" (11 pt) | 24, 16, 780, 56 | |
| Card | `[Late Lines]` | 24, 88, 300, 96 | Title "Late deliveries" |
| Card | `[Late After Late Hand-over %]` | 336, 88, 300, 96 | Title "Started with a late hand-over" |
| Card | `[Late Hand-over Rate %]` | 648, 88, 300, 96 | Title "Hand-overs that were late" |
| Card | `[Avg Days Late]` | 960, 88, 296, 96 | Title "Average days late" |
| Clustered bar chart | Y axis `fact_order_line[Handover]`, X axis `[Late Rate %]` | 24, 200, 616, 240 | Title "Late rate after an on-time and a late hand-over"; Filters on this visual: `Handover` is not "Not handed over"; data labels on (0.0%) |
| Clustered column chart | X axis `dim_product[department]`, Y axis `[Late After Late Hand-over %]` | 656, 200, 600, 240 | Title "Late deliveries that started with the supplier, by department"; sort descending; data labels on |
| Line chart | X axis `dim_date[month]`, Y axis `[Late Hand-over Rate %]` and `[Late Rate %]` | 24, 456, 1232, 248 | Title "Late hand-overs and late deliveries by promised month"; legend top; markers on; the same two filters on this visual as the page 1 line chart |

## Page 4 · Supplier detail (drill-through)

| Setting | Value |
|---|---|
| Page type | Format page → Page information → Page type **Drill-through**; Drill-through from: `dim_supplier[supplier]`; Keep all filters **On** |
| Back button | Power BI adds it at the top left; keep it at 24, 16, 32, 32 |

| Visual | Fields | Position | Settings |
|---|---|---|---|
| Multi-row card | `dim_supplier[supplier]`, `dim_supplier[city]`, `dim_supplier[state]` | 72, 16, 500, 72 | No title |
| Card | `[Delivered Lines]` | 24, 104, 300, 96 | Title "Delivered lines" |
| Card | `[Late Rate %]` | 336, 104, 300, 96 | Title "Late rate" |
| Card | `[OTIF %]` | 648, 104, 300, 96 | Title "On time, in full" |
| Card | `[Late Hand-over Rate %]` | 960, 104, 296, 96 | Title "Hand-overs that were late" |
| Line chart | X axis `dim_date[month]`, Y axis `[Late Rate %]` | 24, 216, 600, 488 | Title "This supplier's late rate by month" |
| Table | `fact_order_line[order_id]`, `fact_order_line[order_item_id]`, `dim_product[category]`, `fact_order_line[due_date]`, `fact_order_line[delivered_date]`, `fact_order_line[Delivery]`, `fact_order_line[Handover]` | 640, 216, 616, 488 | Title "Order lines"; sort by `due_date` descending; Cell elements → `Delivery` → Font color → Rules: "Late" accent `#2563EB` |

## Finish

- Page names exactly as above; hide page 4 from the page tabs (right-click → Hide page). It opens by drill-through.
- File → Save as `Supplier_Scorecard.pbix` in the repo's `powerbi/` folder.
- Take one screenshot per page (pages 1 to 3, and page 4 drilled to `S0082`) into `powerbi/screenshots/`,
  named `1-scorecard.png`, `2-suppliers.png`, `3-why-late.png`, `4-supplier-detail.png`.
