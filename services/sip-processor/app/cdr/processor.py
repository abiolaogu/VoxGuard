"""CDR processing and logging."""
import logging
from datetime import datetime
from typing import Optional

import redis.asyncio as redis
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

from .models import CDRRecord, CallState
from .metrics import CDRMetricsCalculator
from ..signaling.models import SIPHeaderInfo

logger = logging.getLogger(__name__)


class CDRProcessor:
    """Process call events and maintain CDR records.
    
    Handles the full lifecycle of a call from INVITE to BYE,
    updating Redis counters in real-time and logging to PostgreSQL.
    """
    
    def __init__(
        self, 
        redis_client: redis.Redis,
        postgres_session: Optional[AsyncSession] = None,
        window_seconds: int = 300
    ):
        """Initialize the CDR processor.
        
        Args:
            redis_client: Async Redis client for real-time counters
            postgres_session: Async PostgreSQL session for persistent logging
            window_seconds: Metrics window in seconds
        """
        self.redis = redis_client
        self.postgres = postgres_session
        self.metrics = CDRMetricsCalculator(redis_client, window_seconds)
        
        # In-memory cache for active calls
        self._active_calls: dict[str, CDRRecord] = {}
    
    async def process_invite(self, header_info: SIPHeaderInfo) -> CDRRecord:
        """Process a SIP INVITE (call attempt).
        
        Args:
            header_info: Parsed SIP header information
            
        Returns:
            Created CDR record
        """
        cdr = CDRRecord(
            call_id=header_info.call_id,
            a_number=header_info.a_number,
            b_number=header_info.b_number,
            start_time=datetime.utcnow(),
            state=CallState.ATTEMPTING,
            cli=header_info.cli,
            p_asserted_identity=header_info.p_asserted_identity,
            has_cli_mismatch=header_info.has_cli_mismatch,
            via_headers=header_info.via
        )
        
        # Store in active calls
        self._active_calls[cdr.call_id] = cdr
        
        # Update Redis counters
        await self.metrics.record_attempt(cdr.b_number, cdr.a_number)
        
        logger.info(
            f"Call attempt: {cdr.a_number} -> {cdr.b_number} "
            f"(CLI mismatch: {cdr.has_cli_mismatch})"
        )
        
        return cdr
    
    async def process_answer(self, call_id: str) -> Optional[CDRRecord]:
        """Process a call answer event (200 OK).
        
        Args:
            call_id: SIP Call-ID
            
        Returns:
            Updated CDR record or None if not found
        """
        cdr = self._active_calls.get(call_id)
        if not cdr:
            logger.warning(f"Answer for unknown call: {call_id}")
            return None
        
        cdr.state = CallState.ANSWERED
        cdr.answer_time = datetime.utcnow()
        
        # Update Redis counters
        await self.metrics.record_answer(cdr.b_number)
        
        logger.info(f"Call answered: {cdr.call_id}")
        
        return cdr
    
    async def process_bye(self, call_id: str) -> Optional[CDRRecord]:
        """Process a call termination (BYE).
        
        Args:
            call_id: SIP Call-ID
            
        Returns:
            Completed CDR record or None if not found
        """
        cdr = self._active_calls.pop(call_id, None)
        if not cdr:
            logger.warning(f"BYE for unknown call: {call_id}")
            return None
        
        cdr.state = CallState.COMPLETED
        cdr.end_time = datetime.utcnow()
        
        # Record duration if call was answered
        if cdr.is_answered:
            await self.metrics.record_duration(cdr.b_number, cdr.duration_seconds)
        
        # Log to PostgreSQL
        if self.postgres:
            await self._log_cdr_to_postgres(cdr)
        
        logger.info(
            f"Call completed: {cdr.call_id} "
            f"(duration: {cdr.duration_seconds:.1f}s)"
        )
        
        return cdr
    
    async def process_failure(
        self, 
        call_id: str, 
        state: CallState = CallState.FAILED
    ) -> Optional[CDRRecord]:
        """Process a call failure (4xx, 5xx, 6xx responses).
        
        Args:
            call_id: SIP Call-ID
            state: Failure state (FAILED, BUSY, NO_ANSWER, etc.)
            
        Returns:
            Failed CDR record or None if not found
        """
        cdr = self._active_calls.pop(call_id, None)
        if not cdr:
            return None
        
        cdr.state = state
        cdr.end_time = datetime.utcnow()
        
        # Log to PostgreSQL
        if self.postgres:
            await self._log_cdr_to_postgres(cdr)
        
        logger.info(f"Call failed: {cdr.call_id} ({state.value})")
        
        return cdr
    
    async def get_active_call(self, call_id: str) -> Optional[CDRRecord]:
        """Get an active call by ID.
        
        Args:
            call_id: SIP Call-ID
            
        Returns:
            CDR record or None
        """
        return self._active_calls.get(call_id)
    
    @property
    def active_call_count(self) -> int:
        """Get the number of active calls."""
        return len(self._active_calls)
    
    async def _log_cdr_to_postgres(self, cdr: CDRRecord) -> None:
        """Log a completed CDR to PostgreSQL.
        
        Args:
            cdr: Completed CDR record
        """
        try:
            query = text("""
                INSERT INTO cdr_logs (
                    call_id, a_number, b_number, 
                    start_time, answer_time, end_time,
                    duration_seconds, state, 
                    cli, p_asserted_identity, has_cli_mismatch,
                    source_ip
                ) VALUES (
                    :call_id, :a_number, :b_number,
                    :start_time, :answer_time, :end_time,
                    :duration_seconds, :state,
                    :cli, :p_asserted_identity, :has_cli_mismatch,
                    :source_ip
                )
            """)
            
            await self.postgres.execute(query, {
                "call_id": cdr.call_id,
                "a_number": cdr.a_number,
                "b_number": cdr.b_number,
                "start_time": cdr.start_time,
                "answer_time": cdr.answer_time,
                "end_time": cdr.end_time,
                "duration_seconds": cdr.duration_seconds,
                "state": cdr.state.value,
                "cli": cdr.cli,
                "p_asserted_identity": cdr.p_asserted_identity,
                "has_cli_mismatch": cdr.has_cli_mismatch,
                "source_ip": cdr.source_ip
            })
            
        except Exception as e:
            logger.error(f"Failed to log CDR to PostgreSQL: {e}")
