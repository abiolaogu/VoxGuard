"""
Anti-Call Masking Detection System - LumaDB Edition
Configuration settings using Pydantic
"""

from pydantic_settings import BaseSettings
from pydantic import Field
from typing import Optional, List
import os


class LumaDBSettings(BaseSettings):
    """LumaDB connection settings - replaces kdb+, Kafka, Redis, and PostgreSQL"""

    # LumaDB REST API
    rest_host: str = Field(default="localhost", env="LUMADB_REST_HOST")
    rest_port: int = Field(default=8080, env="LUMADB_REST_PORT")

    # LumaDB PostgreSQL Protocol (SQL queries)
    pg_host: str = Field(default="localhost", env="LUMADB_PG_HOST")
    pg_port: int = Field(default=5432, env="LUMADB_PG_PORT")
    pg_user: str = Field(default="lumadb", env="LUMADB_PG_USER")
    pg_password: str = Field(default="lumadb", env="LUMADB_PG_PASSWORD")
    pg_database: str = Field(default="default", env="LUMADB_PG_DATABASE")

    # LumaDB Kafka Protocol (streaming)
    kafka_host: str = Field(default="localhost", env="LUMADB_KAFKA_HOST")
    kafka_port: int = Field(default=9092, env="LUMADB_KAFKA_PORT")

    # LumaDB gRPC (high-performance queries)
    grpc_host: str = Field(default="localhost", env="LUMADB_GRPC_HOST")
    grpc_port: int = Field(default=50051, env="LUMADB_GRPC_PORT")

    @property
    def rest_url(self) -> str:
        return f"http://{self.rest_host}:{self.rest_port}"

    @property
    def pg_dsn(self) -> str:
        return f"postgresql://{self.pg_user}:{self.pg_password}@{self.pg_host}:{self.pg_port}/{self.pg_database}"

    @property
    def kafka_bootstrap_servers(self) -> str:
        return f"{self.kafka_host}:{self.kafka_port}"

    class Config:
        env_prefix = "LUMADB_"


class DetectionSettings(BaseSettings):
    """Anti-call masking detection configuration"""

    # Detection window in seconds (5 second sliding window)
    window_seconds: int = Field(default=5, env="ACM_WINDOW_SECONDS")

    # Minimum distinct A-numbers to trigger alert
    threshold: int = Field(default=5, env="ACM_THRESHOLD")

    # Cooldown between alerts for same B-number (seconds)
    cooldown_seconds: int = Field(default=30, env="ACM_COOLDOWN_SECONDS")

    # Auto-disconnect detected fraud calls
    auto_disconnect: bool = Field(default=False, env="ACM_AUTO_DISCONNECT")

    # Auto-block patterns after detection
    auto_block: bool = Field(default=True, env="ACM_AUTO_BLOCK")

    # Block duration in hours
    block_duration_hours: int = Field(default=24, env="ACM_BLOCK_DURATION_HOURS")

    class Config:
        env_prefix = "ACM_"


class APISettings(BaseSettings):
    """API server configuration"""

    host: str = Field(default="0.0.0.0", env="API_HOST")
    port: int = Field(default=5001, env="API_PORT")
    debug: bool = Field(default=False, env="API_DEBUG")
    workers: int = Field(default=4, env="API_WORKERS")

    # CORS settings
    cors_origins: List[str] = Field(default=["*"], env="API_CORS_ORIGINS")

    class Config:
        env_prefix = "API_"


class StreamingSettings(BaseSettings):
    """LumaDB Kafka-compatible streaming settings"""

    # Topic names
    calls_topic: str = Field(default="acm.calls", env="STREAM_CALLS_TOPIC")
    alerts_topic: str = Field(default="acm.alerts", env="STREAM_ALERTS_TOPIC")
    actions_topic: str = Field(default="acm.actions", env="STREAM_ACTIONS_TOPIC")

    # Consumer group
    consumer_group: str = Field(default="acm-detection", env="STREAM_CONSUMER_GROUP")

    # Batch settings
    batch_size: int = Field(default=100, env="STREAM_BATCH_SIZE")
    batch_timeout_ms: int = Field(default=100, env="STREAM_BATCH_TIMEOUT_MS")

    class Config:
        env_prefix = "STREAM_"


class Settings(BaseSettings):
    """Main application settings"""

    # Sub-configurations
    lumadb: LumaDBSettings = LumaDBSettings()
    detection: DetectionSettings = DetectionSettings()
    api: APISettings = APISettings()
    streaming: StreamingSettings = StreamingSettings()

    # Application info
    app_name: str = "Anti-Call Masking Detection System"
    app_version: str = "2.0.0"
    environment: str = Field(default="development", env="ENVIRONMENT")

    # Logging
    log_level: str = Field(default="INFO", env="LOG_LEVEL")
    log_format: str = Field(default="json", env="LOG_FORMAT")

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


# Global settings instance
settings = Settings()
