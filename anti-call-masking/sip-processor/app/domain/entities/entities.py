"""
Domain Entities - Business objects with identity and lifecycle

Entities represent core business concepts with unique identities
that persist over time.
"""

from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional, List
from enum import Enum
import uuid

from app.domain.value_objects import MSISDN, IPAddress, FraudScore, Severity, FraudType, CallId


class CallStatus(Enum):
    """Call status in the system"""
    RINGING = "ringing"
    ACTIVE = "active"
    COMPLETED = "completed"
    FAILED = "failed"
    BLOCKED = "blocked"


class AlertStatus(Enum):
    """Alert workflow status"""
    PENDING = "pending"
    ACKNOWLEDGED = "acknowledged"
    INVESTIGATING = "investigating"
    RESOLVED = "resolved"
    REPORTED_NCC = "reported_ncc"


class ResolutionType(Enum):
    """How an alert was resolved"""
    CONFIRMED_FRAUD = "confirmed_fraud"
    FALSE_POSITIVE = "false_positive"
    ESCALATED = "escalated"
    WHITELISTED = "whitelisted"


@dataclass
class Call:
    """
    Call aggregate - represents a single call in the detection system
    
    The Call entity tracks all metadata needed for fraud detection,
    including source/destination numbers, gateway IP, and detection status.
    """
    id: CallId
    a_number: MSISDN  # Caller (A-number)
    b_number: MSISDN  # Called party (B-number)
    source_ip: IPAddress
    timestamp: datetime = field(default_factory=datetime.utcnow)
    status: CallStatus = CallStatus.RINGING
    switch_id: Optional[str] = None
    raw_call_id: Optional[str] = None
    is_flagged: bool = False
    alert_id: Optional[str] = None
    fraud_score: FraudScore = field(default_factory=lambda: FraudScore(0.0))
    created_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: datetime = field(default_factory=datetime.utcnow)
    
    def flag_as_fraud(self, alert_id: str, score: FraudScore) -> None:
        """Flags this call as part of a fraud alert"""
        if self.is_flagged:
            raise ValueError("Call is already flagged")
        self.is_flagged = True
        self.alert_id = alert_id
        self.fraud_score = score
        self.updated_at = datetime.utcnow()
    
    def update_status(self, new_status: CallStatus) -> None:
        """Updates call status with validation"""
        terminal_states = {CallStatus.COMPLETED, CallStatus.FAILED, CallStatus.BLOCKED}
        if self.status in terminal_states:
            raise ValueError(f"Cannot transition from {self.status} to {new_status}")
        self.status = new_status
        self.updated_at = datetime.utcnow()
    
    @property
    def is_potential_cli_masking(self) -> bool:
        """Checks if this call shows CLI masking indicators"""
        return self.a_number.is_nigerian and self.source_ip.is_likely_international
    
    @property
    def is_active(self) -> bool:
        """Returns True if call is ongoing"""
        return self.status in {CallStatus.RINGING, CallStatus.ACTIVE}
    
    @classmethod
    def create(cls, a_number: str, b_number: str, source_ip: str) -> 'Call':
        """Factory method to create a new Call"""
        return cls(
            id=CallId.generate(),
            a_number=MSISDN.from_string(a_number),
            b_number=MSISDN.from_string(b_number),
            source_ip=IPAddress(source_ip),
        )


