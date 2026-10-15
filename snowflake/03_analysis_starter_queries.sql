/* STARTER QUERIES - copy into a normal Snowflake worksheet. Always analyse the *_clean tables, never the raw ones. */
USE DATABASE INTERVIEW;
USE SCHEMA CLEAN;

-- 1. What was fixed or flagged, and how many rows each (every order has a dq_flags note)
SELECT f.value::STRING AS issue, COUNT(*) AS orders
FROM orders_clean, LATERAL FLATTEN(input => SPLIT(dq_flags, ';')) f
WHERE dq_flags IS NOT NULL
GROUP BY 1 ORDER BY 2 DESC;

-- 2. Orders per month. Zero-value orders look like cancelled orders, so they are excluded here.
SELECT DATE_TRUNC('month', order_dt) AS month,
       COUNT(*)                      AS orders,
       ROUND(SUM(total_cost), 2)     AS total_cost,
       ROUND(SUM(total_shipping), 2) AS total_shipping
FROM orders_clean
WHERE NOT is_zero_value_order
GROUP BY 1 ORDER BY 1;

-- 3. Top 10 destination countries
SELECT address_to_country, COUNT(*) AS orders
FROM orders_clean
WHERE NOT is_zero_value_order
GROUP BY 1 ORDER BY 2 DESC LIMIT 10;

-- 4. Most popular product types (line items joined to orders; safe because orders_clean has one row per order)
SELECT li.product_type, COUNT(*) AS line_items, SUM(li.quantity) AS units
FROM line_items_clean li
JOIN orders_clean o ON o.order_id = li.order_id
WHERE NOT o.is_zero_value_order
GROUP BY 1 ORDER BY units DESC;

-- 5. How fast each carrier is. Only orders with valid dates are used (see the fulfilled/delivered flags).
SELECT shipment_carrier,
       COUNT(*) AS orders,
       ROUND(AVG(DATEDIFF('hour', order_dt, fulfilled_dt)) / 24, 1)            AS avg_days_to_fulfil,
       ROUND(AVG(DATEDIFF('hour', fulfilled_dt, shipment_delivered_at)) / 24, 1) AS avg_days_to_deliver
FROM orders_clean
WHERE fulfilled_dt IS NOT NULL AND shipment_delivered_at IS NOT NULL
GROUP BY 1 HAVING COUNT(*) >= 100
ORDER BY orders DESC;

-- 6. Reprint rate by print provider (higher = more problems?)
SELECT print_provider_id,
       COUNT(*)                                   AS line_items,
       ROUND(100 * AVG(IFF(is_reprint, 1, 0)), 2) AS reprint_pct
FROM line_items_clean
GROUP BY 1 HAVING COUNT(*) >= 500
ORDER BY reprint_pct DESC;
