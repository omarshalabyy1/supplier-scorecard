-- The scorecard's headline numbers, computed in SQL on the star schema.
-- powerbi/06-checks.md lists the same numbers from the notebook; the report must match both.

WITH line AS (
    SELECT f.*,
           p.department,
           delivered_date IS NOT NULL                                        AS delivered,
           delivered_date IS NOT NULL AND delivered_date <= due_date         AS on_time,
           delivered_date > due_date                                         AS late,
           handed_over IS NOT NULL                                           AS handed,
           handed_over > handover_due                                        AS late_handover
    FROM star.fact_order_line f
    JOIN star.dim_product p USING (product_key)
)
SELECT COALESCE(department, 'All departments')                                       AS department,
       COUNT(DISTINCT order_id)                                                      AS orders,
       COUNT(*)                                                                      AS order_lines,
       COUNT(*) FILTER (WHERE delivered)                                             AS delivered_lines,
       COUNT(*) FILTER (WHERE late)                                                  AS late_lines,
       ROUND(100.0 * COUNT(*) FILTER (WHERE late) / COUNT(*) FILTER (WHERE delivered), 2) AS late_rate_pct,
       ROUND(100.0 * COUNT(*) FILTER (WHERE delivered) / COUNT(*), 2)                AS fill_rate_pct,
       ROUND(100.0 * COUNT(*) FILTER (WHERE on_time) / COUNT(*), 2)                  AS otif_pct,
       ROUND(AVG(delivered_date - due_date) FILTER (WHERE late), 2)                  AS avg_days_late,
       COUNT(*) FILTER (WHERE late_handover)                                         AS late_handover_lines,
       ROUND(100.0 * COUNT(*) FILTER (WHERE late_handover) / COUNT(*) FILTER (WHERE handed), 2) AS late_handover_rate_pct,
       ROUND(100.0 * COUNT(*) FILTER (WHERE late AND late_handover) / COUNT(*) FILTER (WHERE late), 2) AS late_after_late_handover_pct
FROM line
GROUP BY ROLLUP (department)
ORDER BY department NULLS FIRST;

-- Watch list: suppliers with at least 30 delivered lines and a late rate at least twice the overall rate.
WITH supplier AS (
    SELECT supplier_key,
           COUNT(*) FILTER (WHERE delivered_date IS NOT NULL) AS delivered_lines,
           COUNT(*) FILTER (WHERE delivered_date > due_date)  AS late_lines
    FROM star.fact_order_line
    GROUP BY supplier_key
),
overall AS (
    SELECT SUM(late_lines)::numeric / SUM(delivered_lines) AS late_rate FROM supplier
)
SELECT COUNT(*)                                                                         AS watch_list_suppliers,
       ROUND(100.0 * SUM(late_lines) / (SELECT SUM(late_lines) FROM supplier), 2)       AS share_of_late_pct,
       ROUND(100.0 * SUM(delivered_lines) / (SELECT SUM(delivered_lines) FROM supplier), 2) AS share_of_delivered_pct
FROM supplier, overall
WHERE delivered_lines >= 30
  AND late_lines::numeric / delivered_lines >= 2 * overall.late_rate;