@dataclass
class FraudAlert:
    """
    FraudAlert aggregate - represents a detected fraud event
    
    Tracks the complete lifecycle of a fraud alert from detection
    through resolution and NCC reporting.
    """
    id: str
    b_number: MSISDN
    fraud_type: FraudType
    score: FraudScore
    severity: Severity
    a_numbers: List[str] = field(default_factory=list)
    call_ids: List[str] = field(default_factory=list)
    source_ips: List[str] = field(default_factory=list)
    distinct_callers: int = 0
    
    # Workflow state
    status: AlertStatus = AlertStatus.PENDING
    acknowledged_by: Optional[str] = None
    acknowledged_at: Optional[datetime] = None
    resolved_by: Optional[str] = None
    resolved_at: Optional[datetime] = None
    resolution: Optional[ResolutionType] = None
    resolution_notes: Optional[str] = None
    
    # NCC reporting
    ncc_reported: bool = False
    ncc_report_id: Optional[str] = None
    
    # Timestamps
    detected_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: datetime = field(default_factory=datetime.utcnow)
    
    def acknowledge(self, user_id: str) -> None:
        """Marks alert as acknowledged by a user"""
        if self.status != AlertStatus.PENDING:
            raise ValueError("Only pending alerts can be acknowledged")
        self.status = AlertStatus.ACKNOWLEDGED
        self.acknowledged_by = user_id
        self.acknowledged_at = datetime.utcnow()
        self.updated_at = datetime.utcnow()
    
    def start_investigation(self) -> None:
        """Moves alert to investigation status"""
        if self.status != AlertStatus.ACKNOWLEDGED:
            raise ValueError("Alert must be acknowledged before investigation")
        self.status = AlertStatus.INVESTIGATING
        self.updated_at = datetime.utcnow()
    
    def resolve(self, user_id: str, resolution: ResolutionType, notes: Optional[str] = None) -> None:
        """Resolves the alert"""
        if self.status == AlertStatus.RESOLVED:
            raise ValueError("Alert is already resolved")
        self.status = AlertStatus.RESOLVED
        self.resolved_by = user_id
        self.resolved_at = datetime.utcnow()
        self.resolution = resolution
        self.resolution_notes = notes
        self.updated_at = datetime.utcnow()
    
    def report_to_ncc(self, report_id: str) -> None:
        """Marks alert as reported to NCC"""
        self.ncc_reported = True
        self.ncc_report_id = report_id
        self.status = AlertStatus.REPORTED_NCC
        self.updated_at = datetime.utcnow()
    
    @property
    def should_auto_escalate(self) -> bool:
        """Determines if alert should be auto-escalated to NCC"""
        return self.severity == Severity.CRITICAL and self.score.value >= 0.95
    
    @classmethod
    def create(
        cls,
        b_number: str,
        fraud_type: FraudType,
        score: float,
        a_numbers: List[str],
        call_ids: List[str],
        source_ips: List[str],
    ) -> 'FraudAlert':
        """Factory method to create a new FraudAlert"""
        fraud_score = FraudScore(score)
        return cls(
            id=str(uuid.uuid4()),
            b_number=MSISDN.from_string(b_number),
            fraud_type=fraud_type,
            score=fraud_score,
            severity=fraud_score.severity,
            a_numbers=a_numbers,
            call_ids=call_ids,
            source_ips=source_ips,
            distinct_callers=len(set(a_numbers)),
        )


@dataclass
class Blacklist:
    """Blacklist entry for numbers or IPs"""
    id: str
    entry_type: str  # "msisdn", "ip", "range"
    value: str
    reason: str
    source: str  # "manual", "auto", "ncc"
    added_by: str
    expires_at: Optional[datetime] = None
    created_at: datetime = field(default_factory=datetime.utcnow)
    
    @property
    def is_expired(self) -> bool:
        if self.expires_at is None:
            return False
        return datetime.utcnow() > self.expires_at
    
    @classmethod
    def create_msisdn_entry(cls, msisdn: str, reason: str, added_by: str) -> 'Blacklist':
        """Creates a new MSISDN blacklist entry"""
        return cls(
            id=str(uuid.uuid4()),
            entry_type="msisdn",
            value=MSISDN.from_string(msisdn).value,
            reason=reason,
            source="manual",
            added_by=added_by,
        )
    
    @classmethod
    def create_ip_entry(cls, ip: str, reason: str, added_by: str) -> 'Blacklist':
        """Creates a new IP blacklist entry"""
        return cls(
            id=str(uuid.uuid4()),
            entry_type="ip",
            value=IPAddress(ip).value,
            reason=reason,
            source="manual",
            added_by=added_by,
        )
