-- Pivoting the following table long: 
-- +------+---------+----------+----------+
-- | year | revenue_A | revenue_B | total  |
-- +------+---------+----------+----------+
-- | 2020 |     100  |     200  |     300  |
-- | 2021 |     150  |     250  |     400  |
-- +------+---------+----------+----------+
select
     year
    ,'A' AS product
    ,revenue_A AS revenue
from
    sales_summary

union all

select
     year
    ,'B' AS product
    ,revenue_B AS revenue
from
    sales_summary

order by 
    year, product