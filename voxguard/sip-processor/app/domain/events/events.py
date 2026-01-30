"""
Domain Events - Events for cross-context communication

Domain events represent significant business occurrences that
other parts of the system may need to react to.
"""

from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional, List
from abc import ABC
import uuid


@dataclass
class DomainEvent(ABC):
    """Base class for all domain events"""
    event_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    occurred_at: datetime = field(default_factory=datetime.utcnow)
    
    @property
    def event_type(self) -> str:
        return self.__class__.__name__


@dataclass
class CallRegisteredEvent(DomainEvent):
    """Emitted when a new call is registered in the system"""
    call_id: str = ""
    a_number: str = ""
    b_number: str = ""
    source_ip: str = ""


@dataclass
class FraudDetectedEvent(DomainEvent):
    """Emitted when fraud is detected"""
    alert_id: str = ""
    b_number: str = ""
    fraud_type: str = ""
    distinct_callers: int = 0
    score: float = 0.0
    source_ips: List[str] = field(default_factory=list)


@dataclass
class AlertAcknowledgedEvent(DomainEvent):
    """Emitted when an alert is acknowledged"""
    alert_id: str = ""
    acknowledged_by: str = ""


@dataclass
class AlertResolvedEvent(DomainEvent):
    """Emitted when an alert is resolved"""
    alert_id: str = ""
    resolved_by: str = ""
    resolution: str = ""
    notes: Optional[str] = None


@dataclass
class GatewayBlacklistedEvent(DomainEvent):
    """Emitted when a gateway is blacklisted"""
    gateway_id: str = ""
    gateway_ip: str = ""
    reason: str = ""


@dataclass
class NCCReportSubmittedEvent(DomainEvent):
    """Emitted when a report is submitted to NCC"""
    report_id: str = ""
    alert_ids: List[str] = field(default_factory=list)
    ncc_reference: str = ""


class EventBus:
    """
    Simple in-process event bus for domain events
    
    In production, this would be replaced with a message broker
    like RabbitMQ, Kafka, or NATS.
    """
    
    def __init__(self):
        self._handlers: dict = {}
    
    def subscribe(self, event_type: type, handler: callable) -> None:
        """Subscribes a handler to an event type"""
        if event_type not in self._handlers:
            self._handlers[event_type] = []
        self._handlers[event_type].append(handler)
    
    async def publish(self, event: DomainEvent) -> None:
        """Publishes an event to all subscribers"""
        event_type = type(event)
        handlers = self._handlers.get(event_type, [])
        for handler in handlers:
            try:
                if asyncio.iscoroutinefunction(handler):
                    await handler(event)
                else:
                    handler(event)
            except Exception as e:
                # Log error but don't stop processing
                print(f"Error in event handler: {e}")
    
    async def publish_all(self, events: List[DomainEvent]) -> None:
        """Publishes multiple events"""
        for event in events:
            await self.publish(event)


import asyncio  # Import at end to avoid circular import


# Global event bus instance
_event_bus: Optional[EventBus] = None


def get_event_bus() -> EventBus:
    """Gets the global event bus instance"""
    global _event_bus
    if _event_bus is None:
        _event_bus = EventBus()
    return _event_bus
