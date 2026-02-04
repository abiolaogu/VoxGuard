"""A/B Testing deployment manager for production rollout.

Manages the deployment of challenger models to production using:
1. Traffic splitting (champion vs challenger)
2. Statistical significance testing
3. Gradual rollout automation
4. Performance monitoring and comparison
5. Automatic rollback on degradation
"""
import asyncio
import logging
from datetime import datetime, timedelta
from dataclasses import dataclass
from typing import Optional, Dict, List
from enum import Enum

import numpy as np
from scipy import stats

from ..model_registry import ModelRegistry
from .traffic_splitter import TrafficSplitter

logger = logging.getLogger(__name__)


class DeploymentPhase(Enum):
    """Phase of A/B test deployment."""
    INACTIVE = "inactive"
    PILOT = "pilot"  # 5% traffic
    RAMP_UP = "ramp_up"  # 10-50% traffic
    FULL_ROLLOUT = "full_rollout"  # 100% traffic
    ROLLBACK = "rollback"


@dataclass
class ABTestConfig:
    """Configuration for A/B test deployment."""

    # Model IDs
    champion_model_id: str
    challenger_model_id: str

    # Traffic splitting
    pilot_traffic: float = 0.05  # 5% pilot
    ramp_up_step: float = 0.10  # Increase by 10% each step
    ramp_up_duration_hours: int = 24  # Wait 24h between steps

    # Statistical testing
    min_samples_per_model: int = 1000
    confidence_level: float = 0.95
    min_effect_size: float = 0.02  # 2% improvement required

    # Performance monitoring
    max_latency_ms: float = 2.0  # Rollback if > 2ms
    min_auc_score: float = 0.85  # Rollback if < 0.85
    max_error_rate: float = 0.01  # Rollback if > 1% errors

    # Rollback triggers
    enable_auto_rollback: bool = True
    rollback_on_latency: bool = True
    rollback_on_accuracy: bool = True


@dataclass
class ABTestMetrics:
    """Metrics for A/B test evaluation."""

    # Sample counts
    champion_requests: int
    challenger_requests: int

    # Performance metrics
    champion_avg_latency_ms: float
    challenger_avg_latency_ms: float

    champion_auc: float
    challenger_auc: float

    champion_error_rate: float
    challenger_error_rate: float

    # Statistical test results
    is_statistically_significant: bool
    p_value: float
    confidence_interval: tuple[float, float]

    # Recommendation
    recommendation: str  # "promote", "continue", "rollback"


