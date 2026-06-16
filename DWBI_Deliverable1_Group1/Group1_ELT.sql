-- -------------------------
-- STAGING SCHEMA IMPLEMENTATION
-- -------------------------
CREATE SCHEMA IF NOT EXISTS staging;

-- RAW REGION
CREATE TABLE IF NOT EXISTS dw.raw_region AS
SELECT * FROM staging.stg_region;


-- RAW EXCHANGE
CREATE TABLE IF NOT EXISTS dw.raw_exchange AS
SELECT * FROM staging.stg_exchange;

-- RAW CRYPTO INFO
CREATE TABLE IF NOT EXISTS dw.raw_crypto_info AS
SELECT * FROM staging.stg_crypto_info;

-- RAW STOCK INFO
CREATE TABLE IF NOT EXISTS dw.raw_stock_info AS
SELECT * FROM staging.stg_stock_info;

-- RAW USER INFO
CREATE TABLE IF NOT EXISTS dw.raw_user_info AS
SELECT * FROM staging.stg_user_info;

-- RAW CRYPTO PRICES
CREATE TABLE IF NOT EXISTS dw.raw_crypto_prices AS
SELECT * FROM staging.stg_crypto_prices;

-- RAW STOCK PRICES
CREATE TABLE IF NOT EXISTS dw.raw_stock_prices AS
SELECT * FROM staging.stg_stock_prices;

-- RAW USER TRADES
CREATE TABLE IF NOT EXISTS dw.raw_user_trades AS
SELECT * FROM staging.stg_user_trades;



--1) Date Dimension Elt
CREATE TABLE IF NOT EXISTS dw.dim_date_elt (
    date_id       INT PRIMARY KEY,
    full_date     DATE NOT NULL UNIQUE,
    day_of_week   VARCHAR(10),
    day           INT,
    month         INT,
    month_name    VARCHAR(20),
    quarter       INT,
    year          INT
);

-- 2) Region dimension Elt
CREATE TABLE IF NOT EXISTS dw.dim_region_elt (
    region_key    INT PRIMARY KEY,
    country       VARCHAR(100) NOT NULL UNIQUE,
    continent     VARCHAR(50),
    timezone      VARCHAR(30)
);

-- 3) Exchange dimension Elt
CREATE TABLE IF NOT EXISTS dw.dim_exchange_elt (
    exchange_id   INT PRIMARY KEY,
    exchange_name VARCHAR(100) UNIQUE NOT NULL
);

-- 4) Crypto Info dimension Elt
CREATE TABLE IF NOT EXISTS dw.dim_crypto_info_elt (
    crypto_id        INT PRIMARY KEY,
    symbol           VARCHAR(20) UNIQUE NOT NULL,
    symbol_name      VARCHAR(150),
    launch_year      INT,
    max_supply       NUMERIC(30,0),
    sample_marketcap NUMERIC(30,2)
);

-- 5) Stock Info dimension Elt
CREATE TABLE IF NOT EXISTS dw.dim_stock_info_elt (
    stock_id           INT PRIMARY KEY,
    symbol             VARCHAR(20) UNIQUE NOT NULL,
    company_name       VARCHAR(150),
    sector             VARCHAR(100),
    ipo_year           INT,
    shares_outstanding NUMERIC(30,0),
    marketcap          NUMERIC(30,2)
);

-- 6) User Info dimension Elt
CREATE TABLE IF NOT EXISTS dw.dim_user_info_elt (
    user_key          INT PRIMARY KEY,
    user_id           VARCHAR(50) UNIQUE,
    user_name         VARCHAR(150),
    email             VARCHAR(100),
    registration_date DATE,
    risk_profile      VARCHAR(30),
    region_key        INT
);

-- 7) Crypto Prices dimension Elt
CREATE TABLE IF NOT EXISTS dw.dim_crypto_prices_elt (
    cryptoprice_id  INT PRIMARY KEY,
    name            VARCHAR(100),
    symbol          VARCHAR(20),
    price_date      DATE,
    high_price      NUMERIC(20,4),
    low_price       NUMERIC(20,4),
    open_price      NUMERIC(20,4),
    close_price     NUMERIC(20,4),
    volume          NUMERIC(30,2),
    marketcap       NUMERIC(30,2),
    crypto_id       INT
);

