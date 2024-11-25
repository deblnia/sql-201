# sql-201
The original impetus for a SQL 201 project was [this tweet from Teej](https://x.com/teej_m/status/1455293290979512326?ref_src=twsrc%5Etfw%7Ctwcamp%5Etweetembed%7Ctwterm%5E1455293290979512326%7Ctwgr%5Ee5263a4dbc115cbf192753a2ad7755373b0a96ac%7Ctwcon%5Es1_c10&ref_url=https%3A%2F%2Fwww.notion.so%2Fdeblina%2FSQL-201-863f8241e1884ea194f6d73ff7daf18c). I started writing this as a blog post earlier this year, but I was inspired by [Ben Nour](https://github.com/ben-n93/SQL-tips-and-tricks) to just make this a repo and call it a day.

- [Writing Debuggable SQL](#writing-debuggable-sql)
    - [Use trailing commas](#use-trailing-commas)
    - [Use a dummy column in your where clause](#use-a-dummy-column-in-your-where-clause)
    - [Use CTEs](#use-ctes)
- [Anti-patterns](#anti-patterns)
    - [Distinct](#distinct)
    - [Ordering on any CTE but your last](#ordering-on-any-cte-but-your-last)
    - [Correlated Subqueries](#correlated-subqueries)
- [Gotchas](#gotchas)
    - [Filtering on the right table in a left join](#filtering-on-the-right-table-in-a-left-join)
    - [COUNT(*) includes null values, COUNT(col) does not include null values](#count-includes-null-values-countcol-does-not-include-null-values)
    - [Use EXISTS Instead of IN or NOT IN](#use-exists-instead-of-in-or-not-in)
- [Joins](#joins)
    - [Cross Joins](#cross-joins)
    - [Self Joins](#self-joins)
    - [Range Joins](#range-joins)
- [Set Operations](#set-operations)
- [Window Functions](#window-functions)
- [String Stuff](#string-stuff)
- [Non-standard Features](#non-standard-features)
    - [Grouping Sets](#grouping-sets)
    - [Rollups](#rollups)
- [See Also](#see-also)
    - [SQL Levels Explained](https://github.com/airbytehq/SQL-Levels-Explained)

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
    user_id 
    , timestamp 
    , num_likes--, 
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
    user_id
    , timestamp 
    , num_likes
from table 
where --num_blocks > 0
--AND  
num_likes is not null 
```

### Use CTEs 

As Teej says, common table expressions (CTEs) are the closest thing SQL has to import statements. They help organize logic by isolating transformations, and let you define a sub-table to work with or from. 

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
    base.user_id
    , orders.order_id 
from base 
left join orders 
on base.user_id = orders.user_id 
and base.latest_order = orders.placed_at
``` 
You can also write CTEs as sub-queries of a sort, but I personally find this harder to read. More jumping back and forth required IMO. This is most readable if you just want to do one subquery and join on and on, usually building up flags. 

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

Sorting is expensive, and should be avoided until necessary. If you need to do any intermediate ordering, I would do it explicitly using a window function. 

```sql 
-- intemediate ordering, not great 
WITH base AS (
    select 
        user_id
        , num_likes
    from table
    order by num_likes DESC  -- Pointless ordering here
), filtered_base AS (
    select 
        user_id
        , num_likes
    from base 
    order by num_likes ASC  -- Re-ordering the same data again for no reason
)
select user_id 
from filtered_base 
order by num_likes desc  -- Final ordering that actually matters
limit 1;

-- better! 
    select 
        user_id 
        , num_likes 
    from table 
    qualify rank() over(order by num_likes desc) = 1 
``` 

### Correlated Subqueries 

These are usually subqueries in the WHERE clause to meet a specific filtering criteria. These can get very expensive since you're doing nested evaluation (the query executes once for every row in the main query, meaning that the inner query is driven by the outer one, unlike in a normal subquery where the inner query executes once and first), and are better off as atomic CTEs and explicit joins. 


```sql
-- correlated sub-query 
select 
    e.name
    , e.salary
from Employee e
WHERE 1=1 
    AND e.salary > (
    SELECT AVG(salary)
    FROM Employee
    WHERE departmentId = e.departmentId
    ) 
```

More examples on the [Wikipedia page](https://en.wikipedia.org/wiki/Correlated_subquery). 

### Avoid using wildcards at the beginning of a string 

E.g. (‘%jess%’ vs. ‘jess%’)

## Gotchas 

### Filtering columns to a specific values in the right table when doing a left join 

Or vice versa! I am just a left-join purist. 

SQL's execution process first performs the join (in this case, a LEFT JOIN) and then applies the filter in the WHERE clause. Since non-matching rows from the right table result in NULL values, those NULL rows won't pass the condition in the WHERE clause (like WHERE right_table.some_column = 'X'). As a result, those rows are filtered out, mimicking the behavior of an INNER JOIN.

You can add filters to the ON clause of the join to get around this. The result table will still have everything in the left table, but only the right table info you've filtered for would be filled in. 

```sql 
-- THIS IS EFFECTIVELY AN INNER JOIN! 
SELECT table_a.id 
FROM table_a
LEFT JOIN table_b 
ON table_a.id = table_b.id
WHERE table_b.ds = CURRENT_DATE

-- Good left join :) 
SELECT table_a.id, 
FROM table_a
LEFT JOIN table_b 
ON table_a.id = table_b.id AND table_b.ds = CURRENT_DATE
``` 

This is also slightly different between [Presto and Hive](https://teradata.github.io/presto/docs/141t/migration/from-hive.html). 

Also note that this does not effect anti-joins (as in below), since those explicitly deal with nulls. A left join only behaves like an inner join when you don't account for the null values in the right table. 

```sql 
-- An anti-join, just getting the days that are in table a that are not in table b 
SELECT table_a.id 
FROM table_a
LEFT JOIN table_b 
ON table_a.id = table_b.id
WHERE table_b.ds is null 
``` 

### COUNT(*) includes null values, COUNT(col) does not include null values 

### Use EXISTS instead of IN or NOT IN 

In and not in do not count nulls. Use them only when you're dealing with specific values and you know you won't get any NULLs. EXISTS and NOT EXISTS are better for verifying prescence / absence of relationships without needing exact matches. 

### Case statements short circuit evaluate 

A case statement will return the first true condition it hits and not evaluate all the others, so you want your most restrictive conditions first. If no conditions hit and there's no else to default a result to, the case statement will return null. 

This is slightly implementation specific, so definitely check the docs for your specific RDBMS.

## Joins 

If you want a more comprehensive introduction to how to think about joins, I'd suggest: 
- [Julia Evans' nice rules for joins](https://wizardzines.com/comics/joins/)
- [Sarah Anoke's intro to joins](https://sanoke.github.io/blog/datasci/sql-joins.html)
- [Justin Jaffrey's ways of thinking about joins](https://justinjaffray.com/joins-13-ways)
- [Randy Au's Can we stop with the SQL joins venn diagram insanity](https://counting.substack.com/p/can-we-stop-with-the-sql-joins-venn-diagrams-insanity-16791d9250c3?s=r)

### Cross Joins 

Cross joins give a row for each possible pairing of a row from Table A and a row from Table B. They don't require any join keys, since they're exhaustive. 

Comma joins are also default cross joins. 

The common pattern that I see is cross-join unnest-ing to explode a struct. 

Imagine this table: 

| user_id | favorite_colors           |
|---------|---------------------------|
| 1       | ["red", "blue"]           |
| 2       | ["green", "yellow", "blue"] |
| 3       | ["black"]                 |


```sql 
SELECT 
    user_i 
    , color
FROM 
    users, 
    UNNEST(favorite_colors) AS color
    -- in presto this is 
    -- CROSS JOIN UNNEST (users.favorite_colors) AS c(colors)
    -- where the c is the new exploded table alias and colors is the column names 
```

Gets: 

| user_id | color   |
|---------|---------|
| 1       | red     |
| 1       | blue    |
| 2       | green   |
| 2       | yellow  |
| 2       | blue    |
| 3       | black   |

### Self Joins 

If you join a table to itself, you get a sort of poor-man's version of nested iteration. For example, these two things are equivalent. 

```sql 
select id
from table_a a 
left join table_a a1 USING (id) 
where a.time < a1.time 
```
```python 
final_set = []

for row in table_a: 
	for same_row in table_a: 
		if row[id] == same_row[id]:
			if row[time] < same_row[time]:
				final_set.append(row)
```

This can be especially useful in situations where data is hierarchical (eg. org charts), or you're trying to find relationships between rows (i.e. users with the same title but different pay). 

Joining on id and using some time window filter is a pretty common pattern. 

### Range Joins 

Range joins are joins that involve a range of values (>=, <= etc.) instead of just strict equality. They can be useful for funnels. 

```sql 
SELECT 
    e.employee_id 
    , e.name
    , e.salary
    , s.bracket_name
FROM 
    employees e
JOIN 
    salary_brackets s
ON 
    e.salary BETWEEN s.min_salary AND s.max_salary
```

The BETWEEN predicate is inclusive (so both the bounds count as part of the range). The order of arguments is always lower_bound and upper_bound. 

## Set Operations 

### UNION 

Equivalent to a row bind. UNION ALL binds all rows, keeping duplicates. UNION doesn't keep duplicates. We usually prefer UNION ALL. 

```sql
select 
    user_id 
from table_for_one_day 

union all 

select 
    user_id 
from table_for_another_day 

```

### EXCEPT AND INTERSECT 

What they sounds like. You can use this in the traditional set operation way - to difference two full queries - but they seem particularly powerful when the queries are pulling from two different tables. 


## Window Functions 

Window functions let you do aggregations in place. They look something like this: 

```sql 
function_name OVER (PARTITION BY col_name1, col_name2, ...
                    ORDER BY col_name3
                    frame_clause)
```

The **partition** specifies the window over which the query is aggregating. The **order** specifies the order. The **frame clause** specifies a subset of the window (the set of rows relative to the current row used in computation). 

I prefer keeping window functions in separate CTEs, not mixing them with group-by and summarize aggregations. You don't need to group by window functions, but the grain of the result can be confusing. You can also [ORDER BY an aggregation, but that needs to be grouped](https://stackoverflow.com/questions/65201713/why-use-group-by-in-window-function). 

See also: 
- [Understanding Window Functions](https://tapoueh.org/blog/2013/08/understanding-window-functions/)
- [Sarah Anoke on Window Functions](https://sanoke.github.io/blog/datasci/sql-window.html)
- [Yuan Meng's Notes](https://yuanm.notion.site/window-functions-0a792ad76e90400d9381df0931e0c990) 

## String Stuff 

### Use || to concatenate strings 
 
I had to use this to concatenate two rows to make my own unique ID per row once. 

### Use < and > to de-dupe and alphabetize strings

## Non-standard Features 

### Having  

Can save some CTEs. HAVING filters on aggregations in place, but still requires grouping! It's late in the order of execution.  

```sql
-- no having 
with no_having as (
	select
		user_id
		, count(*) num 
	from examples
	where 1=1
	group by 1
)
select
	user_id 
from no_having
where 1=1
and num > 5

-- equivalent to
select
	user_id 
from examples
where 1=1
group by 1 
having count(*) > 5 
```

### Qualify 

Can save some CTEs. QUALIFY filers on window functions in place. Commonly used to de-dupe. 

```
-- deduping with qualify. filtering just for the most recent row 
select
	user_id
	, ts 
from examples
where 1=1
qualify rank() over(partition by user_id order by ts desc) = 1  
```

### Grouping Sets 

### Rollups 

### Cube 

### Pivot and Unpivot 

### Offset 

I prefer to use a window function to explicitly rank and then select from ranks, but `OFFSET` can be used in conjunction with `LIMIT` too. 

```sql
SELECT
	EmployeeID
	, FirstName
	, LastName
FROM Employees
ORDER BY EmployeeID
LIMIT 5
OFFSET 5
```
This gives us employees 6-10. 

## See Also 
- [SQL Levels Explained](https://github.com/airbytehq/SQL-Levels-Explained)
- [Mode's SQL Tutorial](https://mode.com/sql-tutorial)
- [Teej's Funnel Patterns](https://github.com/teej/sf-funnels)
- [Haki Benita's SQL for Data Analysis](https://hakibenita.com/sql-for-data-analysis)
- [On the SQL Order of Operations](https://blog.jooq.org/a-beginners-guide-to-the-true-order-of-sql-operations/)
- Style Guides:
    - [Simon Holywell's](https://www.sqlstyle.guide/)
    - [Mazur's](https://github.com/mattm/sql-style-guide)
    - [Brooklyn Data's](https://github.com/brooklyn-data/co/blob/main/sql_style_guide.md)
- Practice: 
    - [Julia Evans join challenges](https://joins-238123.netlify.app/join-challenges/)
    - [LeetCode SQL](https://leetcode.com/problemset/database/?page=1)
    - [Beyond Leetcode SQL](https://github.com/shawlu95/Beyond-LeetCode-SQL)
    - [8 Week SQL Challenge](https://8weeksqlchallenge.com/case-study-1/)
    - [DataLemur](https://datalemur.com/)
    - [Star SQL](https://selectstarsql.com/) 
    - [Knightlab SQL Mystery](https://mystery.knightlab.com/walkthrough.html)
