select order_id, address_to_country
from {{ ref('orders_clean') }}
where address_to_country is not null
  and not regexp_like(address_to_country, '[A-Z]{2}')
