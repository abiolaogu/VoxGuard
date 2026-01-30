"""
Anti-Call Masking Detection System - LumaDB Edition
Database models and schema initialization
"""

from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
from enum import Enum
import uuid


class CallStatus(str, Enum):
    """Call status enumeration"""
    ACTIVE = "active"
    RINGING = "ringing"
    ANSWERED = "answered"
    ENDED = "ended"
    DISCONNECTED = "disconnected"


class AlertSeverity(str, Enum):
    """Alert severity levels"""
    CRITICAL = "CRITICAL"
    HIGH = "HIGH"
    MEDIUM = "MEDIUM"
    LOW = "LOW"


class AlertStatus(str, Enum):
    """Alert status"""
    NEW = "NEW"
    INVESTIGATING = "INVESTIGATING"
    RESOLVED = "RESOLVED"
    FALSE_POSITIVE = "FALSE_POSITIVE"


class CallEvent(BaseModel):
    """Incoming call event model"""
    call_id: Optional[str] = Field(default_factory=lambda: str(uuid.uuid4()))
    a_number: str = Field(..., description="Calling party number (A-number)")
    b_number: str = Field(..., description="Called party number (B-number)")
    source_ip: Optional[str] = Field(default=None, description="Source IP address")
    switch_id: Optional[str] = Field(default="default", description="Voice switch identifier")
    timestamp: Optional[datetime] = Field(default_factory=datetime.utcnow)
    raw_call_id: Optional[str] = Field(default=None, description="Raw call ID from switch")
    metadata: Optional[Dict[str, Any]] = Field(default_factory=dict)


class CallRecord(BaseModel):
    """Call record stored in LumaDB"""
    call_id: str
    a_number: str
    b_number: str
    timestamp: datetime
    status: CallStatus = CallStatus.ACTIVE
    flagged: bool = False
    alert_id: Optional[str] = None
    switch_id: str = "default"
    raw_call_id: Optional[str] = None
    source_ip: Optional[str] = None


class FraudAlert(BaseModel):
    """Fraud alert model"""
    alert_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    b_number: str
    a_numbers: List[str]
    call_ids: List[str]
    call_count: int
    window_start: datetime
    window_end: datetime
    severity: AlertSeverity
    status: AlertStatus = AlertStatus.NEW
    source_ips: List[str] = Field(default_factory=list)
    retry_count: int = 0
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    resolved_at: Optional[datetime] = None
    assigned_to: Optional[str] = None
    notes: Optional[str] = None


class ThreatLevel(BaseModel):
    """Threat level for a B-number"""
    b_number: str
    threat_level: str
    distinct_a_numbers: int
    distinct_ips: int
    call_count: int
    last_seen: datetime


class BlockedPattern(BaseModel):
    """Blocked number pattern"""
    pattern_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    b_number: str
    a_numbers: List[str]
    alert_id: str
    blocked_at: datetime = Field(default_factory=datetime.utcnow)
    expires_at: datetime
    active: bool = True
    reason: str = "Auto-blocked due to masking detection"


class DetectionResult(BaseModel):
    """Result of call processing"""
    detected: bool
    alert_id: Optional[str] = None
    latency_ms: float = 0.0
    message: str = ""


# SQL Schema for LumaDB (PostgreSQL-compatible)
LUMADB_SCHEMA = """
-- Calls table - time-series optimized
CREATE TABLE IF NOT EXISTS calls (
    call_id TEXT PRIMARY KEY,
    a_number TEXT NOT NULL,
    b_number TEXT NOT NULL,
    timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'active',
    flagged BOOLEAN NOT NULL DEFAULT FALSE,
    alert_id TEXT,
    switch_id TEXT DEFAULT 'default',
    raw_call_id TEXT,
    source_ip TEXT
);

-- Create index for sliding window queries (time-series optimized)
CREATE INDEX IF NOT EXISTS idx_calls_b_number_ts ON calls (b_number, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_calls_timestamp ON calls (timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_calls_alert ON calls (alert_id) WHERE alert_id IS NOT NULL;

-- Fraud alerts table
CREATE TABLE IF NOT EXISTS fraud_alerts (
    alert_id TEXT PRIMARY KEY,
    b_number TEXT NOT NULL,
    a_numbers TEXT[] NOT NULL,
    call_ids TEXT[] NOT NULL,
    source_ips TEXT[] DEFAULT '{}',
    call_count INTEGER NOT NULL,
    window_start TIMESTAMP NOT NULL,
    window_end TIMESTAMP NOT NULL,
    severity TEXT NOT NULL DEFAULT 'MEDIUM',
    status TEXT NOT NULL DEFAULT 'NEW',
    retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMP,
    assigned_to TEXT,
    notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_alerts_status ON fraud_alerts (status);
CREATE INDEX IF NOT EXISTS idx_alerts_severity ON fraud_alerts (severity);
CREATE INDEX IF NOT EXISTS idx_alerts_created ON fraud_alerts (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_b_number ON fraud_alerts (b_number);

-- Blocked patterns table
CREATE TABLE IF NOT EXISTS blocked_patterns (
    pattern_id TEXT PRIMARY KEY,
    b_number TEXT NOT NULL,
    a_numbers TEXT[] NOT NULL,
    alert_id TEXT NOT NULL,
    blocked_at TIMESTAMP NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    reason TEXT
);

CREATE INDEX IF NOT EXISTS idx_blocked_active ON blocked_patterns (active, expires_at);
CREATE INDEX IF NOT EXISTS idx_blocked_b_number ON blocked_patterns (b_number);

-- Cooldowns table (for alert rate limiting)
CREATE TABLE IF NOT EXISTS cooldowns (
    b_number TEXT PRIMARY KEY,
    last_alert_at TIMESTAMP NOT NULL,
    alert_count INTEGER DEFAULT 1
);

-- Whitelist table
CREATE TABLE IF NOT EXISTS whitelist (
    id TEXT PRIMARY KEY,
    pattern_type TEXT NOT NULL,  -- 'b_number', 'a_number_prefix', 'ip_range'
    pattern TEXT NOT NULL,
    reason TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    created_by TEXT
);

CREATE INDEX IF NOT EXISTS idx_whitelist_type ON whitelist (pattern_type);

-- Statistics table (time-series)
CREATE TABLE IF NOT EXISTS detection_stats (
    timestamp TIMESTAMP PRIMARY KEY,
    processed_count BIGINT NOT NULL DEFAULT 0,
    alert_count INTEGER NOT NULL DEFAULT 0,
    disconnected_count INTEGER NOT NULL DEFAULT 0,
    avg_latency_ms FLOAT DEFAULT 0,
    max_latency_ms FLOAT DEFAULT 0,
    active_calls INTEGER DEFAULT 0,
    memory_mb FLOAT DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_stats_ts ON detection_stats (timestamp DESC);
"""

# Kafka Topics Configuration (LumaDB is Kafka-compatible)
KAFKA_TOPICS = {
    "calls": {
        "name": "acm.calls",
        "partitions": 3,
        "replication_factor": 1,
        "retention_ms": 86400000,  # 24 hours
    },
    "alerts": {
        "name": "acm.alerts",
        "partitions": 1,
        "replication_factor": 1,
        "retention_ms": 604800000,  # 7 days
    },
    "actions": {
        "name": "acm.actions",
        "partitions": 1,
        "replication_factor": 1,
        "retention_ms": 604800000,  # 7 days
    }
}
