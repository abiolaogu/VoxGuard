"""Traffic splitting for A/B testing."""
import logging
import random
from dataclasses import dataclass
from typing import Optional

logger = logging.getLogger(__name__)


@dataclass
class TrafficConfig:
    """Configuration for traffic splitting."""

    model_a_traffic: float  # Fraction for model A (0-1)
    model_b_traffic: float  # Fraction for model B (0-1)

    def __post_init__(self):
        """Validate traffic configuration."""
        total = self.model_a_traffic + self.model_b_traffic
        if not (0.99 <= total <= 1.01):  # Allow small floating point error
            raise ValueError(
                f"Traffic splits must sum to 1.0, got {total}"
            )


class TrafficSplitter:
    """Split traffic between two models for A/B testing."""

    def __init__(
        self,
        model_a_traffic: float = 0.9,
        model_b_traffic: float = 0.1,
        seed: Optional[int] = None,
    ):
        """Initialize the traffic splitter.

        Args:
            model_a_traffic: Fraction of traffic for model A
            model_b_traffic: Fraction of traffic for model B
            seed: Random seed for reproducibility
        """
        self.config = TrafficConfig(
            model_a_traffic=model_a_traffic, model_b_traffic=model_b_traffic
        )

        if seed is not None:
            random.seed(seed)

        self.model_a_count = 0
        self.model_b_count = 0

        logger.info(
            f"Traffic splitter initialized: "
            f"Model A={model_a_traffic*100:.1f}%, "
            f"Model B={model_b_traffic*100:.1f}%"
        )

    def should_use_model_b(self) -> bool:
        """Decide whether to use model B for this request.

        Returns:
            True if model B should be used, False for model A
        """
        use_b = random.random() < self.config.model_b_traffic

        if use_b:
            self.model_b_count += 1
        else:
            self.model_a_count += 1

        return use_b

    def get_model_assignment(self, request_id: str) -> str:
        """Get model assignment for a request.

        Args:
            request_id: Unique request identifier

        Returns:
            "model_a" or "model_b"
        """
        # Use hash-based assignment for deterministic routing
        hash_value = hash(request_id) % 100
        threshold = int(self.config.model_a_traffic * 100)

        if hash_value < threshold:
            self.model_a_count += 1
            return "model_a"
        else:
            self.model_b_count += 1
            return "model_b"

    def update_traffic_split(
        self, model_a_traffic: float, model_b_traffic: float
    ) -> None:
        """Update the traffic split configuration.

        Args:
            model_a_traffic: New fraction for model A
            model_b_traffic: New fraction for model B
        """
        self.config = TrafficConfig(
            model_a_traffic=model_a_traffic, model_b_traffic=model_b_traffic
        )

        logger.info(
            f"Traffic split updated: "
            f"Model A={model_a_traffic*100:.1f}%, "
            f"Model B={model_b_traffic*100:.1f}%"
        )

    def get_traffic_stats(self) -> dict:
        """Get traffic statistics.

        Returns:
            Dictionary with traffic counts and percentages
        """
        total = self.model_a_count + self.model_b_count

        if total == 0:
            return {
                "model_a_count": 0,
                "model_b_count": 0,
                "model_a_percentage": 0.0,
                "model_b_percentage": 0.0,
                "total_requests": 0,
            }

        return {
            "model_a_count": self.model_a_count,
            "model_b_count": self.model_b_count,
            "model_a_percentage": self.model_a_count / total * 100,
            "model_b_percentage": self.model_b_count / total * 100,
            "total_requests": total,
        }

    def reset_counters(self) -> None:
        """Reset traffic counters."""
        self.model_a_count = 0
        self.model_b_count = 0
        logger.info("Traffic counters reset")


class GradualRollout:
    """Gradually increase traffic to a new model."""

    def __init__(
        self,
        initial_traffic: float = 0.1,
        step_percentage: float = 0.1,
        max_traffic: float = 1.0,
    ):
        """Initialize gradual rollout.

        Args:
            initial_traffic: Starting traffic percentage (0-1)
            step_percentage: Increment per step (0-1)
            max_traffic: Maximum traffic percentage (0-1)
        """
        self.current_traffic = initial_traffic
        self.step_percentage = step_percentage
        self.max_traffic = max_traffic

        logger.info(
            f"Gradual rollout initialized: "
            f"start={initial_traffic*100:.1f}%, "
            f"step={step_percentage*100:.1f}%, "
            f"max={max_traffic*100:.1f}%"
        )

    def increase_traffic(self) -> float:
        """Increase traffic by one step.

        Returns:
            New traffic percentage
        """
        old_traffic = self.current_traffic
        self.current_traffic = min(
            self.current_traffic + self.step_percentage, self.max_traffic
        )

        logger.info(
            f"Traffic increased: "
            f"{old_traffic*100:.1f}% → {self.current_traffic*100:.1f}%"
        )

        return self.current_traffic

    def is_complete(self) -> bool:
        """Check if rollout is complete.

        Returns:
            True if at maximum traffic
        """
        return self.current_traffic >= self.max_traffic

    def get_current_split(self) -> tuple[float, float]:
        """Get current traffic split.

        Returns:
            Tuple of (model_a_traffic, model_b_traffic)
        """
        return 1.0 - self.current_traffic, self.current_traffic
