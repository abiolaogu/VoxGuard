"""
Sentinel API routes

FastAPI endpoints for CDR ingestion and alert management.
"""
import time
from fastapi import APIRouter, UploadFile, File, HTTPException, Depends, Query
from typing import Optional
import asyncpg

from .parser import CDRParser
from .database import SentinelDatabase
from .models import CDRIngestResponse

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
