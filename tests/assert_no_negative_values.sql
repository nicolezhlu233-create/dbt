select 'orders' as tbl, order_id as id from {{ ref('orders_clean') }} where total_cost < 0 or total_shipping < 0
union all
select 'line_items', order_id from {{ ref('line_items_clean') }} where quantity <= 0
