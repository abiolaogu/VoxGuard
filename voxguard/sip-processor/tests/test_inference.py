"""Tests for inference engine."""
import pytest
from unittest.mock import MagicMock, patch
from datetime import datetime

from app.inference.engine import MaskingInferenceEngine, PredictionResult
from app.inference.features import FeatureExtractor, MaskingFeatures
from app.cdr.models import CDRMetrics


class TestFeatureExtractor:
    """Tests for feature extraction."""
    
    def test_extract_features_from_metrics(self):
        """Test feature extraction from CDR metrics."""
        metrics = CDRMetrics(
            b_number="+19876543210",
            asr=75.0,
            aloc=120.0,
            overlap_ratio=0.3,
            concurrent_callers=3
        )
        
        extractor = FeatureExtractor()
        features = extractor.extract(
            metrics=metrics,
            cli_mismatch=True,
            call_rate=1.5,
            short_call_ratio=0.2
        )
        
        assert features.asr == 75.0
        assert features.aloc == 120.0
        assert features.overlap_ratio == 0.3
        assert features.cli_mismatch == 1.0
        assert features.distinct_a_count == 3
        assert features.call_rate == 1.5
    
    def test_feature_array_shape(self):
        """Test that feature array has correct shape."""
        features = MaskingFeatures(
            asr=50.0,
            aloc=60.0,
            overlap_ratio=0.5,
            cli_mismatch=0.0,
            distinct_a_count=5,
            call_rate=1.0,
            short_call_ratio=0.1,
            high_volume_flag=0.0
        )
        
        arr = features.to_array()
        assert arr.shape == (1, 8)


class TestMaskingInferenceEngine:
    """Tests for masking inference engine."""
    
    def test_rule_based_detection_high_distinct_callers(self):
        """Test rule-based detection triggers on high distinct callers."""
        engine = MaskingInferenceEngine(threshold=0.5)
        engine._use_model = False  # Force rule-based
        
        metrics = CDRMetrics(
            b_number="+19876543210",
            asr=50.0,
            aloc=30.0,
            overlap_ratio=0.9,
            concurrent_callers=6  # >= 5 threshold
        )
        
        result = engine.predict(metrics)
        
        assert result.is_masking
        assert result.probability >= 0.5
        assert result.method == "rule_based"
    
    def test_rule_based_no_masking_low_volume(self):
        """Test rule-based detection does not trigger on low volume."""
        engine = MaskingInferenceEngine(threshold=0.7)
        engine._use_model = False
        
        metrics = CDRMetrics(
            b_number="+19876543210",
            asr=80.0,
            aloc=120.0,
            overlap_ratio=0.1,
            concurrent_callers=2
        )
        
        result = engine.predict(metrics)
        
        assert not result.is_masking
        assert result.probability < 0.7
    
    def test_cli_mismatch_increases_score(self):
        """Test that CLI mismatch increases the masking score."""
        engine = MaskingInferenceEngine(threshold=0.5)
        engine._use_model = False
        
        metrics = CDRMetrics(
            b_number="+19876543210",
            asr=50.0,
            aloc=30.0,
            overlap_ratio=0.5,
            concurrent_callers=4
        )
        
        result_no_mismatch = engine.predict(metrics, cli_mismatch=False)
        result_with_mismatch = engine.predict(metrics, cli_mismatch=True)
        
        assert result_with_mismatch.probability > result_no_mismatch.probability
    
    def test_prediction_result_risk_levels(self):
        """Test risk level classification."""
        result_critical = PredictionResult(
            is_masking=True,
            probability=0.95,
            confidence="HIGH",
            features_used={},
            method="rule_based"
        )
        assert result_critical.risk_level == "CRITICAL"
        
        result_high = PredictionResult(
            is_masking=True,
            probability=0.75,
            confidence="MEDIUM",
            features_used={},
            method="rule_based"
        )
        assert result_high.risk_level == "HIGH"
        
        result_low = PredictionResult(
            is_masking=False,
            probability=0.35,
            confidence="LOW",
            features_used={},
            method="rule_based"
        )
        assert result_low.risk_level == "LOW"
    
    def test_threshold_update(self):
        """Test updating detection threshold."""
        engine = MaskingInferenceEngine(threshold=0.5)
        
        engine.update_threshold(0.8)
        assert engine.threshold == 0.8
        
        with pytest.raises(ValueError):
            engine.update_threshold(1.5)
