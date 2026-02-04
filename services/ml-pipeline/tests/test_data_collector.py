"""Unit tests for automated data collection pipeline."""
import asyncio
import pytest
from datetime import datetime, timedelta

import pandas as pd
import sys
sys.path.append("..")

from data_collector import DataCollector, DataCollectionConfig


@pytest.fixture
def test_config():
    """Create test data collection configuration."""
    return DataCollectionConfig(
        questdb_host="localhost",
        questdb_port=8812,
        yugabyte_host="localhost",
        yugabyte_port=5433,
        lookback_days=7,
        min_samples=100,
        output_path="/tmp/training",
    )


@pytest.fixture
def data_collector(test_config):
    """Create data collector instance."""
    return DataCollector(test_config)


class TestDataCollector:
    """Tests for DataCollector."""

    @pytest.mark.asyncio
    async def test_initialization(self, data_collector, test_config):
        """Test data collector initialization."""
        assert data_collector.config == test_config
        assert data_collector.total_records_collected == 0
        assert data_collector.fraud_records == 0
        assert data_collector.non_fraud_records == 0

    @pytest.mark.asyncio
    async def test_connect(self, data_collector):
        """Test database connections."""
        await data_collector.connect()

        # In production, these would be actual connections
        # For now, just verify they're set
        assert data_collector._questdb_conn is not None
        assert data_collector._yugabyte_conn is not None

    @pytest.mark.asyncio
    async def test_collect_training_data(self, data_collector):
        """Test collecting training data."""
        await data_collector.connect()

        start_date = datetime.now() - timedelta(days=7)
        end_date = datetime.now()

        training_df = await data_collector.collect_training_data(start_date, end_date)

        # Verify DataFrame structure
        assert isinstance(training_df, pd.DataFrame)
        assert len(training_df) > 0

        # Verify required columns
        required_cols = [
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

        for col in required_cols:
            assert col in training_df.columns

        # Verify data types
        assert training_df["is_fraud"].dtype in [int, bool]
        assert training_df["cli_mismatch"].dtype in [int, bool]

    @pytest.mark.asyncio
    async def test_extract_cdr_metrics(self, data_collector):
        """Test extracting CDR metrics from QuestDB."""
        await data_collector.connect()

        start_date = datetime.now() - timedelta(days=7)
        end_date = datetime.now()

        cdr_data = await data_collector._extract_cdr_metrics(start_date, end_date)

        assert isinstance(cdr_data, pd.DataFrame)
        assert len(cdr_data) > 0
        assert "timestamp" in cdr_data.columns
        assert "b_number" in cdr_data.columns
        assert "asr" in cdr_data.columns

    @pytest.mark.asyncio
    async def test_extract_fraud_labels(self, data_collector):
        """Test extracting fraud labels from YugabyteDB."""
        await data_collector.connect()

        start_date = datetime.now() - timedelta(days=7)
        end_date = datetime.now()

        fraud_labels = await data_collector._extract_fraud_labels(start_date, end_date)

        assert isinstance(fraud_labels, pd.DataFrame)
        assert len(fraud_labels) > 0
        assert "b_number" in fraud_labels.columns
        assert "is_fraud" in fraud_labels.columns
        assert "fraud_probability" in fraud_labels.columns

    def test_validate_and_clean(self, data_collector):
        """Test data validation and cleaning."""
        # Create test DataFrame with invalid data
        test_df = pd.DataFrame({
            "asr": [50.0, 101.0, 75.0, -10.0],  # One invalid (>100), one invalid (<0)
            "aloc": [100.0, 200.0, 150.0, -50.0],  # One invalid (<0)
            "overlap_ratio": [0.5, 1.5, 0.8, 0.6],  # One invalid (>1)
            "cli_mismatch": [0, 1, 0, 1],
            "distinct_a_count": [3, 5, 4, 2],
            "call_rate": [1.0, 2.0, 1.5, 0.8],
            "short_call_ratio": [0.2, 0.3, 0.25, 0.15],
            "high_volume_flag": [0, 1, 0, 0],
            "is_fraud": [0, 1, 0, 1],
        })

        cleaned_df = data_collector._validate_and_clean(test_df)

        # Only valid rows should remain
        assert len(cleaned_df) < len(test_df)
        assert (cleaned_df["asr"] >= 0).all()
        assert (cleaned_df["asr"] <= 100).all()
        assert (cleaned_df["overlap_ratio"] >= 0).all()
        assert (cleaned_df["overlap_ratio"] <= 1).all()

    def test_balance_dataset(self, data_collector):
        """Test dataset balancing."""
        # Create imbalanced dataset (90% non-fraud, 10% fraud)
        test_df = pd.DataFrame({
            "asr": [50.0] * 100,
            "aloc": [100.0] * 100,
            "overlap_ratio": [0.5] * 100,
            "cli_mismatch": [0] * 100,
            "distinct_a_count": [3] * 100,
            "call_rate": [1.0] * 100,
            "short_call_ratio": [0.2] * 100,
            "high_volume_flag": [0] * 100,
            "is_fraud": [0] * 90 + [1] * 10,  # 10% fraud
        })

        balanced_df = data_collector._balance_dataset(test_df)

        # Calculate fraud percentage
        fraud_pct = (balanced_df["is_fraud"] == 1).sum() / len(balanced_df)

        # Should be closer to 30% fraud (target ratio)
        assert 0.20 <= fraud_pct <= 0.40

    @pytest.mark.asyncio
    async def test_save_dataset(self, data_collector, tmp_path):
        """Test saving dataset to Parquet."""
        # Create test DataFrame
        test_df = pd.DataFrame({
            "asr": [50.0, 60.0, 70.0],
            "aloc": [100.0, 150.0, 200.0],
            "overlap_ratio": [0.5, 0.6, 0.7],
            "cli_mismatch": [0, 1, 0],
            "distinct_a_count": [3, 4, 5],
            "call_rate": [1.0, 1.5, 2.0],
            "short_call_ratio": [0.2, 0.25, 0.3],
            "high_volume_flag": [0, 1, 0],
            "is_fraud": [0, 1, 0],
        })

        output_path = str(tmp_path / "test_data.parquet")
        saved_path = await data_collector.save_dataset(test_df, output_path)

        assert saved_path == output_path

    def test_get_metrics(self, data_collector):
        """Test getting collector metrics."""
        data_collector.total_records_collected = 1000
        data_collector.fraud_records = 300
        data_collector.non_fraud_records = 700

        metrics = data_collector.get_metrics()

        assert metrics["total_records"] == 1000
        assert metrics["fraud_records"] == 300
        assert metrics["non_fraud_records"] == 700
        assert metrics["fraud_percentage"] == 30.0

    @pytest.mark.asyncio
    async def test_close(self, data_collector):
        """Test closing database connections."""
        await data_collector.connect()
        await data_collector.close()

        # Connections should be cleared
        assert data_collector._questdb_conn is None
        assert data_collector._yugabyte_conn is None


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
