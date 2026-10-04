# 04 · Pages and visuals

Canvas: 16:9, 1280 × 720 (**Format page → Canvas settings**). Positions are `x, y, w, h` in pixels from
the top-left corner (**Format → General → Properties → Size and position**). Apply the theme first
(`05-theme.json`), then build the visuals in the order listed; the `#` is used in `07-interactions.md`.

**Conventions for every visual**

- Title on, with the text given in the row (**Format → General → Title**).
- Number formats come from the measures (`03-measures.dax`); no visual sets its own.
- Cards: **Format → Visual → Callout value → Display units: None**, so a card shows 112,650, not 113K.
  Category label off (the title names the value).
- Tooltips: the fields in the visual, plus any listed under "Tooltips".
- Colours are slots of the shared theme. Data colours 1 to 6 are the top row of every colour picker:
  **1 blue, 2 navy, 3 light blue, 4 slate, 5 deep blue, 6 pale blue.** **Danger** is the theme's "bad"
  colour; it is not in the picker, so choose **Custom color** and type `C2410C`.

4 pages, 39 visuals: Scorecard 12, Suppliers 9, Why late 10, Supplier detail 8.

Rename the pages (double-click the tab): **Scorecard**, **Suppliers**, **Why late**, **Supplier detail**.

## The two slicers (pages 1 to 3)

Build them on page 1. Copy them (Ctrl+C) and paste (Ctrl+V) on pages 2 and 3; when Power BI asks,
choose **Sync**. Then **View → Sync slicers**: both slicers **Sync** and **Visible** on Scorecard,
Suppliers and Why late, and neither box on Supplier detail (the drill-through carries the filters
there).

| Slicer | Field | Style | Selection | Header |
|---|---|---|---|---|
| Department | `dim_product[department]` | Dropdown | Multi-select with Ctrl on, Show "Select all" option on | "Department" |
| Promised date | `dim_date[date]` | Between | a date range | "Promised date" |

## Page 1 · Scorecard

The question: how are deliveries doing, and in which department?

| # | Visual | x, y, w, h | Fields | Settings |
|---|---|---|---|---|
| 1 | Text box | 24, 16, 780, 56 | "Supplier scorecard" and, on a new line, "Order lines by the date promised to the customer" | First line Segoe UI Semibold 20, theme colour 2; second line Segoe UI 11, theme colour 4 |
| 2 | Slicer | 820, 12, 216, 64 | `dim_product[department]` | as in the slicer table |
| 3 | Slicer | 1048, 12, 208, 64 | `dim_date[date]` | as in the slicer table |
| 4 | Card | 24, 88, 196, 96 | `[Orders]` | Title "Orders" |
| 5 | Card | 232, 88, 196, 96 | `[Order Lines]` | Title "Order lines" |
| 6 | Card | 440, 88, 196, 96 | `[OTIF %]` | Title "On time, in full" |
| 7 | Card | 648, 88, 196, 96 | `[Fill Rate %]` | Title "Fill rate" |
| 8 | Card | 856, 88, 196, 96 | `[Late Rate %]` | Title "Late rate" |
| 9 | Card | 1064, 88, 192, 96 | `[Watch List Suppliers]` | Title "Suppliers on the watch list" |
| 10 | Line chart | 24, 200, 616, 260 | X-axis: `dim_date[month]`; Y-axis: `[Late Rate %]`; Tooltips: `[Delivered Lines]`, `[Late Lines]` | Title "Late rate by promised month". X-axis type: Categorical. Sort axis: `month`, ascending (it follows `month_sort`). Line colour: theme colour 1. Markers on. Data labels off. Filter on this visual: `dim_date[date]`, Advanced filtering, "is on or after" 1 March 2017 **And** "is on or before" 31 August 2018 (the months with at least 1,000 deliveries, as in the notebook) |
| 11 | Clustered bar chart | 656, 200, 600, 260 | Y-axis: `dim_product[department]`; X-axis: `[Late Rate %]`; Tooltips: `[Delivered Lines]`, `[Late Lines]`, `[OTIF %]` | Title "Late rate by department". Sort by Late Rate %, descending. Bar colour: theme colour 1. Data labels on |
| 12 | Table | 24, 476, 1232, 228 | `weekly_summary[department]`, `weekly_summary[summary]` | Title "This week's summary". Filter on this visual: drag `weekly_summary[week_start]` into it, Filter type **Top N**, Show items **Top 1**, By value: `week_start` set to **Latest**, Apply. Sort by department, ascending. Values → Text wrap on. Column width: department 220 (drag the header edge). Totals off |

## Page 2 · Suppliers

The question: which suppliers make deliveries late?

