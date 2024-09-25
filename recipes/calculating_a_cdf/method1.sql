with hist as (
    select 
        user_id
        , count(distinct order_id) num_orders
    from random_fct_table
    group by 1 
), perc as (
    select 
        -- ntile may not be available on older systems 
        ntile(10) over(order by num_orders desc) as decile 
        , num_orders
    from hist 
), total as (
    select 
        decile
        , sum(num_orders) as total_orders 
    from perc 
    group by 1 
), perc_of_total as (
    select 
        decile
        , 1.0 * total_orders / sum(total_orders) over() as perc_total 
    from total 
)
select 
    decile, 
    sum(perc_total) over(order by decile rows unbounded preceding) as cume_perc_dist
from perc_of_total
order by 1 