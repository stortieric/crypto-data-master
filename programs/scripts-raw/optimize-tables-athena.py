import json
import boto3
import time

glue_client = boto3.client('glue')
athena_client = boto3.client('athena')

def run_athena_optimize(query, database):

    output_location = 's3://bronze-iceberg-data/output/'

    query_id = athena_client.start_query_execution(
        QueryString=query,
        QueryExecutionContext={
            'Database': database
        },
        ResultConfiguration={
            'OutputLocation': output_location
        }
    )['QueryExecutionId']

    while True:
        response = athena_client.get_query_execution(QueryExecutionId=query_id)
        state = response['QueryExecution']['Status']['State']
        if state in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
            break
        time.sleep(1)

    return response

def optimize_tables(event, context):

    databases = glue_client.get_databases()
    
    for database in databases['DatabaseList']:
        db_name = database['Name']
        tables = glue_client.get_tables(DatabaseName=db_name)

        for table in tables['TableList']:
            table_name = table['Name']

            optimize_query = f"OPTIMIZE {db_name}.{table_name} REWRITE DATA USING BIN_PACK"
            result = run_athena_optimize(optimize_query, db_name)
            print(f"Executa otimizacao para tabela: {db_name}.{table_name}, Resultado: {result}")