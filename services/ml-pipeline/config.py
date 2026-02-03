"""ML Pipeline Configuration."""
import os
from dataclasses import dataclass
from typing import Optional


@dataclass
class ModelConfig:
    """Configuration for ML models."""

    # Model paths
    model_registry_path: str = "models/registry"
    active_model_path: str = "models/active/xgboost_masking.json"

    # Training parameters
    max_depth: int = 6
    learning_rate: float = 0.1
    n_estimators: int = 100
    subsample: float = 0.8
    colsample_bytree: float = 0.8

    # Feature engineering
    lookback_days: int = 7
    min_samples_for_training: int = 1000

    # Evaluation thresholds
    min_auc_score: float = 0.85
    min_precision: float = 0.80
    min_recall: float = 0.75
    improvement_threshold: float = 0.02  # 2% better than baseline


@dataclass
class InferenceConfig:
    """Configuration for inference server."""

    host: str = "0.0.0.0"
    port: int = 50051
    max_workers: int = 10
    batch_size: int = 32
    batch_timeout_ms: int = 10  # Wait max 10ms to fill batch

    # Feature cache
    cache_enabled: bool = True
    cache_ttl_seconds: int = 60

    # Monitoring
    metrics_port: int = 9090


@dataclass
class ABTestConfig:
    """Configuration for A/B testing."""

    # Traffic splitting
    model_a_traffic: float = 0.9  # 90% to model A (current production)
    model_b_traffic: float = 0.1  # 10% to model B (challenger)

    # Statistical testing
    min_samples_per_model: int = 1000
    confidence_level: float = 0.95
    min_effect_size: float = 0.05  # 5% improvement required

    # Rollout
    gradual_rollout_enabled: bool = True
    rollout_step_percentage: float = 0.1  # Increase by 10% each step
    rollout_step_duration_hours: int = 24


@dataclass
class TrainingConfig:
    """Configuration for model training."""

    # Scheduling
    schedule_enabled: bool = True
    schedule_cron: str = "0 2 * * *"  # 2 AM daily (WAT)
    schedule_timezone: str = "Africa/Lagos"

    # Data sources
    database_host: str = os.getenv("YUGABYTE_HOST", "localhost")
    database_port: int = int(os.getenv("YUGABYTE_PORT", "5433"))
    database_name: str = os.getenv("YUGABYTE_DB", "voxguard")
    database_user: str = os.getenv("YUGABYTE_USER", "voxguard")
    database_password: str = os.getenv("YUGABYTE_PASSWORD", "")

    # Training data query
    training_query: str = """
        SELECT
            asr,
            aloc,
            overlap_ratio,
            cli_mismatch::int as cli_mismatch,
            distinct_a_count,
            call_rate,
            short_call_ratio,
            high_volume_flag::int as high_volume_flag,
            is_fraud::int as label
        FROM ml_training_data
        WHERE created_at >= NOW() - INTERVAL '{lookback_days} days'
        AND label IS NOT NULL
        ORDER BY created_at DESC
    """

    # Validation split
    test_size: float = 0.2
    validation_size: float = 0.1
    random_seed: int = 42


@dataclass
class MonitoringConfig:
    """Configuration for ML monitoring."""

    # Data drift detection
    drift_detection_enabled: bool = True
    drift_check_interval_hours: int = 6
    drift_threshold: float = 0.1  # KL divergence threshold

    # Model performance alerts
    alert_on_accuracy_drop: bool = True
    accuracy_drop_threshold: float = 0.05  # 5% drop triggers alert

    # Prometheus metrics
    prometheus_enabled: bool = True
    prometheus_port: int = 9091


@dataclass
class MLPipelineConfig:
    """Master configuration for ML pipeline."""

    model: ModelConfig = ModelConfig()
    inference: InferenceConfig = InferenceConfig()
    ab_test: ABTestConfig = ABTestConfig()
    training: TrainingConfig = TrainingConfig()
    monitoring: MonitoringConfig = MonitoringConfig()

    # Environment
    environment: str = os.getenv("ML_ENVIRONMENT", "development")
    debug: bool = os.getenv("ML_DEBUG", "false").lower() == "true"

    @classmethod
    def from_env(cls) -> "MLPipelineConfig":
        """Create configuration from environment variables."""
        config = cls()

        # Override with environment variables
        if env_host := os.getenv("ML_INFERENCE_HOST"):
            config.inference.host = env_host

        if env_port := os.getenv("ML_INFERENCE_PORT"):
            config.inference.port = int(env_port)

        if env_workers := os.getenv("ML_MAX_WORKERS"):
            config.inference.max_workers = int(env_workers)

        if env_lookback := os.getenv("ML_TRAINING_LOOKBACK_DAYS"):
            config.model.lookback_days = int(env_lookback)

        if env_schedule := os.getenv("ML_TRAINING_SCHEDULE"):
            config.training.schedule_cron = env_schedule

        return config

    @property
    def database_dsn(self) -> str:
        """Get PostgreSQL connection string."""
        return (
            f"postgresql://{self.training.database_user}:{self.training.database_password}"
            f"@{self.training.database_host}:{self.training.database_port}"
            f"/{self.training.database_name}"
        )
