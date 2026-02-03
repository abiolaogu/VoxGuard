# VoxGuard Voice Switch - Production Hardening Guide

**Version:** 3.0
**Date:** 2026-02-03
**Status:** Production Ready

## Overview

This document describes the production hardening implementation for VoxGuard Voice Switch (P0-3 requirement from PRD). The system is now production-ready with:

- ✅ High availability OpenSIPS cluster (3+ instances)
- ✅ HAProxy load balancer for SIP traffic
- ✅ Circuit breaker pattern for graceful degradation
- ✅ Enhanced health check endpoints
- ✅ Horizontal auto-scaling
- ✅ Zero-downtime deployments

---

## Architecture

```
                     Internet
                        |
                   [HAProxy LB]
                   /     |     \
                  /      |      \
          [OpenSIPS-1][OpenSIPS-2][OpenSIPS-3]
                  \      |      /
                   \     |     /
              [ACM Engine Cluster]
               (with Circuit Breaker)
                   /     |     \
                  /      |      \
           [DragonflyDB][YugabyteDB][ClickHouse]
```

### Key Components

1. **HAProxy Load Balancer**
   - Layer 4 TCP/UDP load balancing
   - Session affinity for SIP dialogs
   - Health check probes
   - Automatic failover

2. **OpenSIPS Cluster**
   - 3 active instances (configurable)
   - Shared state via DragonflyDB
   - Database-backed dialogs
   - Auto-scaling based on CPU/memory

3. **Circuit Breaker**
   - Protects ACM detection engine
   - Three states: CLOSED, OPEN, HALF_OPEN
   - Configurable thresholds
   - Fail-open strategy (allow calls when open)

4. **Health Checks**
   - Liveness probe (process alive)
   - Readiness probe (can serve traffic)
   - Detailed component status
   - Circuit breaker metrics

---

## Deployment Options

### Option 1: Docker Compose (Recommended for Testing)

```bash
# Navigate to infrastructure directory
cd infrastructure/production

# Configure environment variables
cp .env.example .env
# Edit .env with your settings:
# - YUGABYTE_PASSWORD
# - REDIS_PASSWORD
# - CLICKHOUSE_PASSWORD
# - GRAFANA_PASSWORD

# Start production stack
docker-compose -f docker-compose.prod.yml up -d

# Verify all services are healthy
docker-compose -f docker-compose.prod.yml ps

# Check HAProxy stats
open http://localhost:8404/stats
# Username: admin
# Password: voxguard2026 (change in production!)
```

### Option 2: Kubernetes (Recommended for Production)

```bash
# Create namespace
kubectl create namespace voxguard-prod

# Create secrets
kubectl create secret generic voxguard-secrets \
  --from-literal=yugabyte-password=$YUGABYTE_PASSWORD \
  --from-literal=redis-password=$REDIS_PASSWORD \
  --from-literal=clickhouse-password=$CLICKHOUSE_PASSWORD \
  -n voxguard-prod

# Deploy OpenSIPS cluster
kubectl apply -f infrastructure/kubernetes/voice-switch/deployment.yaml

# Check rollout status
kubectl rollout status deployment/opensips -n voxguard-prod

# Get external IP for SIP traffic
kubectl get svc opensips -n voxguard-prod
```

---

## Configuration

### OpenSIPS Production Settings

**File:** `services/voice-switch/opensips-production.cfg`

Key production tunings:
- **Workers:** 32 processes (adjust based on CPU cores)
- **TCP Connections:** 8192 max
- **Memory:** 512MB shared, 16MB per process
- **Timeouts:** Optimized for SIP (120s INVITE, 2m dialog)
- **Circuit Breaker:** 5 failures trigger OPEN, 30s retry timeout

### HAProxy Configuration

**File:** `services/voice-switch/haproxy.cfg`

Key features:
- **Session Affinity:** Source IP-based for SIP dialogs
- **Health Checks:** OPTIONS probe every 10s
- **Timeouts:** 5s connect, 2m client, 5m server (TCP)
- **Circuit Breaker:** 5 consecutive failures mark server down

### Circuit Breaker Settings

**File:** `services/voice-switch/circuit_breaker.py`

