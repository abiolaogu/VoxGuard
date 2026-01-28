"""
Repository Abstractions - Interfaces for data access

Repository interfaces define the contract for persistence operations,
allowing domain logic to be independent of infrastructure.
"""

from abc import ABC, abstractmethod
from datetime import datetime
from typing import Optional, List, Protocol

from app.domain.entities import Call, FraudAlert, Blacklist, AlertStatus
from app.domain.value_objects import CallId, MSISDN


class CallRepository(ABC):
    """Repository interface for Call aggregate"""
    
    @abstractmethod
    async def save(self, call: Call) -> None:
        """Persists a call (insert or update)"""
        pass
    
    @abstractmethod
    async def find_by_id(self, call_id: CallId) -> Optional[Call]:
        """Finds a call by ID"""
        pass
    
    @abstractmethod
    async def find_calls_in_window(
        self,
        b_number: MSISDN,
        window_start: datetime,
        window_end: datetime,
    ) -> List[Call]:
        """Finds all calls to a B-number within a time window"""
        pass
    
    @abstractmethod
    async def count_distinct_callers(
        self,
        b_number: MSISDN,
        window_start: datetime,
        window_end: datetime,
    ) -> int:
        """Counts distinct A-numbers calling a B-number in window"""
        pass
    
    @abstractmethod
    async def flag_as_fraud(self, call_ids: List[CallId], alert_id: str) -> int:
        """Flags multiple calls as part of a fraud alert"""
        pass


class AlertRepository(ABC):
    """Repository interface for FraudAlert aggregate"""
    
    @abstractmethod
    async def save(self, alert: FraudAlert) -> None:
        """Persists an alert (insert or update)"""
        pass
    
    @abstractmethod
    async def find_by_id(self, alert_id: str) -> Optional[FraudAlert]:
        """Finds an alert by ID"""
        pass
    
    @abstractmethod
    async def find_pending(self) -> List[FraudAlert]:
        """Finds all pending alerts"""
        pass
    
    @abstractmethod
    async def find_by_status(self, status: AlertStatus) -> List[FraudAlert]:
        """Finds alerts by status"""
        pass
    
    @abstractmethod
    async def count_pending(self) -> int:
        """Counts pending alerts"""
        pass


class BlacklistRepository(ABC):
    """Repository interface for Blacklist"""
    
    @abstractmethod
    async def save(self, entry: Blacklist) -> None:
        """Persists a blacklist entry"""
        pass
    
    @abstractmethod
    async def find_by_value(self, value: str) -> Optional[Blacklist]:
        """Finds a blacklist entry by value"""
        pass
    
    @abstractmethod
    async def is_blacklisted(self, value: str) -> bool:
        """Checks if a value is blacklisted"""
        pass
    
    @abstractmethod
    async def delete(self, entry_id: str) -> None:
        """Deletes a blacklist entry"""
        pass
    
    @abstractmethod
    async def cleanup_expired(self) -> int:
        """Removes expired entries, returns count deleted"""
        pass


class DetectionCache(Protocol):
    """Protocol for detection cache (sliding window)"""
    
    async def add_caller_to_window(
        self,
        b_number: str,
        a_number: str,
        call_id: str,
        source_ip: str,
        window_seconds: int,
    ) -> None:
        """Adds a caller to the detection window"""
        ...
    
    async def get_distinct_caller_count(self, b_number: str) -> int:
        """Gets distinct caller count for a B-number"""
        ...
    
    async def get_distinct_callers(self, b_number: str) -> List[str]:
        """Gets list of distinct callers for a B-number"""
        ...
    
    async def clear_window(self, b_number: str) -> None:
        """Clears the detection window for a B-number"""
        ...


class TimeSeriesStore(Protocol):
    """Protocol for time-series storage (QuestDB)"""
    
    async def ingest_call(self, call: Call) -> None:
        """Ingests a call into time-series storage"""
        ...
    
    async def ingest_alert(self, alert: FraudAlert) -> None:
        """Ingests an alert into time-series storage"""
        ...
    
    async def get_call_metrics(
        self,
        b_number: str,
        window_seconds: int,
    ) -> dict:
        """Gets call metrics for a B-number"""
        ...
