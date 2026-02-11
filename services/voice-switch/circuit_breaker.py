"""
Circuit Breaker Pattern Implementation for VoxGuard
Protects services from cascading failures and provides graceful degradation

Author: Claude (VoxGuard Autonomous Factory)
Date: 2026-02-03
"""

import asyncio
import time
from dataclasses import dataclass, field
from enum import Enum
from typing import Callable, Optional, Any, Dict
import logging
from functools import wraps

logger = logging.getLogger(__name__)


class CircuitState(Enum):
    """Circuit breaker states"""
    CLOSED = "closed"      # Normal operation, requests pass through
    OPEN = "open"          # Circuit is open, requests fail fast
    HALF_OPEN = "half_open"  # Testing if service has recovered


@dataclass
class CircuitBreakerConfig:
    """Configuration for circuit breaker behavior"""
    failure_threshold: int = 5  # Number of failures before opening
    success_threshold: int = 2  # Successful calls needed to close from half-open
    timeout: float = 30.0  # Seconds to wait before attempting recovery
    half_open_max_calls: int = 3  # Max concurrent calls in half-open state
    expected_exception: type = Exception  # Exception type to track
    fallback_function: Optional[Callable] = None  # Fallback when circuit is open


@dataclass
class CircuitBreakerMetrics:
    """Metrics tracked by circuit breaker"""
    total_requests: int = 0
    successful_requests: int = 0
    failed_requests: int = 0
    rejected_requests: int = 0  # Rejected due to open circuit
    state_transitions: Dict[str, int] = field(default_factory=lambda: {
        "closed_to_open": 0,
        "open_to_half_open": 0,
        "half_open_to_closed": 0,
        "half_open_to_open": 0
    })
    last_failure_time: Optional[float] = None
    last_success_time: Optional[float] = None
    current_state: CircuitState = CircuitState.CLOSED


class CircuitBreakerError(Exception):
    """Raised when circuit breaker rejects a request"""
    pass


class CircuitBreakerOpenError(CircuitBreakerError):
    """Raised when circuit is open and request is rejected"""
    def __init__(self, service_name: str, retry_after: float):
        self.service_name = service_name
        self.retry_after = retry_after
        super().__init__(
            f"Circuit breaker for '{service_name}' is OPEN. "
            f"Retry after {retry_after:.1f} seconds."
        )