| # | Visual | x, y, w, h | Fields | Settings |
|---|---|---|---|---|
| 1 | Text box | 24, 16, 780, 56 | "Suppliers" and, on a new line, "Watch list: 30+ delivered lines and a late rate at least twice the rate of all suppliers" | as page 1 #1 |
| 2 | Slicer | 820, 12, 216, 64 | `dim_product[department]` | synced copy of page 1 #2 |
| 3 | Slicer | 1048, 12, 208, 64 | `dim_date[date]` | synced copy of page 1 #3 |
| 4 | Card | 24, 88, 300, 96 | `[Watch List Suppliers]` | Title "Suppliers on the watch list" |
| 5 | Card | 336, 88, 300, 96 | `[Watch List Share of Delivered %]` | Title "Their share of deliveries" |
| 6 | Card | 648, 88, 300, 96 | `[Watch List Share of Late %]` | Title "Their share of late deliveries" |
| 7 | Card | 960, 88, 296, 96 | `[Watch List Threshold %]` | Title "Watch-list late rate" |
| 8 | Table | 24, 200, 776, 504 | `dim_supplier[supplier]`, `dim_supplier[state]`, `[Delivered Lines]`, `[Late Lines]`, `[Late Rate %]`, `[OTIF %]`, `[Late Hand-over Rate %]`, `[Share of Late Deliveries %]`, `[On Watch List]` | Title "Supplier scorecard". Sort by Late Lines, descending. Filter on this visual: `Delivered Lines` is greater than or equal to 1. Cell elements: `Late Lines` → Data bars on, positive bar theme colour 1; `On Watch List` → Icons on → Format style Rules, "If value = 1 then" the flag icon, no icon otherwise. Totals on |
| 9 | Scatter chart | 816, 200, 440, 504 | Values: `dim_supplier[supplier]`; X-axis: `[Delivered Lines]`; Y-axis: `[Late Rate %]`; Tooltips: `[Late Lines]`, `[On Watch List]` | Title "Volume against late rate". X-axis scale type: Log. Markers → Colors → fx → Format style Rules on `On Watch List`: if value = 1 then theme colour 1, if value = 0 then theme colour 6. Analytics pane: Y-axis constant line, Value fx → Field value `Watch List Threshold %`, colour danger, data label on with text "watch list"; X-axis constant line, value 30, colour theme colour 4, dashed |

Right-click a supplier in #8 or #9 → **Drill through → Supplier detail**.

## Page 3 · Why late

The question: did a late delivery start with the supplier or after it?

| # | Visual | x, y, w, h | Fields | Settings |
|---|---|---|---|---|
| 1 | Text box | 24, 16, 780, 56 | "Why late" and, on a new line, "Each line has two promises: the supplier's hand-over deadline and the customer's date" | as page 1 #1 |
| 2 | Slicer | 820, 12, 216, 64 | `dim_product[department]` | synced copy of page 1 #2 |
| 3 | Slicer | 1048, 12, 208, 64 | `dim_date[date]` | synced copy of page 1 #3 |
| 4 | Card | 24, 88, 300, 96 | `[Late Lines]` | Title "Late deliveries" |
| 5 | Card | 336, 88, 300, 96 | `[Late After Late Hand-over %]` | Title "Started with a late hand-over" |
| 6 | Card | 648, 88, 300, 96 | `[Late Hand-over Rate %]` | Title "Hand-overs that were late" |
| 7 | Card | 960, 88, 296, 96 | `[Avg Days Late]` | Title "Average days late" |
| 8 | Clustered bar chart | 24, 200, 616, 240 | Y-axis: `fact_order_line[Handover]`; X-axis: `[Late Rate %]`; Tooltips: `[Delivered Lines]`, `[Late Lines]` | Title "Late rate after an on-time and a late hand-over". Filter on this visual: `Handover`, Basic filtering, tick only "Late hand-over" and "On-time hand-over". Sort by Late Rate %, descending. Bar colour: theme colour 1. Data labels on |
| 9 | Clustered column chart | 656, 200, 600, 240 | X-axis: `dim_product[department]`; Y-axis: `[Late After Late Hand-over %]`; Tooltips: `[Late Lines]` | Title "Late deliveries that started with the supplier, by department". Sort by Late After Late Hand-over %, descending. Column colour: theme colour 1. Data labels on |
| 10 | Line chart | 24, 456, 1232, 248 | X-axis: `dim_date[month]`; Y-axis: `[Late Hand-over Rate %]`, `[Late Rate %]` | Title "Late hand-overs and late deliveries by promised month". X-axis type: Categorical, sorted by `month` ascending. Lines: Late Hand-over Rate % theme colour 1, Late Rate % theme colour 4. Legend: top. Markers on. Data labels off. Filter on this visual: the same `dim_date[date]` filter as page 1 #10 |

## Page 4 · Supplier detail (drill-through)

**Format page → Page information:** Page type **Drill through**; Drill through from:
`dim_supplier[supplier]` (drag it into the Drill through well); **Keep all filters** on; Cross-report
off. Power BI adds a back button: that is #1.

| # | Visual | x, y, w, h | Fields | Settings |
|---|---|---|---|---|
| 1 | Back button | 24, 16, 32, 32 | | added by Power BI; keep its action "Back" |
| 2 | Multi-row card | 72, 16, 500, 72 | `dim_supplier[supplier]`, `dim_supplier[city]`, `dim_supplier[state]` | Title off |
| 3 | Card | 24, 104, 300, 96 | `[Delivered Lines]` | Title "Delivered lines" |
| 4 | Card | 336, 104, 300, 96 | `[Late Rate %]` | Title "Late rate" |
| 5 | Card | 648, 104, 300, 96 | `[OTIF %]` | Title "On time, in full" |
| 6 | Card | 960, 104, 296, 96 | `[Late Hand-over Rate %]` | Title "Hand-overs that were late" |
| 7 | Line chart | 24, 216, 600, 488 | X-axis: `dim_date[month]`; Y-axis: `[Late Rate %]` | Title "This supplier's late rate by month". X-axis type: Categorical, sorted by `month` ascending. Line colour theme colour 1. Markers on. Data labels on |
| 8 | Table | 640, 216, 616, 488 | `fact_order_line[order_id]`, `fact_order_line[order_item_id]`, `dim_product[category]`, `fact_order_line[due_date]`, `fact_order_line[delivered_date]`, `fact_order_line[Delivery]`, `fact_order_line[Handover]` | Title "Order lines". Sort by due_date, descending. Totals off |

Right-click the page tab → **Hide page**. It opens only by drill-through.

## Not used

No bookmarks, no buttons other than the drill-through back button, no tooltip pages, and no page- or
report-level filters. `07-interactions.md` lists the visual-level filters and every interaction.
