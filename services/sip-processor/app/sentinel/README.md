# Sentinel Anti-Call Masking Engine

## Overview

Sentinel is a high-performance batch processing and analysis engine designed to detect SIM Box fraud (CLI Spoofing) through comprehensive analysis of Call Detail Records (CDR) and historical patterns.

## Architecture

```
┌─────────────────────────────────────────────────┐
│            Sentinel Engine Components           │
├─────────────────────────────────────────────────┤
│ • CDR Ingestion      (parser.py, routes.py)    │
│ • Pattern Detection  (detector.py)              │
│ • Alert Management   (database.py, models.py)   │
│ • Mock Data Gen      (mock_data.py)             │
└─────────────────────────────────────────────────┘
```

## Features

### Phase 1: Foundation ✅
- ✅ CDR CSV ingestion with validation
- ✅ Database schema for call records and alerts
- ✅ Basic API endpoints (ingest, alerts, health)
- ✅ Unit tests for parser module

### Phase 2: Detection Engine ✅
- ✅ SDHF (Short Duration High Frequency) detection
- ✅ Alert generation with severity levels
- ✅ Mock CDR data generator (5K records)
- ✅ Comprehensive unit tests for detector

### Phase 3: Real-Time & Integration ✅
- ✅ Real-time event receiver endpoint
- ✅ WebSocket alert notifications
- ✅ Risk scoring for real-time calls
- ✅ End-to-end integration tests

### Phase 4: Production Hardening ✅
- ✅ Performance optimization (caching, connection pooling, batch processing)
- ✅ Production deployment configs (Docker, Kubernetes, monitoring)
- ✅ Monitoring & alerting setup (Prometheus, Grafana)
- ✅ Production documentation (deployment guide, operations runbook)

## API Endpoints

### 1. CDR Ingestion
```bash
POST /api/v1/sentinel/ingest
Content-Type: multipart/form-data

# Upload CDR CSV file
curl -X POST http://localhost:8000/api/v1/sentinel/ingest \
  -F "cdr_file=@sample_cdr.csv"
```

**Response:**
```json
{
  "status": "success",
  "records_processed": 5000,
  "records_inserted": 4998,
  "duplicates_skipped": 2,
  "processing_time_seconds": 12.5
}
```

### 2. SDHF Detection
```bash
POST /api/v1/sentinel/detect/sdhf
Content-Type: application/json

# Run SDHF detection with custom parameters
curl -X POST http://localhost:8000/api/v1/sentinel/detect/sdhf \
  -H "Content-Type: application/json" \
  -d '{
    "time_window_hours": 24,
    "min_unique_destinations": 50,
    "max_avg_duration_seconds": 3.0
  }'
```

**Response:**
```json
{
  "status": "success",
  "alerts_generated": 3,
  "alert_ids": [101, 102, 103],
  "suspects": ["+2348012345678", "+2349087654321", "+2347065432109"]
}
```

### 3. Get Alerts
```bash
GET /api/v1/sentinel/alerts?severity=HIGH&reviewed=false&limit=50

# Retrieve fraud alerts with filtering
curl http://localhost:8000/api/v1/sentinel/alerts?severity=HIGH&reviewed=false
```

**Response:**
```json
{
  "status": "success",
  "count": 3,
  "alerts": [
    {
      "id": 101,
      "alert_type": "SDHF_SIMBOX",
      "suspect_number": "+2348012345678",
      "alert_severity": "HIGH",
      "evidence_summary": "Caller made 120 calls to 95 unique destinations...",
      "call_count": 120,
      "unique_destinations": 95,
      "avg_duration_seconds": 2.2,
      "detection_rule": "SDHF_001",
      "created_at": "2026-01-23T00:15:30Z",
      "reviewed": false
    }
  ]
}
```

### 4. Update Alert
```bash
PATCH /api/v1/sentinel/alerts/{alert_id}
Content-Type: application/json

# Mark alert as reviewed with notes
curl -X PATCH http://localhost:8000/api/v1/sentinel/alerts/101 \
  -H "Content-Type: application/json" \
  -d '{
    "reviewed": true,
    "reviewer_notes": "Confirmed SIM Box - escalated to security team"
  }'
```

### 5. Health Check
```bash
GET /api/v1/sentinel/health

curl http://localhost:8000/api/v1/sentinel/health
```

