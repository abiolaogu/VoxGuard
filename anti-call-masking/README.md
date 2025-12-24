# Anti-Call Masking Detection System

Real-time fraud detection system using **LumaDB** to identify and prevent call masking attacks in VoIP networks.

## Overview

Call masking fraud occurs when attackers use multiple originating phone numbers (A-numbers) to obscure the true source of calls to a target number (B-number). This system detects **multicall masking attacks** where 5+ distinct callers contact the same recipient within a 5-second window.

### Detection Rule

| Parameter | Value | Description |
|-----------|-------|-------------|
| Window | 5 seconds | Sliding time window |
| Threshold | 5 | Minimum distinct A-numbers |
| Action | Disconnect | Terminate all flagged calls |

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   SIP Clients   │────>│  Voice Switch    │────>│  LumaDB Fraud   │
│                 │     │  (FreeSWITCH/    │     │  Detection      │
│                 │<────│   Kamailio)      │<────│  Engine         │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                        Call Events (ESL)        Disconnect Commands
```

## LumaDB - Unified Database Platform

This system uses [LumaDB](https://github.com/abiolaogu/LumaDB) as a unified database platform that replaces:

- **kdb+/q** - Time-series processing
- **Kafka/Redpanda** - Message streaming
- **Redis** - Caching
- **PostgreSQL** - Data storage

### LumaDB Features

| Protocol | Port | Description |
|----------|------|-------------|
| PostgreSQL | 5432 | SQL queries via wire protocol |
| Kafka | 9092 | 100% Kafka-compatible streaming |
| REST API | 8080 | HTTP endpoints |
| GraphQL | 4000 | Query language |
| gRPC | 50051 | High-performance RPC |
| Prometheus | 9090 | Metrics endpoint |

## Quick Start

### Prerequisites

- **Docker & Docker Compose** (recommended)
- **Python 3.11+** (for local development)

### Installation

```bash
# Clone the repository
git clone https://github.com/abiolaogu/Anti_Call-Masking.git
cd Anti_Call-Masking/anti-call-masking

# Start with Docker (recommended)
docker-compose up -d

# Verify services are running
docker-compose ps
```

### Verify Installation

```bash
# Health check
curl http://localhost:5001/health

# Get detection statistics
curl http://localhost:5001/acm/stats

# Submit a test call event
curl -X POST http://localhost:5001/acm/call \
  -H "Content-Type: application/json" \
  -d '{"a_number": "A001", "b_number": "B999"}'

# Get recent alerts
curl http://localhost:5001/acm/alerts?minutes=10
```

## Directory Structure

```
anti-call-masking/
├── lumadb/                   # LumaDB-based detection service
│   ├── api.py                # FastAPI HTTP server
│   ├── detection.py          # Core detection algorithm
│   ├── database.py           # LumaDB client (unified interface)
│   ├── models.py             # Data models and SQL schema
│   ├── config.py             # Configuration settings
│   ├── requirements.txt      # Python dependencies
│   └── Dockerfile            # Container definition
├── frontend/                 # React dashboard
├── mobile/                   # Flutter mobile app
├── integration/              # Voice switch integration
├── config/
│   ├── lumadb.yaml           # LumaDB configuration
│   └── prometheus.yml        # Metrics configuration
├── docker-compose.yml        # Container orchestration
└── README.md
```

## Configuration

### Detection Settings

Configure via environment variables or API:

| Variable | Default | Description |
|----------|---------|-------------|
| `ACM_WINDOW_SECONDS` | 5 | Sliding time window |
| `ACM_THRESHOLD` | 5 | Min distinct A-numbers |
| `ACM_COOLDOWN_SECONDS` | 30 | Alert cooldown period |
| `ACM_AUTO_DISCONNECT` | false | Auto-terminate calls |
| `ACM_AUTO_BLOCK` | true | Auto-block patterns |

### LumaDB Connection

```yaml
# config/lumadb.yaml
storage:
  engine: lsm
  data_dir: /data
  wal:
    enabled: true

kafka:
  port: 9092
  num_partitions: 3
  retention_hours: 168

query:
  result_cache_size_mb: 128
  enable_parallel_scan: true
```

### Runtime Configuration

```bash
# Update detection settings via API
curl -X POST http://localhost:5001/acm/config \
  -H "Content-Type: application/json" \
  -d '{"threshold": 5, "window_seconds": 5}'

# Get current configuration
curl http://localhost:5001/acm/config
```

## API Reference

### Call Processing

```bash
# Process single call event
POST /acm/call
{
  "a_number": "2347011111111",
  "b_number": "2348012345678",
  "source_ip": "192.168.1.100",
  "switch_id": "switch-01",
  "call_id": "uuid-123"
}

# Response
{
  "detected": false,
  "b_number": "2348012345678",
  "call_count": 1,
  "distinct_a_count": 1,
  "window_seconds": 5,
  "threshold": 5
}

