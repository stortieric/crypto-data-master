import boto3
import time
import requests
import os
from datetime import datetime

def insert_icons(event, context):

    size = "256"
    url = f"https://rest.coinapi.io/v1/assets/icons/{size}"
    api_key = os.environ['COIN_API_KEY']

    headers = {
        'Accept': 'application/json',
        'X-CoinAPI-Key': api_key
    }

    response = requests.get(url, headers=headers)
    
    if response.status_code != 200:
        print(f"Erro ao chamar a API: {response.status_code} - {response.text}")
        return {
            'statusCode': response.status_code,
            'body': response.text
        }
    
    assets_data = response.json()
    athena_client = boto3.client('athena')
    output_location = 's3://bronze-iceberg-data/output/'

    for asset in assets_data:

        asset_id = asset.get("asset_id")
        asset_url = asset.get("url")
        load_date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        query = f"""
        INSERT INTO crypto_db.crypto_assets (asset_id, url, load_date)
        VALUES ('{asset_id}', '{asset_url}', TIMESTAMP '{load_date}');
        """

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
        print(f'Início da execucao da query de insercao: {query}, Id da Execucao: {execution_id}')

        while True:
            response = athena_client.get_query_execution(QueryExecutionId=execution_id)
            status = response['QueryExecution']['Status']['State']
            print(f"Query de insercao \"{query}\" status: {status}")

            if status in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
                break
            time.sleep(1)

    return {
        'statusCode': 200,
        'body': 'Dados inseridos com sucesso na tabela Iceberg!'
    }
