# New client

This repo is a GitHub template for the offering **Power BI supplier scorecard**. A new client gets a
**private** repo from it (Use this template > Create a new repository > Private); client data never goes
into this public repo. Everything that changes per client is in three places: `config/client.yaml`,
`.env`, and the files in `data/input/`.

## Done in the template

What the client gets with no work. Hours are an estimate of building each part from scratch.

| Part | Estimate (hours) |
|---|---|
| PostgreSQL warehouse in Docker; six input files checked for their columns, then loaded with `COPY`; keys and the category foreign key; four load checks in one transaction (`load.py`, `sql/01_raw.sql`, `sql/03_checks.sql`) | 3 |
| Star schema: the order-line fact with both promises' dates, supplier, product and department, date, and the client's rule settings (`sql/02_star.sql`) | 2 |
| The rules and 19 measures in DAX, the supplier watch list, one dynamic row-level security role (`powerbi/02-model.md`, `powerbi/03-measures.dax`) | 4 |
| Weekly summaries written by a local LLM, with the three checks on numbers, suppliers and direction (`summarize.py`) | 4 |
| Client settings: `config/client.yaml`, `config.py` (`load_config()`), `.env`, the Power BI theme written from the config (`theme.py`) | 2 |
| Analysis notebook: every number and four charts (`analysis/analysis.ipynb`), and the SQL check (`sql/check_numbers.sql`) | 4 |
| Power BI build pack: 7 queries, the model, 2 calculated columns, 19 measures, 4 pages with 39 visuals, interactions, checks, a 38-step checklist (`powerbi/`) | 8 |
| README with its diagrams, and the input file guide (`data/input/README.md`) | 3 |
| **Total** | **30** |

## Configure

Per client, file by file. Hours are an estimate.

| File | Key | Example | Estimate (hours) |
|---|---|---|---|
| `config/client.yaml` | `client.name`, `report.title`, `report.colours` | `Client C`, `"#0F766E"` | 0.5 |
| `.env` | `DB_PASSWORD` | a new password | 0.25 |
| `data/input/` orders, order lines, products, suppliers | `inputs.orders`, `inputs.order_items`, `inputs.products`, `inputs.sellers` | the client's export with its columns renamed to the template's | 3 |
| `data/input/` mapping files | `inputs.categories`, `inputs.buyers` | `HOM-01,kitchenware,Home goods` | 1.5 |
| `config/client.yaml` | `rules.*`, `summary.week`, `summary.model`, `report.trend_from`, `report.trend_to` | `1`, `12`, `2`, `1.6`, `"2025-03-10"` | 0.25 |
| Ollama on the client's machine; run `load.py`, `summarize.py`, `theme.py` and the notebook; fix what the checks report | | | 1 |
| Power BI: build from `powerbi/08-build-checklist.md` with the client's server in the Warehouse query; the client's numbers into `powerbi/06-checks.md` | `warehouse.*` | `127.0.0.1:5435` | 3 |
| **Total** | | | **9.5** |

## Custom

Typical work for one client beyond the template. Hours are an estimate.

| Work | Estimate (hours) |
|---|---|
| In full by quantity (ordered against received) instead of delivered or not: two input columns, the rule and two measures | 4 |
| A scheduled weekly run: load, summaries and a Power BI refresh through a gateway | 3 |
| Summaries in another language: the prompt and the words the direction check looks for | 2 |
| One more page, for example supplier lead time or purchase cost | 4 |
| **Total** | **13** |

## Share already done (estimate)

Template hours ÷ (template + configure + custom) hours = 30 ÷ (30 + 9.5 + 13) = 30 ÷ 52.5 = **57%** (57.1%).

## Steps

1. Create the private repo from the template and clone it.
2. `cp .env.example .env` and set `DB_PASSWORD`.
3. Edit `config/client.yaml`.
4. Put the six files in `data/input/` ([columns and examples](../data/input/README.md)).
5. `docker compose up -d`, `python load.py`; start Ollama and pull `summary.model`; `python summarize.py`,
   `python theme.py`, then run the notebook.
6. Build the Power BI report from `powerbi/08-build-checklist.md`, with the notebook's numbers in
   `powerbi/06-checks.md`.

## Second-client drill (2026-10-05)

The acceptance test of the template: a fresh clone, a made-up second client, a run from scratch.