# Process batch events
POST /acm/calls/batch
{
  "events": [...]
}
```

### Alerts

```bash
# Get recent alerts
GET /acm/alerts?minutes=60

# Get specific alert
GET /acm/alerts/{alert_id}

# Update alert status
PATCH /acm/alerts/{alert_id}
{
  "status": "investigating",
  "notes": "Under review"
}
```

### Threat Levels

```bash
# Get threat level for B-number
GET /acm/threat?b_number=2348012345678

# Get all elevated threats
GET /acm/threats
```

### Statistics

```bash
# Get detection stats
GET /acm/stats

# Response
{
  "total_calls": 125000,
  "total_alerts": 47,
  "detection_rate": 99.8,
  "avg_latency_ms": 1.2
}
```

## Docker Deployment

### Basic (Detection Only)

```bash
docker-compose up -d lumadb acm-detection
```

### With FreeSWITCH Simulator

```bash
docker-compose --profile with-simulator up -d
```

### With Monitoring Stack

```bash
docker-compose --profile monitoring up -d
# Access Grafana at http://localhost:3000 (admin/admin)
```

### With Frontend Dashboard

```bash
docker-compose --profile with-frontend up -d
# Access dashboard at http://localhost:5173
```

### Full Stack

```bash
docker-compose --profile with-simulator --profile monitoring --profile with-frontend up -d
```

## Performance Targets

| Metric | Target | Notes |
|--------|--------|-------|
| Detection Latency | <10ms | P99 |
| Throughput | 100K+ CPS | Single node |
| Memory | <4GB | 5-minute window |
| Detection Rate | >99.9% | True positives |
| False Positive Rate | <0.1% | |

## Switch Integration

### FreeSWITCH (ESL)

```bash
# FreeSWITCH event_socket.conf.xml
<configuration name="event_socket.conf">
  <settings>
    <param name="listen-ip" value="0.0.0.0"/>
    <param name="listen-port" value="8021"/>
    <param name="password" value="ClueCon"/>
  </settings>
</configuration>
```

Events subscribed:
- `CHANNEL_CREATE` - Call setup
- `CHANNEL_ANSWER` - Call answered
- `CHANNEL_HANGUP` - Call terminated

### Voice-Switch-IM Integration

See [integration/voice-switch-im/README.md](integration/voice-switch-im/README.md) for Voice-Switch-IM integration details.

## Monitoring

### Prometheus Metrics (Port 5001/metrics)

- `acm_calls_processed_total`
- `acm_alerts_generated_total`
- `acm_detection_latency_seconds`

### LumaDB Metrics (Port 9090)

LumaDB exposes Prometheus metrics at `:9090/metrics`:
- Storage metrics
- Query performance
- Kafka consumer lag
- Cache hit rates

### Health Check

```bash
curl http://localhost:5001/health
# Returns: status, version, database connection, stats
```

## Frontend Dashboard

React-based dashboard for real-time monitoring:

```bash
cd frontend
npm install
npm run dev
# Access at http://localhost:5173
```

Features:
- Real-time alert notifications
- Threat level visualization
- Call traffic analytics
- Alert management workflow

## Mobile App

Flutter mobile app for on-the-go monitoring:

```bash
cd mobile
flutter pub get
flutter run
```

Features:
- Push notifications for critical alerts
- Quick alert triage
- Offline-capable

## Troubleshooting

### Common Issues

**No alerts generated:**
1. Check threshold: `curl http://localhost:5001/acm/config`
2. Verify LumaDB connection: `curl http://localhost:5001/health`
3. Review cooldown settings

**High latency:**
1. Check LumaDB resources: `docker stats lumadb`
2. Verify query cache settings in `config/lumadb.yaml`
3. Monitor Prometheus metrics

**LumaDB connection fails:**
1. Verify container is running: `docker-compose ps`
2. Check logs: `docker-compose logs lumadb`
3. Verify port bindings

### Debug Mode

```bash
# Enable debug logging
export LOG_LEVEL=DEBUG
docker-compose up -d acm-detection

# View logs
docker-compose logs -f acm-detection
```

## Security Considerations

- **Network Isolation**: Run detection engine in isolated network segment
- **Authentication**: Enable LumaDB authentication in production
- **Access Control**: Restrict API port access
- **Audit Logging**: All actions logged with timestamps
- **Data Retention**: Configure automatic cleanup in LumaDB

## Contributing

1. Fork the repository
2. Create a feature branch
3. Run tests: `pytest lumadb/tests/`
4. Submit pull request

## License

MIT License - See LICENSE file

## References

- [LumaDB](https://github.com/abiolaogu/LumaDB)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [FreeSWITCH ESL](https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Client-and-Developer-Interfaces/Event-Socket-Library/)
- [Kamailio MI](https://www.kamailio.org/docs/modules/stable/modules/mi_fifo.html)
- [SIP RFC 3261](https://tools.ietf.org/html/rfc3261)
