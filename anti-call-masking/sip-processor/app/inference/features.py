"""Feature extraction for masking detection."""
import numpy as np
from dataclasses import dataclass
from typing import Optional

from ..cdr.models import CDRMetrics


@dataclass
class MaskingFeatures:
    """Features extracted for masking detection model."""
    
    # CDR Metrics
    asr: float                    # Answer Seizure Ratio (0-100)
    aloc: float                   # Average Length of Call (seconds)
    overlap_ratio: float          # Concurrent caller ratio (0-1)
    
    # Identity Features
    cli_mismatch: float           # 1.0 if CLI != P-Asserted-Identity
    
    # Volume Features  
    distinct_a_count: int         # Distinct callers in window
    call_rate: float              # Calls per second
    
    # Derived Features
    short_call_ratio: float       # Ratio of calls < 10 seconds
    high_volume_flag: float       # 1.0 if > 10 calls in 5 seconds
    
    def to_array(self) -> np.ndarray:
        """Convert to numpy array for model input."""
        return np.array([[
            self.asr,
            self.aloc,
            self.overlap_ratio,
            self.cli_mismatch,
            float(self.distinct_a_count),
            self.call_rate,
            self.short_call_ratio,
            self.high_volume_flag
        ]])
    
    @classmethod
    def feature_names(cls) -> list[str]:
        """Get ordered feature names."""
        return [
            "asr",
            "aloc", 
            "overlap_ratio",
            "cli_mismatch",
            "distinct_a_count",
            "call_rate",
            "short_call_ratio",
            "high_volume_flag"
        ]


class FeatureExtractor:
    """Extract features from CDR metrics and SIP data."""
    
    # Thresholds
    SHORT_CALL_THRESHOLD = 10.0  # seconds
    HIGH_VOLUME_THRESHOLD = 10   # calls in 5 seconds
    
    def extract(
        self,
        metrics: CDRMetrics,
        cli_mismatch: bool = False,
        call_rate: float = 0.0,
        short_call_ratio: float = 0.0
    ) -> MaskingFeatures:
        """Extract features for model prediction.
        
        Args:
            metrics: CDR metrics for the B-number
            cli_mismatch: Whether CLI differs from P-Asserted-Identity
            call_rate: Calls per second to this B-number
            short_call_ratio: Ratio of short duration calls
            
        Returns:
            MaskingFeatures ready for model input
        """
        return MaskingFeatures(
            asr=metrics.asr,
            aloc=metrics.aloc,
            overlap_ratio=metrics.overlap_ratio,
            cli_mismatch=1.0 if cli_mismatch else 0.0,
            distinct_a_count=metrics.concurrent_callers,
            call_rate=call_rate,
            short_call_ratio=short_call_ratio,
            high_volume_flag=1.0 if metrics.concurrent_callers >= self.HIGH_VOLUME_THRESHOLD else 0.0
        )
    
    def extract_from_dict(
        self,
        metrics_dict: dict,
        sip_info: dict
    ) -> MaskingFeatures:
        """Extract features from dictionaries.
        
        Args:
            metrics_dict: Dictionary with ASR, ALOC, overlap_ratio
            sip_info: Dictionary with CLI mismatch, call rate info
            
        Returns:
            MaskingFeatures ready for model input
        """
        return MaskingFeatures(
            asr=metrics_dict.get("asr", 0.0),
            aloc=metrics_dict.get("aloc", 0.0),
            overlap_ratio=metrics_dict.get("overlap_ratio", 0.0),
            cli_mismatch=1.0 if sip_info.get("cli_mismatch", False) else 0.0,
            distinct_a_count=sip_info.get("distinct_a_count", 0),
            call_rate=sip_info.get("call_rate", 0.0),
            short_call_ratio=sip_info.get("short_call_ratio", 0.0),
            high_volume_flag=1.0 if sip_info.get("distinct_a_count", 0) >= self.HIGH_VOLUME_THRESHOLD else 0.0
        )
