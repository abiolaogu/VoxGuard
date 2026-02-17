"""
Sentinel API routes

FastAPI endpoints for CDR ingestion and alert management.
"""
import time
from fastapi import APIRouter, UploadFile, File, HTTPException, Depends, Query, Body
from typing import Optional
from pydantic import BaseModel, Field
import asyncpg

from .parser import CDRParser
from .database import SentinelDatabase
from .models import CDRIngestResponse, CallRecord
from .detector import FraudDetectionEngine, SDHFDetector

router = APIRouter(prefix="/api/v1/sentinel", tags=["sentinel"])


# Dependency to get database pool (to be implemented in main.py)
async def get_db_pool():
    """Placeholder for database pool dependency"""
    # This will be properly injected from the main app
    raise HTTPException(status_code=500, detail="Database pool not configured")


@router.post("/ingest", response_model=CDRIngestResponse)
async def ingest_cdr(
    cdr_file: UploadFile = File(...),
    db_pool: asyncpg.Pool = Depends(get_db_pool)
):
    """
    Ingest CDR CSV file for batch processing

    Accepts a CSV file with call detail records, validates the format,
    and stores the records in the database for analysis.

    **Required CSV columns:**
    - call_date (YYYY-MM-DD)
    - call_time (HH:MM:SS)
    - caller_number (E.164 format)
    - callee_number (E.164 format)
    - duration_seconds (integer)

    **Optional CSV columns:**
    - call_direction (inbound/outbound)
    - termination_cause
    - location_code

    **Returns:**
    - status: success or error
    - records_processed: Total number of records in CSV
    - records_inserted: Number of records successfully inserted
    - duplicates_skipped: Number of duplicate records skipped
    - processing_time_seconds: Time taken to process the file
    - errors: List of validation/parsing errors (if any)
    """
    start_time = time.time()

    # Validate file type
    if not cdr_file.filename.endswith('.csv'):
        raise HTTPException(status_code=400, detail="Only CSV files are supported")

    try:
        # Read file content
        file_content = await cdr_file.read()

        # Parse CSV
        parser = CDRParser()
        records, parse_errors = parser.parse_csv(file_content)

        if parse_errors and not records:
            return CDRIngestResponse(
                status="error",
                records_processed=0,
                records_inserted=0,
                duplicates_skipped=0,
                processing_time_seconds=time.time() - start_time,
                errors=parse_errors
            )

        # Deduplicate records
        unique_records, csv_duplicates = parser.deduplicate(records)

        # Check database for existing records
        db = SentinelDatabase(db_pool)
        non_duplicate_records = await db.check_duplicates(unique_records)
        db_duplicates = len(unique_records) - len(non_duplicate_records)

        # Insert records
        inserted_count = await db.insert_call_records(non_duplicate_records)

        total_duplicates = csv_duplicates + db_duplicates
        processing_time = time.time() - start_time

        return CDRIngestResponse(
            status="success" if inserted_count > 0 else "partial",
            records_processed=len(records),
            records_inserted=inserted_count,
            duplicates_skipped=total_duplicates,
            processing_time_seconds=round(processing_time, 2),
            errors=parse_errors if parse_errors else None
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ingestion failed: {str(e)}")


@router.get("/alerts")
async def get_alerts(
    severity: Optional[str] = Query(None, pattern="^(LOW|MEDIUM|HIGH|CRITICAL)$"),
    reviewed: Optional[bool] = Query(None),
    limit: int = Query(50, ge=1, le=1000),
    db_pool: asyncpg.Pool = Depends(get_db_pool)
):
    """
    Retrieve fraud alerts with optional filtering

    **Query parameters:**
    - severity: Filter by alert severity (LOW, MEDIUM, HIGH, CRITICAL)
    - reviewed: Filter by reviewed status (true/false)
    - limit: Maximum number of alerts to return (1-1000, default: 50)

    **Returns:**
    List of fraud alert objects
    """
    try:
        db = SentinelDatabase(db_pool)
        alerts = await db.get_alerts(severity=severity, reviewed=reviewed, limit=limit)
        return {
            "status": "success",
            "count": len(alerts),
            "alerts": alerts
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve alerts: {str(e)}")


@router.get("/health")
async def health_check():
    """
    Health check endpoint for load balancers

    **Returns:**
    Simple status response
    """
    return {
        "status": "healthy",
        "service": "sentinel-anti-masking",
        "version": "1.0.0"
    }


class SDHFDetectionRequest(BaseModel):
    """Request model for SDHF detection"""
    time_window_hours: int = Field(24, ge=1, le=168, description="Time window in hours (1-168)")
    min_unique_destinations: int = Field(50, ge=1, description="Minimum unique destinations")
    max_avg_duration_seconds: float = Field(3.0, ge=0, description="Maximum average duration in seconds")


@router.post("/detect/sdhf")
async def detect_sdhf(
    request: SDHFDetectionRequest = Body(...),
    db_pool: asyncpg.Pool = Depends(get_db_pool)
):
    """
    Run SDHF (Short Duration High Frequency) detection

    Analyzes call records to detect potential SIM Box fraud patterns.
    Flags numbers making many calls to unique destinations with short average duration.

    **Request Body:**
    - time_window_hours: Time window to analyze (default: 24, max: 168)
    - min_unique_destinations: Minimum unique destinations to trigger (default: 50)
    - max_avg_duration_seconds: Maximum average duration for suspicious pattern (default: 3.0)

    **Returns:**
    - alerts_generated: Number of alerts created
    - alert_ids: List of created alert IDs
    - suspects: List of suspect phone numbers
    """
    try:
        detector = SDHFDetector(db_pool)
        alert_ids = await detector.generate_sdhf_alerts(
            time_window_hours=request.time_window_hours,
            min_unique_destinations=request.min_unique_destinations,
            max_avg_duration_seconds=request.max_avg_duration_seconds
        )

        # Get suspect numbers from alerts
        if alert_ids:
            async with db_pool.acquire() as conn:
                query = "SELECT suspect_number FROM sentinel_fraud_alerts WHERE id = ANY($1)"
                rows = await conn.fetch(query, alert_ids)
                suspects = [row['suspect_number'] for row in rows]
        else:
            suspects = []

        return {
            "status": "success",
            "alerts_generated": len(alert_ids),
            "alert_ids": alert_ids,
            "suspects": suspects
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"SDHF detection failed: {str(e)}")


@router.patch("/alerts/{alert_id}")
async def update_alert(
    alert_id: int,
    reviewed: bool = Body(...),
    reviewer_notes: Optional[str] = Body(None),
    db_pool: asyncpg.Pool = Depends(get_db_pool)
):
    """
    Update a fraud alert (mark as reviewed, add notes)

    **Path Parameters:**
    - alert_id: ID of the alert to update

    **Request Body:**
    - reviewed: Mark alert as reviewed (true/false)
    - reviewer_notes: Optional notes from reviewer

    **Returns:**
    Updated alert status
    """
    try:
        query = """
            UPDATE sentinel_fraud_alerts
            SET reviewed = $1, reviewer_notes = $2
            WHERE id = $3
            RETURNING id, reviewed, reviewer_notes
        """

        async with db_pool.acquire() as conn:
            row = await conn.fetchrow(query, reviewed, reviewer_notes, alert_id)

            if not row:
                raise HTTPException(status_code=404, detail=f"Alert {alert_id} not found")

            return {
                "status": "success",
                "alert": dict(row)
            }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update alert: {str(e)}")


class RealTimeCallEvent(BaseModel):
    """Real-time call event model"""
    caller_number: str = Field(..., description="Caller phone number in E.164 format")
    callee_number: str = Field(..., description="Callee phone number in E.164 format")
    duration_seconds: int = Field(..., ge=0, description="Call duration in seconds")
    call_direction: Optional[str] = Field(None, pattern="^(inbound|outbound)$", description="Call direction")
    timestamp: str = Field(..., description="ISO 8601 timestamp (e.g., 2024-01-15T14:32:15Z)")


class RealTimeEventResponse(BaseModel):
    """Response model for real-time event"""
    status: str
    event_id: str
    risk_score: float = Field(..., ge=0.0, le=1.0, description="Risk score between 0.0 and 1.0")


@router.post("/events/call", response_model=RealTimeEventResponse)
async def receive_call_event(
    event: RealTimeCallEvent = Body(...),
    db_pool: asyncpg.Pool = Depends(get_db_pool)
):
    """
    Accept real-time call events from external systems for immediate analysis

    This endpoint receives individual call events in real-time and performs
    immediate risk scoring based on recent call patterns for the caller.

    **Request Body:**
    - caller_number: Caller phone number in E.164 format
    - callee_number: Callee phone number in E.164 format
    - duration_seconds: Call duration in seconds
    - call_direction: Call direction (inbound/outbound)
    - timestamp: ISO 8601 timestamp

    **Returns:**
    - status: "accepted"
    - event_id: Unique event identifier
    - risk_score: Real-time risk score (0.0-1.0)

    **Risk Scoring Logic:**
    - Analyzes caller's pattern in last 24 hours
    - Considers: unique destinations, average duration, call frequency
    - Higher scores indicate higher fraud risk
    """
    try:
        from datetime import datetime
        import uuid

        # Parse timestamp
        try:
            call_timestamp = datetime.fromisoformat(event.timestamp.replace('Z', '+00:00'))
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid timestamp format. Use ISO 8601 (e.g., 2024-01-15T14:32:15Z)")

        # Create call record
        call_record = CallRecord(
            call_timestamp=call_timestamp,
            caller_number=event.caller_number,
            callee_number=event.callee_number,
            duration_seconds=event.duration_seconds,
            call_direction=event.call_direction
        )

        # Insert call record into database
        db = SentinelDatabase(db_pool)
        await db.insert_call_records([call_record])

        # Calculate risk score based on recent activity
        risk_score = await calculate_risk_score(event.caller_number, db_pool)

        # Generate event ID
        event_id = f"evt_{uuid.uuid4().hex[:12]}"

        return RealTimeEventResponse(
            status="accepted",
            event_id=event_id,
            risk_score=round(risk_score, 2)
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to process call event: {str(e)}")


async def calculate_risk_score(caller_number: str, db_pool: asyncpg.Pool) -> float:
    """
    Calculate real-time risk score for a caller based on recent activity

    Risk factors:
    - High number of unique destinations (24h window)
    - Short average call duration
    - High call frequency

    Returns score between 0.0 (low risk) and 1.0 (high risk)
    """
    try:
        async with db_pool.acquire() as conn:
            # Get caller stats for last 24 hours
            query = """
                SELECT
                    COUNT(DISTINCT callee_number) as unique_destinations,
                    AVG(duration_seconds) as avg_duration,
                    COUNT(*) as call_count
                FROM call_records
                WHERE caller_number = $1
                  AND call_timestamp >= NOW() - INTERVAL '24 hours'
            """
            row = await conn.fetchrow(query, caller_number)

            if not row or row['call_count'] == 0:
                return 0.0  # No recent activity

            unique_destinations = row['unique_destinations'] or 0
            avg_duration = row['avg_duration'] or 0
            call_count = row['call_count'] or 0

            # Risk scoring algorithm
            risk_score = 0.0

            # Factor 1: Unique destinations (weight: 0.5)
            # > 100 destinations = max risk
            destination_risk = min(unique_destinations / 100.0, 1.0) * 0.5
            risk_score += destination_risk

            # Factor 2: Short call duration (weight: 0.3)
            # < 3 seconds avg = max risk
            if avg_duration > 0:
                duration_risk = max(1.0 - (avg_duration / 3.0), 0.0) * 0.3
                risk_score += duration_risk

            # Factor 3: High call frequency (weight: 0.2)
            # > 200 calls = max risk
            frequency_risk = min(call_count / 200.0, 1.0) * 0.2
            risk_score += frequency_risk

            return min(risk_score, 1.0)

    except Exception:
        # Return neutral score on error
        return 0.5


@router.get("/metrics")
async def get_metrics():
    """
    Get Prometheus-formatted metrics for monitoring

    Returns metrics in Prometheus exposition format including:
    - CDR ingestion counters
    - Alert generation statistics
    - API performance histograms
    - Cache and database pool utilization
    """
    from .metrics import get_metrics
    from fastapi.responses import PlainTextResponse

    metrics = get_metrics()
    return PlainTextResponse(
        content=metrics.get_prometheus_metrics(),
        media_type="text/plain"
    )


@router.get("/metrics/json")
async def get_metrics_json():
    """
    Get metrics in JSON format

    Returns the same metrics as /metrics endpoint but in JSON format
    for easier programmatic access and debugging.
    """
    from .metrics import get_metrics

    metrics = get_metrics()
    return metrics.get_json_metrics()


@router.get("/performance/stats")
async def get_performance_stats():
    """
    Get detailed performance statistics

    Returns performance statistics for all monitored operations including
    percentiles, cache statistics, and operation-specific metrics.
    """
    from .performance import get_performance_monitor, get_cache

    perf_monitor = get_performance_monitor()
    cache = get_cache()

    return {
        "performance": perf_monitor.get_all_stats(),
        "cache": cache.get_stats()
    }
