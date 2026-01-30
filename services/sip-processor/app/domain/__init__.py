"""
Domain Layer Package

Provides the core business logic independent of infrastructure:
- Value Objects: Immutable objects with validation (MSISDN, IPAddress, etc.)
- Entities: Business objects with identity (Call, FraudAlert, Blacklist)
- Repositories: Abstract interfaces for data access
- Services: Business logic spanning multiple entities
- Events: Domain events for cross-context communication
"""

from app.domain.value_objects import (
    MSISDN,
    IPAddress,
    FraudScore,
    CallId,
    Severity,
    FraudType,
    DetectionWindow,
    DetectionThreshold,
)

from app.domain.entities import (
    Call,
    CallStatus,
    FraudAlert,
    AlertStatus,
    ResolutionType,
    Blacklist,
)

from app.domain.repositories import (
    CallRepository,
    AlertRepository,
    BlacklistRepository,
    DetectionCache,
    TimeSeriesStore,
)

from app.domain.services import (
    DetectionService,
    AlertService,
)

from app.domain.events import (
    DomainEvent,
    CallRegisteredEvent,
    FraudDetectedEvent,
    AlertAcknowledgedEvent,
    AlertResolvedEvent,
    EventBus,
    get_event_bus,
)

__all__ = [
    # Value Objects
    "MSISDN",
    "IPAddress",
    "FraudScore",
    "CallId",
    "Severity",
    "FraudType",
    "DetectionWindow",
    "DetectionThreshold",
    # Entities
    "Call",
    "CallStatus",
    "FraudAlert",
    "AlertStatus",
    "ResolutionType",
    "Blacklist",
    # Repositories
    "CallRepository",
    "AlertRepository",
    "BlacklistRepository",
    "DetectionCache",
    "TimeSeriesStore",
    # Services
    "DetectionService",
    "AlertService",
    # Events
    "DomainEvent",
    "CallRegisteredEvent",
    "FraudDetectedEvent",
    "AlertAcknowledgedEvent",
    "AlertResolvedEvent",
    "EventBus",
    "get_event_bus",
]
