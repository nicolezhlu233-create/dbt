select o.order_id, o.address_to_country, o.address_to_region
from {{ ref('orders_clean') }} o
left join {{ ref('ref_region_code') }} r
    on r.country = o.address_to_country and r.code = o.address_to_region
where o.address_to_country in ('US', 'CA')
  and o.address_to_region is not null
  and r.code is null
