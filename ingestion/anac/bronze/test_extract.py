from unittest.mock import patch, MagicMock
from extract import extract


@patch("extract.boto3.client")
@patch("extract.requests.get")
def test_extract_uploads_to_s3(mock_get, mock_boto):
    mock_response = MagicMock()
    mock_get.return_value = mock_response

    mock_s3 = MagicMock()
    mock_boto.return_value = mock_s3

    extract("http://fake-url.com/file.csv", "pasta/arquivo.csv")

    mock_s3.upload_fileobj.assert_called_once_with(
        mock_response.raw, "anac-raw-dev", "pasta/arquivo.csv"
    )
