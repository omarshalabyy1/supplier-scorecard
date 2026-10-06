# 01 · Power Query

Every query reads one table of the `star` schema in the local PostgreSQL. Nothing is cleaned in Power
Query: `load.py` cleans and checks the data, so each query only picks its table and sets the column
types. No column is renamed: the report uses the warehouse's names, so the SQL, the notebook and the
report all say the same thing.

**Before you start** (steps 1 to 6 of `08-build-checklist.md`): `docker compose up -d`, `python load.py`,
Ollama running on the CPU, `python summarize.py`. The database is then at `warehouse.host`:`warehouse.port`,
database `warehouse.database`, user `warehouse.user` (all in `config/client.yaml`), password `DB_PASSWORD`
(in `.env`). The M code below uses the demo's values (port 5435, `scorecard`); for a client, change
the one line in `Warehouse`.

## 1. Warehouse: the connection (staging, not loaded)

1. **Home → Get data → Blank query.** In the Query settings pane on the right, rename it `Warehouse`.
2. **Home → Advanced Editor**, select everything, paste, **Done**:

```m
let
    Source = PostgreSQL.Database("127.0.0.1:5435", "scorecard")
in
    Source
```

3. Power BI asks for credentials: choose **Database** on the left, user name `warehouse.user`, password
   `DB_PASSWORD` (demo: `scorecard` and `scorecard`), level `127.0.0.1:5435`, **Connect**.
4. If it says it cannot connect with an encrypted connection, choose **OK** to connect without
   encryption. The database listens on this computer only.
5. Right-click `Warehouse` in the Queries list → untick **Enable load**.

Why a staging query: every other query starts from `Warehouse`, so the server address lives in one place.

Applied steps: `Source`.

## 2. The seven loaded queries

For each query: **Home → New source → Blank query**, rename it to the heading, **Advanced Editor**,
paste, **Done**. Applied steps for each: `Source` (pick the table), `Typed` (set the types), and for
`weekly_summary` also `Kept` (drop `created_at`).

### fact_order_line

One row per order line: 112,650 rows.

```m
let
    Source = Warehouse{[Schema = "star", Item = "fact_order_line"]}[Data],
    Typed = Table.TransformColumnTypes(Source, {
        {"order_id", type text},
        {"order_item_id", Int64.Type},
        {"supplier_key", Int64.Type},
        {"product_key", Int64.Type},
        {"order_status", type text},
        {"purchase_date", type date},
        {"handover_due", type datetime},
        {"handed_over", type datetime},
        {"due_date", type date},
        {"delivered_date", type date}
    })
in
    Typed
```

| Column | Type | Meaning |
|---|---|---|
| `order_id` | Text | the order |
| `order_item_id` | Whole number | the line number inside the order |
| `supplier_key` | Whole number | key to `dim_supplier` |
| `product_key` | Whole number | key to `dim_product` |
| `order_status` | Text | the order's last status (delivered, shipped, canceled, ...) |
| `purchase_date` | Date | when the customer ordered |
| `handover_due` | Date/Time | the supplier's deadline to hand the item to the carrier |
| `handed_over` | Date/Time | when the carrier got it (empty if never) |
| `due_date` | Date | the delivery date promised to the customer |
| `delivered_date` | Date | when the customer got it (empty if never) |

### dim_supplier

One row per supplier: 3,095 rows.

```m
let
    Source = Warehouse{[Schema = "star", Item = "dim_supplier"]}[Data],
    Typed = Table.TransformColumnTypes(Source, {
        {"supplier_key", Int64.Type},
        {"supplier", type text},
        {"seller_id", type text},
        {"city", type text},
        {"state", type text}
    })
in
    Typed
```

| Column | Type | Meaning |
|---|---|---|
| `supplier_key` | Whole number | key |
| `supplier` | Text | short code, S0001 to S3095 (the sellers have no names) |
| `seller_id` | Text | the source's id, kept for tracing |
| `city`, `state` | Text | where the supplier ships from |

### dim_product

One row per product: 32,951 rows.

