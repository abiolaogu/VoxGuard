"""
Anti-Call Masking Detection System - LumaDB Edition
FastAPI HTTP Server replacing kdb+ HTTP server
"""

from contextlib import asynccontextmanager
from datetime import datetime
from typing import List, Optional
import structlog
from fastapi import FastAPI, HTTPException, Query, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response

from config import settings
from models import (
    CallEvent, FraudAlert, AlertStatus, ThreatLevel, DetectionResult
)
from database import db
from detection import engine

logger = structlog.get_logger()

# Prometheus metrics
CALLS_PROCESSED = Counter(
    'acm_calls_processed_total',
    'Total number of calls processed'
)
ALERTS_GENERATED = Counter(
    'acm_alerts_generated_total',
    'Total number of fraud alerts generated',
    ['severity']
)
DETECTION_LATENCY = Histogram(
    'acm_detection_latency_seconds',
    'Call detection latency in seconds',
    buckets=[.0001, .0005, .001, .005, .01, .025, .05, .1, .25, .5, 1.0]
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler"""
    # Startup
    logger.info("Starting Anti-Call Masking Detection System (LumaDB Edition)")
    await db.initialize()
    yield
    # Shutdown
    await db.close()
    logger.info("Shutdown complete")


app = FastAPI(
    title="Anti-Call Masking Detection System",
    description="Real-time fraud detection using LumaDB time-series analytics",
    version="2.0.0",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.api.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# =========================================================================
# Health & Status Endpoints
# =========================================================================

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    try:
        stats = await db.get_stats()
        return {
            "status": "healthy",
            "timestamp": datetime.utcnow().isoformat(),
            "version": settings.app_version,
            "database": "connected",
            "stats": stats
        }
    except Exception as e:
        raise HTTPException(status_code=503, detail=str(e))


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "name": settings.app_name,
        "version": settings.app_version,
        "description": "Anti-Call Masking Detection System powered by LumaDB",
        "endpoints": {
            "health": "/health",
            "call": "POST /acm/call",
            "alerts": "GET /acm/alerts",
            "threat": "GET /acm/threat",
            "stats": "GET /acm/stats"
        }
    }


# =========================================================================
# Call Processing Endpoints (replacing kdb+ IPC)
# =========================================================================

class CallEventRequest(BaseModel):
    """Request model for call event"""
    a_number: str
    b_number: str
    source_ip: Optional[str] = None
    switch_id: Optional[str] = None
    call_id: Optional[str] = None
    raw_call_id: Optional[str] = None


class BatchCallRequest(BaseModel):
    """Request model for batch call events"""
    events: List[CallEventRequest]


@app.post("/acm/call", response_model=DetectionResult)
async def process_call(request: CallEventRequest, background_tasks: BackgroundTasks):
    """
    Process a single call event for fraud detection.

    This endpoint accepts call events from voice switches and
    checks for multicall masking attacks in real-time.
    """
    event = CallEvent(
        a_number=request.a_number,
        b_number=request.b_number,
        source_ip=request.source_ip,
        switch_id=request.switch_id,
        call_id=request.call_id,
        raw_call_id=request.raw_call_id
    )

    with DETECTION_LATENCY.time():
        result = await engine.process_call(event)

    CALLS_PROCESSED.inc()
    if result.detected and result.alert_id:
        ALERTS_GENERATED.labels(severity="detected").inc()

    # Background cleanup
    background_tasks.add_task(db.cleanup_old_records)

    return result


@app.post("/acm/calls/batch")
async def process_call_batch(request: BatchCallRequest, background_tasks: BackgroundTasks):
    """Process a batch of call events"""
    events = [
        CallEvent(
            a_number=e.a_number,
            b_number=e.b_number,
            source_ip=e.source_ip,
            switch_id=e.switch_id,
            call_id=e.call_id,
            raw_call_id=e.raw_call_id
        )
        for e in request.events
    ]

    results = await engine.process_batch(events)
    CALLS_PROCESSED.inc(len(events))

    detected_count = sum(1 for r in results if r.detected)
    if detected_count > 0:
        ALERTS_GENERATED.labels(severity="batch").inc(detected_count)

    background_tasks.add_task(db.cleanup_old_records)

    return {
        "processed": len(results),
        "detected": detected_count,
        "results": results
    }


# Voice-Switch-IM compatible endpoint
@app.post("/event")
async def process_event(request: CallEventRequest, background_tasks: BackgroundTasks):
    """Voice-Switch-IM compatible call event endpoint"""
    return await process_call(request, background_tasks)


@app.post("/events/batch")
async def process_events_batch(request: BatchCallRequest, background_tasks: BackgroundTasks):
    """Voice-Switch-IM compatible batch endpoint"""
    return await process_call_batch(request, background_tasks)


# =========================================================================
# Alert Endpoints
# =========================================================================

@app.get("/acm/alerts")
async def get_alerts(minutes: int = Query(60, ge=1, le=10080)):
    """Get fraud alerts from the last N minutes"""
    alerts = await db.get_recent_alerts(minutes)
    return {
        "count": len(alerts),
        "minutes": minutes,
        "alerts": [alert.model_dump() for alert in alerts]
    }


@app.get("/acm/alerts/{alert_id}")
async def get_alert(alert_id: str):
    """Get specific alert details"""
    alert = await db.get_alert(alert_id)
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    return alert.model_dump()


class UpdateAlertRequest(BaseModel):
    status: AlertStatus
    notes: Optional[str] = None


@app.patch("/acm/alerts/{alert_id}")
async def update_alert(alert_id: str, request: UpdateAlertRequest):
    """Update alert status"""
    success = await db.update_alert_status(alert_id, request.status, request.notes)
    if not success:
        raise HTTPException(status_code=404, detail="Alert not found")
    return {"success": True, "alert_id": alert_id, "new_status": request.status.value}


# =========================================================================
# Threat Level Endpoints
# =========================================================================

@app.get("/acm/threat")
async def get_threat_level(b_number: str = Query(..., min_length=1)):
    """Get current threat level for a B-number"""
    threat = await db.get_threat_level(b_number)
    return threat.model_dump()


@app.get("/acm/threats")
async def get_elevated_threats():
    """Get all B-numbers with elevated threat levels"""
    threats = await db.get_elevated_threats()
    return {
        "count": len(threats),
        "threats": [t.model_dump() for t in threats]
    }


# =========================================================================
# Statistics Endpoints
# =========================================================================

@app.get("/acm/stats")
async def get_stats():
    """Get detection statistics"""
    db_stats = await db.get_stats()
    engine_stats = engine.get_stats()
    return {
        **db_stats,
        **engine_stats,
        "timestamp": datetime.utcnow().isoformat()
    }


@app.get("/stats")
async def get_stats_compat():
    """Compatibility endpoint for stats"""
    return await get_stats()


# =========================================================================
# Configuration Endpoints
# =========================================================================

class ConfigUpdateRequest(BaseModel):
    threshold: Optional[int] = None
    window_seconds: Optional[int] = None


@app.post("/acm/config")
async def update_config(request: ConfigUpdateRequest):
    """Update detection configuration"""
    results = {}

    if request.threshold is not None:
        success = await engine.set_threshold(request.threshold)
        results["threshold"] = {"success": success, "value": request.threshold}

    if request.window_seconds is not None:
        success = await engine.set_window(request.window_seconds)
        results["window_seconds"] = {"success": success, "value": request.window_seconds}

    return results


@app.get("/acm/config")
async def get_config():
    """Get current detection configuration"""
    return {
        "window_seconds": settings.detection.window_seconds,
        "threshold": settings.detection.threshold,
        "cooldown_seconds": settings.detection.cooldown_seconds,
        "auto_disconnect": settings.detection.auto_disconnect,
        "auto_block": settings.detection.auto_block,
        "block_duration_hours": settings.detection.block_duration_hours
    }


# =========================================================================
# Prometheus Metrics Endpoint
# =========================================================================

@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    return Response(
        content=generate_latest(),
        media_type=CONTENT_TYPE_LATEST
    )


# =========================================================================
# Main entry point
# =========================================================================

def main():
    """Run the API server"""
    import uvicorn
    uvicorn.run(
        "api:app",
        host=settings.api.host,
        port=settings.api.port,
        workers=settings.api.workers,
        reload=settings.api.debug
    )


if __name__ == "__main__":
    main()
