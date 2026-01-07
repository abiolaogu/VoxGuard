"""Configuration settings for SIP Processor."""
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    # Service info
    app_name: str = "Anti-Call Masking SIP Processor"
    app_version: str = "1.0.0"
    debug: bool = False
    
    # Redis configuration (real-time counters)
    redis_url: str = "redis://localhost:6379"
    redis_max_connections: int = 20
    
    # PostgreSQL configuration (long-term CDR logs)
    postgres_url: str = "postgresql+asyncpg://cdr_user:cdr_secure_password@localhost:5432/cdr_logs"
    postgres_pool_size: int = 10
    
    # SIP Signaling configuration
    sip_interface: str = "eth0"
    sip_port: int = 5060
    
    # Detection configuration
    detection_window_seconds: int = 5
    detection_threshold: int = 5
    masking_probability_threshold: float = 0.7
    
    # Model configuration
    model_path: str = "models/xgboost_masking.json"
    
    # CDR metrics configuration
    cdr_window_seconds: int = 300  # 5-minute window for metrics
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
