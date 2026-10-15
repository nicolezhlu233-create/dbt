-- raw order rows = clean orders + rejected duplicates ; raw line item rows = clean line item rows
with c as (
    select
        (select count(*) from {{ source('raw', 'orders_raw') }})      as raw_orders,
        (select count(*) from {{ ref('orders_clean') }})                    as clean_orders,
        (select count(*) from {{ ref('orders_rejected') }})           as rejected_orders,
        (select count(*) from {{ source('raw', 'line_items_raw') }})  as raw_items,
        (select count(*) from {{ ref('line_items_clean') }})                as clean_items
)
select * from c
where raw_orders <> clean_orders + rejected_orders
   or raw_items  <> clean_items
