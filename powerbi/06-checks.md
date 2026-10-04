# 06 · Checks: the numbers the report must show

Every number below comes from `analysis/analysis.ipynb` (computed from the source files with pandas) and
was matched by `sql/check_numbers.sql` (computed on the warehouse). If a card shows anything else, the
build has a mistake: check the relationship, the calculated column or the measure behind it.

All checks are with **no slicer selected** and **not viewing as a role**, unless the row says otherwise.
Power BI shows percentages to one decimal place.

## Page 1 · Scorecard

| Visual | Must show |
|---|---|
| Orders | 98,666 |
| Order lines | 112,650 |
| On time, in full (`OTIF %`) | 91.4% |
| Fill rate | 97.8% |
| Late rate | 6.6% |
| Suppliers on the watch list | 61 |
| Bar chart, highest bar | Health & Beauty 7.3% |
| Bar chart, lowest bar | Kitchen & Appliances 4.9% |
| Line chart, highest month | Mar 2018, 16.3% |
| Summary table | 11 rows for the week of 27 Aug 2018 (10 departments and All departments) |

Late rate by department (bar chart labels):

| Department | Delivered lines | Late lines | Late rate | OTIF |
|---|---|---|---|---|
| Health & Beauty | 12,846 | 934 | 7.3% | 90.7% |
| Home & Furniture | 22,149 | 1,580 | 7.1% | 91.3% |
| Other | 1,842 | 126 | 6.8% | 89.7% |
| Electronics | 16,868 | 1,146 | 6.8% | 91.0% |
| Books, Media & Stationery | 4,086 | 277 | 6.8% | 90.8% |
| Toys, Baby & Gifts | 11,176 | 731 | 6.5% | 91.3% |
| Tools, Garden & Auto | 11,407 | 742 | 6.5% | 91.7% |
| Sports & Fashion | 17,941 | 1,138 | 6.3% | 91.5% |
| Food, Drink & Pets | 3,053 | 157 | 5.1% | 93.0% |
| Kitchen & Appliances | 8,828 | 434 | 4.9% | 92.7% |

## Page 2 · Suppliers

| Visual | Must show |
|---|---|
| Suppliers on the watch list | 61 |
| Their share of deliveries | 4.4% |
| Their share of late deliveries | 12.0% |
| Watch-list late rate | 13.2% |
| Table, first rows (sorted by late lines) | S0082: 402 delivered, 78 late, 19.4%, watch list · S1591: 424, 64, 15.1%, watch list · S1670: 300, 49, 16.3%, watch list |
| Table, total row | 110,196 delivered lines, 7,265 late lines |

## Page 3 · Why late

| Visual | Must show |
|---|---|
| Late deliveries | 7,265 |
| Started with a late hand-over | 29.0% |
| Hand-overs that were late | 9.4% |
| Average days late | 10.5 |
| Bar chart | Late hand-over 20.5%, On-time hand-over 5.2% |
| Column chart, highest | Other 42.9%, then Food, Drink & Pets 36.3% |
| Column chart, lowest | Sports & Fashion 20.0% |

## Page 4 · Supplier detail (drill through from S0082)

| Visual | Must show |
|---|---|
| Delivered lines | 402 |
| Late rate | 19.4% |
| Table | 78 rows with Delivery = "Late" |

## Row-level security (Modeling → View as → `buyer.electronics@example.com`, role Buyer)

| Visual | Must show |
|---|---|
| Department slicer and bar chart | Electronics only |
| Order lines | 17,271 |
| Late rate | 6.8% |
| On time, in full | 91.0% |
| Summary table | one row, Electronics |

## Run the SQL side yourself

```bash
docker compose exec -T postgres psql -U scorecard -d scorecard < sql/check_numbers.sql
```
