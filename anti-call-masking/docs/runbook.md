# Anti-Call Masking Detection System - Operations Runbook

**Version:** 2.0
**Last Updated:** January 2026
**Architecture:** Rust Detection Engine + QuestDB + DragonflyDB + YugabyteDB

---

## Table of Contents
1. [System Overview](#system-overview)
2. [Common Operations](#common-operations)
3. [Incident Response](#incident-response)
4. [Troubleshooting](#troubleshooting)
5. [Maintenance Procedures](#maintenance-procedures)
6. [Performance Tuning](#performance-tuning)
7. [NCC Compliance Operations](#ncc-compliance-operations)

---

## System Overview

### Architecture
```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   SIP Clients   │────>│    OpenSIPS      │────>│  ACM Detection  │
│                 │     │  (MI Interface)  │     │  Engine (Rust)  │
│                 │<────│                  │<────│  (port 8080)    │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                                                         │
                        ┌────────────────────────────────┼────────────────────────────────┐
                        │                                │                                │
                        ▼                                ▼                                ▼
               ┌─────────────────┐              ┌─────────────────┐              ┌─────────────────┐
               │   DragonflyDB   │              │    QuestDB      │              │   YugabyteDB    │
               │  (Real-time     │              │  (Time-series   │              │  (Persistent    │
               │   Cache)        │              │   Analytics)    │              │   Storage)      │
               │  port 6379      │              │  ports 8812,    │              │  port 5433      │
               └─────────────────┘              │  9009, 9000     │              └─────────────────┘
                                                └─────────────────┘
```

### Key Ports
| Port | Service | Protocol |
|------|---------|----------|
| 8080 | ACM Detection Engine API | HTTP/REST |
| 9090 | ACM Metrics (Prometheus) | HTTP |
| 5060 | OpenSIPS SIP | UDP/TCP |
| 8888 | OpenSIPS MI HTTP | HTTP |
| 6379 | DragonflyDB | Redis Protocol |
| 8812 | QuestDB PostgreSQL Wire | PostgreSQL |
| 9009 | QuestDB ILP | InfluxDB Line Protocol |
| 9000 | QuestDB Web Console | HTTP |
| 5433 | YugabyteDB YSQL | PostgreSQL |
| 8123 | ClickHouse HTTP | HTTP |

### Critical Thresholds
| Metric | Warning | Critical |
|--------|---------|----------|
| P99 Latency | 1ms | 5ms |
| Memory (per container) | 3GB | 4GB |
| DragonflyDB Memory | 4GB | 5GB |
| Detection Rate | 99.5% | 99.0% |
| Alert Rate | 10/min | 50/min |
| CPS (Calls per Second) | 100K | 150K |

---

## Common Operations

### Starting the System

```bash
# Docker Compose deployment (recommended)
cd /path/to/anti-call-masking
docker-compose up -d

# Verify all services are healthy
docker-compose ps

# Check logs
docker-compose logs -f acm-engine
```

### Stopping the System

```bash
# Graceful shutdown
docker-compose down

# Force stop (if unresponsive)
docker-compose down --timeout 30
```

### Checking System Status

```bash
# API Health Check
curl http://localhost:8080/health

# Detailed Status
curl http://localhost:8080/api/v1/status

# Prometheus Metrics
curl http://localhost:9090/metrics

# DragonflyDB Connection
redis-cli -h localhost -p 6379 ping

# QuestDB Health
curl http://localhost:9003

# YugabyteDB Status
psql -h localhost -p 5433 -U opensips -d opensips -c "SELECT 1"
```

### Managing Configuration

```bash
# View current config
curl http://localhost:8080/api/v1/config

# Update detection threshold (live)
curl -X PATCH http://localhost:8080/api/v1/config \
  -H "Content-Type: application/json" \
  -d '{"detection_threshold": 7}'

# Update detection window (live)
curl -X PATCH http://localhost:8080/api/v1/config \
  -H "Content-Type: application/json" \
  -d '{"detection_window_seconds": 3}'
```

### Managing Whitelist

```bash
# View current whitelist
curl http://localhost:8080/api/v1/whitelist

# Add B-number to whitelist
curl -X POST http://localhost:8080/api/v1/whitelist \
  -H "Content-Type: application/json" \
  -d '{"b_number": "+2348012345678", "reason": "Call center"}'

# Remove from whitelist
curl -X DELETE http://localhost:8080/api/v1/whitelist/+2348012345678
```

### Manual Intervention

```bash
# Disconnect active calls to a B-number
curl -X POST http://localhost:8080/api/v1/fraud/disconnect \
  -H "Content-Type: application/json" \
  -d '{"b_number": "+2348012345678", "reason": "manual_intervention"}'

# Block a pattern
curl -X POST http://localhost:8080/api/v1/blocks \
  -H "Content-Type: application/json" \
  -d '{"pattern": "+234801*", "duration_hours": 24}'

# View recent alerts
curl "http://localhost:8080/api/v1/fraud/alerts?limit=10"
```

---

## Incident Response

### INC-001: High Detection Latency

**Symptoms:**
- P99 latency > 5ms
- Alert: "Detection latency exceeds threshold"
- Grafana shows latency spike

**Diagnosis:**
```bash
# Check current metrics
curl http://localhost:9090/metrics | grep acm_detection_latency

# Check DragonflyDB latency
redis-cli -p 6379 --latency

# Check container resources
docker stats acm-engine dragonfly questdb
```

**Resolution:**
1. If DragonflyDB latency high:
   ```bash
   # Check memory usage
   redis-cli -p 6379 INFO memory

   # Trigger background save if needed
   redis-cli -p 6379 BGSAVE
   ```
2. If detection engine memory high:
   ```bash
   # Restart detection engine
   docker-compose restart acm-engine
   ```
3. If QuestDB slow:
   ```bash
   # Check active queries
   curl "http://localhost:9000/exec?query=SELECT%20*%20FROM%20sys.query_activity"
   ```

### INC-002: OpenSIPS Connection Lost

**Symptoms:**
- Alert: "OpenSIPS disconnected"
- No new events being processed
- Dashboard shows connection status = 0

**Diagnosis:**
```bash
# Check OpenSIPS is running
docker-compose ps opensips

# Check MI interface
curl http://localhost:8888/mi/version

# Check logs
docker-compose logs --tail=100 opensips
```

**Resolution:**
1. Verify network connectivity:
   ```bash
   docker-compose exec acm-engine ping opensips
   ```
2. Restart OpenSIPS:
   ```bash
   docker-compose restart opensips
   ```
3. Force reconnection from detection engine:
   ```bash
   curl -X POST http://localhost:8080/api/v1/reconnect/opensips
   ```

### INC-003: High Alert Volume

**Symptoms:**
- Alerts/minute > 50
- Possible mass attack or false positive storm

**Diagnosis:**
```bash
# Get recent alerts
curl "http://localhost:8080/api/v1/fraud/alerts?minutes=30"

# Analyze B-numbers under attack
curl "http://localhost:8080/api/v1/analytics/top-targets?minutes=30"
```

**Resolution:**
1. If legitimate attack, monitor and let system handle
2. If false positives:
   ```bash
   # Identify pattern and whitelist
   curl -X POST http://localhost:8080/api/v1/whitelist \
     -H "Content-Type: application/json" \
     -d '{"b_number": "+2348012345678", "reason": "False positive - call center"}'
   ```
3. If threshold too sensitive:
   ```bash
   curl -X PATCH http://localhost:8080/api/v1/config \
     -H "Content-Type: application/json" \
     -d '{"detection_threshold": 7}'
   ```

### INC-004: Memory Critical

**Symptoms:**
- Container memory > 4GB
- OOM warnings in logs

**Resolution:**
1. Restart affected service:
   ```bash
   docker-compose restart acm-engine
   ```
2. Clear DragonflyDB cache if needed:
   ```bash
   redis-cli -p 6379 FLUSHDB
   ```
3. Check for memory leaks:
   ```bash
   docker-compose logs acm-engine | grep -i "memory\|oom"
   ```

### INC-005: NCC SFTP Upload Failed

**Symptoms:**
- Daily report not uploaded
- Alert: "NCC SFTP upload failed"

**Diagnosis:**
```bash
# Check SFTP uploader logs
docker-compose logs --tail=100 ncc-sftp-uploader

# Verify SFTP connectivity
docker-compose exec ncc-sftp-uploader sftp -o BatchMode=yes ${NCC_SFTP_HOST}
```

**Resolution:**
1. Check credentials:
   ```bash
   # Verify environment variables
   docker-compose exec ncc-sftp-uploader env | grep NCC
   ```
2. Manual upload:
   ```bash
   docker-compose exec ncc-sftp-uploader /scripts/manual-upload.sh
   ```
3. Contact NCC if their server is down

---

## Troubleshooting

### No Alerts Generated

1. Check detection is enabled:
   ```bash
   curl http://localhost:8080/api/v1/config | jq '.detection_enabled'
   ```
2. Check events are being received:
   ```bash
   curl http://localhost:9090/metrics | grep acm_events_received_total
   ```
3. Check threshold settings:
   ```bash
   curl http://localhost:8080/api/v1/config | jq '.detection_threshold'
   ```
4. Verify DragonflyDB connectivity:
   ```bash
   redis-cli -p 6379 ping
   ```

### False Positives

1. Identify patterns:
   ```bash
   curl "http://localhost:8080/api/v1/fraud/alerts?status=new&limit=50"
   ```
2. Common false positives:
   - Conference call setups
   - Call center campaigns
   - IVR callback systems
3. Add to whitelist as needed

### Disconnect Commands Failing

1. Check OpenSIPS connection:
   ```bash
   curl http://localhost:8080/api/v1/status | jq '.opensips_connected'
   ```
2. Check action queue:
   ```bash
   curl http://localhost:8080/api/v1/actions/queue
   ```
3. Verify call IDs are valid

---

## Maintenance Procedures

### Daily Health Check

```bash
#!/bin/bash
# Daily health check script

echo "=== ACM Daily Health Check ==="
echo "Date: $(date)"

# API Health
echo -n "API Health: "
curl -s http://localhost:8080/health | jq -r '.status'

# Container Status
echo "Container Status:"
docker-compose ps

# Key Metrics
echo "Key Metrics:"
curl -s http://localhost:9090/metrics | grep -E "acm_detection_latency_p99|acm_alerts_total|acm_calls_processed"

# Disk Usage
echo "Disk Usage:"
df -h /var/lib/docker
```

### Weekly Maintenance

1. **Review and archive old data:**
   ```bash
   # Archive alerts older than 30 days
   curl -X POST http://localhost:8080/api/v1/maintenance/archive-alerts?days=30
   ```

2. **Review blocked patterns:**
   ```bash
   curl http://localhost:8080/api/v1/blocks?active=true
   ```

3. **Check storage usage:**
   ```bash
   docker-compose exec clickhouse clickhouse-client --query="SELECT database, table, formatReadableSize(sum(bytes)) FROM system.parts GROUP BY database, table"
   ```

### Monthly Maintenance

1. **Rotate logs:**
   ```bash
   docker-compose exec acm-engine logrotate /etc/logrotate.d/acm
   ```

2. **Update containers (if new versions):**
   ```bash
   docker-compose pull
   docker-compose up -d
   ```

3. **Review and update thresholds based on traffic patterns**

### Backup Procedures

```bash
# Backup YugabyteDB
docker-compose exec yugabyte ysql_dump -U opensips opensips > backup_$(date +%Y%m%d).sql

# Backup configuration
cp docker-compose.yml docker-compose.yml.bak
cp config/prometheus.yml config/prometheus.yml.bak

# Backup ClickHouse data
docker-compose exec clickhouse clickhouse-client --query="BACKUP DATABASE acm TO Disk('backups', 'acm_$(date +%Y%m%d)')"
```

### Recovery Procedures

```bash
# Restore YugabyteDB
docker-compose exec -T yugabyte ysql -U opensips opensips < backup_20260129.sql

# Restore from full backup
docker-compose down
# Restore volume data
docker-compose up -d
```

---

## Performance Tuning

### For Higher Throughput

```bash
# Increase detection engine workers
docker-compose exec acm-engine env ACM_WORKER_THREADS=8

# Increase DragonflyDB threads
# In docker-compose.yml, update dragonfly command:
# --proactor_threads=8
```

### For Lower Latency

```bash
# Reduce detection window
curl -X PATCH http://localhost:8080/api/v1/config \
  -d '{"detection_window_seconds": 3}'

# Enable aggressive caching
curl -X PATCH http://localhost:8080/api/v1/config \
  -d '{"cache_ttl_seconds": 1}'
```

### For Lower Memory

```bash
# Reduce DragonflyDB max memory
# In docker-compose.yml: --maxmemory=2gb

# Reduce detection window
curl -X PATCH http://localhost:8080/api/v1/config \
  -d '{"detection_window_seconds": 3}'
```

### Scaling Guidelines

| CPS | Recommended Config |
|-----|-------------------|
| <50K | Default settings |
| 50K-100K | window=3s, workers=4 |
| 100K-150K | window=3s, workers=8, dragonfly=8GB |
| >150K | Consider horizontal scaling with load balancer |

---

## NCC Compliance Operations

### Daily Report Generation

Reports are automatically generated and uploaded daily at 01:00 AM WAT.

```bash
# Check last upload status
docker-compose logs --tail=50 ncc-sftp-uploader | grep -i upload

# Manual report generation
docker-compose exec ncc-sftp-uploader /scripts/generate-daily-report.sh

# View generated reports
docker-compose exec ncc-sftp-uploader ls -la /var/acm/reports/
```

### ATRS Integration Status

```bash
# Check ATRS API connectivity
curl -X GET http://localhost:8080/api/v1/ncc/atrs/status

# Verify ATRS credentials
curl -X POST http://localhost:8080/api/v1/ncc/atrs/verify
```

### Monthly Compliance Report

```bash
# Generate monthly compliance summary
curl -X POST "http://localhost:8080/api/v1/ncc/reports/monthly?year=2026&month=01"

# Export for NCC submission
curl -X GET "http://localhost:8080/api/v1/ncc/reports/monthly/2026-01/export" -o ncc_monthly_202601.csv
```

---

## Appendix: Quick Reference

### API Endpoints
```
GET  /health              - Liveness probe
GET  /api/v1/status       - Detailed status
GET  /api/v1/config       - Configuration
PATCH /api/v1/config      - Update config
GET  /api/v1/fraud/alerts - List alerts
POST /api/v1/fraud/disconnect - Disconnect calls
GET  /api/v1/whitelist    - View whitelist
POST /api/v1/whitelist    - Add to whitelist
```

### Docker Commands
```bash
docker-compose ps          # Service status
docker-compose logs -f     # Follow all logs
docker-compose restart X   # Restart service X
docker-compose exec X bash # Shell into container
```

### Emergency Contacts
- On-call: [Configure in deployment]
- Escalation: [Configure in deployment]
- NCC Contact: [Configure based on ICL agreement]
- Carrier NOC: [Configure in deployment]

---

**Document Version:** 2.0
**Classification:** Internal Operations
