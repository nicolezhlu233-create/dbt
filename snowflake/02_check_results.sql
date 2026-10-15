/* Run AFTER the dbt build finishes. All results are in INTERVIEW.CLEAN. */
USE DATABASE INTERVIEW;
USE SCHEMA CLEAN;

SHOW TABLES IN SCHEMA INTERVIEW.CLEAN;     -- you should see ORDERS_CLEAN, LINE_ITEMS_CLEAN, ORDERS_REJECTED ...

SELECT 'orders_clean'     AS tbl, COUNT(*) AS n, 310905 AS expected FROM orders_clean
UNION ALL SELECT 'line_items_clean', COUNT(*), 411581 FROM line_items_clean
UNION ALL SELECT 'orders_rejected',  COUNT(*), 740    FROM orders_rejected;
