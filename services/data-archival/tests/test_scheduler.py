"""
Unit tests for Archival Scheduler
"""
import pytest
from datetime import datetime, timedelta
from unittest.mock import Mock, MagicMock, patch, call

from ..scheduler import ArchivalScheduler
from ..storage_client import ArchiveMetadata
from ..config import Config, DatabaseConfig, S3Config, ArchivalConfig


class TestArchivalScheduler:
    """Test suite for ArchivalScheduler"""

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
            ),
            archival=ArchivalConfig(
                hot_retention_days=90,
                schedule_cron="0 2 1 * *",  # Monthly at 2 AM
                tables_to_archive=["acm_alerts", "audit_events"],
            ),
        )

    @pytest.fixture
    def mock_archival_service(self):
        """Create mock archival service"""
        mock_service = MagicMock()
        return mock_service

    @pytest.fixture
    def scheduler(self, test_config, mock_archival_service):
        """Create scheduler with mocked dependencies"""
        with patch("psycopg2.connect"), \
             patch("boto3.client"), \
             patch.object(ArchivalScheduler, "_setup_event_listeners"):
            scheduler = ArchivalScheduler(test_config)
            scheduler.archival_service = mock_archival_service
            return scheduler

    def test_init_creates_scheduler(self, test_config):
        """Test initialization creates background scheduler"""
        with patch("psycopg2.connect"), \
             patch("boto3.client"):
            scheduler = ArchivalScheduler(test_config)

            assert scheduler.config == test_config
            assert scheduler.scheduler is not None
            assert hasattr(scheduler, "archival_service")

    def test_setup_event_listeners(self, test_config):
        """Test event listeners are configured"""
        with patch("psycopg2.connect"), \
             patch("boto3.client"):
            scheduler = ArchivalScheduler(test_config)

            # Verify listeners added (2 listeners: executed and error)
            assert len(scheduler.scheduler._listeners) == 2

    def test_start_schedules_jobs(self, scheduler):
        """Test start() schedules all jobs"""
        # Mock scheduler.add_job
        with patch.object(scheduler.scheduler, "add_job") as mock_add_job, \
             patch.object(scheduler.scheduler, "start") as mock_start, \
             patch.object(scheduler.scheduler, "get_jobs", return_value=[]):
            scheduler.start()

            # Verify all 3 jobs were added
            assert mock_add_job.call_count == 3

            # Verify job IDs
            call_ids = [call_args[1]["id"] for call_args in mock_add_job.call_args_list]
            assert "monthly_archival" in call_ids
            assert "daily_cleanup" in call_ids
            assert "weekly_stats" in call_ids

            # Verify scheduler started
            mock_start.assert_called_once()

    def test_stop_shuts_down_scheduler(self, scheduler, mock_archival_service):
        """Test stop() shuts down scheduler and closes service"""
        with patch.object(scheduler.scheduler, "shutdown") as mock_shutdown:
            scheduler.stop()

            # Verify scheduler shutdown
            mock_shutdown.assert_called_once_with(wait=True)

            # Verify archival service closed
            mock_archival_service.close.assert_called_once()

    def test_run_archival_job_success(self, scheduler, mock_archival_service, test_config):
        """Test successful archival job execution"""
        # Mock archive metadata
        metadata1 = ArchiveMetadata(
            archive_id="archive-1",
            table_name="acm_alerts",
            partition_key="2024-01",
            record_count=100,
            original_size_bytes=5000,
            compressed_size_bytes=1250,
            compression_type="zstd",
            created_at=datetime.utcnow().isoformat(),
            checksum_sha256="abc123",
            s3_key="archives/archive-1.zstd",
            retention_until=(datetime.utcnow() + timedelta(days=365)).isoformat(),
        )

        metadata2 = ArchiveMetadata(
            archive_id="archive-2",
            table_name="audit_events",
            partition_key="2024-01",
            record_count=200,
            original_size_bytes=10000,
            compressed_size_bytes=2500,
            compression_type="zstd",
            created_at=datetime.utcnow().isoformat(),
            checksum_sha256="def456",
            s3_key="archives/archive-2.zstd",
            retention_until=(datetime.utcnow() + timedelta(days=365)).isoformat(),
        )

        # Mock archive_table to return metadata
        mock_archival_service.archive_table.side_effect = [metadata1, metadata2]

        # Execute job
        scheduler._run_archival_job()

        # Verify archive_table called for each table
        assert mock_archival_service.archive_table.call_count == 2

        # Verify correct tables archived
        call_args_list = mock_archival_service.archive_table.call_args_list
        tables_archived = [call_args[1]["table_name"] for call_args in call_args_list]
        assert "acm_alerts" in tables_archived
        assert "audit_events" in tables_archived

        # Verify cutoff date calculation
        for call_args in call_args_list:
            cutoff_date = call_args[1]["cutoff_date"]
            expected_cutoff = datetime.utcnow() - timedelta(days=test_config.archival.hot_retention_days)
            # Allow 1-second tolerance for test execution time
            assert abs((cutoff_date - expected_cutoff).total_seconds()) < 2

    def test_run_archival_job_no_data(self, scheduler, mock_archival_service):
        """Test archival job when no data to archive"""
        # Mock archive_table to return None (no data)
        mock_archival_service.archive_table.return_value = None

        # Execute job
        scheduler._run_archival_job()

        # Verify archive_table still called
        assert mock_archival_service.archive_table.call_count == 2

    def test_run_archival_job_partial_failure(self, scheduler, mock_archival_service):
        """Test archival job continues after table failure"""
        # Mock first table success, second table failure
        metadata = ArchiveMetadata(
            archive_id="archive-1",
            table_name="acm_alerts",
            partition_key="2024-01",
            record_count=100,
            original_size_bytes=5000,
            compressed_size_bytes=1250,
            compression_type="zstd",
            created_at=datetime.utcnow().isoformat(),
            checksum_sha256="abc123",
            s3_key="archives/archive-1.zstd",
            retention_until=(datetime.utcnow() + timedelta(days=365)).isoformat(),
        )

        mock_archival_service.archive_table.side_effect = [
            metadata,
            Exception("S3 upload failed"),
        ]

        # Execute job (should not raise exception)
        scheduler._run_archival_job()

        # Verify both tables attempted
        assert mock_archival_service.archive_table.call_count == 2

    def test_run_cleanup_job_success(self, scheduler, mock_archival_service):
        """Test successful cleanup job execution"""
        # Mock delete_expired_archives
        mock_archival_service.delete_expired_archives.return_value = 5

        # Execute job
        scheduler._run_cleanup_job()

        # Verify deletion called
        mock_archival_service.delete_expired_archives.assert_called_once()

    def test_run_cleanup_job_failure(self, scheduler, mock_archival_service):
        """Test cleanup job handles failures"""
        # Mock deletion failure
        mock_archival_service.delete_expired_archives.side_effect = Exception("S3 error")

        # Execute job (should not raise exception)
        scheduler._run_cleanup_job()

        # Verify deletion was attempted
        mock_archival_service.delete_expired_archives.assert_called_once()

    def test_log_retention_statistics(self, scheduler, mock_archival_service):
        """Test retention statistics logging"""
        # Mock statistics
        mock_stats = {
            "total_archives": 10,
            "total_archived_records": 5000,
            "total_compressed_size_mb": 125.5,
            "total_original_size_mb": 500.0,
            "compression_ratio": 0.75,
            "by_table": {
                "acm_alerts": {
                    "archive_count": 5,
                    "record_count": 2500,
                    "compressed_size_mb": 62.75,
                    "original_size_mb": 250.0,
                },
                "audit_events": {
                    "archive_count": 5,
                    "record_count": 2500,
                    "compressed_size_mb": 62.75,
                    "original_size_mb": 250.0,
                },
            },
        }

        mock_archival_service.get_retention_statistics.return_value = mock_stats

        # Execute job
        scheduler._log_retention_statistics()

        # Verify statistics retrieved
        mock_archival_service.get_retention_statistics.assert_called_once()

    def test_log_retention_statistics_failure(self, scheduler, mock_archival_service):
        """Test statistics logging handles failures"""
        # Mock failure
        mock_archival_service.get_retention_statistics.side_effect = Exception("DB error")

        # Execute job (should not raise exception)
        scheduler._log_retention_statistics()

        # Verify attempt was made
        mock_archival_service.get_retention_statistics.assert_called_once()

    def test_trigger_manual_archival_success(self, scheduler, mock_archival_service):
        """Test manual archival trigger"""
        # Mock successful archival
        metadata = ArchiveMetadata(
            archive_id="manual-archive-123",
            table_name="acm_alerts",
            partition_key="2024-01",
            record_count=50,
            original_size_bytes=2500,
            compressed_size_bytes=625,
            compression_type="zstd",
            created_at=datetime.utcnow().isoformat(),
            checksum_sha256="xyz789",
            s3_key="archives/manual-archive-123.zstd",
            retention_until=(datetime.utcnow() + timedelta(days=365)).isoformat(),
        )

        mock_archival_service.archive_table.return_value = metadata

        # Trigger manual archival
        cutoff_date = datetime(2024, 1, 1)
        archive_id = scheduler.trigger_manual_archival("acm_alerts", cutoff_date)

        # Verify success
        assert archive_id == "manual-archive-123"

        # Verify archive_table called with correct parameters
        mock_archival_service.archive_table.assert_called_once_with(
            table_name="acm_alerts",
            partition_key="2024-01",
            cutoff_date=cutoff_date,
        )

    def test_trigger_manual_archival_no_data(self, scheduler, mock_archival_service):
        """Test manual archival when no data exists"""
        # Mock no data to archive
        mock_archival_service.archive_table.return_value = None

        cutoff_date = datetime(2024, 1, 1)
        archive_id = scheduler.trigger_manual_archival("acm_alerts", cutoff_date)

        # Verify None returned
        assert archive_id is None

    def test_trigger_manual_archival_failure(self, scheduler, mock_archival_service):
        """Test manual archival failure handling"""
        # Mock archival failure
        mock_archival_service.archive_table.side_effect = Exception("Upload failed")

        cutoff_date = datetime(2024, 1, 1)
        archive_id = scheduler.trigger_manual_archival("acm_alerts", cutoff_date)

        # Verify None returned on failure
        assert archive_id is None

    def test_get_next_run_times(self, scheduler):
        """Test getting next run times for scheduled jobs"""
        # Mock jobs with next run times
        mock_job1 = Mock()
        mock_job1.id = "monthly_archival"
        mock_job1.next_run_time = datetime(2024, 3, 1, 2, 0)

        mock_job2 = Mock()
        mock_job2.id = "daily_cleanup"
        mock_job2.next_run_time = datetime(2024, 2, 5, 3, 0)

        with patch.object(scheduler.scheduler, "get_jobs", return_value=[mock_job1, mock_job2]):
            run_times = scheduler.get_next_run_times()

        # Verify correct mapping
        assert run_times["monthly_archival"] == mock_job1.next_run_time
        assert run_times["daily_cleanup"] == mock_job2.next_run_time

    def test_list_jobs(self, scheduler):
        """Test listing all scheduled jobs"""
        # Mock jobs
        mock_job1 = Mock()
        mock_job1.id = "monthly_archival"
        mock_job1.name = "Monthly Data Archival"
        mock_job1.next_run_time = datetime(2024, 3, 1, 2, 0)
        mock_job1.trigger = "cron[month='*', day='1', hour='2', minute='0']"

        mock_job2 = Mock()
        mock_job2.id = "daily_cleanup"
        mock_job2.name = "Daily Archive Cleanup"
        mock_job2.next_run_time = datetime(2024, 2, 5, 3, 0)
        mock_job2.trigger = "cron[day='*', hour='3', minute='0']"

        with patch.object(scheduler.scheduler, "get_jobs", return_value=[mock_job1, mock_job2]):
            jobs = scheduler.list_jobs()

        # Verify job list
        assert len(jobs) == 2

        # Verify first job
        assert jobs[0]["id"] == "monthly_archival"
        assert jobs[0]["name"] == "Monthly Data Archival"
        assert jobs[0]["next_run_time"] == mock_job1.next_run_time

        # Verify second job
        assert jobs[1]["id"] == "daily_cleanup"
        assert jobs[1]["name"] == "Daily Archive Cleanup"

    def test_partition_key_format(self, scheduler, mock_archival_service):
        """Test partition key follows YYYY-MM format"""
        metadata = ArchiveMetadata(
            archive_id="test",
            table_name="acm_alerts",
            partition_key="2024-01",
            record_count=1,
            original_size_bytes=100,
            compressed_size_bytes=25,
            compression_type="zstd",
            created_at=datetime.utcnow().isoformat(),
            checksum_sha256="abc",
            s3_key="archives/test.zstd",
            retention_until=(datetime.utcnow() + timedelta(days=365)).isoformat(),
        )

        mock_archival_service.archive_table.return_value = metadata

        # Trigger archival
        scheduler._run_archival_job()

        # Verify partition key format
        for call_args in mock_archival_service.archive_table.call_args_list:
            partition_key = call_args[1]["partition_key"]
            # Should match YYYY-MM format
            assert len(partition_key) == 7
            assert partition_key[4] == "-"
            year, month = partition_key.split("-")
            assert year.isdigit() and len(year) == 4
            assert month.isdigit() and len(month) == 2
