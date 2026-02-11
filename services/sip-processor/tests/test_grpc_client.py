"""Unit tests for gRPC ML inference client."""
import asyncio
import pytest

import sys
sys.path.append("..")

from app.inference.grpc_client import (
    MLInferenceClient,
    InferenceMode,
    GRPCPredictionResponse,
)


@pytest.fixture
def grpc_client():
    """Create gRPC client instance."""
    return MLInferenceClient(
        grpc_host="localhost",
        grpc_port=50051,
        timeout_ms=100,
        max_retries=3,
        circuit_breaker_threshold=5,
        circuit_breaker_timeout=30,
        mode=InferenceMode.HYBRID,
        local_model_path="models/xgboost_masking.json",
    )


@pytest.fixture
def grpc_only_client():
    """Create gRPC-only client (no fallback)."""
    return MLInferenceClient(
        grpc_host="localhost",
        grpc_port=50051,
        timeout_ms=100,
        mode=InferenceMode.GRPC_PRIMARY,
    )


class TestMLInferenceClient:
    """Tests for MLInferenceClient."""

    def test_initialization(self, grpc_client):
        """Test client initialization."""
        assert grpc_client.grpc_host == "localhost"
        assert grpc_client.grpc_port == 50051
        assert grpc_client.mode == InferenceMode.HYBRID
        assert grpc_client.circuit_open is False
        assert grpc_client.total_requests == 0

    @pytest.mark.asyncio
    async def test_predict_success(self, grpc_client):
        """Test successful prediction."""
        features = [50.0, 100.0, 0.8, 1.0, 5.0, 2.0, 0.3, 1.0]

        response = await grpc_client.predict(features, request_id="test-001")

        assert isinstance(response, GRPCPredictionResponse)
        assert isinstance(response.is_fraud, bool)
        assert 0.0 <= response.probability <= 1.0
        assert response.latency_ms > 0
        assert grpc_client.total_requests == 1

    @pytest.mark.asyncio
    async def test_predict_high_risk_features(self, grpc_client):
        """Test prediction with high-risk features."""
        # High-risk features: many callers, high overlap, CLI mismatch
        features = [30.0, 50.0, 0.9, 1.0, 8.0, 3.0, 0.5, 1.0]

        response = await grpc_client.predict(features)

        assert isinstance(response, GRPCPredictionResponse)
        # With these high-risk features, probability should be high
        assert response.probability > 0.5

    @pytest.mark.asyncio
    async def test_predict_low_risk_features(self, grpc_client):
        """Test prediction with low-risk features."""
        # Low-risk features: few callers, low overlap, no CLI mismatch
        features = [80.0, 200.0, 0.2, 0.0, 2.0, 0.5, 0.1, 0.0]

        response = await grpc_client.predict(features)

        assert isinstance(response, GRPCPredictionResponse)
        # With these low-risk features, probability should be low
        assert response.probability < 0.5

    @pytest.mark.asyncio
    async def test_health_check(self, grpc_client):
        """Test health check."""
        is_healthy = await grpc_client.health_check()

        # Should be healthy initially (circuit not open)
        assert is_healthy is True

    def test_get_metrics(self, grpc_client):
        """Test getting client metrics."""
        # Simulate some requests
        grpc_client.total_requests = 100
        grpc_client.grpc_requests = 90
        grpc_client.local_requests = 10
        grpc_client.failed_requests = 5
        grpc_client.total_latency_ms = 100.0

        metrics = grpc_client.get_metrics()

        assert metrics["total_requests"] == 100
        assert metrics["grpc_requests"] == 90
        assert metrics["local_requests"] == 10
        assert metrics["failed_requests"] == 5
        assert metrics["avg_latency_ms"] == 1.0
        assert metrics["grpc_percentage"] == 90.0
        assert metrics["local_percentage"] == 10.0
        assert metrics["circuit_open"] is False

    def test_reset_circuit_breaker(self, grpc_client):
        """Test resetting circuit breaker."""
        # Simulate circuit breaker opening
        grpc_client.circuit_open = True
        grpc_client.consecutive_failures = 10

        # Reset
        grpc_client.reset_circuit_breaker()

        assert grpc_client.circuit_open is False
        assert grpc_client.consecutive_failures == 0

    @pytest.mark.asyncio
    async def test_circuit_breaker_opens_on_failures(self, grpc_only_client):
        """Test that circuit breaker opens after threshold failures."""
        # Note: This test would need to mock gRPC failures
        # For now, just verify the initial state
        assert grpc_only_client.circuit_open is False
        assert grpc_only_client.consecutive_failures == 0

    @pytest.mark.asyncio
    async def test_predict_multiple_requests(self, grpc_client):
        """Test multiple predictions."""
        features = [50.0, 100.0, 0.5, 0.0, 3.0, 1.0, 0.2, 0.0]

        # Make multiple predictions
        for i in range(10):
            response = await grpc_client.predict(features, request_id=f"test-{i}")
            assert isinstance(response, GRPCPredictionResponse)

        # Verify metrics
        assert grpc_client.total_requests == 10
        assert grpc_client.grpc_requests > 0  # Should have used gRPC

    def test_inference_mode_hybrid(self):
        """Test HYBRID mode initialization."""
        client = MLInferenceClient(
            mode=InferenceMode.HYBRID,
            local_model_path="models/xgboost_masking.json",
        )

        assert client.mode == InferenceMode.HYBRID
        # Should have local engine initialized
        # (In production, this would be verified)

    def test_inference_mode_grpc_primary(self):
        """Test GRPC_PRIMARY mode initialization."""
        client = MLInferenceClient(
            mode=InferenceMode.GRPC_PRIMARY,
        )

        assert client.mode == InferenceMode.GRPC_PRIMARY
        # Should not have local engine
        assert client._local_engine is None

    def test_inference_mode_local_fallback(self):
        """Test LOCAL_FALLBACK mode initialization."""
        client = MLInferenceClient(
            mode=InferenceMode.LOCAL_FALLBACK,
            local_model_path="models/xgboost_masking.json",
        )

        assert client.mode == InferenceMode.LOCAL_FALLBACK
        # Should have local engine initialized

    @pytest.mark.asyncio
    async def test_close_client(self, grpc_client):
        """Test closing client."""
        await grpc_client.close()
        # Should cleanup resources (verify no errors)


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
