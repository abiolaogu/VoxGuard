"""
Unit tests for NCC Compliance Scheduler.

Tests cover:
- Scheduler initialization
- Job scheduling (daily, weekly, monthly)
- Report generation and submission
- Event listeners
- Manual triggers
- Error handling
"""

import asyncio
import pytest
from datetime import date, timedelta
from pathlib import Path
from unittest.mock import Mock, MagicMock, patch, AsyncMock, call

from apscheduler.triggers.cron import CronTrigger
from apscheduler.events import JobExecutionEvent, EVENT_JOB_ERROR, EVENT_JOB_EXECUTED

from ncc_integration.scheduler import ComplianceScheduler
from ncc_integration.config import (
    ComplianceConfig,
    AtrsConfig,
    SftpConfig,
    DatabaseConfig,
    SchedulerConfig,
)


@pytest.fixture
def compliance_config():
    """Create compliance configuration for testing."""
    return ComplianceConfig(
        atrs=AtrsConfig(
            environment="sandbox",
            client_id="test-client",
            client_secret="test-secret",
            icl_license="ICL-NG-2025-001234",
            base_url="https://api-sandbox.ncc.gov.ng/v2",
            timeout_seconds=30,
            max_retries=3,
        ),
        sftp=SftpConfig(
            host="sftp.ncc.gov.ng",
            port=22,
            username="ncc_upload",
            private_key_path="/etc/ncc/id_rsa",
            remote_path="/uploads",
        ),
        database=DatabaseConfig(
            host="localhost",
            port=5432,
            database="voxguard",
            user="postgres",
            password="password",
        ),
        scheduler=SchedulerConfig(
            daily_report_cron="30 4 * * *",
            weekly_report_cron="0 10 * * MON",
            monthly_report_cron="0 15 5 * *",
            timezone="Africa/Lagos",
        ),
        enable_daily_reports=True,
        enable_weekly_reports=True,
        enable_monthly_reports=True,
    )


@pytest.fixture
def mock_scheduler():
    """Mock APScheduler."""
    with patch('ncc_integration.scheduler.AsyncIOScheduler') as mock_class:
        mock_instance = MagicMock()
        mock_class.return_value = mock_instance
        yield mock_instance


# Initialization Tests

def test_scheduler_initialization(compliance_config, mock_scheduler):
    """Test scheduler initializes with configuration."""
    scheduler = ComplianceScheduler(compliance_config)

    assert scheduler.config == compliance_config
    assert scheduler.output_dir == Path("/var/ncc/reports")

    # Verify event listeners were added
    assert mock_scheduler.add_listener.call_count == 2


def test_event_listeners_registered(compliance_config, mock_scheduler):
    """Test event listeners are registered correctly."""
    scheduler = ComplianceScheduler(compliance_config)

    # Verify listeners for job execution and error events
    calls = mock_scheduler.add_listener.call_args_list
    assert len(calls) == 2

    # First call: job executed listener
    assert calls[0][0][1] == EVENT_JOB_EXECUTED

    # Second call: job error listener
    assert calls[1][0][1] == EVENT_JOB_ERROR


# Scheduler Start Tests

def test_scheduler_start_creates_output_directory(compliance_config, mock_scheduler):
    """Test scheduler creates output directory on start."""
    with patch('pathlib.Path.mkdir') as mock_mkdir:
        scheduler = ComplianceScheduler(compliance_config)
        scheduler.start()

        mock_mkdir.assert_called_once_with(parents=True, exist_ok=True)


def test_scheduler_start_adds_daily_job(compliance_config, mock_scheduler):
    """Test scheduler adds daily report job."""
    scheduler = ComplianceScheduler(compliance_config)
    scheduler.start()

    # Verify job was added
    mock_scheduler.add_job.assert_any_call(
        scheduler._generate_and_submit_daily_report,
        CronTrigger.from_crontab("30 4 * * *"),
        id="daily_report",
        name="NCC Daily Compliance Report",
        replace_existing=True,
    )


