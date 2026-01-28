"""
Domain Value Objects - Immutable objects with validation

These value objects encapsulate Nigerian telecom-specific validations
and provide type-safe representations used across the domain.
"""

import re
from dataclasses import dataclass
from typing import Optional, Tuple
from enum import Enum
from ipaddress import ip_address, IPv4Address, IPv6Address


class InvalidMSISDNError(ValueError):
    """Raised when MSISDN format is invalid"""
    pass


class InvalidIPAddressError(ValueError):
    """Raised when IP address format is invalid"""
    pass


# Nigerian carrier prefixes mapping
NIGERIAN_PREFIXES = {
    "MTN": ["0803", "0806", "0703", "0706", "0813", "0816", "0814", "0903", "0906"],
    "GLO": ["0805", "0807", "0705", "0815", "0811", "0905"],
    "AIRTEL": ["0802", "0808", "0708", "0812", "0701", "0902", "0901", "0907"],
    "9MOBILE": ["0809", "0818", "0817", "0909", "0908"],
}


@dataclass(frozen=True)
class MSISDN:
    """
    Mobile Station International Subscriber Directory Number
    
    Represents a Nigerian phone number with validation and normalization.
    Format: +234XXXXXXXXXX (E.164)
    """
    value: str
    
    def __post_init__(self):
        if not self._is_valid(self.value):
            raise InvalidMSISDNError(f"Invalid MSISDN format: {self.value}")
    
    @staticmethod
    def _is_valid(value: str) -> bool:
        """Validates Nigerian MSISDN format"""
        # Pattern: +234 followed by 10 digits
        pattern = r'^\+?234[0-9]{10}$'
        return bool(re.match(pattern, value))
    
    @classmethod
    def from_string(cls, value: str) -> 'MSISDN':
        """Creates MSISDN from various formats with normalization"""
        normalized = cls._normalize(value)
        return cls(normalized)
    
    @staticmethod
    def _normalize(value: str) -> str:
        """Normalizes to +234XXXXXXXXXX format"""
        # Remove spaces and dashes
        cleaned = re.sub(r'[\s\-]', '', value)
        
        # Handle different formats
        if cleaned.startswith('0') and len(cleaned) == 11:
            return '+234' + cleaned[1:]
        elif cleaned.startswith('234') and len(cleaned) == 13:
            return '+' + cleaned
        elif cleaned.startswith('+234') and len(cleaned) == 14:
            return cleaned
        
        return cleaned
    
    @property
    def prefix(self) -> str:
        """Returns the 4-digit prefix (e.g., 0803)"""
        if self.value.startswith('+234'):
            return '0' + self.value[4:7]
        return self.value[:4]
    
    @property
    def carrier(self) -> Optional[str]:
        """Returns the carrier name based on prefix"""
        prefix = self.prefix
        for carrier, prefixes in NIGERIAN_PREFIXES.items():
            if prefix in prefixes:
                return carrier
        return None
    
    @property
    def is_nigerian(self) -> bool:
        """Returns True if this is a Nigerian number"""
        return self.value.startswith('+234')
    
    def __str__(self) -> str:
        return self.value


@dataclass(frozen=True)
class IPAddress:
    """
    IP Address value object with validation and classification
    """
    value: str
    _parsed: object = None
    
    def __post_init__(self):
        try:
            parsed = ip_address(self.value)
            object.__setattr__(self, '_parsed', parsed)
        except ValueError:
            raise InvalidIPAddressError(f"Invalid IP address: {self.value}")
    
    @property
    def is_ipv4(self) -> bool:
        return isinstance(self._parsed, IPv4Address)
    
    @property
    def is_ipv6(self) -> bool:
        return isinstance(self._parsed, IPv6Address)
    
    @property
    def is_private(self) -> bool:
        """Returns True if this is a private/internal IP"""
        return self._parsed.is_private
    
    @property
    def is_likely_international(self) -> bool:
        """Heuristic: non-private IPs from non-Nigerian ranges may be international"""
        return not self.is_private
    
    def __str__(self) -> str:
        return self.value


class Severity(Enum):
    """Alert severity levels"""
    LOW = 1
    MEDIUM = 2
    HIGH = 3
    CRITICAL = 4
    
    @classmethod
    def from_score(cls, score: float) -> 'Severity':
        """Determines severity from confidence score"""
        if score >= 0.9:
            return cls.CRITICAL
        elif score >= 0.75:
            return cls.HIGH
        elif score >= 0.5:
            return cls.MEDIUM
        return cls.LOW


class FraudType(Enum):
    """Types of fraud detected"""
    CLI_MASKING = "cli_masking"
    SIMBOX = "simbox"
    WANGIRI = "wangiri"
    IRSF = "irsf"
    PBX_HACKING = "pbx_hacking"
    UNKNOWN = "unknown"


@dataclass(frozen=True)
class FraudScore:
    """
    Fraud confidence score (0.0 - 1.0)
    
    Represents the confidence level of fraud detection.
    """
    value: float
    
    def __post_init__(self):
        # Clamp value between 0 and 1
        clamped = max(0.0, min(1.0, self.value))
        object.__setattr__(self, 'value', clamped)
    
    @property
    def severity(self) -> Severity:
        return Severity.from_score(self.value)
    
    @property
    def is_high_confidence(self) -> bool:
        return self.value >= 0.8
    
    @property
    def exceeds_block_threshold(self) -> bool:
        return self.value >= 0.9
    
    def __float__(self) -> float:
        return self.value


@dataclass(frozen=True)
class CallId:
    """Unique call identifier"""
    value: str
    
    def __post_init__(self):
        if not self.value or len(self.value.strip()) == 0:
            raise ValueError("CallId cannot be empty")
    
    @classmethod
    def generate(cls) -> 'CallId':
        import uuid
        return cls(str(uuid.uuid4()))
    
    def __str__(self) -> str:
        return self.value


@dataclass(frozen=True)
class DetectionWindow:
    """Detection time window configuration"""
    seconds: int
    
    def __post_init__(self):
        if self.seconds < 1 or self.seconds > 60:
            raise ValueError(f"Detection window must be 1-60 seconds, got {self.seconds}")


@dataclass(frozen=True)
class DetectionThreshold:
    """Threshold for distinct caller detection"""
    distinct_callers: int
    
    def __post_init__(self):
        if self.distinct_callers < 2 or self.distinct_callers > 100:
            raise ValueError(f"Threshold must be 2-100 callers, got {self.distinct_callers}")
