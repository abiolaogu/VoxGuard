"""
NCC Compliance Scheduler

Schedules and executes periodic compliance tasks:
- Daily reports at 05:30 WAT
- Weekly reports on Monday at 11:00 WAT
- Monthly reports on 5th at 16:00 WAT
"""

import asyncio
import logging
from datetime import date, timedelta
from pathlib import Path
from typing import Optional

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from apscheduler.events import EVENT_JOB_ERROR, EVENT_JOB_EXECUTED

from .config import ComplianceConfig
from .atrs_client import AtrsClient
from .sftp_uploader import SftpUploader
from .report_generator import ReportGenerator

logger = logging.getLogger(__name__)


class ComplianceScheduler:
    """
    Scheduler for NCC compliance tasks.

    Manages periodic report generation and submission according to
    NCC deadlines.
    """

    def __init__(self, config: ComplianceConfig):
        """
        Initialize compliance scheduler.

        Args:
            config: Complete compliance configuration
        """
        self.config = config
        self.scheduler = AsyncIOScheduler(timezone=config.scheduler.timezone)
        self.output_dir = Path("/var/ncc/reports")

        # Set up event listeners
        self.scheduler.add_listener(
            self._job_executed_listener,
            EVENT_JOB_EXECUTED,
        )
        self.scheduler.add_listener(
            self._job_error_listener,
            EVENT_JOB_ERROR,
        )

    def _job_executed_listener(self, event):
        """Log successful job execution."""
        logger.info(f"Job {event.job_id} completed successfully")

    def _job_error_listener(self, event):
        """Log job errors."""
        logger.error(
            f"Job {event.job_id} failed: {event.exception}",
            exc_info=event.exception,
        )

    async def _generate_and_submit_daily_report(
        self,
        report_date: Optional[date] = None,
    ) -> None:
        """
        Generate and submit daily compliance report.

        Args:
            report_date: Date to generate report for (default: yesterday)
        """
        if report_date is None:
            report_date = date.today() - timedelta(days=1)

        logger.info(f"Starting daily report generation for {report_date}")

        try:
            # Generate reports
            async with ReportGenerator(
                self.config.database,
                self.config.atrs.icl_license,
            ) as generator:
                result = await generator.generate_daily_report(
                    report_date,
                    self.output_dir,
                )

            logger.info(f"Daily report generated: {result['checksum']}")

            # Upload to SFTP
            with SftpUploader(self.config.sftp) as uploader:
                files_to_upload = [
                    (result["files"]["stats"], Path(result["files"]["stats"]).name),
                    (result["files"]["alerts"], Path(result["files"]["alerts"]).name),
                    (result["files"]["targets"], Path(result["files"]["targets"]).name),
                    (result["files"]["summary"], Path(result["files"]["summary"]).name),
                ]

                uploader.upload_batch(files_to_upload)

            logger.info("Daily report uploaded to SFTP")

            # Submit to ATRS API
            async with AtrsClient(self.config.atrs) as atrs:
                top_targets = []
                # Parse top targets from the generated files for API submission
                # (In production, this would be extracted from the generator result)

                response = await atrs.submit_daily_report(
                    report_date=report_date.isoformat(),
                    statistics=result["statistics"],
                    top_targeted_numbers=top_targets,
                    checksum=result["checksum"],
                )

                logger.info(f"Daily report submitted to ATRS: {response.get('report_id')}")

        except Exception as e:
            logger.error(f"Failed to generate/submit daily report: {e}", exc_info=True)
            raise

    async def _generate_weekly_report(
        self,
        end_date: Optional[date] = None,
    ) -> None:
        """
        Generate and submit weekly compliance report.

        Args:
            end_date: End date of week (default: yesterday)
        """
        if end_date is None:
            end_date = date.today() - timedelta(days=1)

        start_date = end_date - timedelta(days=6)

        logger.info(f"Generating weekly report for {start_date} to {end_date}")

        try:
            # TODO: Implement weekly report generation
            # This would aggregate daily statistics for the week
            logger.info("Weekly report generation not yet implemented")

        except Exception as e:
            logger.error(f"Failed to generate weekly report: {e}", exc_info=True)
            raise

    async def _generate_monthly_report(
        self,
        report_month: Optional[str] = None,
    ) -> None:
        """
        Generate and submit monthly compliance report.

        Args:
            report_month: Month to report (YYYY-MM, default: previous month)
        """
        if report_month is None:
            today = date.today()
            first_of_this_month = today.replace(day=1)
            last_month = first_of_this_month - timedelta(days=1)
            report_month = last_month.strftime("%Y-%m")

        logger.info(f"Generating monthly report for {report_month}")

        try:
            # TODO: Implement monthly report generation
            # This would aggregate daily/weekly statistics for the month
            logger.info("Monthly report generation not yet implemented")

        except Exception as e:
            logger.error(f"Failed to generate monthly report: {e}", exc_info=True)
            raise

    def start(self) -> None:
        """
        Start the compliance scheduler.

        Schedules all periodic tasks according to NCC deadlines.
        """
        logger.info("Starting NCC compliance scheduler")

        # Ensure output directory exists
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # Schedule daily report (05:30 WAT = 04:30 UTC)
        if self.config.enable_daily_reports:
            self.scheduler.add_job(
                self._generate_and_submit_daily_report,
                CronTrigger.from_crontab(self.config.scheduler.daily_report_cron),
                id="daily_report",
                name="NCC Daily Compliance Report",
                replace_existing=True,
            )
            logger.info(
                f"Scheduled daily report: {self.config.scheduler.daily_report_cron}"
            )

        # Schedule weekly report (Monday 11:00 WAT = 10:00 UTC)
        if self.config.enable_weekly_reports:
            self.scheduler.add_job(
                self._generate_weekly_report,
                CronTrigger.from_crontab(self.config.scheduler.weekly_report_cron),
                id="weekly_report",
                name="NCC Weekly Compliance Report",
                replace_existing=True,
            )
            logger.info(
                f"Scheduled weekly report: {self.config.scheduler.weekly_report_cron}"
            )

        # Schedule monthly report (5th at 16:00 WAT = 15:00 UTC)
        if self.config.enable_monthly_reports:
            self.scheduler.add_job(
                self._generate_monthly_report,
                CronTrigger.from_crontab(self.config.scheduler.monthly_report_cron),
                id="monthly_report",
                name="NCC Monthly Compliance Report",
                replace_existing=True,
            )
            logger.info(
                f"Scheduled monthly report: {self.config.scheduler.monthly_report_cron}"
            )

        self.scheduler.start()
        logger.info("NCC compliance scheduler started")

    def stop(self) -> None:
        """Stop the scheduler."""
        logger.info("Stopping NCC compliance scheduler")
        self.scheduler.shutdown(wait=True)

    async def trigger_daily_report(
        self,
        report_date: Optional[date] = None,
    ) -> None:
        """
        Manually trigger daily report generation.

        Args:
            report_date: Date to generate report for (default: yesterday)
        """
        logger.info("Manually triggering daily report")
        await self._generate_and_submit_daily_report(report_date)

    def get_next_run_times(self) -> dict:
        """
        Get next scheduled run times for all jobs.

        Returns:
            Dictionary of job_id -> next_run_time
        """
        jobs = self.scheduler.get_jobs()
        return {
            job.id: job.next_run_time.isoformat() if job.next_run_time else None
            for job in jobs
        }


async def main():
    """Main entry point for standalone scheduler service."""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )

    # Load configuration
    config = ComplianceConfig.from_env()

    # Create and start scheduler
    scheduler = ComplianceScheduler(config)
    scheduler.start()

    logger.info("NCC Compliance Scheduler running. Press Ctrl+C to exit.")
    logger.info(f"Next run times: {scheduler.get_next_run_times()}")

    try:
        # Keep running
        while True:
            await asyncio.sleep(3600)  # Wake up every hour
    except KeyboardInterrupt:
        logger.info("Shutdown requested")
    finally:
        scheduler.stop()


if __name__ == "__main__":
    asyncio.run(main())
