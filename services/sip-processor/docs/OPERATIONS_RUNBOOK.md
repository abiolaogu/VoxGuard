# Sentinel Operations Runbook

## Quick Reference

| Scenario | Priority | Action | Page |
|----------|----------|--------|------|
| Service Down | P0 | [Service Down](#service-down-p0) | 1 |
| High Error Rate | P1 | [High Error Rate](#high-error-rate-p1) | 2 |
| Slow Performance | P2 | [Slow Performance](#slow-performance-p2) | 3 |
| Database Issues | P1 | [Database Problems](#database-issues-p1) | 4 |
| Alert Backlog | P2 | [Alert Backlog](#alert-backlog-p2) | 5 |

---

## Service Down (P0)

### Symptoms
- HTTP 5xx errors
- Health check failures
- Prometheus alert: `SentinelServiceDown`
- Unable to access `/health` endpoint

### Diagnosis

```bash
# Check pod status
kubectl get pods -n anti-call-masking -l app=sentinel-engine

# Check recent events
kubectl get events -n anti-call-masking --sort-by='.lastTimestamp'

# View pod logs
kubectl logs -n anti-call-masking -l app=sentinel-engine --tail=200

# Check pod describe for crash details
kubectl describe pod <pod-name> -n anti-call-masking
```

### Common Causes & Solutions

#### 1. OOMKilled (Out of Memory)

**Indicators**: Pod status shows `OOMKilled`

```bash
# Check memory usage history
kubectl top pods -n anti-call-masking -l app=sentinel-engine

# Temporary fix: Increase memory limits
kubectl edit deployment sentinel-engine -n anti-call-masking
# Change: memory: 4Gi -> 8Gi

# Long-term fix: Optimize memory usage
- Reduce database pool size
- Lower batch processing size
- Enable memory profiling
```

#### 2. CrashLoopBackOff

**Indicators**: Pod continuously restarting

```bash
# View previous pod logs
kubectl logs -n anti-call-masking <pod-name> --previous

# Common fixes:
# a) Database connection failure
kubectl get secret sentinel-secrets -n anti-call-masking -o yaml
# Verify DATABASE_URL is correct

# b) Missing migrations
kubectl exec -it <pod-name> -n anti-call-masking -- \
  psql $DATABASE_URL -c "SELECT * FROM call_records LIMIT 1;"

# c) Configuration error
kubectl get configmap sentinel-config -n anti-call-masking -o yaml
```

#### 3. ImagePullBackOff

**Indicators**: Unable to pull container image

```bash
# Check image name and tag
kubectl describe pod <pod-name> -n anti-call-masking | grep Image

# Fix: Update deployment with correct image
kubectl set image deployment/sentinel-engine \
  sentinel-engine=sentinel-engine:1.0.0 \
  -n anti-call-masking
```

### Resolution Steps

1. **Immediate**: Scale up healthy replicas if some are running
   ```bash
   kubectl scale deployment sentinel-engine --replicas=5 -n anti-call-masking
   ```

2. **Investigate**: Examine logs and metrics
   ```bash
   kubectl logs -n anti-call-masking -l app=sentinel-engine --tail=500 > /tmp/sentinel-logs.txt
   ```

3. **Rollback**: If caused by recent deployment
   ```bash
   kubectl rollout undo deployment/sentinel-engine -n anti-call-masking
   kubectl rollout status deployment/sentinel-engine -n anti-call-masking
   ```

4. **Verify**: Check service health
   ```bash
   kubectl port-forward -n anti-call-masking svc/sentinel-engine 8000:8000
   curl http://localhost:8000/health
   ```

### Escalation
If unresolved after 15 minutes, escalate to Platform Engineering team.

---

## High Error Rate (P1)

### Symptoms
- Prometheus alert: `SentinelHighIngestionErrorRate` or `SentinelCriticalIngestionErrorRate`
- Metric: `sentinel_cdr_ingestion_errors_total` increasing rapidly
- User reports of failed API requests

### Diagnosis

```bash
# Check error rate
curl http://sentinel-engine:8000/api/v1/sentinel/metrics | grep ingestion_errors

# View recent logs with errors
kubectl logs -n anti-call-masking -l app=sentinel-engine --tail=500 | grep ERROR

# Check Grafana dashboard: "Error Rates" panel
```

### Common Causes & Solutions

#### 1. Malformed CSV Files

**Indicators**: `ValidationError` in logs

```python
# Example error:
# "ValidationError: Invalid phone number format: +234ABC123"
```

**Solution**:
- Add input validation at upload
- Implement CSV pre-validation endpoint
- Return detailed error messages to clients

```bash
# Check recent ingestion attempts
kubectl logs -n anti-call-masking -l app=sentinel-engine | grep "POST /api/v1/sentinel/ingest"
```

#### 2. Database Connection Failures

**Indicators**: `asyncpg.exceptions.TooManyConnectionsError` or connection timeouts

```bash
# Check database connections
kubectl exec -it postgres-pod -n anti-call-masking -- \
  psql -U sentinel_user -d sentinel -c \
  "SELECT count(*) FROM pg_stat_activity WHERE datname='sentinel';"

# Check max connections
kubectl exec -it postgres-pod -n anti-call-masking -- \
  psql -U sentinel_user -d sentinel -c "SHOW max_connections;"
```

**Solution**:
```bash
# Increase max_connections in PostgreSQL
kubectl exec -it postgres-pod -n anti-call-masking -- \
  psql -U postgres -c "ALTER SYSTEM SET max_connections = 200;"

# Restart PostgreSQL
kubectl rollout restart statefulset/postgres -n anti-call-masking

# Or: Reduce pool size in Sentinel
kubectl set env deployment/sentinel-engine \
  DATABASE_POOL_MAX_SIZE=30 \
  -n anti-call-masking
```

#### 3. Duplicate Record Errors

**Indicators**: `IntegrityError` or `duplicate key value` in logs

```bash
# Check duplicate rate
curl http://sentinel-engine:8000/api/v1/sentinel/metrics | grep duplicate
```

**Solution**: This is expected behavior. Monitor the ratio:
- **Normal**: < 5% duplicates
- **Warning**: 5-10% duplicates
- **Critical**: > 10% duplicates (investigate data source)

### Resolution Steps

1. **Identify error type** from logs
2. **Isolate affected component** (parser, database, detector)
3. **Apply targeted fix** based on cause
4. **Monitor error rate** for 15 minutes
5. **Document incident** in post-mortem

### Preventive Measures
- Implement rate limiting on upload endpoint
- Add circuit breaker for database operations
- Enhance input validation

---

## Slow Performance (P2)

### Symptoms
- Prometheus alert: `SentinelSlowAPIResponses` or `SentinelSlowDetection`
- Metric: `sentinel_api_request_duration_seconds{quantile="0.95"} > 0.5`
- Users reporting timeouts

### Diagnosis

```bash
# Check API response times
curl http://sentinel-engine:8000/api/v1/sentinel/metrics | grep api_request_duration

# Check detection duration
curl http://sentinel-engine:8000/api/v1/sentinel/metrics | grep detection_duration

# Database query performance
kubectl exec -it postgres-pod -n anti-call-masking -- \
  psql -U sentinel_user -d sentinel -c \
  "SELECT pid, now() - pg_stat_activity.query_start AS duration, query
   FROM pg_stat_activity
   WHERE state = 'active'
   ORDER BY duration DESC
   LIMIT 10;"
```

### Common Causes & Solutions

#### 1. Missing Database Indexes

**Solution**:
```sql
-- Connect to database
kubectl exec -it postgres-pod -n anti-call-masking -- psql -U sentinel_user -d sentinel

-- Check existing indexes
\di

-- Add missing indexes if not present
CREATE INDEX CONCURRENTLY idx_call_records_timestamp
  ON call_records(call_timestamp);

CREATE INDEX CONCURRENTLY idx_call_records_caller_timestamp
  ON call_records(caller_number, call_timestamp);

-- Analyze tables
ANALYZE call_records;
```

#### 2. Table Bloat

**Indicators**: Large table size, slow queries

```sql
-- Check table size
SELECT pg_size_pretty(pg_total_relation_size('call_records'));

-- Run VACUUM
VACUUM ANALYZE call_records;

-- Or VACUUM FULL (requires downtime)
VACUUM FULL call_records;
```

#### 3. Low Cache Hit Rate

**Indicators**: `sentinel_cache_hit_rate < 50`

```bash
# Check cache stats
curl http://sentinel-engine:8000/api/v1/sentinel/metrics | grep cache_hit_rate
```

**Solution**:
```bash
# Increase cache TTL
kubectl edit configmap sentinel-config -n anti-call-masking
# Change: ttl_seconds: 300 -> 600

# Or: Add Redis for distributed caching
kubectl set env deployment/sentinel-engine \
  REDIS_URL=redis://redis:6379/0 \
  -n anti-call-masking
```

#### 4. High Database Pool Utilization

**Indicators**: `sentinel_database_pool_utilization > 90`

**Solution**:
```bash
# Increase pool size
kubectl set env deployment/sentinel-engine \
  DATABASE_POOL_MAX_SIZE=100 \
  -n anti-call-masking

# Monitor impact
watch -n 5 'curl -s http://sentinel-engine:8000/api/v1/sentinel/metrics | grep pool_utilization'
```

### Resolution Steps

1. **Identify bottleneck**: Database, application, or network
2. **Apply quick fix**: Scale horizontally, increase pool size
3. **Implement optimization**: Add indexes, tune queries
4. **Load test**: Verify improvement under realistic load
5. **Update runbook**: Document new thresholds

---

## Database Issues (P1)

### Symptoms
- Database connection errors
- Query timeouts
- Data inconsistencies

### Diagnosis

```bash
# Check database pod status
kubectl get pods -n anti-call-masking | grep postgres

# Check database logs
kubectl logs -n anti-call-masking postgres-pod --tail=200

# Connect to database
kubectl exec -it postgres-pod -n anti-call-masking -- \
  psql -U sentinel_user -d sentinel
```

### Common Scenarios

#### 1. Database Disk Full

```bash
# Check disk usage
kubectl exec -it postgres-pod -n anti-call-masking -- df -h

# If > 90% full, archive old data
psql -U sentinel_user -d sentinel -c \
  "DELETE FROM call_records
   WHERE call_timestamp < NOW() - INTERVAL '90 days';"

# Vacuum to reclaim space
VACUUM FULL call_records;
```

#### 2. Long-Running Queries

```sql
-- Find blocking queries
SELECT pid, now() - pg_stat_activity.query_start AS duration, query
FROM pg_stat_activity
WHERE state = 'active' AND now() - pg_stat_activity.query_start > interval '30 seconds';

-- Kill query if necessary (use with caution)
SELECT pg_terminate_backend(<pid>);
```

#### 3. Replication Lag (if using replicas)

```sql
-- Check replication status
SELECT client_addr, state, sync_state,
       pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS lag_bytes
FROM pg_stat_replication;

-- If lag > 1GB, investigate network or replica performance
```

### Recovery Procedures

#### Restore from Backup

```bash
# 1. Stop application
kubectl scale deployment sentinel-engine --replicas=0 -n anti-call-masking

# 2. Restore database
kubectl exec -it postgres-pod -n anti-call-masking -- \
  pg_restore -U sentinel_user -d sentinel /backups/sentinel-latest.dump

# 3. Verify data
kubectl exec -it postgres-pod -n anti-call-masking -- \
  psql -U sentinel_user -d sentinel -c "SELECT COUNT(*) FROM call_records;"

# 4. Start application
kubectl scale deployment sentinel-engine --replicas=3 -n anti-call-masking
```

---

## Alert Backlog (P2)

### Symptoms
- Prometheus alert: `SentinelHighUnreviewedAlerts`
- Metric: `sentinel_unreviewed_alerts > 100`
- Analysts reporting overwhelmed queue

### Diagnosis

```bash
# Check unreviewed count
curl http://sentinel-engine:8000/api/v1/sentinel/alerts?reviewed=false | jq '.count'

# Check alert distribution by severity
curl http://sentinel-engine:8000/api/v1/sentinel/metrics | grep alerts_by_severity
```

### Resolution Steps

#### 1. Triage by Severity

```bash
# Get CRITICAL alerts first
curl "http://sentinel-engine:8000/api/v1/sentinel/alerts?severity=CRITICAL&reviewed=false&limit=50"

# Review and mark false positives
curl -X PATCH "http://sentinel-engine:8000/api/v1/sentinel/alerts/123" \
  -H "Content-Type: application/json" \
  -d '{"reviewed": true, "reviewer_notes": "False positive - corporate call center"}'
```

#### 2. Bulk Operations (if needed)

```python
# Python script for bulk review
import requests

# Get all LOW severity alerts older than 7 days
response = requests.get(
    "http://sentinel-engine:8000/api/v1/sentinel/alerts",
    params={"severity": "LOW", "reviewed": "false"}
)

alerts = response.json()["alerts"]
old_alerts = [a for a in alerts if is_older_than_7_days(a["created_at"])]

# Bulk mark as reviewed
for alert in old_alerts:
    requests.patch(
        f"http://sentinel-engine:8000/api/v1/sentinel/alerts/{alert['id']}",
        json={"reviewed": True, "reviewer_notes": "Auto-reviewed: aged out"}
    )
```

#### 3. Adjust Detection Thresholds

If backlog is due to too many false positives:

```bash
# Increase SDHF thresholds to be more strict
curl -X POST "http://sentinel-engine:8000/api/v1/sentinel/detect/sdhf" \
  -H "Content-Type: application/json" \
  -d '{
    "time_window_hours": 24,
    "min_unique_destinations": 75,  # Increased from 50
    "max_avg_duration_seconds": 2.0   # Decreased from 3.0
  }'

# Update default thresholds in ConfigMap
kubectl edit configmap sentinel-config -n anti-call-masking
```

### Preventive Measures
- Implement auto-aging policy for LOW severity alerts
- Enhance detection rules to reduce false positives
- Add confidence scoring to prioritize alerts
- Scale analyst team during high-activity periods

---

## Emergency Procedures

### Complete System Restart

```bash
# 1. Scale down application
kubectl scale deployment sentinel-engine --replicas=0 -n anti-call-masking

# 2. Restart database (if necessary)
kubectl rollout restart statefulset/postgres -n anti-call-masking

# 3. Wait for database to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n anti-call-masking --timeout=300s

# 4. Scale up application
kubectl scale deployment sentinel-engine --replicas=3 -n anti-call-masking

# 5. Verify health
kubectl wait --for=condition=ready pod -l app=sentinel-engine -n anti-call-masking --timeout=300s
kubectl port-forward -n anti-call-masking svc/sentinel-engine 8000:8000
curl http://localhost:8000/health
```

### Rollback Deployment

```bash
# View deployment history
kubectl rollout history deployment/sentinel-engine -n anti-call-masking

# Rollback to previous version
kubectl rollout undo deployment/sentinel-engine -n anti-call-masking

# Rollback to specific revision
kubectl rollout undo deployment/sentinel-engine --to-revision=3 -n anti-call-masking

# Monitor rollback
kubectl rollout status deployment/sentinel-engine -n anti-call-masking
```

### Enable Debug Logging

```bash
# Temporarily enable debug logs
kubectl set env deployment/sentinel-engine LOG_LEVEL=DEBUG -n anti-call-masking

# View debug logs
kubectl logs -n anti-call-masking -l app=sentinel-engine --tail=500 -f

# Revert to INFO
kubectl set env deployment/sentinel-engine LOG_LEVEL=INFO -n anti-call-masking
```

---

## Monitoring Checklist

Daily:
- [ ] Check Grafana dashboard for anomalies
- [ ] Review unreviewed alert count
- [ ] Verify backup completion
- [ ] Check error rate trends

Weekly:
- [ ] Review performance metrics (API latency, detection duration)
- [ ] Analyze false positive rate
- [ ] Check database growth and plan for archival
- [ ] Review and update detection thresholds

Monthly:
- [ ] Conduct load testing
- [ ] Review and update this runbook
- [ ] Analyze incident patterns
- [ ] Plan capacity for next month

---

## Contact Information

| Role | Contact | Escalation Time |
|------|---------|-----------------|
| On-Call Engineer | Slack: #sentinel-oncall | Immediate |
| Database Admin | Slack: #dba-team | 15 minutes |
| Platform Engineering | Slack: #platform-eng | 30 minutes |
| Security Team | Slack: #security | 1 hour (for fraud investigation) |

## Useful Links

- **Grafana Dashboard**: https://grafana.example.com/d/sentinel
- **Prometheus**: https://prometheus.example.com
- **Kubernetes Dashboard**: https://k8s.example.com
- **Documentation**: https://docs.example.com/sentinel
- **Incident Tracker**: https://incidents.example.com

---

**Last Updated**: 2026-01-23
**Version**: 1.0.0
**Next Review**: 2026-02-23
