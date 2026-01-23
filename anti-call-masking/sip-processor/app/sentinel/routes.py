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
from .models import CDRIngestResponse
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
    severity: Optional[str] = Query(None, regex="^(LOW|MEDIUM|HIGH|CRITICAL)$"),
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
