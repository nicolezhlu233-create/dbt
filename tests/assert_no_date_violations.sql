-- Returns offending rows (test passes when 0 rows). Date-only fulfilled values (midnight) may precede the order's time.
select order_id
from {{ ref('orders_clean') }}
where (fulfilled_dt < order_dt and fulfilled_dt <> date_trunc('day', fulfilled_dt))
   or shipment_delivered_at < fulfilled_dt
   or shipment_delivered_at < order_dt
   or fulfilled_dt          > to_timestamp_ntz('{{ var("data_cutoff") }}')
   or shipment_delivered_at > to_timestamp_ntz('{{ var("data_cutoff") }}')
