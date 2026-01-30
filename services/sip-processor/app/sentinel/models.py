"""
Sentinel database models and schemas
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, validator
import re


class CallRecord(BaseModel):
    """CDR call record model"""
    id: Optional[int] = None
    call_timestamp: datetime
    caller_number: str = Field(..., min_length=1, max_length=20)
    callee_number: str = Field(..., min_length=1, max_length=20)
    duration_seconds: int = Field(..., ge=0)
    call_direction: Optional[str] = Field(None, max_length=10)
    termination_cause: Optional[str] = Field(None, max_length=50)
    location_code: Optional[str] = Field(None, max_length=10)
    processed_at: Optional[datetime] = None

    @validator('caller_number', 'callee_number')
    def validate_e164_format(cls, v):
        """Validate E.164 phone number format"""
        if not re.match(r'^\+?[1-9]\d{1,14}$', v):
            raise ValueError(f'Invalid E.164 phone number format: {v}')
        return v

    @validator('call_direction')
    def validate_direction(cls, v):
        """Validate call direction"""
        if v is not None and v not in ['inbound', 'outbound']:
            raise ValueError('call_direction must be "inbound" or "outbound"')
        return v


class SuspiciousPattern(BaseModel):
    """Suspicious pattern detection model"""
    id: Optional[int] = None
    pattern_type: str = Field(..., max_length=50)
    suspect_number: str = Field(..., max_length=20)
    detection_timestamp: Optional[datetime] = None
    confidence_score: float = Field(..., ge=0.0, le=1.0)
    metadata: Optional[dict] = None


class SentinelFraudAlert(BaseModel):
    """Fraud alert model"""
    id: Optional[int] = None
    alert_type: str = Field(..., max_length=50)
    suspect_number: str = Field(..., max_length=20)
    alert_severity: str = Field(..., max_length=20)
    evidence_summary: str
    call_count: Optional[int] = None
    unique_destinations: Optional[int] = None
    avg_duration_seconds: Optional[float] = None
    detection_rule: Optional[str] = Field(None, max_length=100)
    created_at: Optional[datetime] = None
    reviewed: bool = False
    reviewer_notes: Optional[str] = None

    @validator('alert_severity')
    def validate_severity(cls, v):
        """Validate alert severity"""
        valid_severities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']
        if v not in valid_severities:
            raise ValueError(f'alert_severity must be one of: {valid_severities}')
        return v


class CDRIngestRequest(BaseModel):
    """Request model for CDR ingestion"""
    pass


class CDRIngestResponse(BaseModel):
    """Response model for CDR ingestion"""
    status: str
    records_processed: int
    records_inserted: int
    duplicates_skipped: int
    processing_time_seconds: float
    errors: Optional[list] = []
