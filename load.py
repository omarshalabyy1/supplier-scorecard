"""Check the client's input files, load them into PostgreSQL and build the supplier scorecard's star schema.

Run it after `docker compose up -d`. It rebuilds everything from data/input/ in one transaction:
if a check fails, nothing changes and the report keeps the last good load.
"""
from pathlib import Path

import pandas as pd
import psycopg

from config import load_config

HERE = Path(__file__).parent

TABLES = {  # raw table: (its file in client.yaml inputs, the columns it needs); categories before products
    "raw.orders": ("orders", ["order_id", "order_status", "order_purchase_timestamp", "order_delivered_carrier_date",
                              "order_delivered_customer_date", "order_estimated_delivery_date"]),
    "raw.order_items": ("order_items", ["order_id", "order_item_id", "product_id", "seller_id", "shipping_limit_date"]),
    "raw.categories": ("categories", ["product_category_name", "category", "department"]),
    "raw.products": ("products", ["product_id", "product_category_name"]),
    "raw.sellers": ("sellers", ["seller_id", "seller_city", "seller_state"]),
    "raw.buyers": ("buyers", ["buyer_email", "department"]),
}


def sql(name):
    return (HERE / "sql" / name).read_text(encoding="utf-8")


cfg = load_config()

# The input check: every file is there and has its columns, before anything in the database changes.
frames = {}
for table, (key, columns) in TABLES.items():
    path = cfg["input_dir"] / cfg["inputs"][key]
    if not path.exists():
        raise SystemExit(f"missing input file data/input/{path.name} (inputs.{key} in config/client.yaml)")
    missing = [c for c in columns if c not in pd.read_csv(path, nrows=0, encoding="utf-8-sig").columns]
    if missing:
        raise SystemExit(f"data/input/{path.name} is missing column(s): {', '.join(missing)}")
    frames[table] = pd.read_csv(path, usecols=columns, dtype=str, encoding="utf-8-sig")[columns]

with psycopg.connect(cfg["db_url"]) as conn:
    conn.execute(sql("01_raw.sql"))
    for table, df in frames.items():
        try:
            with conn.cursor().copy(f"COPY {table} ({', '.join(df.columns)}) FROM STDIN WITH (FORMAT csv)") as copy:
                copy.write(df.to_csv(index=False, header=False))
        except psycopg.errors.IntegrityError as e:
            raise SystemExit(f"data/input/{cfg['inputs'][TABLES[table][0]]}: {e.diag.message_detail}")
        print(f"{table:26} {len(df):>8,} rows")

    for key, value in cfg["rules"].items():
        conn.execute("SELECT set_config(%s, %s, false)", [f"client.{key}", str(value)])
    conn.execute(sql("02_star.sql"))
    for table in ["dim_supplier", "dim_product", "dim_date", "fact_order_line", "buyer"]:
        print(f"star.{table:21} {conn.execute(f'SELECT COUNT(*) FROM star.{table}').fetchone()[0]:>8,} rows")

    failed = [(rule, bad) for rule, bad in conn.execute(sql("03_checks.sql")) if bad]
    for rule, bad in failed:
        print(f"CHECK FAILED: {rule} ({bad:,} rows)")
    if failed:
        raise SystemExit("Load rolled back: the warehouse still holds the last good load.")
    print("All checks passed.")