class CircuitBreaker:
    """
    Circuit Breaker implementation with three states: CLOSED, OPEN, HALF_OPEN

    Features:
    - Automatic failure detection and recovery
    - Configurable thresholds and timeouts
    - Fallback function support
    - Comprehensive metrics
    - Thread-safe operation
    """

    def __init__(self, name: str, config: Optional[CircuitBreakerConfig] = None):
        self.name = name
        self.config = config or CircuitBreakerConfig()
        self.metrics = CircuitBreakerMetrics()
        self._state = CircuitState.CLOSED
        self._failure_count = 0
        self._success_count = 0
        self._last_failure_time: Optional[float] = None
        self._half_open_calls = 0
        self._lock = asyncio.Lock()

    @property
    def state(self) -> CircuitState:
        """Get current circuit breaker state"""
        return self._state

    @property
    def is_closed(self) -> bool:
        """Check if circuit is closed (normal operation)"""
        return self._state == CircuitState.CLOSED

    @property
    def is_open(self) -> bool:
        """Check if circuit is open (failing fast)"""
        return self._state == CircuitState.OPEN

    @property
    def is_half_open(self) -> bool:
        """Check if circuit is half-open (testing recovery)"""
        return self._state == CircuitState.HALF_OPEN

    async def _transition_to(self, new_state: CircuitState):
        """Transition to a new state with logging and metrics"""
        old_state = self._state
        if old_state != new_state:
            self._state = new_state
            self.metrics.current_state = new_state

            # Track transition
            transition_key = f"{old_state.value}_to_{new_state.value}"
            if transition_key in self.metrics.state_transitions:
                self.metrics.state_transitions[transition_key] += 1

            logger.info(
                f"Circuit breaker '{self.name}': {old_state.value.upper()} -> {new_state.value.upper()}"
            )

            # Reset counters on state transitions
            if new_state == CircuitState.CLOSED:
                self._failure_count = 0
                self._success_count = 0
                self._half_open_calls = 0
            elif new_state == CircuitState.HALF_OPEN:
                self._half_open_calls = 0
                self._success_count = 0

    async def _on_success(self):
        """Handle successful request"""
        async with self._lock:
            self.metrics.total_requests += 1
            self.metrics.successful_requests += 1
            self.metrics.last_success_time = time.time()

            if self._state == CircuitState.HALF_OPEN:
                self._success_count += 1
                logger.debug(
                    f"Circuit breaker '{self.name}': Success in HALF_OPEN "
                    f"({self._success_count}/{self.config.success_threshold})"
                )

                if self._success_count >= self.config.success_threshold:
                    await self._transition_to(CircuitState.CLOSED)
                    logger.info(
                        f"Circuit breaker '{self.name}': Service recovered, "
                        f"circuit CLOSED"
                    )

            elif self._state == CircuitState.CLOSED:
                # Reset failure count on success
                self._failure_count = 0

    async def _on_failure(self, exception: Exception):
        """Handle failed request"""
        async with self._lock:
            self.metrics.total_requests += 1
            self.metrics.failed_requests += 1
            self.metrics.last_failure_time = time.time()
            self._last_failure_time = time.time()

            if self._state == CircuitState.HALF_OPEN:
                # Immediately open on failure in half-open
                logger.warning(
                    f"Circuit breaker '{self.name}': Failure in HALF_OPEN state, "
                    f"reopening circuit"
                )
                await self._transition_to(CircuitState.OPEN)

            elif self._state == CircuitState.CLOSED:
                self._failure_count += 1
                logger.debug(
                    f"Circuit breaker '{self.name}': Failure "
                    f"({self._failure_count}/{self.config.failure_threshold})"
                )

                if self._failure_count >= self.config.failure_threshold:
                    await self._transition_to(CircuitState.OPEN)
                    logger.error(
                        f"Circuit breaker '{self.name}': Failure threshold reached, "
                        f"opening circuit for {self.config.timeout}s"
                    )

    async def _check_and_transition_from_open(self):
        """Check if circuit should transition from OPEN to HALF_OPEN"""
        if self._state != CircuitState.OPEN:
            return

        if self._last_failure_time is None:
            return

        time_since_failure = time.time() - self._last_failure_time
        if time_since_failure >= self.config.timeout:
            async with self._lock:
                # Double-check after acquiring lock
                if self._state == CircuitState.OPEN:
                    await self._transition_to(CircuitState.HALF_OPEN)
                    logger.info(
                        f"Circuit breaker '{self.name}': Timeout expired, "
                        f"trying HALF_OPEN"
                    )

    async def call(self, func: Callable, *args, **kwargs) -> Any:
        """
        Execute a function through the circuit breaker

        Args:
            func: Function to execute (can be async or sync)
            *args, **kwargs: Arguments to pass to the function

        Returns:
            Result of the function call

        Raises:
            CircuitBreakerOpenError: If circuit is open
            Original exception: If function fails
        """
        # Check if we should transition from OPEN to HALF_OPEN
        await self._check_and_transition_from_open()

        # Reject if circuit is OPEN
        if self._state == CircuitState.OPEN:
            self.metrics.rejected_requests += 1

            # Try fallback if configured
            if self.config.fallback_function:
                logger.info(f"Circuit breaker '{self.name}': Using fallback function")
                if asyncio.iscoroutinefunction(self.config.fallback_function):
                    return await self.config.fallback_function(*args, **kwargs)
                else:
                    return self.config.fallback_function(*args, **kwargs)

            # Calculate retry time
            retry_after = 0.0
            if self._last_failure_time:
                retry_after = max(
                    0,
                    self.config.timeout - (time.time() - self._last_failure_time)
                )

            raise CircuitBreakerOpenError(self.name, retry_after)

        # Limit concurrent calls in HALF_OPEN state
        if self._state == CircuitState.HALF_OPEN:
            async with self._lock:
                if self._half_open_calls >= self.config.half_open_max_calls:
                    self.metrics.rejected_requests += 1
                    logger.debug(
                        f"Circuit breaker '{self.name}': HALF_OPEN concurrent "
                        f"call limit reached"
                    )
                    raise CircuitBreakerOpenError(self.name, 0)
                self._half_open_calls += 1

        # Execute the function
        try:
            if asyncio.iscoroutinefunction(func):
                result = await func(*args, **kwargs)
            else:
                result = func(*args, **kwargs)

            await self._on_success()
            return result

        except self.config.expected_exception as e:
            await self._on_failure(e)
            raise

        except Exception as e:
            # Unexpected exception - don't count towards circuit breaker
            logger.warning(
                f"Circuit breaker '{self.name}': Unexpected exception type "
                f"{type(e).__name__}, not counting towards failure threshold"
            )
            raise

        finally:
            if self._state == CircuitState.HALF_OPEN:
                async with self._lock:
                    self._half_open_calls -= 1

    def get_metrics(self) -> Dict[str, Any]:
        """Get current metrics as dictionary"""
        return {
            "name": self.name,
            "state": self._state.value,
            "total_requests": self.metrics.total_requests,
            "successful_requests": self.metrics.successful_requests,
            "failed_requests": self.metrics.failed_requests,
            "rejected_requests": self.metrics.rejected_requests,
            "failure_rate": (
                self.metrics.failed_requests / self.metrics.total_requests
                if self.metrics.total_requests > 0 else 0
            ),
            "state_transitions": self.metrics.state_transitions,
            "last_failure_time": self.metrics.last_failure_time,
            "last_success_time": self.metrics.last_success_time,
        }

    def reset(self):
        """Reset circuit breaker to initial state"""
        self._state = CircuitState.CLOSED
        self._failure_count = 0
        self._success_count = 0
        self._last_failure_time = None
        self._half_open_calls = 0
        self.metrics = CircuitBreakerMetrics()
        logger.info(f"Circuit breaker '{self.name}': Reset to CLOSED state")