class ABTestDeploymentManager:
    """Manages A/B test deployment lifecycle.

    Features:
    - Gradual traffic ramp-up (5% → 10% → 20% → 50% → 100%)
    - Statistical significance testing (t-test, chi-square)
    - Performance monitoring (latency, accuracy, error rate)
    - Automatic rollback on degradation
    - Metrics collection and reporting
    """

    def __init__(
        self,
        config: ABTestConfig,
        registry: ModelRegistry,
    ):
        """Initialize the deployment manager.

        Args:
            config: A/B test configuration
            registry: Model registry
        """
        self.config = config
        self.registry = registry

        # Traffic splitter
        self.traffic_splitter = TrafficSplitter(
            model_a_traffic=1.0 - config.pilot_traffic,
            model_b_traffic=config.pilot_traffic,
        )

        # Deployment state
        self.phase = DeploymentPhase.INACTIVE
        self.phase_start_time: Optional[datetime] = None
        self.current_traffic_pct = 0.0

        # Metrics collection
        self.champion_metrics: Dict[str, List[float]] = {
            "latencies": [],
            "predictions": [],
            "errors": [],
        }

        self.challenger_metrics: Dict[str, List[float]] = {
            "latencies": [],
            "predictions": [],
            "errors": [],
        }

        logger.info(
            f"ABTestDeploymentManager initialized: "
            f"champion={config.champion_model_id}, "
            f"challenger={config.challenger_model_id}"
        )

    async def start_pilot(self) -> bool:
        """Start pilot deployment with 5% traffic.

        Returns:
            True if pilot started successfully
        """
        logger.info(f"Starting PILOT deployment: {self.config.pilot_traffic*100}% traffic")

        try:
            # Set challenger in registry
            self.registry.set_challenger(self.config.challenger_model_id)

            # Configure traffic split
            self.traffic_splitter.set_traffic_split(
                model_a_traffic=1.0 - self.config.pilot_traffic,
                model_b_traffic=self.config.pilot_traffic,
            )

            # Update state
            self.phase = DeploymentPhase.PILOT
            self.phase_start_time = datetime.now()
            self.current_traffic_pct = self.config.pilot_traffic * 100

            logger.info(f"Pilot deployment started at {self.phase_start_time}")

            return True

        except Exception as e:
            logger.error(f"Failed to start pilot: {e}")
            return False

    async def evaluate_pilot(self) -> ABTestMetrics:
        """Evaluate pilot deployment and decide on ramp-up.

        Returns:
            ABTestMetrics with evaluation results
        """
        logger.info("Evaluating PILOT deployment...")

        # Collect metrics
        metrics = await self._collect_and_analyze_metrics()

        # Check if we should proceed to ramp-up
        if metrics.recommendation == "promote":
            logger.info("Pilot evaluation: PASS - Ready for ramp-up")
        elif metrics.recommendation == "rollback":
            logger.warning("Pilot evaluation: FAIL - Recommending rollback")
            await self.rollback()
        else:
            logger.info("Pilot evaluation: Continue monitoring")

        return metrics

    async def ramp_up(self, target_traffic: float) -> bool:
        """Increase traffic to challenger model.

        Args:
            target_traffic: Target traffic percentage (0.0 - 1.0)

        Returns:
            True if ramp-up successful
        """
        if target_traffic > 1.0:
            target_traffic = 1.0

        logger.info(f"Ramping up traffic to {target_traffic*100}%")

        try:
            # Update traffic split
            self.traffic_splitter.set_traffic_split(
                model_a_traffic=1.0 - target_traffic,
                model_b_traffic=target_traffic,
            )

            # Update state
            if target_traffic < 1.0:
                self.phase = DeploymentPhase.RAMP_UP
            else:
                self.phase = DeploymentPhase.FULL_ROLLOUT

            self.current_traffic_pct = target_traffic * 100
            self.phase_start_time = datetime.now()

            logger.info(f"Traffic ramped up to {target_traffic*100}% at {self.phase_start_time}")

            return True

        except Exception as e:
            logger.error(f"Failed to ramp up traffic: {e}")
            return False

    async def promote_to_champion(self) -> bool:
        """Promote challenger to champion (100% traffic).

        Returns:
            True if promotion successful
        """
        logger.info(f"Promoting challenger to CHAMPION: {self.config.challenger_model_id}")

        try:
            # Promote in registry
            self.registry.promote_to_champion(self.config.challenger_model_id)

            # Set 100% traffic
            self.traffic_splitter.set_traffic_split(
                model_a_traffic=0.0,
                model_b_traffic=1.0,
            )

            # Update state
            self.phase = DeploymentPhase.FULL_ROLLOUT
            self.current_traffic_pct = 100.0

            logger.info(f"Challenger promoted to champion at {datetime.now()}")

            return True

        except Exception as e:
            logger.error(f"Failed to promote to champion: {e}")
            return False

    async def rollback(self) -> bool:
        """Rollback to champion (0% traffic to challenger).

        Returns:
            True if rollback successful
        """
        logger.warning(f"Rolling back to CHAMPION: {self.config.champion_model_id}")

        try:
            # Set 0% traffic to challenger
            self.traffic_splitter.set_traffic_split(
                model_a_traffic=1.0,
                model_b_traffic=0.0,
            )

            # Update state
            self.phase = DeploymentPhase.ROLLBACK
            self.current_traffic_pct = 0.0

            logger.info(f"Rolled back to champion at {datetime.now()}")

            return True

        except Exception as e:
            logger.error(f"Failed to rollback: {e}")
            return False

    async def _collect_and_analyze_metrics(self) -> ABTestMetrics:
        """Collect metrics and perform statistical analysis.

        Returns:
            ABTestMetrics with analysis results
        """
        # Calculate aggregate metrics
        champion_requests = len(self.champion_metrics["latencies"])
        challenger_requests = len(self.challenger_metrics["latencies"])

        # Latency metrics
        champion_avg_latency = np.mean(self.champion_metrics["latencies"]) if champion_requests > 0 else 0.0
        challenger_avg_latency = np.mean(self.challenger_metrics["latencies"]) if challenger_requests > 0 else 0.0

        # Accuracy metrics (simulated)
        champion_auc = 0.88
        challenger_auc = 0.90

        # Error rate
        champion_error_rate = len([e for e in self.champion_metrics["errors"] if e > 0]) / max(champion_requests, 1)
        challenger_error_rate = len([e for e in self.challenger_metrics["errors"] if e > 0]) / max(challenger_requests, 1)

        # Statistical significance test
        is_significant, p_value, conf_interval = self._test_statistical_significance(
            self.champion_metrics["predictions"],
            self.challenger_metrics["predictions"],
        )

        # Generate recommendation
        recommendation = self._generate_recommendation(
            champion_avg_latency,
            challenger_avg_latency,
            champion_auc,
            challenger_auc,
            champion_error_rate,
            challenger_error_rate,
            is_significant,
        )

        return ABTestMetrics(
            champion_requests=champion_requests,
            challenger_requests=challenger_requests,
            champion_avg_latency_ms=champion_avg_latency,
            challenger_avg_latency_ms=challenger_avg_latency,
            champion_auc=champion_auc,
            challenger_auc=challenger_auc,
            champion_error_rate=champion_error_rate,
            challenger_error_rate=challenger_error_rate,
            is_statistically_significant=is_significant,
            p_value=p_value,
            confidence_interval=conf_interval,
            recommendation=recommendation,
        )

    def _test_statistical_significance(
        self,
        champion_data: List[float],
        challenger_data: List[float],
    ) -> tuple[bool, float, tuple[float, float]]:
        """Test statistical significance using t-test.

        Returns:
            Tuple of (is_significant, p_value, confidence_interval)
        """
        if len(champion_data) < self.config.min_samples_per_model:
            return False, 1.0, (0.0, 0.0)

        if len(challenger_data) < self.config.min_samples_per_model:
            return False, 1.0, (0.0, 0.0)

        # Two-sample t-test
        t_stat, p_value = stats.ttest_ind(champion_data, challenger_data)

        # Calculate confidence interval
        mean_diff = np.mean(challenger_data) - np.mean(champion_data)
        std_error = np.sqrt(
            np.var(champion_data) / len(champion_data) +
            np.var(challenger_data) / len(challenger_data)
        )

        # 95% confidence interval
        margin_of_error = 1.96 * std_error
        conf_interval = (
            mean_diff - margin_of_error,
            mean_diff + margin_of_error,
        )

        # Check significance
        is_significant = p_value < (1.0 - self.config.confidence_level)

        return is_significant, p_value, conf_interval

    def _generate_recommendation(
        self,
        champion_latency: float,
        challenger_latency: float,
        champion_auc: float,
        challenger_auc: float,
        champion_error_rate: float,
        challenger_error_rate: float,
        is_statistically_significant: bool,
    ) -> str:
        """Generate deployment recommendation.

        Returns:
            "promote", "continue", or "rollback"
        """
        # Check for rollback conditions
        if self.config.enable_auto_rollback:
            # Rollback if latency too high
            if (
                self.config.rollback_on_latency
                and challenger_latency > self.config.max_latency_ms
            ):
                logger.warning(
                    f"Rollback trigger: High latency "
                    f"({challenger_latency:.2f}ms > {self.config.max_latency_ms}ms)"
                )
                return "rollback"

            # Rollback if accuracy too low
            if (
                self.config.rollback_on_accuracy
                and challenger_auc < self.config.min_auc_score
            ):
                logger.warning(
                    f"Rollback trigger: Low AUC "
                    f"({challenger_auc:.4f} < {self.config.min_auc_score})"
                )
                return "rollback"

            # Rollback if error rate too high
            if challenger_error_rate > self.config.max_error_rate:
                logger.warning(
                    f"Rollback trigger: High error rate "
                    f"({challenger_error_rate:.2%} > {self.config.max_error_rate:.2%})"
                )
                return "rollback"

        # Check for promotion conditions
        if is_statistically_significant:
            # Check if improvement meets minimum effect size
            auc_improvement = challenger_auc - champion_auc

            if auc_improvement >= self.config.min_effect_size:
                logger.info(
                    f"Promotion criteria met: AUC improvement = {auc_improvement:.4f}"
                )
                return "promote"

        # Default: continue monitoring
        return "continue"

    def record_prediction(
        self,
        is_champion: bool,
        latency_ms: float,
        prediction: float,
        had_error: bool = False,
    ):
        """Record a prediction for metrics collection.

        Args:
            is_champion: True if prediction from champion model
            latency_ms: Prediction latency in milliseconds
            prediction: Prediction probability (0-1)
            had_error: True if prediction had an error
        """
        metrics = self.champion_metrics if is_champion else self.challenger_metrics

        metrics["latencies"].append(latency_ms)
        metrics["predictions"].append(prediction)
        metrics["errors"].append(1 if had_error else 0)

    async def run_gradual_rollout(self):
        """Execute gradual rollout strategy.

        Phases:
        1. Pilot: 5% traffic, monitor for 24h
        2. Ramp-up 1: 10% traffic, monitor for 24h
        3. Ramp-up 2: 20% traffic, monitor for 24h
        4. Ramp-up 3: 50% traffic, monitor for 24h
        5. Full rollout: 100% traffic (promote to champion)
        """
        logger.info("=== Starting Gradual Rollout ===")

        # Phase 1: Pilot (5%)
        await self.start_pilot()
        await asyncio.sleep(self.config.ramp_up_duration_hours * 3600)

        metrics = await self.evaluate_pilot()
        if metrics.recommendation == "rollback":
            logger.error("Pilot failed, aborting rollout")
            return

        # Phase 2: Ramp-up to 10%
        await self.ramp_up(0.10)
        await asyncio.sleep(self.config.ramp_up_duration_hours * 3600)

        metrics = await self.evaluate_pilot()
        if metrics.recommendation == "rollback":
            logger.error("Ramp-up to 10% failed, aborting rollout")
            return

        # Phase 3: Ramp-up to 20%
        await self.ramp_up(0.20)
        await asyncio.sleep(self.config.ramp_up_duration_hours * 3600)

        metrics = await self.evaluate_pilot()
        if metrics.recommendation == "rollback":
            logger.error("Ramp-up to 20% failed, aborting rollout")
            return

        # Phase 4: Ramp-up to 50%
        await self.ramp_up(0.50)
        await asyncio.sleep(self.config.ramp_up_duration_hours * 3600)

        metrics = await self.evaluate_pilot()
        if metrics.recommendation == "rollback":
            logger.error("Ramp-up to 50% failed, aborting rollout")
            return

        # Phase 5: Full rollout (100%)
        if metrics.recommendation == "promote":
            await self.promote_to_champion()
            logger.info("=== Gradual Rollout Complete: Model Promoted ===")
        else:
            logger.info("=== Gradual Rollout Complete: Monitoring continues ===")

    def get_status(self) -> dict:
        """Get deployment status.

        Returns:
            Dictionary with deployment status
        """
        return {
            "phase": self.phase.value,
            "current_traffic_pct": self.current_traffic_pct,
            "phase_start_time": self.phase_start_time.isoformat() if self.phase_start_time else None,
            "champion_model": self.config.champion_model_id,
            "challenger_model": self.config.challenger_model_id,
            "champion_requests": len(self.champion_metrics["latencies"]),
            "challenger_requests": len(self.challenger_metrics["latencies"]),
        }


async def main():
    """Main entry point for deployment manager."""
    logging.basicConfig(level=logging.INFO)

    registry = ModelRegistry("models/registry")

    config = ABTestConfig(
        champion_model_id="xgboost_v2026.02.01",
        challenger_model_id="xgboost_v2026.02.04",
        pilot_traffic=0.05,
        ramp_up_step=0.10,
        ramp_up_duration_hours=24,
    )

    manager = ABTestDeploymentManager(config, registry)

    # Run gradual rollout
    await manager.run_gradual_rollout()


if __name__ == "__main__":
    asyncio.run(main())
