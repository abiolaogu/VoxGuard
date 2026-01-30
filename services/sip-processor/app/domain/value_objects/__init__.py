"""Domain Value Objects package"""

from .value_objects import (
    MSISDN,
    IPAddress,
    FraudScore,
    CallId,
    Severity,
    FraudType,
    DetectionWindow,
    DetectionThreshold,
    InvalidMSISDNError,
    InvalidIPAddressError,
    NIGERIAN_PREFIXES,
)

__all__ = [
    "MSISDN",
    "IPAddress", 
    "FraudScore",
    "CallId",
    "Severity",
    "FraudType",
    "DetectionWindow",
    "DetectionThreshold",
    "InvalidMSISDNError",
    "InvalidIPAddressError",
    "NIGERIAN_PREFIXES",
]
