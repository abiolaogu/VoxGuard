"""Model Registry for versioning and managing ML models."""
import json
import logging
import os
import shutil
from dataclasses import dataclass, asdict
from datetime import datetime
from pathlib import Path
from typing import Optional, List, Dict, Any

logger = logging.getLogger(__name__)


@dataclass
class ModelMetadata:
    """Metadata for a registered model."""

    model_id: str  # Unique identifier (e.g., "xgboost_v1.2.3")
    version: str  # Semantic version (e.g., "1.2.3")
    created_at: str  # ISO 8601 timestamp
    algorithm: str  # "xgboost", "lightgbm", etc.

    # Training metrics
    training_samples: int
    auc_score: float
    precision: float
    recall: float
    f1_score: float
    accuracy: float

    # Feature info
    features: List[str]
    feature_importance: Dict[str, float]

    # Model config
    hyperparameters: Dict[str, Any]

    # Deployment info
    status: str  # "candidate", "champion", "archived"
    deployed_at: Optional[str] = None
    replaced_by: Optional[str] = None

    # Performance tracking
    production_metrics: Optional[Dict[str, float]] = None

    def to_dict(self) -> dict:
        """Convert to dictionary."""
        return asdict(self)

    @classmethod
    def from_dict(cls, data: dict) -> "ModelMetadata":
        """Create from dictionary."""
        return cls(**data)


