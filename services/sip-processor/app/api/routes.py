"""API endpoints for SIP processing and masking detection."""
import logging
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
import redis.asyncio as redis

from ..config import get_settings
from ..dependencies import get_redis
from ..cdr.metrics import CDRMetricsCalculator
from ..cdr.models import CDRMetrics
from ..inference.engine import MaskingInferenceEngine, PredictionResult
from ..signaling.parser import parse_sip_message
from .schemas import (
    CallAnalysisRequest,
    CallAnalysisResponse,
    CDRMetricsResponse,
    SIPParseRequest,
    SIPParseResponse,
    AlertResponse
)

logger = logging.getLogger(__name__)

router = APIRouter(tags=["call-analysis"])

# Singleton inference engine
_inference_engine: Optional[MaskingInferenceEngine] = None


def get_inference_engine() -> MaskingInferenceEngine:
    """Get or create inference engine singleton."""
    global _inference_engine
    if _inference_engine is None:
        settings = get_settings()
        _inference_engine = MaskingInferenceEngine(
            model_path=settings.model_path,
            threshold=settings.masking_probability_threshold
        )
    return _inference_engine


@router.post("/analyze", response_model=CallAnalysisResponse)
async def analyze_call(
    request: CallAnalysisRequest,
    redis_client: redis.Redis = Depends(get_redis)
) -> CallAnalysisResponse:
    """Analyze a call for potential masking attack.
    
    This endpoint:
    1. Retrieves CDR metrics from Redis
    2. Extracts features from metrics and SIP info
    3. Runs XGBoost inference (or rule-based fallback)
    4. Returns risk assessment
    """
    settings = get_settings()
    
    try:
        # Get CDR metrics calculator
        calculator = CDRMetricsCalculator(
            redis_client, 
            window_seconds=settings.cdr_window_seconds
        )
        
        # Record the call attempt
        await calculator.record_attempt(request.b_number, request.a_number)
        
        # Get real-time metrics
        metrics = await calculator.get_all_metrics(request.b_number)
        
        # Determine CLI mismatch
        cli_mismatch = False
        if request.cli and request.p_asserted_identity:
            cli_mismatch = request.cli != request.p_asserted_identity
        
        # Run inference
        engine = get_inference_engine()
        result = engine.predict(
            metrics=metrics,
            cli_mismatch=cli_mismatch,
            call_rate=request.call_rate,
            short_call_ratio=request.short_call_ratio
        )
        
        # Log alerts
        if result.is_masking:
            logger.warning(
                f"MASKING DETECTED: B={request.b_number} "
                f"prob={result.probability:.2f} risk={result.risk_level}"
            )
        
        return CallAnalysisResponse(
            call_id=request.call_id,
            is_masking=result.is_masking,
            masking_probability=result.probability,
            risk_level=result.risk_level,
            confidence=result.confidence,
            method=result.method,
            metrics=CDRMetricsResponse(
                b_number=metrics.b_number,
                asr=metrics.asr,
                aloc=metrics.aloc,
                overlap_ratio=metrics.overlap_ratio,
                total_attempts=metrics.total_attempts,
                answered_calls=metrics.answered_calls,
                concurrent_callers=metrics.concurrent_callers,
                window_seconds=metrics.window_seconds
            ),
            features_used=result.features_used,
            timestamp=datetime.utcnow()
        )
        
    except Exception as e:
        logger.error(f"Call analysis failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Analysis failed: {str(e)}"
        )


@router.get("/metrics/{b_number}", response_model=CDRMetricsResponse)
async def get_metrics(
    b_number: str,
    redis_client: redis.Redis = Depends(get_redis)
) -> CDRMetricsResponse:
    """Get CDR metrics for a B-number.
    
    Returns real-time ASR, ALOC, and Overlap Ratio calculated
    from Redis counters.
    """
    settings = get_settings()
    
    try:
        calculator = CDRMetricsCalculator(
            redis_client,
            window_seconds=settings.cdr_window_seconds
        )
        metrics = await calculator.get_all_metrics(b_number)
        
        return CDRMetricsResponse(
            b_number=metrics.b_number,
            asr=metrics.asr,
            aloc=metrics.aloc,
            overlap_ratio=metrics.overlap_ratio,
            total_attempts=metrics.total_attempts,
            answered_calls=metrics.answered_calls,
            concurrent_callers=metrics.concurrent_callers,
            window_seconds=metrics.window_seconds
        )
        
    except Exception as e:
        logger.error(f"Failed to get metrics: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve metrics: {str(e)}"
        )


@router.post("/sip/parse", response_model=SIPParseResponse)
async def parse_sip(request: SIPParseRequest) -> SIPParseResponse:
    """Parse a raw SIP message and extract headers.
    
    Useful for testing SIP header extraction without
    packet capture.
    """
    try:
        raw_bytes = request.raw_message.encode("utf-8")
        header_info = parse_sip_message(raw_bytes)
        
        if not header_info:
            return SIPParseResponse(
                success=False,
                error="Failed to parse SIP message"
            )
        
        return SIPParseResponse(
            success=True,
            call_id=header_info.call_id,
            method=header_info.method.value,
            cli=header_info.cli,
            p_asserted_identity=header_info.p_asserted_identity,
            from_uri=header_info.from_uri,
            to_uri=header_info.to_uri,
            has_cli_mismatch=header_info.has_cli_mismatch
        )
        
    except Exception as e:
        logger.error(f"SIP parsing failed: {e}")
        return SIPParseResponse(
            success=False,
            error=str(e)
        )


@router.delete("/metrics/{b_number}")
async def reset_metrics(
    b_number: str,
    redis_client: redis.Redis = Depends(get_redis)
) -> dict:
    """Reset all metrics for a B-number.
    
    Use with caution - this clears all CDR counters.
    """
    settings = get_settings()
    
    try:
        calculator = CDRMetricsCalculator(
            redis_client,
            window_seconds=settings.cdr_window_seconds
        )
        await calculator.reset_metrics(b_number)
        
        return {"status": "reset", "b_number": b_number}
        
    except Exception as e:
        logger.error(f"Failed to reset metrics: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to reset metrics: {str(e)}"
        )


@router.get("/model/status")
async def model_status() -> dict:
    """Get the status of the ML model."""
    engine = get_inference_engine()
    
    return {
        "model_loaded": engine.model_manager.is_loaded,
        "xgboost_available": engine.model_manager.is_available,
        "detection_method": "xgboost" if engine._use_model else "rule_based",
        "threshold": engine.threshold
    }


@router.post("/model/reload")
async def reload_model() -> dict:
    """Reload the XGBoost model from disk."""
    engine = get_inference_engine()
    success = engine.reload_model()
    
    return {
        "success": success,
        "model_loaded": engine.model_manager.is_loaded,
        "detection_method": "xgboost" if engine._use_model else "rule_based"
    }
