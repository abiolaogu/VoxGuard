"""
Anti-Call Masking Fraud Detection using Isolation Forest
=========================================================

This module provides anomaly detection for call masking fraud using
the Isolation Forest algorithm trained on CDR (Call Detail Record) features.

Features used:
- call_frequency: calls per minute from a single CLI
- dispersion_ratio: unique recipients / total calls
- duration_variance: standard deviation of call lengths
"""

import pickle
import logging
from pathlib import Path
from datetime import datetime, timedelta
from typing import Tuple, Optional

import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest
from sklearn.model_selection import train_test_split
from sklearn.metrics import precision_score, recall_score, f1_score, confusion_matrix

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def calculate_fraud_score(cdr_dataframe: pd.DataFrame) -> pd.DataFrame:
    """
    Calculate fraud scores for CDR data using Isolation Forest features.
    
    Features extracted:
    - call_frequency: Number of calls per minute from a single CLI
    - dispersion_ratio: Unique recipients / total calls (0-1)
    - duration_variance: Standard deviation of call lengths
    
    Args:
        cdr_dataframe: DataFrame with columns:
            - cli: Calling Line Identity (A-number)
            - recipient: Called number (B-number)  
            - timestamp: Call timestamp
            - duration: Call duration in seconds
            
    Returns:
        DataFrame with original data plus fraud features and anomaly scores
    """
    if cdr_dataframe.empty:
        return cdr_dataframe
    
    # Ensure timestamp is datetime
    if not pd.api.types.is_datetime64_any_dtype(cdr_dataframe['timestamp']):
        cdr_dataframe['timestamp'] = pd.to_datetime(cdr_dataframe['timestamp'])
    
    # Group by CLI to compute per-caller features
    features = []
    
    for cli, group in cdr_dataframe.groupby('cli'):
        # Sort by timestamp
        group = group.sort_values('timestamp')
        
        # Call frequency: calls per minute
        if len(group) > 1:
            time_span = (group['timestamp'].max() - group['timestamp'].min()).total_seconds() / 60
            call_frequency = len(group) / max(time_span, 1/60)  # Avoid division by zero
        else:
            call_frequency = 1.0
        
        # Dispersion ratio: unique recipients / total calls
        unique_recipients = group['recipient'].nunique()
        dispersion_ratio = unique_recipients / len(group)
        
        # Duration variance: std of call lengths
        if len(group) > 1:
            duration_variance = group['duration'].std()
        else:
            duration_variance = 0.0
        
        features.append({
            'cli': cli,
            'call_frequency': call_frequency,
            'dispersion_ratio': dispersion_ratio,
            'duration_variance': duration_variance,
            'total_calls': len(group),
            'unique_recipients': unique_recipients
        })
    
    # Create features dataframe
    features_df = pd.DataFrame(features)
    
    # Merge back with original data
    result = cdr_dataframe.merge(features_df, on='cli', how='left')
    
    return result


