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
        "'optimize_rewrite_delete_file_threshold'='10');"
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