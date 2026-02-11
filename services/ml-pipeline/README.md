## ML Pipeline for VoxGuard

**Version:** 1.0.0
**Purpose:** Advanced machine learning integration for fraud detection

---

## Overview

The ML Pipeline provides complete infrastructure for training, deploying, and monitoring machine learning models in the VoxGuard fraud detection system. It implements:

- **Real-time inference** with <1ms latency via gRPC
- **Automated model retraining** on labeled data
- **A/B testing** framework for model comparison
- **Model versioning** and registry for lifecycle management
- **Performance monitoring** with data drift detection

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         ML Pipeline                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │  Training   │───→│    Model     │───→│  Inference   │       │
│  │ Orchestrator│    │   Registry   │    │   Server     │       │
│  └─────────────┘    └──────────────┘    └──────────────┘       │
│         │                   │                    │               │
│         │                   │                    │               │
│         ↓                   ↓                    ↓               │
│  ┌─────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │  Evaluator  │    │   Metadata   │    │  A/B Testing │       │
│  │  (Metrics)  │    │   Storage    │    │   Traffic    │       │
│  └─────────────┘    └──────────────┘    └──────────────┘       │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
           │                                          │
           ↓                                          ↓
    ┌──────────────┐                          ┌──────────────┐
    │  YugabyteDB  │                          │ Detection    │
    │ (Training    │                          │ Engine       │
    │  Data)       │                          │ (Rust)       │
    └──────────────┘                          └──────────────┘
```

---

## Components

### 1. Model Registry (`model_registry.py`)

Manages model versions and lifecycle.

**Features:**
- Semantic versioning (e.g., `xgboost_v2026.02.03.140530`)
- Metadata storage (metrics, features, hyperparameters)
- Champion/Challenger pattern for production deployment
- Model comparison and promotion
- Archival and deletion

**Usage:**
```python
from ml_pipeline.model_registry import ModelRegistry, ModelMetadata

registry = ModelRegistry("models/registry")

# Register a new model
metadata = ModelMetadata(
    model_id="xgboost_v2026.02.03.140530",
    version="2026.02.03.140530",
    auc_score=0.92,
    precision=0.88,
    recall=0.85,
    ...
)
registry.register_model("path/to/model.json", metadata)

# Promote to production
registry.promote_to_champion("xgboost_v2026.02.03.140530")

# Get champion
model_id, model_path = registry.get_champion()
```

---

### 2. Model Training (`training/trainer.py`)

XGBoost model training orchestrator.

**Features:**
- Train/validation/test split
- Hyperparameter configuration
- Early stopping
- Feature importance tracking
- Model versioning

**Usage:**
```python
from ml_pipeline.training.trainer import ModelTrainer

trainer = ModelTrainer(
    max_depth=6,
    learning_rate=0.1,
    n_estimators=100
)

# Prepare data
dtrain, dval, dtest = trainer.prepare_data(df)

# Train model
history = trainer.train(dtrain, dval, early_stopping_rounds=20)

# Get feature importance
importance = trainer.get_feature_importance()

# Save model
trainer.save_model("models/xgboost_new.json")
```

---

### 3. Model Evaluation (`training/evaluator.py`)

Comprehensive model performance metrics.

**Metrics:**
- AUC, Accuracy, Precision, Recall, F1
- Confusion matrix
- Specificity, FPR, FNR
- Threshold sensitivity analysis

**Usage:**
```python
from ml_pipeline.training.evaluator import ModelEvaluator

evaluator = ModelEvaluator(threshold=0.7)

# Evaluate model
metrics = evaluator.evaluate(y_true, y_pred_proba)

print(f"AUC: {metrics.auc_score:.4f}")
print(f"Precision: {metrics.precision:.4f}")
print(f"Recall: {metrics.recall:.4f}")

# Check if model passes thresholds
passes = metrics.passes_thresholds(
    min_auc=0.85,
    min_precision=0.80,
    min_recall=0.75
)

# Compare with baseline
is_better = metrics.is_better_than(baseline_metrics, min_improvement=0.02)
```

---

### 4. Inference Server (`inference_server.py`)

Real-time gRPC inference server.

**Features:**
- <1ms prediction latency
- Batch processing for efficiency
- A/B testing support
- Request queuing
- Prometheus metrics

**Usage:**
```python
from ml_pipeline.inference_server import InferenceServer

server = InferenceServer(
    registry_path="models/registry",
    host="0.0.0.0",
    port=50051,
    batch_size=32,
    batch_timeout_ms=10
)

# Set challenger model for A/B testing
server.set_challenger_model("xgboost_v2026.02.03.140530")

# Start server
await server.serve()
```

**gRPC API:**
```proto
service FraudDetection {
  rpc Predict (PredictionRequest) returns (PredictionResponse);
}