-- 8) Stock Prices dimension Elt
CREATE TABLE IF NOT EXISTS dw.dim_stock_prices_elt (
    stockprice_id   INT PRIMARY KEY,
    price_date      DATE,
    close_price     NUMERIC(20,4),
    volume          NUMERIC(30,2),
    open_price      NUMERIC(20,4),
    high_price      NUMERIC(20,4),
    low_price       NUMERIC(20,4),
    symbol          VARCHAR(20),
    stock_id        INT
);


-- ----------------------------
-- Fact: Crypto Prices Elt
-- ----------------------------

CREATE TABLE dw.fact_crypto_prices_elt (
    fact_crypto_id   serial PRIMARY KEY,
    crypto_id        INT,
    exchange_id      INT,
    date_id          INT,
    open_price       NUMERIC(20,6),
    high_price       NUMERIC(20,6),
    low_price        NUMERIC(20,6),
    close_price      NUMERIC(20,6),
    volume           NUMERIC(30,6),
    market_cap       NUMERIC(30,2),
    price_change     NUMERIC(20,6),
    price_change_pct NUMERIC(10,4),
    avg_price        NUMERIC(20,6),
    is_bullish_day   BOOLEAN
);


-- ----------------------------
-- Fact: Stock Prices Elt
-- ----------------------------

CREATE TABLE IF NOT EXISTS dw.fact_stock_prices_elt (
    fact_stock_id    serial PRIMARY KEY,
    stock_id         INT,
    exchange_id      INT,
    date_id          INT,

    open_price       NUMERIC(20,6),
    high_price       NUMERIC(20,6),
    low_price        NUMERIC(20,6),
    close_price      NUMERIC(20,6),
    volume           NUMERIC(30,6),

    price_change     NUMERIC(20,6),
    price_change_pct NUMERIC(10,4),
    avg_price        NUMERIC(20,6),
    is_bullish_day   BOOLEAN
);

-- ----------------------------
-- Fact: User Trades Elt
-- ----------------------------

CREATE TABLE IF NOT EXISTS dw.fact_trades_elt (
    fact_trade_id    serial PRIMARY KEY,
    user_key         INT,

    asset_symbol     VARCHAR(20),
    asset_type       VARCHAR(10),
    date_id          INT,
    trade_type       VARCHAR(10) CHECK (trade_type IN ('BUY','SELL')),

    quantity         NUMERIC(30,6),
    price_usd        NUMERIC(20,6),
    total_usd        NUMERIC(25,2),
    exchange_id      INT,
    region_key       INT,

    trade_value_usd  NUMERIC(25,2)
);

-- -------------------
-- Loading ELT Tables
-- -------------------
INSERT INTO dw.dim_date_elt (
    date_id, full_date, day_of_week, day, month, month_name, quarter, year
)
SELECT DISTINCT
    TO_CHAR(TO_TIMESTAMP(PriceDate, 'DD-MM-YY HH24:MI'), 'YYYYMMDD')::int AS date_id,
    TO_TIMESTAMP(PriceDate, 'DD-MM-YY HH24:MI')::date AS full_date,
    TO_CHAR(TO_TIMESTAMP(PriceDate, 'DD-MM-YY HH24:MI'), 'Day') AS day_of_week,
    EXTRACT(DAY FROM TO_TIMESTAMP(PriceDate, 'DD-MM-YY HH24:MI'))::int AS day,
    EXTRACT(MONTH FROM TO_TIMESTAMP(PriceDate, 'DD-MM-YY HH24:MI'))::int AS month,
    TO_CHAR(TO_TIMESTAMP(PriceDate, 'DD-MM-YY HH24:MI'), 'Month') AS month_name,
    EXTRACT(QUARTER FROM TO_TIMESTAMP(PriceDate, 'DD-MM-YY HH24:MI'))::int AS quarter,
    EXTRACT(YEAR FROM TO_TIMESTAMP(PriceDate, 'DD-MM-YY HH24:MI'))::int AS year
FROM dw.raw_crypto_prices
WHERE PriceDate IS NOT NULL
ON CONFLICT (date_id) DO NOTHING;



