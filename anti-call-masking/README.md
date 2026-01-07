# Anti-Call Masking Detection System

[![LumaDB](https://img.shields.io/badge/LumaDB-Unified%20Platform-blue.svg)](https://github.com/abiolaogu/lumadb)
[![Rust](https://img.shields.io/badge/Rust-1.70%2B-orange.svg)](https://www.rust-lang.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100%2B-009688.svg)](https://fastapi.tiangolo.com)

Real-time fraud detection system for identifying call masking attacks using **LumaDB** unified database platform.
Designed for **sub-millisecond latency** and **horizontal scalability**.

## Overview

Call masking (CLI spoofing) is a technique used by fraudsters to disguise their identity by rotating through multiple caller IDs. This system detects such patterns in real-time with:

- **Sub-millisecond Detection**: LumaDB + Rust + FastAPI powered detection
- **Unified Data Platform**: Single LumaDB instance replaces PostgreSQL, Redis, ClickHouse, and Kafka
- **XGBoost ML Inference**: Machine learning-based masking probability scoring
- **Real-time CDR Metrics**: ASR, ALOC, and Overlap Ratio calculations

### Detection Rule

| Parameter | Value | Description |
|-----------|-------|-------------|
| Window | 5 seconds | Sliding time window |
| Threshold | 5 | Minimum distinct A-numbers |
| ML Threshold | 0.7 | XGBoost masking probability |
| Action | Disconnect | Terminate all flagged calls |

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Voice Switch / SIP Clients                    │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                    ┌───────────▼───────────┐
                    │   SIP Processor       │ Port 8000
                    │   (FastAPI + XGBoost) │
                    └───────────┬───────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐      ┌───────────────┐      ┌───────────────┐
│ Detection     │      │ ACM Detection │      │   LumaDB      │
│ Service       │      │ (Python)      │      │   Unified     │
│ (Rust)        │      │ Port 5001     │      │   Database    │
│ Port 8080     │      └───────┬───────┘      │               │
└───────┬───────┘              │              │ • PostgreSQL  │
        │                      │              │ • Redis       │
        └──────────────────────┴──────────────│ • ClickHouse  │
                                              │ • Kafka       │
                                              │               │
                                              │ Ports:        │
                                              │ 5432 (PG)     │
                                              │ 6379 (Redis)  │
                                              │ 8123 (CH)     │
                                              │ 9092 (Kafka)  │
                                              └───────────────┘
```

## Quick Start

### Prerequisites

- **Docker & Docker Compose** v2.0+
- **8GB RAM** recommended for LumaDB

### Installation

```bash
# Clone the repository
git clone https://github.com/abiolaogu/Anti_Call-Masking.git
cd Anti_Call-Masking/anti-call-masking

# Start with LumaDB (default)
docker-compose up -d

# Verify services
curl http://localhost:8080/health   # Rust detection service
curl http://localhost:8000/health   # SIP processor
curl http://localhost:5001/health   # ACM detection
curl http://localhost:8180/health   # LumaDB REST API
```

### Legacy Mode (Optional)

To use the old stack (ClickHouse + DragonflyDB + PostgreSQL):

```bash
docker-compose --profile legacy up -d
```

## Services

| Service | Port | Description |
|---------|------|-------------|
| **LumaDB** | 5432, 6379, 8123, 9092 | Unified database platform |
| **Detection Service** | 8080 | Rust-based sliding window detection |
| **SIP Processor** | 8000 | FastAPI SIP parsing + XGBoost ML |
| **ACM Detection** | 5001 | Python LumaDB-native detection |
| **Prometheus** | 9091 | Metrics collection (--profile monitoring) |
| **Grafana** | 3000 | Dashboards (--profile monitoring) |

## LumaDB Protocol Compatibility

LumaDB provides wire-compatible protocols for seamless integration:

| Protocol | Port | Replaces |
|----------|------|----------|
| PostgreSQL | 5432 | PostgreSQL 16 |
| Redis | 6379 | Redis 7, DragonflyDB |
| ClickHouse HTTP | 8123 | ClickHouse 23.8 |
| Kafka | 9092 | Kafka, Redpanda |
| REST API | 8180 | Custom APIs |
| GraphQL | 4000 | Hasura, PostGraphile |
| gRPC | 50051 | Custom gRPC |
| Prometheus | 9090 | Native metrics |

## API Endpoints

### SIP Processor (Port 8000)

```bash
# Analyze a call for masking
curl -X POST http://localhost:8000/api/v1/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "call_id": "abc123",
    "a_number": "+12025551234",
    "b_number": "+19876543210",
    "distinct_a_count": 6
  }'

# Get CDR metrics
curl http://localhost:8000/api/v1/metrics/+19876543210
```

### Detection Service (Port 8080)

```bash
# Submit call event
curl -X POST http://localhost:8080/event \
  -H "Content-Type: application/json" \
  -d '{
    "a_number": "+12025551234",
    "b_number": "+19876543210",
    "timestamp": 1704672000,
    "event_type": "INVITE"
  }'
```

## Configuration

### LumaDB Settings (`config/lumadb.yaml`)

```yaml
# PostgreSQL wire protocol
postgres:
  port: 5432
  max_connections: 1000

# Redis wire protocol
redis:
  port: 6379
  max_memory: 1073741824  # 1GB

# ClickHouse HTTP API
clickhouse:
  port: 8123

# Kafka protocol
kafka:
  port: 9092
  retention_ms: 604800000  # 7 days
```

### Detection Settings

```bash
# Environment variables
DETECTION_WINDOW_SECONDS=5    # Sliding window
DETECTION_THRESHOLD=5         # Min distinct A-numbers
MASKING_PROBABILITY_THRESHOLD=0.7  # XGBoost threshold
```

## Directory Structure

```
anti-call-masking/
├── config/
│   ├── lumadb.yaml           # LumaDB configuration
│   └── prometheus-lumadb.yml # Prometheus config
├── detection-service-rust/   # Rust detection service
├── sip-processor/            # FastAPI SIP + XGBoost
├── lumadb/                   # Python LumaDB detection
├── frontend/                 # React dashboard
├── mobile/                   # Flutter mobile app
├── docs/                     # Documentation
├── k8s/                      # Kubernetes manifests
└── docker-compose.yml        # Container orchestration
```

## Monitoring

```bash
# Start with monitoring
docker-compose --profile monitoring up -d

# Access dashboards
open http://localhost:3000  # Grafana (admin/admin)
open http://localhost:9091  # Prometheus
```

## Testing

```bash
# Run SIP processor tests
cd sip-processor
pip install -r requirements.txt
pytest tests/ -v

# Run Rust detection tests
cd detection-service-rust
cargo test
```

## Performance

| Metric | Value |
|--------|-------|
| Detection Latency | < 1ms |
| Throughput | 100K+ events/sec |
| Memory (LumaDB) | 4-8GB |
| Storage | ~1GB per 10M CDRs |

## License

MIT License - see [LICENSE](LICENSE) for details.
