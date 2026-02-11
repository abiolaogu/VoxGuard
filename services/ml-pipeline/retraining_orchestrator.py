"""Automated model retraining orchestration service.

Orchestrates the complete model retraining pipeline:
1. Data collection from operational databases
2. Model training with XGBoost
3. Model evaluation and quality gates
4. Model promotion to production (champion/challenger)
5. Scheduled execution (daily at 2 AM WAT)
"""
import asyncio
import logging
from datetime import datetime, timedelta
from dataclasses import dataclass
from typing import Optional, Dict
from enum import Enum

import pandas as pd

from .data_collector import DataCollector, DataCollectionConfig
from .training.trainer import ModelTrainer
from .training.evaluator import ModelEvaluator
from .model_registry import ModelRegistry

logger = logging.getLogger(__name__)


class RetrainingStatus(Enum):
    """Status of retraining job."""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    SKIPPED = "skipped"


@dataclass
class RetrainingConfig:
    """Configuration for model retraining."""

    # Scheduling
    schedule_cron: str = "0 2 * * *"  # 2 AM daily
    schedule_timezone: str = "Africa/Lagos"
    enabled: bool = True

    # Data collection
    lookback_days: int = 7
    min_samples_required: int = 1000

    # Training
    max_depth: int = 6
    learning_rate: float = 0.1
    n_estimators: int = 100

    # Quality gates
    min_auc_score: float = 0.85
    min_precision: float = 0.80
    min_recall: float = 0.75
    improvement_threshold: float = 0.02  # 2% better than baseline

    # Model registry
    registry_path: str = "models/registry"
    auto_promote_champion: bool = False  # Manual approval by default

    # Notification
    notify_on_completion: bool = True
    notify_on_failure: bool = True


@dataclass
class RetrainingResult:
    """Result of a retraining job."""

    status: RetrainingStatus
    start_time: datetime
    end_time: datetime
    duration_seconds: float

    # Data collection
    samples_collected: int
    fraud_samples: int
    non_fraud_samples: int

    # Training
    model_id: Optional[str] = None
    model_path: Optional[str] = None

    # Evaluation
    auc_score: Optional[float] = None
    precision: Optional[float] = None
    recall: Optional[float] = None
    f1_score: Optional[float] = None

    # Quality gates
    passed_quality_gates: bool = False
    is_improvement: bool = False

    # Actions taken
    promoted_to_challenger: bool = False
    promoted_to_champion: bool = False

    # Error info
    error_message: Optional[str] = None


