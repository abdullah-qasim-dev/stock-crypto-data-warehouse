-- Group 1 - Schema Justification File
-- Deliverable 2: Schema Implementation (Extended)

-- =============================================================
-- PRIMARY KEY JUSTIFICATION
-- =============================================================

-- dim_date.date_id
-- Unique numeric key for each calendar day ensures fast lookups and joins.

-- dim_region.region_key
-- Surrogate key uniquely identifies each region without relying on text fields.

-- dim_exchange.exchange_id
-- Exchange ID ensures each market/exchange is uniquely identifiable.

-- dim_crypto_info.crypto_id
-- Surrogate key ensures each cryptocurrency has a unique identifier.

-- dim_stock_info.stock_id
-- Surrogate key to uniquely identify each stock/company.

-- dim_user_info.user_key
-- Unique user surrogate key avoids issues with changing natural IDs (emails/usernames).

-- dim_crypto_prices.cryptoprice_id
-- Unique key for each crypto daily price record.

-- dim_stock_prices.stockprice_id
-- Unique key for each stock daily price record.

-- fact_crypto_prices.fact_crypto_id
-- Surrogate key ensures each crypto price fact row is uniquely tracked.

-- fact_stock_prices.fact_stock_id
-- Surrogate key ensures each stock price fact record is unique.

-- fact_trades.fact_trade_id
-- Surrogate key uniquely identifies each trade transaction.


-- =============================================================
-- FOREIGN KEY JUSTIFICATION
-- =============================================================

-- fact_crypto_prices.crypto_id → dim_crypto_info.crypto_id
-- Links price data to the corresponding crypto asset.

-- fact_crypto_prices.exchange_id → dim_exchange.exchange_id
-- Ensures exchange reference consistency.

-- fact_crypto_prices.date_id → dim_date.date_id
-- Enables time-series analytics and historical reporting.

-- fact_stock_prices.stock_id → dim_stock_info.stock_id
-- Connects stock price fact data to stock metadata.

-- fact_stock_prices.exchange_id → dim_exchange.exchange_id
-- Ensures exchange consistency in stock price records.

-- fact_stock_prices.date_id → dim_date.date_id
-- Enables time-based stock analytics.

-- fact_trades.user_key → dim_user_info.user_key
-- Connects every trade to a valid system user.

-- fact_trades.date_id → dim_date.date_id
-- Allows time-based trade analysis.

-- fact_trades.exchange_id → dim_exchange.exchange_id
-- Ensures valid market context for each trade.

-- fact_trades.region_key → dim_region.region_key
-- Ties trades to user geography/market region.


-- =============================================================
-- INDEX RECOMMENDATIONS (3 KEY COLUMNS)
-- =============================================================

-- 1) dim_date.date_id / fact tables date_id
-- Date-based filtering & time-series analysis will be very common.

-- 2) dim_crypto_info.symbol & dim_stock_info.symbol
-- Symbols (BTC, ETH, AAPL, etc.) will be frequently searched & joined.

-- 3) fact_trades.user_key
-- User-level trade analysis and segmentation will run frequently.


