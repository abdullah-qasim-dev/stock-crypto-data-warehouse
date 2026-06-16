-- -------------------------
-- STAGING SCHEMA IMPLEMENTATION
-- -------------------------
CREATE SCHEMA IF NOT EXISTS staging;


-- Region Dimension (staging)
CREATE TABLE IF NOT EXISTS staging.stg_region (
    RegionKey TEXT,
    Country TEXT,
    Continent TEXT,
    TimeZone TEXT
);

-- Exchange Dimension (staging)
CREATE TABLE IF NOT EXISTS staging.stg_exchange (
    ExchangeID TEXT,
    ExchangeName TEXT
);

-- Crypto Info Dimension (staging)
CREATE TABLE IF NOT EXISTS staging.stg_crypto_info (
    CryptoID TEXT,
    Symbol TEXT,
    SymbolName TEXT,
    LaunchYear TEXT,
    MaxSupply TEXT,
    SampleMarketCap TEXT
);

-- Stock Info Dimension (staging)
CREATE TABLE IF NOT EXISTS staging.stg_stock_info (
    StockID TEXT,
    Symbol TEXT,
    CompanyName TEXT,
    Sector TEXT,
    IPOYear TEXT,
    SharesOutstanding TEXT,
    MarketCap TEXT
);

-- User Info Dimension (staging)
CREATE TABLE IF NOT EXISTS staging.stg_user_info (
    UserKey TEXT,
    UserID TEXT,
    UserName TEXT,
    Email TEXT,
    RegistrationDate TEXT,
    RiskProfile TEXT,
    RegionKey TEXT
);

-- Crypto Prices Dimension (staging)
CREATE TABLE IF NOT EXISTS staging.stg_crypto_prices (
    CryptoPriceID TEXT,
    Name TEXT,
    Symbol TEXT,
    PriceDate TEXT,
    HighPrice TEXT,
    LowPrice TEXT,
    OpenPrice TEXT,
    ClosePrice TEXT,
    Volume TEXT,
    MarketCap TEXT,
    CryptoID TEXT
);

-- Stock Prices Dimension (staging)
CREATE TABLE IF NOT EXISTS staging.stg_stock_prices (
    PriceDate TEXT,
    ClosePrice TEXT,
    Volume TEXT,
    OpenPrice TEXT,
    HighPrice TEXT,
    LowPrice TEXT,
    Symbol TEXT,
    StockID TEXT
);

-- -------------------------
-- USER TRADES STAGING TABLE
-- -------------------------
CREATE TABLE IF NOT EXISTS staging.stg_user_trades (
    TradeKey TEXT,
    UserKey TEXT,
    AssetSymbol TEXT,
    AssetType TEXT,
    TradeDate TEXT,
    TradeType TEXT,
    Quantity TEXT,
    PriceUSD TEXT,
    TotalUSD TEXT,
    Exchange TEXT,
    Region TEXT
);

