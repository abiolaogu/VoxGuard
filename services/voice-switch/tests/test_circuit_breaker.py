"""
Unit tests for Circuit Breaker implementation

Author: Claude (VoxGuard Autonomous Factory)
Date: 2026-02-03
"""

import pytest
import asyncio
import time
from unittest.mock import AsyncMock, Mock

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from circuit_breaker import (
    CircuitBreaker,
    CircuitBreakerConfig,
    CircuitState,
    CircuitBreakerOpenError,
    circuit_breaker as cb_decorator
)


class TestCircuitBreaker:
    """Test cases for CircuitBreaker class"""

    @pytest.fixture
    def config(self):
        """Default circuit breaker configuration for testing"""
        return CircuitBreakerConfig(
            failure_threshold=3,
            success_threshold=2,
            timeout=1.0,  # Short timeout for tests
            half_open_max_calls=2,
            expected_exception=ValueError
        )

    @pytest.fixture
    def breaker(self, config):
        """Circuit breaker instance for testing"""
        return CircuitBreaker("test_service", config)

    @pytest.mark.asyncio
    async def test_initial_state_is_closed(self, breaker):
        """Circuit breaker should start in CLOSED state"""
        assert breaker.state == CircuitState.CLOSED
        assert breaker.is_closed
        assert not breaker.is_open
        assert not breaker.is_half_open

    @pytest.mark.asyncio
    async def test_successful_call(self, breaker):
        """Successful calls should pass through"""
        async def successful_func():
            return "success"

        result = await breaker.call(successful_func)
        assert result == "success"
        assert breaker.metrics.successful_requests == 1
        assert breaker.metrics.failed_requests == 0

    @pytest.mark.asyncio
    async def test_failed_call_increments_counter(self, breaker):
        """Failed calls should increment failure counter"""
        async def failing_func():
            raise ValueError("Test error")

        with pytest.raises(ValueError):
            await breaker.call(failing_func)

        assert breaker.metrics.failed_requests == 1
        assert breaker.state == CircuitState.CLOSED  # Still closed after 1 failure

    @pytest.mark.asyncio
    async def test_circuit_opens_after_threshold(self, breaker):
        """Circuit should open after reaching failure threshold"""
        async def failing_func():
            raise ValueError("Test error")

        # Trigger failures up to threshold (3)
        for i in range(3):
            with pytest.raises(ValueError):
                await breaker.call(failing_func)

        # Circuit should now be OPEN
        assert breaker.state == CircuitState.OPEN
        assert breaker.is_open
        assert breaker.metrics.failed_requests == 3

    @pytest.mark.asyncio
    async def test_open_circuit_rejects_calls(self, breaker):
        """Open circuit should reject calls with CircuitBreakerOpenError"""
        async def failing_func():
            raise ValueError("Test error")

        # Open the circuit
        for i in range(3):
            with pytest.raises(ValueError):
                await breaker.call(failing_func)

        # Now try a call - should be rejected
        async def any_func():
            return "should not execute"

        with pytest.raises(CircuitBreakerOpenError) as exc_info:
            await breaker.call(any_func)

        assert "test_service" in str(exc_info.value)
        assert breaker.metrics.rejected_requests == 1

    @pytest.mark.asyncio
    async def test_circuit_transitions_to_half_open(self, breaker):
        """Circuit should transition to HALF_OPEN after timeout"""
        async def failing_func():
            raise ValueError("Test error")

        # Open the circuit
        for i in range(3):
            with pytest.raises(ValueError):
                await breaker.call(failing_func)

        assert breaker.state == CircuitState.OPEN

        # Wait for timeout
        await asyncio.sleep(1.1)  # Config timeout is 1.0s

        # Next call should transition to HALF_OPEN
        async def test_func():
            return "testing"

        result = await breaker.call(test_func)
        assert result == "testing"
        assert breaker.state == CircuitState.HALF_OPEN

    @pytest.mark.asyncio
    async def test_half_open_closes_after_successes(self, breaker):
        """HALF_OPEN circuit should close after success threshold"""
        async def failing_func():
            raise ValueError("Test error")

        async def successful_func():
            return "success"

        # Open the circuit
        for i in range(3):
            with pytest.raises(ValueError):
                await breaker.call(failing_func)

        # Wait and transition to HALF_OPEN
        await asyncio.sleep(1.1)
        await breaker.call(successful_func)  # First success in HALF_OPEN

        assert breaker.state == CircuitState.HALF_OPEN

        # Second success should close circuit
        await breaker.call(successful_func)
        assert breaker.state == CircuitState.CLOSED

    @pytest.mark.asyncio
    async def test_half_open_reopens_on_failure(self, breaker):
        """HALF_OPEN circuit should reopen immediately on failure"""
        async def failing_func():
            raise ValueError("Test error")

        async def successful_func():
            return "success"

        # Open the circuit
        for i in range(3):
            with pytest.raises(ValueError):
                await breaker.call(failing_func)

        # Wait and transition to HALF_OPEN
        await asyncio.sleep(1.1)
        await breaker.call(successful_func)  # Transition to HALF_OPEN

        assert breaker.state == CircuitState.HALF_OPEN

        # Failure in HALF_OPEN should immediately reopen
        with pytest.raises(ValueError):
            await breaker.call(failing_func)

        assert breaker.state == CircuitState.OPEN

    @pytest.mark.asyncio
    async def test_half_open_limits_concurrent_calls(self, breaker):
        """HALF_OPEN should limit concurrent calls to configured max"""
        # Create a long-running function
        async def slow_func():
            await asyncio.sleep(0.5)
            return "slow"

        async def failing_func():
            raise ValueError("Test error")

        # Open the circuit
        for i in range(3):
            with pytest.raises(ValueError):
                await breaker.call(failing_func)

        # Wait and transition to HALF_OPEN
        await asyncio.sleep(1.1)

        # Start multiple concurrent calls
        tasks = [breaker.call(slow_func) for _ in range(5)]

        # Some should be rejected due to concurrent limit (2 in config)
        results = await asyncio.gather(*tasks, return_exceptions=True)

        rejected_count = sum(
            1 for r in results if isinstance(r, CircuitBreakerOpenError)
        )
        success_count = sum(1 for r in results if r == "slow")

        assert rejected_count >= 3  # At least 3 should be rejected
        assert success_count <= 2  # Max 2 should succeed

    @pytest.mark.asyncio
    async def test_fallback_function(self):
        """Circuit breaker should use fallback when open"""
        async def fallback_func():
            return "fallback_result"

        config = CircuitBreakerConfig(
            failure_threshold=2,
            timeout=1.0,
            expected_exception=ValueError,
            fallback_function=fallback_func
        )
        breaker = CircuitBreaker("test_fallback", config)

        async def failing_func():
            raise ValueError("Test error")

        # Open the circuit
        for i in range(2):
            with pytest.raises(ValueError):
                await breaker.call(failing_func)

        # Now calls should use fallback
        result = await breaker.call(failing_func)
        assert result == "fallback_result"

    @pytest.mark.asyncio
    async def test_metrics_tracking(self, breaker):
        """Circuit breaker should accurately track metrics"""
        async def sometimes_failing(should_fail):
            if should_fail:
                raise ValueError("Fail")
            return "success"

        # Execute mixed successes and failures
        await breaker.call(sometimes_failing, False)  # Success
        await breaker.call(sometimes_failing, False)  # Success

        with pytest.raises(ValueError):
            await breaker.call(sometimes_failing, True)  # Failure

        metrics = breaker.get_metrics()

        assert metrics["total_requests"] == 3
        assert metrics["successful_requests"] == 2
        assert metrics["failed_requests"] == 1
        assert metrics["state"] == "closed"
        assert 0 <= metrics["failure_rate"] <= 1

    @pytest.mark.asyncio
    async def test_reset(self, breaker):
        """Reset should return circuit to initial state"""
        async def failing_func():
            raise ValueError("Test error")

        # Open the circuit
        for i in range(3):
            with pytest.raises(ValueError):
                await breaker.call(failing_func)

        assert breaker.state == CircuitState.OPEN

        # Reset
        breaker.reset()

        assert breaker.state == CircuitState.CLOSED
        assert breaker.metrics.total_requests == 0
        assert breaker.metrics.failed_requests == 0

    @pytest.mark.asyncio
    async def test_sync_function_support(self, breaker):
        """Circuit breaker should support synchronous functions"""
        def sync_func():
            return "sync_result"

        result = await breaker.call(sync_func)
        assert result == "sync_result"

    @pytest.mark.asyncio
    async def test_unexpected_exception_not_counted(self, breaker):
        """Unexpected exceptions should not count towards failure threshold"""
        async def unexpected_error_func():
            raise RuntimeError("Unexpected")  # Not ValueError

        # Should raise but not count towards threshold
        with pytest.raises(RuntimeError):
            await breaker.call(unexpected_error_func)

        # Circuit should still be closed
        assert breaker.state == CircuitState.CLOSED
        # Failure should not be counted
        assert breaker.metrics.failed_requests == 0

    @pytest.mark.asyncio
    async def test_state_transitions_tracked(self, breaker):
        """State transitions should be tracked in metrics"""
        async def failing_func():
            raise ValueError("Test error")

        async def successful_func():
            return "success"

        # Closed -> Open
        for i in range(3):
            with pytest.raises(ValueError):
                await breaker.call(failing_func)

        metrics = breaker.get_metrics()
        assert metrics["state_transitions"]["closed_to_open"] == 1

        # Open -> Half-Open
        await asyncio.sleep(1.1)
        await breaker.call(successful_func)

        metrics = breaker.get_metrics()
        assert metrics["state_transitions"]["open_to_half_open"] == 1

        # Half-Open -> Closed
        await breaker.call(successful_func)

        metrics = breaker.get_metrics()
        assert metrics["state_transitions"]["half_open_to_closed"] == 1


class TestCircuitBreakerDecorator:
    """Test cases for @circuit_breaker decorator"""

    @pytest.mark.asyncio
    async def test_decorator_basic_usage(self):
        """Decorator should work with async functions"""
        call_count = 0

        @cb_decorator(
            "decorated_service",
            failure_threshold=2,
            timeout=1.0,
            expected_exception=ValueError
        )
        async def decorated_func(should_fail=False):
            nonlocal call_count
            call_count += 1
            if should_fail:
                raise ValueError("Decorated failure")
            return "decorated_success"

        # Successful call
        result = await decorated_func(False)
        assert result == "decorated_success"
        assert call_count == 1

        # Failing calls to open circuit
        for i in range(2):
            with pytest.raises(ValueError):
                await decorated_func(True)

        # Next call should be rejected (circuit open)
        with pytest.raises(CircuitBreakerOpenError):
            await decorated_func(False)

        # Call count should still be 3 (not 4)
        assert call_count == 3


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