def generate_synthetic_dataset(n_samples: int = 10000, fraud_ratio: float = 0.05) -> pd.DataFrame:
    """
    Generate synthetic CDR dataset for training.
    
    Args:
        n_samples: Total number of call records
        fraud_ratio: Proportion of fraudulent calls
        
    Returns:
        DataFrame with synthetic CDR data and labels
    """
    np.random.seed(42)
    
    n_fraud = int(n_samples * fraud_ratio)
    n_normal = n_samples - n_fraud
    
    # Generate normal calls
    normal_clis = [f"+1{np.random.randint(200, 999)}{np.random.randint(1000000, 9999999)}" 
                   for _ in range(n_normal // 5)]  # ~5 calls per CLI
    normal_data = []
    
    base_time = datetime(2024, 1, 1, 8, 0, 0)
    
    for i in range(n_normal):
        cli = np.random.choice(normal_clis)
        recipient = f"+1{np.random.randint(200, 999)}{np.random.randint(1000000, 9999999)}"
        timestamp = base_time + timedelta(
            days=np.random.randint(0, 30),
            hours=np.random.randint(0, 24),
            minutes=np.random.randint(0, 60)
        )
        # Normal calls: 30-600 seconds, low variance
        duration = max(10, np.random.normal(180, 60))
        
        normal_data.append({
            'cli': cli,
            'recipient': recipient,
            'timestamp': timestamp,
            'duration': duration,
            'is_fraud': 0
        })
    
    # Generate fraudulent calls (masking patterns)
    fraud_clis = [f"+1{np.random.randint(200, 999)}{np.random.randint(1000000, 9999999)}" 
                  for _ in range(n_fraud // 50)]  # Many calls per CLI
    fraud_data = []
    
    for _ in range(n_fraud):
        cli = np.random.choice(fraud_clis)
        # Fraudsters call many different recipients rapidly
        recipient = f"+1{np.random.randint(200, 999)}{np.random.randint(1000000, 9999999)}"
        # Burst of calls within short time
        timestamp = base_time + timedelta(
            days=np.random.randint(0, 5),  # Concentrated in fewer days
            minutes=np.random.randint(0, 60)  # Within same hour
        )
        # Fraud calls: very short, high variance
        duration = max(1, np.random.exponential(15))
        
        fraud_data.append({
            'cli': cli,
            'recipient': recipient,
            'timestamp': timestamp,
            'duration': duration,
            'is_fraud': 1
        })
    
    # Combine and shuffle
    df = pd.concat([pd.DataFrame(normal_data), pd.DataFrame(fraud_data)], ignore_index=True)
    df = df.sample(frac=1, random_state=42).reset_index(drop=True)
    
    logger.info(f"Generated {n_samples} synthetic calls ({n_fraud} fraud, {n_normal} normal)")
    return df


def train_isolation_forest(
    cdr_df: pd.DataFrame,
    contamination: float = 0.05,
    n_estimators: int = 100,
    random_state: int = 42
) -> Tuple[IsolationForest, dict]:
    """
    Train Isolation Forest model on CDR features.
    
    Args:
        cdr_df: DataFrame with CDR data and fraud features
        contamination: Expected proportion of outliers
        n_estimators: Number of trees in the forest
        random_state: Random seed for reproducibility
        
    Returns:
        Tuple of (trained model, metrics dictionary)
    """
    # Extract features
    feature_cols = ['call_frequency', 'dispersion_ratio', 'duration_variance']
    
    # Aggregate to CLI level (one row per caller)
    cli_features = cdr_df.groupby('cli').agg({
        'call_frequency': 'first',
        'dispersion_ratio': 'first', 
        'duration_variance': 'first',
        'is_fraud': 'max'  # If any call is fraud, the CLI is fraud
    }).reset_index()
    
    X = cli_features[feature_cols].values
    y_true = cli_features['is_fraud'].values
    
    # Handle NaN values
    X = np.nan_to_num(X, nan=0.0)
    
    # Train Isolation Forest
    model = IsolationForest(
        contamination=contamination,
        n_estimators=n_estimators,
        random_state=random_state,
        n_jobs=-1
    )
    
    logger.info("Training Isolation Forest model...")
    y_pred_raw = model.fit_predict(X)
    
    # Convert predictions: -1 (anomaly) -> 1 (fraud), 1 (normal) -> 0
    y_pred = (y_pred_raw == -1).astype(int)
    
    # Calculate metrics
    precision = precision_score(y_true, y_pred, zero_division=0)
    recall = recall_score(y_true, y_pred, zero_division=0)
    f1 = f1_score(y_true, y_pred, zero_division=0)
    cm = confusion_matrix(y_true, y_pred)
    
    metrics = {
        'precision': precision,
        'recall': recall,
        'f1_score': f1,
        'confusion_matrix': cm,
        'total_samples': len(y_true),
        'fraud_samples': int(y_true.sum()),
        'normal_samples': int(len(y_true) - y_true.sum()),
        'predicted_fraud': int(y_pred.sum()),
        'true_positives': int(cm[1, 1]) if cm.shape[0] > 1 else 0,
        'false_positives': int(cm[0, 1]) if cm.shape[0] > 1 else 0,
        'true_negatives': int(cm[0, 0]),
        'false_negatives': int(cm[1, 0]) if cm.shape[0] > 1 else 0
    }
    
    logger.info(f"Model trained - Precision: {precision:.4f}, Recall: {recall:.4f}, F1: {f1:.4f}")
    
    return model, metrics


def save_model(model: IsolationForest, path: str = "fraud_model.pkl") -> None:
    """Save trained model to disk."""
    with open(path, 'wb') as f:
        pickle.dump(model, f)
    logger.info(f"Model saved to {path}")


def load_model(path: str = "fraud_model.pkl") -> IsolationForest:
    """Load trained model from disk."""
    with open(path, 'rb') as f:
        model = pickle.load(f)
    logger.info(f"Model loaded from {path}")
    return model


def predict_fraud(model: IsolationForest, cdr_df: pd.DataFrame) -> pd.DataFrame:
    """
    Predict fraud on new CDR data.
    
    Args:
        model: Trained Isolation Forest model
        cdr_df: DataFrame with CDR data
        
    Returns:
        DataFrame with fraud predictions and scores
    """
    # Calculate features
    featured_df = calculate_fraud_score(cdr_df)
    
    feature_cols = ['call_frequency', 'dispersion_ratio', 'duration_variance']
    
    # Aggregate to CLI level
    cli_features = featured_df.groupby('cli').agg({
        'call_frequency': 'first',
        'dispersion_ratio': 'first',
        'duration_variance': 'first'
    }).reset_index()
    
    X = cli_features[feature_cols].values
    X = np.nan_to_num(X, nan=0.0)
    
    # Predict
    predictions = model.predict(X)
    scores = model.score_samples(X)
    
    # Convert to fraud labels
    cli_features['is_fraud_predicted'] = (predictions == -1).astype(int)
    cli_features['anomaly_score'] = -scores  # Higher = more anomalous
    
    # Merge back to original data
    result = featured_df.merge(
        cli_features[['cli', 'is_fraud_predicted', 'anomaly_score']], 
        on='cli', 
        how='left'
    )
    
    return result


def generate_metrics_report(metrics: dict) -> str:
    """Generate a formatted metrics report."""
    report = []
    report.append("=" * 60)
    report.append("ISOLATION FOREST FRAUD DETECTION - MODEL METRICS")
    report.append("=" * 60)
    report.append("")
    report.append("## Dataset Summary")
    report.append(f"- Total Samples (CLIs): {metrics['total_samples']}")
    report.append(f"- Fraud Samples: {metrics['fraud_samples']}")
    report.append(f"- Normal Samples: {metrics['normal_samples']}")
    report.append("")
    report.append("## Model Performance")
    report.append(f"- **Precision**: {metrics['precision']:.4f}")
    report.append(f"- **Recall**: {metrics['recall']:.4f}")
    report.append(f"- **F1 Score**: {metrics['f1_score']:.4f}")
    report.append("")
    report.append("## Confusion Matrix")
    report.append(f"                 Predicted Normal  Predicted Fraud")
    report.append(f"  Actual Normal       {metrics['true_negatives']:5d}            {metrics['false_positives']:5d}")
    report.append(f"  Actual Fraud        {metrics['false_negatives']:5d}            {metrics['true_positives']:5d}")
    report.append("")
    report.append("## Interpretation")
    report.append(f"- True Positives (correctly detected fraud): {metrics['true_positives']}")
    report.append(f"- False Positives (normal flagged as fraud): {metrics['false_positives']}")
    report.append(f"- True Negatives (correctly identified normal): {metrics['true_negatives']}")
    report.append(f"- False Negatives (missed fraud): {metrics['false_negatives']}")
    report.append("")
    report.append("=" * 60)
    
    return "\n".join(report)


if __name__ == "__main__":
    # Step 1: Generate synthetic dataset
    print("Step 1: Generating synthetic CDR dataset (10,000 calls)...")
    cdr_data = generate_synthetic_dataset(n_samples=10000, fraud_ratio=0.05)
    
    # Step 2: Calculate fraud features
    print("Step 2: Calculating fraud features...")
    featured_data = calculate_fraud_score(cdr_data)
    
    # Step 3: Train Isolation Forest model
    print("Step 3: Training Isolation Forest model...")
    model, metrics = train_isolation_forest(featured_data, contamination=0.05)
    
    # Step 4: Save the model
    print("Step 4: Saving model to fraud_model.pkl...")
    save_model(model, "fraud_model.pkl")
    
    # Step 5: Generate and display metrics report
    print("\nStep 5: Model Metrics Summary")
    report = generate_metrics_report(metrics)
    print(report)
    
    # Save metrics to file
    with open("model_metrics.txt", "w") as f:
        f.write(report)
    print("\nMetrics saved to model_metrics.txt")
    
    # Example prediction on new data
    print("\n" + "=" * 60)
    print("Example: Predict on sample data")
    print("=" * 60)
    
    # Create sample test data
    sample_data = pd.DataFrame([
        {'cli': '+12025551234', 'recipient': '+19876543210', 
         'timestamp': datetime.now(), 'duration': 120},
        {'cli': '+12025551234', 'recipient': '+19876543211', 
         'timestamp': datetime.now() + timedelta(seconds=30), 'duration': 5},
        {'cli': '+12025551234', 'recipient': '+19876543212', 
         'timestamp': datetime.now() + timedelta(seconds=45), 'duration': 3},
    ])
    
    result = predict_fraud(model, sample_data)
    print(f"Sample CLI fraud prediction: {result['is_fraud_predicted'].iloc[0]}")
    print(f"Anomaly score: {result['anomaly_score'].iloc[0]:.4f}")
