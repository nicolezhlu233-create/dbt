{# One row per distinct (country, region) pair seen in the data, with the cleaned values.
   - US / CA: region becomes a standard 2-letter code, or NULL if unrecognisable (city names, 'DD', ...)
   - Missing country + a full US state name (e.g. 'SOUTH CAROLINA') -> country inferred as 'US'
   - Any other country: region is free text, left as trimmed upper-case #}
with distinct_pairs as (
    select distinct
        country_raw,
        region_raw,
        regexp_replace(regexp_replace(region_raw, '^(US|CA)-', ''), '[^A-Z]', '') as rkey   -- 'CA-ON' -> 'ON'
    from {{ ref('stg_orders') }}
),

inferred as (
    select
        d.*,
        iff(d.country_raw is null and length(d.rkey) > 2 and k.code is not null, 'US', null) as country_inferred
    from distinct_pairs d
    left join {{ ref('int_region_keys') }} k
        on k.country = 'US' and k.region_key = d.rkey
)

select
    i.country_raw,
    i.region_raw,
    coalesce(i.country_raw, i.country_inferred) as country_clean,
    case
        when i.region_raw is null then null
        when coalesce(i.country_raw, i.country_inferred) in ('US', 'CA') then k.code
        else i.region_raw
    end as region_clean,
    (i.country_inferred is not null) as country_was_inferred
from inferred i
left join {{ ref('int_region_keys') }} k
    on k.country = coalesce(i.country_raw, i.country_inferred)
   and k.region_key = i.rkey