def circuit_breaker(
    name: str,
    failure_threshold: int = 5,
    success_threshold: int = 2,
    timeout: float = 30.0,
    expected_exception: type = Exception,
    fallback_function: Optional[Callable] = None
):
    """
    Decorator for applying circuit breaker pattern to a function

    Usage:
        @circuit_breaker("external_api", failure_threshold=3, timeout=60)
        async def call_external_api():
            # ... your code ...
    """
    config = CircuitBreakerConfig(
        failure_threshold=failure_threshold,
        success_threshold=success_threshold,
        timeout=timeout,
        expected_exception=expected_exception,
        fallback_function=fallback_function
    )
    breaker = CircuitBreaker(name, config)

    def decorator(func):
        @wraps(func)
        async def async_wrapper(*args, **kwargs):
            return await breaker.call(func, *args, **kwargs)

        @wraps(func)
        def sync_wrapper(*args, **kwargs):
            # For sync functions, we need to run in event loop
            loop = asyncio.get_event_loop()
            return loop.run_until_complete(breaker.call(func, *args, **kwargs))

        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        else:
            return sync_wrapper

    return decorator


# Global circuit breaker registry
_circuit_breakers: Dict[str, CircuitBreaker] = {}


def get_circuit_breaker(name: str) -> Optional[CircuitBreaker]:
    """Get a circuit breaker by name from the global registry"""
    return _circuit_breakers.get(name)


def register_circuit_breaker(breaker: CircuitBreaker):
    """Register a circuit breaker in the global registry"""
    _circuit_breakers[breaker.name] = breaker
    logger.info(f"Registered circuit breaker: {breaker.name}")


def get_all_metrics() -> Dict[str, Dict[str, Any]]:
    """Get metrics for all registered circuit breakers"""
    return {
        name: breaker.get_metrics()
        for name, breaker in _circuit_breakers.items()
    }