message PredictionRequest {
  repeated float features = 1;  // 8 features
  string request_id = 2;
}

message PredictionResponse {
  bool is_fraud = 1;
  float probability = 2;
  string model_version = 3;
  float latency_ms = 4;
}
```

---

### 5. A/B Testing (`ab_testing/traffic_splitter.py`)

Traffic splitting for model comparison.

**Features:**
- Configurable traffic split (e.g., 90/10)
- Hash-based deterministic routing
- Gradual rollout system
- Traffic statistics tracking

**Usage:**
```python
from ml_pipeline.ab_testing.traffic_splitter import TrafficSplitter, GradualRollout

# Simple A/B test (90/10 split)
splitter = TrafficSplitter(
    model_a_traffic=0.9,
    model_b_traffic=0.1
)

use_model_b = splitter.should_use_model_b()

# Gradual rollout
rollout = GradualRollout(
    initial_traffic=0.1,
    step_percentage=0.1,
    max_traffic=1.0
)

# Increase traffic incrementally
new_traffic = rollout.increase_traffic()  # 0.1 → 0.2
```

---

## Configuration

Environment variables:

```bash
# Inference Server
ML_INFERENCE_HOST=0.0.0.0
ML_INFERENCE_PORT=50051
ML_MAX_WORKERS=10

# Training
ML_TRAINING_LOOKBACK_DAYS=7
ML_TRAINING_SCHEDULE="0 2 * * *"  # Daily at 2 AM

# Database
YUGABYTE_HOST=localhost
YUGABYTE_PORT=5433
YUGABYTE_DB=voxguard
YUGABYTE_USER=voxguard
YUGABYTE_PASSWORD=<secret>

# Environment
ML_ENVIRONMENT=production
ML_DEBUG=false
```

---

## Deployment

### Docker Deployment

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy ML pipeline
COPY services/ml-pipeline/ ./ml_pipeline/
COPY models/ ./models/

# Run inference server
CMD ["python", "-m", "ml_pipeline.inference_server"]
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ml-inference-server
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ml-inference
  template:
    metadata:
      labels:
        app: ml-inference
    spec:
      containers:
      - name: inference
        image: voxguard/ml-inference:latest
        ports:
        - containerPort: 50051
          name: grpc
        - containerPort: 9091
          name: metrics
        resources:
          requests:
            cpu: "1"
            memory: "2Gi"
          limits:
            cpu: "2"
            memory: "4Gi"
        env:
        - name: ML_INFERENCE_HOST
          value: "0.0.0.0"
        - name: ML_INFERENCE_PORT
          value: "50051"
        volumeMounts:
        - name: models
          mountPath: /app/models
      volumes:
      - name: models
        persistentVolumeClaim:
          claimName: ml-models-pvc
```

---

## Training Pipeline

### Automated Retraining

The training scheduler runs daily at 2 AM (WAT) to retrain models on the latest labeled data.

**Process:**
1. **Data Extraction:** Query YugabyteDB for past 7 days of labeled alerts
2. **Data Preparation:** Split into train/validation/test (70/10/20)
3. **Model Training:** Train XGBoost with early stopping
4. **Evaluation:** Compute metrics on test set
5. **Quality Check:** Ensure AUC ≥ 0.85, Precision ≥ 0.80, Recall ≥ 0.75
6. **Comparison:** Compare with current champion model
7. **Promotion:** If new model is 2%+ better, register as candidate
8. **Notification:** Alert team for manual approval before production deployment

**Manual Training:**

```python
import asyncpg
import pandas as pd
from ml_pipeline.config import MLPipelineConfig
from ml_pipeline.training.trainer import ModelTrainer
from ml_pipeline.training.evaluator import ModelEvaluator
from ml_pipeline.model_registry import ModelRegistry, ModelMetadata

# Load configuration
config = MLPipelineConfig.from_env()

# Connect to database
conn = await asyncpg.connect(config.database_dsn)

# Extract training data
query = config.training.training_query.format(lookback_days=7)
rows = await conn.fetch(query)
df = pd.DataFrame(rows)

# Train model
trainer = ModelTrainer(
    max_depth=config.model.max_depth,
    learning_rate=config.model.learning_rate,
    n_estimators=config.model.n_estimators
)

dtrain, dval, dtest = trainer.prepare_data(df)
history = trainer.train(dtrain, dval)

# Evaluate
evaluator = ModelEvaluator(threshold=0.7)
y_test = dtest.get_label()
y_pred = trainer.predict_from_dmatrix(dtest)
metrics = evaluator.evaluate(y_test, y_pred)

# Check quality
if metrics.passes_thresholds(
    min_auc=config.model.min_auc_score,
    min_precision=config.model.min_precision,
    min_recall=config.model.min_recall
):
    # Save model
    version = ModelTrainer.create_version_string()
    model_id = ModelTrainer.create_model_id(version)
    model_path = f"models/{model_id}.json"
    trainer.save_model(model_path)

    # Register in registry
    registry = ModelRegistry(config.model.model_registry_path)
    metadata = ModelMetadata(
        model_id=model_id,
        version=version,
        created_at=datetime.utcnow().isoformat(),
        algorithm="xgboost",
        training_samples=len(df),
        auc_score=metrics.auc_score,
        precision=metrics.precision,
        recall=metrics.recall,
        f1_score=metrics.f1_score,
        accuracy=metrics.accuracy,
        features=ModelTrainer.FEATURE_NAMES,
        feature_importance=trainer.get_feature_importance(),
        hyperparameters=trainer.params,
        status="candidate"
    )
    registry.register_model(model_path, metadata)

    print(f"Model registered: {model_id}")
    print(f"AUC: {metrics.auc_score:.4f}")
else:
    print("Model did not pass quality thresholds")
```

