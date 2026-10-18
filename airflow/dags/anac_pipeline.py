from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

with DAG(
    dag_id="anac_pipeline",
    description="Extrai dados da ANAC (bronze) e transforma em Parquet (silver)",
    start_date=datetime(2025, 11, 5),
    schedule_interval="0 4 * * *",
    catchup=False,
    tags=["anac", "bronze", "silver"],
) as dag:

    bronze = BashOperator(
        task_id="bronze_extract",
        bash_command="python /opt/airflow/ingestion/anac/bronze/extract.py",
        retries=3,
    )

    silver = BashOperator(
        task_id="silver_transform",
        bash_command="python /opt/airflow/ingestion/anac/silver/transform.py",
        retries=2,
    )

    bronze >> silver
