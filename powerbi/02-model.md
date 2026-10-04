# 02 · The model

A star schema: one fact table of order lines, three dimensions around it, and two side tables that only
the security uses.

```
dim_supplier (1) ──┐
dim_product  (1) ──┼──< fact_order_line (many)
dim_date     (1) ──┘
buyer, weekly_summary: not related (read by row-level security only)
```

## Tables

| Table | Grain (one row per) | Key | Notes |
|---|---|---|---|
| `fact_order_line` | order line: one item of one order | `order_id` + `order_item_id` | the dates of both promises; rules are calculated columns from `03-measures.dax` |
| `dim_supplier` | supplier | `supplier_key` | `supplier` is a short code (sellers have no names) |
| `dim_product` | product | `product_key` | `category` and `department`; security filters `department` |
| `dim_date` | day | `date` | every promised delivery date, Oct 2016 to Oct 2018 |
| `buyer` | buyer | `buyer_email` | which department each buyer owns |
| `weekly_summary` | department and week | `week_start` + `department` | the text written by `summarize.py` |
| `_Measures` | | | holds every measure |

## Relationships

Model view → Manage relationships → New, three times:

| From (many) | To (one) | Cardinality | Cross-filter direction | Active |
|---|---|---|---|---|
| `fact_order_line[supplier_key]` | `dim_supplier[supplier_key]` | Many to one | Single | Yes |
| `fact_order_line[product_key]` | `dim_product[product_key]` | Many to one | Single | Yes |
| `fact_order_line[due_date]` | `dim_date[date]` | Many to one | Single | Yes |

Delete any relationship Power BI created on its own that is not in this table. `buyer` and
`weekly_summary` stay unrelated.

## The date table

Select `dim_date` → Table tools → **Mark as date table** → date column `date`. The report's time axis is
the date the delivery was promised (`due_date`), so a month on the scorecard means "deliveries due that
month".

## Sort by column

- `dim_date[month]` → Column tools → Sort by column → `month_sort`.

## Calculated columns

Add the two calculated columns at the top of `03-measures.dax` to `fact_order_line` (Table tools → New
column): `Delivery` and `Handover`. They hold the rules; every measure filters on them.

## Hidden columns (right-click → Hide in report view)

- `fact_order_line`: `supplier_key`, `product_key`, `handover_due`, `handed_over`, `price`, `freight_value`
- `dim_supplier`: `supplier_key`, `seller_id`
- `dim_product`: `product_key`, `product_id`
- `dim_date`: `month_sort`
- the whole `buyer` table (right-click the table → Hide in report view)

## Display folders (on each measure: Properties → Display folder)

| Folder | Measures |
|---|---|
| `Scorecard` | Order Lines, Orders, Delivered Lines, On-Time Lines, Late Lines, OTIF %, Fill Rate %, Late Rate %, Avg Days Late |
| `Suppliers` | Share of Late Deliveries %, Watch List Threshold %, On Watch List, Watch List Suppliers, Watch List Share of Delivered %, Watch List Share of Late % |
| `Hand-over` | Handed Over Lines, Late Hand-over Lines, Late Hand-over Rate %, Late After Late Hand-over % |

## Row-level security: each buyer sees only their department

1. Modeling → **Manage roles** → New → name it `Buyer`.
2. Select table `dim_product` → switch to the DAX editor → paste:

```dax
dim_product[department]
    IN CALCULATETABLE ( VALUES ( buyer[department] ), buyer[buyer_email] = USERPRINCIPALNAME () )
```

3. Select table `weekly_summary` → DAX editor → paste:

```dax
weekly_summary[department]
    IN CALCULATETABLE ( VALUES ( buyer[department] ), buyer[buyer_email] = USERPRINCIPALNAME () )
```

4. Save.

Filtering `dim_product` filters the fact table through its relationship, so every page, card and
supplier list shrinks to the buyer's department. The summary table has no relationship, so it gets its
own filter; the "All departments" summary is hidden from buyers.

**Test it:** Modeling → **View as** → tick **Other user** and type `buyer.electronics@example.com`, tick
**Buyer** → OK. The report must show only Electronics (numbers in `06-checks.md`). Stop viewing when done.
In the Power BI service, add each buyer's real sign-in to the role and to `data/buyers.csv`.