**Client C (drill):** different file names (`orders.csv`, `lines.csv`, `products.csv`, `suppliers.csv`,
`category_map.csv`, `buyers.csv`), category codes of another shape (`HOM-01`, `ELE-02`, `GRO-03`),
three departments plus "Other", rules `on_time_grace_days: 1`, `handover_grace_hours: 12`,
`watch_list_min_lines: 2`, `watch_list_times_overall: 1.6`, summary week `2025-03-10`, chart window
Feb to Mar 2025, teal colours (`#0F766E`). Input: 9 orders and 11 order lines from 3 suppliers; an
extra column in orders (`channel`) and in order lines (`unit_price`). Planted cases: a delivery 1 day
late and a hand-over 10 hours late, both inside the grace, so on time; four lines delivered 3 or 4
days late; two hand-overs 22 and 26 hours late; a late delivery after an on-time hand-over; a canceled
order of two lines never delivered (short); a product with no category; one order from two suppliers.

| What | Demo | Client C (drill) |
|---|---|---|
| Load | all checks passed; 112,650 order lines | all checks passed; 11 order lines |
| Orders · delivered · late | 98,666 · 110,196 · 7,265 | 9 · 9 · 4 |
| Late rate · fill rate · OTIF | 6.59% · 97.82% · 91.37% | 44.44% · 81.82% · 45.45% |
| Average days late | 10.49 | 3.50 |
| Late hand-overs · rate | 10,423 · 9.35% | 2 · 22.22% |
| Late deliveries after a late hand-over | 29.02% | 50.00% |
| Watch list (threshold) | 61 suppliers, 4.44% of deliveries, 12.04% of late (13.19%) | 1 supplier (S0002), 22.22% of deliveries, 50.00% of late (71.11%) |
| Summaries | 11 for the week of 27 Aug 2018 | 3 for the week of 10 Mar 2025 (All, Home goods, Tech); Grocery and Other skipped for lack of deliveries in one of the two weeks |
| Power BI theme | "Supplier scorecard", `#2563EB` | "Client C supplier scorecard", `#0F766E`, page `#F0FDFA` |
| Notebook | 0 errors | 0 errors; chart titles name Client C, teal colours |

Every Client C number matches a hand calculation from its 11 lines, in the notebook, in
`sql/check_numbers.sql` and in the summaries (week: 7 lines due, late rate 60.0% up from 33.3%, 28.6%
on time and in full, follow up S0003 with 2 late lines).

**Clear failures**, one line each, run on the Client C copy:

```
config/client.yaml is missing rules.watch_list_min_lines
config/client.yaml is not valid YAML: while parsing a flow sequence
.env is missing DB_PASSWORD (copy .env.example to .env)
missing input file data/input/suppliers.csv (inputs.sellers in config/client.yaml)
data/input/lines.csv is missing column(s): shipping_limit_date
summary.week in config/client.yaml must be a Monday (the start of the week).
data/input/products.csv: Key (product_category_name)=(GRO-99) is not present in table "categories".
data/input/orders.csv: Key (order_id)=(O9) already exists.
CHECK FAILED: every department has a buyer (1 rows). Load rolled back: the warehouse keeps the last good load.
```

**Nothing hard-coded:** this search over the code (`*.py`, `sql/*.sql`, `powerbi/03-measures.dax`,
`docker-compose.yml`), the Power Query M code and the notebook's source cells finds nothing:

```
Sample marketplace|#[0-9A-Fa-f]{6}|olist_|2018-08-27|llama3|2017-03|2018-08|Health & Beauty|Electronics|>= 30|\b2 \* |buyer\.[a-z]+@
```

The README, the diagrams in `docs/`, `powerbi/06-checks.md` and the demo values quoted next to config
keys in `powerbi/` describe the demo run, so they keep its values on purpose.

**Nothing broke:** after the drill, `python load.py` on the demo data passed again with the same totals.

## Gaps against the template standard

- **No `client.currency` or `client.decimals`:** the scorecard counts lines and dates, not money, so
  nothing reads them.
- **No `report.check_month`:** the checks use the whole history and a click on one department instead.
  `report.trend_from` and `report.trend_to` set the month charts' window.
- **Rules in DAX, values in a table:** the rules are DAX calculated columns (the offering says "written
  once in DAX"), so the thresholds reach Power BI through the one-row `star.client_setting` table,
  written from `rules` by `load.py`, rather than only through `current_setting()` in SQL.
- **No summary language key:** the direction check looks for English words ("down from", "up from"), so
  another language is custom work (above).
- **Typed by hand in Power BI:** the two watch-list numbers in the Suppliers page subtitle and the
  scatter's X-axis constant line come from `rules.*`, as do the month charts' date filter
  (`report.trend_*`); Power BI cannot read them from the yaml.
- **The Warehouse query** keeps the demo's server line, as in the pilot; the client changes that one line.
- **"Other":** a product with no category goes to the department "Other", so the buyers file needs an
  "Other" row when such products exist; `load.py`'s buyer check names it.
- **Ollama on an older NVIDIA card** crashes in its GPU builds; run it CPU-only
  (`powerbi/08-build-checklist.md`, step 4).
