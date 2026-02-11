"""
Unit tests for S3 Storage Client
"""
import io
import json
import pytest
from datetime import datetime, timedelta
from unittest.mock import Mock, MagicMock, patch
from botocore.exceptions import ClientError

from ..storage_client import StorageClient, ArchiveMetadata
from ..config import S3Config, CompressionType


class TestStorageClient:
    """Test suite for StorageClient"""

    @pytest.fixture
    def s3_config(self):
        """Create test S3 configuration"""
        return S3Config(
            endpoint_url="https://s3.amazonaws.com",
            access_key="test_access_key",
            secret_key="test_secret_key",
            bucket_name="test-bucket",
            region="us-east-1",
            use_ssl=True,
        )

    @pytest.fixture
    def mock_s3_client(self):
        """Create mock S3 client"""
        mock = MagicMock()
        # Mock successful bucket check
        mock.head_bucket.return_value = {}
        return mock

    @pytest.fixture
    def storage_client(self, s3_config, mock_s3_client):
        """Create StorageClient with mocked S3 client"""
        with patch("boto3.client", return_value=mock_s3_client):
            client = StorageClient(s3_config)
            return client

    @pytest.fixture
    def sample_metadata(self):
        """Create sample archive metadata"""
        now = datetime.utcnow()
        retention_until = now + timedelta(days=7 * 365)
        return ArchiveMetadata(
            archive_id="test-archive-123",
            table_name="acm_alerts",
            partition_key="2024-01",
            record_count=1000,
            original_size_bytes=5000000,
            compressed_size_bytes=1250000,
            compression_type="zstd",
            created_at=now.isoformat(),
            checksum_sha256="abc123def456",
            s3_key="archives/acm_alerts/2024-01/test-archive-123.zstd",
            retention_until=retention_until.isoformat(),
        )

    def test_init_creates_s3_client(self, s3_config, mock_s3_client):
        """Test initialization creates S3 client with correct configuration"""
        with patch("boto3.client", return_value=mock_s3_client) as mock_boto:
            client = StorageClient(s3_config)

            # Verify boto3 client was created
            mock_boto.assert_called_once()
            call_kwargs = mock_boto.call_args.kwargs
            assert call_kwargs["endpoint_url"] == s3_config.endpoint_url
            assert call_kwargs["aws_access_key_id"] == s3_config.access_key
            assert call_kwargs["aws_secret_access_key"] == s3_config.secret_key
            assert call_kwargs["use_ssl"] == s3_config.use_ssl

    def test_ensure_bucket_exists_when_bucket_present(self, s3_config, mock_s3_client):
        """Test bucket existence check when bucket exists"""
        with patch("boto3.client", return_value=mock_s3_client):
            StorageClient(s3_config)
            mock_s3_client.head_bucket.assert_called_once_with(Bucket=s3_config.bucket_name)

    def test_ensure_bucket_creates_when_missing(self, s3_config, mock_s3_client):
        """Test bucket creation when bucket doesn't exist"""
        # Mock 404 error (bucket not found)
        mock_s3_client.head_bucket.side_effect = ClientError(
            {"Error": {"Code": "404"}}, "HeadBucket"
        )

        with patch("boto3.client", return_value=mock_s3_client):
            StorageClient(s3_config)
            mock_s3_client.create_bucket.assert_called_once()

    def test_upload_archive_success(self, storage_client, sample_metadata, mock_s3_client):
        """Test successful archive upload"""
        # Prepare test data
        test_data = b"compressed archive data"
        data_stream = io.BytesIO(test_data)

        # Execute upload
        result = storage_client.upload_archive(data_stream, sample_metadata)

        # Verify success
        assert result is True

        # Verify upload_fileobj was called
        assert mock_s3_client.upload_fileobj.called
        upload_call = mock_s3_client.upload_fileobj.call_args
        assert upload_call[0][1] == storage_client.config.bucket_name
        assert upload_call[0][2] == sample_metadata.s3_key

        # Verify metadata in S3 object
        extra_args = upload_call[1]["ExtraArgs"]
        assert extra_args["Metadata"]["archive-id"] == sample_metadata.archive_id
        assert extra_args["Metadata"]["table-name"] == sample_metadata.table_name
        assert extra_args["ServerSideEncryption"] == "AES256"

        # Verify metadata JSON was uploaded
        assert mock_s3_client.put_object.called
        metadata_call = mock_s3_client.put_object.call_args
        assert metadata_call[1]["Key"] == f"metadata/{sample_metadata.archive_id}.json"

    def test_upload_archive_failure(self, storage_client, sample_metadata, mock_s3_client):
        """Test archive upload failure handling"""
        # Mock upload failure
        mock_s3_client.upload_fileobj.side_effect = ClientError(
            {"Error": {"Code": "500", "Message": "Internal Server Error"}}, "UploadFileobj"
        )

        data_stream = io.BytesIO(b"test data")
        result = storage_client.upload_archive(data_stream, sample_metadata)

        # Verify failure is handled gracefully
        assert result is False

    def test_download_archive_success(self, storage_client, mock_s3_client):
        """Test successful archive download"""
        # Mock successful download
        test_data = b"archived data content"
        mock_response = {"Body": io.BytesIO(test_data)}
        mock_s3_client.get_object.return_value = mock_response

        # Execute download
        s3_key = "archives/acm_alerts/2024-01/test.zstd"
        result = storage_client.download_archive(s3_key)

        # Verify success
        assert result == test_data
        mock_s3_client.get_object.assert_called_once_with(
            Bucket=storage_client.config.bucket_name,
            Key=s3_key,
        )

    def test_download_archive_not_found(self, storage_client, mock_s3_client):
        """Test archive download when object not found"""
        # Mock 404 error
        mock_s3_client.get_object.side_effect = ClientError(
            {"Error": {"Code": "NoSuchKey"}}, "GetObject"
        )

        result = storage_client.download_archive("nonexistent-key")

        # Verify None is returned on failure
        assert result is None

    def test_get_metadata_success(self, storage_client, sample_metadata, mock_s3_client):
        """Test successful metadata retrieval"""
        # Mock metadata JSON in S3
        metadata_json = json.dumps({
            "archive_id": sample_metadata.archive_id,
            "table_name": sample_metadata.table_name,
            "partition_key": sample_metadata.partition_key,
            "record_count": sample_metadata.record_count,
            "original_size_bytes": sample_metadata.original_size_bytes,
            "compressed_size_bytes": sample_metadata.compressed_size_bytes,
            "compression_type": sample_metadata.compression_type,
            "created_at": sample_metadata.created_at,
            "checksum_sha256": sample_metadata.checksum_sha256,
            "s3_key": sample_metadata.s3_key,
            "retention_until": sample_metadata.retention_until,
        })

        mock_response = {"Body": io.BytesIO(metadata_json.encode("utf-8"))}
        mock_s3_client.get_object.return_value = mock_response

        # Execute
        result = storage_client.get_metadata(sample_metadata.archive_id)

        # Verify
        assert result is not None
        assert result.archive_id == sample_metadata.archive_id
        assert result.table_name == sample_metadata.table_name
        assert result.record_count == sample_metadata.record_count

    def test_get_metadata_not_found(self, storage_client, mock_s3_client):
        """Test metadata retrieval when not found"""
        # Mock 404 error
        mock_s3_client.get_object.side_effect = ClientError(
            {"Error": {"Code": "NoSuchKey"}}, "GetObject"
        )

        result = storage_client.get_metadata("nonexistent-archive")

        # Verify None is returned
        assert result is None

    def test_list_archives_success(self, storage_client, mock_s3_client):
        """Test listing archives with prefix"""
        # Mock S3 list response
        mock_response = {
            "Contents": [
                {"Key": "archives/acm_alerts/2024-01/archive1.zstd"},
                {"Key": "archives/acm_alerts/2024-01/archive2.zstd"},
                {"Key": "archives/acm_alerts/2024-02/archive3.zstd"},
            ]
        }
        mock_s3_client.list_objects_v2.return_value = mock_response

        # Execute
        prefix = "archives/acm_alerts/"
        result = storage_client.list_archives(prefix)

        # Verify
        assert len(result) == 3
        assert all(key.startswith(prefix) for key in result)
        mock_s3_client.list_objects_v2.assert_called_once_with(
            Bucket=storage_client.config.bucket_name,
            Prefix=prefix,
            MaxKeys=1000,
        )

    def test_list_archives_empty(self, storage_client, mock_s3_client):
        """Test listing archives when none exist"""
        # Mock empty response
        mock_s3_client.list_objects_v2.return_value = {}

        result = storage_client.list_archives("archives/nonexistent/")

        # Verify empty list
        assert result == []

    def test_delete_archive_success(self, storage_client, sample_metadata, mock_s3_client):
        """Test successful archive deletion"""
        # Execute deletion
        result = storage_client.delete_archive(
            sample_metadata.s3_key,
            sample_metadata.archive_id
        )

        # Verify success
        assert result is True

        # Verify both archive and metadata were deleted
        assert mock_s3_client.delete_object.call_count == 2
        delete_calls = mock_s3_client.delete_object.call_args_list

        # Check archive data deletion
        assert delete_calls[0][1]["Key"] == sample_metadata.s3_key

        # Check metadata deletion
        assert delete_calls[1][1]["Key"] == f"metadata/{sample_metadata.archive_id}.json"

    def test_delete_archive_failure(self, storage_client, mock_s3_client):
        """Test archive deletion failure handling"""
        # Mock deletion failure
        mock_s3_client.delete_object.side_effect = ClientError(
            {"Error": {"Code": "500"}}, "DeleteObject"
        )

        result = storage_client.delete_archive("test-key", "test-id")

        # Verify failure is handled gracefully
        assert result is False

    def test_get_archive_size_success(self, storage_client, mock_s3_client):
        """Test getting archive size without download"""
        # Mock head_object response
        expected_size = 1250000
        mock_s3_client.head_object.return_value = {"ContentLength": expected_size}

        # Execute
        s3_key = "archives/test.zstd"
        result = storage_client.get_archive_size(s3_key)

        # Verify
        assert result == expected_size
        mock_s3_client.head_object.assert_called_once_with(
            Bucket=storage_client.config.bucket_name,
            Key=s3_key,
        )

    def test_get_archive_size_not_found(self, storage_client, mock_s3_client):
        """Test getting size of non-existent archive"""
        # Mock 404 error
        mock_s3_client.head_object.side_effect = ClientError(
            {"Error": {"Code": "404"}}, "HeadObject"
        )

        result = storage_client.get_archive_size("nonexistent-key")

        # Verify None is returned
        assert result is None

    def test_verify_integrity_success(self, storage_client, mock_s3_client):
        """Test integrity verification with matching checksum"""
        import hashlib

        # Test data and its checksum
        test_data = b"archive data for integrity test"
        expected_checksum = hashlib.sha256(test_data).hexdigest()

        # Mock download
        mock_response = {"Body": io.BytesIO(test_data)}
        mock_s3_client.get_object.return_value = mock_response

        # Execute
        result = storage_client.verify_integrity("test-key", expected_checksum)

        # Verify success
        assert result is True

    def test_verify_integrity_mismatch(self, storage_client, mock_s3_client):
        """Test integrity verification with mismatched checksum"""
        # Mock download with data that won't match
        test_data = b"corrupted archive data"
        mock_response = {"Body": io.BytesIO(test_data)}
        mock_s3_client.get_object.return_value = mock_response

        # Execute with wrong checksum
        result = storage_client.verify_integrity("test-key", "wrong_checksum")

        # Verify failure
        assert result is False

    def test_verify_integrity_download_failure(self, storage_client, mock_s3_client):
        """Test integrity verification when download fails"""
        # Mock download failure
        mock_s3_client.get_object.side_effect = ClientError(
            {"Error": {"Code": "500"}}, "GetObject"
        )

        result = storage_client.verify_integrity("test-key", "any_checksum")

        # Verify failure
        assert result is False
