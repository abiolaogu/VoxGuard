# Sentinel Production Deployment Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Docker Deployment](#docker-deployment)
3. [Kubernetes Deployment](#kubernetes-deployment)
4. [Configuration](#configuration)
5. [Monitoring Setup](#monitoring-setup)
6. [Security](#security)
7. [Scaling](#scaling)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### System Requirements
- **CPU**: 4+ cores per instance
- **Memory**: 4GB+ RAM per instance
- **Storage**: 100GB+ for database
- **Network**: Low latency connection to database (<10ms)

### Software Requirements
- Docker 20.10+
- Kubernetes 1.24+ (for K8s deployment)
- PostgreSQL 14+ or YugabyteDB
- (Optional) Redis 6+ for distributed caching

### Database Setup
```sql
-- Create database and user
CREATE DATABASE sentinel;
CREATE USER sentinel_user WITH ENCRYPTED PASSWORD 'your-secure-password';
GRANT ALL PRIVILEGES ON DATABASE sentinel TO sentinel_user;

-- Run migrations
psql -U sentinel_user -d sentinel -f migrations/001_sentinel_tables.sql
```

---

## Docker Deployment

### Build Production Image

```bash
# Build optimized production image
docker build -f Dockerfile.prod -t sentinel-engine:1.0.0 .

# Or use multi-arch build for ARM/x86
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -f Dockerfile.prod \
  -t sentinel-engine:1.0.0 \
  --push .
```

### Run with Docker Compose

Create `docker-compose.prod.yaml`:

```yaml
version: '3.8'

services:
  sentinel-engine:
    image: sentinel-engine:1.0.0
    restart: always
    ports:
      - "8000:8000"
    environment:
      DATABASE_URL: postgresql://sentinel_user:password@postgres:5432/sentinel
      DATABASE_POOL_MIN_SIZE: 10
      DATABASE_POOL_MAX_SIZE: 50
      LOG_LEVEL: INFO
      ENVIRONMENT: production
    depends_on:
      - postgres
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '0.5'
          memory: 1G

  postgres:
    image: postgres:14-alpine
    restart: always
    environment:
      POSTGRES_DB: sentinel
      POSTGRES_USER: sentinel_user
      POSTGRES_PASSWORD: your-secure-password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./migrations:/docker-entrypoint-initdb.d
    ports:
      - "5432:5432"

  nginx:
    image: nginx:alpine
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - sentinel-engine

volumes:
  postgres_data:
```

Start the services:

```bash
docker-compose -f docker-compose.prod.yaml up -d
```

---

## Kubernetes Deployment

### 1. Create Namespace

```bash
kubectl create namespace anti-call-masking
```

### 2. Create Secrets

```bash
# Database credentials
kubectl create secret generic sentinel-secrets \
  --namespace=anti-call-masking \
  --from-literal=database-url='postgresql://user:pass@postgres:5432/sentinel' \
  --from-literal=redis-url='redis://redis:6379/0' \
  --from-literal=jwt-secret='your-jwt-secret'
```

### 3. Apply Configuration

```bash
# Apply ConfigMaps
kubectl apply -f k8s/configmap.yaml

# Apply Deployment and Service
kubectl apply -f k8s/deployment.yaml

# Apply Ingress (configure domain first)
kubectl apply -f k8s/ingress.yaml
```

### 4. Verify Deployment

```bash
# Check pod status
kubectl get pods -n anti-call-masking -l app=sentinel-engine

# Check service
kubectl get svc -n anti-call-masking

# View logs
kubectl logs -n anti-call-masking -l app=sentinel-engine --tail=100 -f
```

### 5. Test Health Check

```bash
kubectl port-forward -n anti-call-masking svc/sentinel-engine 8000:8000
curl http://localhost:8000/health
```

---

## Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `DATABASE_URL` | PostgreSQL connection string | - | Yes |
| `DATABASE_POOL_MIN_SIZE` | Min connection pool size | 10 | No |
| `DATABASE_POOL_MAX_SIZE` | Max connection pool size | 50 | No |
| `REDIS_URL` | Redis connection string | - | No |
| `LOG_LEVEL` | Logging level (DEBUG/INFO/WARNING/ERROR) | INFO | No |
| `ENVIRONMENT` | Environment name (development/staging/production) | production | No |
| `CACHE_ENABLED` | Enable caching | true | No |
| `CACHE_TTL_SECONDS` | Cache TTL in seconds | 300 | No |

### Database Connection Pool Tuning

For production workloads:

```python
# Recommended settings based on load
Light load (< 100 req/sec):
  MIN_POOL_SIZE = 10
  MAX_POOL_SIZE = 30

Medium load (100-500 req/sec):
  MIN_POOL_SIZE = 20
  MAX_POOL_SIZE = 50

Heavy load (> 500 req/sec):
  MIN_POOL_SIZE = 50
  MAX_POOL_SIZE = 100
```

### Performance Tuning

Edit `k8s/configmap.yaml`:

```yaml
performance.config: |
  {
    "database": {
      "batch_insert_size": 1000,  # Increase for bulk imports
      "query_timeout": 30
    },
    "cache": {
      "ttl_seconds": 300,  # Increase for less dynamic data
      "alert_ttl_seconds": 60
    },
    "processing": {
      "batch_size": 1000,
      "max_concurrent_batches": 5  # Tune based on CPU cores
    }
  }
```

---

## Monitoring Setup

### Prometheus Configuration

Add Sentinel scrape config to `prometheus.yml`:

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
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
```

### Load Alerting Rules

```bash
# Copy rules to Prometheus config directory
cp monitoring/prometheus-rules.yaml /etc/prometheus/rules/

# Reload Prometheus
curl -X POST http://prometheus:9090/-/reload
```

### Import Grafana Dashboard

1. Open Grafana UI
2. Navigate to **Dashboards → Import**
3. Upload `monitoring/grafana-dashboard.json`
4. Select Prometheus data source
5. Click **Import**

### Access Metrics Endpoint

```bash
# Direct access
curl http://sentinel-engine:8000/api/v1/sentinel/metrics

# Through Kubernetes port-forward
kubectl port-forward -n anti-call-masking svc/sentinel-engine 8000:8000
curl http://localhost:8000/api/v1/sentinel/metrics
```

---

## Security

### API Authentication

Implement JWT authentication in production:

```python
# Add to main.py
from fastapi.security import HTTPBearer
from .auth import verify_jwt_token

security = HTTPBearer()

@app.middleware("http")
async def authenticate(request: Request, call_next):
    if request.url.path not in ["/health", "/docs", "/redoc"]:
        token = request.headers.get("Authorization")
        if not token or not verify_jwt_token(token):
            return JSONResponse(
                status_code=401,
                content={"detail": "Unauthorized"}
            )
    return await call_next(request)
```

### Network Policies

Apply Kubernetes network policies:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: sentinel-engine-policy
  namespace: anti-call-masking
spec:
  podSelector:
    matchLabels:
      app: sentinel-engine
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx
      ports:
        - protocol: TCP
          port: 8000
  egress:
    - to:
        - namespaceSelector: {}
      ports:
        - protocol: TCP
          port: 5432  # PostgreSQL
        - protocol: TCP
          port: 6379  # Redis
```

### Secrets Management

Use external secrets management (HashiCorp Vault, AWS Secrets Manager):

```bash
# Install External Secrets Operator
helm install external-secrets \
  external-secrets/external-secrets \
  -n external-secrets-system \
  --create-namespace

# Create ExternalSecret resource
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: sentinel-secrets
  namespace: anti-call-masking
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: sentinel-secrets
  data:
    - secretKey: database-url
      remoteRef:
        key: sentinel/database
        property: url
EOF
```

---

## Scaling

### Horizontal Pod Autoscaler

The HPA is configured in `k8s/deployment.yaml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: sentinel-engine-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: sentinel-engine
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

Monitor scaling events:

```bash
kubectl get hpa -n anti-call-masking -w
kubectl describe hpa sentinel-engine-hpa -n anti-call-masking
```

### Database Scaling

For high-volume deployments:

1. **Read Replicas**: Configure read-only replicas for query load
2. **Connection Pooling**: Use PgBouncer for connection management
3. **Partitioning**: Partition `call_records` table by date:

```sql
-- Create partitioned table
CREATE TABLE call_records_partitioned (
    id SERIAL,
    call_timestamp TIMESTAMP NOT NULL,
    -- ... other columns
) PARTITION BY RANGE (call_timestamp);

-- Create monthly partitions
CREATE TABLE call_records_2024_01 PARTITION OF call_records_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

### Load Testing

Use k6 for load testing:

```javascript
// load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 100 },  // Ramp up
    { duration: '5m', target: 100 },  // Stay at 100 RPS
    { duration: '2m', target: 0 },    // Ramp down
  ],
};

export default function () {
  let res = http.get('http://sentinel-engine:8000/api/v1/sentinel/health');
  check(res, { 'status 200': (r) => r.status === 200 });
  sleep(1);
}
```

Run test:

```bash
k6 run load-test.js
```

---

## Troubleshooting

### High Memory Usage

**Symptoms**: OOMKilled pods, high memory utilization

**Solutions**:
1. Reduce `DATABASE_POOL_MAX_SIZE`
2. Lower `batch_size` in processing config
3. Increase pod memory limits
4. Check for memory leaks with profiling

```bash
# Check memory usage
kubectl top pods -n anti-call-masking -l app=sentinel-engine

# View OOMKill events
kubectl get events -n anti-call-masking | grep OOM
```

### Slow API Responses

**Symptoms**: High p95 latency, timeouts

**Solutions**:
1. Check database query performance
2. Increase cache TTL
3. Add database indexes
4. Scale horizontally

```bash
# Check API response times
kubectl logs -n anti-call-masking -l app=sentinel-engine | grep "completed in"

# Query Prometheus for latency
curl -G 'http://prometheus:9090/api/v1/query' \
  --data-urlencode 'query=sentinel_api_request_duration_seconds{quantile="0.95"}'
```

### Database Connection Pool Exhausted

**Symptoms**: "Pool exhausted" errors, high pool utilization

**Solutions**:
1. Increase `MAX_POOL_SIZE`
2. Reduce query timeout
3. Check for long-running queries
4. Add read replicas

```sql
-- Find slow queries
SELECT pid, now() - pg_stat_activity.query_start AS duration, query
FROM pg_stat_activity
WHERE state = 'active' AND now() - pg_stat_activity.query_start > interval '5 seconds';
```

### No Alerts Being Generated

**Symptoms**: `sentinel_alerts_generated_total` not increasing

**Solutions**:
1. Check detection job is running
2. Verify CDR data is being ingested
3. Review detection thresholds

```bash
# Check last detection timestamp
curl http://sentinel-engine:8000/api/v1/sentinel/metrics | grep last_detection

# Manually trigger detection
curl -X POST http://sentinel-engine:8000/api/v1/sentinel/detect/sdhf \
  -H "Content-Type: application/json" \
  -d '{"time_window_hours": 24, "min_unique_destinations": 50, "max_avg_duration_seconds": 3.0}'
```

### WebSocket Connection Issues

**Symptoms**: Clients unable to connect to WebSocket endpoint

**Solutions**:
1. Verify Ingress WebSocket annotations
2. Check nginx timeout settings
3. Ensure CORS headers are correct

```yaml
# Ingress annotations for WebSocket
nginx.ingress.kubernetes.io/websocket-services: "sentinel-engine"
nginx.ingress.kubernetes.io/proxy-connect-timeout: "3600"
nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
```

---

## Health Checks

### Liveness Probe
Checks if the application is running (restart if fails)

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 30
  periodSeconds: 10
```

### Readiness Probe
Checks if the application is ready to serve traffic

```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 10
  periodSeconds: 5
```

### Custom Health Checks

Add detailed health check endpoint:

```python
@app.get("/api/v1/sentinel/health/detailed")
async def detailed_health():
    return {
        "status": "healthy",
        "checks": {
            "database": await check_database(),
            "cache": await check_cache(),
            "disk_space": check_disk_space()
        }
    }
```

---

## Backup and Recovery

### Database Backups

```bash
# Daily backup with pg_dump
0 2 * * * pg_dump -U sentinel_user -d sentinel | gzip > /backups/sentinel-$(date +\%Y\%m\%d).sql.gz

# Restore from backup
gunzip -c sentinel-20240115.sql.gz | psql -U sentinel_user -d sentinel
```

### Disaster Recovery

1. **RTO (Recovery Time Objective)**: < 1 hour
2. **RPO (Recovery Point Objective)**: < 15 minutes

Implement:
- Continuous database replication
- Automated backup verification
- Documented recovery procedures

---

## Support

For production issues:
- **Monitoring**: Check Grafana dashboards
- **Logs**: `kubectl logs -n anti-call-masking -l app=sentinel-engine`
- **Metrics**: Access Prometheus at `/metrics` endpoint
- **Documentation**: See [Operations Runbook](OPERATIONS_RUNBOOK.md)

---

**Last Updated**: 2026-01-23
**Version**: 1.0.0
**Maintainer**: BillyRonks Global Operations Team
