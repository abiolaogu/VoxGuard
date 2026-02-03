"""Model evaluation and metrics."""
import logging
from dataclasses import dataclass
from typing import Dict, Any

import numpy as np
from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    roc_auc_score,
    confusion_matrix,
    classification_report,
)

logger = logging.getLogger(__name__)


@dataclass
class EvaluationMetrics:
    """Evaluation metrics for a model."""

    # Core metrics
    auc_score: float
    accuracy: float
    precision: float
    recall: float
    f1_score: float

    # Confusion matrix
    true_positives: int
    true_negatives: int
    false_positives: int
    false_negatives: int

    # Additional metrics
    specificity: float
    false_positive_rate: float
    false_negative_rate: float

    # Sample counts
    total_samples: int
    positive_samples: int
    negative_samples: int

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            "auc_score": self.auc_score,
            "accuracy": self.accuracy,
            "precision": self.precision,
            "recall": self.recall,
            "f1_score": self.f1_score,
            "true_positives": self.true_positives,
            "true_negatives": self.true_negatives,
            "false_positives": self.false_positives,
            "false_negatives": self.false_negatives,
            "specificity": self.specificity,
            "false_positive_rate": self.false_positive_rate,
            "false_negative_rate": self.false_negative_rate,
            "total_samples": self.total_samples,
            "positive_samples": self.positive_samples,
            "negative_samples": self.negative_samples,
        }

    def passes_thresholds(
        self, min_auc: float, min_precision: float, min_recall: float
    ) -> bool:
        """Check if metrics pass minimum thresholds.

        Args:
            min_auc: Minimum AUC score
            min_precision: Minimum precision
            min_recall: Minimum recall

        Returns:
            True if all thresholds are met
        """
        return (
            self.auc_score >= min_auc
            and self.precision >= min_precision
            and self.recall >= min_recall
        )

    def is_better_than(
        self, other: "EvaluationMetrics", min_improvement: float = 0.02
    ) -> bool:
        """Check if this model is significantly better than another.

        Args:
            other: Other model's metrics
            min_improvement: Minimum improvement threshold (e.g., 0.02 = 2%)

        Returns:
            True if this model is better
        """
        auc_improvement = self.auc_score - other.auc_score
        return auc_improvement >= min_improvement


class ModelEvaluator:
    """Evaluate model performance."""

    def __init__(self, threshold: float = 0.7):
        """Initialize the evaluator.

        Args:
            threshold: Classification threshold for probabilities
        """
        self.threshold = threshold

    def evaluate(
        self, y_true: np.ndarray, y_pred_proba: np.ndarray
    ) -> EvaluationMetrics:
        """Evaluate model predictions.

        Args:
            y_true: True labels (0 or 1)
            y_pred_proba: Predicted probabilities (0-1)

        Returns:
            EvaluationMetrics object
        """
        # Convert probabilities to binary predictions
        y_pred = (y_pred_proba >= self.threshold).astype(int)

        # Core metrics
        auc = roc_auc_score(y_true, y_pred_proba)
        accuracy = accuracy_score(y_true, y_pred)
        precision = precision_score(y_true, y_pred, zero_division=0)
        recall = recall_score(y_true, y_pred, zero_division=0)
        f1 = f1_score(y_true, y_pred, zero_division=0)

        # Confusion matrix
        tn, fp, fn, tp = confusion_matrix(y_true, y_pred).ravel()

        # Additional metrics
        specificity = tn / (tn + fp) if (tn + fp) > 0 else 0.0
        fpr = fp / (fp + tn) if (fp + tn) > 0 else 0.0
        fnr = fn / (fn + tp) if (fn + tp) > 0 else 0.0

        # Sample counts
        total = len(y_true)
        positive = int(np.sum(y_true))
        negative = total - positive

        metrics = EvaluationMetrics(
            auc_score=float(auc),
            accuracy=float(accuracy),
            precision=float(precision),
            recall=float(recall),
            f1_score=float(f1),
            true_positives=int(tp),
            true_negatives=int(tn),
            false_positives=int(fp),
            false_negatives=int(fn),
            specificity=float(specificity),
            false_positive_rate=float(fpr),
            false_negative_rate=float(fnr),
            total_samples=total,
            positive_samples=positive,
            negative_samples=negative,
        )

        logger.info(self._format_metrics(metrics))

        return metrics

    def _format_metrics(self, metrics: EvaluationMetrics) -> str:
        """Format metrics for logging.

        Args:
            metrics: Evaluation metrics

        Returns:
            Formatted string
        """
        return (
            f"Evaluation Results:\n"
            f"  AUC: {metrics.auc_score:.4f}\n"
            f"  Accuracy: {metrics.accuracy:.4f}\n"
            f"  Precision: {metrics.precision:.4f}\n"
            f"  Recall: {metrics.recall:.4f}\n"
            f"  F1 Score: {metrics.f1_score:.4f}\n"
            f"  Specificity: {metrics.specificity:.4f}\n"
            f"  Confusion Matrix:\n"
            f"    TP={metrics.true_positives}, TN={metrics.true_negatives}\n"
            f"    FP={metrics.false_positives}, FN={metrics.false_negatives}\n"
            f"  Samples: {metrics.total_samples} "
            f"(Pos={metrics.positive_samples}, Neg={metrics.negative_samples})"
        )

    def generate_report(
        self, y_true: np.ndarray, y_pred_proba: np.ndarray
    ) -> str:
        """Generate detailed classification report.

        Args:
            y_true: True labels
            y_pred_proba: Predicted probabilities

        Returns:
            Classification report string
        """
        y_pred = (y_pred_proba >= self.threshold).astype(int)
        return classification_report(
            y_true, y_pred, target_names=["Not Fraud", "Fraud"], zero_division=0
        )

    def evaluate_threshold_sensitivity(
        self, y_true: np.ndarray, y_pred_proba: np.ndarray, thresholds: list[float]
    ) -> Dict[float, EvaluationMetrics]:
        """Evaluate model at different thresholds.

        Args:
            y_true: True labels
            y_pred_proba: Predicted probabilities
            thresholds: List of thresholds to evaluate

        Returns:
            Dictionary mapping thresholds to metrics
        """
        results = {}

        for threshold in thresholds:
            original_threshold = self.threshold
            self.threshold = threshold
            metrics = self.evaluate(y_true, y_pred_proba)
            results[threshold] = metrics
            self.threshold = original_threshold

        return results

    def compare_models(
        self,
        y_true: np.ndarray,
        model_a_proba: np.ndarray,
        model_b_proba: np.ndarray,
    ) -> Dict[str, Any]:
        """Compare two models side-by-side.

        Args:
            y_true: True labels
            model_a_proba: Model A predictions
            model_b_proba: Model B predictions

        Returns:
            Comparison dictionary
        """
        metrics_a = self.evaluate(y_true, model_a_proba)
        metrics_b = self.evaluate(y_true, model_b_proba)

        return {
            "model_a": metrics_a.to_dict(),
            "model_b": metrics_b.to_dict(),
            "delta": {
                "auc": metrics_b.auc_score - metrics_a.auc_score,
                "accuracy": metrics_b.accuracy - metrics_a.accuracy,
                "precision": metrics_b.precision - metrics_a.precision,
                "recall": metrics_b.recall - metrics_a.recall,
                "f1": metrics_b.f1_score - metrics_a.f1_score,
            },
            "winner": "model_b" if metrics_b.auc_score > metrics_a.auc_score else "model_a",
            "improvement_percentage": (
                (metrics_b.auc_score - metrics_a.auc_score) / metrics_a.auc_score * 100
            ),
        }
