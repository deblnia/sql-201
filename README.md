# sql-201
The original impetus for a SQL 201 project was [this tweet from Teej](https://x.com/teej_m/status/1455293290979512326?ref_src=twsrc%5Etfw%7Ctwcamp%5Etweetembed%7Ctwterm%5E1455293290979512326%7Ctwgr%5Ee5263a4dbc115cbf192753a2ad7755373b0a96ac%7Ctwcon%5Es1_c10&ref_url=https%3A%2F%2Fwww.notion.so%2Fdeblina%2FSQL-201-863f8241e1884ea194f6d73ff7daf18c). I started writing this as a blog post earlier this year, but I was inspired by [Ben Nour](https://github.com/ben-n93/SQL-tips-and-tricks) to just make this a repo and call it a day.

- [Writing Debuggable SQL](#writing-debuggable-sql)
    - [Use trailing commas](#use-trailing-commas)
    - [Use a dummy column in your where clause](#use-a-dummy-column-in-your-where-clause)
    - [Use CTEs](#use-ctes)
- [Anti-patterns](#anti-patterns)
    - [Distinct](#distinct)
    - [Ordering any CTE but your last](#ordering-on-any-cte-but-your-last)


## Writing Debuggable SQL

### Use trailing commas 

```sql 
-- it's easier to comment out columns in this 
select 
    user_id
    , timestamp 
    , num_likes
    -- , num_blocks 
from table 

-- than in this 
select 
    user_id, 
    timestamp, 
    num_likes--, 
    --num_blocks 
from table 
```

### Use a dummy column in your WHERE clause 

```sql 
-- it's easier to comment out filters in this 
select 
    user_id
    , timestamp 
    , num_likes
from table 
where 1=1 
--AND num_blocks > 0 
and num_likes is not null 

-- than in this 
select 
    user_id, 
    timestamp, 
    num_likes
from table 
where --num_blocks > 0
--AND  
num_likes is not null 
```

### Use CTEs 

As Teej says, common table expressions (CTEs) are the closest thing SQL has to import statements. They help organize logic by isolating transformations.

    **One business rule per CTE** is a good rule of thumb, just to keep things atomic. 

```sql 
with base as (
    SELECT 
        user_id 
        , MAX(timstamp) latest_order 
    FROM table 
    WHERE 1=1 
    group by 2 
)
select 
base.user_id,
orders.order_id 
from base 
left join orders 
on base.user_id = orders.user_id 
and base.latest_order = orders.placed_at
``` 
You can also write CTEs as sub-queries of a sort, but I personally find this harder to read. More jumping back and forth required IMO. 

```sql 
select 
base.user_id,
orders.order_id 
from (
        SELECT 
        user_id 
        , MAX(timstamp) latest_order 
    FROM table 
    WHERE 1=1 
    group by 2 
) as base 
left join orders 
on base.user_id = orders.user_id 
and base.latest_order = orders.placed_at
```

## Anti-patterns 

### Distinct 

A blanket distinct in a query is SQL code smell. I try and handle duplicates by making an explicit choice - usually taking the most recent row per unique ID. 

```sql 
-- smelly! 
select distinct 
    user_id 
from table 

-- better, explicitly filters to the most recent row 
select 
    user_id 
from table 
qualify rank() over (partition over user_id order by timestamp desc) = 1 
``` 

### Ordering on any CTE but your last 




## Gotchas 

### Filtering on the right table in a left join 

This will default to an inner join since the 

```sql 
select 
    user_id 
from table 
left join another_table using (user_id)
where 1=1 
and another_table.column > 1 
``` 

### COUNT(*) includes null values, COUNT(col) does not include null values 




## Joins 



## Window Functions 



## See Also 
- [SQL Levels Explained](https://github.com/airbytehq/SQL-Levels-Explained)