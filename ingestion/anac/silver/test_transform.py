import io
import pandas as pd
from unittest.mock import MagicMock
from transform import (
    normalize_column_names,
    read_bronze,
    transform,
    write_silver,
)


def test_transform_strips_whitespace():
    df = pd.DataFrame({"EMPRESA": ["  GOL  ", " LATAM "]})
    result = transform(df)
    assert result["EMPRESA"].tolist() == ["GOL", "LATAM"]


def test_transform_converts_date_columns():
    df = pd.DataFrame({"DATA_REF": ["01/01/2024", "15/06/2023"]})
    result = transform(df)
    assert pd.api.types.is_datetime64_any_dtype(result["DATA_REF"])


def test_transform_ignores_mixed_columns():
    df = pd.DataFrame({"EMPRESA": ["GOL", "01/01/2024"]})
    result = transform(df)
    assert not pd.api.types.is_datetime64_any_dtype(result["EMPRESA"])


def test_transform_preserves_numeric_columns():
    df = pd.DataFrame({"PASSAGEIROS": [100, 200, 300]})
    result = transform(df)
    assert result["PASSAGEIROS"].tolist() == [100, 200, 300]


def test_read_bronze_parses_csv():
    mock_s3 = MagicMock()
    # First line is ANAC metadata row (skipped via skiprows=1)
    csv_content = b"Atualizado em: 2026-10-24\nEMPRESA;DATA_REF\nGOL;01/01/2024\nLATAM;-\n"
    mock_s3.get_object.return_value = {"Body": io.BytesIO(csv_content)}

    df = read_bronze(mock_s3, "anac-raw-dev", "test.csv")

    assert list(df.columns) == ["EMPRESA", "DATA_REF"]
    assert df["EMPRESA"].iloc[0] == "GOL"
    assert pd.isna(df["DATA_REF"].iloc[1])


def test_normalize_column_names():
    df = pd.DataFrame({
        "EMPRESA (SIGLA)": ["GOL"],
        "MÊS": [1],
        "DISTÂNCIA VOADA (KM)": [100.0],
        "PASSAGEIROS GRÁTIS": [5],
    })
    result = normalize_column_names(df)
    assert list(result.columns) == [
        "empresa_sigla",
        "mes",
        "distancia_voada_km",
        "passageiros_gratis",
    ]


def test_write_silver_calls_put_object():
    mock_s3 = MagicMock()
    df = pd.DataFrame({"EMPRESA": ["GOL"], "PASSAGEIROS": [100]})

    write_silver(mock_s3, df, "anac-silver-dev", "test.parquet")

    mock_s3.put_object.assert_called_once()
    call_kwargs = mock_s3.put_object.call_args.kwargs
    assert call_kwargs["Bucket"] == "anac-silver-dev"
    assert call_kwargs["Key"] == "test.parquet"