Default thresholds:
```python
CircuitBreakerConfig(
    failure_threshold=5,      # Failures to open circuit
    success_threshold=2,      # Successes to close circuit
    timeout=30.0,             # Seconds before retry (OPEN -> HALF_OPEN)
    half_open_max_calls=3,    # Max concurrent calls in HALF_OPEN
    expected_exception=Exception
)
```

Adjust based on your environment:
- **High traffic:** Increase `failure_threshold` (e.g., 10)
- **Strict protection:** Decrease `timeout` (e.g., 60s)
- **Faster recovery:** Increase `half_open_max_calls` (e.g., 5)

---

## Health Checks

### Endpoints

| Endpoint | Purpose | Response |
|----------|---------|----------|
| `/health` | Liveness probe | `200` if process alive |
| `/ready` | Readiness probe | `200` if can serve traffic |
| `/metrics` | Prometheus metrics | Circuit breaker stats |

### Health Check Levels

**Healthy:** All components operational
```json
{
  "status": "healthy",
  "components": [
    {"name": "yugabyte", "status": "healthy", "latency_ms": 5.2},
    {"name": "redis", "status": "healthy", "latency_ms": 1.1},
    {"name": "acm_engine", "status": "healthy", "latency_ms": 12.3}
  ],
  "circuit_breakers": {
    "acm_engine": {"state": "closed", "failure_rate": 0.0}
  }
}
```

**Degraded:** Non-critical component issues
```json
{
  "status": "degraded",
  "components": [
    {"name": "yugabyte", "status": "healthy", "latency_ms": 5.2},
    {"name": "redis", "status": "healthy", "latency_ms": 1.1},
    {"name": "acm_engine", "status": "unhealthy", "error": "Timeout"}
  ],
  "circuit_breakers": {
    "acm_engine": {"state": "open", "failure_rate": 1.0}
  }
}
```

**Unhealthy:** Critical component failure (returns `503`)
```json
{
  "status": "unhealthy",
  "components": [
    {"name": "yugabyte", "status": "unhealthy", "error": "Connection refused"},
    {"name": "redis", "status": "healthy", "latency_ms": 1.1}
  ]
}
```

---

## Scaling

### Horizontal Pod Autoscaling (Kubernetes)

OpenSIPS deployment includes HPA configuration:
- **Min Replicas:** 3
- **Max Replicas:** 10
- **CPU Target:** 70%
- **Memory Target:** 80%

Manual scaling:
```bash
kubectl scale deployment opensips --replicas=5 -n voxguard-prod
```

### Vertical Scaling

Adjust resource limits in deployment:
```yaml
resources:
  requests:
    cpu: 4000m      # Increase for higher traffic
    memory: 4Gi
  limits:
    cpu: 8000m
    memory: 8Gi
```

---

## Monitoring

### Prometheus Metrics

**OpenSIPS Metrics (via MI HTTP):**
- `opensips_calls_total` - Total calls processed
- `opensips_fraud_detected` - Fraud events detected
- `opensips_circuit_breaker_open` - Circuit breaker open events
- `opensips_failover_events` - Gateway failover count

**HAProxy Metrics:**
- `haproxy_backend_status` - Backend server status
- `haproxy_frontend_connections` - Active connections
- `haproxy_backend_response_time` - Response time distribution

**Circuit Breaker Metrics:**
- `circuit_breaker_state{service}` - Current state (0=CLOSED, 1=OPEN, 2=HALF_OPEN)
- `circuit_breaker_total_requests{service}` - Total requests
- `circuit_breaker_failed_requests{service}` - Failed requests
- `circuit_breaker_rejected_requests{service}` - Rejected requests

### Grafana Dashboards

Import pre-configured dashboards:
1. **Voice Switch Overview** - Call volume, fraud detection, latency
2. **Circuit Breaker Status** - State transitions, failure rates
3. **Load Balancer Metrics** - Backend health, traffic distribution

---

## Troubleshooting

### Circuit Breaker is OPEN

**Symptoms:**
- Health check shows circuit breaker state: "open"
- ACM engine errors in logs
- Calls are allowed but not checked for fraud

