-- The scorecard's headline numbers, computed in SQL on the star schema with the client's rule values
-- (star.client_setting). powerbi/06-checks.md lists the demo's numbers; the report must match both.

WITH line AS (
    SELECT f.*,
           p.department,
           delivered_date IS NOT NULL                                                          AS delivered,
           delivered_date IS NOT NULL AND delivered_date <= due_date + c.on_time_grace_days    AS on_time,
           delivered_date > due_date + c.on_time_grace_days                                    AS late,
           handed_over IS NOT NULL                                                             AS handed,
           handed_over > handover_due + make_interval(hours => c.handover_grace_hours)         AS late_handover
    FROM star.fact_order_line f
    JOIN star.dim_product p USING (product_key)
    CROSS JOIN star.client_setting c
)
SELECT COALESCE(department, 'All departments')                                       AS department,
       COUNT(DISTINCT order_id)                                                      AS orders,
       COUNT(*)                                                                      AS order_lines,
       COUNT(*) FILTER (WHERE delivered)                                             AS delivered_lines,
       COUNT(*) FILTER (WHERE late)                                                  AS late_lines,
       ROUND(100.0 * COUNT(*) FILTER (WHERE late) / NULLIF(COUNT(*) FILTER (WHERE delivered), 0), 2) AS late_rate_pct,
       ROUND(100.0 * COUNT(*) FILTER (WHERE delivered) / COUNT(*), 2)                AS fill_rate_pct,
       ROUND(100.0 * COUNT(*) FILTER (WHERE on_time) / COUNT(*), 2)                  AS otif_pct,
       ROUND(AVG(delivered_date - due_date) FILTER (WHERE late), 2)                  AS avg_days_late,
       COUNT(*) FILTER (WHERE late_handover)                                         AS late_handover_lines,
       ROUND(100.0 * COUNT(*) FILTER (WHERE late_handover) / NULLIF(COUNT(*) FILTER (WHERE handed), 0), 2) AS late_handover_rate_pct,
       ROUND(100.0 * COUNT(*) FILTER (WHERE late AND late_handover) / NULLIF(COUNT(*) FILTER (WHERE late), 0), 2) AS late_after_late_handover_pct
FROM line
GROUP BY ROLLUP (department)
ORDER BY department NULLS FIRST;

-- Watch list: suppliers with at least watch_list_min_lines delivered lines and a late rate at least
-- watch_list_times_overall times the rate of all suppliers.
WITH supplier AS (
    SELECT supplier_key,
           COUNT(*) FILTER (WHERE delivered_date IS NOT NULL)                   AS delivered_lines,
           COUNT(*) FILTER (WHERE delivered_date > due_date + c.on_time_grace_days) AS late_lines
    FROM star.fact_order_line
    CROSS JOIN star.client_setting c
    GROUP BY supplier_key
),
overall AS (
    SELECT SUM(late_lines)::numeric / SUM(delivered_lines) AS late_rate FROM supplier
)
SELECT COUNT(*)                                                                             AS watch_list_suppliers,
       ROUND(100.0 * SUM(late_lines) / (SELECT SUM(late_lines) FROM supplier), 2)           AS share_of_late_pct,
       ROUND(100.0 * SUM(delivered_lines) / (SELECT SUM(delivered_lines) FROM supplier), 2) AS share_of_delivered_pct
FROM supplier, overall, star.client_setting c
WHERE delivered_lines >= c.watch_list_min_lines
  AND late_lines::numeric / delivered_lines >= c.watch_list_times_overall * overall.late_rate;
