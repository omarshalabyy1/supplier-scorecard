"""Load the source files into PostgreSQL and build the supplier scorecard's star schema.

Run it after `docker compose up -d`. It rebuilds everything from the files in data/,
in one transaction: if a check fails, nothing changes and the report keeps the last good load.
"""
from pathlib import Path

import psycopg

DB = "postgresql://scorecard:scorecard@localhost:5435/scorecard"
HERE = Path(__file__).parent

FILES = {  # raw table: source file
    "raw.orders": "data/raw/olist_orders_dataset.csv",
    "raw.order_items": "data/raw/olist_order_items_dataset.csv",
    "raw.products": "data/raw/olist_products_dataset.csv",
    "raw.sellers": "data/raw/olist_sellers_dataset.csv",
    "raw.category_translation": "data/raw/product_category_name_translation.csv",
    "raw.departments": "data/departments.csv",
    "raw.buyers": "data/buyers.csv",
}


def sql(name):
    return (HERE / "sql" / name).read_text()


with psycopg.connect(DB) as conn:
    conn.execute(sql("01_raw.sql"))
    for table, path in FILES.items():
        with conn.cursor().copy(f"COPY {table} FROM STDIN WITH (FORMAT csv, HEADER true)") as copy:
            copy.write((HERE / path).read_bytes())
        print(f"{table:26} {conn.execute(f'SELECT COUNT(*) FROM {table}').fetchone()[0]:>8,} rows")

    conn.execute(sql("02_star.sql"))
    for table in ["dim_supplier", "dim_product", "dim_date", "fact_order_line", "buyer"]:
        print(f"star.{table:21} {conn.execute(f'SELECT COUNT(*) FROM star.{table}').fetchone()[0]:>8,} rows")

    failed = [(rule, bad) for rule, bad in conn.execute(sql("03_checks.sql")) if bad]
    for rule, bad in failed:
        print(f"CHECK FAILED: {rule} ({bad:,} rows)")
    if failed:
        raise SystemExit("Load rolled back: the warehouse still holds the last good load.")
    print("All checks passed.")