**Investigation:**
```bash
# Check circuit breaker metrics
curl http://opensips:8888/mi/get_statistics | grep circuit_breaker

# Check ACM engine health
curl http://acm-engine:8080/health

# Review OpenSIPS logs
kubectl logs -l app=opensips -n voxguard-prod --tail=100 | grep CIRCUIT_BREAKER
```

**Resolution:**
1. Fix ACM engine issue (check logs, restart if needed)
2. Circuit will automatically transition to HALF_OPEN after timeout (30s)
3. After 2 successful calls, circuit closes
4. Manual reset (if needed):
   ```bash
   # Reset via Redis
   redis-cli DEL cb:acm:state cb:acm:failures cb:acm:next_retry
   ```

### No Backend Servers Available

**Symptoms:**
- HAProxy returns 503
- Health check shows all OpenSIPS instances down

**Investigation:**
```bash
# Check HAProxy backend status
curl http://haproxy:8404/stats

# Check OpenSIPS health
for i in 1 2 3; do
  docker exec opensips-$i opensipsctl fifo get_statistics core:
done
```

**Resolution:**
1. Check database connectivity (YugabyteDB)
2. Check cache connectivity (DragonflyDB)
3. Review OpenSIPS configuration
4. Restart OpenSIPS instances one at a time

### High Latency

**Symptoms:**
- Health check shows high latency (>100ms)
- Prometheus shows increased response times

**Investigation:**
```bash
# Check database performance
psql -h yugabyte -U opensips -c "SELECT pg_stat_database.datname, numbackends FROM pg_stat_database;"

# Check Redis performance
redis-cli --latency-history

# Check OpenSIPS statistics
curl http://opensips:8888/mi/get_statistics
```

**Resolution:**
1. Scale up OpenSIPS replicas
2. Optimize database queries
3. Increase cache memory
4. Review circuit breaker thresholds

---

## Security Considerations

### TLS Configuration

**OpenSIPS TLS:**
- TLSv1.3 enforced
- Strong cipher suites
- Certificate verification enabled

**HAProxy TLS:**
- TLSv1.2+ only
- ECDHE ciphers preferred
- Certificates in `/etc/haproxy/certs/`

### Network Security

**Firewall Rules:**
```bash
# Allow SIP traffic
ufw allow 5060/udp  # SIP UDP
ufw allow 5060/tcp  # SIP TCP
ufw allow 5061/tcp  # SIP TLS

# Allow management (restrict to internal network)
ufw allow from 10.0.0.0/8 to any port 8888  # OpenSIPS MI
ufw allow from 10.0.0.0/8 to any port 8404  # HAProxy Stats
```

**Service Mesh (Optional):**
- Use Istio/Linkerd for mTLS between services
- Enforce network policies
- Add observability

---

## Performance Tuning

### Operating System

```bash
# Increase file descriptor limits
ulimit -n 65536

# TCP tuning
sysctl -w net.core.somaxconn=4096
sysctl -w net.ipv4.tcp_max_syn_backlog=8192
sysctl -w net.ipv4.tcp_tw_reuse=1
```

### OpenSIPS

```cfg
# Increase workers for high traffic
children=64  # 2x CPU cores recommended

# Increase memory
shm_mem_size=1024    # 1GB shared memory
pkg_mem_size=32      # 32MB per process

# Connection limits
tcp_max_connections=16384
```

### DragonflyDB

```bash
# Increase memory
--maxmemory=16gb

# More threads
--proactor_threads=16
```

---

## Testing

### Load Testing

Use SIPp for load testing:
```bash
# Basic call load
sipp -sn uac -r 100 -rp 1000 -d 30000 haproxy:5060

# With authentication
sipp -sf scenarios/register_invite.xml -r 50 haproxy:5060
```

### Circuit Breaker Testing

```bash
# Simulate ACM engine failure
docker stop acm-engine-1 acm-engine-2 acm-engine-3

# Monitor circuit breaker opening
watch -n 1 'curl -s http://opensips:8888/health | jq .circuit_breakers'

# Wait for circuit to open (after 5 failures)
# Verify calls are still allowed (fail-open)

# Restart ACM engines
docker start acm-engine-1 acm-engine-2 acm-engine-3

# Watch circuit recover (HALF_OPEN -> CLOSED)
```

