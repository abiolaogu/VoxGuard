"""
Archival Scheduler

Schedules and executes automated data archival jobs using APScheduler.
"""
import logging
from datetime import datetime, timedelta
from typing import Optional

from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
from apscheduler.events import EVENT_JOB_EXECUTED, EVENT_JOB_ERROR

from .config import Config
from .archival_service import ArchivalService


logger = logging.getLogger(__name__)


class ArchivalScheduler:
    """Scheduler for automated data archival"""

    def __init__(self, config: Config):
        self.config = config
        self.archival_service = ArchivalService(config)
        self.scheduler = BackgroundScheduler()
        self._setup_event_listeners()

    def _setup_event_listeners(self):
        """Setup event listeners for job execution"""

        def job_executed(event):
            logger.info(f"Job {event.job_id} executed successfully")

        def job_error(event):
            logger.error(f"Job {event.job_id} failed: {event.exception}")

        self.scheduler.add_listener(job_executed, EVENT_JOB_EXECUTED)
        self.scheduler.add_listener(job_error, EVENT_JOB_ERROR)

    def start(self):
        """Start the scheduler"""
        logger.info("Starting archival scheduler")

        # Schedule monthly archival job
        self.scheduler.add_job(
            func=self._run_archival_job,
            trigger=CronTrigger.from_crontab(self.config.archival.schedule_cron),
            id="monthly_archival",
            name="Monthly Data Archival",
            replace_existing=True,
        )

        # Schedule daily cleanup of expired archives (GDPR)
        self.scheduler.add_job(
            func=self._run_cleanup_job,
            trigger=CronTrigger(hour=3, minute=0),  # Daily at 3 AM
            id="daily_cleanup",
            name="Daily Archive Cleanup",
            replace_existing=True,
        )

        # Schedule weekly retention statistics
        self.scheduler.add_job(
            func=self._log_retention_statistics,
            trigger=CronTrigger(day_of_week="mon", hour=8, minute=0),  # Monday 8 AM
            id="weekly_stats",
            name="Weekly Retention Statistics",
            replace_existing=True,
        )

        self.scheduler.start()
        logger.info(
            f"Scheduler started with {len(self.scheduler.get_jobs())} jobs: "
            f"{[job.id for job in self.scheduler.get_jobs()]}"
        )

    def stop(self):
        """Stop the scheduler"""
        logger.info("Stopping archival scheduler")
        self.scheduler.shutdown(wait=True)
        self.archival_service.close()

    def _run_archival_job(self):
        """Execute archival job for all configured tables"""
        logger.info("Starting scheduled archival job")
        start_time = datetime.utcnow()

        # Calculate cutoff date (data older than hot_retention_days)
        cutoff_date = datetime.utcnow() - timedelta(days=self.config.archival.hot_retention_days)
        partition_key = cutoff_date.strftime("%Y-%m")

        total_archives = 0
        total_records = 0

        for table_name in self.config.archival.tables_to_archive:
            logger.info(f"Archiving {table_name} (cutoff: {cutoff_date})")
            try:
                metadata = self.archival_service.archive_table(
                    table_name=table_name,
                    partition_key=partition_key,
                    cutoff_date=cutoff_date,
                )

                if metadata:
                    total_archives += 1
                    total_records += metadata.record_count
                    logger.info(
                        f"Created archive {metadata.archive_id} for {table_name} "
                        f"with {metadata.record_count} records"
                    )
                else:
                    logger.info(f"No data to archive for {table_name}")

            except Exception as e:
                logger.error(f"Failed to archive {table_name}: {e}")
                continue

        elapsed = (datetime.utcnow() - start_time).total_seconds()
        logger.info(
            f"Archival job completed in {elapsed:.1f}s: "
            f"{total_archives} archives created, {total_records} records archived"
        )

    def _run_cleanup_job(self):
        """Execute cleanup job for expired archives"""
        logger.info("Starting scheduled cleanup job")
        start_time = datetime.utcnow()

        try:
            deleted_count = self.archival_service.delete_expired_archives()
            elapsed = (datetime.utcnow() - start_time).total_seconds()
            logger.info(f"Cleanup job completed in {elapsed:.1f}s: {deleted_count} archives deleted")

        except Exception as e:
            logger.error(f"Cleanup job failed: {e}")

    def _log_retention_statistics(self):
        """Log retention statistics"""
        logger.info("Generating retention statistics")

        try:
            stats = self.archival_service.get_retention_statistics()
            logger.info(
                f"Retention Statistics:\n"
                f"  Total Archives: {stats['total_archives']}\n"
                f"  Total Records: {stats['total_archived_records']}\n"
                f"  Compressed Size: {stats['total_compressed_size_mb']:.2f} MB\n"
                f"  Original Size: {stats['total_original_size_mb']:.2f} MB\n"
                f"  Compression Ratio: {stats['compression_ratio']:.2%}\n"
                f"  By Table: {stats['by_table']}"
            )

        except Exception as e:
            logger.error(f"Failed to generate statistics: {e}")

    def trigger_manual_archival(self, table_name: str, cutoff_date: datetime) -> Optional[str]:
        """
        Manually trigger archival for a specific table

        Args:
            table_name: Name of the table to archive
            cutoff_date: Archive data older than this date

        Returns:
            Archive ID if successful, None otherwise
        """
        logger.info(f"Manual archival triggered for {table_name} (cutoff: {cutoff_date})")
        partition_key = cutoff_date.strftime("%Y-%m")

        try:
            metadata = self.archival_service.archive_table(
                table_name=table_name,
                partition_key=partition_key,
                cutoff_date=cutoff_date,
            )

            if metadata:
                logger.info(f"Manual archival completed: {metadata.archive_id}")
                return metadata.archive_id
            else:
                logger.warning("No data to archive")
                return None

        except Exception as e:
            logger.error(f"Manual archival failed: {e}")
            return None

    def get_next_run_times(self) -> dict:
        """
        Get next run times for all scheduled jobs

        Returns:
            Dictionary mapping job IDs to next run times
        """
        jobs = self.scheduler.get_jobs()
        return {job.id: job.next_run_time for job in jobs}

    def list_jobs(self) -> list:
        """
        List all scheduled jobs

        Returns:
            List of job information dictionaries
        """
        jobs = self.scheduler.get_jobs()
        return [
            {
                "id": job.id,
                "name": job.name,
                "next_run_time": job.next_run_time,
                "trigger": str(job.trigger),
            }
            for job in jobs
        ]
