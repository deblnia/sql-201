with hist as (
    select 
        user_id
        , count(distinct order_id) as num_orders
    from random_fct_table
    group by 1
), ranks as (
    select 
        *
        , row_number() over(order by num_orders desc) as rnk,
        , count(*) over() as total_rows
    from hist
)
select 
    a.p * 10 as percentile 
    , round(sum(num_orders) * 1.0 / sum(num_orders) over(), 4) as perc_orders
from ranks
cross join unnest(sequence(1, 10)) a(p)
where rnk <= a.p * 0.1 * total_rows 
group by 1
order by 1;