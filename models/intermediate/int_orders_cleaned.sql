{# Applies every date / category rule to EVERY raw order row (including duplicates) and ranks duplicates.
   One boolean per rule, so each fix is traceable and ends up in the dq_flags column of the final table.

   Why these rules (found by profiling):
   - A genuine FULFILLED_DT never has milliseconds. ~5,200 values do, and they match ORDER_DT's
     milliseconds exactly: they are ORDER_DT shifted by whole hours -> corrupt -> NULL.
   - DELIVERED_AT earlier than the order / fulfilment is impossible (same mm:ss as FULFILLED_DT, shifted) -> NULL.
   - Anything after the extract date is in the future -> NULL.  #}

{% set cutoff = "to_timestamp_ntz('" ~ var('data_cutoff') ~ "')" %}

with b as (
    select
        t.*,
        mc.carrier_clean,
        mr.country_clean,
        mr.region_clean,
        coalesce(mr.country_was_inferred, false)                                      as country_was_inferred,
        coalesce(t.fulfilled_raw <> date_trunc('second', t.fulfilled_raw), false)     as f_shifted,
        coalesce(t.fulfilled_raw  = date_trunc('day',    t.fulfilled_raw), false)     as f_date_only
    from {{ ref('stg_orders') }} t
    left join {{ ref('int_carrier_map') }} mc
        on mc.carrier_raw = t.carrier_raw
    left join {{ ref('int_region_map') }} mr
        on mr.country_raw is not distinct from t.country_raw
       and mr.region_raw  is not distinct from t.region_raw
),

c as (
    select
        b.*,
        -- date-only values (00:00:00) are compared by day so a same-day fulfilment is not rejected
        coalesce(not f_shifted and fulfilled_raw is not null and
                 iff(f_date_only, fulfilled_raw::date < order_dt::date, fulfilled_raw < order_dt), false) as f_before_order,
        coalesce(not f_shifted and fulfilled_raw > {{ cutoff }}, false)                                  as f_future
    from b
),

d as (
    select
        c.*,
        iff(fulfilled_raw is not null and not (f_shifted or f_before_order or f_future),
            fulfilled_raw, null) as fulfilled_dt
    from c
),

e as (
    select
        d.*,
        coalesce(delivered_raw > {{ cutoff }}, false)                                as d_future,
        coalesce(delivered_raw < order_dt, false)                                    as d_before_order,
        coalesce(fulfilled_dt is not null and delivered_raw < fulfilled_dt, false)   as d_before_fulfilled
    from d
),

f as (
    select
        e.*,
        iff(delivered_raw is not null and not (d_future or d_before_order or d_before_fulfilled),
            delivered_raw, null) as delivered_at
    from e
)

-- Duplicate handling: keep the most complete row per ORDER_ID (non-null fulfilled / delivered / carrier
-- AFTER cleaning); ties are broken by original file order.
select
    f.*,
    row_number() over (partition by order_id order by
        (iff(fulfilled_dt is not null, 1, 0) + iff(delivered_at is not null, 1, 0) + iff(carrier_clean is not null, 1, 0)) desc,
        row_id)                                                      as rn,
    count(*) over (partition by order_id)                            as copies,
    first_value(raw_hash) over (partition by order_id order by
        (iff(fulfilled_dt is not null, 1, 0) + iff(delivered_at is not null, 1, 0) + iff(carrier_clean is not null, 1, 0)) desc,
        row_id)                                                      as kept_hash
from f
