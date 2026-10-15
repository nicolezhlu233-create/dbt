{# Lookup keys for US states / Canadian provinces: the code itself, the full name with
   everything except letters removed ('NEW JERSEY' -> 'NEWJERSEY'), and hand-picked typos. #}
select country, code as region_key, code from {{ ref('ref_region_code') }}
union
select country, regexp_replace(upper(name), '[^A-Z]', ''), code from {{ ref('ref_region_code') }}
union
select country, alias_key, code from {{ ref('ref_region_alias') }}
