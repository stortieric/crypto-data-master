CREATE TABLE crypto_db.crypto_assets (
    asset_id STRING,
    url STRING,
    load_date TIMESTAMP
)
LOCATION 's3://bronze-iceberg-data/tables/crypto_assets/'
TBLPROPERTIES (
    'table_type' = 'ICEBERG',
    'format' = 'parquet',
    'write_compression' = 'snappy',
    'optimize_rewrite_delete_file_threshold'='10'
);