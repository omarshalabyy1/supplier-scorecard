# The project explained, from zero

This page explains the whole project in plain words: what it does, what every word means, where every number comes from, and how to talk about it in an interview. You do not need to know SQL, Power BI or AI to read it.

[← Back to the README](../README.md)

## 1. The project in one minute

A shop sells items from many suppliers. Each supplier must hand its items to a delivery company (the **carrier**) by a deadline, and the carrier then brings them to the customer by a promised date.

The buyers who manage those suppliers cannot answer simple questions until it is too late:

- Which suppliers deliver late, or not at all?
- Which departments have the most late deliveries?
- When a delivery is late, did it start with the supplier or with the carrier?

This project answers them. It loads the order history into a database, shapes it into tables a report can read, and puts a Power BI scorecard on top. The scorecard judges every order line on time, in full and late, scores every supplier and department, and lists the suppliers that need a call. A small artificial intelligence (AI) model on the laptop writes two or three sentences per department each week, and a check makes sure every number in them is real. Each buyer sees only their own department.

Think of it like a relay race with two batons. The supplier runs the first leg and must hand over by a deadline. The carrier runs the second leg and must finish by the promised date. If the team finishes late, you look at the first hand-over to see whether the trouble started there.

## 2. Words you will meet

| Word | What it means here |
|---|---|
| **Supplier** | A business that sells through the shop and ships the item itself. In this data the suppliers are marketplace sellers (see Data in the README). Each one gets a short code like `S0082`. |
| **Buyer** | The person at the shop who manages the suppliers of one department. There are 10 buyers, one per department. |
| **Department** | A group of product categories one buyer owns, like "Health & Beauty" or "Electronics". There are 10. |
| **Category** | The product type in the source data, like `beleza_saude` (health and beauty). `categories.csv` gives each of the 73 categories an English name and a department. |
| **Order, order line** | An order is one purchase by a customer. An order line is one item in that order, sold by one supplier. One order can have several lines. |
| **Carrier** | The delivery company that takes the item from the supplier to the customer. |
| **Hand-over, hand-over deadline** | The moment the supplier gives the item to the carrier, and the latest time it promised to do so (the supplier's promise). |
| **Promised date** | The delivery date promised to the customer (the customer's promise). In the tables it is called `due_date`. |
| **In full** | The line was delivered. The data has no part quantities, so a line is either delivered or not. |
| **On time** | Delivered on or before the promised date. |
| **Late** | Delivered after the promised date. |
| **Late hand-over** | The carrier got the item after the supplier's deadline. |
| **OTIF** | On time in full: on-time lines ÷ all order lines. The main score. |
| **Fill rate** | Delivered lines ÷ all order lines. |
| **Late rate** | Late lines ÷ delivered lines. A line that never arrived cannot be late, so it is left out. |
| **Days late** | Days between the promised date and the delivery, for late lines only. |
| **Watch list** | Suppliers that need a call: at least 30 delivered lines and a late rate at least twice the rate of all suppliers. |
| **Grace days, grace hours** | Extra time a client may allow before a line counts as late. Both are 0 here, set in `config/client.yaml`. |
| **Database** | A program that stores tables and answers questions about them. This project uses **PostgreSQL** (often "Postgres"), a free and widely used one. |
| **SQL** | Structured Query Language, used to ask a database questions and build tables. The `.sql` files in `sql/` are SQL. |
| **Table, row, column** | Like a spreadsheet sheet: each row is one thing (one order line, one supplier), each column is one fact about it (its date, its department). |
| **Schema** | A folder of tables inside the database. This project has two: `raw` (the files as they came) and `star` (the tables the report reads). |
| **CSV** | Comma-separated values: a plain text file of a table, one row per line. The six inputs are CSV files. |
| **`COPY`** | The PostgreSQL command that loads a whole file into a table at once. Much faster than inserting rows one by one. |
| **Transaction** | A group of database changes that all succeed together or are all undone together ("rolled back"). The whole load is one transaction. |
| **Fact table** | The big table of events you count. Here `fact_order_line`: one row per order line, with both promises' dates. |
| **Dimension table** | A smaller lookup table that describes the facts: the suppliers (`dim_supplier`), the products (`dim_product`) and the days (`dim_date`). You filter and group by them. |
| **Star schema** | One fact table in the middle with dimension tables around it, like a star. It is the standard shape for Power BI reports. See [data-model.svg](data-model.svg). |
| **Grain** | What one row of a table stands for. The grain of `fact_order_line` is "one item of one order, from one supplier". |
| **Primary key (PK)** | The column (or columns) that makes each row unique. Two rows can never share it, so a duplicated row stops the load. |
| **Foreign key (FK)** | A column that must point to an existing row in another table. A product whose category is missing from `categories.csv` stops the load. |
| **Natural key, surrogate key** | A natural key already exists in the data (a seller's long id). A surrogate key is a made-up number: `supplier_key` 1, 2, 3, and the short code `S0001`, `S0002` built from it. |
| **Date table** | `dim_date`: one row per day, so every day exists even if nothing happened on it. Power BI needs one to group by month and week. |
| **Python, pandas** | Python is a programming language. pandas is its library for tables. `load.py`, `summarize.py` and the notebook use them. |
| **Notebook** | `analysis/analysis.ipynb`, a file that mixes code, its output and notes. It computes every number in the README from the input files. |
| **Docker, Docker Compose** | Docker runs programs in a ready-made box called a container, so nobody installs PostgreSQL by hand. `docker-compose.yml` says which box to start. |
| **Port 5435** | The "door number" the database listens on, on this computer only. Each portfolio project uses its own number so several can run at once. |
| **`.env`** | A file for secrets, like the database password. It is never committed; `.env.example` shows its shape. |
| **`config/client.yaml`** | The settings a client would change: name, file names, rule thresholds, the summary week, chart window and colours. YAML is a simple text format for settings. |
| **Power BI** | Microsoft's tool for interactive reports and dashboards. |
| **Power Query** | The part of Power BI that loads and shapes data before the report uses it. |
| **DAX** | Data Analysis Expressions, the formula language of Power BI. |
| **Measure** | A DAX calculation that gives one number for whatever is filtered, like `Late Rate %`. The report has 19. |
| **Calculated column** | A DAX column added to a table, worked out once per row. `Delivery` ("On time", "Late", "Not delivered") and `Handover` hold the rules. |
| **Row-level security (RLS)** | A Power BI rule that hides rows from some users. Here the `Buyer` role shows each buyer only their department's lines. |
| **`USERPRINCIPALNAME()`** | The DAX function that returns the sign-in of the person viewing the report. The security rule looks it up in the `buyer` table. |
| **Drill-through** | Right-click a supplier on one page and jump to a page about that supplier only (page 4, Supplier detail). |
| **Theme** | A Power BI file that sets the report's colours and fonts. `theme.py` writes it from `client.yaml`. |
| **LLM** | Large language model: an AI model that writes text. This project uses one only to put numbers into words. |
| **Ollama, llama3.2 3B** | Ollama is a free program that runs an LLM on your own computer, so no data leaves it. llama3.2 3B is the model: a small one with 3 billion parameters (the numbers the model learned), small enough for a laptop. |
| **Prompt** | The instructions given to the model. In `summarize.py` it says: two or three sentences, copy every number exactly, never calculate a new one. |
| **JSON** | JavaScript Object Notation, a plain text format for data, like `{"late rate": "3.0%"}`. The facts go to the model as JSON, and its answer comes back as JSON. |
| **Pydantic** | A Python library that checks data has the right shape. Here it checks the model's answer has a `summary` of at least 80 characters. |
| **Temperature** | How much the model varies its wording. 0.3 is low: the wording changes a little from run to run, the numbers do not. |

## 3. How it works, file by file

Run in this order (the commands are in the README's "Run it" section):

| Step | File | What it does |
|---|---|---|
| 0 | `docker-compose.yml` | Starts PostgreSQL 17 in a container on port 5435. |
| 0 | `config/client.yaml`, `config.py` | Hold every setting; `config.py` (`load_config()`) is the only reader, and it stops if a setting or the password is missing. |
| 1 | `load.py` + `sql/01_raw.sql` | Checks that the 6 input files exist and have the needed columns, before the database changes. Then loads each into a `raw` table with `COPY`, unchanged. Primary keys stop a duplicated row; a foreign key stops a product category that `categories.csv` does not know. |
| 2 | `sql/02_star.sql` | Builds the star schema: `dim_supplier` (gives each supplier its code), `dim_product` (category and department; a product with no category goes to "Other"), `dim_date`, `fact_order_line`, plus `buyer`, `client_setting` (the rule thresholds from `client.yaml`) and an empty `weekly_summary`. |
| 3 | `sql/03_checks.sql` | Four checks: every order line reached the fact table, every department has a buyer, every promised date is in `dim_date`, and no delivery comes before its purchase. If any fails, `load.py` stops with `CHECK FAILED` and the whole transaction is undone, so the report keeps the last good load. |
| 4 | `summarize.py` | For the week in `summary.week`, works out each department's numbers in SQL, sends them to the local model, checks the answer and saves it in `star.weekly_summary`. See "The weekly summary" below. |
| 5 | `theme.py` | Writes the Power BI theme file (`powerbi/05-theme.json`) from the colours in `client.yaml`. |
| 6 | `analysis/analysis.ipynb` | Reads the input files with pandas (not the database), computes every number in the README and draws the charts in `docs/`. |
| 7 | `sql/check_numbers.sql` | The same headline numbers in SQL on the database, so the notebook and the database can be compared. |
| 8 | `powerbi/` | Step-by-step instructions to build the report: queries, model, the 2 calculated columns and 19 measures (`03-measures.dax`), pages, theme, and the numbers each visual must show (`06-checks.md`), in a 38-step checklist. |

The 6 input files: 4 come from the order history (orders, order items, products, sellers; you download them, see Data in the README) and 2 are small files committed in `data/input/` (`categories.csv` gives each category its department, `buyers.csv` gives each buyer's sign-in its department).

### The rules, with an example

One real order line from the data (order `001d8f0e…`, line 1). This order has two lines, both the same product from the same supplier, so both are judged the same way. The supplier's long id is `f4aba7c0…`, a seller in São Paulo. Sorted by that id, it is the 2,962nd supplier, so its code is `S2962`. The product's category is `beleza_saude`, which `categories.csv` puts in **Health & Beauty**.

| Moment | Date and time | Column |
|---|---|---|
| Ordered | 14 May 2017, 17:19 | `purchase_date` |
| Supplier's hand-over deadline | 18 May 2017, 17:35 | `handover_due` |
| Handed to the carrier | 24 May 2017, 15:45 | `handed_over` |
| Promised to the customer | 24 May 2017 | `due_date` |
| Delivered | 26 May 2017 | `delivered_date` |

1. **In full?** There is a delivery date, so yes. It counts in Delivered Lines.
2. **On time?** Delivered 26 May, promised 24 May, with 0 grace days. 26 May is after 24 May, so the line is **Late**, by 26 − 24 = 2 days.
3. **Late hand-over?** The carrier got it on 24 May at 15:45, after the deadline of 18 May at 17:35 (0 grace hours). So yes: a **late hand-over**. The gap is 5 days and 22 hours; the picture rounds it to "6 days" by counting calendar days (24 − 18).
4. **What it adds to.** This line is one of the 7,265 late lines, and one of the 2,108 late lines that started with a late hand-over (the "29%"). Its supplier `S2962` had 115 delivered lines, 7 of them late: 7 / 115 = 6.1%, under the watch-list mark of 13.2%, so `S2962` is not on the watch list.

The supplier handed over 6 days late, on the very day the customer was promised the item. The carrier then took 2 more days. The delivery was late, and it started with the supplier. This is the line in [mental-model.svg](mental-model.svg); notebook cell 17 picks it as the first late line with a late hand-over, by order id.

### The weekly summary (the AI part)

`summarize.py` writes one short text per department per week. The model never works out a number. The steps:

1. **SQL works out the facts** for the week and the week before: order lines due, late rate this week and last week, OTIF, and the supplier with the most late lines.
2. **The model writes.** The facts go to llama3.2 3B through Ollama as JSON, with the prompt. Pydantic makes the model answer in JSON with one field, `summary`, at least 80 characters long.
3. **Three checks.** Every number in the text must appear in the facts. Every supplier code it names must be the one in the facts. And it must say the late rate went the right way: "down from" when it fell, "up from" when it rose, "the same as" when it did not move, and never words like "increase" when it fell.
4. **Try again or stop.** A text that fails a check is written again. After three failed tries the run stops, and because the save is in one transaction, nothing is saved.
5. **Save.** A text that passes goes into `star.weekly_summary`, one row per week and department. Running the same week again replaces the old text instead of adding a second one.

It writes 11 texts: one per department (10) and one for all departments. There is no fixed test set of summaries in the repo: the README does not claim an accuracy score, only that a summary breaking a check is never saved. The two mistakes the README mentions (saying "increased" when the rate fell, and naming the example supplier from the prompt) come from the author's first runs; no log of them is in the repo.

## 4. Every number, explained

The notebook ([`analysis/analysis.ipynb`](../analysis/analysis.ipynb)) prints almost all of these. The cell numbers below count from 0, the first cell. A few are not printed by the notebook; those say so, and were worked out with pandas from the same input files with the same rules.

### The headline and the results table

| Number | What it means | How it is worked out | Where |
|---|---|---|---|
| **98,666 orders** | Orders with at least one order line. | Count of distinct order ids among the order lines. | notebook cell 5 |
| **112,650 order lines** | Every item of every order. | Count of rows in the order items file. The fact table holds the same count, and `03_checks.sql` stops the load if not. | notebook cells 1, 3, 5 |
| **3,095 suppliers** | Every supplier in the sellers file. | Count of rows. | notebook cell 1 |
| **91.4% on time and in full** | OTIF: the share of all lines that arrived on time. | 102,931 on-time lines / 112,650 lines = 91.37%. | notebook cell 5; `sql/check_numbers.sql` |
| **97.8% of lines delivered** | Fill rate. | 110,196 delivered lines / 112,650 lines = 97.82%. | notebook cell 5 |
| **6.6% of delivered lines late** | Late rate. | 7,265 late lines / 110,196 delivered lines = 6.59%. Also the "All suppliers 6.6%" in header.svg. | notebook cell 5 |
| **10.5 days on average** | How late a late line is, on average. | 76,201 days late in total / 7,265 late lines = 10.49 days. | notebook cell 5 |
| **29% of late deliveries started with a late hand-over** | The headline. Of all late lines, the share whose supplier also handed over late. | 2,108 lines both late and with a late hand-over / 7,265 late lines = 29.02%. | notebook cells 5, 15, 21 |
| **20.5% after a late hand-over** | When the supplier handed over late, how often the delivery was late. | 2,108 late / 10,271 delivered lines with a late hand-over = 20.52%. | notebook cell 15 |
| **5.2% after an on-time hand-over** | The same for suppliers that handed over on time. | 5,156 late / 99,924 delivered lines with an on-time hand-over = 5.16%. | notebook cell 15 |
| **4 times as likely** | How much a late hand-over raises the chance of a late delivery. | 20.52 / 5.16 = 3.98, shown as 4.0 in the notebook. | notebook cell 15 |
| **61 suppliers on the watch list** | Suppliers with at least 30 delivered lines and a late rate of at least 13.19%. | 13.19% = 2 × 6.59% (twice the rate of all suppliers). 61 suppliers pass both tests. | notebook cell 12 |
| **2,970 suppliers that delivered** | Suppliers with at least one delivered line. | Count of suppliers whose delivered lines are above 0. | notebook cell 12 |
| **2.1% of suppliers** | The watch list's share of suppliers. | 61 / 2,970 = 2.05%. | notebook cell 12 |
| **4.4% of deliveries** | The watch list's share of delivered lines. | 4,893 / 110,196 = 4.44%. | notebook cell 12 |
| **12.0% (12%) of late ones** | The watch list's share of late lines. | 875 / 7,265 = 12.04%. | notebook cell 12 |
| **S0082: 78 of 402 (19.4%)** | The supplier with the most late lines. | 78 late / 402 delivered lines = 19.40%. It had 405 lines; 3 were never delivered. | notebook cell 12 (first row of the table) |
| **Health & Beauty 7.3%** | The department late most often. | 934 late / 12,846 delivered = 7.27%. | notebook cell 7 |
| **Kitchen & Appliances 4.9%** | The department late least often. | 434 late / 8,828 delivered = 4.92%. | notebook cell 7 |
| **December 2017: 12.2%** | Late rate of lines promised that month. | 1,005 late / 8,210 delivered = 12.24%. | notebook cell 10 |
| **March 2018: 16.3%, April 2018: 13.5%** | The same for those months. March is the highest month. | 1,596 / 9,786 = 16.31%; 1,022 / 7,548 = 13.54%. | notebook cell 10 |
| **Between 1.5% and 6.8%** | Every other month in the chart window. | Lowest July 2018: 120 / 8,146 = 1.47%. Highest June 2018: 359 / 5,319 = 6.75%. | notebook cell 10 |
| **1.3% of orders with several suppliers** | Orders whose lines come from more than one supplier, which share one carrier date. | 1,278 / 98,666 orders = 1.30%. Not printed by the notebook; worked out with pandas from the order items file. | pandas, not in the notebook |
| **March 2017 to August 2018** | The months the trend charts show. | `report.trend_from` and `report.trend_to` in `config/client.yaml`. March 2017 is the first month with at least 1,000 delivered lines (2,985; February 2017 had 348). The history ends in August 2018. | `config/client.yaml`; notebook cell 10 |
| **30 lines, twice the late rate** | The watch-list rule. | Settings `watch_list_min_lines` and `watch_list_times_overall` in `config/client.yaml`, copied into `star.client_setting`. | `config/client.yaml` |
| **38 steps, 19 measures, 4 pages** | The size of the Power BI build. | Count of numbered steps in `powerbi/08-build-checklist.md` and of measures in `powerbi/03-measures.dax`. | `powerbi/` |
| **About three minutes** | How long the 3B model takes to write the 11 summaries on a laptop processor. | Timed by hand on one laptop; not measured by any file in the repo. | README only |

### The weekly summary example

The README quotes one summary: Home & Furniture, week of 27 August 2018. The notebook (cell 19) prints only the all-department numbers for that week (2,035 lines due, late rate 2.49% against 6.59% the week before, OTIF 96.41%). The Home & Furniture numbers below were worked out with pandas from the input files, with the same rules as `summarize.py`:

| Number | How it is worked out |
|---|---|
| **375 order lines** | Home & Furniture lines promised in the week starting Monday 27 August 2018. |
| **3.0%** | 11 late / 371 delivered = 2.96%, rounded to one decimal as `summarize.py` does. |
| **6.8% last week** | Week of 20 August: 27 late / 396 delivered = 6.82%. This is Home & Furniture's own rate, not the overall 6.6%. |
| **96.0%** | 360 on-time lines / 375 lines = 96.0% OTIF. |
| **S0193, 4 late lines** | The Home & Furniture supplier with the most late lines that week. |

Things that can look wrong but are not:

- **99,441 orders in data-flow.svg, 98,666 in the headline.** 775 orders in the orders file have no order line: 603 "unavailable", 164 "canceled", 5 "created", 2 "invoiced" and 1 "shipped". With no line, they have no supplier to score.
- **3,095 suppliers, but 2,970 "that delivered".** 125 suppliers never delivered a single line (206 lines in total), so they have no late rate. They still count in Order Lines and OTIF.
- **91.4% + 6.6% is not 100%.** They use different bottoms. OTIF divides by all 112,650 lines; the late rate divides by the 110,196 delivered lines. Counted the same way: 102,931 on time + 7,265 late + 2,454 not delivered = 112,650.
- **10,271 + 99,924 = 110,195, one less than 110,196 delivered.** One delivered line has no carrier date, so it has no hand-over to judge. And the 10,423 late hand-overs in all are more than the 10,271 in the hand-over chart, because 152 of them were never delivered.
- **The supplier table in Power BI shows 91.5% and 9.3%, the cards 91.4% and 9.4%.** The table keeps only suppliers with a delivered line, which leaves out the 206 lines above. `powerbi/06-checks.md` says so.
- **29%, 29.0%, 29.02%.** The same number, rounded to 0, 1 or 2 decimals in different places. The same goes for 12% and 12.0%, and "4 times" for 3.98.
- **More order lines (112,650) than orders (98,666).** One order can hold several items: the example order has two lines.
- **"Other" holds 1,914 lines.** 1,603 come from products with no category in the source, and 311 from the one category `categories.csv` puts in "Other".
- **`dim_date` runs to 12 November 2018,** past the last delivery. It covers every promised date, from 30 September 2016 to 12 November 2018: 774 days.
- **September 2018 is not in the trend chart, though it has 2,214 delivered lines.** All of them arrived by 31 August, because the history ends there. Any line that would have arrived late is simply missing, so its late rate (0 late) would look perfect when it is not.

### The diagrams

| Number | Where you see it | What it means |
|---|---|---|
| **6 CSV files, 4 order exports** | data-flow.svg | The 6 inputs: 4 from the order history (orders, order items, products, sellers) plus `categories.csv` and `buyers.csv`. |
| **99,441** | data-flow.svg | Rows in `raw.orders`: every order in the file, including the 775 with no line. Notebook cell 1. |
| **112,650** | data-flow.svg, data-model.svg | Rows in `raw.order_items` and in `fact_order_line`: one per order line, the same count in both. Notebook cell 1. |
| **73** | data-flow.svg | Rows in `raw.categories`: one per category in `categories.csv`. |
| **32,951** | data-flow.svg, data-model.svg | Rows in `raw.products` and `dim_product`: one per product. Notebook cell 1. |
| **3,095** | data-flow.svg, data-model.svg | Rows in `raw.sellers` and `dim_supplier`: one per supplier. Notebook cell 1. |
| **10** | data-flow.svg, data-model.svg | Rows in `raw.buyers` and `buyer`: one buyer per department. |
| **774 rows** | data-flow.svg, data-model.svg | Days in `dim_date`, from 30 September 2016 to 12 November 2018. |
| **1 row** | data-flow.svg, data-model.svg | `client_setting`: the 4 rule values (0, 0, 30, 2). |
| **11 rows** | data-flow.svg, data-model.svg | `weekly_summary` after one week: 10 departments plus all departments. |
| **1 to \*** | data-model.svg | One dimension row links to many fact rows: one supplier has many order lines. |
| **01 to 05; 1, 2, 3** | how-it-works.svg, data-flow.svg | Step numbers: load, rules, secure, explain, report; and raw, star schema, Power BI. |
| **29%** | header.svg, mental-model.svg | The headline: 2,108 / 7,265 (above). |
| **S0082 19.4%, S1670 16.3% (WATCH)** | header.svg | Two watch-list suppliers. S0082: 78 / 402. S1670: 49 / 300 = 16.33%. Both in notebook cell 12. |
| **S1236 5.1%** | header.svg | The supplier with the most delivered lines (1,996), shown as a large supplier that is not on the watch list: 102 late / 1,996 = 5.11%. Not printed by the notebook; worked out with pandas. |
| **All suppliers 6.6%** | header.svg | The overall late rate, 7,265 / 110,196. |
| **14, 18, 24, 26 May; 6 days, 2 days** | mental-model.svg | The example line in section 3: ordered, hand-over deadline, handed over and promised, delivered. Notebook cell 17. |
| **20.5%, 5.2%** | mental-model.svg | Late rate after a late and an on-time hand-over. Notebook cell 15. |

The four charts in the README are drawn by the notebook: `late-rate-by-department.png` in cell 8, `late-rate-by-month.png` in cell 10, `suppliers-watch-list.png` in cell 13 and `handover-effect.png` in cell 15. Their numbers are the ones in the table above.

## 5. What the results mean for the business

- **Most deliveries are fine.** 91.4% of all lines arrived on time and in full, and 97.8% arrived at all. The problem is a minority, so it is worth finding exactly where it sits.
- **The supplier's hand-over is the place to look first.** After a late hand-over, 20.5% of deliveries arrive late; after an on-time one, 5.2%. 29% of all late deliveries started there. A buyer can raise hand-over time with a supplier directly, which is harder to do with a carrier.
- **A short list does a lot of the damage.** 61 suppliers (2.1% of those that delivered) handle 4.4% of deliveries but 12.0% of late ones. The buyers know which suppliers to call first.
- **Departments differ less than suppliers.** Department late rates run from 4.9% to 7.3%. The spread between suppliers is much wider: S0082 is late on 19.4% of its lines.
- **Some months need a plan.** Late rates jumped in December 2017 (12.2%) and in March and April 2018 (16.3% and 13.5%). Buyers can agree tighter hand-over times with suppliers before busy months.
- **The weekly summary saves a buyer reading charts.** For the chosen week they get two or three sentences with the week's numbers and one supplier to call.

## 6. Interview questions you can expect

**Explain the project in 30 seconds.**
Buyers found out which suppliers delivered late only when the shelf was empty. I loaded the order history into a PostgreSQL star schema with one row per order line, wrote the rules for on time, in full and late once in DAX, and built a Power BI scorecard by supplier and department where each buyer sees only their department. A local LLM writes a weekly summary, and code checks every number in it. Result: 91.4% on time and in full, 29% of late deliveries started with a late hand-over by the supplier, and 61 suppliers with 4.4% of deliveries caused 12% of late ones.

**Why one row per order line, not per order?**
Because a supplier and a product belong to a line, not to an order: 1.3% of orders have lines from more than one supplier. With one row per line, every score is a simple count, and it adds up the same way by supplier, department or month.

**How do you tell the supplier's part from the carrier's?**
Each line carries two promises: the supplier's hand-over deadline and the date promised to the customer. I judge the line against both. If the hand-over was late, the late delivery is linked to the supplier. It is a link, not proof: the carrier may also have been slow, and the README says so in its limits.

**Why are the rules DAX calculated columns?**
So the report has one definition: `Delivery` and `Handover` are worked out once per line, and all 19 measures filter on them instead of repeating the logic. The thresholds come from the `client_setting` table, so no measure holds a client's number. The same rules also exist in SQL (`check_numbers.sql`, `summarize.py`) and pandas (the notebook); that repetition is on purpose, so three separate calculations can be compared.

**How do you know the numbers are right?**
Three ways. The notebook reads the input files with pandas and never touches the database, so it is an independent answer. `sql/check_numbers.sql` computes the same numbers on the database, and `powerbi/06-checks.md` lists the number each visual must show. On top of that, `load.py` runs four checks and loads everything in one transaction: if a check fails, nothing changes and the report keeps the last good load.

**Why is the watch list "30 lines and twice the overall rate", not a fixed late rate?**
A supplier with 1 line that arrived late has a 100% late rate, which says nothing. The 30-line minimum keeps out suppliers too small to judge. Twice the overall rate moves with the business: when a buyer filters to one department, the mark becomes twice that department's own rate. Both numbers are client settings and a starting point to tune with the buyers.

**How does each buyer see only their department?**
One dynamic row-level security role. A `buyer` table maps each sign-in to a department, and the rule keeps only the products whose department matches `USERPRINCIPALNAME()`. The filter then flows from `dim_product` to the fact table. A new buyer is one new row in `buyers.csv`, not a new role.

**How do you stop the LLM from inventing numbers?**
The model never calculates. SQL works out the facts, and the model only puts them into words. Then code checks the text: every number must be one of the facts, every supplier code must be the one given, and the direction of the late rate must be right. A text that fails is written again, and after three tries the run stops and saves nothing. It runs on Ollama on the laptop, so no order data leaves the machine and there is no cost per call.

**Why surrogate keys like S0082, and what is the risk?**
Seller ids are long random strings, hard to read on a chart, and the data has no supplier names. So `02_star.sql` numbers the suppliers by sorting their ids and turns the number into a code. The risk: the numbering is redone on every load, so if a new supplier's id sorts early, every later code shifts by one. For a live client I would store the code once per seller and keep it, or use the client's own supplier number.

**How would you set it up for a real client?**
Change `config/client.yaml` (name, file names, grace days, watch-list rule, summary week, colours), put their 6 files in `data/input/` (`buyers.csv` with real sign-ins), and run the same commands. No code changes.

## 7. Limits, in plain words

- The suppliers are marketplace sellers that ship straight to customers; the hand-over deadline is the marketplace's shipping limit for each item.
- The carrier's pick-up date is kept per order, not per line. In the 1.3% of orders with several suppliers, each supplier gets the same date.
- "In full" means delivered. The data has no part quantities, so a short delivery cannot be seen.
- A late delivery after a late hand-over is linked to the supplier, not proven to be caused by it.
- The history ends in August 2018, so the charts stop there.
- Supplier codes (S0001 and so on) are given again on every load, so a new supplier can shift them.
- There is no fixed test set for the weekly summaries. The checks stop wrong numbers, wrong suppliers and the wrong direction, but nobody has scored the wording.
