-- Each row is one rule and the number of rows that break it. load.py stops if any number is above 0.
-- (A product category missing from categories.csv is already stopped by the foreign key in 01_raw.sql.)

SELECT 'every order line reached the fact table' AS rule,
       (SELECT COUNT(*) FROM raw.order_items) - (SELECT COUNT(*) FROM star.fact_order_line) AS bad_rows
UNION ALL
SELECT 'every department has a buyer',
       COUNT(*)
FROM (SELECT DISTINCT department FROM star.dim_product) d
LEFT JOIN star.buyer b USING (department)
WHERE b.buyer_email IS NULL
UNION ALL
SELECT 'every promised date is in dim_date',
       COUNT(*)
FROM star.fact_order_line f
LEFT JOIN star.dim_date d ON d.date = f.due_date
WHERE d.date IS NULL
UNION ALL
SELECT 'no delivery before the purchase',
       COUNT(*)
FROM star.fact_order_line
WHERE delivered_date < purchase_date;
