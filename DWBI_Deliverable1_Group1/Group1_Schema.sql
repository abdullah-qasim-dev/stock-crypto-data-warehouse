-- -------------------------
-- DATA WAREHOUSE SCHEMA
-- -------------------------

-- Creating DW schema
CREATE SCHEMA IF NOT EXISTS dw;

-- -------------------------
-- DIMENSION TABLES
-- -------------------------

-- 1) Date dimension
CREATE TABLE IF NOT EXISTS dw.dim_date (
    date_id       INT PRIMARY KEY,
    full_date     DATE NOT NULL UNIQUE,
    day_of_week   VARCHAR(10),
    day           INT,
    month         INT,
    month_name    VARCHAR(20),
    quarter       INT,
    year          INT
);

-- 2) Region dimension
CREATE TABLE IF NOT EXISTS dw.dim_region (
    region_key    INT PRIMARY KEY,
    country       VARCHAR(100) NOT NULL UNIQUE,
    continent     VARCHAR(50),
    timezone      VARCHAR(30)
);

-- 3) Exchange dimension
CREATE TABLE IF NOT EXISTS dw.dim_exchange (
    exchange_id   INT PRIMARY KEY,
    exchange_name VARCHAR(100) UNIQUE NOT NULL
);

-- 4) Crypto Info dimension
CREATE TABLE IF NOT EXISTS dw.dim_crypto_info (
    crypto_id        INT PRIMARY KEY,
    symbol           VARCHAR(20) UNIQUE NOT NULL,
    symbol_name      VARCHAR(150),
    launch_year      INT,
    max_supply       NUMERIC(30,0),
    sample_marketcap NUMERIC(30,2)
);

-- 5) Stock Info dimension
CREATE TABLE IF NOT EXISTS dw.dim_stock_info (
    stock_id           INT PRIMARY KEY,
    symbol             VARCHAR(20) UNIQUE NOT NULL,
    company_name       VARCHAR(150),
    sector             VARCHAR(100),
    ipo_year           INT,
    shares_outstanding NUMERIC(30,0),
    marketcap          NUMERIC(30,2)
);

-- 6) User Info dimension
CREATE TABLE IF NOT EXISTS dw.dim_user_info (
    user_key          INT PRIMARY KEY,
    user_id           VARCHAR(50) UNIQUE,
    user_name         VARCHAR(150),
    email             VARCHAR(100),
    registration_date DATE,
    risk_profile      VARCHAR(30),
    region_key        INT
);

-- 7) Crypto Prices dimension
CREATE TABLE IF NOT EXISTS dw.dim_crypto_prices (
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

-- 8) Stock Prices dimension
CREATE TABLE IF NOT EXISTS dw.dim_stock_prices (
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

-- -------------------------
-- FACT TABLES
-- -------------------------

-- Fact: Crypto Prices
CREATE TABLE IF NOT EXISTS dw.fact_crypto_prices (
    fact_crypto_id   serial PRIMARY KEY,
    crypto_id        INT REFERENCES dw.dim_crypto_info(crypto_id),
    exchange_id      INT REFERENCES dw.dim_exchange(exchange_id),
    date_id          INT REFERENCES dw.dim_date(date_id),
    open_price       NUMERIC(20,6),
    high_price       NUMERIC(20,6),
    low_price        NUMERIC(20,6),
    close_price      NUMERIC(20,6),
    volume           NUMERIC(30,6),
    market_cap       NUMERIC(30,2),

    -- Derived Metrics
    price_change     NUMERIC(20,6),
    price_change_pct NUMERIC(10,4),
    avg_price        NUMERIC(20,6),
    is_bullish_day   BOOLEAN
);

-- Fact: Stock Prices
CREATE TABLE IF NOT EXISTS dw.fact_stock_prices (
    fact_stock_id    serial PRIMARY KEY,
    stock_id         INT REFERENCES dw.dim_stock_info(stock_id),
    exchange_id      INT REFERENCES dw.dim_exchange(exchange_id),
    date_id          INT REFERENCES dw.dim_date(date_id),
    open_price       NUMERIC(20,6),
    high_price       NUMERIC(20,6),
    low_price        NUMERIC(20,6),
    close_price      NUMERIC(20,6),
    volume           NUMERIC(30,6),

    -- Derived Metrics
    price_change     NUMERIC(20,6),
    price_change_pct NUMERIC(10,4),
    avg_price        NUMERIC(20,6),
    is_bullish_day   BOOLEAN
);

-- Fact: User Trades
CREATE TABLE IF NOT EXISTS dw.fact_trades (
    fact_trade_id    serial PRIMARY KEY,
    user_key         INT REFERENCES dw.dim_user_info(user_key),
    asset_symbol     VARCHAR(20),
    asset_type       VARCHAR(10),
    date_id          INT REFERENCES dw.dim_date(date_id),
    trade_type       VARCHAR(10) CHECK (trade_type IN ('BUY','SELL')),
    quantity         NUMERIC(30,6),
    price_usd        NUMERIC(20,6),
    total_usd        NUMERIC(25,2),
    exchange_id      INT REFERENCES dw.dim_exchange(exchange_id),
    region_key       INT REFERENCES dw.dim_region(region_key),

    -- Derived Metric
    trade_value_usd  NUMERIC(25,2)
);
