"""Unit tests for A/B testing deployment manager."""
import asyncio
import pytest
from datetime import datetime

import sys
sys.path.append("..")

from ab_testing.deployment_manager import (
    ABTestDeploymentManager,
    ABTestConfig,
    DeploymentPhase,
)
from model_registry import ModelRegistry


@pytest.fixture
def test_registry(tmp_path):
    """Create a test model registry."""
    registry_path = tmp_path / "registry"
    registry_path.mkdir()
    return ModelRegistry(str(registry_path))


@pytest.fixture
def test_config():
    """Create test A/B test configuration."""
    return ABTestConfig(
        champion_model_id="xgboost_v2026.01.01",
        challenger_model_id="xgboost_v2026.02.04",
        pilot_traffic=0.05,
        ramp_up_step=0.10,
        ramp_up_duration_hours=1,  # Short for testing
        min_samples_per_model=10,  # Low for testing
    )


@pytest.fixture
def deployment_manager(test_config, test_registry):
    """Create deployment manager instance."""
    return ABTestDeploymentManager(test_config, test_registry)


class TestABTestDeploymentManager:
    """Tests for ABTestDeploymentManager."""

    @pytest.mark.asyncio
    async def test_initialization(self, deployment_manager, test_config):
        """Test deployment manager initialization."""
        assert deployment_manager.phase == DeploymentPhase.INACTIVE
        assert deployment_manager.current_traffic_pct == 0.0
        assert deployment_manager.config == test_config

    @pytest.mark.asyncio
    async def test_start_pilot(self, deployment_manager):
        """Test starting pilot deployment."""
        success = await deployment_manager.start_pilot()

        assert success is True
        assert deployment_manager.phase == DeploymentPhase.PILOT
        assert deployment_manager.current_traffic_pct == 5.0
        assert deployment_manager.phase_start_time is not None

    @pytest.mark.asyncio
    async def test_ramp_up(self, deployment_manager):
        """Test traffic ramp-up."""
        # Start pilot first
        await deployment_manager.start_pilot()

        # Ramp up to 20%
        success = await deployment_manager.ramp_up(0.20)

        assert success is True
        assert deployment_manager.phase == DeploymentPhase.RAMP_UP
        assert deployment_manager.current_traffic_pct == 20.0

    @pytest.mark.asyncio
    async def test_promote_to_champion(self, deployment_manager, test_registry):
        """Test promoting challenger to champion."""
        # Register both models first
        test_registry.register_model(
            model_id=deployment_manager.config.champion_model_id,
            model_path="/tmp/champion.json",
            metadata={"metrics": {"auc": 0.88}},
        )

        test_registry.register_model(
            model_id=deployment_manager.config.challenger_model_id,
            model_path="/tmp/challenger.json",
            metadata={"metrics": {"auc": 0.90}},
        )

        test_registry.set_champion(deployment_manager.config.champion_model_id)

        # Promote challenger
        success = await deployment_manager.promote_to_champion()

        assert success is True
        assert deployment_manager.phase == DeploymentPhase.FULL_ROLLOUT
        assert deployment_manager.current_traffic_pct == 100.0

        # Verify champion was updated in registry
        champion = test_registry.get_champion()
        assert champion is not None
        assert champion[0] == deployment_manager.config.challenger_model_id

    @pytest.mark.asyncio
    async def test_rollback(self, deployment_manager):
        """Test rollback to champion."""
        # Start pilot first
        await deployment_manager.start_pilot()

        # Rollback
        success = await deployment_manager.rollback()

        assert success is True
        assert deployment_manager.phase == DeploymentPhase.ROLLBACK
        assert deployment_manager.current_traffic_pct == 0.0

    def test_record_prediction_champion(self, deployment_manager):
        """Test recording champion prediction."""
        deployment_manager.record_prediction(
            is_champion=True,
            latency_ms=0.8,
            prediction=0.75,
            had_error=False,
        )

        assert len(deployment_manager.champion_metrics["latencies"]) == 1
        assert deployment_manager.champion_metrics["latencies"][0] == 0.8
        assert len(deployment_manager.challenger_metrics["latencies"]) == 0

    def test_record_prediction_challenger(self, deployment_manager):
        """Test recording challenger prediction."""
        deployment_manager.record_prediction(
            is_champion=False,
            latency_ms=0.9,
            prediction=0.85,
            had_error=False,
        )

        assert len(deployment_manager.challenger_metrics["latencies"]) == 1
        assert deployment_manager.challenger_metrics["latencies"][0] == 0.9
        assert len(deployment_manager.champion_metrics["latencies"]) == 0

    @pytest.mark.asyncio
    async def test_evaluate_pilot(self, deployment_manager):
        """Test pilot evaluation."""
        # Record some metrics
        for _ in range(20):
            deployment_manager.record_prediction(
                is_champion=True, latency_ms=0.8, prediction=0.75
            )
            deployment_manager.record_prediction(
                is_champion=False, latency_ms=0.9, prediction=0.85
            )

        metrics = await deployment_manager.evaluate_pilot()

        assert metrics.champion_requests == 20
        assert metrics.challenger_requests == 20
        assert metrics.champion_avg_latency_ms == 0.8
        assert metrics.challenger_avg_latency_ms == 0.9

    def test_get_status(self, deployment_manager):
        """Test getting deployment status."""
        status = deployment_manager.get_status()

        assert status["phase"] == DeploymentPhase.INACTIVE.value
        assert status["current_traffic_pct"] == 0.0
        assert status["champion_model"] == deployment_manager.config.champion_model_id
        assert status["challenger_model"] == deployment_manager.config.challenger_model_id


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
