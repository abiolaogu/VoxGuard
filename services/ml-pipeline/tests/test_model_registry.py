"""Tests for model registry."""
import json
import tempfile
from pathlib import Path

import pytest

from ..model_registry import ModelRegistry, ModelMetadata


@pytest.fixture
def temp_registry():
    """Create a temporary registry."""
    with tempfile.TemporaryDirectory() as tmpdir:
        yield ModelRegistry(tmpdir)


@pytest.fixture
def sample_metadata():
    """Create sample model metadata."""
    return ModelMetadata(
        model_id="xgboost_v1.0.0",
        version="1.0.0",
        created_at="2026-02-03T12:00:00Z",
        algorithm="xgboost",
        training_samples=10000,
        auc_score=0.92,
        precision=0.88,
        recall=0.85,
        f1_score=0.865,
        accuracy=0.90,
        features=["asr", "aloc", "overlap_ratio"],
        feature_importance={"asr": 0.4, "aloc": 0.3, "overlap_ratio": 0.3},
        hyperparameters={"max_depth": 6, "learning_rate": 0.1},
        status="candidate",
    )


def test_registry_initialization(temp_registry):
    """Test registry initialization."""
    assert temp_registry.registry_path.exists()
    assert temp_registry.index_path.exists()
    assert "models" in temp_registry.index
    assert temp_registry.index["champion"] is None


def test_register_model(temp_registry, sample_metadata):
    """Test registering a model."""
    # Create a dummy model file
    with tempfile.NamedTemporaryFile(suffix=".json", delete=False) as f:
        model_path = f.name
        json.dump({"dummy": "model"}, f)

    try:
        model_id = temp_registry.register_model(model_path, sample_metadata)
        assert model_id == "xgboost_v1.0.0"
        assert model_id in temp_registry.index["models"]

        # Check model file was copied
        registered_path = temp_registry.get_model_path(model_id)
        assert registered_path is not None
        assert Path(registered_path).exists()

        # Check metadata was saved
        metadata = temp_registry.get_metadata(model_id)
        assert metadata is not None
        assert metadata.auc_score == 0.92
    finally:
        Path(model_path).unlink()


def test_get_metadata(temp_registry, sample_metadata):
    """Test retrieving metadata."""
    with tempfile.NamedTemporaryFile(suffix=".json", delete=False) as f:
        model_path = f.name
        json.dump({"dummy": "model"}, f)

    try:
        model_id = temp_registry.register_model(model_path, sample_metadata)
        metadata = temp_registry.get_metadata(model_id)

        assert metadata.model_id == "xgboost_v1.0.0"
        assert metadata.auc_score == 0.92
        assert metadata.status == "candidate"
    finally:
        Path(model_path).unlink()


def test_promote_to_champion(temp_registry, sample_metadata):
    """Test promoting a model to champion."""
    with tempfile.NamedTemporaryFile(suffix=".json", delete=False) as f:
        model_path = f.name
        json.dump({"dummy": "model"}, f)

    try:
        model_id = temp_registry.register_model(model_path, sample_metadata)
        success = temp_registry.promote_to_champion(model_id)

        assert success is True
        assert temp_registry.index["champion"] == model_id

        # Check metadata was updated
        metadata = temp_registry.get_metadata(model_id)
        assert metadata.status == "champion"
        assert metadata.deployed_at is not None
    finally:
        Path(model_path).unlink()


def test_get_champion(temp_registry, sample_metadata):
    """Test getting the champion model."""
    # No champion initially
    assert temp_registry.get_champion() is None

    with tempfile.NamedTemporaryFile(suffix=".json", delete=False) as f:
        model_path = f.name
        json.dump({"dummy": "model"}, f)

    try:
        model_id = temp_registry.register_model(model_path, sample_metadata)
        temp_registry.promote_to_champion(model_id)

        champion = temp_registry.get_champion()
        assert champion is not None
        assert champion[0] == model_id
        assert Path(champion[1]).exists()
    finally:
        Path(model_path).unlink()


def test_list_models(temp_registry):
    """Test listing models."""
    # Create two models
    models = []
    for i in range(2):
        metadata = ModelMetadata(
            model_id=f"xgboost_v1.{i}.0",
            version=f"1.{i}.0",
            created_at=f"2026-02-03T12:0{i}:00Z",
            algorithm="xgboost",
            training_samples=10000,
            auc_score=0.90 + i * 0.02,
            precision=0.88,
            recall=0.85,
            f1_score=0.865,
            accuracy=0.90,
            features=["asr"],
            feature_importance={"asr": 1.0},
            hyperparameters={},
            status="candidate" if i == 0 else "champion",
        )

        with tempfile.NamedTemporaryFile(suffix=".json", delete=False) as f:
            model_path = f.name
            json.dump({"dummy": f"model{i}"}, f)

        model_id = temp_registry.register_model(model_path, metadata)
        models.append((model_id, model_path))

    try:
        # List all models
        all_models = temp_registry.list_models()
        assert len(all_models) == 2

        # List only candidates
        candidates = temp_registry.list_models(status="candidate")
        assert len(candidates) == 1
        assert candidates[0]["model_id"] == "xgboost_v1.0.0"
    finally:
        for _, path in models:
            Path(path).unlink()


def test_compare_models(temp_registry):
    """Test comparing two models."""
    # Create two models
    models = []
    for i in range(2):
        metadata = ModelMetadata(
            model_id=f"xgboost_v1.{i}.0",
            version=f"1.{i}.0",
            created_at=f"2026-02-03T12:0{i}:00Z",
            algorithm="xgboost",
            training_samples=10000,
            auc_score=0.90 + i * 0.03,
            precision=0.88 + i * 0.02,
            recall=0.85 + i * 0.01,
            f1_score=0.865,
            accuracy=0.90,
            features=["asr"],
            feature_importance={"asr": 1.0},
            hyperparameters={},
            status="candidate",
        )

        with tempfile.NamedTemporaryFile(suffix=".json", delete=False) as f:
            model_path = f.name
            json.dump({"dummy": f"model{i}"}, f)

        model_id = temp_registry.register_model(model_path, metadata)
        models.append((model_id, model_path))

    try:
        comparison = temp_registry.compare_models(models[0][0], models[1][0])

        assert comparison is not None
        assert comparison["delta"]["auc"] == pytest.approx(0.03)
        assert comparison["winner"] == models[1][0]
    finally:
        for _, path in models:
            Path(path).unlink()


def test_archive_model(temp_registry, sample_metadata):
    """Test archiving a model."""
    with tempfile.NamedTemporaryFile(suffix=".json", delete=False) as f:
        model_path = f.name
        json.dump({"dummy": "model"}, f)

    try:
        model_id = temp_registry.register_model(model_path, sample_metadata)
        success = temp_registry.archive_model(model_id)

        assert success is True
        metadata = temp_registry.get_metadata(model_id)
        assert metadata.status == "archived"
    finally:
        Path(model_path).unlink()