INSERT INTO dw.dim_date_elt (
    date_id, full_date, day_of_week, day, month, month_name, quarter, year
)
SELECT DISTINCT
    TO_CHAR(
        CASE 
            WHEN PriceDate LIKE '%/%' THEN TO_DATE(PriceDate, 'MM/DD/YYYY')
            ELSE TO_DATE(PriceDate, 'DD-MM-YY')
        END, 'YYYYMMDD'
    )::int AS date_id,
    CASE 
        WHEN PriceDate LIKE '%/%' THEN TO_DATE(PriceDate, 'MM/DD/YYYY')
        ELSE TO_DATE(PriceDate, 'DD-MM-YY')
    END AS full_date,
    TO_CHAR(
        CASE 
            WHEN PriceDate LIKE '%/%' THEN TO_DATE(PriceDate, 'MM/DD/YYYY')
            ELSE TO_DATE(PriceDate, 'DD-MM-YY')
        END, 'Day'
    ) AS day_of_week,
    EXTRACT(DAY FROM 
        CASE 
            WHEN PriceDate LIKE '%/%' THEN TO_DATE(PriceDate, 'MM/DD/YYYY')
            ELSE TO_DATE(PriceDate, 'DD-MM-YY')
        END
    )::int AS day,
    EXTRACT(MONTH FROM 
        CASE 
            WHEN PriceDate LIKE '%/%' THEN TO_DATE(PriceDate, 'MM/DD/YYYY')
            ELSE TO_DATE(PriceDate, 'DD-MM-YY')
        END
    )::int AS month,
    TO_CHAR(
        CASE 
            WHEN PriceDate LIKE '%/%' THEN TO_DATE(PriceDate, 'MM/DD/YYYY')
            ELSE TO_DATE(PriceDate, 'DD-MM-YY')
        END, 'Month'
    ) AS month_name,
    EXTRACT(QUARTER FROM 
        CASE 
            WHEN PriceDate LIKE '%/%' THEN TO_DATE(PriceDate, 'MM/DD/YYYY')
            ELSE TO_DATE(PriceDate, 'DD-MM-YY')
        END
    )::int AS quarter,
    EXTRACT(YEAR FROM 
        CASE 
            WHEN PriceDate LIKE '%/%' THEN TO_DATE(PriceDate, 'MM/DD/YYYY')
            ELSE TO_DATE(PriceDate, 'DD-MM-YY')
        END
    )::int AS year
FROM dw.raw_stock_prices
WHERE PriceDate IS NOT NULL
ON CONFLICT (date_id) DO NOTHING;


INSERT INTO dw.dim_date_elt (
    date_id, full_date, day_of_week, day, month, month_name, quarter, year
)
SELECT DISTINCT
    TO_CHAR(TO_DATE(TradeDate, 'YYYY-MM-DD'), 'YYYYMMDD')::int AS date_id,
    TO_DATE(TradeDate, 'YYYY-MM-DD') AS full_date,
    TO_CHAR(TO_DATE(TradeDate, 'YYYY-MM-DD'), 'Day') AS day_of_week,
    EXTRACT(DAY FROM TO_DATE(TradeDate, 'YYYY-MM-DD'))::int AS day,
    EXTRACT(MONTH FROM TO_DATE(TradeDate, 'YYYY-MM-DD'))::int AS month,
    TO_CHAR(TO_DATE(TradeDate, 'YYYY-MM-DD'), 'Month') AS month_name,
    EXTRACT(QUARTER FROM TO_DATE(TradeDate, 'YYYY-MM-DD'))::int AS quarter,
    EXTRACT(YEAR FROM TO_DATE(TradeDate, 'YYYY-MM-DD'))::int AS year
FROM dw.raw_user_trades
WHERE TradeDate IS NOT NULL
ON CONFLICT (date_id) DO NOTHING;



INSERT INTO dw.dim_region_elt (region_key, country, continent, timezone)
SELECT DISTINCT
    regionkey::int,
    INITCAP(TRIM(country)),
    INITCAP(TRIM(continent)),
    UPPER(TRIM(timezone))
FROM dw.raw_region
WHERE country IS NOT NULL AND country <> '';



INSERT INTO dw.dim_exchange_elt (exchange_id, exchange_name)
SELECT DISTINCT
    exchangeid::int,
    INITCAP(TRIM(exchangeName))
FROM dw.raw_exchange
WHERE exchangename IS NOT NULL AND exchangename <> '';



INSERT INTO dw.dim_crypto_info_elt (crypto_id, symbol, symbol_name, launch_year, max_supply, sample_marketcap)
SELECT DISTINCT
    cryptoid::int,
    UPPER(TRIM(symbol)),
    INITCAP(TRIM(symbolname)),
    NULLIF(launchyear, '')::int,
    COALESCE(NULLIF(maxsupply, '')::numeric, 0),
    COALESCE(NULLIF(samplemarketcap, '')::numeric, 0)
