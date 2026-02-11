"""Model training orchestrator."""
import logging
from datetime import datetime
from pathlib import Path
from typing import Tuple, Dict, Any, Optional

import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split

logger = logging.getLogger(__name__)

# Try to import XGBoost
try:
    import xgboost as xgb

    XGBOOST_AVAILABLE = True
except ImportError:
    XGBOOST_AVAILABLE = False
    xgb = None


class ModelTrainer:
    """Train XGBoost models for fraud detection."""

    FEATURE_NAMES = [
        "asr",
        "aloc",
        "overlap_ratio",
        "cli_mismatch",
        "distinct_a_count",
        "call_rate",
        "short_call_ratio",
        "high_volume_flag",
    ]

    def __init__(
        self,
        max_depth: int = 6,
        learning_rate: float = 0.1,
        n_estimators: int = 100,
        subsample: float = 0.8,
        colsample_bytree: float = 0.8,
        random_seed: int = 42,
    ):
        """Initialize the trainer.

        Args:
            max_depth: Maximum tree depth
            learning_rate: Learning rate (eta)
            n_estimators: Number of boosting rounds
            subsample: Row sampling ratio
            colsample_bytree: Column sampling ratio
            random_seed: Random seed for reproducibility
        """
        if not XGBOOST_AVAILABLE:
            raise RuntimeError("XGBoost is not installed")

        self.params = {
            "objective": "binary:logistic",
            "eval_metric": "auc",
            "max_depth": max_depth,
            "eta": learning_rate,
            "subsample": subsample,
            "colsample_bytree": colsample_bytree,
            "seed": random_seed,
            "verbosity": 1,
        }

        self.n_estimators = n_estimators
        self.random_seed = random_seed
        self.model: Optional[xgb.Booster] = None

    def prepare_data(
        self, df: pd.DataFrame, test_size: float = 0.2, validation_size: float = 0.1
    ) -> Tuple[xgb.DMatrix, xgb.DMatrix, xgb.DMatrix]:
        """Prepare train/val/test datasets.

        Args:
            df: DataFrame with features and 'label' column
            test_size: Test set ratio
            validation_size: Validation set ratio (from remaining after test)

        Returns:
            Tuple of (train_dmatrix, val_dmatrix, test_dmatrix)
        """
        # Validate required columns
        required_cols = self.FEATURE_NAMES + ["label"]
        missing_cols = set(required_cols) - set(df.columns)
        if missing_cols:
            raise ValueError(f"Missing required columns: {missing_cols}")

        # Extract features and labels
        X = df[self.FEATURE_NAMES].values
        y = df["label"].values

        # Train/test split
        X_temp, X_test, y_temp, y_test = train_test_split(
            X, y, test_size=test_size, random_state=self.random_seed, stratify=y
        )

        # Train/validation split
        val_size_adjusted = validation_size / (1 - test_size)
        X_train, X_val, y_train, y_val = train_test_split(
            X_temp,
            y_temp,
            test_size=val_size_adjusted,
            random_state=self.random_seed,
            stratify=y_temp,
        )

        logger.info(
            f"Data split: Train={len(X_train)}, Val={len(X_val)}, Test={len(X_test)}"
        )

        # Create DMatrix objects
        dtrain = xgb.DMatrix(X_train, label=y_train, feature_names=self.FEATURE_NAMES)
        dval = xgb.DMatrix(X_val, label=y_val, feature_names=self.FEATURE_NAMES)
        dtest = xgb.DMatrix(X_test, label=y_test, feature_names=self.FEATURE_NAMES)

        return dtrain, dval, dtest

    def train(
        self,
        dtrain: xgb.DMatrix,
        dval: xgb.DMatrix,
        early_stopping_rounds: int = 20,
    ) -> Dict[str, Any]:
        """Train the XGBoost model.

        Args:
            dtrain: Training dataset
            dval: Validation dataset
            early_stopping_rounds: Stop if no improvement for N rounds

        Returns:
            Training history dictionary
        """
        evals = [(dtrain, "train"), (dval, "val")]
        evals_result = {}

        self.model = xgb.train(
            params=self.params,
            dtrain=dtrain,
            num_boost_round=self.n_estimators,
            evals=evals,
            evals_result=evals_result,
            early_stopping_rounds=early_stopping_rounds,
            verbose_eval=10,
        )

        logger.info(f"Training completed. Best iteration: {self.model.best_iteration}")

        return {
            "best_iteration": self.model.best_iteration,
            "best_score": self.model.best_score,
            "train_auc": evals_result["train"]["auc"][self.model.best_iteration],
            "val_auc": evals_result["val"]["auc"][self.model.best_iteration],
        }

    def get_feature_importance(self) -> Dict[str, float]:
        """Get feature importance scores.

        Returns:
            Dictionary of feature names to importance scores
        """
        if not self.model:
            raise RuntimeError("Model not trained")

        importance = self.model.get_score(importance_type="gain")

        # Normalize to sum to 1.0
        total = sum(importance.values())
        return {k: v / total for k, v in importance.items()}

    def save_model(self, output_path: str) -> None:
        """Save the trained model.

        Args:
            output_path: Path to save the model
        """
        if not self.model:
            raise RuntimeError("Model not trained")

        Path(output_path).parent.mkdir(parents=True, exist_ok=True)
        self.model.save_model(output_path)
        logger.info(f"Model saved to {output_path}")

    def load_model(self, model_path: str) -> None:
        """Load a trained model.

        Args:
            model_path: Path to the model file
        """
        self.model = xgb.Booster()
        self.model.load_model(model_path)
        logger.info(f"Model loaded from {model_path}")

    def predict(self, X: np.ndarray) -> np.ndarray:
        """Make predictions.

        Args:
            X: Feature array of shape (n_samples, n_features)

        Returns:
            Prediction probabilities
        """
        if not self.model:
            raise RuntimeError("Model not trained or loaded")

        dmatrix = xgb.DMatrix(X, feature_names=self.FEATURE_NAMES)
        return self.model.predict(dmatrix)

    def predict_from_dmatrix(self, dmatrix: xgb.DMatrix) -> np.ndarray:
        """Make predictions from DMatrix.

        Args:
            dmatrix: XGBoost DMatrix

        Returns:
            Prediction probabilities
        """
        if not self.model:
            raise RuntimeError("Model not trained or loaded")

        return self.model.predict(dmatrix)

    @classmethod
    def create_version_string(cls) -> str:
        """Create a version string for the model.

        Format: YYYY.MM.DD.HHMMSS (e.g., "2026.02.03.140530")

        Returns:
            Version string
        """
        now = datetime.utcnow()
        return now.strftime("%Y.%m.%d.%H%M%S")

    @classmethod
    def create_model_id(cls, version: str) -> str:
        """Create a model ID.

        Args:
            version: Version string

        Returns:
            Model ID (e.g., "xgboost_v2026.02.03.140530")
        """
        return f"xgboost_v{version}"
