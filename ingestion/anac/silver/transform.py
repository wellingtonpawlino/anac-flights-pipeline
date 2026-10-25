import io
import os
import re
import unicodedata

import boto3
import pandas as pd

BRONZE_BUCKET = os.environ.get("BRONZE_BUCKET", "anac-raw-dev")
SILVER_BUCKET = os.environ.get("SILVER_BUCKET", "anac-silver-dev")
BRONZE_KEY = "dados_estatisticos/Dados_Estatisticos.csv"
SILVER_KEY = "dados_estatisticos/Dados_Estatisticos.parquet"

NULL_VALUES = ["-", "--", "–", "—", "N/A", "n/a", ""]


def get_s3_client():
    return boto3.client("s3")


def read_bronze(s3_client, bucket: str, key: str) -> pd.DataFrame:
    response = s3_client.get_object(Bucket=bucket, Key=key)
    return pd.read_csv(
        io.BytesIO(response["Body"].read()),
        encoding="utf-8-sig",
        sep=";",
        skiprows=1,
        decimal=",",
        na_values=NULL_VALUES,
        keep_default_na=True,
    )


def transform(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()

    str_cols = df.select_dtypes(include=["object"]).columns
    df[str_cols] = df[str_cols].apply(lambda col: col.str.strip())

    for col in str_cols:
        sample = df[col].dropna().head(100)
        is_date = sample.str.match(r"^\d{2}/\d{2}/\d{4}$").all()
        if len(sample) > 0 and is_date:
            df[col] = pd.to_datetime(
                df[col], format="%d/%m/%Y", errors="coerce"
            )

    return df


def normalize_column_names(df: pd.DataFrame) -> pd.DataFrame:
    def _normalize(col: str) -> str:
        col = col.strip().lower()
        col = unicodedata.normalize("NFKD", col)
        col = col.encode("ascii", errors="ignore").decode("ascii")
        col = re.sub(r"[^a-z0-9]+", "_", col)
        return col.strip("_")

    df.columns = [_normalize(c) for c in df.columns]
    return df


def write_silver(s3_client, df: pd.DataFrame, bucket: str, key: str):
    buffer = io.BytesIO()
    df.to_parquet(buffer, index=False, engine="pyarrow")
    buffer.seek(0)
    s3_client.put_object(Bucket=bucket, Key=key, Body=buffer.getvalue())
    print(f"Written {key} to {bucket}")


def run():
    s3 = get_s3_client()
    df = read_bronze(s3, BRONZE_BUCKET, BRONZE_KEY)
    df = transform(df)
    df = normalize_column_names(df)
    write_silver(s3, df, SILVER_BUCKET, SILVER_KEY)


if __name__ == "__main__":
    run()