### Failover Testing

```bash
# Kill one OpenSIPS instance
kubectl delete pod -l app=opensips --field-selector=status.phase=Running -n voxguard-prod | head -1

# Verify HAProxy detects failure and routes to healthy instances
curl http://haproxy:8404/stats | grep opensips

# Verify zero call drops (check Prometheus metrics)
```

---

## Maintenance

### Rolling Updates

**Docker Compose:**
```bash
# Update configuration
docker-compose -f docker-compose.prod.yml up -d --no-deps opensips-1

# Wait for health check
sleep 30

# Update remaining instances
docker-compose -f docker-compose.prod.yml up -d --no-deps opensips-2 opensips-3
```

**Kubernetes:**
```bash
# Update config map
kubectl apply -f infrastructure/kubernetes/voice-switch/deployment.yaml

# Kubernetes automatically performs rolling update
kubectl rollout status deployment/opensips -n voxguard-prod

# Rollback if needed
kubectl rollout undo deployment/opensips -n voxguard-prod
```

### Backup and Recovery

**Database Backup:**
```bash
# YugabyteDB backup
yugabyted backup --backup_location=/backup/yugabyte

# DragonflyDB snapshot
redis-cli BGSAVE
```

**Configuration Backup:**
```bash
# Backup all configs
tar -czf voxguard-config-$(date +%Y%m%d).tar.gz \
  services/voice-switch/*.cfg \
  infrastructure/production/*.yml \
  infrastructure/kubernetes/
```

---

## Disaster Recovery

### Scenario: Complete Datacenter Failure

1. **Activate Standby Datacenter:**
   ```bash
   kubectl config use-context standby-cluster
   kubectl apply -f infrastructure/kubernetes/voice-switch/
   ```

2. **Update DNS:**
   ```bash
   # Point SIP records to standby load balancer
   sip.voxguard.com -> standby-lb-ip
   ```

3. **Restore Data:**
   ```bash
   # Restore YugabyteDB from backup
   yugabyted restore --backup_location=/backup/yugabyte
   ```

4. **Verify:**
   ```bash
   # Check all health endpoints
   curl http://standby-lb/health
   ```

### Scenario: Database Corruption

1. **Switch to Read Replica:**
   ```bash
   # Update OpenSIPS config to use replica
   kubectl set env deployment/opensips DB_HOST=yugabyte-replica -n voxguard-prod
   ```

2. **Restore Primary:**
   ```bash
   # Restore from backup
   yugabyted restore --backup_location=/backup/yugabyte
   ```

3. **Switch Back:**
   ```bash
   kubectl set env deployment/opensips DB_HOST=yugabyte -n voxguard-prod
   ```

---

## Compliance

This production hardening implementation satisfies:

- ✅ **P0-3 PRD Requirements:** Production OpenSIPS config, load balancer, health checks, circuit breaker
- ✅ **High Availability:** 3+ instances with automatic failover
- ✅ **Scalability:** Horizontal auto-scaling from 3 to 10 instances
- ✅ **Resilience:** Circuit breaker prevents cascading failures
- ✅ **Observability:** Comprehensive health checks and metrics
- ✅ **Zero Downtime:** Rolling updates with pod disruption budgets
- ✅ **Backpressure Handling:** Rate limiting and connection pooling

---

## Next Steps

After deploying production hardening:

1. **P1-1: Observability & Monitoring**
   - Pre-configured Grafana dashboards
   - Distributed tracing with Jaeger
   - Alert rules for Prometheus

2. **P1-2: Advanced Detection Algorithms**
   - Sequential spoofing detection
   - Geographic impossibility checks
   - Wangiri fraud detection

3. **Production Validation**
   - Load testing at expected traffic levels
   - Chaos engineering (failure injection)
   - Security audit

---

## Support

For issues or questions:
- **Documentation:** `docs/` directory
- **Runbooks:** `docs/runbooks/`
- **Logs:** Check Grafana Loki or CloudWatch
- **Metrics:** Prometheus + Grafana

**Emergency Contacts:**
- On-Call Engineer: [PagerDuty]
- DevOps Team: [Slack #voxguard-ops]
- Security Team: [security@voxguard.com]
