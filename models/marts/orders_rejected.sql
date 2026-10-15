{# Duplicate order rows that were removed, kept so nothing is silently lost. #}
select
    row_id,
    order_id,
    iff(raw_hash = kept_hash, 'exact_duplicate', 'conflicting_duplicate') as reason,
    fulfilled_raw,
    delivered_raw,
    carrier_raw,
    order_dt
from {{ ref('int_orders_cleaned') }}
where rn > 1
