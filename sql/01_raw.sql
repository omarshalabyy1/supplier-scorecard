-- Raw layer: each source file loaded as it is, one table per file.
-- The primary keys stop a duplicated row at load time.

DROP SCHEMA IF EXISTS raw CASCADE;
CREATE SCHEMA raw;

CREATE TABLE raw.orders (
    order_id                      text PRIMARY KEY,
    customer_id                   text,
    order_status                  text,
    order_purchase_timestamp      timestamp,
    order_approved_at             timestamp,
    order_delivered_carrier_date  timestamp,
    order_delivered_customer_date timestamp,
    order_estimated_delivery_date timestamp
);

CREATE TABLE raw.order_items (
    order_id            text,
    order_item_id       int,
    product_id          text,
    seller_id           text,
    shipping_limit_date timestamp,
    price               numeric(10, 2),
    freight_value       numeric(10, 2),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE raw.products (
    product_id                 text PRIMARY KEY,
    product_category_name      text,
    product_name_lenght        int,
    product_description_lenght int,
    product_photos_qty         int,
    product_weight_g           int,
    product_length_cm          int,
    product_height_cm          int,
    product_width_cm           int
);

CREATE TABLE raw.sellers (
    seller_id              text PRIMARY KEY,
    seller_zip_code_prefix text,
    seller_city            text,
    seller_state           text
);

CREATE TABLE raw.category_translation (
    product_category_name         text PRIMARY KEY,
    product_category_name_english text
);

-- Our own files: which department each category belongs to, and which buyer owns each department.
CREATE TABLE raw.departments (
    product_category_name text PRIMARY KEY,
    department            text NOT NULL
);

CREATE TABLE raw.buyers (
    buyer_email text PRIMARY KEY,
    department  text NOT NULL
);
