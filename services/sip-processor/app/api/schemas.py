"""API request/response schemas."""
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional


class CDRMetricsResponse(BaseModel):
    """CDR metrics response."""
    
    b_number: str
    asr: float = Field(description="Answer Seizure Ratio (0-100)")
    aloc: float = Field(description="Average Length of Call in seconds")
    overlap_ratio: float = Field(description="Concurrent caller ratio (0-1)")
    total_attempts: int = 0
    answered_calls: int = 0
    concurrent_callers: int = 0
    window_seconds: int = 300


class CallAnalysisRequest(BaseModel):
    """Request to analyze a call for masking."""
    
    call_id: str = Field(description="Unique call identifier")
    a_number: str = Field(description="Caller number (A-party)")
    b_number: str = Field(description="Called number (B-party)")
    cli: Optional[str] = Field(None, description="Calling Line Identity from From header")
    p_asserted_identity: Optional[str] = Field(None, description="P-Asserted-Identity header value")
    distinct_a_count: int = Field(0, description="Number of distinct callers in window")
    call_rate: float = Field(0.0, description="Calls per second to this B-number")
    short_call_ratio: float = Field(0.0, description="Ratio of calls under 10 seconds")


class CallAnalysisResponse(BaseModel):
    """Response from call analysis."""
    
    call_id: str
    is_masking: bool = Field(description="Whether call is flagged as masking attack")
    masking_probability: float = Field(description="Masking probability (0-1)")
    risk_level: str = Field(description="Risk level: MINIMAL, LOW, MEDIUM, HIGH, CRITICAL")
    confidence: str = Field(description="Confidence level: LOW, MEDIUM, HIGH")
    method: str = Field(description="Detection method: xgboost or rule_based")
    metrics: CDRMetricsResponse
    features_used: dict = Field(default_factory=dict)
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class SIPParseRequest(BaseModel):
    """Request to parse a raw SIP message."""
    
    raw_message: str = Field(description="Raw SIP message as string")
    source_ip: Optional[str] = Field("0.0.0.0", description="Source IP address")


class SIPParseResponse(BaseModel):
    """Response from SIP parsing."""
    
    success: bool
    call_id: Optional[str] = None
    method: Optional[str] = None
    cli: Optional[str] = None
    p_asserted_identity: Optional[str] = None
    from_uri: Optional[str] = None
    to_uri: Optional[str] = None
    has_cli_mismatch: bool = False
    error: Optional[str] = None


class AlertResponse(BaseModel):
    """Masking alert response."""
    
    alert_id: str
    call_id: str
    b_number: str
    distinct_caller_count: int
    masking_probability: float
    risk_level: str
    created_at: datetime
    description: str
    recommended_action: str = "BLOCK"


class HealthResponse(BaseModel):
    """Health check response."""
    
    status: str
    service: str
    version: str
    components: dict = Field(default_factory=dict)
