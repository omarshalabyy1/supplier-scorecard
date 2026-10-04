# 02 · The model

A star schema: one fact table of order lines with three dimensions around it, plus two side tables
that only the security and the summary visual use.

```
dim_supplier (1) ──┐
dim_product  (1) ──┼──< fact_order_line (many)
dim_date     (1) ──┘
buyer, weekly_summary: no relationship (read by row-level security and one table visual)
_Measures: holds every measure
```

## Before anything: Auto date/time off

**File → Options and settings → Options → Current file → Data load:** untick **Auto date/time**.
Why: `dim_date` is the date table; the automatic hidden date tables would only add size and a second,
competing date hierarchy.

## Tables

| Table | Grain (one row per) | Key | Rows | Why it is shaped this way |
|---|---|---|---|---|
| `fact_order_line` | order line: one item of one order | `order_id` + `order_item_id` | 112,650 | one supplier and one product per line, so every score adds up from lines |
| `dim_supplier` | supplier | `supplier_key` | 3,095 | the scorecard's main axis |
| `dim_product` | product | `product_key` | 32,951 | carries category and department; security filters `department` here |
| `dim_date` | day | `date` | 774 | every promised delivery date; the report's time axis |
| `buyer` | buyer | `buyer_email` | 10 | which department each buyer owns; read only by security |
| `weekly_summary` | department and week | `week_start` + `department` | 11 | the text written by `summarize.py` |
| `_Measures` | | | | one home for every measure |

## Relationships

**Model view.** First delete every relationship Power BI created on its own (right-click the line →
Delete). Then **Home → Manage relationships → New**, three times:

| # | From (many side) | To (one side) | Cardinality | Cross-filter direction | Active | Why |
|---|---|---|---|---|---|---|
| 1 | `fact_order_line[supplier_key]` | `dim_supplier[supplier_key]` | Many to one (*:1) | Single | Yes | each line has one supplier |
| 2 | `fact_order_line[product_key]` | `dim_product[product_key]` | Many to one (*:1) | Single | Yes | each line has one product; this is the path the security filter travels |
| 3 | `fact_order_line[due_date]` | `dim_date[date]` | Many to one (*:1) | Single | Yes | a month on the scorecard means "deliveries promised that month", the date both on time and late are judged against |

`buyer` and `weekly_summary` get no relationship: security reads `buyer` inside its own filter, and
`weekly_summary` is filtered by its own security rule. Single direction everywhere: filters flow from
the dimensions to the fact, never back.

## Mark the date table

Select `dim_date` → **Table tools → Mark as date table** → date column `date` → **OK**. Why: Power BI
then treats `dim_date` as the one calendar of the model.

## Sort by column

- `dim_date[month]` → **Column tools → Sort by column → `month_sort`**. Why: otherwise months sort
  alphabetically (Apr before Aug before Dec).

## Column formats and summarization

Select each column in the Data pane, then **Column tools**:

| Column | Format | Summarization | Why |
|---|---|---|---|
| `fact_order_line[purchase_date]`, `[due_date]`, `[delivered_date]` | Custom `d mmm yyyy` | | readable dates in the supplier detail table |
| `dim_date[date]`, `dim_date[week_start]` | Custom `d mmm yyyy` | | the same |
| `weekly_summary[week_start]` | Custom `d mmm yyyy` | | the same |
| `fact_order_line[order_item_id]` | Whole number | Don't summarize | it is a line number, not an amount |
| `dim_date[year]` | Whole number, no thousands separator | Don't summarize | a label, not an amount |

Every measure carries its own format string (`03-measures.dax`), so visuals need no format of their own.

## Calculated columns

Add the two calculated columns at the top of `03-measures.dax` to `fact_order_line` (select the table →
**Table tools → New column**, paste): `Delivery` and `Handover`. Why: they hold the rules in one place,
and every measure filters on them.

## Hidden columns

Right-click → **Hide in report view**. Why: keys and source ids are for joins and tracing, not for
visuals, and hiding them keeps the field list short.

- `fact_order_line`: `supplier_key`, `product_key`, `handover_due`, `handed_over`, `price`, `freight_value`
- `dim_supplier`: `supplier_key`, `seller_id`
- `dim_product`: `product_key`, `product_id`
- `dim_date`: `month_sort`
- the whole `buyer` table (right-click the table → **Hide in report view**)

`order_item_id` stays visible: the supplier detail table needs it, or two lines of one order with the
same dates would merge into one row.

## Display folders

Select each measure → **Properties → Display folder** (Model view):

| Folder | Measures |
|---|---|
| `Scorecard` | Order Lines, Orders, Delivered Lines, On-Time Lines, Late Lines, OTIF %, Fill Rate %, Late Rate %, Avg Days Late |
| `Suppliers` | Share of Late Deliveries %, Watch List Threshold %, On Watch List, Watch List Suppliers, Watch List Share of Delivered %, Watch List Share of Late % |
| `Hand-over` | Handed Over Lines, Late Hand-over Lines, Late Hand-over Rate %, Late After Late Hand-over % |

## Row-level security: each buyer sees only their department

1. **Modeling → Manage roles → New.** Name the role `Buyer`.
2. Select table `dim_product` → **Switch to DAX editor** → paste:

```dax
dim_product[department]
    IN CALCULATETABLE ( VALUES ( buyer[department] ), buyer[buyer_email] = USERPRINCIPALNAME () )
```

3. Select table `weekly_summary` → **Switch to DAX editor** → paste:

```dax
weekly_summary[department]
    IN CALCULATETABLE ( VALUES ( buyer[department] ), buyer[buyer_email] = USERPRINCIPALNAME () )
```

4. **Save.**

Why one dynamic role and not ten fixed ones: a new buyer is one new row in `data/buyers.csv`, not a new
role. Filtering `dim_product` reaches the fact table through relationship 2, so every card, chart and
supplier list shrinks to the buyer's department; the watch-list threshold then becomes that
department's own (twice its late rate). `weekly_summary` has no relationship, so it gets its own rule,
and the "All departments" summary is hidden from buyers.

**Test it:** **Modeling → View as** → tick **Other user**, type `buyer.electronics@example.com`, tick
**Buyer** → **OK**. Expected numbers: `06-checks.md`, "Row-level security". **Stop viewing** when done.
In the Power BI service, put each buyer's real sign-in in `data/buyers.csv` and add them to the role.
