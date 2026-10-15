-- order_id must look like <shop_id>.<digits> and start with its own shop_id
select order_id, shop_id
from {{ ref('orders_clean') }}
where not regexp_like(order_id, '[0-9]+\\.[0-9]+')
   or try_to_number(split_part(order_id, '.', 1)) is distinct from shop_id