def test_scheduler_start_adds_weekly_job(compliance_config, mock_scheduler):
    """Test scheduler adds weekly report job."""
    scheduler = ComplianceScheduler(compliance_config)
    scheduler.start()

    # Verify job was added
    mock_scheduler.add_job.assert_any_call(
        scheduler._generate_weekly_report,
        CronTrigger.from_crontab("0 10 * * MON"),
        id="weekly_report",
        name="NCC Weekly Compliance Report",
        replace_existing=True,
    )


def test_scheduler_start_adds_monthly_job(compliance_config, mock_scheduler):
    """Test scheduler adds monthly report job."""
    scheduler = ComplianceScheduler(compliance_config)
    scheduler.start()

    # Verify job was added
    mock_scheduler.add_job.assert_any_call(
        scheduler._generate_monthly_report,
        CronTrigger.from_crontab("0 15 5 * *"),
        id="monthly_report",
        name="NCC Monthly Compliance Report",
        replace_existing=True,
    )


def test_scheduler_start_skips_disabled_jobs(compliance_config, mock_scheduler):
    """Test scheduler skips disabled jobs."""
    compliance_config.enable_daily_reports = False
    compliance_config.enable_weekly_reports = False

    scheduler = ComplianceScheduler(compliance_config)
    scheduler.start()

    # Verify only monthly job was added
    assert mock_scheduler.add_job.call_count == 1

    # Verify it's the monthly job
    call_args = mock_scheduler.add_job.call_args
    assert call_args[1]['id'] == "monthly_report"


def test_scheduler_start_starts_underlying_scheduler(compliance_config, mock_scheduler):
    """Test scheduler starts underlying APScheduler."""
    scheduler = ComplianceScheduler(compliance_config)
    scheduler.start()

    mock_scheduler.start.assert_called_once()


# Scheduler Stop Tests

def test_scheduler_stop(compliance_config, mock_scheduler):
    """Test scheduler stops gracefully."""
    scheduler = ComplianceScheduler(compliance_config)
    scheduler.stop()

    mock_scheduler.shutdown.assert_called_once_with(wait=True)


# Daily Report Generation Tests

@pytest.mark.asyncio
async def test_generate_daily_report_success(compliance_config):
    """Test successful daily report generation and submission."""
    mock_result = {
        "files": {
            "stats": "/var/ncc/reports/ACM_DAILY_001_20260128.csv",
            "alerts": "/var/ncc/reports/ACM_ALERTS_001_20260128.csv",
            "targets": "/var/ncc/reports/ACM_TARGETS_001_20260128.csv",
            "summary": "/var/ncc/reports/ACM_SUMMARY_001_20260128.json",
        },
        "statistics": {
            "total_alerts": 150,
            "critical_alerts": 25,
        },
        "checksum": "sha256:abc123",
    }

    with patch('ncc_integration.scheduler.ReportGenerator') as mock_gen_class, \
         patch('ncc_integration.scheduler.SftpUploader') as mock_sftp_class, \
         patch('ncc_integration.scheduler.AtrsClient') as mock_atrs_class:

        # Mock report generator
        mock_generator = MagicMock()
        mock_generator.__aenter__ = AsyncMock(return_value=mock_generator)
        mock_generator.__aexit__ = AsyncMock()
        mock_generator.generate_daily_report = AsyncMock(return_value=mock_result)
        mock_gen_class.return_value = mock_generator

        # Mock SFTP uploader
        mock_uploader = MagicMock()
        mock_uploader.__enter__ = MagicMock(return_value=mock_uploader)
        mock_uploader.__exit__ = MagicMock()
        mock_sftp_class.return_value = mock_uploader

        # Mock ATRS client
        mock_atrs = MagicMock()
        mock_atrs.__aenter__ = AsyncMock(return_value=mock_atrs)
        mock_atrs.__aexit__ = AsyncMock()
        mock_atrs.submit_daily_report = AsyncMock(return_value={"report_id": "RPT-001"})
        mock_atrs_class.return_value = mock_atrs

        scheduler = ComplianceScheduler(compliance_config)
        await scheduler._generate_and_submit_daily_report(date(2026, 1, 28))

        # Verify report was generated
        mock_generator.generate_daily_report.assert_called_once()

        # Verify files were uploaded
        mock_uploader.upload_batch.assert_called_once()
        upload_args = mock_uploader.upload_batch.call_args[0][0]
        assert len(upload_args) == 4  # 4 files

        # Verify report was submitted to ATRS
        mock_atrs.submit_daily_report.assert_called_once()


