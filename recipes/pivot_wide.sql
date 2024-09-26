-- Pivoting the following table wide: 
-- +------+---------+---------+
-- | year | product | revenue |
-- +------+---------+---------+
-- | 2020 | A       |     100 |
-- | 2020 | B       |     200 |
-- | 2021 | A       |     150 |
-- | 2021 | B       |     250 |
-- +------+---------+---------+
select
     year
    , SUM(CASE WHEN product = 'A' THEN revenue ELSE 0 END) AS revenue_A
    , SUM(CASE WHEN product = 'B' THEN revenue ELSE 0 END) AS revenue_B
from
    sales
group by
    year
order by
    year