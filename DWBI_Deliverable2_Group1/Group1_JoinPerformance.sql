-- ============================================================================
-- 1) FORCE NESTED LOOP
-- ============================================================================
SET enable_hashjoin = off;
SET enable_mergejoin = off;
SET enable_nestloop = on;

-- Run EXPLAIN ANALYZE for Nested Loop
EXPLAIN ANALYZE
SELECT
    u.user_name,
    r.country,
    d.year,
    d.month,
    COUNT(*) AS trade_count,
    SUM(ft.total_usd) AS total_trade_usd
FROM dw.fact_trades ft
JOIN dw.dim_user_info u  ON ft.user_key = u.user_key
JOIN dw.dim_region r     ON ft.region_key = r.region_key
JOIN dw.dim_date d       ON ft.date_id = d.date_id
WHERE d.year = 2020
GROUP BY u.user_name, r.country, d.year, d.month
ORDER BY d.year, d.month, r.country, u.user_name;

-- Reset planner switches to default (enable all)
SET enable_hashjoin = on;
SET enable_mergejoin = on;
SET enable_nestloop = on;

-- ============================================================================
-- 2) FORCE SORT-MERGE JOIN
-- Disable hash and nested loop, enable mergejoin only.
-- Useful when inputs are large and can be sorted efficiently.
-- ============================================================================
SET enable_hashjoin = off;
SET enable_nestloop = off;
SET enable_mergejoin = on;

EXPLAIN ANALYZE
SELECT
    u.user_name,
    r.country,
    d.year,
    d.month,
    COUNT(*) AS trade_count,
    SUM(ft.total_usd) AS total_trade_usd
FROM dw.fact_trades ft
JOIN dw.dim_user_info u  ON ft.user_key = u.user_key
JOIN dw.dim_region r     ON ft.region_key = r.region_key
JOIN dw.dim_date d       ON ft.date_id = d.date_id
WHERE d.year = 2020
GROUP BY u.user_name, r.country, d.year, d.month
ORDER BY d.year, d.month, r.country, u.user_name;

-- Reset planner switches to default
SET enable_hashjoin = on;
SET enable_mergejoin = on;
SET enable_nestloop = on;

-- ============================================================================
-- 3) FORCE HASH JOIN
-- Disable merge and nested loop, enable hashjoin only.
-- Hash joins are usually fastest for large equi-joins without ordering.
-- ============================================================================
SET enable_mergejoin = off;
SET enable_nestloop = off;
SET enable_hashjoin = on;

EXPLAIN ANALYZE
SELECT
    u.user_name,
    r.country,
    d.year,
    d.month,
    COUNT(*) AS trade_count,
    SUM(ft.total_usd) AS total_trade_usd
FROM dw.fact_trades ft
JOIN dw.dim_user_info u  ON ft.user_key = u.user_key
JOIN dw.dim_region r     ON ft.region_key = r.region_key
JOIN dw.dim_date d       ON ft.date_id = d.date_id
WHERE d.year = 2020
GROUP BY u.user_name, r.country, d.year, d.month
ORDER BY d.year, d.month, r.country, u.user_name;

-- Reset planner switches to default (enable all)
SET enable_hashjoin = on;
SET enable_mergejoin = on;
SET enable_nestloop = on;


-- =======================
-- DSS vs OLTP Comparison
-- =======================
-- DSS: Long-running aggregation
EXPLAIN ANALYZE
SELECT
    r.country,
    d.year,
    d.month,
    SUM(ft.total_usd) AS monthly_trade_usd,
    COUNT(*) AS trade_count
FROM dw.fact_trades ft
JOIN dw.dim_region r ON ft.region_key = r.region_key
JOIN dw.dim_date d   ON ft.date_id = d.date_id
WHERE d.year BETWEEN 2019 AND 2021
GROUP BY r.country, d.year, d.month
ORDER BY d.year, d.month, r.country;

-- OLTP: Simple lookup by primary key
EXPLAIN ANALYZE
SELECT *
FROM dw.fact_trades
WHERE fact_trade_id = 1;  


