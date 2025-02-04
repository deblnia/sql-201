WITH retention_d0 AS (
    SELECT
        ds,
        country_bucket,
        user_id
    FROM fact_table
    WHERE
        1=1 
        AND DATE_DIFF('day', DATE(ds), DATE('2024-01-28')) BETWEEN 0 AND 28
),
retention_w1 AS (
    SELECT
        ds,
        country_bucket,
        user_id
    FROM fact_table
    WHERE
        1=1 
        AND DATE_DIFF('day', DATE(ds), DATE('2024-01-28')) BETWEEN 0 AND 28
),
daily AS (
    SELECT
        a.ds,
        'global' country_bucket,
        COUNT(DISTINCT a.user_id) producer_dau,
        COUNT(DISTINCT b.user_id) day_over_week_retained_producer_dau,
        1. * COUNT(DISTINCT b.user_id) / COUNT(DISTINCT a.user_id) w_d_stickiness,
        AVG(1. * COUNT(DISTINCT b.user_id) / COUNT(DISTINCT a.user_id)) OVER (
            PARTITION BY
                'global'
            ORDER BY
                a.ds rows BETWEEN 6 PRECEDING AND CURRENT ROW
        ) w_d_stickiness_7d
    FROM retention_d0 a
    LEFT JOIN retention_w1 b
        ON a.user_id = b.user_id
        AND DATE_DIFF('day', DATE(a.ds), DATE(b.ds)) BETWEEN 1 AND 7
    GROUP BY
        1, 2
)
SELECT
    *
FROM daily
ORDER BY
    1 DESC,
    2