class ModelRegistry:
    """Manage model versions and lifecycle."""

    METADATA_FILE = "metadata.json"
    REGISTRY_INDEX = "registry_index.json"

    def __init__(self, registry_path: str = "models/registry"):
        """Initialize the model registry.

        Args:
            registry_path: Base path for model storage
        """
        self.registry_path = Path(registry_path)
        self.registry_path.mkdir(parents=True, exist_ok=True)

        self.index_path = self.registry_path / self.REGISTRY_INDEX
        self._load_index()

    def _load_index(self) -> None:
        """Load the registry index."""
        if self.index_path.exists():
            with open(self.index_path, "r") as f:
                self.index = json.load(f)
        else:
            self.index = {
                "models": {},
                "champion": None,
                "last_updated": datetime.utcnow().isoformat(),
            }
            self._save_index()

    def _save_index(self) -> None:
        """Save the registry index."""
        self.index["last_updated"] = datetime.utcnow().isoformat()
        with open(self.index_path, "w") as f:
            json.dump(self.index, f, indent=2)

    def register_model(
        self, model_path: str, metadata: ModelMetadata
    ) -> str:
        """Register a new model in the registry.

        Args:
            model_path: Path to the model file
            metadata: Model metadata

        Returns:
            Model ID
        """
        model_id = metadata.model_id

        # Create model directory
        model_dir = self.registry_path / model_id
        model_dir.mkdir(parents=True, exist_ok=True)

        # Copy model file
        model_file = Path(model_path)
        dest_model = model_dir / f"model{model_file.suffix}"
        shutil.copy2(model_file, dest_model)

        # Save metadata
        metadata_file = model_dir / self.METADATA_FILE
        with open(metadata_file, "w") as f:
            json.dump(metadata.to_dict(), f, indent=2)

        # Update index
        self.index["models"][model_id] = {
            "version": metadata.version,
            "created_at": metadata.created_at,
            "status": metadata.status,
            "auc_score": metadata.auc_score,
            "model_path": str(dest_model),
        }
        self._save_index()

        logger.info(f"Registered model: {model_id} (AUC: {metadata.auc_score:.4f})")
        return model_id

    def get_model_path(self, model_id: str) -> Optional[str]:
        """Get the file path for a model.

        Args:
            model_id: Model identifier

        Returns:
            Path to model file or None if not found
        """
        if model_id not in self.index["models"]:
            return None

        model_dir = self.registry_path / model_id
        model_files = list(model_dir.glob("model.*"))

        if not model_files:
            return None

        return str(model_files[0])

    def get_metadata(self, model_id: str) -> Optional[ModelMetadata]:
        """Get metadata for a model.

        Args:
            model_id: Model identifier

        Returns:
            ModelMetadata or None if not found
        """
        metadata_file = self.registry_path / model_id / self.METADATA_FILE

        if not metadata_file.exists():
            return None

        with open(metadata_file, "r") as f:
            data = json.load(f)

        return ModelMetadata.from_dict(data)

    def update_metadata(self, model_id: str, metadata: ModelMetadata) -> bool:
        """Update metadata for a model.

        Args:
            model_id: Model identifier
            metadata: Updated metadata

        Returns:
            True if successful
        """
        if model_id not in self.index["models"]:
            return False

        metadata_file = self.registry_path / model_id / self.METADATA_FILE

        with open(metadata_file, "w") as f:
            json.dump(metadata.to_dict(), f, indent=2)

        # Update index
        self.index["models"][model_id]["status"] = metadata.status
        if metadata.deployed_at:
            self.index["models"][model_id]["deployed_at"] = metadata.deployed_at
        self._save_index()

        return True

    def promote_to_champion(self, model_id: str) -> bool:
        """Promote a model to champion (production).

        Args:
            model_id: Model to promote

        Returns:
            True if successful
        """
        if model_id not in self.index["models"]:
            logger.error(f"Model {model_id} not found in registry")
            return False

        # Archive previous champion
        old_champion = self.index.get("champion")
        if old_champion:
            old_metadata = self.get_metadata(old_champion)
            if old_metadata:
                old_metadata.status = "archived"
                old_metadata.replaced_by = model_id
                self.update_metadata(old_champion, old_metadata)

        # Promote new champion
        new_metadata = self.get_metadata(model_id)
        if not new_metadata:
            return False

        new_metadata.status = "champion"
        new_metadata.deployed_at = datetime.utcnow().isoformat()
        self.update_metadata(model_id, new_metadata)

        # Update index
        self.index["champion"] = model_id
        self._save_index()

        logger.info(f"Promoted {model_id} to champion (replaced {old_champion})")
        return True

    def get_champion(self) -> Optional[tuple[str, str]]:
        """Get the current champion model.

        Returns:
            Tuple of (model_id, model_path) or None
        """
        champion_id = self.index.get("champion")
        if not champion_id:
            return None

        model_path = self.get_model_path(champion_id)
        if not model_path:
            return None

        return champion_id, model_path

    def list_models(
        self, status: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """List all models in the registry.

        Args:
            status: Filter by status (candidate, champion, archived)

        Returns:
            List of model summaries
        """
        models = []

        for model_id, info in self.index["models"].items():
            if status and info["status"] != status:
                continue

            metadata = self.get_metadata(model_id)
            if metadata:
                models.append(
                    {
                        "model_id": model_id,
                        "version": metadata.version,
                        "status": metadata.status,
                        "created_at": metadata.created_at,
                        "auc_score": metadata.auc_score,
                        "precision": metadata.precision,
                        "recall": metadata.recall,
                        "deployed_at": metadata.deployed_at,
                    }
                )

        # Sort by created_at (newest first)
        models.sort(key=lambda x: x["created_at"], reverse=True)
        return models

    def compare_models(
        self, model_a_id: str, model_b_id: str
    ) -> Optional[Dict[str, Any]]:
        """Compare two models.

        Args:
            model_a_id: First model
            model_b_id: Second model

        Returns:
            Comparison dictionary or None if error
        """
        metadata_a = self.get_metadata(model_a_id)
        metadata_b = self.get_metadata(model_b_id)

        if not metadata_a or not metadata_b:
            return None

        return {
            "model_a": {
                "id": model_a_id,
                "auc": metadata_a.auc_score,
                "precision": metadata_a.precision,
                "recall": metadata_a.recall,
                "f1": metadata_a.f1_score,
            },
            "model_b": {
                "id": model_b_id,
                "auc": metadata_b.auc_score,
                "precision": metadata_b.precision,
                "recall": metadata_b.recall,
                "f1": metadata_b.f1_score,
            },
            "delta": {
                "auc": metadata_b.auc_score - metadata_a.auc_score,
                "precision": metadata_b.precision - metadata_a.precision,
                "recall": metadata_b.recall - metadata_a.recall,
                "f1": metadata_b.f1_score - metadata_a.f1_score,
            },
            "winner": model_b_id
            if metadata_b.auc_score > metadata_a.auc_score
            else model_a_id,
        }

    def archive_model(self, model_id: str) -> bool:
        """Archive a model (soft delete).

        Args:
            model_id: Model to archive

        Returns:
            True if successful
        """
        metadata = self.get_metadata(model_id)
        if not metadata:
            return False

        metadata.status = "archived"
        return self.update_metadata(model_id, metadata)

    def delete_model(self, model_id: str) -> bool:
        """Permanently delete a model.

        Args:
            model_id: Model to delete

        Returns:
            True if successful
        """
        if model_id not in self.index["models"]:
            return False

        # Don't allow deleting champion
        if self.index.get("champion") == model_id:
            logger.error(f"Cannot delete champion model {model_id}")
            return False

        # Delete model directory
        model_dir = self.registry_path / model_id
        if model_dir.exists():
            shutil.rmtree(model_dir)

        # Remove from index
        del self.index["models"][model_id]
        self._save_index()

        logger.info(f"Deleted model: {model_id}")
        return True