--Loading Dimension Date from Crypto Prices
INSERT INTO dw.dim_date (
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
FROM staging.stg_crypto_prices
WHERE PriceDate IS NOT NULL
ON CONFLICT (date_id) DO NOTHING;



--Loading Dimension Date from Stock Prices
INSERT INTO dw.dim_date (
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
FROM staging.stg_stock_prices
WHERE PriceDate IS NOT NULL
ON CONFLICT (date_id) DO NOTHING;


--Loading Dimension Date from User Trades

INSERT INTO dw.dim_date (
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
FROM staging.stg_user_trades
WHERE TradeDate IS NOT NULL
ON CONFLICT (date_id) DO NOTHING;


--Loading Dimension Region
INSERT INTO dw.dim_region (region_key, country, continent, timezone)
SELECT DISTINCT
    regionkey::int,
    INITCAP(TRIM(country)),
    INITCAP(TRIM(continent)),
    UPPER(TRIM(timezone))
FROM staging.stg_region
WHERE country IS NOT NULL AND country <> '';


--Loading Dimension Exchange

INSERT INTO dw.dim_exchange (exchange_id, exchange_name)
SELECT DISTINCT
    exchangeid::int,
    INITCAP(TRIM(exchangeName))
FROM staging.stg_exchange
WHERE exchangename IS NOT NULL AND exchangename <> '';


--Loading Dimension Crypto Prices

INSERT INTO dw.dim_crypto_info (crypto_id, symbol, symbol_name, launch_year, max_supply, sample_marketcap)
SELECT DISTINCT
    cryptoid::int,
    UPPER(TRIM(symbol)),
    INITCAP(TRIM(symbolname)),
    NULLIF(launchyear, '')::int,
    COALESCE(NULLIF(maxsupply, '')::numeric, 0),
    COALESCE(NULLIF(samplemarketcap, '')::numeric, 0)
FROM staging.stg_crypto_info
WHERE symbol IS NOT NULL AND symbol <> '';


--Loading Dimension Stock Info
INSERT INTO dw.dim_stock_info (stock_id, symbol, company_name, sector, ipo_year, shares_outstanding, marketcap)
SELECT DISTINCT
    stockid::int,
    UPPER(TRIM(symbol)),
    INITCAP(TRIM(companyname)),
    INITCAP(TRIM(sector)),
    NULLIF(ipoyear, '')::int,
    COALESCE(NULLIF(sharesoutstanding, '')::numeric, 0),
    COALESCE(NULLIF(marketcap, '')::numeric, 0)
FROM staging.stg_stock_info
WHERE symbol IS NOT NULL AND symbol <> '';


--Loading Dimension User Info
INSERT INTO dw.dim_user_info (user_key, user_id, user_name, email, registration_date, risk_profile, region_key)
SELECT DISTINCT
    userkey::int,
    TRIM(userid),
    INITCAP(TRIM(username)),
    LOWER(TRIM(email)),
    NULLIF(registrationdate, '')::date,
    INITCAP(TRIM(riskprofile)),
    NULLIF(regionkey, '')::int
FROM staging.stg_user_info
WHERE userid IS NOT NULL AND userid <> '';



--Loading Dimension Crypto Prices

INSERT INTO dw.dim_crypto_prices (
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
FROM staging.stg_crypto_prices
WHERE pricedate IS NOT NULL;


--Loading Dimension Stock Prices
INSERT INTO dw.dim_stock_prices (
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
FROM staging.stg_stock_prices
WHERE symbol IS NOT NULL AND symbol <> '';



-- -------------------------
-- LOAD Fact Tables
-- -------------------------

--Loading Fact Crypto Prices
INSERT INTO dw.fact_crypto_prices (
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

FROM staging.stg_crypto_prices stg
JOIN dw.dim_crypto_info ci 
    ON ci.crypto_id = stg.cryptoid::int
JOIN dw.dim_crypto_prices cp 
    ON cp.crypto_id = ci.crypto_id
   AND cp.price_date = TO_TIMESTAMP(stg.pricedate, 'DD-MM-YY HH24:MI')::date
JOIN dw.dim_date d 
    ON d.full_date = cp.price_date;



--Loading Fact Stock Prices
INSERT INTO dw.fact_stock_prices (
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

FROM staging.stg_stock_prices stg
JOIN dw.dim_stock_info si 
    ON si.stock_id = stg.stockid::int
JOIN dw.dim_stock_prices sp 
    ON sp.stock_id = si.stock_id
   AND sp.price_date = stg.pricedate::date
JOIN dw.dim_date d 
    ON d.full_date = sp.price_date;



--Loading Fact Trades
INSERT INTO dw.fact_trades (
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
FROM staging.stg_user_trades s
JOIN dw.dim_user_info u 
    ON u.user_key = s.userKey::int
JOIN dw.dim_date d 
    ON d.full_date = s.tradeDate::date
LEFT JOIN dw.dim_exchange e 
    ON UPPER(TRIM(s.exchange)) = UPPER(TRIM(e.exchange_name))
LEFT JOIN dw.dim_region r 
    ON INITCAP(TRIM(s.region)) = INITCAP(TRIM(r.country));



