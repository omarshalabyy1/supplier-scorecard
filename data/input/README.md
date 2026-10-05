# Input files

The six files a client supplies, as CSV with a header row, UTF-8. The file names are set in
`config/client.yaml` under `inputs`. Extra columns are ignored. `python load.py` stops with a one-line
message if a file is missing, a required column is not there, a key is duplicated, or a product's
category is missing from the categories file.

## orders (`inputs.orders`)

One row per order.

| Column | Type | Example |
|---|---|---|
| order_id | text, unique | 001d8f0e34a38c37f7dba2a37d4eba8b |
| order_status | text | delivered |
| order_purchase_timestamp | timestamp | 2017-05-14 17:19:44 |
| order_delivered_carrier_date | timestamp, empty if the carrier never got it | 2017-05-24 15:45:01 |
| order_delivered_customer_date | timestamp, empty if never delivered (the line is then not in full) | 2017-05-26 13:14:50 |
| order_estimated_delivery_date | date, the date promised to the customer | 2017-05-24 00:00:00 |

## order_items (`inputs.order_items`)

One row per order line: one item of one order, from one supplier.

| Column | Type | Example |
|---|---|---|
| order_id | text, in orders | 001d8f0e34a38c37f7dba2a37d4eba8b |
| order_item_id | whole number, 1, 2 ... within the order | 1 |
| product_id | text, in products | e67307ff0f15ade43fcb6e670be7a74c |
| seller_id | text, in sellers | f4aba7c0bca51484c30ab7bdc34bcdd1 |
| shipping_limit_date | timestamp, the supplier's deadline to hand the item to the carrier | 2017-05-18 17:35:11 |

## products (`inputs.products`)

| Column | Type | Example |
|---|---|---|
| product_id | text, unique | e67307ff0f15ade43fcb6e670be7a74c |
| product_category_name | text, in categories; empty puts the product in department "Other" | beleza_saude |

## sellers (`inputs.sellers`)

The suppliers.

| Column | Type | Example |
|---|---|---|
| seller_id | text, unique | f4aba7c0bca51484c30ab7bdc34bcdd1 |
| seller_city | text | sao paulo |
| seller_state | text | SP |

## categories (`inputs.categories`)

Every `product_category_name` that appears in products, with the name the report shows and the
department that buys it.

| Column | Type | Example |
|---|---|---|
| product_category_name | text, unique (any shape of code) | beleza_saude |
| category | text | health_beauty |
| department | text | Health & Beauty |

## buyers (`inputs.buyers`)

One row per buyer: the sign-in they use for Power BI and the department they own. Every department
in categories (and "Other", if any product has no category) needs a buyer; `load.py` checks it.

| Column | Type | Example |
|---|---|---|
| buyer_email | text, unique | buyer.beauty@example.com |
| department | text, as in categories | Health & Beauty |

## The demo files

`categories.csv` and `buyers.csv` are committed. The four order files are Olist's and are not
committed: download them into this folder (about 35 MB), from the folder in the main README's Data
section:

```bash
curl -L -o data/input/olist_orders_dataset.csv https://raw.githubusercontent.com/olist/work-at-olist-data/master/datasets/olist_orders_dataset.csv
```
```bash
curl -L -o data/input/olist_order_items_dataset.csv https://raw.githubusercontent.com/olist/work-at-olist-data/master/datasets/olist_order_items_dataset.csv
```
```bash
curl -L -o data/input/olist_products_dataset.csv https://raw.githubusercontent.com/olist/work-at-olist-data/master/datasets/olist_products_dataset.csv
```
```bash
curl -L -o data/input/olist_sellers_dataset.csv https://raw.githubusercontent.com/olist/work-at-olist-data/master/datasets/olist_sellers_dataset.csv
```

The category codes and English names in `categories.csv` derive from the
[Olist dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (CC BY-NC-SA 4.0); the
departments are this project's own. The buyer addresses in `buyers.csv` are made up (example.com). A
client's private copy replaces both with their own.
