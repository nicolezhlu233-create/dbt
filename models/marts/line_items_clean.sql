{# Line items are NOT de-duplicated: the file has no line id, and identical rows inside one order are normal
   (3 identical T-shirts = 3 rows). line_no makes each row uniquely addressable. #}
select
    order_id,
    (row_number() over (partition by order_id order by row_id))::int as line_no,
    print_provider_id,
    product_brand,
    product_type,
    quantity,
    is_reprint,
    nullif(array_to_string(array_construct_compact(
        iff(print_provider_id is null, 'missing_print_provider', null),
        iff(quantity >= 50,            'bulk_quantity_ge_50', null),
        iff(product_brand = 'Generic brand'
            and product_type in ('T-Shirt', 'Hoodie', 'Sweatshirt', 'Kids clothes'),
                                       'generic_brand_on_apparel', null)
    ), ';'), '') as dq_flags
from {{ ref('stg_line_items') }}
