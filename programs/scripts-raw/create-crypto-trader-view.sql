CREATE OR REPLACE VIEW crypto_db.crypto_trader_view AS
SELECT  t.document_id,
        t.asset_id,
        t.asset_type,
        a.url,
        q.price_crypto,
        t.quantity,
        q.price_crypto * t.quantity AS total_price_transaction,
        t.trade_type,
        t.transaction_timestamp
FROM    crypto_db.crypto_trader t
INNER JOIN crypto_db.crypto_quote q
    ON  t.asset_id = q.asset_id
        AND t.asset_type = q.asset_type
        AND t.transaction_timestamp BETWEEN q.start_window AND q.end_window
INNER JOIN crypto_db.crypto_assets a
    ON  q.asset_id = a.asset_id
        AND CAST(a.load_date AS DATE) >= (SELECT MAX(CAST(load_date AS DATE)) FROM crypto_db.crypto_assets);