# sql-201
The original impetus for a SQL 201 project was [this tweet from Teej](https://x.com/teej_m/status/1455293290979512326?ref_src=twsrc%5Etfw%7Ctwcamp%5Etweetembed%7Ctwterm%5E1455293290979512326%7Ctwgr%5Ee5263a4dbc115cbf192753a2ad7755373b0a96ac%7Ctwcon%5Es1_c10&ref_url=https%3A%2F%2Fwww.notion.so%2Fdeblina%2FSQL-201-863f8241e1884ea194f6d73ff7daf18c). I started writing this as a blog post earlier this year, but I was inspired by [Ben Nour](https://github.com/ben-n93/SQL-tips-and-tricks) to just make this a repo and call it a day.

- [Writing Debuggable SQL](#writing-debuggable-sql)

## Writing Debuggable SQL

- Use trailing commas 

```sql 
-- it's easier to comment out columns in this 
SELECT 
    user_id
    , timestamp 
    , num_likes
    -- , num_blocks 
FROM table 

-- than in this 
SELECT 
    user_id, 
    timestamp, 
    num_likes--, 
    --num_blocks 
FROM table 
```

- Use a dummy column in your WHERE clause 

- Use CTEs 

## Anti-patterns 

