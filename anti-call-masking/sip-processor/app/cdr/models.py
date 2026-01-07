"""CDR data models."""
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Optional


class CallState(str, Enum):
    """Call state enumeration."""
    ATTEMPTING = "attempting"
    RINGING = "ringing"
    ANSWERED = "answered"
    COMPLETED = "completed"
    FAILED = "failed"
    BUSY = "busy"
    NO_ANSWER = "no_answer"
    CANCELLED = "cancelled"


@dataclass
class CDRRecord:
    """Call Detail Record."""
    
    # Identifiers
    call_id: str
    
    # Parties
    a_number: str  # Caller
    b_number: str  # Called
    
    # Timing
    start_time: datetime
    answer_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    
    # State
    state: CallState = CallState.ATTEMPTING
    
    # SIP details
    cli: Optional[str] = None
    p_asserted_identity: Optional[str] = None
    has_cli_mismatch: bool = False
    
    # Network info
    source_ip: Optional[str] = None
    via_headers: list[str] = field(default_factory=list)
    
    @property
    def duration_seconds(self) -> float:
        """Calculate call duration in seconds."""
        if not self.answer_time or not self.end_time:
            return 0.0
        return (self.end_time - self.answer_time).total_seconds()
    
    @property
    def setup_time_seconds(self) -> float:
        """Calculate call setup time (ring time) in seconds."""
        if not self.answer_time:
            return 0.0
        return (self.answer_time - self.start_time).total_seconds()
    
    @property
    def is_answered(self) -> bool:
        """Check if call was answered."""
        return self.state in (CallState.ANSWERED, CallState.COMPLETED)
    
    @property
    def is_completed(self) -> bool:
        """Check if call is completed."""
        return self.state in (
            CallState.COMPLETED, 
            CallState.FAILED, 
            CallState.BUSY, 
            CallState.NO_ANSWER,
            CallState.CANCELLED
        )


@dataclass
class CDRMetrics:
    """CDR metrics for a destination (B-number)."""
    
    b_number: str
    
    # Answer Seizure Ratio (ASR)
    # = Answered calls / Total attempts
    asr: float = 0.0
    
    # Average Length of Call (ALOC) in seconds
    # = Sum of call durations / Number of answered calls
    aloc: float = 0.0
    
    # Overlap Ratio
    # = Concurrent calls / Total calls in window
    overlap_ratio: float = 0.0
    
    # Supporting data
    total_attempts: int = 0
    answered_calls: int = 0
    concurrent_callers: int = 0
    
    # Time window
    window_seconds: int = 300
    calculated_at: datetime = field(default_factory=datetime.utcnow)
    
    def to_dict(self) -> dict:
        """Convert to dictionary."""
        return {
            "b_number": self.b_number,
            "asr": self.asr,
            "aloc": self.aloc,
            "overlap_ratio": self.overlap_ratio,
            "total_attempts": self.total_attempts,
            "answered_calls": self.answered_calls,
            "concurrent_callers": self.concurrent_callers,
            "window_seconds": self.window_seconds,
            "calculated_at": self.calculated_at.isoformat()
        }
