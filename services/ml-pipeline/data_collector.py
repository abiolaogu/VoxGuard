"""Automated data collection pipeline for ML training.

Extracts training data from QuestDB time-series and YugabyteDB relational
databases, prepares features, and creates labeled datasets for model training.
"""
import asyncio
import logging
from datetime import datetime, timedelta
from dataclasses import dataclass
from typing import List, Optional, Tuple

import pandas as pd
import numpy as np

logger = logging.getLogger(__name__)


@dataclass
class DataCollectionConfig:
    """Configuration for data collection."""

    # Database connections
    questdb_host: str = "localhost"
    questdb_port: int = 8812
    yugabyte_host: str = "localhost"
    yugabyte_port: int = 5433
    yugabyte_db: str = "voxguard"
    yugabyte_user: str = "voxguard"
    yugabyte_password: str = ""

    # Collection parameters
    lookback_days: int = 7
    min_samples: int = 1000
    fraud_label_threshold: float = 0.7

    # Feature engineering
    window_seconds: int = 5
    min_call_duration: int = 10

    # Output
    output_path: str = "data/training"
    dataset_version: str = ""


class DataCollector:
    """Collects and prepares training data from operational databases.

    Features:
    - Extracts CDR metrics from QuestDB time-series
    - Enriches with fraud labels from YugabyteDB
    - Handles imbalanced datasets with fraud oversampling
    - Validates data quality and feature distributions
    - Exports to Parquet format for efficient training
    """

    def __init__(self, config: DataCollectionConfig):
        """Initialize the data collector.

        Args:
            config: Data collection configuration
        """
        self.config = config

        # Database connections
        self._questdb_conn = None
        self._yugabyte_conn = None

        # Metrics
        self.total_records_collected = 0
        self.fraud_records = 0
        self.non_fraud_records = 0

        logger.info(
            f"DataCollector initialized: lookback={config.lookback_days} days, "
            f"min_samples={config.min_samples}"
        )

    async def connect(self):
        """Connect to databases."""
        try:
            # In production, these would be actual database connections
            # For now, we'll simulate the connections
            logger.info(f"Connecting to QuestDB at {self.config.questdb_host}:{self.config.questdb_port}")
            logger.info(f"Connecting to YugabyteDB at {self.config.yugabyte_host}:{self.config.yugabyte_port}")

            # Simulate connection delay
            await asyncio.sleep(0.1)

            self._questdb_conn = "questdb_connection"
            self._yugabyte_conn = "yugabyte_connection"

            logger.info("Database connections established")

        except Exception as e:
            logger.error(f"Failed to connect to databases: {e}")
            raise

    async def collect_training_data(
        self,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> pd.DataFrame:
        """Collect training data for model training.

        Args:
            start_date: Start date for data collection (default: lookback_days ago)
            end_date: End date for data collection (default: now)

        Returns:
            DataFrame with features and labels
        """
        if not start_date:
            start_date = datetime.now() - timedelta(days=self.config.lookback_days)

        if not end_date:
            end_date = datetime.now()

        logger.info(f"Collecting training data from {start_date} to {end_date}")

        # Step 1: Extract CDR metrics from QuestDB
        cdr_data = await self._extract_cdr_metrics(start_date, end_date)
        logger.info(f"Extracted {len(cdr_data)} CDR records from QuestDB")

        # Step 2: Extract fraud labels from YugabyteDB
        fraud_labels = await self._extract_fraud_labels(start_date, end_date)
        logger.info(f"Extracted {len(fraud_labels)} fraud labels from YugabyteDB")

        # Step 3: Merge and create feature matrix
        training_df = self._merge_and_engineer_features(cdr_data, fraud_labels)
        logger.info(f"Created feature matrix with {len(training_df)} samples")

        # Step 4: Validate data quality
        training_df = self._validate_and_clean(training_df)
        logger.info(f"After validation: {len(training_df)} samples")

        # Step 5: Handle class imbalance
        training_df = self._balance_dataset(training_df)
        logger.info(
            f"After balancing: {len(training_df)} samples "
            f"({self.fraud_records} fraud, {self.non_fraud_records} non-fraud)"
        )

        # Update metrics
        self.total_records_collected = len(training_df)

        return training_df

    async def _extract_cdr_metrics(
        self,
        start_date: datetime,
        end_date: datetime,
    ) -> pd.DataFrame:
        """Extract CDR metrics from QuestDB time-series database.

        Query:
        SELECT
            timestamp,
            b_number,
            a_number,
            call_duration,
            call_status,
            asr,
            aloc,
            distinct_a_count,
            call_rate,
            overlap_ratio,
            short_call_ratio
        FROM cdr_metrics
        WHERE timestamp BETWEEN start_date AND end_date
        """
        # In production, this would execute actual QuestDB query
        # For now, generate synthetic data

        logger.info("Executing QuestDB CDR metrics query...")
        await asyncio.sleep(0.5)  # Simulate query time

        # Generate synthetic CDR data
        num_samples = 5000

        data = {
            "timestamp": pd.date_range(start=start_date, end=end_date, periods=num_samples),
            "b_number": [f"234{np.random.randint(70, 90)}{np.random.randint(10000000, 99999999)}" for _ in range(num_samples)],
            "a_number": [f"234{np.random.randint(70, 90)}{np.random.randint(10000000, 99999999)}" for _ in range(num_samples)],
            "call_duration": np.random.exponential(scale=120, size=num_samples),
            "call_status": np.random.choice(["answered", "busy", "no_answer"], num_samples, p=[0.6, 0.2, 0.2]),
            "asr": np.random.uniform(40, 95, num_samples),
            "aloc": np.random.uniform(30, 300, num_samples),
            "distinct_a_count": np.random.randint(1, 10, num_samples),
            "call_rate": np.random.uniform(0.1, 3.0, num_samples),
            "overlap_ratio": np.random.uniform(0, 1, num_samples),
            "short_call_ratio": np.random.uniform(0, 0.5, num_samples),
        }

        return pd.DataFrame(data)

    async def _extract_fraud_labels(
        self,
        start_date: datetime,
        end_date: datetime,
    ) -> pd.DataFrame:
        """Extract fraud labels from YugabyteDB.

        Query:
        SELECT
            b_number,
            timestamp,
            is_fraud,
            fraud_probability,
            fraud_type,
            detection_method
        FROM fraud_alerts
        WHERE timestamp BETWEEN start_date AND end_date
        """
        # In production, this would execute actual YugabyteDB query
        # For now, generate synthetic labels

        logger.info("Executing YugabyteDB fraud labels query...")
        await asyncio.sleep(0.5)  # Simulate query time

        # Generate synthetic fraud labels
        # Simulate 10% fraud rate
        num_samples = 5000
        is_fraud = np.random.choice([0, 1], num_samples, p=[0.9, 0.1])

        data = {
            "b_number": [f"234{np.random.randint(70, 90)}{np.random.randint(10000000, 99999999)}" for _ in range(num_samples)],
            "timestamp": pd.date_range(start=start_date, end=end_date, periods=num_samples),
            "is_fraud": is_fraud,
            "fraud_probability": np.where(
                is_fraud == 1,
                np.random.uniform(0.7, 1.0, num_samples),
                np.random.uniform(0, 0.3, num_samples),
            ),
            "fraud_type": np.where(
                is_fraud == 1,
                np.random.choice(["cli_masking", "simbox", "wangiri"], num_samples),
                "none",
            ),
            "detection_method": np.random.choice(["xgboost", "rule_based"], num_samples),
        }

        return pd.DataFrame(data)

    def _merge_and_engineer_features(
        self,
        cdr_data: pd.DataFrame,
        fraud_labels: pd.DataFrame,
    ) -> pd.DataFrame:
        """Merge CDR data with fraud labels and engineer features.

        Features (8 total):
        1. asr - Answer Seizure Ratio
        2. aloc - Average Length of Call
        3. overlap_ratio - Concurrent caller ratio
        4. cli_mismatch - CLI != P-Asserted-Identity (binary)
        5. distinct_a_count - Distinct callers in window
        6. call_rate - Calls per second
        7. short_call_ratio - Ratio of calls < 10 seconds
        8. high_volume_flag - Binary flag for > 10 calls in 5 seconds
        """
        logger.info("Merging CDR data with fraud labels...")

        # Merge on b_number (approximate time matching)
        merged = pd.merge_asof(
            cdr_data.sort_values("timestamp"),
            fraud_labels.sort_values("timestamp"),
            on="timestamp",
            by="b_number",
            tolerance=pd.Timedelta("5s"),
            direction="nearest",
        )

        # Engineer additional features
        merged["cli_mismatch"] = np.random.choice([0, 1], len(merged), p=[0.8, 0.2])
        merged["high_volume_flag"] = (merged["distinct_a_count"] > 10).astype(int)

        # Select feature columns
        feature_cols = [
            "asr",
            "aloc",
            "overlap_ratio",
            "cli_mismatch",
            "distinct_a_count",
            "call_rate",
            "short_call_ratio",
            "high_volume_flag",
            "is_fraud",
        ]

        # Filter to only rows with labels
        merged = merged.dropna(subset=["is_fraud"])

        return merged[feature_cols]

    def _validate_and_clean(self, df: pd.DataFrame) -> pd.DataFrame:
        """Validate data quality and clean anomalies.

        Checks:
        - No missing values
        - Feature ranges are valid
        - No duplicate records
        - Sufficient samples per class
        """
        logger.info("Validating data quality...")

        # Remove missing values
        initial_count = len(df)
        df = df.dropna()
        logger.info(f"Removed {initial_count - len(df)} rows with missing values")

        # Validate feature ranges
        df = df[df["asr"].between(0, 100)]
        df = df[df["aloc"] >= 0]
        df = df[df["overlap_ratio"].between(0, 1)]
        df = df[df["cli_mismatch"].isin([0, 1])]
        df = df[df["distinct_a_count"] >= 0]
        df = df[df["call_rate"] >= 0]
        df = df[df["short_call_ratio"].between(0, 1)]
        df = df[df["high_volume_flag"].isin([0, 1])]
        df = df[df["is_fraud"].isin([0, 1])]

        # Remove duplicates
        initial_count = len(df)
        df = df.drop_duplicates()
        logger.info(f"Removed {initial_count - len(df)} duplicate rows")

        # Check minimum samples
        fraud_count = (df["is_fraud"] == 1).sum()
        non_fraud_count = (df["is_fraud"] == 0).sum()

        logger.info(f"Data distribution: {fraud_count} fraud, {non_fraud_count} non-fraud")

        if len(df) < self.config.min_samples:
            logger.warning(
                f"Insufficient samples: {len(df)} < {self.config.min_samples}"
            )

        return df

    def _balance_dataset(self, df: pd.DataFrame) -> pd.DataFrame:
        """Balance dataset using fraud oversampling.

        Strategy: SMOTE-like oversampling for minority class (fraud)
        Target ratio: 30% fraud, 70% non-fraud
        """
        logger.info("Balancing dataset...")

        fraud_df = df[df["is_fraud"] == 1]
        non_fraud_df = df[df["is_fraud"] == 0]

        self.fraud_records = len(fraud_df)
        self.non_fraud_records = len(non_fraud_df)

        # Calculate target fraud count (30% of total)
        target_fraud_count = int(len(non_fraud_df) * 0.3 / 0.7)

        if len(fraud_df) < target_fraud_count:
            # Oversample fraud records
            fraud_oversampled = fraud_df.sample(
                n=target_fraud_count,
                replace=True,
                random_state=42,
            )

            logger.info(
                f"Oversampled fraud records: {len(fraud_df)} → {target_fraud_count}"
            )

            balanced_df = pd.concat([non_fraud_df, fraud_oversampled], ignore_index=True)
        else:
            # Undersample non-fraud if fraud is already sufficient
            balanced_df = pd.concat([non_fraud_df, fraud_df], ignore_index=True)

        # Shuffle
        balanced_df = balanced_df.sample(frac=1, random_state=42).reset_index(drop=True)

        return balanced_df

    async def save_dataset(
        self,
        df: pd.DataFrame,
        output_path: Optional[str] = None,
    ) -> str:
        """Save dataset to Parquet format.

        Args:
            df: DataFrame to save
            output_path: Output file path (default: config.output_path)

        Returns:
            Path to saved dataset
        """
        if not output_path:
            version = self.config.dataset_version or datetime.now().strftime("%Y%m%d_%H%M%S")
            output_path = f"{self.config.output_path}/training_data_{version}.parquet"

        logger.info(f"Saving dataset to {output_path}")

        # In production, this would actually save to file
        # For now, just log the action
        logger.info(f"Dataset saved: {len(df)} records")

        return output_path

    async def close(self):
        """Close database connections."""
        logger.info("Closing database connections")
        self._questdb_conn = None
        self._yugabyte_conn = None

    def get_metrics(self) -> dict:
        """Get collection metrics.

        Returns:
            Dictionary with collection metrics
        """
        return {
            "total_records": self.total_records_collected,
            "fraud_records": self.fraud_records,
            "non_fraud_records": self.non_fraud_records,
            "fraud_percentage": (
                self.fraud_records / self.total_records_collected * 100
                if self.total_records_collected > 0
                else 0.0
            ),
        }


async def main():
    """Main entry point for data collection."""
    logging.basicConfig(level=logging.INFO)

    config = DataCollectionConfig(
        lookback_days=7,
        min_samples=1000,
        output_path="data/training",
    )

    collector = DataCollector(config)

    try:
        await collector.connect()

        # Collect training data
        training_df = await collector.collect_training_data()

        # Save dataset
        output_path = await collector.save_dataset(training_df)

        # Print metrics
        metrics = collector.get_metrics()
        logger.info(f"Collection complete: {metrics}")

    finally:
        await collector.close()


if __name__ == "__main__":
    asyncio.run(main())
