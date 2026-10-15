{# Types and trims the raw orders. No business rules here - only casting.
   try_* functions return NULL instead of failing on a bad value. #}
with src as (
    select
        *,
        -- fingerprint of the untouched row (computed BEFORE any renaming), used to tell exact duplicates
        -- from conflicting ones
        hash(merchant_id, order_id, shop_id, address_to_country, address_to_region, order_dt,
             fulfilled_dt, sales_channel_type_id, total_cost, total_shipping, merchant_registered_dt,
             sub_is_active_flag, sub_plan, shipment_carrier, shipment_delivered_at) as raw_hash
    from {{ source('raw', 'orders_raw') }}
)

select
    -- the uploaded table has no row number, so build a stable one (only used to break ties between duplicates)
    row_number() over (order by raw_hash)                                as row_id,
    try_to_number({{ clean_text('merchant_id') }})                       as merchant_id,
    {{ trim_ws('order_id') }}                                            as order_id,        -- text on purpose
    try_to_number({{ clean_text('shop_id') }})                           as shop_id,
    nullif(upper({{ trim_ws('address_to_country') }}), '')               as country_raw,
    nullif(upper({{ trim_ws('address_to_region') }}), '')                as region_raw,
    try_to_timestamp_ntz({{ clean_text('order_dt') }})                    as order_dt,
    try_to_timestamp_ntz({{ clean_text('fulfilled_dt') }})                    as fulfilled_raw,
    try_to_number({{ clean_text('sales_channel_type_id') }})             as sales_channel_type_id,
    try_to_decimal({{ clean_text('total_cost') }}, 12, 2)                as total_cost,
    try_to_decimal({{ clean_text('total_shipping') }}, 12, 2)            as total_shipping,
    try_to_timestamp_ntz({{ clean_text('merchant_registered_dt') }})                    as merchant_registered_dt,
    (lower({{ trim_ws('sub_is_active_flag') }}) = 'true')                as sub_is_active,
    {{ clean_text('sub_plan') }}                                         as sub_plan,
    {{ clean_text('shipment_carrier') }}                                 as carrier_raw,
    try_to_timestamp_ntz({{ clean_text('shipment_delivered_at') }})                    as delivered_raw,
    raw_hash
from src
