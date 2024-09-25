with hist as (
    select 
        user_id
        , count(distinct order_id) num_orders
    from random_fct_table
    group by 1 
), perc as (
  select 
    ntile(10) over(order by num_orders desc) as decile 
    -- this might be a FB / Presto specific UDF 
    , cume_dist() over(order by num_orders desc) as cume_dist
  from hist
)

select 
    ntile
    , max(cume_dist) as cume_dist
from perc
group by 1
order by 1