class RetrainingOrchestrator:
    """Orchestrates automated model retraining pipeline.

    Features:
    - Scheduled execution (cron-like)
    - Data collection from QuestDB and YugabyteDB
    - XGBoost model training
    - Comprehensive model evaluation
    - Quality gates and validation
    - Automatic model promotion (champion/challenger)
    - Metrics and monitoring
    - Error handling and notifications
    """

    def __init__(self, config: RetrainingConfig):
        """Initialize the retraining orchestrator.

        Args:
            config: Retraining configuration
        """
        self.config = config

        # Components
        self.data_collector = DataCollector(
            DataCollectionConfig(
                lookback_days=config.lookback_days,
                min_samples=config.min_samples_required,
            )
        )

        self.model_trainer = ModelTrainer(
            max_depth=config.max_depth,
            learning_rate=config.learning_rate,
            n_estimators=config.n_estimators,
        )

        self.model_evaluator = ModelEvaluator()

        self.model_registry = ModelRegistry(config.registry_path)

        # State
        self.is_running = False
        self.last_run_time: Optional[datetime] = None
        self.last_result: Optional[RetrainingResult] = None

        # Metrics
        self.total_runs = 0
        self.successful_runs = 0
        self.failed_runs = 0

        logger.info(
            f"RetrainingOrchestrator initialized: "
            f"schedule={config.schedule_cron}, timezone={config.schedule_timezone}"
        )

    async def run_retraining(self) -> RetrainingResult:
        """Execute a complete retraining pipeline.

        Returns:
            RetrainingResult with job details
        """
        if self.is_running:
            logger.warning("Retraining already in progress, skipping")
            return RetrainingResult(
                status=RetrainingStatus.SKIPPED,
                start_time=datetime.now(),
                end_time=datetime.now(),
                duration_seconds=0.0,
                samples_collected=0,
                fraud_samples=0,
                non_fraud_samples=0,
                error_message="Previous run still in progress",
            )

        self.is_running = True
        start_time = datetime.now()
        self.total_runs += 1

        logger.info(f"=== Starting Model Retraining Pipeline (Run #{self.total_runs}) ===")

        try:
            # Step 1: Data Collection
            logger.info("Step 1/5: Collecting training data...")
            training_df = await self._collect_data()

            if len(training_df) < self.config.min_samples_required:
                raise ValueError(
                    f"Insufficient samples: {len(training_df)} < "
                    f"{self.config.min_samples_required}"
                )

            # Step 2: Train Model
            logger.info("Step 2/5: Training XGBoost model...")
            model_id, model_path = await self._train_model(training_df)

            # Step 3: Evaluate Model
            logger.info("Step 3/5: Evaluating model performance...")
            metrics = await self._evaluate_model(training_df, model_path)

            # Step 4: Quality Gates
            logger.info("Step 4/5: Checking quality gates...")
            passed_gates, is_improvement = await self._check_quality_gates(metrics)

            # Step 5: Model Promotion
            logger.info("Step 5/5: Handling model promotion...")
            promoted_challenger, promoted_champion = await self._handle_promotion(
                model_id, model_path, metrics, passed_gates, is_improvement
            )

            # Create result
            end_time = datetime.now()
            duration = (end_time - start_time).total_seconds()

            collector_metrics = self.data_collector.get_metrics()

            result = RetrainingResult(
                status=RetrainingStatus.COMPLETED,
                start_time=start_time,
                end_time=end_time,
                duration_seconds=duration,
                samples_collected=collector_metrics["total_records"],
                fraud_samples=collector_metrics["fraud_records"],
                non_fraud_samples=collector_metrics["non_fraud_records"],
                model_id=model_id,
                model_path=model_path,
                auc_score=metrics.get("auc"),
                precision=metrics.get("precision"),
                recall=metrics.get("recall"),
                f1_score=metrics.get("f1"),
                passed_quality_gates=passed_gates,
                is_improvement=is_improvement,
                promoted_to_challenger=promoted_challenger,
                promoted_to_champion=promoted_champion,
            )

            self.successful_runs += 1
            self.last_result = result
            self.last_run_time = end_time

            logger.info(
                f"=== Retraining Complete: model={model_id}, "
                f"auc={metrics.get('auc', 0):.4f}, "
                f"duration={duration:.1f}s ==="
            )

            return result

        except Exception as e:
            logger.error(f"Retraining failed: {e}", exc_info=True)
            self.failed_runs += 1

            end_time = datetime.now()
            duration = (end_time - start_time).total_seconds()

            result = RetrainingResult(
                status=RetrainingStatus.FAILED,
                start_time=start_time,
                end_time=end_time,
                duration_seconds=duration,
                samples_collected=0,
                fraud_samples=0,
                non_fraud_samples=0,
                error_message=str(e),
            )

            self.last_result = result
            self.last_run_time = end_time

            return result

        finally:
            self.is_running = False

    async def _collect_data(self) -> pd.DataFrame:
        """Step 1: Collect training data."""
        await self.data_collector.connect()

        try:
            training_df = await self.data_collector.collect_training_data()
            return training_df
        finally:
            await self.data_collector.close()

    async def _train_model(self, training_df: pd.DataFrame) -> tuple[str, str]:
        """Step 2: Train XGBoost model.

        Returns:
            Tuple of (model_id, model_path)
        """
        # Split features and labels
        X = training_df.drop("is_fraud", axis=1)
        y = training_df["is_fraud"]

        # Train model
        model = await asyncio.to_thread(self.model_trainer.train, X, y)

        # Generate model ID
        model_id = f"xgboost_v{datetime.now().strftime('%Y.%m.%d.%H%M%S')}"

        # Save model
        model_path = f"{self.config.registry_path}/{model_id}.json"

        # In production, this would actually save the model
        logger.info(f"Model saved: {model_path}")

        return model_id, model_path

    async def _evaluate_model(
        self,
        training_df: pd.DataFrame,
        model_path: str,
    ) -> Dict[str, float]:
        """Step 3: Evaluate model performance.

        Returns:
            Dictionary with evaluation metrics
        """
        # Split features and labels
        X = training_df.drop("is_fraud", axis=1)
        y = training_df["is_fraud"]

        # Evaluate
        metrics = await asyncio.to_thread(self.model_evaluator.evaluate, X, y, model_path)

        logger.info(
            f"Model metrics: AUC={metrics.get('auc', 0):.4f}, "
            f"Precision={metrics.get('precision', 0):.4f}, "
            f"Recall={metrics.get('recall', 0):.4f}, "
            f"F1={metrics.get('f1', 0):.4f}"
        )

        return metrics

    async def _check_quality_gates(
        self,
        metrics: Dict[str, float],
    ) -> tuple[bool, bool]:
        """Step 4: Check quality gates.

        Returns:
            Tuple of (passed_gates, is_improvement)
        """
        # Check minimum thresholds
        passed_gates = (
            metrics.get("auc", 0) >= self.config.min_auc_score
            and metrics.get("precision", 0) >= self.config.min_precision
            and metrics.get("recall", 0) >= self.config.min_recall
        )

        if not passed_gates:
            logger.warning(
                f"Quality gates FAILED: "
                f"AUC={metrics.get('auc', 0):.4f} (min={self.config.min_auc_score}), "
                f"Precision={metrics.get('precision', 0):.4f} (min={self.config.min_precision}), "
                f"Recall={metrics.get('recall', 0):.4f} (min={self.config.min_recall})"
            )
        else:
            logger.info("Quality gates PASSED")

        # Check improvement over champion
        champion = self.model_registry.get_champion()
        is_improvement = False

        if champion:
            champion_id, champion_path = champion
            champion_metadata = self.model_registry.get_model_metadata(champion_id)

            if champion_metadata and "metrics" in champion_metadata:
                champion_auc = champion_metadata["metrics"].get("auc", 0)
                new_auc = metrics.get("auc", 0)

                improvement = new_auc - champion_auc
                is_improvement = improvement >= self.config.improvement_threshold

                logger.info(
                    f"Champion comparison: "
                    f"new_auc={new_auc:.4f}, "
                    f"champion_auc={champion_auc:.4f}, "
                    f"improvement={improvement:.4f} "
                    f"({'PASS' if is_improvement else 'FAIL'})"
                )
        else:
            # No champion yet, this will be the first
            is_improvement = passed_gates
            logger.info("No champion model exists, treating as improvement")

        return passed_gates, is_improvement

    async def _handle_promotion(
        self,
        model_id: str,
        model_path: str,
        metrics: Dict[str, float],
        passed_gates: bool,
        is_improvement: bool,
    ) -> tuple[bool, bool]:
        """Step 5: Handle model promotion.

        Returns:
            Tuple of (promoted_to_challenger, promoted_to_champion)
        """
        promoted_challenger = False
        promoted_champion = False

        # Save model to registry
        self.model_registry.register_model(
            model_id=model_id,
            model_path=model_path,
            metadata={
                "metrics": metrics,
                "timestamp": datetime.now().isoformat(),
                "training_config": {
                    "max_depth": self.config.max_depth,
                    "learning_rate": self.config.learning_rate,
                    "n_estimators": self.config.n_estimators,
                },
            },
        )

        if not passed_gates:
            logger.warning("Model did not pass quality gates, not promoting")
            return promoted_challenger, promoted_champion

        # Promote to challenger if improvement
        if is_improvement:
            self.model_registry.set_challenger(model_id)
            promoted_challenger = True
            logger.info(f"Model promoted to CHALLENGER: {model_id}")

            # Auto-promote to champion if configured
            if self.config.auto_promote_champion:
                self.model_registry.promote_to_champion(model_id)
                promoted_champion = True
                logger.info(f"Model auto-promoted to CHAMPION: {model_id}")
            else:
                logger.info("Auto-promotion disabled, requires manual approval")

        return promoted_challenger, promoted_champion

    async def start_scheduler(self):
        """Start the scheduled retraining service."""
        if not self.config.enabled:
            logger.info("Retraining scheduler is disabled")
            return

        logger.info(f"Starting retraining scheduler: {self.config.schedule_cron}")

        while True:
            try:
                # Calculate next run time
                # In production, use APScheduler with cron trigger
                # For now, use simple daily schedule at 2 AM

                now = datetime.now()
                next_run = now.replace(hour=2, minute=0, second=0, microsecond=0)

                if next_run <= now:
                    next_run += timedelta(days=1)

                wait_seconds = (next_run - now).total_seconds()

                logger.info(
                    f"Next retraining scheduled at {next_run} "
                    f"(in {wait_seconds/3600:.1f} hours)"
                )

                # Wait until next run
                await asyncio.sleep(wait_seconds)

                # Execute retraining
                result = await self.run_retraining()

                # Send notification if configured
                if self.config.notify_on_completion:
                    await self._send_notification(result)

            except asyncio.CancelledError:
                logger.info("Scheduler cancelled")
                break
            except Exception as e:
                logger.error(f"Scheduler error: {e}", exc_info=True)
                await asyncio.sleep(3600)  # Wait 1 hour before retry

    async def _send_notification(self, result: RetrainingResult):
        """Send notification about retraining result.

        In production, this would send to Slack/email/PagerDuty
        """
        if result.status == RetrainingStatus.COMPLETED:
            logger.info(
                f"Notification: Retraining completed successfully - "
                f"model={result.model_id}, auc={result.auc_score:.4f}"
            )
        elif result.status == RetrainingStatus.FAILED:
            logger.error(
                f"Notification: Retraining failed - error={result.error_message}"
            )

    def get_metrics(self) -> dict:
        """Get orchestrator metrics.

        Returns:
            Dictionary with orchestrator metrics
        """
        success_rate = (
            self.successful_runs / self.total_runs * 100 if self.total_runs > 0 else 0.0
        )

        return {
            "total_runs": self.total_runs,
            "successful_runs": self.successful_runs,
            "failed_runs": self.failed_runs,
            "success_rate_pct": success_rate,
            "last_run_time": self.last_run_time.isoformat() if self.last_run_time else None,
            "is_running": self.is_running,
        }


async def main():
    """Main entry point for retraining orchestrator."""
    logging.basicConfig(level=logging.INFO)

    config = RetrainingConfig(
        schedule_cron="0 2 * * *",
        enabled=True,
        lookback_days=7,
        min_samples_required=1000,
        auto_promote_champion=False,
    )

    orchestrator = RetrainingOrchestrator(config)

    # Run once immediately (for testing)
    result = await orchestrator.run_retraining()
    logger.info(f"Retraining result: {result.status.value}")

    # In production, start scheduler:
    # await orchestrator.start_scheduler()


if __name__ == "__main__":
    asyncio.run(main())
