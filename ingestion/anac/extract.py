import boto3
import requests
from botocore.client import Config

MINIO_ENDPOINT = "http://localhost:9000"
MINIO_ACCESS_KEY = "minioadmin"
MINIO_SECRET_KEY = "minioadmin"
BUCKET_NAME = "anac-raw" #ajuste


def get_s3_client():
    return boto3.client(
        "s3",
        endpoint_url=MINIO_ENDPOINT,
        aws_access_key_id=MINIO_ACCESS_KEY,
        aws_secret_access_key=MINIO_SECRET_KEY,
        config=Config(signature_version="s3v4"),
    )


def extract(url: str, s3_key: str):
    response = requests.get(url, stream=True)
    response.raise_for_status()

    s3 = get_s3_client()
    s3.upload_fileobj(response.raw, BUCKET_NAME, s3_key)
    print(f"Uploaded {s3_key} to {BUCKET_NAME}")


if __name__ == "__main__":
    url = "https://sistemas.anac.gov.br/dadosabertos/Voos%20e%20opera%C3%A7%C3%B5es%20a%C3%A9reas/Dados%20Estat%C3%ADsticos%20do%20Transporte%20A%C3%A9reo/Dados_Estatisticos.csv"
    s3_key = "dados_estatisticos/Dados_Estatisticos.csv"
    extract(url, s3_key)
