from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

with DAG(
    dag_id="anac_pipeline",
    description="Extrai dados da ANAC (bronze), transforma em Parquet (silver) e agrega em Athena (gold)",
    start_date=datetime(2025, 11, 5),
    schedule_interval="0 4 * * *",
    catchup=False,
    tags=["anac", "bronze", "silver", "gold"],
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

    gold = BashOperator(
        task_id="gold_dbt",
        bash_command="cd /opt/airflow/dbt && python -m dbt run --profiles-dir /opt/airflow/dbt",
        env={"DBT_TARGET": "dev", "DBT_ENV": "dev"},
        retries=1,
    )

    bronze >> silver >> gold