### 6. Real-Time Call Event (Phase 3)
```bash
POST /api/v1/sentinel/events/call
Content-Type: application/json

# Submit real-time call event for immediate analysis
curl -X POST http://localhost:8000/api/v1/sentinel/events/call \
  -H "Content-Type: application/json" \
  -d '{
    "caller_number": "+2348012345678",
    "callee_number": "+2349087654321",
    "duration_seconds": 2,
    "call_direction": "outbound",
    "timestamp": "2024-01-15T14:32:15Z"
  }'
```

**Response:**
```json
{
  "status": "accepted",
  "event_id": "evt_abc123def456",
  "risk_score": 0.73
}
```

**Risk Score Calculation:**
- Analyzes caller's pattern in last 24 hours
- Factors: unique destinations (50%), short duration (30%), call frequency (20%)
- 0.0 = low risk, 1.0 = high risk
- Thresholds: <0.3 low, 0.3-0.6 medium, 0.6-0.8 high, >0.8 critical

### 7. WebSocket Alert Stream (Phase 3)
```javascript
// Connect to WebSocket for real-time alert notifications
const ws = new WebSocket('ws://localhost:8000/api/v1/sentinel/ws/alerts');

ws.onopen = () => {
    console.log('Connected to Sentinel alert stream');
};

ws.onmessage = (event) => {
    const message = JSON.parse(event.data);

    if (message.type === 'alert') {
        console.log('New fraud alert:', message.data);
        // Update dashboard UI
        displayAlert(message.data);
    } else if (message.type === 'heartbeat') {
        console.log('Connection alive');
    } else if (message.type === 'connected') {
        console.log('Welcome:', message.message);
    }
};

ws.onerror = (error) => {
    console.error('WebSocket error:', error);
};

ws.onclose = () => {
    console.log('Connection closed - attempting reconnect...');
    setTimeout(connectWebSocket, 5000);
};
```

**Alert Message Format:**
```json
{
  "type": "alert",
  "timestamp": "2024-01-15T14:32:15Z",
  "data": {
    "id": 123,
    "alert_type": "SDHF_SIMBOX",
    "suspect_number": "+2348012345678",
    "alert_severity": "HIGH",
    "evidence_summary": "75 unique destinations, avg 2.1s duration",
    "call_count": 75,
    "unique_destinations": 75,
    "avg_duration_seconds": 2.1,
    "detection_rule": "SDHF_001",
    "created_at": "2024-01-15T14:32:15Z"
  }
}
```

## SDHF Detection Algorithm

**Rule Definition:** Flag numbers making > 50 calls to unique destinations within 24 hours where average call duration < 3 seconds.

**Severity Calculation:**
- **CRITICAL**: ≥200 unique destinations, avg duration ≤1.5s
- **HIGH**: ≥100 unique destinations, avg duration ≤2.0s
- **MEDIUM**: ≥75 unique destinations OR avg duration ≤1.0s
- **LOW**: Just above threshold

**SQL Query:**
```sql
WITH caller_stats AS (
    SELECT
        caller_number,
        COUNT(*) as call_count,
        COUNT(DISTINCT callee_number) as unique_destinations,
        AVG(duration_seconds) as avg_duration
    FROM call_records
    WHERE call_timestamp >= NOW() - INTERVAL '24 hours'
    GROUP BY caller_number
    HAVING
        COUNT(DISTINCT callee_number) > 50
        AND AVG(duration_seconds) < 3
)
SELECT * FROM caller_stats
ORDER BY unique_destinations DESC
```

## Mock Data Generator

Generate realistic CDR test data with embedded SIM Box patterns:

```bash
# From app/sentinel directory
python mock_data.py [output_file] [total_records] [simbox_callers] [calls_per_simbox]

# Example: Generate 5000 records with 3 SIM Box callers
python mock_data.py test_data.csv 5000 3 75
```

**Programmatic Usage:**
```python
from app.sentinel.mock_data import MockCDRGenerator

generator = MockCDRGenerator(seed=42)

# Generate CSV content
csv_content, simbox_numbers = generator.generate_csv(
    total_records=5000,
    simbox_callers=3,
    simbox_calls_per_caller=75
)

# Save to file
simbox_numbers = generator.save_to_file(
    "mock_cdr.csv",
    total_records=5000,
    simbox_callers=3,
    simbox_calls_per_caller=75
)

print(f"SIM Box test numbers: {simbox_numbers}")
```

**Generated Data Characteristics:**
- **Normal Calls**: 30s - 30min duration, random Nigerian numbers
- **SIM Box Calls**: 1-5s duration, high frequency, many unique destinations
- **Time Distribution**: Spread across 23-hour window
- **Phone Format**: E.164 Nigerian numbers (+234...)

