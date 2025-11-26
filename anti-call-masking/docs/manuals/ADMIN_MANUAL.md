# System Administrator Manual
## Anti-Call Masking Detection System

**Version:** 1.0.0
**Last Updated:** November 2024

---

## Table of Contents

1. [Introduction](#introduction)
2. [System Architecture](#system-architecture)
3. [Installation Guide](#installation-guide)
4. [Configuration](#configuration)
5. [User Management](#user-management)
6. [System Monitoring](#system-monitoring)
7. [Backup and Recovery](#backup-and-recovery)
8. [Troubleshooting](#troubleshooting)
9. [Security Guidelines](#security-guidelines)

---

## 1. Introduction

### 1.1 Purpose
The Anti-Call Masking Detection System is designed to detect and prevent multicall masking fraud attacks in VoIP/telecom networks. This manual provides system administrators with comprehensive guidance for deploying, configuring, and maintaining the system.

### 1.2 Audience
This manual is intended for:
- System Administrators
- DevOps Engineers
- IT Infrastructure Teams

### 1.3 System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 4 cores | 8+ cores |
| RAM | 8 GB | 16+ GB |
| Storage | 50 GB SSD | 200+ GB NVMe |
| Network | 1 Gbps | 10 Gbps |
| OS | Ubuntu 20.04+ / RHEL 8+ | Ubuntu 22.04 LTS |

---

## 2. System Architecture

### 2.1 High-Level Architecture

```
                    ┌─────────────────────────────────────────┐
                    │           Load Balancer                 │
                    │         (NGINX/HAProxy)                 │
                    └────────────────┬────────────────────────┘
                                     │
              ┌──────────────────────┼──────────────────────┐
              │                      │                      │
    ┌─────────▼─────────┐  ┌─────────▼─────────┐  ┌─────────▼─────────┐
    │   Carrier API     │  │   Carrier API     │  │   Carrier API     │
    │   (Instance 1)    │  │   (Instance 2)    │  │   (Instance N)    │
    └─────────┬─────────┘  └─────────┬─────────┘  └─────────┬─────────┘
              │                      │                      │
              └──────────────────────┼──────────────────────┘
                                     │
                    ┌────────────────▼────────────────┐
                    │     kdb+ Analytics Engine       │
                    │  ┌──────────────────────────┐   │
                    │  │  Anti-Call Masking       │   │
                    │  │  Detection Module        │   │
                    │  └──────────────────────────┘   │
                    └────────────────┬────────────────┘
                                     │
              ┌──────────────────────┼──────────────────────┐
              │                      │                      │
    ┌─────────▼─────────┐  ┌─────────▼─────────┐  ┌─────────▼─────────┐
    │   YugabyteDB      │  │   DragonflyDB     │  │   Prometheus      │
    │   (Persistence)   │  │   (Cache)         │  │   (Metrics)       │
    └───────────────────┘  └───────────────────┘  └───────────────────┘
```

### 2.2 Component Overview

| Component | Purpose | Port |
|-----------|---------|------|
| Carrier API | REST API gateway | 8080 |
| kdb+ Analytics | Real-time detection | 5000 (IPC), 5001 (HTTP) |
| kdb+ Tickerplant | Event streaming | 5011 |
| kdb+ RDB | Real-time queries | 5012 |
| YugabyteDB | Persistent storage | 5433 |
| DragonflyDB | Caching layer | 6379 |
| Kamailio SBC | SIP border controller | 5060 |
| Prometheus | Metrics collection | 9090 |
| Grafana | Visualization | 3000 |

---

## 3. Installation Guide

### 3.1 Prerequisites

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install kubectl (for Kubernetes deployments)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### 3.2 Docker Deployment

```bash
# Clone the repository
git clone https://github.com/abiolaogu/Anti_Call-Masking.git
cd Anti_Call-Masking/anti-call-masking

# Configure environment
cp .env.example .env
# Edit .env with your settings

# Start the services
docker-compose up -d

# Verify deployment
docker-compose ps
docker-compose logs -f
```

### 3.3 Kubernetes Deployment

```bash
# Create namespace
kubectl create namespace anti-call-masking

# Apply configurations
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml

# Verify deployment
kubectl get pods -n anti-call-masking
kubectl get services -n anti-call-masking
```

### 3.4 Voice-Switch-IM Integration

```bash
# Clone Voice-Switch-IM
cd /opt
git clone https://github.com/abiolaogu/Voice-Switch-IM.git
cd Voice-Switch-IM

# Start integrated stack
docker-compose up -d

# Verify kdb+ is running with anti-call masking
curl http://localhost:5001/health
curl http://localhost:5001/acm/stats
```

---

## 4. Configuration

### 4.1 Detection Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `DETECTION_WINDOW_SEC` | 5 | Time window for detection (seconds) |
| `DETECTION_THRESHOLD` | 5 | Min distinct A-numbers to trigger alert |
| `AUTO_DISCONNECT` | true | Automatically disconnect fraud calls |
| `COOLDOWN_SECS` | 60 | Cooldown per B-number after alert |

### 4.2 Environment Variables

```bash
# Detection Settings
DETECTION_WINDOW_SEC=5
DETECTION_THRESHOLD=5

# kdb+ Settings
KDB_HOST=kdb
KDB_PORT=5000
KDB_HTTP_PORT=5001

# Database Settings
DATABASE_URL=postgres://postgres:postgres@yugabyte-tserver:5433/voice_switch

# Cache Settings
REDIS_URL=redis://dragonfly:6379/0

# Logging
LOG_LEVEL=info
LOG_FORMAT=json

# Metrics
METRICS_ENABLED=true
PROMETHEUS_PORT=9090
```

### 4.3 kdb+ Runtime Configuration

```q
// Connect to kdb+
q) \p 5000

// View current settings
q) .acm.getStats[]

// Modify detection threshold
q) .acm.setThreshold[7]

// Modify detection window
q) .acm.setWindow[10]

// View elevated threats
q) .acm.getElevatedThreats[]
```

### 4.4 API Configuration

```yaml
# config/api.yaml
server:
  port: 8080
  read_timeout: 30s
  write_timeout: 30s

rate_limiting:
  enabled: true
  requests_per_second: 1000
  burst: 100

circuit_breaker:
  enabled: true
  threshold: 5
  timeout: 30s
```

---

## 5. User Management

### 5.1 User Roles

| Role | Permissions |
|------|-------------|
| Admin | Full system access, user management |
| SOC Analyst | View alerts, investigate fraud |
| Operator | View metrics, basic operations |
| API User | API access only |

### 5.2 Creating Users

```bash
# Via API
curl -X POST http://localhost:8080/api/v1/admin/users \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "analyst1",
    "email": "analyst1@example.com",
    "role": "soc_analyst",
    "password": "SecureP@ss123"
  }'
```

### 5.3 Role-Based Access Control

```yaml
# config/rbac.yaml
roles:
  admin:
    permissions:
      - "*"
  soc_analyst:
    permissions:
      - "alerts:read"
      - "alerts:update"
      - "calls:read"
      - "reports:read"
  operator:
    permissions:
      - "metrics:read"
      - "health:read"
  api_user:
    permissions:
      - "events:write"
      - "alerts:read"
```

---

## 6. System Monitoring

### 6.1 Health Checks

```bash
# kdb+ Health
curl http://localhost:5001/health

# Carrier API Health
curl http://localhost:8080/health

# Full system status
curl http://localhost:8080/ready
```

### 6.2 Key Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `fraud_detection_latency_ms` | Detection latency | > 100ms |
| `fraud_alerts_total` | Total alerts generated | Rate > 10/min |
| `active_calls_count` | Current active calls | > 10000 |
| `kdb_memory_usage_bytes` | kdb+ memory usage | > 80% |
| `api_error_rate` | API error percentage | > 1% |

### 6.3 Grafana Dashboards

1. **System Overview**: Overall health and metrics
2. **Fraud Detection**: Real-time detection stats
3. **Performance**: Latency and throughput
4. **Infrastructure**: Resource utilization

Import dashboards from `grafana/dashboard.json`.

### 6.4 Log Analysis

```bash
# View kdb+ logs
docker logs kdb-analytics -f

# View carrier-api logs
docker logs carrier-api -f | jq .

# Search for fraud alerts
docker logs kdb-analytics 2>&1 | grep "FRAUD ALERT"

# Filter by log level
docker logs carrier-api 2>&1 | jq 'select(.level=="error")'
```

---

## 7. Backup and Recovery

### 7.1 Data Backup

```bash
# Backup kdb+ data
docker exec kdb-analytics q -c "\d .backup; save[\`:backup/cdr;cdr]; save[\`:backup/fraudAlert;fraudAlert]"

# Backup YugabyteDB
docker exec yugabyte-tserver /home/yugabyte/bin/ysql_dump -h localhost -p 5433 -U postgres voice_switch > backup.sql

# Backup configuration
tar -czvf config_backup.tar.gz config/ k8s/ .env
```

### 7.2 Automated Backups

```yaml
# k8s/cronjob-backup.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-job
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: backup-agent:latest
            command: ["/backup.sh"]
          restartPolicy: OnFailure
```

### 7.3 Disaster Recovery

1. **RTO (Recovery Time Objective)**: 15 minutes
2. **RPO (Recovery Point Objective)**: 5 minutes

**Recovery Steps:**
```bash
# 1. Stop affected services
docker-compose stop

# 2. Restore data
docker exec kdb-analytics q -c "\d .backup; load[\`:backup/cdr]; load[\`:backup/fraudAlert]"

# 3. Restore database
cat backup.sql | docker exec -i yugabyte-tserver /home/yugabyte/bin/ysqlsh -h localhost -p 5433 -U postgres

# 4. Restart services
docker-compose up -d

# 5. Verify recovery
curl http://localhost:5001/health
curl http://localhost:8080/ready
```

---

## 8. Troubleshooting

### 8.1 Common Issues

#### kdb+ Not Responding

```bash
# Check container status
docker ps | grep kdb

# Check logs
docker logs kdb-analytics --tail 100

# Restart kdb+
docker restart kdb-analytics

# Check port binding
netstat -tlnp | grep 5000
```

#### High Detection Latency

```bash
# Check kdb+ memory
curl http://localhost:5001/acm/stats | jq '.callsInTable'

# Force cleanup
docker exec kdb-analytics q -c ".acm.cleanup[]"

# Check system resources
docker stats kdb-analytics
```

#### Database Connection Issues

```bash
# Check YugabyteDB status
docker exec yugabyte-tserver /home/yugabyte/bin/yb-admin -master_addresses yugabyte-master:7100 list_all_masters

# Check connection pool
docker exec carrier-api curl localhost:8080/stats | jq '.db_pool'

# Reset connection pool
docker restart carrier-api
```

### 8.2 Performance Tuning

```bash
# Increase kdb+ memory limit
docker update --memory=8g kdb-analytics

# Increase worker threads
# Edit docker-compose.yml: command: q -p 5000 -s 8 -w 4000

# Tune database connections
DB_MAX_CONNS=200
DB_MIN_CONNS=50
```

### 8.3 Log Levels

```bash
# Enable debug logging
LOG_LEVEL=debug docker-compose up -d carrier-api

# kdb+ debug mode
docker exec kdb-analytics q -c "\t 1"  # Enable timing
```

---

## 9. Security Guidelines

### 9.1 Network Security

```yaml
# Firewall rules
- Allow 8080/tcp from trusted networks only
- Allow 5060/udp from SIP networks only
- Block 5000/tcp from external (kdb+ IPC)
- Allow 5001/tcp from internal only
```

### 9.2 Authentication

- Use strong passwords (min 16 characters)
- Enable MFA for admin accounts
- Rotate API keys every 90 days
- Use JWT with short expiration (1 hour)

### 9.3 Audit Logging

```bash
# View audit logs
docker logs carrier-api 2>&1 | jq 'select(.type=="audit")'

# Important events to monitor:
# - Login attempts
# - Configuration changes
# - User management actions
# - Alert acknowledgments
```

### 9.4 Vulnerability Management

```bash
# Run security scan
trivy image carrier-api:latest

# Check for CVEs
grype carrier-api:latest

# Update base images regularly
docker-compose pull
docker-compose up -d
```

---

## Appendix A: CLI Reference

```bash
# System Status
acm-cli status           # Overall status
acm-cli health           # Health check
acm-cli metrics          # Current metrics

# Detection Management
acm-cli detect stats     # Detection statistics
acm-cli detect threats   # List elevated threats
acm-cli detect config    # View/set configuration

# Alert Management
acm-cli alerts list      # List recent alerts
acm-cli alerts ack <id>  # Acknowledge alert

# User Management
acm-cli users list       # List users
acm-cli users add        # Add user
acm-cli users delete     # Delete user
```

---

## Appendix B: Support Contacts

| Issue Type | Contact |
|------------|---------|
| Technical Support | support@example.com |
| Security Incidents | security@example.com |
| Bug Reports | https://github.com/abiolaogu/Anti_Call-Masking/issues |

---

**Document Version:** 1.0.0
**Classification:** Internal Use Only
