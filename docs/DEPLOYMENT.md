# Deployment Guide

## Prerequisites

- Docker & Docker Compose v2.20+
- Kubernetes 1.28+ (for production)
- 8+ CPU cores, 32GB RAM per node

---

## Docker Compose (Development)

### Start All Services
```bash
docker-compose -f deployment/docker/docker-compose.yml up -d
```

### Initialize Databases
```bash
./scripts/init-yugabyte.sh
./scripts/init-clickhouse.sh
./scripts/seed-nigerian-prefixes.sh
```

### Verify Health
```bash
curl http://localhost:8080/health  # Detection Engine
curl http://localhost:8081/health  # Management API
curl http://localhost:3000         # Grafana
```

---

## Kubernetes (Production)

### Apply Manifests
```bash
kubectl apply -f deployment/k8s/namespace.yaml
kubectl apply -f deployment/k8s/configmaps.yaml
kubectl apply -f deployment/k8s/secrets.yaml
kubectl apply -f deployment/k8s/
```

### Verify Deployment
```bash
kubectl get pods -n acm
kubectl logs -f deployment/detection-engine -n acm
```

---

## Configuration

### Environment Variables

#### Detection Engine
| Variable | Description | Default |
|----------|-------------|---------|
| `DRAGONFLY_URL` | DragonflyDB connection | `redis://dragonfly:6379` |
| `YUGABYTE_URL` | YugabyteDB connection | `postgres://...` |
| `QUESTDB_URL` | QuestDB ILP endpoint | `http://questdb:9000` |
| `DETECTION_WINDOW_SECONDS` | Sliding window size | `5` |
| `DETECTION_THRESHOLD` | Distinct callers threshold | `5` |

#### Management API
| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection | `postgres://...` |
| `JWT_SECRET` | JWT signing key | (required) |
| `GIN_MODE` | Gin framework mode | `release` |

#### NCC Compliance
| Variable | Description |
|----------|-------------|
| `NCC_ATRS_URL` | ATRS API endpoint |
| `NCC_CLIENT_ID` | ICL client ID |
| `NCC_CLIENT_SECRET` | ICL client secret |
| `NCC_SFTP_HOST` | SFTP server for CDR uploads |

---

## Geo-Distributed Deployment

### Lagos (Primary)
- 3x OpenSIPS nodes (load balanced)
- DragonflyDB primary
- YugabyteDB tablet leaders
- QuestDB primary

### Abuja/Asaba (Replicas)
- 1x OpenSIPS node each
- DragonflyDB replicas (`REPLICAOF lagos:6379`)
- YugabyteDB followers

---

## Scaling

### Horizontal Scaling
```bash
# Scale detection engine
kubectl scale deployment detection-engine --replicas=5 -n acm

# Scale management API
kubectl scale deployment management-api --replicas=3 -n acm
```

### Performance Tuning
```bash
# Increase connection pool
export DRAGONFLY_POOL_SIZE=64
export YUGABYTE_MAX_CONNECTIONS=100
```

---

## Monitoring

### Grafana Dashboards
- ACM Overview - Real-time fraud stats
- Detection Performance - Latency histograms
- Gateway Health - Per-gateway metrics
- NCC Compliance - Reporting status

### Alerts
Configure in `monitoring/prometheus/alerts.yml`:
- High fraud rate (>10%)
- Detection latency >5ms
- Cache miss rate >5%
- Database connection failures

---

## Backup & Recovery

### YugabyteDB Backup
```bash
./scripts/backup-yugabyte.sh
```

### Restore
```bash
./scripts/restore-yugabyte.sh backup-2026-01-29.tar.gz
```
