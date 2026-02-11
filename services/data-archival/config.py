"""
Configuration for Data Archival Service
"""
import os
from enum import Enum
from dataclasses import dataclass
from typing import Optional


class CompressionType(Enum):
    """Supported compression algorithms"""
    GZIP = "gzip"
    ZSTD = "zstd"
    NONE = "none"


class ArchivalFrequency(Enum):
    """Archival schedule options"""
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"


@dataclass
class DatabaseConfig:
    """Database connection configuration"""
    host: str
    port: int
    database: str
    user: str
    password: str

    @classmethod
    def from_env(cls) -> "DatabaseConfig":
        return cls(
            host=os.getenv("DB_HOST", "localhost"),
            port=int(os.getenv("DB_PORT", "5433")),
            database=os.getenv("DB_NAME", "acm_db"),
            user=os.getenv("DB_USER", "admin"),
            password=os.getenv("DB_PASSWORD", ""),
        )


@dataclass
class S3Config:
    """S3-compatible storage configuration"""
    endpoint_url: str
    access_key: str
    secret_key: str
    bucket_name: str
    region: str
    use_ssl: bool = True

    @classmethod
    def from_env(cls) -> "S3Config":
        return cls(
            endpoint_url=os.getenv("S3_ENDPOINT", "https://s3.amazonaws.com"),
            access_key=os.getenv("S3_ACCESS_KEY", ""),
            secret_key=os.getenv("S3_SECRET_KEY", ""),
            bucket_name=os.getenv("S3_BUCKET", "voxguard-archives"),
            region=os.getenv("S3_REGION", "us-east-1"),
            use_ssl=os.getenv("S3_USE_SSL", "true").lower() == "true",
        )


@dataclass
class ArchivalConfig:
    """Main archival configuration"""
    # Retention policy
    hot_retention_days: int = 90  # Keep recent data in hot storage
    warm_retention_days: int = 365  # Keep 1-year data in warm storage
    cold_retention_years: int = 7  # NCC compliance: 7-year retention

    # Archival settings
    frequency: ArchivalFrequency = ArchivalFrequency.MONTHLY
    compression: CompressionType = CompressionType.ZSTD
    compression_level: int = 3  # Balance between speed and ratio
    chunk_size: int = 10000  # Records per chunk for batch processing

    # Tables to archive
    tables_to_archive: list[str] = None

    # Schedule (cron format)
    schedule_cron: str = "0 2 1 * *"  # 2 AM on 1st of each month

    # Storage paths
    archive_prefix: str = "archives"  # S3 prefix for archives
    metadata_prefix: str = "metadata"  # S3 prefix for metadata

    # Performance
    max_workers: int = 4  # Parallel compression workers
    batch_timeout_seconds: int = 300  # 5-minute timeout per batch

    # Monitoring
    enable_metrics: bool = True
    metrics_port: int = 9092  # Prometheus metrics port

    # GDPR compliance
    enable_gdpr_deletion: bool = True
    gdpr_retention_days: int = 2555  # 7 years in days

    def __post_init__(self):
        if self.tables_to_archive is None:
            self.tables_to_archive = [
                "acm_alerts",
                "audit_events",
                "call_detail_records",
                "gateway_blacklist_history",
                "fraud_investigations",
            ]

    @classmethod
    def from_env(cls) -> "ArchivalConfig":
        return cls(
            hot_retention_days=int(os.getenv("ARCHIVAL_HOT_RETENTION_DAYS", "90")),
            warm_retention_days=int(os.getenv("ARCHIVAL_WARM_RETENTION_DAYS", "365")),
            cold_retention_years=int(os.getenv("ARCHIVAL_COLD_RETENTION_YEARS", "7")),
            frequency=ArchivalFrequency(os.getenv("ARCHIVAL_FREQUENCY", "monthly")),
            compression=CompressionType(os.getenv("ARCHIVAL_COMPRESSION", "zstd")),
            compression_level=int(os.getenv("ARCHIVAL_COMPRESSION_LEVEL", "3")),
            chunk_size=int(os.getenv("ARCHIVAL_CHUNK_SIZE", "10000")),
            schedule_cron=os.getenv("ARCHIVAL_SCHEDULE_CRON", "0 2 1 * *"),
            max_workers=int(os.getenv("ARCHIVAL_MAX_WORKERS", "4")),
            enable_metrics=os.getenv("ARCHIVAL_ENABLE_METRICS", "true").lower() == "true",
            metrics_port=int(os.getenv("ARCHIVAL_METRICS_PORT", "9092")),
        )


@dataclass
class Config:
    """Combined configuration"""
    db: DatabaseConfig
    s3: S3Config
    archival: ArchivalConfig

    @classmethod
    def from_env(cls) -> "Config":
        return cls(
            db=DatabaseConfig.from_env(),
            s3=S3Config.from_env(),
            archival=ArchivalConfig.from_env(),
        )


# Global config instance
config = Config.from_env()
