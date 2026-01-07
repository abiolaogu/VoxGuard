# Voice-Switch-IM Integration Files

This directory contains integration files for the Anti-Call Masking fraud detection system with [Voice-Switch-IM](https://github.com/abiolaogu/Voice-Switch-IM).

## LumaDB Integration

The anti-call masking detection system now uses **LumaDB** as the unified database platform, replacing kdb+, Kafka, Redis, and PostgreSQL with a single high-performance database.

### Key Benefits

- **Simplified Architecture**: Single database for time-series, streaming, and storage
- **High Performance**: Sub-millisecond query latency
- **Unified Protocols**: PostgreSQL, Kafka, REST, GraphQL, gRPC all in one
- **Smaller Footprint**: 7.7MB binary replaces multiple database systems

## Files Overview

### Go Backend Files

- `call.go` - Call event and fraud alert data models
- `fraud_handler.go` - HTTP API handlers for fraud detection (connects to LumaDB-based detection service)
- `router.go.patch` - Router configuration

### LumaDB Detection Service

The detection logic is in `/lumadb/` directory:

```python
# Key modules:
api.py          # FastAPI HTTP server
detection.py    # Core detection algorithm
database.py     # LumaDB client (PostgreSQL + Kafka protocols)
models.py       # Data models and SQL schema
config.py       # Configuration settings
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Voice-Switch-IM                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │           LumaDB (Unified Database) :5432/:9092/:8080         │ │
│  │  ┌─────────────────────┐  ┌─────────────────────┐            │ │
│  │  │ Time-Series Storage │  │ Kafka Streaming     │            │ │
│  │  │ - calls table       │  │ - call-events topic │            │ │
│  │  │ - fraud_alerts      │  │ - fraud-alerts topic│            │ │
│  │  │ - detection_stats   │  │                     │            │ │
│  │  └─────────────────────┘  └─────────────────────┘            │ │
│  │                                                               │ │
│  │  Tables: calls, fraud_alerts, blocked_patterns, cooldowns    │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                              │                                      │
│  ┌───────────────────────────▼───────────────────────────────────┐ │
│  │       ACM Detection Service (Python FastAPI) :5001           │ │
│  │  - /acm/call - Process call events                           │ │
│  │  - /acm/alerts - Get fraud alerts                            │ │
│  │  - /acm/threat - Get threat levels                           │ │
│  │  - /acm/stats - Detection statistics                         │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                              │                                      │
│  ┌───────────────────────────▼───────────────────────────────────┐ │
│  │              Carrier API (Go) :8080                           │ │
│  │  - Uses HTTP client to connect to ACM Detection               │ │
│  │  - /api/v1/fraud/* endpoints for HTTP access                  │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

## Configuration

### Environment Variables (carrier-api)

```yaml
# ACM Detection Connection
LUMADB_ENDPOINT: "http://acm-detection:5001"  # ACM detection service

# Kamailio for call disconnect
KAMAILIO_MI_URL: "http://kamailio-sbc:5060"
```

### Detection Parameters

Set via HTTP API:

```bash
# Update configuration
curl -X POST http://acm-detection:5001/acm/config \
  -H "Content-Type: application/json" \
  -d '{"threshold":5,"window_seconds":5}'

# Get current configuration
curl http://acm-detection:5001/acm/config
```

## API Endpoints

### ACM Detection Service (:5001)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/acm/call` | POST | Process single call event |
| `/acm/calls/batch` | POST | Process batch call events |
| `/acm/alerts` | GET | Get fraud alerts |
| `/acm/alerts/{id}` | GET | Get specific alert |
| `/acm/alerts/{id}` | PATCH | Update alert status |
| `/acm/threat` | GET | Get threat level for B-number |
| `/acm/threats` | GET | Get all elevated threats |
| `/acm/stats` | GET | Get detection statistics |
| `/acm/config` | GET/POST | Get/update configuration |
| `/metrics` | GET | Prometheus metrics |

### Carrier API (:8080)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/fraud/events` | POST | Submit call event |
| `/api/v1/fraud/events/batch` | POST | Submit batch events |
| `/api/v1/fraud/disconnect` | POST | Disconnect fraudulent calls |
| `/api/v1/fraud/calls/active` | GET | List active calls |
| `/api/v1/fraud/alerts` | GET | Get fraud alerts |
| `/api/v1/fraud/health` | GET | Fraud subsystem health |

## Testing

```bash
# Check ACM Detection health
curl http://localhost:5001/health

# Check detection stats
curl http://localhost:5001/acm/stats

# Submit test call via ACM Detection directly
curl -X POST http://localhost:5001/acm/call \
  -H "Content-Type: application/json" \
  -d '{"a_number":"A001","b_number":"B999"}'

# Submit via carrier-api
curl -X POST http://localhost:8080/api/v1/fraud/events \
  -H "Content-Type: application/json" \
  -d '{"call_id":"test1","a_number":"A001","b_number":"B999","status":"active"}'

# Get elevated threats
curl http://localhost:5001/acm/threats

# Get recent alerts
curl http://localhost:5001/acm/alerts?minutes=60
```

## Migration from kdb+ Integration

If you were previously running the kdb+-based fraud detection:

1. Replace the `fraud-detection` service with `acm-detection` in docker-compose.yml
2. Add `lumadb` service for the unified database
3. Update `FRAUD_DETECTION_URL` to point to ACM Detection (`http://acm-detection:5001`)
4. Update API paths:
   - `/event` → `/acm/call`
   - `/events/batch` → `/acm/calls/batch`
5. Deploy: `docker-compose up -d --build`

## Docker Compose Example

```yaml
services:
  lumadb:
    image: ghcr.io/abiolaogu/lumadb:latest
    ports:
      - "5432:5432"   # PostgreSQL
      - "9092:9092"   # Kafka
      - "8080:8080"   # REST API
      - "9090:9090"   # Prometheus metrics

  acm-detection:
    build:
      context: ./lumadb
      dockerfile: Dockerfile
    ports:
      - "5001:5001"
    environment:
      - LUMADB_REST_HOST=lumadb
      - LUMADB_PG_HOST=lumadb
      - ACM_THRESHOLD=5
      - ACM_WINDOW_SECONDS=5
    depends_on:
      - lumadb
```

## Performance

| Metric | Value |
|--------|-------|
| Detection Latency | <10ms P99 |
| Throughput | 100K+ calls/second |
| Memory | <4GB for 5-minute window |
| Database Size | 7.7MB (LumaDB binary) |
