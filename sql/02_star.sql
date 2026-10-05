-- Star schema for the supplier scorecard.
-- Grain of the fact: one order line (one item of one order, sold by one supplier).
-- The tables keep only facts and dates; the scorecard rules (on time, in full, late) are DAX measures,
-- and the thresholds they use are in star.client_setting, written from config/client.yaml.

DROP SCHEMA IF EXISTS star CASCADE;
CREATE SCHEMA star;

-- The client's rule values (rules in config/client.yaml), one row. load.py passes them in as settings.
CREATE TABLE star.client_setting AS
SELECT current_setting('client.on_time_grace_days')::int          AS on_time_grace_days,
       current_setting('client.handover_grace_hours')::int        AS handover_grace_hours,
       current_setting('client.watch_list_min_lines')::int        AS watch_list_min_lines,
       current_setting('client.watch_list_times_overall')::numeric AS watch_list_times_overall;

-- One row per supplier. Sellers may have no names, so each gets a short code.
CREATE TABLE star.dim_supplier AS
SELECT ROW_NUMBER() OVER (ORDER BY seller_id)::int                         AS supplier_key,
       'S' || LPAD((ROW_NUMBER() OVER (ORDER BY seller_id))::text, 4, '0') AS supplier,
       seller_id,
       INITCAP(seller_city)                                                AS city,
       seller_state                                                        AS state
FROM raw.sellers;

-- One row per product, with its category and the department that buys it.
CREATE TABLE star.dim_product AS
SELECT ROW_NUMBER() OVER (ORDER BY p.product_id)::int AS product_key,
       p.product_id,
       COALESCE(c.category, 'unknown')               AS category,
       COALESCE(c.department, 'Other')               AS department
FROM raw.products p
LEFT JOIN raw.categories c USING (product_category_name);

-- One row per day across every promised delivery date.
CREATE TABLE star.dim_date AS
SELECT day::date                                                   AS date,
       EXTRACT(year FROM day)::int                                 AS year,
       TO_CHAR(day, 'Mon YYYY')                                    AS month,
       (EXTRACT(year FROM day) * 100 + EXTRACT(month FROM day))::int AS month_sort,
       DATE_TRUNC('week', day)::date                               AS week_start
FROM GENERATE_SERIES(
         (SELECT MIN(order_estimated_delivery_date) FROM raw.orders),
         (SELECT MAX(order_estimated_delivery_date) FROM raw.orders),
         INTERVAL '1 day') AS day;

-- One row per order line, with the supplier's promise and the customer's promise side by side.
CREATE TABLE star.fact_order_line AS
SELECT i.order_id,
       i.order_item_id,
       s.supplier_key,
       p.product_key,
       o.order_status,
       o.order_purchase_timestamp::date        AS purchase_date,
       i.shipping_limit_date                   AS handover_due,    -- the supplier promised to hand it to the carrier by
       o.order_delivered_carrier_date          AS handed_over,     -- when the carrier got it
       o.order_estimated_delivery_date::date   AS due_date,        -- the date promised to the customer
       o.order_delivered_customer_date::date   AS delivered_date   -- when the customer got it (empty if never)
FROM raw.order_items i
JOIN raw.orders o        USING (order_id)
JOIN star.dim_supplier s USING (seller_id)
JOIN star.dim_product p  USING (product_id);

-- Row-level security: which buyer sees which department.
CREATE TABLE star.buyer AS
SELECT buyer_email, department FROM raw.buyers;

-- Filled by summarize.py: one short written summary per department per week.
CREATE TABLE star.weekly_summary (
    week_start date,
    department text,
    summary    text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (week_start, department)
);