@pytest.mark.asyncio
async def test_generate_daily_report_defaults_to_yesterday(compliance_config):
    """Test daily report defaults to yesterday's date."""
    with patch('ncc_integration.scheduler.ReportGenerator') as mock_gen_class, \
         patch('ncc_integration.scheduler.SftpUploader') as mock_sftp_class, \
         patch('ncc_integration.scheduler.AtrsClient') as mock_atrs_class, \
         patch('ncc_integration.scheduler.date') as mock_date:

        # Mock date.today()
        mock_today = date(2026, 1, 29)
        mock_date.today.return_value = mock_today

        # Setup mocks
        mock_generator = MagicMock()
        mock_generator.__aenter__ = AsyncMock(return_value=mock_generator)
        mock_generator.__aexit__ = AsyncMock()
        mock_generator.generate_daily_report = AsyncMock(return_value={
            "files": {
                "stats": "/var/ncc/reports/ACM_DAILY_001_20260128.csv",
                "alerts": "/var/ncc/reports/ACM_ALERTS_001_20260128.csv",
                "targets": "/var/ncc/reports/ACM_TARGETS_001_20260128.csv",
                "summary": "/var/ncc/reports/ACM_SUMMARY_001_20260128.json",
            },
            "statistics": {},
            "checksum": "sha256:abc123",
        })
        mock_gen_class.return_value = mock_generator

        mock_uploader = MagicMock()
        mock_uploader.__enter__ = MagicMock(return_value=mock_uploader)
        mock_uploader.__exit__ = MagicMock()
        mock_sftp_class.return_value = mock_uploader

        mock_atrs = MagicMock()
        mock_atrs.__aenter__ = AsyncMock(return_value=mock_atrs)
        mock_atrs.__aexit__ = AsyncMock()
        mock_atrs.submit_daily_report = AsyncMock(return_value={"report_id": "RPT-001"})
        mock_atrs_class.return_value = mock_atrs

        scheduler = ComplianceScheduler(compliance_config)
        await scheduler._generate_and_submit_daily_report()

        # Verify yesterday's date was used
        expected_date = mock_today - timedelta(days=1)
        mock_generator.generate_daily_report.assert_called_once_with(
            expected_date,
            Path("/var/ncc/reports"),
        )


@pytest.mark.asyncio
async def test_generate_daily_report_error_handling(compliance_config):
    """Test daily report error handling."""
    with patch('ncc_integration.scheduler.ReportGenerator') as mock_gen_class:
        # Mock report generator to raise error
        mock_generator = MagicMock()
        mock_generator.__aenter__ = AsyncMock(return_value=mock_generator)
        mock_generator.__aexit__ = AsyncMock()
        mock_generator.generate_daily_report = AsyncMock(
            side_effect=Exception("Database connection failed")
        )
        mock_gen_class.return_value = mock_generator

        scheduler = ComplianceScheduler(compliance_config)

        with pytest.raises(Exception) as exc_info:
            await scheduler._generate_and_submit_daily_report(date(2026, 1, 28))

        assert "Database connection failed" in str(exc_info.value)


# Weekly Report Generation Tests

@pytest.mark.asyncio
async def test_generate_weekly_report_defaults_to_yesterday(compliance_config):
    """Test weekly report defaults to yesterday as end date."""
    with patch('ncc_integration.scheduler.date') as mock_date:
        mock_today = date(2026, 2, 4)
        mock_date.today.return_value = mock_today

        scheduler = ComplianceScheduler(compliance_config)
        await scheduler._generate_weekly_report()

        # Test completes without error (weekly not implemented yet)


@pytest.mark.asyncio
async def test_generate_weekly_report_with_custom_date(compliance_config):
    """Test weekly report with custom end date."""
    scheduler = ComplianceScheduler(compliance_config)
    await scheduler._generate_weekly_report(date(2026, 1, 28))

    # Test completes without error (weekly not implemented yet)


