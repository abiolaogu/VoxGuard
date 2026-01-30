# Administrator Manual
## Anti-Call Masking Detection System

**Version:** 2.0
**Last Updated:** January 2026
**Architecture:** Rust + QuestDB + DragonflyDB + YugabyteDB

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [System Architecture](#2-system-architecture)
3. [Deployment](#3-deployment)
4. [Configuration Management](#4-configuration-management)
5. [Database Administration](#5-database-administration)
6. [Monitoring & Observability](#6-monitoring--observability)
7. [Security Administration](#7-security-administration)
8. [Backup & Recovery](#8-backup--recovery)
9. [Scaling & Performance](#9-scaling--performance)
10. [Troubleshooting](#10-troubleshooting)
11. [Maintenance Procedures](#11-maintenance-procedures)
12. [Compliance Administration](#12-compliance-administration)

---

## 1. Introduction

### 1.1 Purpose

This manual provides comprehensive guidance for system administrators responsible for deploying, configuring, monitoring, and maintaining the Anti-Call Masking Detection System.

### 1.2 Target Audience

- System Administrators
- DevOps Engineers
- Database Administrators
- Security Administrators
- Infrastructure Engineers

### 1.3 Prerequisites

- Linux system administration (Ubuntu/RHEL)
- Docker and Kubernetes experience
- PostgreSQL/SQL administration
- Prometheus/Grafana familiarity
- Network security fundamentals

### 1.4 System Requirements

| Component | Minimum | Recommended | Production |
|-----------|---------|-------------|------------|
| CPU | 8 cores | 16 cores | 32 cores |
| Memory | 32 GB | 64 GB | 128 GB |
| Storage | 500 GB SSD | 1 TB NVMe | 2 TB NVMe RAID |
| Network | 1 Gbps | 10 Gbps | 25 Gbps |

---

## 2. System Architecture

### 2.1 Component Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Anti-Call Masking Platform                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────────┐    │
│  │   OpenSIPS      │────▶│   ACM Detection │────▶│   Management API    │    │
│  │   (SIP Proxy)   │     │   Engine (Rust) │     │   (Go)              │    │
│  │   Port 5060     │     │   Port 8080     │     │   Port 8081         │    │
│  └─────────────────┘     └────────┬────────┘     └─────────────────────┘    │
│                                   │                                         │
│           ┌───────────────────────┼───────────────────────┐                │
│           │                       │                       │                 │
│           ▼                       ▼                       ▼                 │
│  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐       │
│  │   DragonflyDB   │     │    QuestDB      │     │   YugabyteDB    │       │
│  │   (Cache)       │     │   (TimeSeries)  │     │   (Persistence) │       │
│  │   Port 6379     │     │   Port 8812     │     │   Port 5433     │       │
│  └─────────────────┘     └─────────────────┘     └─────────────────┘       │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     Monitoring Stack                                 │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐             │   │
│  │  │Prometheus│  │ Grafana  │  │  Homer   │  │ Alertmgr │             │   │
│  │  │ :9091    │  │  :3000   │  │  :9080   │  │  :9093   │             │   │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘             │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Data Flow

```
SIP Client → OpenSIPS → ACM Engine → DragonflyDB (detection)
                                  → QuestDB (real-time analytics)
                                  → YugabyteDB (persistence)
                                  → ClickHouse (historical analytics)
```

### 2.3 Network Requirements

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| External | OpenSIPS | 5060 | UDP/TCP | SIP signaling |
| External | OpenSIPS | 5061 | TCP/TLS | SIP over TLS |
| OpenSIPS | ACM Engine | 8080 | HTTP | Event submission |
| ACM Engine | DragonflyDB | 6379 | Redis | Cache queries |
| ACM Engine | QuestDB | 9009 | ILP | Time-series ingestion |
| ACM Engine | YugabyteDB | 5433 | PostgreSQL | Persistence |
| Prometheus | All services | Various | HTTP | Metrics collection |

---

## 3. Deployment

### 3.1 Docker Compose Deployment

```bash
# Clone repository
git clone https://github.com/yourorg/anti-call-masking.git
cd anti-call-masking

# Create environment file
cp .env.example .env
# Edit .env with your configuration

# Start all services
docker-compose up -d

# Verify services
docker-compose ps

# View logs
docker-compose logs -f
```

### 3.2 Environment Configuration

```bash
# .env file
# Database credentials
YUGABYTE_PASSWORD=your_secure_password_here
CLICKHOUSE_PASSWORD=your_analytics_password_here
GRAFANA_PASSWORD=your_grafana_password_here

# NCC Compliance
NCC_ENABLED=true
NCC_CLIENT_ID=your_ncc_client_id
NCC_CLIENT_SECRET=your_ncc_client_secret
NCC_ICL_LICENSE=ICL-NG-2025-XXXXXX
NCC_SFTP_USER=your_sftp_username

# Security
JWT_SECRET=your_jwt_secret_minimum_32_chars

# Performance tuning
ACM_WORKER_THREADS=4
ACM_BATCH_SIZE=100
```

### 3.3 Kubernetes Deployment

```bash
# Apply namespace
kubectl apply -f k8s/namespace.yaml

# Create secrets
kubectl create secret generic acm-secrets \
  --from-literal=yugabyte-password=$YUGABYTE_PASSWORD \
  --from-literal=clickhouse-password=$CLICKHOUSE_PASSWORD \
  --from-literal=jwt-secret=$JWT_SECRET \
  -n fraud-detection

# Apply configuration
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/

# Verify deployment
kubectl get pods -n fraud-detection
kubectl get services -n fraud-detection
```

### 3.4 Post-Deployment Verification

```bash
# Health checks
curl http://localhost:8080/health
curl http://localhost:8081/health

# Database connectivity
psql -h localhost -p 5433 -U opensips -d opensips -c "SELECT 1"
redis-cli -p 6379 ping

# Metrics endpoint
curl http://localhost:9090/metrics | head -20

# Test detection endpoint
curl -X POST http://localhost:8080/api/v1/fraud/events \
  -H "Content-Type: application/json" \
  -d '{"call_id":"test-123","a_number":"+2348012345678","b_number":"+2348098765432","status":"active"}'
```

---

## 4. Configuration Management

### 4.1 Detection Configuration

Access via Management API or directly in database:

```bash
# View current configuration
curl http://localhost:8080/api/v1/config

# Update detection threshold
curl -X PATCH http://localhost:8080/api/v1/config \
  -H "Content-Type: application/json" \
  -d '{"detection_threshold": 7}'

# Update detection window
curl -X PATCH http://localhost:8080/api/v1/config \
  -H "Content-Type: application/json" \
  -d '{"detection_window_seconds": 3}'
```

### 4.2 Configuration Parameters

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `detection_threshold` | 5 | 3-20 | Distinct A-numbers to trigger alert |
| `detection_window_seconds` | 5 | 1-30 | Time window for detection |
| `auto_disconnect` | true | - | Auto-disconnect fraudulent calls |
| `cooldown_seconds` | 60 | 30-300 | Cooldown between alerts for same B-number |
| `max_batch_size` | 100 | 10-1000 | Maximum events per batch |
| `cache_ttl_seconds` | 10 | 1-60 | DragonflyDB cache TTL |

### 4.3 Whitelist Management

```bash
# View whitelist
curl http://localhost:8080/api/v1/whitelist

# Add to whitelist
curl -X POST http://localhost:8080/api/v1/whitelist \
  -H "Content-Type: application/json" \
  -d '{
    "b_number": "+2348012345678",
    "reason": "Call center - verified",
    "expires_at": "2026-12-31T23:59:59Z"
  }'

# Remove from whitelist
curl -X DELETE http://localhost:8080/api/v1/whitelist/+2348012345678
```

### 4.4 Block Pattern Management

```bash
# View active blocks
curl http://localhost:8080/api/v1/blocks?active=true

# Add block
curl -X POST http://localhost:8080/api/v1/blocks \
  -H "Content-Type: application/json" \
  -d '{
    "pattern": "+234701*",
    "reason": "Known fraud range",
    "duration_hours": 24
  }'

# Remove block
curl -X DELETE http://localhost:8080/api/v1/blocks/{block_id}
```

---

## 5. Database Administration

### 5.1 YugabyteDB Administration

```bash
# Connect to YugabyteDB
docker-compose exec yugabyte ysqlsh -U opensips -d opensips

# Check cluster health
docker-compose exec yugabyte yb-admin \
  --master_addresses yugabyte:7100 get_universe_config

# View table sizes
SELECT
    table_name,
    pg_size_pretty(pg_total_relation_size(quote_ident(table_name)))
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY pg_total_relation_size(quote_ident(table_name)) DESC;

# Vacuum tables
VACUUM ANALYZE;
```

### 5.2 QuestDB Administration

```bash
# Access QuestDB console
# Web UI: http://localhost:9000

# Query via PostgreSQL wire protocol
psql -h localhost -p 8812 -U admin

# Check table sizes
SELECT table_name, designatedTimestamp, partitionBy
FROM tables();

# Drop old partitions (retention management)
ALTER TABLE call_events DROP PARTITION
WHERE timestamp < dateadd('d', -30, now());
```

### 5.3 ClickHouse Administration

```bash
# Connect to ClickHouse
docker-compose exec clickhouse clickhouse-client

# Check database sizes
SELECT
    database,
    table,
    formatReadableSize(sum(bytes)) as size,
    sum(rows) as rows
FROM system.parts
GROUP BY database, table
ORDER BY sum(bytes) DESC;

# Optimize tables
OPTIMIZE TABLE fraud_alerts FINAL;

# Check replication status
SELECT * FROM system.replicas;
```

### 5.4 DragonflyDB Administration

```bash
# Connect to DragonflyDB
redis-cli -p 6379

# Check memory usage
INFO memory

# Check connected clients
INFO clients

# Monitor commands (caution: high traffic)
MONITOR

# Flush database (emergency only)
FLUSHDB
```

---

## 6. Monitoring & Observability

### 6.1 Prometheus Queries

```promql
# Detection latency P99
histogram_quantile(0.99, rate(acm_detection_latency_bucket[5m]))

# Alerts per minute
rate(acm_alerts_total[1m]) * 60

# Calls processed per second
rate(acm_calls_processed_total[1m])

# System uptime
time() - acm_start_time_seconds

# DragonflyDB memory usage
redis_memory_used_bytes / redis_memory_max_bytes * 100
```

### 6.2 Grafana Dashboards

Pre-configured dashboards available at `http://localhost:3000`:

| Dashboard | Purpose |
|-----------|---------|
| ACM Overview | System health and KPIs |
| Detection Performance | Latency and throughput |
| Alert Analytics | Fraud patterns and trends |
| Database Metrics | DB performance and capacity |
| SIP Metrics | OpenSIPS performance |

### 6.3 Log Management

```bash
# View detection engine logs
docker-compose logs -f acm-engine

# Filter for errors
docker-compose logs acm-engine 2>&1 | grep -i error

# View all logs with timestamps
docker-compose logs -t --tail=100

# Export logs to file
docker-compose logs --no-color > /var/log/acm/export_$(date +%Y%m%d).log
```

### 6.4 Health Checks

```bash
# API health endpoint
curl -s http://localhost:8080/health | jq

# Expected response:
{
  "status": "healthy",
  "components": {
    "dragonfly": "connected",
    "questdb": "connected",
    "yugabyte": "connected",
    "opensips": "connected"
  },
  "version": "2.0.0",
  "uptime_seconds": 86400
}
```

---

## 7. Security Administration

### 7.1 TLS Configuration

```yaml
# Configure TLS for OpenSIPS
opensips:
  tls:
    certificate: /etc/opensips/tls/server.crt
    private_key: /etc/opensips/tls/server.key
    ca_certificate: /etc/opensips/tls/ca.crt
    verify_client: optional
    ciphers: "HIGH:!aNULL:!MD5"
```

### 7.2 API Authentication

```bash
# Generate API key
curl -X POST http://localhost:8081/api/v1/auth/keys \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "External Integration",
    "scopes": ["events:write", "alerts:read"],
    "expires_in_days": 365
  }'

# Revoke API key
curl -X DELETE http://localhost:8081/api/v1/auth/keys/{key_id} \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### 7.3 Network Security

```bash
# Firewall rules (UFW example)
sudo ufw allow from 10.0.0.0/8 to any port 8080
sudo ufw allow from 10.0.0.0/8 to any port 5060
sudo ufw deny from any to any port 6379  # Internal only
sudo ufw deny from any to any port 5433  # Internal only
```

### 7.4 Audit Logging

```sql
-- Query audit logs
SELECT * FROM audit_log
WHERE timestamp > NOW() - INTERVAL '24 hours'
ORDER BY timestamp DESC
LIMIT 100;

-- User activity
SELECT
    user_id,
    action,
    COUNT(*) as count
FROM audit_log
WHERE timestamp > NOW() - INTERVAL '7 days'
GROUP BY user_id, action
ORDER BY count DESC;
```

---

## 8. Backup & Recovery

### 8.1 Backup Procedures

```bash
#!/bin/bash
# backup.sh - Daily backup script

BACKUP_DIR=/var/backups/acm/$(date +%Y%m%d)
mkdir -p $BACKUP_DIR

# YugabyteDB backup
docker-compose exec -T yugabyte ysql_dump \
  -U opensips opensips > $BACKUP_DIR/yugabyte.sql

# ClickHouse backup
docker-compose exec clickhouse clickhouse-client \
  --query="BACKUP DATABASE acm TO Disk('backups', 'acm_$(date +%Y%m%d)')"

# Configuration backup
cp -r config/ $BACKUP_DIR/config/
cp docker-compose.yml $BACKUP_DIR/
cp .env $BACKUP_DIR/

# Compress
tar -czf $BACKUP_DIR.tar.gz -C /var/backups/acm $(date +%Y%m%d)
rm -rf $BACKUP_DIR

# Upload to remote storage (optional)
aws s3 cp $BACKUP_DIR.tar.gz s3://your-bucket/acm-backups/

echo "Backup completed: $BACKUP_DIR.tar.gz"
```

### 8.2 Recovery Procedures

```bash
#!/bin/bash
# restore.sh - Restore from backup

BACKUP_DATE=$1
BACKUP_FILE=/var/backups/acm/${BACKUP_DATE}.tar.gz

# Stop services
docker-compose down

# Extract backup
tar -xzf $BACKUP_FILE -C /tmp/

# Restore YugabyteDB
docker-compose up -d yugabyte
sleep 30
docker-compose exec -T yugabyte ysql \
  -U opensips opensips < /tmp/${BACKUP_DATE}/yugabyte.sql

# Restore configuration
cp /tmp/${BACKUP_DATE}/config/* config/
cp /tmp/${BACKUP_DATE}/docker-compose.yml .
cp /tmp/${BACKUP_DATE}/.env .

# Restart all services
docker-compose up -d

echo "Restore completed from $BACKUP_DATE"
```

### 8.3 Disaster Recovery

| RTO | RPO | Strategy |
|-----|-----|----------|
| 1 hour | 15 minutes | Hot standby in DR site |
| 4 hours | 1 hour | Warm standby with replication |
| 24 hours | 24 hours | Cold backup restoration |

---

## 9. Scaling & Performance

### 9.1 Horizontal Scaling

```yaml
# Kubernetes HPA configuration
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: acm-engine-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: acm-engine
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### 9.2 Performance Tuning

```bash
# Increase file descriptors
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf

# Kernel tuning for high throughput
echo "net.core.somaxconn=65535" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog=65535" >> /etc/sysctl.conf
sysctl -p
```

### 9.3 Capacity Planning

| CPS | CPU | Memory | DragonflyDB | Disk IOPS |
|-----|-----|--------|-------------|-----------|
| 50K | 8 cores | 32 GB | 4 GB | 10,000 |
| 100K | 16 cores | 64 GB | 8 GB | 25,000 |
| 150K | 32 cores | 128 GB | 16 GB | 50,000 |

---

## 10. Troubleshooting

### 10.1 Common Issues

| Symptom | Cause | Solution |
|---------|-------|----------|
| High latency | DragonflyDB memory full | Increase memory or reduce TTL |
| Connection refused | Service not running | Check `docker-compose ps` |
| Alert storm | Threshold too low | Increase detection threshold |
| Missing metrics | Prometheus scrape issue | Check Prometheus targets |

### 10.2 Diagnostic Commands

```bash
# Check service status
docker-compose ps

# Check container resource usage
docker stats

# Check network connectivity
docker-compose exec acm-engine ping dragonfly

# Check logs for errors
docker-compose logs --tail=100 | grep -i error

# Database connection test
docker-compose exec acm-engine /health-check.sh
```

### 10.3 Emergency Procedures

```bash
# Emergency restart
docker-compose restart acm-engine

# Clear cache (last resort)
redis-cli -p 6379 FLUSHDB

# Disable detection temporarily
curl -X PATCH http://localhost:8080/api/v1/config \
  -d '{"detection_enabled": false}'
```

---

## 11. Maintenance Procedures

### 11.1 Daily Maintenance

- [ ] Review alert dashboard
- [ ] Check system health metrics
- [ ] Verify NCC report uploads
- [ ] Review error logs

### 11.2 Weekly Maintenance

- [ ] Review disk space usage
- [ ] Check backup integrity
- [ ] Review blocked patterns
- [ ] Update whitelist as needed
- [ ] Review false positive reports

### 11.3 Monthly Maintenance

- [ ] Apply security patches
- [ ] Rotate logs
- [ ] Review and optimize queries
- [ ] Capacity review
- [ ] Compliance audit preparation

### 11.4 Scheduled Maintenance Windows

```
Maintenance Window: Sunday 02:00-04:00 WAT
Emergency Contact: +234-XXX-XXX-XXXX

Procedure:
1. Send maintenance notification (24h advance)
2. Enable maintenance mode
3. Perform updates
4. Run validation tests
5. Disable maintenance mode
6. Send completion notification
```

---

## 12. Compliance Administration

### 12.1 NCC Reporting Status

```bash
# Check last upload status
docker-compose logs --tail=50 ncc-sftp-uploader | grep upload

# Manual report trigger
docker-compose exec ncc-sftp-uploader /scripts/generate-daily-report.sh

# Verify ATRS connectivity
curl http://localhost:8080/api/v1/ncc/atrs/status
```

### 12.2 Data Retention

| Data Type | Retention | Action |
|-----------|-----------|--------|
| Call events | 90 days | Auto-archive |
| Fraud alerts | 7 years | Archive to cold storage |
| Audit logs | 5 years | Archive to cold storage |
| Metrics | 30 days | Auto-delete |

### 12.3 Compliance Checklist

- [ ] Daily reports submitted by 06:00 WAT
- [ ] Monthly reports submitted by 5th
- [ ] Incident reports within SLA
- [ ] Data retention policies enforced
- [ ] Access controls reviewed quarterly
- [ ] Security audit scheduled

---

## Appendix A: Quick Reference

### Service Ports
| Service | Port | Protocol |
|---------|------|----------|
| ACM Engine | 8080 | HTTP |
| Management API | 8081 | HTTP |
| OpenSIPS | 5060 | SIP |
| DragonflyDB | 6379 | Redis |
| YugabyteDB | 5433 | PostgreSQL |
| QuestDB | 8812 | PostgreSQL |
| ClickHouse | 8123 | HTTP |
| Prometheus | 9091 | HTTP |
| Grafana | 3000 | HTTP |

### Essential Commands
```bash
# Status
docker-compose ps
docker-compose logs -f

# Restart
docker-compose restart <service>
docker-compose down && docker-compose up -d

# Health
curl http://localhost:8080/health
curl http://localhost:9091/metrics

# Config
curl http://localhost:8080/api/v1/config
```

---

**Document Version:** 2.0
**Classification:** Internal Use Only