## Database Schema

### call_records
Stores historical CDR data:
```sql
CREATE TABLE call_records (
    id SERIAL PRIMARY KEY,
    call_timestamp TIMESTAMP NOT NULL,
    caller_number VARCHAR(20) NOT NULL,
    callee_number VARCHAR(20) NOT NULL,
    duration_seconds INTEGER NOT NULL,
    call_direction VARCHAR(10),
    termination_cause VARCHAR(50),
    location_code VARCHAR(10),
    processed_at TIMESTAMP DEFAULT NOW(),
    INDEX idx_caller_timestamp (caller_number, call_timestamp)
);
```

### sentinel_fraud_alerts
Stores detected fraud alerts:
```sql
CREATE TABLE sentinel_fraud_alerts (
    id SERIAL PRIMARY KEY,
    alert_type VARCHAR(50) NOT NULL,
    suspect_number VARCHAR(20) NOT NULL,
    alert_severity VARCHAR(20) NOT NULL, -- LOW, MEDIUM, HIGH, CRITICAL
    evidence_summary TEXT NOT NULL,
    call_count INTEGER,
    unique_destinations INTEGER,
    avg_duration_seconds FLOAT,
    detection_rule VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    reviewed BOOLEAN DEFAULT FALSE,
    reviewer_notes TEXT
);
```

## Testing

### Run All Tests
```bash
# From sip-processor directory
pytest tests/sentinel/ -v
```

### Run Specific Test Suites
```bash
# Parser tests (Phase 1)
pytest tests/sentinel/test_parser.py -v

# Detector tests (Phase 2)
pytest tests/sentinel/test_detector.py -v

# Mock data tests (Phase 2)
pytest tests/sentinel/test_mock_data.py -v
```

### Test Coverage
```bash
pytest tests/sentinel/ --cov=app.sentinel --cov-report=html
```

## Development Workflow

### 1. Generate Test Data
```bash
python app/sentinel/mock_data.py test_cdr.csv 5000 3 75
```

### 2. Ingest Data
```bash
curl -X POST http://localhost:8000/api/v1/sentinel/ingest \
  -F "cdr_file=@test_cdr.csv"
```

### 3. Run Detection
```bash
curl -X POST http://localhost:8000/api/v1/sentinel/detect/sdhf \
  -H "Content-Type: application/json" \
  -d '{"time_window_hours": 24, "min_unique_destinations": 50, "max_avg_duration_seconds": 3.0}'
```

### 4. Review Alerts
```bash
curl http://localhost:8000/api/v1/sentinel/alerts?severity=HIGH
```

### 5. Mark as Reviewed
```bash
curl -X PATCH http://localhost:8000/api/v1/sentinel/alerts/1 \
  -H "Content-Type: application/json" \
  -d '{"reviewed": true, "reviewer_notes": "Investigated - confirmed fraud"}'
```

## Module Structure

```
app/sentinel/
├── __init__.py           # Module initialization
├── models.py             # Pydantic models and schemas
├── parser.py             # CDR CSV parsing logic
├── database.py           # Database operations
├── routes.py             # FastAPI endpoints
├── detector.py           # SDHF detection engine (Phase 2)
├── mock_data.py          # Test data generator (Phase 2)
└── README.md             # This file

tests/sentinel/
├── __init__.py
├── test_parser.py        # Parser unit tests (17 tests)
├── test_detector.py      # Detector unit tests (15 tests)
└── test_mock_data.py     # Mock data tests (18 tests)
```

## Performance Benchmarks

**Target Performance (Per PRD):**
- ✅ Ingest 100K CDR records in < 30 seconds
- ✅ SDHF detection scan < 60 seconds for 1M records
- ✅ API response time < 500ms (p95)

**Actual Performance:**
- Ingestion: ~8K records/second (batch size: 1000)
- Detection: SQL-optimized with indexes
- Deduplication: In-memory + database check

## Phase 4: Production Features

### Performance Monitoring

Access performance metrics:

```bash
# Prometheus metrics
curl http://localhost:8000/api/v1/sentinel/metrics

# JSON metrics
curl http://localhost:8000/api/v1/sentinel/metrics/json

# Performance stats with percentiles
curl http://localhost:8000/api/v1/sentinel/performance/stats
```

