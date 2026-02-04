"""
Unit tests for Archival Service
"""
import json
import pytest
from datetime import datetime, timedelta
from unittest.mock import Mock, MagicMock, patch, call
from unittest import mock

from ..archival_service import ArchivalService
from ..storage_client import ArchiveMetadata
from ..config import Config, DatabaseConfig, S3Config, ArchivalConfig, CompressionType


class TestArchivalService:
    """Test suite for ArchivalService"""

    @pytest.fixture
    def test_config(self):
        """Create test configuration"""
        return Config(
            db=DatabaseConfig(
                host="localhost",
                port=5433,
                database="test_db",
                user="test_user",
                password="test_pass",
            ),
            s3=S3Config(
                endpoint_url="https://s3.test.com",
                access_key="test_key",
                secret_key="test_secret",
                bucket_name="test-bucket",
                region="us-east-1",
                use_ssl=True,
            ),
            archival=ArchivalConfig(
                hot_retention_days=90,
                cold_retention_years=7,
                compression=CompressionType.GZIP,
                chunk_size=100,
            ),
        )

    @pytest.fixture
    def mock_db_connection(self):
        """Create mock database connection"""
        mock_conn = MagicMock()
        mock_cursor = MagicMock()
        mock_conn.cursor.return_value.__enter__.return_value = mock_cursor
        return mock_conn, mock_cursor

    @pytest.fixture
    def archival_service(self, test_config, mock_db_connection):
        """Create ArchivalService with mocked dependencies"""
        mock_conn, mock_cursor = mock_db_connection

        with patch("psycopg2.connect", return_value=mock_conn), \
             patch("boto3.client"):
            service = ArchivalService(test_config)
            service.db_conn = mock_conn
            service._cursor = mock_cursor
            return service

    @pytest.fixture
    def sample_records(self):
        """Create sample database records"""
        return [
            {
                "id": 1,
                "detected_at": "2024-01-15T10:30:00",
                "gateway_id": "GW001",
                "is_fraud": True,
            },
            {
                "id": 2,
                "detected_at": "2024-01-16T11:45:00",
                "gateway_id": "GW002",
                "is_fraud": False,
            },
            {
                "id": 3,
                "detected_at": "2024-01-17T14:20:00",
                "gateway_id": "GW003",
                "is_fraud": True,
            },
        ]

    def test_init_creates_connections(self, test_config):
        """Test initialization creates database and storage connections"""
        with patch("psycopg2.connect") as mock_connect, \
             patch("boto3.client"):
            service = ArchivalService(test_config)

            # Verify database connection
            mock_connect.assert_called_once()
            call_kwargs = mock_connect.call_args.kwargs
            assert call_kwargs["host"] == test_config.db.host
            assert call_kwargs["port"] == test_config.db.port
            assert call_kwargs["database"] == test_config.db.database

    def test_get_date_column_returns_correct_column(self, archival_service):
        """Test date column mapping for different tables"""
        assert archival_service._get_date_column("acm_alerts") == "detected_at"
        assert archival_service._get_date_column("audit_events") == "created_at"
        assert archival_service._get_date_column("call_detail_records") == "call_start_time"
        assert archival_service._get_date_column("gateway_blacklist_history") == "created_at"
        assert archival_service._get_date_column("fraud_investigations") == "created_at"
        assert archival_service._get_date_column("unknown_table") == "created_at"  # Default

    def test_query_records_to_archive_success(
        self, archival_service, mock_db_connection, sample_records
    ):
        """Test querying records for archival"""
        mock_conn, mock_cursor = mock_db_connection
        mock_cursor.fetchall.return_value = sample_records

        cutoff_date = datetime(2024, 2, 1)
        result = archival_service._query_records_to_archive("acm_alerts", cutoff_date)

        # Verify query execution
        assert mock_cursor.execute.called
        execute_call = mock_cursor.execute.call_args
        assert "acm_alerts" in execute_call[0][0]
        assert "detected_at" in execute_call[0][0]
        assert execute_call[0][1][0] == cutoff_date

        # Verify results
        assert len(result) == len(sample_records)
        assert result[0]["id"] == 1

    def test_query_records_no_data(self, archival_service, mock_db_connection):
        """Test querying when no records exist"""
        mock_conn, mock_cursor = mock_db_connection
        mock_cursor.fetchall.return_value = []

        cutoff_date = datetime(2024, 2, 1)
        result = archival_service._query_records_to_archive("acm_alerts", cutoff_date)

        assert result == []

    def test_delete_archived_records_success(self, archival_service, mock_db_connection):
        """Test deletion of archived records"""
        mock_conn, mock_cursor = mock_db_connection
        mock_cursor.rowcount = 100

        cutoff_date = datetime(2024, 2, 1)
        deleted_count = archival_service._delete_archived_records("acm_alerts", cutoff_date)

        # Verify DELETE query execution
        assert mock_cursor.execute.called
        execute_call = mock_cursor.execute.call_args
        assert "DELETE FROM" in execute_call[0][0]
        assert "acm_alerts" in execute_call[0][0]

        # Verify commit
        assert mock_conn.commit.called

        # Verify count
        assert deleted_count == 100

    def test_archive_table_success(
        self, archival_service, mock_db_connection, sample_records
    ):
        """Test successful table archival"""
        mock_conn, mock_cursor = mock_db_connection
        mock_cursor.fetchall.return_value = sample_records
        mock_cursor.rowcount = len(sample_records)

        # Mock storage upload success
        with patch.object(archival_service.storage, "upload_archive", return_value=True):
            cutoff_date = datetime(2024, 2, 1)
            metadata = archival_service.archive_table(
                table_name="acm_alerts",
                partition_key="2024-01",
                cutoff_date=cutoff_date,
            )

        # Verify metadata returned
        assert metadata is not None
        assert metadata.table_name == "acm_alerts"
        assert metadata.partition_key == "2024-01"
        assert metadata.record_count == len(sample_records)
        assert metadata.original_size_bytes > 0
        assert metadata.compressed_size_bytes > 0
        assert metadata.checksum_sha256 is not None

        # Verify retention period (7 years)
        retention_until = datetime.fromisoformat(metadata.retention_until)
        created_at = datetime.fromisoformat(metadata.created_at)
        delta = retention_until - created_at
        assert delta.days >= 7 * 365 - 1  # Allow 1-day tolerance

    def test_archive_table_no_records(self, archival_service, mock_db_connection):
        """Test archival when no records to archive"""
        mock_conn, mock_cursor = mock_db_connection
        mock_cursor.fetchall.return_value = []

        cutoff_date = datetime(2024, 2, 1)
        metadata = archival_service.archive_table(
            table_name="acm_alerts",
            partition_key="2024-01",
            cutoff_date=cutoff_date,
        )

        # Should return None when no records
        assert metadata is None

    def test_archive_table_upload_failure(
        self, archival_service, mock_db_connection, sample_records
    ):
        """Test archival handling when S3 upload fails"""
        mock_conn, mock_cursor = mock_db_connection
        mock_cursor.fetchall.return_value = sample_records

        # Mock storage upload failure
        with patch.object(archival_service.storage, "upload_archive", return_value=False):
            cutoff_date = datetime(2024, 2, 1)
            metadata = archival_service.archive_table(
                table_name="acm_alerts",
                partition_key="2024-01",
                cutoff_date=cutoff_date,
            )

        # Should return None on upload failure
        assert metadata is None

        # Verify records were NOT deleted
        delete_query_found = False
        for call_args in mock_cursor.execute.call_args_list:
            if "DELETE FROM" in str(call_args):
                delete_query_found = True
                break
        assert not delete_query_found

    def test_archive_table_compression(
        self, archival_service, mock_db_connection, sample_records
    ):
        """Test that archival compresses data"""
        mock_conn, mock_cursor = mock_db_connection
        mock_cursor.fetchall.return_value = sample_records

        with patch.object(archival_service.storage, "upload_archive", return_value=True):
            cutoff_date = datetime(2024, 2, 1)
            metadata = archival_service.archive_table(
                table_name="acm_alerts",
                partition_key="2024-01",
                cutoff_date=cutoff_date,
            )

        # Verify compression occurred
        assert metadata.compressed_size_bytes < metadata.original_size_bytes
        compression_ratio = archival_service.compression.get_compression_ratio(
            metadata.original_size_bytes,
            metadata.compressed_size_bytes
        )
        assert compression_ratio > 0

    def test_restore_archive_success(self, archival_service, mock_db_connection):
        """Test successful archive restoration"""
        mock_conn, mock_cursor = mock_db_connection

        # Mock archive data
        test_records = [
            {"id": 1, "name": "Record 1"},
            {"id": 2, "name": "Record 2"},
        ]
        records_json = json.dumps(test_records)
        compressed_data = archival_service.compression.compress(records_json.encode("utf-8"))

        # Mock metadata
        import hashlib
        checksum = hashlib.sha256(compressed_data).hexdigest()
        metadata = ArchiveMetadata(
            archive_id="test-123",
            table_name="acm_alerts",
            partition_key="2024-01",
            record_count=2,
            original_size_bytes=len(records_json),
            compressed_size_bytes=len(compressed_data),
            compression_type="gzip",
            created_at=datetime.utcnow().isoformat(),
            checksum_sha256=checksum,
            s3_key="archives/test-123.gz",
            retention_until=(datetime.utcnow() + timedelta(days=365)).isoformat(),
        )

        # Mock storage operations
        with patch.object(archival_service.storage, "get_metadata", return_value=metadata), \
             patch.object(archival_service.storage, "download_archive", return_value=compressed_data):

            mock_cursor.rowcount = 1
            result = archival_service.restore_archive("test-123")

        # Verify restoration
        assert result is not None
        assert len(result) == 2
        assert result[0]["id"] == 1
        assert result[1]["id"] == 2

        # Verify INSERT queries executed
        assert mock_cursor.execute.called

    def test_restore_archive_metadata_not_found(self, archival_service):
        """Test restoration when metadata doesn't exist"""
        with patch.object(archival_service.storage, "get_metadata", return_value=None):
            result = archival_service.restore_archive("nonexistent-id")

        assert result is None

    def test_restore_archive_checksum_mismatch(self, archival_service):
        """Test restoration with corrupted archive (checksum mismatch)"""
        # Mock metadata with one checksum
        metadata = ArchiveMetadata(
            archive_id="test-123",
            table_name="acm_alerts",
            partition_key="2024-01",
            record_count=1,
            original_size_bytes=100,
            compressed_size_bytes=50,
            compression_type="gzip",
            created_at=datetime.utcnow().isoformat(),
            checksum_sha256="expected_checksum",
            s3_key="archives/test.gz",
            retention_until=(datetime.utcnow() + timedelta(days=365)).isoformat(),
        )

        # Mock download with different data (wrong checksum)
        corrupted_data = b"corrupted archive data"

        with patch.object(archival_service.storage, "get_metadata", return_value=metadata), \
             patch.object(archival_service.storage, "download_archive", return_value=corrupted_data):
            result = archival_service.restore_archive("test-123")

        # Restoration should fail due to checksum mismatch
        assert result is None

    def test_list_archives_for_table(self, archival_service):
        """Test listing archives for specific table"""
        # Mock S3 keys
        s3_keys = [
            "archives/acm_alerts/2024-01/archive1.zstd",
            "archives/acm_alerts/2024-02/archive2.zstd",
        ]

        # Mock metadata
        metadata_list = [
            ArchiveMetadata(
                archive_id="archive1",
                table_name="acm_alerts",
                partition_key="2024-01",
                record_count=100,
                original_size_bytes=5000,
                compressed_size_bytes=1250,
                compression_type="zstd",
                created_at=datetime.utcnow().isoformat(),
                checksum_sha256="abc123",
                s3_key=s3_keys[0],
                retention_until=(datetime.utcnow() + timedelta(days=365)).isoformat(),
            ),
            ArchiveMetadata(
                archive_id="archive2",
                table_name="acm_alerts",
                partition_key="2024-02",
                record_count=150,
                original_size_bytes=7500,
                compressed_size_bytes=1875,
                compression_type="zstd",
                created_at=datetime.utcnow().isoformat(),
                checksum_sha256="def456",
                s3_key=s3_keys[1],
                retention_until=(datetime.utcnow() + timedelta(days=365)).isoformat(),
            ),
        ]

        with patch.object(archival_service.storage, "list_archives", return_value=s3_keys), \
             patch.object(archival_service.storage, "get_metadata", side_effect=metadata_list):
            result = archival_service.list_archives_for_table("acm_alerts")

        # Verify results
        assert len(result) == 2
        assert all(m.table_name == "acm_alerts" for m in result)

    def test_get_retention_statistics(self, archival_service, test_config):
        """Test retention statistics calculation"""
        # Mock archives for different tables
        mock_archives = {
            "acm_alerts": [
                ArchiveMetadata(
                    archive_id="alert1",
                    table_name="acm_alerts",
                    partition_key="2024-01",
                    record_count=100,
                    original_size_bytes=1000000,
                    compressed_size_bytes=250000,
                    compression_type="zstd",
                    created_at=datetime.utcnow().isoformat(),
                    checksum_sha256="abc",
                    s3_key="archives/alert1.zstd",
                    retention_until=(datetime.utcnow() + timedelta(days=365)).isoformat(),
                ),
            ],
            "audit_events": [
                ArchiveMetadata(
                    archive_id="audit1",
                    table_name="audit_events",
                    partition_key="2024-01",
                    record_count=200,
                    original_size_bytes=2000000,
                    compressed_size_bytes=500000,
                    compression_type="zstd",
                    created_at=datetime.utcnow().isoformat(),
                    checksum_sha256="def",
                    s3_key="archives/audit1.zstd",
                    retention_until=(datetime.utcnow() + timedelta(days=365)).isoformat(),
                ),
            ],
        }

        def mock_list_archives(table_name):
            return mock_archives.get(table_name, [])

        with patch.object(
            archival_service,
            "list_archives_for_table",
            side_effect=mock_list_archives
        ):
            stats = archival_service.get_retention_statistics()

        # Verify overall statistics
        assert stats["total_archives"] == 2
        assert stats["total_archived_records"] == 300
        assert stats["total_compressed_size_mb"] > 0
        assert stats["total_original_size_mb"] > 0
        assert stats["compression_ratio"] > 0

        # Verify per-table statistics
        assert "acm_alerts" in stats["by_table"]
        assert stats["by_table"]["acm_alerts"]["archive_count"] == 1
        assert stats["by_table"]["acm_alerts"]["record_count"] == 100

    def test_delete_expired_archives(self, archival_service):
        """Test deletion of expired archives"""
        # Create expired archive metadata
        expired_metadata = ArchiveMetadata(
            archive_id="expired-123",
            table_name="acm_alerts",
            partition_key="2017-01",
            record_count=100,
            original_size_bytes=5000,
            compressed_size_bytes=1250,
            compression_type="zstd",
            created_at=(datetime.utcnow() - timedelta(days=8*365)).isoformat(),
            checksum_sha256="abc123",
            s3_key="archives/expired-123.zstd",
            retention_until=(datetime.utcnow() - timedelta(days=1)).isoformat(),  # Expired
        )

        # Mock archives list
        with patch.object(
            archival_service,
            "list_archives_for_table",
            return_value=[expired_metadata]
        ), patch.object(
            archival_service.storage,
            "delete_archive",
            return_value=True
        ) as mock_delete:
            deleted_count = archival_service.delete_expired_archives()

        # Verify deletion
        assert deleted_count == 1
        mock_delete.assert_called_once_with(
            expired_metadata.s3_key,
            expired_metadata.archive_id
        )

    def test_delete_expired_archives_none_expired(self, archival_service):
        """Test deletion when no archives are expired"""
        # Create non-expired archive
        active_metadata = ArchiveMetadata(
            archive_id="active-123",
            table_name="acm_alerts",
            partition_key="2024-01",
            record_count=100,
            original_size_bytes=5000,
            compressed_size_bytes=1250,
            compression_type="zstd",
            created_at=datetime.utcnow().isoformat(),
            checksum_sha256="abc123",
            s3_key="archives/active-123.zstd",
            retention_until=(datetime.utcnow() + timedelta(days=365)).isoformat(),  # Not expired
        )

        with patch.object(
            archival_service,
            "list_archives_for_table",
            return_value=[active_metadata]
        ), patch.object(
            archival_service.storage,
            "delete_archive",
            return_value=True
        ) as mock_delete:
            deleted_count = archival_service.delete_expired_archives()

        # Verify no deletion
        assert deleted_count == 0
        mock_delete.assert_not_called()

    def test_close_connection(self, archival_service, mock_db_connection):
        """Test closing database connection"""
        mock_conn, _ = mock_db_connection

        archival_service.close()

        # Verify connection closed
        mock_conn.close.assert_called_once()
