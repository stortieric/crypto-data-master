CREATE TABLE crypto_db.crypto_quote (
    asset_id STRING,
    asset_type STRING,
    start_window TIMESTAMP,
    end_window TIMESTAMP,
    price_crypto DOUBLE,
    ref_date DATE
) 
PARTITIONED BY (ref_date)
LOCATION 's3://bronze-iceberg-data/tables/crypto_quote/'
TBLPROPERTIES (
    'table_type' = 'ICEBERG',
    'format' = 'parquet',
    'write_compression' = 'snappy',
    'optimize_rewrite_delete_file_threshold'='10'
);