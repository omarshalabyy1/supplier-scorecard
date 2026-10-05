# 06 · Checks: the numbers the report must show

Every number below was computed with pandas from the source files, with the same rules as
`analysis/analysis.ipynb`, and the totals match `sql/check_numbers.sql` on the warehouse. If a visual
shows anything else, the build has a mistake: check the relationship, the calculated column, the
measure or the visual filter behind it.

All checks are with **no slicer selected**, **nothing clicked** and **not viewing as a role**, unless the
row says otherwise. Power BI shows percentages to one decimal place; the values below are rounded the
same way.

## Row counts (Table view, bottom left)

| Table | Rows |
|---|---|
| `fact_order_line` | 112,650 |
| `dim_supplier` | 3,095 |
| `dim_product` | 32,951 |
| `dim_date` | 774 |
| `buyer` | 10 |
| `weekly_summary` | 11 |
| `client_setting` | 1 (0, 0, 30, 2) |

## Page 1 · Scorecard

| # | Visual | Must show |
|---|---|---|
| 4 | Orders | 98,666 |
| 5 | Order lines | 112,650 |
| 6 | On time, in full | 91.4% |
| 7 | Fill rate | 97.8% |
| 8 | Late rate | 6.6% |
| 9 | Suppliers on the watch list | 61 |
| 10 | Line chart | 18 months, Mar 2017 to Aug 2018 (the demo's `report.trend_from` and `trend_to`); highest Mar 2018 at 16.3% |
| 11 | Bar chart | the labels in the table below, Health & Beauty on top |
| 12 | Summary table | 11 rows (10 departments and All departments), week of 27 Aug 2018 |

Bar chart #11 (and the OTIF in its tooltip):

| Department | Late rate | OTIF |
|---|---|---|
| Health & Beauty | 7.3% | 90.7% |
| Home & Furniture | 7.1% | 91.3% |
| Other | 6.8% | 89.7% |
| Electronics | 6.8% | 91.0% |
| Books, Media & Stationery | 6.8% | 90.8% |
| Toys, Baby & Gifts | 6.5% | 91.3% |
| Tools, Garden & Auto | 6.5% | 91.7% |
| Sports & Fashion | 6.3% | 91.5% |
| Food, Drink & Pets | 5.1% | 93.0% |
| Kitchen & Appliances | 4.9% | 92.7% |

**Click check:** click the Health & Beauty bar in #11. Orders 12,013 · Order lines 13,128 · On time, in
full 90.7% · Fill rate 97.9% · Late rate 7.3% · Suppliers on the watch list 7 (the threshold becomes
twice Health & Beauty's own late rate). Click the bar again to clear.

## Page 2 · Suppliers

| # | Visual | Must show |
|---|---|---|
| 4 | Suppliers on the watch list | 61 |
| 5 | Their share of deliveries | 4.4% |
| 6 | Their share of late deliveries | 12.0% |
| 7 | Watch-list late rate | 13.2% |
| 8 | Table | 2,970 suppliers (those with at least one delivered line); first rows below |
| 9 | Scatter | the dashed watch-list line at 13.2%; the blue dots sit above it and right of 30 |

Table #8, sorted by late lines:

| supplier | state | Delivered Lines | Late Lines | Late Rate % | OTIF % | Late Hand-over Rate % | Share of Late Deliveries % | On Watch List |
|---|---|---|---|---|---|---|---|---|
| S0082 | MA | 402 | 78 | 19.4% | 80.0% | 31.9% | 1.1% | flag |
| S1591 | SP | 424 | 64 | 15.1% | 83.5% | 28.5% | 0.9% | flag |
| S1670 | PR | 300 | 49 | 16.3% | 83.1% | 50.3% | 0.7% | flag |
| Total | | 110,196 | 7,265 | 6.6% | 91.5% | 9.3% | 100.0% | (blank) |

The total's OTIF and hand-over rate differ from the page 1 cards (91.4%, 9.4%) on purpose: the table's
filter keeps only suppliers with a delivered line, which leaves out 206 lines from 125 suppliers that
never delivered anything.

## Page 3 · Why late

| # | Visual | Must show |
|---|---|---|
| 4 | Late deliveries | 7,265 |
| 5 | Started with a late hand-over | 29.0% |
| 6 | Hand-overs that were late | 9.4% |
| 7 | Average days late | 10.5 |
| 8 | Bar chart | Late hand-over 20.5% · On-time hand-over 5.2% |
| 9 | Column chart | the labels below, highest first |
| 10 | Line chart | 18 months; Late Hand-over Rate % highest in Mar 2017 (16.7%); Late Rate % highest in Mar 2018 (16.3%) |

Column chart #9: Other 42.9% · Food, Drink & Pets 36.3% · Kitchen & Appliances 32.7% · Home & Furniture
32.2% · Books, Media & Stationery 31.8% · Electronics 31.2% · Toys, Baby & Gifts 30.2% · Health &
Beauty 29.8% · Tools, Garden & Auto 23.6% · Sports & Fashion 20.0%.

## Page 4 · Supplier detail (drill through from S0082 on page 2)

| # | Visual | Must show |
|---|---|---|
| 2 | Multi-row card | S0082, state MA |
| 3 | Delivered lines | 402 |
| 4 | Late rate | 19.4% |
| 5 | On time, in full | 80.0% |
| 6 | Hand-overs that were late | 31.9% |
| 8 | Table | 405 rows (402 delivered, 3 not); 78 with Delivery = "Late" |

## Row-level security (Modeling → View as → `buyer.electronics@example.com`, role Buyer)

| Page | Visual | Must show |
|---|---|---|
| 1 | Department slicer and bar chart | Electronics only |
| 1 | Orders · Order lines | 15,383 · 17,271 |
| 1 | On time, in full · Fill rate · Late rate | 91.0% · 97.7% · 6.8% |
| 1 | Suppliers on the watch list | 7 |
| 1 | Summary table | one row, Electronics |
| 2 | Watch-list late rate | 13.6% |

Choosing Electronics in the Department slicer (without View as) shows the same numbers, except that the
summary table keeps all 11 rows: the slicer does not reach that table, only security does.

## Run the SQL side yourself

```bash
docker compose exec -T postgres psql -U scorecard -d scorecard < sql/check_numbers.sql
```
