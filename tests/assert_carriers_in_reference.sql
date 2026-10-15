-- A failure here means a NEW carrier name appeared: add it to seeds/ref_carrier.csv.
select o.order_id, o.shipment_carrier
from {{ ref('orders_clean') }} o
left join {{ ref('ref_carrier') }} c on c.carrier = o.shipment_carrier
where o.shipment_carrier is not null and c.carrier is null
