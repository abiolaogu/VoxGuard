"""gRPC inference server for real-time ML predictions."""
import asyncio
import logging
import time
from concurrent import futures
from dataclasses import dataclass
from typing import List, Optional, Dict

import grpc
import numpy as np

from .model_registry import ModelRegistry
from .ab_testing.traffic_splitter import TrafficSplitter

logger = logging.getLogger(__name__)

# Try to import XGBoost
try:
    import xgboost as xgb

    XGBOOST_AVAILABLE = True
except ImportError:
    XGBOOST_AVAILABLE = False
    xgb = None


# Proto definitions (simplified - in production, generate from .proto file)
@dataclass
class PredictionRequest:
    """Request for fraud prediction."""

    features: List[float]  # 8 features
    request_id: str = ""
    model_version: Optional[str] = None


@dataclass
class PredictionResponse:
    """Response with fraud prediction."""

    is_fraud: bool
    probability: float
    model_version: str
    latency_ms: float


class InferenceServer:
    """gRPC server for real-time model inference."""

    def __init__(
        self,
        registry_path: str = "models/registry",
        host: str = "0.0.0.0",
        port: int = 50051,
        max_workers: int = 10,
        batch_size: int = 32,
        batch_timeout_ms: int = 10,
        enable_ab_testing: bool = False,
    ):
        """Initialize the inference server.

        Args:
            registry_path: Path to model registry
            host: Server host
            port: Server port
            max_workers: Max gRPC workers
            batch_size: Batch size for inference
            batch_timeout_ms: Max wait time to fill batch
            enable_ab_testing: Enable A/B testing
        """
        if not XGBOOST_AVAILABLE:
            raise RuntimeError("XGBoost is not installed")

        self.host = host
        self.port = port
        self.max_workers = max_workers
        self.batch_size = batch_size
        self.batch_timeout_ms = batch_timeout_ms / 1000.0  # Convert to seconds

        # Model registry
        self.registry = ModelRegistry(registry_path)

        # Load champion model
        champion = self.registry.get_champion()
        if not champion:
            raise RuntimeError("No champion model found in registry")

        self.champion_id, champion_path = champion
        self.champion_model = xgb.Booster()
        self.champion_model.load_model(champion_path)
        logger.info(f"Loaded champion model: {self.champion_id}")

        # A/B testing
        self.enable_ab_testing = enable_ab_testing
        self.traffic_splitter: Optional[TrafficSplitter] = None
        self.challenger_model: Optional[xgb.Booster] = None
        self.challenger_id: Optional[str] = None

        # Batching
        self.request_queue: asyncio.Queue = asyncio.Queue()
        self.batch_processor_task: Optional[asyncio.Task] = None

        # Metrics
        self.total_requests = 0
        self.champion_requests = 0
        self.challenger_requests = 0
        self.total_latency_ms = 0.0

    def set_challenger_model(self, model_id: str) -> bool:
        """Set a challenger model for A/B testing.

        Args:
            model_id: Model ID from registry

        Returns:
            True if successful
        """
        model_path = self.registry.get_model_path(model_id)
        if not model_path:
            logger.error(f"Model {model_id} not found in registry")
            return False

        self.challenger_model = xgb.Booster()
        self.challenger_model.load_model(model_path)
        self.challenger_id = model_id

        # Initialize traffic splitter
        self.traffic_splitter = TrafficSplitter(
            model_a_traffic=0.9, model_b_traffic=0.1  # 90/10 split
        )

        logger.info(f"Set challenger model: {model_id} (10% traffic)")
        return True

    def predict(self, features: np.ndarray) -> tuple[np.ndarray, str]:
        """Make prediction with the appropriate model.

        Args:
            features: Feature array of shape (n_samples, 8)

        Returns:
            Tuple of (probabilities, model_id)
        """
        # A/B testing: decide which model to use
        if (
            self.enable_ab_testing
            and self.traffic_splitter
            and self.challenger_model
        ):
            use_challenger = self.traffic_splitter.should_use_model_b()

            if use_challenger:
                self.challenger_requests += 1
                dmatrix = xgb.DMatrix(features)
                proba = self.challenger_model.predict(dmatrix)
                return proba, self.challenger_id
            else:
                self.champion_requests += 1
                dmatrix = xgb.DMatrix(features)
                proba = self.champion_model.predict(dmatrix)
                return proba, self.champion_id
        else:
            # Use champion only
            self.champion_requests += 1
            dmatrix = xgb.DMatrix(features)
            proba = self.champion_model.predict(dmatrix)
            return proba, self.champion_id

    async def handle_request(
        self, request: PredictionRequest
    ) -> PredictionResponse:
        """Handle a single prediction request.

        Args:
            request: Prediction request

        Returns:
            Prediction response
        """
        start_time = time.time()

        # Convert features to numpy array
        features = np.array([request.features])

        # Make prediction
        proba, model_id = self.predict(features)
        probability = float(proba[0])

        # Calculate latency
        latency_ms = (time.time() - start_time) * 1000

        # Update metrics
        self.total_requests += 1
        self.total_latency_ms += latency_ms

        return PredictionResponse(
            is_fraud=probability >= 0.7,
            probability=probability,
            model_version=model_id,
            latency_ms=latency_ms,
        )

    async def batch_processor(self):
        """Process requests in batches for efficiency."""
        while True:
            batch = []
            futures_list = []

            # Collect batch with timeout
            timeout = time.time() + self.batch_timeout_ms

            while len(batch) < self.batch_size and time.time() < timeout:
                try:
                    request, future = await asyncio.wait_for(
                        self.request_queue.get(), timeout=0.001
                    )
                    batch.append(request)
                    futures_list.append(future)
                except asyncio.TimeoutError:
                    break

            if not batch:
                await asyncio.sleep(0.001)
                continue

            # Process batch
            start_time = time.time()

            features = np.array([req.features for req in batch])
            proba, model_id = self.predict(features)

            latency_ms = (time.time() - start_time) * 1000

            # Set results
            for i, future in enumerate(futures_list):
                response = PredictionResponse(
                    is_fraud=float(proba[i]) >= 0.7,
                    probability=float(proba[i]),
                    model_version=model_id,
                    latency_ms=latency_ms / len(batch),
                )
                if not future.cancelled():
                    future.set_result(response)

            # Update metrics
            self.total_requests += len(batch)
            self.total_latency_ms += latency_ms

    async def start_batch_processor(self):
        """Start the batch processing task."""
        self.batch_processor_task = asyncio.create_task(self.batch_processor())
        logger.info("Batch processor started")

    async def stop_batch_processor(self):
        """Stop the batch processing task."""
        if self.batch_processor_task:
            self.batch_processor_task.cancel()
            try:
                await self.batch_processor_task
            except asyncio.CancelledError:
                pass
            logger.info("Batch processor stopped")

    def get_metrics(self) -> Dict[str, float]:
        """Get server metrics.

        Returns:
            Metrics dictionary
        """
        avg_latency = (
            self.total_latency_ms / self.total_requests if self.total_requests > 0 else 0.0
        )

        metrics = {
            "total_requests": self.total_requests,
            "champion_requests": self.champion_requests,
            "challenger_requests": self.challenger_requests,
            "avg_latency_ms": avg_latency,
            "champion_traffic_pct": (
                self.champion_requests / self.total_requests * 100
                if self.total_requests > 0
                else 0.0
            ),
        }

        return metrics

    async def serve(self):
        """Start the gRPC server."""
        logger.info(f"Starting inference server on {self.host}:{self.port}")
        logger.info(f"Champion model: {self.champion_id}")

        if self.enable_ab_testing and self.challenger_id:
            logger.info(f"Challenger model: {self.challenger_id} (10% traffic)")

        # Start batch processor
        await self.start_batch_processor()

        # In production, this would be a real gRPC server
        # For now, we'll keep the server running
        try:
            while True:
                await asyncio.sleep(60)
                metrics = self.get_metrics()
                logger.info(
                    f"Server metrics: {metrics['total_requests']} requests, "
                    f"avg latency {metrics['avg_latency_ms']:.2f}ms"
                )
        except asyncio.CancelledError:
            logger.info("Server shutting down")
            await self.stop_batch_processor()


async def main():
    """Main entry point."""
    logging.basicConfig(level=logging.INFO)

    server = InferenceServer(
        registry_path="models/registry",
        host="0.0.0.0",
        port=50051,
        max_workers=10,
        batch_size=32,
        batch_timeout_ms=10,
        enable_ab_testing=False,
    )

    await server.serve()


if __name__ == "__main__":
    asyncio.run(main())
