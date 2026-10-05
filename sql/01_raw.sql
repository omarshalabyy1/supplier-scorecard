-- Raw layer: the columns the scorecard needs from each input file, loaded as they are.
-- Primary keys stop a duplicated row; the foreign key stops a product category missing from categories.csv.

DROP SCHEMA IF EXISTS raw CASCADE;
CREATE SCHEMA raw;

CREATE TABLE raw.orders (
    order_id                      text PRIMARY KEY,
    order_status                  text,
    order_purchase_timestamp      timestamp,
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
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE raw.categories (
    product_category_name text PRIMARY KEY,
    category              text NOT NULL,
    department            text NOT NULL
);

CREATE TABLE raw.products (
    product_id            text PRIMARY KEY,
    product_category_name text REFERENCES raw.categories   -- empty is allowed: the product goes to "Other"
);

CREATE TABLE raw.sellers (
    seller_id    text PRIMARY KEY,
    seller_city  text,
    seller_state text
);

CREATE TABLE raw.buyers (
    buyer_email text PRIMARY KEY,
    department  text NOT NULL
);
