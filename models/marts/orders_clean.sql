{# Final clean orders: one row per ORDER_ID. dq_flags lists everything that was changed or looks unusual. #}
select
    r.order_id,
    r.merchant_id,
    r.shop_id,
    r.country_clean                    as address_to_country,
    r.region_clean                     as address_to_region,
    r.order_dt,
    r.fulfilled_dt,
    r.sales_channel_type_id,
    r.total_cost,
    r.total_shipping,
    r.merchant_registered_dt,
    r.sub_is_active,
    r.sub_plan,
    r.carrier_clean                    as shipment_carrier,
    r.delivered_at                     as shipment_delivered_at,
    -- 97% of these are never fulfilled => most likely cancelled orders. Exclude from revenue / fulfilment KPIs.
    coalesce(r.total_cost = 0 and r.total_shipping = 0, false) as is_zero_value_order,

    nullif(array_to_string(array_construct_compact(
        iff(r.copies > 1,                                         'duplicate_key_collapsed', null),
        iff(r.f_shifted,                                          'fulfilled_shifted_nulled', null),
        iff(r.f_before_order,                                     'fulfilled_before_order_nulled', null),
        iff(r.f_future,                                           'fulfilled_in_future_nulled', null),
        iff(r.f_date_only and r.fulfilled_dt is not null,         'fulfilled_date_only', null),
        case when r.d_before_order     then 'delivered_before_order_nulled'
             when r.d_before_fulfilled then 'delivered_before_fulfilled_nulled'
             when r.d_future           then 'delivered_in_future_nulled' end,
        iff(r.delivered_at is not null and r.fulfilled_raw is null, 'delivered_without_fulfilled', null),
        iff(datediff('second', r.order_dt, r.fulfilled_dt) > 90 * 86400, 'slow_fulfilment_gt90d', null),
        case when r.country_raw is null and r.country_clean is null then 'country_missing'
             when r.country_was_inferred                            then 'country_inferred' end,
        case when r.region_raw is not null and r.region_clean is null then 'region_unrecognised_nulled'
             when r.region_clean is distinct from r.region_raw        then 'region_normalised' end,
        case when lower(r.carrier_raw) = 'unknown'                                         then 'carrier_unknown_nulled'
             when r.carrier_raw is not null and r.carrier_clean is distinct from r.carrier_raw then 'carrier_suffix_stripped' end,
        iff(r.total_cost = 0 and r.total_shipping = 0,            'zero_value_order', null),
        iff(r.total_cost >= 1000,                                 'high_value_ge_1000', null),
        iff(li.order_id is null,                                  'no_line_items', null)
    ), ';'), '') as dq_flags

from {{ ref('int_orders_cleaned') }} r
left join (select distinct order_id from {{ ref('stg_line_items') }}) li
    on li.order_id = r.order_id
where r.rn = 1
