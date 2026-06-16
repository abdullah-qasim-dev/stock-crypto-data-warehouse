-- Test file just
CREATE TABLE stocks (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(10),
    price DECIMAL(10,2),
    date DATE
);