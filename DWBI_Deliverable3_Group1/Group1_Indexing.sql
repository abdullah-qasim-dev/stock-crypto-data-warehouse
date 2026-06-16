-- Step 1: Queries (Before Indexing)

-- Query 1: Uses indexing on three key columns (date_id, symbol, user_key)
EXPLAIN ANALYZE
SELECT t.user_key, u.user_name, t.asset_symbol, c.symbol_name AS crypto_name, s.symbol AS stock_symbol, d.year, SUM(t.quantity * t.price_usd) AS total_trade_value, AVG(t.price_usd) AS avg_price
FROM dw.fact_trades t
LEFT JOIN dw.dim_user_info u ON t.user_key = u.user_key
LEFT JOIN dw.dim_crypto_info c ON t.asset_symbol = c.symbol
LEFT JOIN dw.dim_stock_info s ON t.asset_symbol = s.symbol
LEFT JOIN dw.dim_date d ON t.date_id = d.date_id
WHERE d.year = 2025
GROUP BY t.user_key, u.user_name, t.asset_symbol, c.symbol_name, s.symbol, d.year
HAVING SUM(t.quantity * t.price_usd) > 1000
ORDER BY total_trade_value DESC
LIMIT 100;

-- Query 2: Uses only one indexing column (user_key)
EXPLAIN ANALYZE
SELECT t.user_key, u.user_name, COUNT(*) AS total_trades, SUM(t.total_usd) AS total_volume
FROM dw.fact_trades t
JOIN dw.dim_user_info u ON t.user_key = u.user_key
WHERE t.user_key IN (101, 102, 103, 104, 105)
GROUP BY t.user_key, u.user_name
ORDER BY total_volume DESC;

--Query 3 (Bitmap index).
EXPLAIN ANALYZE
SELECT *
FROM dw.fact_trades t
JOIN dw.dim_user_info u ON t.user_key = u.user_key
WHERE u.risk_profile = 'Moderate' OR u.risk_profile = 'Aggressive';

--Query 4 (Materialized View)
EXPLAIN ANALYZE
SELECT t.user_key, u.user_name, t.asset_symbol, c.symbol_name AS crypto_name, s.symbol AS stock_symbol, d.year, d.month, SUM(t.quantity * t.price_usd) AS total_trade_value, AVG(t.price_usd) AS avg_price, COUNT(*) AS trade_count
FROM dw.fact_trades t
LEFT JOIN dw.dim_user_info u ON t.user_key = u.user_key
LEFT JOIN dw.dim_crypto_info c ON t.asset_symbol = c.symbol
LEFT JOIN dw.dim_stock_info s ON t.asset_symbol = s.symbol
LEFT JOIN dw.dim_date d ON t.date_id = d.date_id
GROUP BY t.user_key, u.user_name, t.asset_symbol, c.symbol_name, s.symbol, d.year, d.month
ORDER BY total_trade_value DESC
LIMIT 200;

-- Step 2: Create Indexes
CREATE INDEX IF NOT EXISTS idx_fact_trades_user_key ON dw.fact_trades(user_key);
CREATE INDEX IF NOT EXISTS idx_dim_crypto_info_symbol ON dw.dim_crypto_info(symbol);
CREATE INDEX IF NOT EXISTS idx_dim_stock_info_symbol ON dw.dim_stock_info(symbol);
CREATE INDEX IF NOT EXISTS idx_dim_date_date_id ON dw.dim_date(date_id);
CREATE INDEX IF NOT EXISTS idx_dim_user_info_risk_profile ON dw.dim_user_info(risk_profile);

-- DROP INDEX IF EXISTS dw.idx_fact_trades_user_key;
-- DROP INDEX IF EXISTS dw.idx_dim_crypto_info_symbol;
-- DROP INDEX IF EXISTS dw.idx_dim_stock_info_symbol;
-- DROP INDEX IF EXISTS dw.idx_dim_date_date_id;
-- DROP INDEX IF EXISTS dw.idx_dim_user_info_risk_profile;

-- Step 3: Re-run the same queries to compare performance

-- Query 1 (B-Tree Index)
EXPLAIN ANALYZE
SELECT t.user_key, u.user_name, t.asset_symbol, c.symbol_name AS crypto_name, s.symbol AS stock_symbol, d.year, SUM(t.quantity * t.price_usd) AS total_trade_value, AVG(t.price_usd) AS avg_price
FROM dw.fact_trades t
LEFT JOIN dw.dim_user_info u ON t.user_key = u.user_key
LEFT JOIN dw.dim_crypto_info c ON t.asset_symbol = c.symbol
LEFT JOIN dw.dim_stock_info s ON t.asset_symbol = s.symbol
LEFT JOIN dw.dim_date d ON t.date_id = d.date_id
WHERE d.year = 2025
GROUP BY t.user_key, u.user_name, t.asset_symbol, c.symbol_name, s.symbol, d.year
HAVING SUM(t.quantity * t.price_usd) > 1000
ORDER BY total_trade_value DESC
LIMIT 100;

-- Query 2 (B-Tree Index)
EXPLAIN ANALYZE
SELECT t.user_key, u.user_name, COUNT(*) AS total_trades, SUM(t.total_usd) AS total_volume
FROM dw.fact_trades t
JOIN dw.dim_user_info u ON t.user_key = u.user_key
WHERE t.user_key IN (101, 102, 103, 104, 105)
GROUP BY t.user_key, u.user_name
ORDER BY total_volume DESC;

--Query 3 (Bitmap index).
EXPLAIN ANALYZE
SELECT *
FROM dw.fact_trades t
JOIN dw.dim_user_info u ON t.user_key = u.user_key
WHERE u.risk_profile = 'Moderate' OR u.risk_profile = 'Aggressive';

--Creating Materialized View.
CREATE MATERIALIZED VIEW dw.mv_trade_summary AS
SELECT t.user_key, u.user_name, t.asset_symbol, c.symbol_name AS crypto_name, s.symbol AS stock_symbol, d.year, d.month, SUM(t.quantity * t.price_usd) AS total_trade_value, AVG(t.price_usd) AS avg_price, COUNT(*) AS trade_count
FROM dw.fact_trades t
LEFT JOIN dw.dim_user_info u ON t.user_key = u.user_key
LEFT JOIN dw.dim_crypto_info c ON t.asset_symbol = c.symbol
LEFT JOIN dw.dim_stock_info s ON t.asset_symbol = s.symbol
LEFT JOIN dw.dim_date d ON t.date_id = d.date_id
GROUP BY t.user_key, u.user_name, t.asset_symbol, c.symbol_name, s.symbol, d.year, d.month;


EXPLAIN ANALYZE
SELECT *
FROM dw.mv_trade_summary;
