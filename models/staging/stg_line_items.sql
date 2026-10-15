select
    -- the uploaded table has no row number; build a stable one. Identical rows are interchangeable anyway.
    row_number() over (order by order_id, print_provider_id, product_brand, product_type, quantity, reprint_flag) as row_id,
    {{ trim_ws('order_id') }}                                   as order_id,   -- text on purpose
    try_to_number({{ clean_text('print_provider_id') }})        as print_provider_id,
    {{ clean_text('product_brand') }}                           as product_brand,
    {{ clean_text('product_type') }}                            as product_type,
    try_to_number({{ clean_text('quantity') }})                 as quantity,
    -- source only ever contains 'true' or blank, so blank means FALSE
    (lower(coalesce({{ trim_ws('reprint_flag') }}, '')) = 'true') as is_reprint
from {{ source('raw', 'line_items_raw') }}