---

## A/B Testing Workflow

### 1. Deploy Challenger Model

```python
from ml_pipeline.inference_server import InferenceServer

server = InferenceServer(registry_path="models/registry", enable_ab_testing=True)

# Set challenger to receive 10% of traffic
server.set_challenger_model("xgboost_v2026.02.03.140530")

await server.serve()
```

### 2. Monitor Performance

Monitor metrics in Grafana:
- Prediction latency (champion vs challenger)
- Model accuracy (champion vs challenger)
- Traffic distribution

### 3. Gradual Rollout

```python
from ml_pipeline.ab_testing.traffic_splitter import GradualRollout

rollout = GradualRollout(
    initial_traffic=0.1,   # Start at 10%
    step_percentage=0.1,   # Increase by 10% per step
    max_traffic=1.0        # Up to 100%
)

# Every 24 hours, increase traffic if metrics are good
for step in range(10):
    new_traffic = rollout.increase_traffic()
    print(f"Step {step+1}: {new_traffic*100:.0f}% traffic")

    # Update traffic split
    model_a_traffic, model_b_traffic = rollout.get_current_split()
    server.traffic_splitter.update_traffic_split(model_a_traffic, model_b_traffic)

    # Wait 24 hours
    await asyncio.sleep(86400)

    if rollout.is_complete():
        print("Rollout complete!")
        break
```

### 4. Promote to Champion

```python
from ml_pipeline.model_registry import ModelRegistry

registry = ModelRegistry("models/registry")

# Promote new model to champion
registry.promote_to_champion("xgboost_v2026.02.03.140530")

# Restart inference server to use new champion
```

---

## Monitoring

### Prometheus Metrics

The inference server exposes metrics on port 9091:

```
# Model performance
ml_predictions_total{model_version}
ml_prediction_latency_seconds{model_version}
ml_fraud_detected_total{model_version}

# Traffic distribution
ml_model_a_requests_total
ml_model_b_requests_total

# Data drift
ml_feature_drift{feature_name}
ml_prediction_drift
```

### Grafana Dashboard

See `monitoring/grafana/dashboards/ml-monitoring.json` for the pre-configured dashboard.

---

## Testing

### Unit Tests

```bash
cd services/ml-pipeline
pytest tests/ -v --cov=. --cov-report=html
```

### Integration Tests

```bash
# Start dependencies
docker-compose up -d yugabyte dragonfly

# Run integration tests
pytest tests/integration/ -v
```

---

## Troubleshooting

### Issue: Inference latency >1ms

**Causes:**
- Batch size too small
- Model too complex
- Database queries in hot path

**Solutions:**
- Increase batch size: `batch_size=64`
- Enable feature caching: `cache_enabled=true`
- Profile with `cProfile`

### Issue: Model accuracy degrading

**Causes:**
- Data drift (feature distributions changed)
- Fraud patterns evolved
- Label quality issues

**Solutions:**
- Check data drift metrics
- Retrain model on recent data
- Review labeling process

### Issue: A/B test not showing difference

**Causes:**
- Sample size too small
- Models too similar
- Effect size too small

**Solutions:**
- Increase test duration
- Check confidence intervals
- Review model differences

---

## References

- [PRD Section 3.6](../../docs/PRD.md#36-advanced-ml-detection-p1)
- [XGBoost Documentation](https://xgboost.readthedocs.io/)
- [gRPC Python Guide](https://grpc.io/docs/languages/python/)
- [A/B Testing Best Practices](https://en.wikipedia.org/wiki/A/B_testing)

---

**Maintained by:** VoxGuard Factory System
**Last Updated:** 2026-02-03
