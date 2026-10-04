# 01 · Power Query

Every query reads one table of the `star` schema in PostgreSQL. Nothing is cleaned in Power Query: the
cleaning and the checks happen in `load.py`, so the report only sets column types.

Before you start: `docker compose up -d`, `python load.py` and `python summarize.py 2018-08-27` have run
(see the main README).

## 1. The connection (staging query, not loaded)

1. Home → Get data → Blank query. Rename it `Warehouse`.
2. Home → Advanced Editor, paste, Done:

```m
let
    Source = PostgreSQL.Database("localhost:5435", "scorecard")
in
    Source
```

3. When asked for credentials, choose **Database**: user `scorecard`, password `scorecard`.
4. If Power BI says it cannot connect with encryption, choose **OK** to connect without it (the database
   only listens on this computer).
5. Right-click `Warehouse` → untick **Enable load**. It stays a staging query: every other query starts
   from it, so the server name lives in one place.

## 2. The tables (each one loaded)

For each query below: Home → New source → Blank query, rename it to the name in the heading, open the
Advanced Editor and paste.

### fact_order_line

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
        {"delivered_date", type date},
        {"price", Currency.Type},
        {"freight_value", Currency.Type}
    })
in
    Typed
```

### dim_supplier

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

### dim_product

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

### dim_date

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

### buyer

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

### weekly_summary

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

## 3. The measures table

Home → Enter data. Name the table `_Measures`, leave the one column empty, Load. The measures in
`03-measures.dax` go in this table; once the first measure is in, delete the empty column (`Column1`).

## What loads

| Query | Loads | Rows |
|---|---|---|
| `Warehouse` | No (staging) | |
| `fact_order_line` | Yes | 112,650 |
| `dim_supplier` | Yes | 3,095 |
| `dim_product` | Yes | 32,951 |
| `dim_date` | Yes | 774 |
| `buyer` | Yes (hidden, used by security) | 10 |
| `weekly_summary` | Yes | 11 per summarised week |
| `_Measures` | Yes (measures only) | |

Close & Apply.
