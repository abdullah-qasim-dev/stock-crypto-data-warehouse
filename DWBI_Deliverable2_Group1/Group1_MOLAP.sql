CREATE TABLE dw.molap_crypto AS
SELECT
    d.year,
    d.month,
    ci.symbol,
    AVG(f.close_price) AS avg_close,
    SUM(f.volume) AS total_volume
FROM dw.fact_crypto_prices f
JOIN dw.dim_crypto_info ci ON f.crypto_id = ci.crypto_id
JOIN dw.dim_date d ON f.date_id = d.date_id
GROUP BY d.year, d.month, ci.symbol
ORDER BY d.year, d.month, ci.symbol;


CREATE TABLE dw.molap_stock AS
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



Select * from dw.molap_crypto
Select * from dw.molap_stock


--Vallidation Queries to Check Mismatches in the Ouputs of OlAP and MOLAP
SELECT COUNT(*) AS "Mismatches bw OLAP and MOLAP of Crypto"
FROM (
    SELECT d.year, d.month, ci.symbol,
           AVG(f.close_price) AS avg_close,
           SUM(f.volume) AS total_volume
    FROM dw.fact_crypto_prices f
    JOIN dw.dim_crypto_info ci ON f.crypto_id = ci.crypto_id
    JOIN dw.dim_date d ON f.date_id = d.date_id
    GROUP BY d.year, d.month, ci.symbol
) olap
LEFT JOIN dw.molap_crypto m
USING(year, month, symbol)
WHERE ROUND(olap.avg_close, 4) != ROUND(m.avg_close, 4)
   OR olap.total_volume != m.total_volume;


SELECT COUNT(*) AS "Mismatches bw OLAP and MOLAP of Stock"
FROM (
    SELECT d.year, d.month, si.symbol,
           AVG(f.close_price) AS avg_close,
           SUM(f.volume) AS total_volume
    FROM dw.fact_stock_prices f
    JOIN dw.dim_stock_info si ON f.stock_id = si.stock_id
    JOIN dw.dim_date d ON f.date_id = d.date_id
    GROUP BY d.year, d.month, si.symbol
) olap
LEFT JOIN dw.molap_stock m
USING(year, month, symbol)
WHERE ROUND(olap.avg_close, 4) != ROUND(m.avg_close, 4)
   OR olap.total_volume != m.total_volume;

   

