"""Configuration for NCC Integration Service."""

import os
from dataclasses import dataclass
from typing import Optional


@dataclass
class AtrsConfig:
    """ATRS API configuration."""

    base_url: str
    client_id: str
    client_secret: str
    icl_license: str
    timeout_seconds: int = 30
    max_retries: int = 3

    @classmethod
    def from_env(cls) -> "AtrsConfig":
        """Load configuration from environment variables."""
        env = os.getenv("NCC_ENVIRONMENT", "sandbox")

        if env == "production":
            base_url = "https://atrs-api.ncc.gov.ng/v2"
        else:
            base_url = "https://atrs-sandbox.ncc.gov.ng/v2"

        return cls(
            base_url=base_url,
            client_id=os.getenv("NCC_CLIENT_ID", ""),
            client_secret=os.getenv("NCC_CLIENT_SECRET", ""),
            icl_license=os.getenv("NCC_ICL_LICENSE", "ICL-NG-2025-001234"),
            timeout_seconds=int(os.getenv("NCC_TIMEOUT", "30")),
            max_retries=int(os.getenv("NCC_MAX_RETRIES", "3")),
        )


@dataclass
class SftpConfig:
    """SFTP server configuration for CDR uploads."""

    host: str
    port: int
    username: str
    private_key_path: str
    remote_path: str

    @classmethod
    def from_env(cls) -> "SftpConfig":
        """Load configuration from environment variables."""
        icl_license = os.getenv("NCC_ICL_LICENSE", "ICL-NG-2025-001234")

        return cls(
            host=os.getenv("NCC_SFTP_HOST", "sftp.ncc.gov.ng"),
            port=int(os.getenv("NCC_SFTP_PORT", "22")),
            username=os.getenv("NCC_SFTP_USER", "ncc_upload"),
            private_key_path=os.getenv("NCC_SFTP_KEY_PATH", "/etc/ncc/id_rsa"),
            remote_path=f"/incoming/{icl_license}/daily/",
        )


@dataclass
class DatabaseConfig:
    """PostgreSQL database configuration."""

    host: str
    port: int
    database: str
    user: str
    password: str

    @classmethod
    def from_env(cls) -> "DatabaseConfig":
        """Load configuration from environment variables."""
        return cls(
            host=os.getenv("POSTGRES_HOST", "localhost"),
            port=int(os.getenv("POSTGRES_PORT", "5432")),
            database=os.getenv("POSTGRES_DB", "voxguard"),
            user=os.getenv("POSTGRES_USER", "postgres"),
            password=os.getenv("POSTGRES_PASSWORD", ""),
        )

    @property
    def connection_string(self) -> str:
        """Get PostgreSQL connection string."""
        return (
            f"postgresql://{self.user}:{self.password}"
            f"@{self.host}:{self.port}/{self.database}"
        )


@dataclass
class SchedulerConfig:
    """Scheduler configuration."""

    # Daily report at 05:30 WAT (04:30 UTC if WAT is UTC+1)
    daily_report_cron: str = "30 4 * * *"

    # Weekly report Monday at 11:00 WAT (10:00 UTC)
    weekly_report_cron: str = "0 10 * * MON"

    # Monthly report on 5th at 16:00 WAT (15:00 UTC)
    monthly_report_cron: str = "0 15 5 * *"

    timezone: str = "Africa/Lagos"

    @classmethod
    def from_env(cls) -> "SchedulerConfig":
        """Load configuration from environment variables."""
        return cls(
            daily_report_cron=os.getenv("NCC_DAILY_CRON", "30 4 * * *"),
            weekly_report_cron=os.getenv("NCC_WEEKLY_CRON", "0 10 * * MON"),
            monthly_report_cron=os.getenv("NCC_MONTHLY_CRON", "0 15 5 * *"),
            timezone=os.getenv("NCC_TIMEZONE", "Africa/Lagos"),
        )


@dataclass
class ComplianceConfig:
    """Complete NCC compliance configuration."""

    atrs: AtrsConfig
    sftp: SftpConfig
    database: DatabaseConfig
    scheduler: SchedulerConfig

    # Enable/disable components
    enable_real_time_reporting: bool = True
    enable_daily_reports: bool = True
    enable_weekly_reports: bool = True
    enable_monthly_reports: bool = True

    @classmethod
    def from_env(cls) -> "ComplianceConfig":
        """Load complete configuration from environment."""
        return cls(
            atrs=AtrsConfig.from_env(),
            sftp=SftpConfig.from_env(),
            database=DatabaseConfig.from_env(),
            scheduler=SchedulerConfig.from_env(),
            enable_real_time_reporting=os.getenv("NCC_ENABLE_REALTIME", "true").lower() == "true",
            enable_daily_reports=os.getenv("NCC_ENABLE_DAILY", "true").lower() == "true",
            enable_weekly_reports=os.getenv("NCC_ENABLE_WEEKLY", "true").lower() == "true",
            enable_monthly_reports=os.getenv("NCC_ENABLE_MONTHLY", "true").lower() == "true",
        )