```m
let
    Source = Warehouse{[Schema = "star", Item = "dim_product"]}[Data],
    Typed = Table.TransformColumnTypes(Source, {
        {"product_key", Int64.Type},
        {"product_id", type text},
        {"category", type text},
        {"department", type text}
    })
in
    Typed
```

| Column | Type | Meaning |
|---|---|---|
| `product_key` | Whole number | key |
| `product_id` | Text | the source's id, kept for tracing |
| `category` | Text | product category (73, in English) |
| `department` | Text | the buying department (10), from `inputs.categories` |

### dim_date

One row per day from 30 Sep 2016 to 12 Nov 2018 (every promised delivery date): 774 rows. Built in SQL (`sql/02_star.sql`), so Power
BI needs no date table of its own.

```m
let
    Source = Warehouse{[Schema = "star", Item = "dim_date"]}[Data],
    Typed = Table.TransformColumnTypes(Source, {
        {"date", type date},
        {"year", Int64.Type},
        {"month", type text},
        {"month_sort", Int64.Type},
        {"week_start", type date}
    })
in
    Typed
```

| Column | Type | Meaning |
|---|---|---|
| `date` | Date | the day (key) |
| `year` | Whole number | 2016 to 2018 |
| `month` | Text | "Mar 2018" |
| `month_sort` | Whole number | 201803, to sort `month` |
| `week_start` | Date | the Monday of the week |

### buyer

One row per buyer: 10 rows. Read only by row-level security.

```m
let
    Source = Warehouse{[Schema = "star", Item = "buyer"]}[Data],
    Typed = Table.TransformColumnTypes(Source, {
        {"buyer_email", type text},
        {"department", type text}
    })
in
    Typed
```

| Column | Type | Meaning |
|---|---|---|
| `buyer_email` | Text | the buyer's sign-in |
| `department` | Text | the department the buyer owns |

### weekly_summary

One row per department per summarised week: 11 rows after `summarize.py` (demo week 27 Aug 2018).

```m
let
    Source = Warehouse{[Schema = "star", Item = "weekly_summary"]}[Data],
    Typed = Table.TransformColumnTypes(Source, {
        {"week_start", type date},
        {"department", type text},
        {"summary", type text}
    }),
    Kept = Table.SelectColumns(Typed, {"week_start", "department", "summary"})
in
    Kept
```

| Column | Type | Meaning |
|---|---|---|
| `week_start` | Date | the Monday of the summarised week |
| `department` | Text | a department, or "All departments" |
| `summary` | Text | two or three sentences written by the local model and checked |

### client_setting

One row: the client's rule values from `rules` in `config/client.yaml`, written by `load.py`. The DAX
reads its thresholds from here, so a new client changes the yaml, not the measures.

```m
let
    Source = Warehouse{[Schema = "star", Item = "client_setting"]}[Data],
    Typed = Table.TransformColumnTypes(Source, {
        {"on_time_grace_days", Int64.Type},
        {"handover_grace_hours", Int64.Type},
        {"watch_list_min_lines", Int64.Type},
        {"watch_list_times_overall", type number}
    })
in
    Typed
```

| Column | Type | Meaning (demo value) |
|---|---|---|
| `on_time_grace_days` | Whole number | days after the promised date that still count as on time (0) |
| `handover_grace_hours` | Whole number | hours after the supplier's deadline that still count as an on-time hand-over (0) |
| `watch_list_min_lines` | Whole number | delivered lines a supplier needs to be judged (30) |
| `watch_list_times_overall` | Decimal number | how many times the overall late rate puts a supplier on the watch list (2) |

## 3. The measures table

**Home → Enter data.** Name the table `_Measures`, leave the one column as it is, **Load**. The
measures from `03-measures.dax` go in this table; once the first measure is in, delete `Column1`.

## What loads

| Query | Enable load | Rows |
|---|---|---|
| `Warehouse` | Off (staging) | |
| `fact_order_line` | On | 112,650 |
| `dim_supplier` | On | 3,095 |
| `dim_product` | On | 32,951 |
| `dim_date` | On | 774 |
| `buyer` | On (hidden in the model) | 10 |
| `weekly_summary` | On | 11 |
| `client_setting` | On (hidden in the model) | 1 |
| `_Measures` | On (measures only) | |

**Home → Close & Apply.**