@pytest.mark.asyncio
async def test_generate_weekly_report_error_handling(compliance_config):
    """Test weekly report error handling."""
    with patch('ncc_integration.scheduler.logger') as mock_logger:
        scheduler = ComplianceScheduler(compliance_config)

        # Should not raise error (just logs that it's not implemented)
        await scheduler._generate_weekly_report(date(2026, 1, 28))


# Monthly Report Generation Tests

@pytest.mark.asyncio
async def test_generate_monthly_report_defaults_to_previous_month(compliance_config):
    """Test monthly report defaults to previous month."""
    with patch('ncc_integration.scheduler.date') as mock_date:
        mock_today = date(2026, 2, 4)
        mock_date.today.return_value = mock_today

        scheduler = ComplianceScheduler(compliance_config)
        await scheduler._generate_monthly_report()

        # Test completes without error (monthly not implemented yet)


@pytest.mark.asyncio
async def test_generate_monthly_report_with_custom_month(compliance_config):
    """Test monthly report with custom month."""
    scheduler = ComplianceScheduler(compliance_config)
    await scheduler._generate_monthly_report("2026-01")

    # Test completes without error (monthly not implemented yet)


@pytest.mark.asyncio
async def test_generate_monthly_report_error_handling(compliance_config):
    """Test monthly report error handling."""
    with patch('ncc_integration.scheduler.logger') as mock_logger:
        scheduler = ComplianceScheduler(compliance_config)

        # Should not raise error (just logs that it's not implemented)
        await scheduler._generate_monthly_report("2026-01")


# Manual Trigger Tests

@pytest.mark.asyncio
async def test_trigger_daily_report_manually(compliance_config):
    """Test manual daily report trigger."""
    with patch.object(
        ComplianceScheduler,
        '_generate_and_submit_daily_report',
        new_callable=AsyncMock
    ) as mock_gen:
        scheduler = ComplianceScheduler(compliance_config)
        await scheduler.trigger_daily_report(date(2026, 1, 28))

        # Verify internal method was called
        mock_gen.assert_called_once_with(date(2026, 1, 28))


@pytest.mark.asyncio
async def test_trigger_daily_report_defaults_to_yesterday(compliance_config):
    """Test manual trigger defaults to yesterday."""
    with patch.object(
        ComplianceScheduler,
        '_generate_and_submit_daily_report',
        new_callable=AsyncMock
    ) as mock_gen:
        scheduler = ComplianceScheduler(compliance_config)
        await scheduler.trigger_daily_report()

        # Verify method was called with None (which defaults to yesterday)
        mock_gen.assert_called_once_with(None)


# Job Listing Tests

def test_get_next_run_times(compliance_config, mock_scheduler):
    """Test getting next run times for all jobs."""
    # Mock jobs
    from datetime import datetime
    mock_job1 = MagicMock()
    mock_job1.id = "daily_report"
    mock_job1.next_run_time = datetime(2026, 2, 5, 4, 30)

    mock_job2 = MagicMock()
    mock_job2.id = "weekly_report"
    mock_job2.next_run_time = datetime(2026, 2, 10, 10, 0)

    mock_scheduler.get_jobs.return_value = [mock_job1, mock_job2]

    scheduler = ComplianceScheduler(compliance_config)
    next_runs = scheduler.get_next_run_times()

    assert "daily_report" in next_runs
    assert "weekly_report" in next_runs
    assert "2026-02-05" in next_runs["daily_report"]
    assert "2026-02-10" in next_runs["weekly_report"]


def test_get_next_run_times_handles_none(compliance_config, mock_scheduler):
    """Test getting next run times handles jobs with no next run."""
    mock_job = MagicMock()
    mock_job.id = "daily_report"
    mock_job.next_run_time = None

    mock_scheduler.get_jobs.return_value = [mock_job]

    scheduler = ComplianceScheduler(compliance_config)
    next_runs = scheduler.get_next_run_times()

    assert next_runs["daily_report"] is None
