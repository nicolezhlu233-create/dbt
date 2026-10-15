select order_id, line_no, count(*) as n
from {{ ref('line_items_clean') }}
group by 1, 2
having count(*) > 1