**Available Metrics:**
- `sentinel_cdr_records_ingested_total` - Total CDR records processed
- `sentinel_alerts_generated_total` - Total fraud alerts generated
- `sentinel_alerts_by_severity_total` - Alerts by severity level
- `sentinel_api_request_duration_seconds` - API latency percentiles
- `sentinel_cache_hit_rate` - Cache effectiveness
- `sentinel_database_pool_utilization` - Connection pool usage
- `sentinel_active_websocket_connections` - Current WebSocket clients
- `sentinel_unreviewed_alerts` - Pending alert count

### Production Deployment

**Docker Production Build:**
```bash
docker build -f Dockerfile.prod -t sentinel-engine:1.0.0 .
docker run -p 8000:8000 \
  -e DATABASE_URL=postgresql://user:pass@postgres:5432/sentinel \
  sentinel-engine:1.0.0
```

**Kubernetes Deployment:**
```bash
# Apply all manifests
kubectl apply -f k8s/

# Check deployment status
kubectl get pods -n anti-call-masking -l app=sentinel-engine

# View logs
kubectl logs -n anti-call-masking -l app=sentinel-engine --tail=100 -f
```

**Key Features:**
- Multi-stage Docker build for optimized image size
- Non-root container user for security
- Horizontal Pod Autoscaler (3-10 replicas)
- Health checks (liveness & readiness probes)
- Resource limits and requests
- Pod anti-affinity for high availability

### Monitoring Setup

**Prometheus Configuration:**
```yaml
scrape_configs:
  - job_name: 'sentinel-engine'
    scrape_interval: 30s
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names:
            - anti-call-masking
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
```

**Grafana Dashboard:**
- Import `monitoring/grafana-dashboard.json`
- Includes 11 panels covering ingestion, alerts, performance, and errors
- Pre-configured alerts for slow responses and high error rates

**Alert Rules:**
- High ingestion error rate (>1/sec for 5min)
- Slow API responses (p95 > 500ms)
- Detection duration exceeds 60 seconds
- Unreviewed alerts backlog (>100)
- Database pool exhaustion (>90% utilization)
- Service down or multiple instances down

See `monitoring/prometheus-rules.yaml` for complete alert definitions.

### Performance Optimization

**Connection Pool Configuration:**
```python
from app.sentinel.performance import PoolConfig

# Production settings
DATABASE_POOL_MIN_SIZE = 10
DATABASE_POOL_MAX_SIZE = 50
BATCH_INSERT_SIZE = 1000
```

**Caching:**
```python
from app.sentinel.performance import cached

@cached(ttl_seconds=300, key_prefix="alerts")
async def get_alerts(severity: str):
    # Results cached for 5 minutes
    return await fetch_alerts(severity)
```

**Performance Monitoring:**
```python
from app.sentinel.performance import monitor_performance

@monitor_performance("detect_sdhf")
async def detect_sdhf_patterns():
    # Automatically tracks duration and records metrics
    pass
```

### Operations

**Production Documentation:**
- [Production Deployment Guide](../../docs/PRODUCTION_DEPLOYMENT.md) - Full deployment instructions
- [Operations Runbook](../../docs/OPERATIONS_RUNBOOK.md) - Troubleshooting and incident response

**Health Checks:**
```bash
# Basic health
curl http://localhost:8000/health

# Detailed health (with component checks)
curl http://localhost:8000/api/v1/sentinel/health
```

**Scaling:**
```bash
# Manual scaling
kubectl scale deployment sentinel-engine --replicas=5 -n anti-call-masking

# HPA will auto-scale based on CPU/memory (70% CPU, 80% memory triggers)
```

## Future Enhancements (v2.0)

### Advanced Detection
- [ ] Geographic anomaly detection
- [ ] Behavioral profiling
- [ ] Machine learning models (XGBoost)
- [ ] Pattern correlation analysis

## Troubleshooting

### Common Issues

**1. Import Errors**
```bash
# Ensure you're in the correct directory
cd anti-call-masking/sip-processor
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
```

**2. Database Connection**
```python
# Ensure database pool is configured in main.py
# The get_db_pool() dependency must be properly injected
```

**3. CSV Parsing Errors**
```bash
# Verify CSV format matches PRD specification
# Required columns: call_date, call_time, caller_number, callee_number, duration_seconds
```

## Contributing

1. Follow existing code patterns and type hints
2. Write unit tests for new features (pytest)
3. Update this README for API changes
4. Use E.164 format for phone numbers
5. Follow PRD specifications

## License

Copyright © 2026 BillyRonks Global. All rights reserved.
