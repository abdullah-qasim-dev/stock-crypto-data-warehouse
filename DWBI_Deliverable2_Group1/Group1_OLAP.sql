-- OLAP: Crypto monthly summary from fact table
SELECT
    d.year,
    d.month,
    ci.symbol,
    AVG(f.close_price) AS avg_close,
    SUM(f.volume) AS total_volume
FROM dw.fact_crypto_prices f
JOIN dw.dim_crypto_info ci ON f.crypto_id = ci.crypto_id
JOIN dw.dim_date d ON f.date_id = d.date_id
where
GROUP BY d.year, d.month, ci.symbol;


-- OLAP: Stock monthly summary from fact table

SELECT
    d.year,
    d.month,
    si.symbol,
    AVG(f.close_price) AS avg_close,
    SUM(f.volume) AS total_volume
FROM dw.fact_stock_prices f
JOIN dw.dim_stock_info si ON f.stock_id = si.stock_id
JOIN dw.dim_date d ON f.date_id = d.date_id
GROUP BY d.year, d.month, si.symbol
ORDER BY d.year, d.month, si.symbol;
