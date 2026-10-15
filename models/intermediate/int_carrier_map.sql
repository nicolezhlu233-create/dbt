{# Maps every distinct raw carrier value to a real carrier name.
   Rules, in priority order:
     1. exact match to the reference list            ('Usps'          -> 'Usps')
     2. reference name + exactly 3 junk characters   ('UspsNCk'       -> 'Usps',
                                                      'Ups Mail InnovationsIDN' -> 'Ups Mail Innovations')
     3. 'Unknown' -> NULL;  anything unmatched -> NULL
   Review this model's output after a run: any carrier_clean IS NULL that is not 'Unknown' is a new carrier
   that should be added to seeds/ref_carrier.csv. #}
with raw as (
    select distinct carrier_raw
    from {{ ref('stg_orders') }}
    where carrier_raw is not null
),

candidates as (
    select
        r.carrier_raw,
        c.carrier,
        iff(r.carrier_raw = c.carrier, 0, 1) as is_suffix_match
    from raw r
    left join {{ ref('ref_carrier') }} c
        on r.carrier_raw = c.carrier
        or (length(r.carrier_raw) = length(c.carrier) + 3
            and left(r.carrier_raw, length(c.carrier)) = c.carrier)
)

select
    carrier_raw,
    iff(lower(carrier_raw) = 'unknown', null, carrier) as carrier_clean
from candidates
qualify row_number() over (
            partition by carrier_raw
            order by is_suffix_match, length(carrier) desc nulls last) = 1
