"""
Domain Services - Business logic that spans multiple entities

Services implement complex operations that don't naturally belong
to a single entity.
"""

from datetime import datetime, timedelta
from typing import List, Optional, Tuple

from app.domain.entities import Call, FraudAlert, CallStatus
from app.domain.value_objects import (
    MSISDN, IPAddress, FraudScore, FraudType, CallId,
    DetectionWindow, DetectionThreshold,
)
from app.domain.repositories import CallRepository, AlertRepository, DetectionCache, TimeSeriesStore
from app.domain.events import DomainEvent, FraudDetectedEvent, CallRegisteredEvent


class DetectionService:
    """
    Core fraud detection service using sliding window algorithm
    
    Detects CLI masking attacks by counting distinct callers
    to the same B-number within a configured time window.
    """
    
    def __init__(
        self,
        call_repo: CallRepository,
        alert_repo: AlertRepository,
        cache: DetectionCache,
        ts_store: TimeSeriesStore,
        window_seconds: int = 5,
        threshold: int = 5,
    ):
        self.call_repo = call_repo
        self.alert_repo = alert_repo
        self.cache = cache
        self.ts_store = ts_store
        self.window = DetectionWindow(window_seconds)
        self.threshold = DetectionThreshold(threshold)
        self._pending_events: List[DomainEvent] = []
    
    async def register_call(
        self,
        a_number: str,
        b_number: str,
        source_ip: str,
        call_id: Optional[str] = None,
    ) -> Tuple[Call, Optional[FraudAlert]]:
        """
        Registers a new call and performs fraud detection
        
        Returns:
            Tuple of (Call, FraudAlert or None if no fraud detected)
        """
        # Create call entity
        call = Call.create(a_number, b_number, source_ip)
        if call_id:
            call.raw_call_id = call_id
        
        # Emit call registered event
        self._pending_events.append(CallRegisteredEvent(
            call_id=str(call.id),
            a_number=a_number,
            b_number=b_number,
            source_ip=source_ip,
        ))
        
        # Add to cache for sliding window detection
        await self.cache.add_caller_to_window(
            b_number=str(call.b_number),
            a_number=str(call.a_number),
            call_id=str(call.id),
            source_ip=source_ip,
            window_seconds=self.window.seconds,
        )
        
        # Persist call
        await self.call_repo.save(call)
        
        # Ingest to time-series store
        await self.ts_store.ingest_call(call)
        
        # Check for fraud
        distinct_count = await self.cache.get_distinct_caller_count(str(call.b_number))
        
        if distinct_count >= self.threshold.distinct_callers:
            alert = await self._create_fraud_alert(call, distinct_count)
            return call, alert
        
        return call, None
    
    async def _create_fraud_alert(self, trigger_call: Call, distinct_count: int) -> FraudAlert:
        """Creates a fraud alert when threshold is exceeded"""
        # Get all callers from the window
        callers = await self.cache.get_distinct_callers(str(trigger_call.b_number))
        now = datetime.utcnow()
        window_start = now - timedelta(seconds=self.window.seconds)
        
        # Get all calls in the window
        calls = await self.call_repo.find_calls_in_window(
            trigger_call.b_number,
            window_start,
            now,
        )
        
        # Calculate confidence score
        confidence = min(1.0, distinct_count / 10.0)  # 10 callers = 100% confidence
        
        # Determine fraud type based on source IP
        if trigger_call.source_ip.is_likely_international:
            fraud_type = FraudType.CLI_MASKING
        else:
            fraud_type = FraudType.SIMBOX
        
        # Create alert
        alert = FraudAlert.create(
            b_number=str(trigger_call.b_number),
            fraud_type=fraud_type,
            score=confidence,
            a_numbers=callers,
            call_ids=[str(c.id) for c in calls],
            source_ips=list(set(str(c.source_ip) for c in calls)),
        )
        
        # Flag all calls in the window
        for call in calls:
            call.flag_as_fraud(alert.id, FraudScore(confidence))
            await self.call_repo.save(call)
        
        # Persist alert
        await self.alert_repo.save(alert)
        
        # Ingest to time-series
        await self.ts_store.ingest_alert(alert)
        
        # Clear window to prevent duplicate alerts
        await self.cache.clear_window(str(trigger_call.b_number))
        
        # Emit fraud detected event
        self._pending_events.append(FraudDetectedEvent(
            alert_id=alert.id,
            b_number=str(alert.b_number),
            fraud_type=fraud_type.value,
            distinct_callers=distinct_count,
            score=confidence,
        ))
        
        return alert
    
    def get_pending_events(self) -> List[DomainEvent]:
        """Returns and clears pending domain events"""
        events = self._pending_events
        self._pending_events = []
        return events


class AlertService:
    """Service for managing fraud alert lifecycle"""
    
    def __init__(self, alert_repo: AlertRepository):
        self.alert_repo = alert_repo
        self._pending_events: List[DomainEvent] = []
    
    async def acknowledge_alert(self, alert_id: str, user_id: str) -> FraudAlert:
        """Acknowledges an alert"""
        alert = await self.alert_repo.find_by_id(alert_id)
        if not alert:
            raise ValueError(f"Alert not found: {alert_id}")
        
        alert.acknowledge(user_id)
        await self.alert_repo.save(alert)
        return alert
    
    async def resolve_alert(
        self,
        alert_id: str,
        user_id: str,
        resolution: str,
        notes: Optional[str] = None,
    ) -> FraudAlert:
        """Resolves an alert"""
        from app.domain.entities import ResolutionType
        
        alert = await self.alert_repo.find_by_id(alert_id)
        if not alert:
            raise ValueError(f"Alert not found: {alert_id}")
        
        resolution_type = ResolutionType(resolution)
        alert.resolve(user_id, resolution_type, notes)
        await self.alert_repo.save(alert)
        return alert
    
    async def get_pending_alerts(self) -> List[FraudAlert]:
        """Gets all pending alerts"""
        return await self.alert_repo.find_pending()
    
    async def get_pending_count(self) -> int:
        """Gets count of pending alerts"""
        return await self.alert_repo.count_pending()
