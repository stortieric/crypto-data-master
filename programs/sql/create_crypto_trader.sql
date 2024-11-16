CREATE TABLE crypto_db.crypto_trader (
    transaction_id BIGINT,
    asset_id STRING,
    asset_type STRING,
    transaction_timestamp TIMESTAMP,
    trade_type STRING,
    quantity INT,
    ref_date DATE
) 
PARTITIONED BY (ref_date)
LOCATION 's3://bronze-iceberg-data/tables/crypto_trader/'
TBLPROPERTIES (
    'table_type' = 'ICEBERG',
    'format' = 'parquet',
    'write_compression' = 'snappy',
    'optimize_rewrite_delete_file_threshold'='10'
);