FROM dw.raw_crypto_info
WHERE symbol IS NOT NULL AND symbol <> '';



INSERT INTO dw.dim_stock_info_elt (stock_id, symbol, company_name, sector, ipo_year, shares_outstanding, marketcap)
SELECT DISTINCT
    stockid::int,
    UPPER(TRIM(symbol)),
    INITCAP(TRIM(companyname)),
    INITCAP(TRIM(sector)),
    NULLIF(ipoyear, '')::int,
    COALESCE(NULLIF(sharesoutstanding, '')::numeric, 0),
    COALESCE(NULLIF(marketcap, '')::numeric, 0)
FROM dw.raw_stock_info
WHERE symbol IS NOT NULL AND symbol <> '';


INSERT INTO dw.dim_user_info_elt (user_key, user_id, user_name, email, registration_date, risk_profile, region_key)
SELECT DISTINCT
    userkey::int,
    TRIM(userid),
    INITCAP(TRIM(username)),
    LOWER(TRIM(email)),
    NULLIF(registrationdate, '')::date,
    INITCAP(TRIM(riskprofile)),
    NULLIF(regionkey, '')::int
FROM dw.raw_user_info
WHERE userid IS NOT NULL AND userid <> '';



INSERT INTO dw.dim_crypto_prices_elt (
    cryptoprice_id, name, symbol, price_date, high_price, low_price, open_price, close_price, volume, marketcap, crypto_id
)
SELECT DISTINCT
    row_number() OVER () AS cryptoprice_id,
    INITCAP(TRIM(name)),
    UPPER(TRIM(symbol)),
    TO_TIMESTAMP(pricedate, 'DD-MM-YY HH24:MI')::date AS price_date,
    COALESCE(NULLIF(REPLACE(highprice, '$', ''), '')::numeric, 0),
    COALESCE(NULLIF(REPLACE(lowprice, '$', ''), '')::numeric, 0),
    COALESCE(NULLIF(REPLACE(openprice, '$', ''), '')::numeric, 0),
    COALESCE(NULLIF(REPLACE(closeprice, '$', ''), '')::numeric, 0),
    COALESCE(NULLIF(REPLACE(volume, '$', ''), '')::numeric, 0),
    COALESCE(NULLIF(REPLACE(marketcap, '$', ''), '')::numeric, 0),
    NULLIF(cryptoid, '')::int
FROM dw.raw_crypto_prices
WHERE pricedate IS NOT NULL;



INSERT INTO dw.dim_stock_prices_elt (
    stockprice_id, price_date, close_price, volume, open_price, high_price, low_price, symbol, stock_id
)
SELECT DISTINCT
    row_number() OVER () AS stockprice_id,
    NULLIF(pricedate, '')::date,
    COALESCE(NULLIF(REPLACE(closeprice, '$', ''), '')::numeric, 0),
    COALESCE(NULLIF(REPLACE(volume, '$', ''), '')::numeric, 0),
    COALESCE(NULLIF(REPLACE(openprice, '$', ''), '')::numeric, 0),
    COALESCE(NULLIF(REPLACE(highprice, '$', ''), '')::numeric, 0),
    COALESCE(NULLIF(REPLACE(lowprice, '$', ''), '')::numeric, 0),
    UPPER(TRIM(symbol)),
    NULLIF(stockid, '')::int
FROM dw.raw_stock_prices
WHERE symbol IS NOT NULL AND symbol <> '';


-- -----------------------
-- LOADING ELT FACT TABLES
-- -----------------------
INSERT INTO dw.fact_crypto_prices_elt (
    crypto_id, exchange_id, date_id,
    open_price, high_price, low_price, close_price, volume, market_cap,
    price_change, price_change_pct, avg_price, is_bullish_day
)
SELECT 
    ci.crypto_id,
    NULL AS exchange_id,
    d.date_id,

    cp.open_price,
    cp.high_price,
    cp.low_price,
    cp.close_price,
    cp.volume,
    cp.marketcap,

    (cp.close_price - cp.open_price) AS price_change,
    CASE 
        WHEN cp.open_price = 0 THEN NULL
        ELSE ((cp.close_price - cp.open_price) / cp.open_price) * 100 
    END AS price_change_pct,
    (cp.open_price + cp.high_price + cp.low_price + cp.close_price) / 4 AS avg_price,
    (cp.close_price > cp.open_price) AS is_bullish_day

