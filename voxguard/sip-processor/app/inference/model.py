"""XGBoost model management."""
import logging
import os
from pathlib import Path
from typing import Optional

import numpy as np

logger = logging.getLogger(__name__)

# Try to import xgboost
try:
    import xgboost as xgb
    XGBOOST_AVAILABLE = True
except ImportError:
    XGBOOST_AVAILABLE = False
    xgb = None


class ModelManager:
    """Manage XGBoost model loading and lifecycle."""
    
    def __init__(self, model_path: Optional[str] = None):
        """Initialize the model manager.
        
        Args:
            model_path: Path to the XGBoost model file
        """
        self.model_path = model_path or "models/xgboost_masking.json"
        self._model: Optional[xgb.Booster] = None
        self._is_loaded = False
    
    @property
    def is_available(self) -> bool:
        """Check if XGBoost is available."""
        return XGBOOST_AVAILABLE
    
    @property
    def is_loaded(self) -> bool:
        """Check if model is loaded."""
        return self._is_loaded and self._model is not None
    
    def load(self) -> bool:
        """Load the XGBoost model.
        
        Returns:
            True if model loaded successfully
        """
        if not XGBOOST_AVAILABLE:
            logger.warning("XGBoost not available - using fallback rules")
            return False
        
        try:
            model_file = Path(self.model_path)
            
            if not model_file.exists():
                logger.warning(f"Model file not found: {self.model_path}")
                return False
            
            self._model = xgb.Booster()
            self._model.load_model(str(model_file))
            self._is_loaded = True
            
            logger.info(f"Loaded XGBoost model from {self.model_path}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to load model: {e}")
            self._model = None
            self._is_loaded = False
            return False
    
    def predict(self, features: np.ndarray) -> np.ndarray:
        """Make prediction with the model.
        
        Args:
            features: Feature array of shape (n_samples, n_features)
            
        Returns:
            Prediction probabilities
        """
        if not self.is_loaded:
            raise RuntimeError("Model not loaded")
        
        dmatrix = xgb.DMatrix(features)
        return self._model.predict(dmatrix)
    
    def unload(self) -> None:
        """Unload the model to free memory."""
        self._model = None
        self._is_loaded = False
        logger.info("Model unloaded")
    
    @staticmethod
    def create_dummy_model(output_path: str = "models/xgboost_masking.json") -> None:
        """Create a dummy model for testing.
        
        This creates a simple XGBoost model that can be used for testing
        when no trained model is available.
        
        Args:
            output_path: Path to save the model
        """
        if not XGBOOST_AVAILABLE:
            logger.error("XGBoost not available")
            return
        
        # Create synthetic training data
        np.random.seed(42)
        n_samples = 1000
        
        # Features: asr, aloc, overlap_ratio, cli_mismatch, distinct_a, call_rate, short_ratio, high_vol
        X = np.random.rand(n_samples, 8)
        
        # Labels: high overlap ratio + high distinct_a_count = masking
        y = ((X[:, 2] > 0.5) & (X[:, 4] > 0.5)).astype(int)
        
        # Train a simple model
        dtrain = xgb.DMatrix(X, label=y)
        params = {
            "objective": "binary:logistic",
            "max_depth": 3,
            "eta": 0.1,
            "eval_metric": "auc"
        }
        
        model = xgb.train(params, dtrain, num_boost_round=50)
        
        # Save model
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        model.save_model(output_path)
        logger.info(f"Created dummy model at {output_path}")
