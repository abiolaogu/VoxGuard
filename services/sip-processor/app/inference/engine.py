"""XGBoost masking detection inference engine."""
import logging
from dataclasses import dataclass
from typing import Tuple, Optional

import numpy as np

from .features import FeatureExtractor, MaskingFeatures
from .model import ModelManager
from ..cdr.models import CDRMetrics

logger = logging.getLogger(__name__)


@dataclass
class PredictionResult:
    """Result of masking detection prediction."""
    
    is_masking: bool          # Whether call is flagged as masking
    probability: float        # Masking probability (0-1)
    confidence: str           # LOW, MEDIUM, HIGH
    features_used: dict       # Features that were used
    method: str               # "xgboost" or "rule_based"
    
    @property
    def risk_level(self) -> str:
        """Get risk level based on probability."""
        if self.probability >= 0.9:
            return "CRITICAL"
        elif self.probability >= 0.7:
            return "HIGH"
        elif self.probability >= 0.5:
            return "MEDIUM"
        elif self.probability >= 0.3:
            return "LOW"
        return "MINIMAL"


class MaskingInferenceEngine:
    """XGBoost-based call masking detection engine.
    
    Uses a pre-trained XGBoost model to detect masking attacks
    based on CDR metrics and SIP header analysis.
    
    Falls back to rule-based detection if model is unavailable.
    """
    
    # Default thresholds
    DEFAULT_THRESHOLD = 0.7
    RULE_BASED_DISTINCT_A_THRESHOLD = 5
    RULE_BASED_WINDOW_SECONDS = 5
    
    def __init__(
        self, 
        model_path: str = "models/xgboost_masking.json",
        threshold: float = DEFAULT_THRESHOLD
    ):
        """Initialize the inference engine.
        
        Args:
            model_path: Path to the XGBoost model file
            threshold: Probability threshold for flagging masking (0-1)
        """
        self.threshold = threshold
        self.model_manager = ModelManager(model_path)
        self.feature_extractor = FeatureExtractor()
        
        # Try to load model
        self._use_model = self.model_manager.load()
        
        if not self._use_model:
            logger.warning("Using rule-based fallback for masking detection")
    
    def predict(
        self, 
        metrics: CDRMetrics,
        cli_mismatch: bool = False,
        call_rate: float = 0.0,
        short_call_ratio: float = 0.0
    ) -> PredictionResult:
        """Predict if a call is a masking attack.
        
        Args:
            metrics: CDR metrics for the B-number
            cli_mismatch: Whether CLI differs from P-Asserted-Identity
            call_rate: Calls per second to this B-number
            short_call_ratio: Ratio of short duration calls
            
        Returns:
            PredictionResult with masking flag and probability
        """
        # Extract features
        features = self.feature_extractor.extract(
            metrics=metrics,
            cli_mismatch=cli_mismatch,
            call_rate=call_rate,
            short_call_ratio=short_call_ratio
        )
        
        if self._use_model:
            return self._predict_with_model(features)
        else:
            return self._predict_with_rules(features)
    
    def predict_from_dict(
        self,
        metrics_dict: dict,
        sip_info: dict
    ) -> PredictionResult:
        """Predict masking from dictionaries (for API usage).
        
        Args:
            metrics_dict: Dictionary with ASR, ALOC, overlap_ratio
            sip_info: Dictionary with CLI mismatch, call rate info
            
        Returns:
            PredictionResult with masking flag and probability
        """
        features = self.feature_extractor.extract_from_dict(metrics_dict, sip_info)
        
        if self._use_model:
            return self._predict_with_model(features)
        else:
            return self._predict_with_rules(features)
    
    def _predict_with_model(self, features: MaskingFeatures) -> PredictionResult:
        """Make prediction using XGBoost model."""
        try:
            feature_array = features.to_array()
            probability = float(self.model_manager.predict(feature_array)[0])
            
            return PredictionResult(
                is_masking=probability >= self.threshold,
                probability=probability,
                confidence=self._get_confidence(probability),
                features_used=self._features_to_dict(features),
                method="xgboost"
            )
            
        except Exception as e:
            logger.error(f"Model prediction failed, using rules: {e}")
            return self._predict_with_rules(features)
    
    def _predict_with_rules(self, features: MaskingFeatures) -> PredictionResult:
        """Make prediction using rule-based fallback.
        
        Rules:
        1. >= 5 distinct callers in 5s window = MASKING
        2. Overlap ratio > 0.8 = HIGH probability
        3. CLI mismatch + high volume = SUSPICIOUS
        """
        score = 0.0
        
        # Rule 1: Distinct caller threshold (primary rule)
        if features.distinct_a_count >= self.RULE_BASED_DISTINCT_A_THRESHOLD:
            score += 0.5
        
        # Rule 2: High overlap ratio
        if features.overlap_ratio > 0.8:
            score += 0.3
        elif features.overlap_ratio > 0.5:
            score += 0.15
        
        # Rule 3: CLI mismatch with high volume
        if features.cli_mismatch > 0 and features.distinct_a_count >= 3:
            score += 0.2
        
        # Rule 4: Very high call rate
        if features.call_rate > 2.0:  # > 2 calls per second
            score += 0.1
        
        # Rule 5: Low ASR with high volume (many failed attempts)
        if features.asr < 20.0 and features.distinct_a_count >= 4:
            score += 0.1
        
        probability = min(score, 1.0)
        
        return PredictionResult(
            is_masking=probability >= self.threshold,
            probability=probability,
            confidence=self._get_confidence(probability),
            features_used=self._features_to_dict(features),
            method="rule_based"
        )
    
    def _get_confidence(self, probability: float) -> str:
        """Get confidence level from probability."""
        if probability > 0.9 or probability < 0.1:
            return "HIGH"
        elif probability > 0.7 or probability < 0.3:
            return "MEDIUM"
        return "LOW"
    
    def _features_to_dict(self, features: MaskingFeatures) -> dict:
        """Convert features to dictionary."""
        return {
            "asr": features.asr,
            "aloc": features.aloc,
            "overlap_ratio": features.overlap_ratio,
            "cli_mismatch": features.cli_mismatch > 0,
            "distinct_a_count": features.distinct_a_count,
            "call_rate": features.call_rate,
            "short_call_ratio": features.short_call_ratio,
            "high_volume_flag": features.high_volume_flag > 0
        }
    
    def update_threshold(self, threshold: float) -> None:
        """Update the masking probability threshold.
        
        Args:
            threshold: New threshold (0-1)
        """
        if 0.0 <= threshold <= 1.0:
            self.threshold = threshold
            logger.info(f"Updated masking threshold to {threshold}")
        else:
            raise ValueError("Threshold must be between 0 and 1")
    
    def reload_model(self) -> bool:
        """Reload the XGBoost model.
        
        Returns:
            True if model reloaded successfully
        """
        self._use_model = self.model_manager.load()
        return self._use_model