FROM dw.raw_crypto_prices stg
JOIN dw.dim_crypto_info_elt ci 
    ON ci.crypto_id = stg.cryptoid::int
JOIN dw.dim_crypto_prices_elt cp 
    ON cp.crypto_id = ci.crypto_id
   AND cp.price_date = TO_TIMESTAMP(stg.pricedate, 'DD-MM-YY HH24:MI')::date
JOIN dw.dim_date_elt d 
    ON d.full_date = cp.price_date;



INSERT INTO dw.fact_stock_prices_elt (
    stock_id, exchange_id, date_id,
    open_price, high_price, low_price, close_price, volume,
    price_change, price_change_pct, avg_price, is_bullish_day
)
SELECT
    si.stock_id,
    NULL AS exchange_id,
    d.date_id,

    sp.open_price,
    sp.high_price,
    sp.low_price,
    sp.close_price,
    sp.volume,

    (sp.close_price - sp.open_price) AS price_change,
    CASE 
        WHEN sp.open_price = 0 THEN NULL
        ELSE ((sp.close_price - sp.open_price) / sp.open_price) * 100 
    END AS price_change_pct,
    (sp.open_price + sp.high_price + sp.low_price + sp.close_price) / 4 AS avg_price,
    (sp.close_price > sp.open_price) AS is_bullish_day

FROM dw.raw_stock_prices stg
JOIN dw.dim_stock_info_elt si 
    ON si.stock_id = stg.stockid::int
JOIN dw.dim_stock_prices_elt sp 
    ON sp.stock_id = si.stock_id
   AND sp.price_date = stg.pricedate::date
JOIN dw.dim_date_elt d 
    ON d.full_date = sp.price_date;



INSERT INTO dw.fact_trades_elt (
    user_key, asset_symbol, asset_type, date_id, trade_type,
    quantity, price_usd, total_usd, exchange_id, region_key, trade_value_usd
)
SELECT
    u.user_key,
    UPPER(TRIM(s.assetSymbol)),
    INITCAP(s.assetType),
    d.date_id,
    UPPER(TRIM(s.tradeType)),

    s.quantity::numeric,
    s.priceUSD::numeric,
    s.totalUSD::numeric,

    e.exchange_id,
    r.region_key,

    (s.quantity::numeric * s.priceUSD::numeric) AS trade_value_usd

FROM dw.raw_user_trades s
JOIN dw.dim_user_info_elt u 
    ON u.user_key = s.userKey::int
JOIN dw.dim_date_elt d 
    ON d.full_date = s.tradeDate::date
LEFT JOIN dw.dim_exchange_elt e 
    ON UPPER(TRIM(s.exchange)) = UPPER(TRIM(e.exchange_name))
LEFT JOIN dw.dim_region_elt r 
    ON INITCAP(TRIM(s.region)) = INITCAP(TRIM(r.country));


-- -------------------
-- VALIDATION QUERIES
-- -------------------

--FACT TABLES Count VALIDATION
SELECT 'fact_trades' AS table, COUNT(*) AS etl_count FROM dw.fact_trades
UNION ALL
SELECT 'fact_trades_elt', COUNT(*) FROM dw.fact_trades_elt
UNION ALL
SELECT 'fact_crypto_prices', COUNT(*) FROM dw.fact_crypto_prices
UNION ALL
SELECT 'fact_crypto_prices_elt', COUNT(*) FROM dw.fact_crypto_prices_elt
UNION ALL
SELECT 'fact_stock_prices', COUNT(*) FROM dw.fact_stock_prices
UNION ALL
SELECT 'fact_stock_prices_elt', COUNT(*) FROM dw.fact_stock_prices_elt;

--DIMENSION TABLES Count VALIDATION
SELECT 'dim_region' AS table, COUNT(*) AS etl_count FROM dw.dim_region
UNION ALL SELECT 'dim_region_elt', COUNT(*) FROM dw.dim_region_elt

UNION ALL SELECT 'dim_exchange', COUNT(*) FROM dw.dim_exchange
UNION ALL SELECT 'dim_exchange_elt', COUNT(*) FROM dw.dim_exchange_elt

UNION ALL SELECT 'dim_crypto_info', COUNT(*) FROM dw.dim_crypto_info
UNION ALL SELECT 'dim_crypto_info_elt', COUNT(*) FROM dw.dim_crypto_info_elt

UNION ALL SELECT 'dim_stock_info', COUNT(*) FROM dw.dim_stock_info
UNION ALL SELECT 'dim_stock_info_elt', COUNT(*) FROM dw.dim_stock_info_elt

