import json
import boto3
import time

def create_tables(event, context):
    athena_client = boto3.client('athena')

    queries = [
        "CREATE TABLE crypto_db.crypto_assets ("
        "asset_id STRING, "
        "url STRING, "
        "load_date TIMESTAMP) "
        "LOCATION 's3://bronze-iceberg-data/tables/crypto_assets/' "
        "TBLPROPERTIES ("
        "'table_type' = 'ICEBERG', "
        "'format' = 'parquet', "
        "'write_compression' = 'snappy', "
        "'optimize_rewrite_delete_file_threshold'='10');",

        "CREATE TABLE crypto_db.crypto_quote ("
        "asset_id STRING, "
        "asset_type STRING, "
        "start_window TIMESTAMP, "
        "end_window TIMESTAMP, "
        "price_crypto DOUBLE, "
        "ref_date DATE) "
        "PARTITIONED BY (ref_date) "
        "LOCATION 's3://bronze-iceberg-data/tables/crypto_quote/' "
        "TBLPROPERTIES ("
        "'table_type' = 'ICEBERG', "
        "'format' = 'parquet', "
        "'write_compression' = 'snappy', "
        "'optimize_rewrite_delete_file_threshold'='10');",

        "CREATE TABLE crypto_db.crypto_trader ("
        "transaction_id BIGINT, "
        "document_id STRING, "
        "asset_id STRING, "
        "asset_type STRING, "
        "transaction_timestamp TIMESTAMP, "
        "trade_type STRING, "
        "quantity INT, "
        "ref_date DATE) "
        "PARTITIONED BY (ref_date) "
        "LOCATION 's3://bronze-iceberg-data/tables/crypto_trader/' "
        "TBLPROPERTIES ("
        "'table_type' = 'ICEBERG', "
        "'format' = 'parquet', "
        "'write_compression' = 'snappy', "
        "'optimize_rewrite_delete_file_threshold'='10');",

        """
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
        """
    ]
    
    output_location = 's3://bronze-iceberg-data/output/'

    for query in queries:
        response = athena_client.start_query_execution(
            QueryString=query,
            QueryExecutionContext={
                'Database': 'crypto_db'
            },
            ResultConfiguration={
                'OutputLocation': output_location
            }
        )
        
        execution_id = response['QueryExecutionId']
        print(f'Inicio da execucao da query: {query}, Id da Execucao: {execution_id}')

        while True:
            response = athena_client.get_query_execution(QueryExecutionId=execution_id)
            status = response['QueryExecution']['Status']['State']
            print(f"Query \"{query}\" status: {status}")

            if status in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
                break
            time.sleep(1)

    return {
        'statusCode': 200,
        'body': json.dumps('Queries executadas com sucesso!')
    }