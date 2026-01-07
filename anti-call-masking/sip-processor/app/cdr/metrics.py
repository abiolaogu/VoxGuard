"""Real-time CDR metrics calculation using Redis."""
import logging
from datetime import datetime
from typing import Optional

import redis.asyncio as redis

from .models import CDRMetrics

logger = logging.getLogger(__name__)


class CDRMetricsCalculator:
    """Calculate ASR, ALOC, and Overlap Ratio in real-time.
    
    Uses Redis for sub-millisecond counter operations to enable
    real-time metric calculation for call masking detection.
    """
    
    # Redis key prefixes
    KEY_PREFIX = "cdr"
    WINDOW_PREFIX = "window"
    
    def __init__(self, redis_client: redis.Redis, window_seconds: int = 300):
        """Initialize the metrics calculator.
        
        Args:
            redis_client: Async Redis client
            window_seconds: Time window for metrics (default 5 minutes)
        """
        self.redis = redis_client
        self.window_seconds = window_seconds
    
    def _key(self, *parts: str) -> str:
        """Build a Redis key."""
        return ":".join([self.KEY_PREFIX] + list(parts))
    
    def _window_key(self, b_number: str) -> str:
        """Build a window key for concurrent caller tracking."""
        return f"{self.WINDOW_PREFIX}:{b_number}"
    
    async def record_attempt(self, b_number: str, a_number: str) -> None:
        """Record a call attempt.
        
        Args:
            b_number: Called party number
            a_number: Calling party number
        """
        pipe = self.redis.pipeline()
        
        # Increment total attempts
        attempts_key = self._key(b_number, "attempts")
        pipe.incr(attempts_key)
        pipe.expire(attempts_key, self.window_seconds)
        
        # Add to concurrent caller set (for overlap detection)
        window_key = self._window_key(b_number)
        pipe.sadd(window_key, a_number)
        pipe.expire(window_key, 5)  # 5-second window for concurrent callers
        
        # Track total calls in window
        total_key = self._key(b_number, "total_window")
        pipe.incr(total_key)
        pipe.expire(total_key, self.window_seconds)
        
        await pipe.execute()
    
    async def record_answer(self, b_number: str) -> None:
        """Record that a call was answered.
        
        Args:
            b_number: Called party number
        """
        answered_key = self._key(b_number, "answered")
        pipe = self.redis.pipeline()
        pipe.incr(answered_key)
        pipe.expire(answered_key, self.window_seconds)
        await pipe.execute()
    
    async def record_duration(self, b_number: str, duration_seconds: float) -> None:
        """Record call duration for ALOC calculation.
        
        Args:
            b_number: Called party number
            duration_seconds: Call duration in seconds
        """
        durations_key = self._key(b_number, "durations")
        pipe = self.redis.pipeline()
        pipe.rpush(durations_key, str(duration_seconds))
        pipe.expire(durations_key, self.window_seconds)
        # Keep list bounded
        pipe.ltrim(durations_key, -1000, -1)  # Keep last 1000 durations
        await pipe.execute()
    
    async def calculate_asr(self, b_number: str) -> float:
        """Calculate Answer Seizure Ratio.
        
        ASR = Answered Calls / Total Attempts * 100
        
        Args:
            b_number: Called party number
            
        Returns:
            ASR as a percentage (0-100)
        """
        attempts_key = self._key(b_number, "attempts")
        answered_key = self._key(b_number, "answered")
        
        attempts = await self.redis.get(attempts_key)
        answered = await self.redis.get(answered_key)
        
        attempts = int(attempts) if attempts else 0
        answered = int(answered) if answered else 0
        
        if attempts == 0:
            return 0.0
        
        return (answered / attempts) * 100.0
    
    async def calculate_aloc(self, b_number: str) -> float:
        """Calculate Average Length of Call.
        
        ALOC = Sum of Durations / Number of Answered Calls
        
        Args:
            b_number: Called party number
            
        Returns:
            ALOC in seconds
        """
        durations_key = self._key(b_number, "durations")
        durations = await self.redis.lrange(durations_key, 0, -1)
        
        if not durations:
            return 0.0
        
        total = sum(float(d) for d in durations)
        return total / len(durations)
    
    async def calculate_overlap_ratio(self, b_number: str) -> float:
        """Calculate Overlap Ratio (concurrent callers).
        
        Overlap Ratio = Distinct Concurrent Callers / Total Calls in Window
        
        High overlap ratio indicates potential masking attack
        (many different A-numbers calling the same B-number simultaneously).
        
        Args:
            b_number: Called party number
            
        Returns:
            Overlap ratio (0-1)
        """
        window_key = self._window_key(b_number)
        total_key = self._key(b_number, "total_window")
        
        concurrent_count = await self.redis.scard(window_key)
        total = await self.redis.get(total_key)
        total = int(total) if total else 1
        
        if total == 0:
            return 0.0
        
        return min(float(concurrent_count) / float(total), 1.0)
    
    async def get_concurrent_callers(self, b_number: str) -> int:
        """Get the number of concurrent callers to a B-number.
        
        Args:
            b_number: Called party number
            
        Returns:
            Number of distinct callers in the current window
        """
        window_key = self._window_key(b_number)
        return await self.redis.scard(window_key)
    
    async def get_all_metrics(self, b_number: str) -> CDRMetrics:
        """Get all CDR metrics for a B-number.
        
        Args:
            b_number: Called party number
            
        Returns:
            CDRMetrics with all calculated values
        """
        # Calculate all metrics in parallel
        asr = await self.calculate_asr(b_number)
        aloc = await self.calculate_aloc(b_number)
        overlap_ratio = await self.calculate_overlap_ratio(b_number)
        
        # Get supporting counts
        attempts_key = self._key(b_number, "attempts")
        answered_key = self._key(b_number, "answered")
        window_key = self._window_key(b_number)
        
        attempts = await self.redis.get(attempts_key)
        answered = await self.redis.get(answered_key)
        concurrent = await self.redis.scard(window_key)
        
        return CDRMetrics(
            b_number=b_number,
            asr=asr,
            aloc=aloc,
            overlap_ratio=overlap_ratio,
            total_attempts=int(attempts) if attempts else 0,
            answered_calls=int(answered) if answered else 0,
            concurrent_callers=concurrent,
            window_seconds=self.window_seconds,
            calculated_at=datetime.utcnow()
        )
    
    async def reset_metrics(self, b_number: str) -> None:
        """Reset all metrics for a B-number.
        
        Args:
            b_number: Called party number
        """
        keys = [
            self._key(b_number, "attempts"),
            self._key(b_number, "answered"),
            self._key(b_number, "durations"),
            self._key(b_number, "total_window"),
            self._window_key(b_number)
        ]
        await self.redis.delete(*keys)