UNION ALL SELECT 'dim_user_info', COUNT(*) FROM dw.dim_user_info
UNION ALL SELECT 'dim_user_info_elt', COUNT(*) FROM dw.dim_user_info_elt

UNION ALL SELECT 'dim_crypto_prices', COUNT(*) FROM dw.dim_crypto_prices
UNION ALL SELECT 'dim_crypto_prices_elt', COUNT(*) FROM dw.dim_crypto_prices_elt

UNION ALL SELECT 'dim_stock_prices', COUNT(*) FROM dw.dim_stock_prices
UNION ALL SELECT 'dim_stock_prices_elt', COUNT(*) FROM dw.dim_stock_prices_elt

UNION ALL SELECT 'dim_date', COUNT(*) FROM dw.dim_date
UNION ALL SELECT 'dim_date_elt', COUNT(*) FROM dw.dim_date_elt;



-- FACT CRYPTO VALIDATION
SELECT 
    'fact_crypto_prices' AS table_name,
    COUNT(*) AS row_count,
    SUM(open_price) AS sum_open,
    SUM(high_price) AS sum_high,
    SUM(low_price) AS sum_low,
    SUM(close_price) AS sum_close,
    SUM(volume) AS sum_volume,
    SUM(market_cap) AS sum_marketcap,
    SUM(price_change) AS sum_price_change,
    SUM(price_change_pct) AS sum_price_change_pct,
    SUM(avg_price) AS sum_avg_price,
    SUM(CASE WHEN is_bullish_day THEN 1 ELSE 0 END) AS bullish_days
FROM dw.fact_crypto_prices

UNION ALL

SELECT 
    'fact_crypto_prices_elt' AS table_name,
    COUNT(*) AS row_count,
    SUM(open_price) AS sum_open,
    SUM(high_price) AS sum_high,
    SUM(low_price) AS sum_low,
    SUM(close_price) AS sum_close,
    SUM(volume) AS sum_volume,
    SUM(market_cap) AS sum_marketcap,
    SUM(price_change) AS sum_price_change,
    SUM(price_change_pct) AS sum_price_change_pct,
    SUM(avg_price) AS sum_avg_price,
    SUM(CASE WHEN is_bullish_day THEN 1 ELSE 0 END) AS bullish_days
FROM dw.fact_crypto_prices_elt;





-- FACT STOCK VALIDATION
SELECT 
    'fact_stock_prices' AS table_name,
    COUNT(*) AS row_count,
    SUM(open_price) AS sum_open,
    SUM(high_price) AS sum_high,
    SUM(low_price) AS sum_low,
    SUM(close_price) AS sum_close,
    SUM(volume) AS sum_volume,
    SUM(price_change) AS sum_price_change,
    SUM(price_change_pct) AS sum_price_change_pct,
    SUM(avg_price) AS sum_avg_price,
    SUM(CASE WHEN is_bullish_day THEN 1 ELSE 0 END) AS bullish_days
FROM dw.fact_stock_prices

UNION ALL

SELECT 
    'fact_stock_prices_elt' AS table_name,
    COUNT(*) AS row_count,
    SUM(open_price) AS sum_open,
    SUM(high_price) AS sum_high,
    SUM(low_price) AS sum_low,
    SUM(close_price) AS sum_close,
    SUM(volume) AS sum_volume,
    SUM(price_change) AS sum_price_change,
    SUM(price_change_pct) AS sum_price_change_pct,
    SUM(avg_price) AS sum_avg_price,
    SUM(CASE WHEN is_bullish_day THEN 1 ELSE 0 END) AS bullish_days
FROM dw.fact_stock_prices_elt;



-- FACT TRADES VALIDATION
SELECT 
    'fact_trades' AS table_name,
    COUNT(*) AS row_count,
    SUM(quantity) AS total_quantity,
    SUM(price_usd) AS total_price_usd,
    SUM(total_usd) AS total_sum,
    SUM(trade_value_usd) AS total_trade_value
FROM dw.fact_trades

UNION ALL

SELECT 
    'fact_trades_elt' AS table_name,
    COUNT(*) AS row_count,
    SUM(quantity) AS total_quantity,
    SUM(price_usd) AS total_price_usd,
    SUM(total_usd) AS total_sum,
    SUM(trade_value_usd) AS total_trade_value
FROM dw.fact_trades_elt;







