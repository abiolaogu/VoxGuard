# VoxGuard Disaster Recovery Plan

**Version:** 2.1.0
**Date:** February 12, 2026
**Status:** Production Active
**Owner:** VoxGuard Platform Engineering & SRE
**Classification:** Confidential -- Internal Use Only
**Compliance:** NCC ICL Framework 2026, ISO 22301 Business Continuity
**Last DR Drill:** January 18, 2026
**Next DR Drill:** April 18, 2026

---

## Table of Contents

1. [DR Objectives](#dr-objectives)
2. [Backup Strategy](#backup-strategy)
3. [Recovery Procedures](#recovery-procedures)
4. [Multi-Region Failover](#multi-region-failover)
5. [Communication Plan](#communication-plan)
6. [Testing Schedule](#testing-schedule)
7. [Runbook Integration](#runbook-integration)
8. [Post-Incident Review Process](#post-incident-review-process)
9. [AIDD Autonomous Recovery](#aidd-autonomous-recovery)
10. [DR Architecture](#dr-architecture)
11. [Appendix](#appendix)

---

## DR Objectives

### Recovery Objectives

| Objective | Target | Maximum Tolerable | Measurement |
|-----------|--------|-------------------|-------------|
| **RPO** (Recovery Point Objective) | 15 minutes | **1 hour** | Maximum data loss window |
| **RTO** (Recovery Time Objective) | 1 hour | **4 hours** | Maximum downtime duration |
| **MTPD** (Max Tolerable Period of Disruption) | 8 hours | 24 hours | Total business disruption |
| **RCO** (Recovery Consistency Objective) | 99.9% | 99.0% | Data consistency after recovery |

### Service Level Targets During DR

| Service | Availability | Latency | Throughput |
|---------|-------------|---------|------------|
| Detection Engine | 99.9% | P99 < 5ms (degraded) | 100K CPS (reduced) |
| Management API | 99.5% | P99 < 50ms | Normal |
| Frontend Dashboard | 99.5% | LCP < 5s (degraded) | Normal |
| NCC Reporting | 99.0% | Best effort | Batch mode |
| CDR Ingestion | 99.5% | < 500ms | 500K rows/sec (reduced) |

### DR Scope

```mermaid
flowchart TD
    subgraph "Tier 1 - Critical (RTO: 1h)"
        DE[Detection Engine]
        DDB[(DragonflyDB Cache)]
        YDB[(YugabyteDB Primary)]
    end

    subgraph "Tier 2 - Important (RTO: 2h)"
        MA[Management API]
        HAS[Hasura GraphQL]
        FE[Frontend Dashboard]
    end

    subgraph "Tier 3 - Standard (RTO: 4h)"
        PS[Processing Service]
        CH[(ClickHouse Analytics)]
        NCC[NCC Compliance]
    end

    subgraph "Tier 4 - Deferrable (RTO: 8h)"
        ML[ML Training Pipeline]
        REP[Report Builder]
        ARC[Archival Service]
    end
```

---

## Backup Strategy

### YugabyteDB (Primary OLTP Database)

**Strategy:** Continuous replication + hourly snapshots

```
┌───────────────────────────────────────────────────────────────────────┐
│                    YugabyteDB Backup Architecture                     │
│                                                                       │
│  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐ │
│  │  Lagos Primary  │────>│  Abuja Replica  │────>│  Asaba DR       │ │
│  │  (Synchronous)  │     │  (Async, <10s)  │     │  (Async, <30s)  │ │
│  └────────┬────────┘     └─────────────────┘     └─────────────────┘ │
│           │                                                           │
│           │  Hourly Snapshots                                        │
│           ▼                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │                  S3-Compatible Object Storage                    │  │
│  │                                                                   │  │
│  │  Hourly Snapshots     Daily Snapshots     Weekly Snapshots       │  │
│  │  (7 day retention)    (30 day retention)  (1 year retention)     │  │
│  └─────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────┘
```

| Backup Type | Frequency | Retention | Storage | RPO Impact |
|-------------|-----------|-----------|---------|-----------|
| Synchronous replication | Continuous | Real-time | Abuja replica | 0 (no data loss) |
| Async replication | Continuous (<10s lag) | Real-time | Asaba DR | < 10 seconds |
| Incremental snapshot | Every 1 hour | 7 days | S3 (Lagos) | < 1 hour |
| Full snapshot | Daily (02:00 WAT) | 30 days | S3 (Lagos + Asaba) | < 24 hours |
| Weekly archive | Sunday 03:00 WAT | 1 year | S3 Glacier | < 7 days |

**Backup Commands:**

```bash
# Manual hourly snapshot
yb-admin -master_addresses $YB_MASTER create_snapshot voxguard

# List available snapshots
yb-admin -master_addresses $YB_MASTER list_snapshots

# Export snapshot to S3
yb-admin -master_addresses $YB_MASTER export_snapshot \
  <snapshot_id> s3://voxguard-backups/yugabyte/$(date +%Y%m%d_%H%M)/

# Verify backup integrity
yb-admin -master_addresses $YB_MASTER list_snapshot_restorations
```

**Automated Backup CronJob:**

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: yugabyte-hourly-backup
  namespace: voxguard-prod
spec:
  schedule: "0 * * * *"  # Every hour
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: backup
              image: ghcr.io/voxguard/db-backup:latest
              command:
                - /bin/sh
                - -c
                - |
                  yb-admin -master_addresses $YB_MASTER create_snapshot voxguard
                  yb-admin -master_addresses $YB_MASTER export_snapshot \
                    $(yb-admin -master_addresses $YB_MASTER list_snapshots | tail -1 | awk '{print $1}') \
                    s3://voxguard-backups/yugabyte/$(date +%Y%m%d_%H%M)/
              envFrom:
                - secretRef:
                    name: yugabyte-backup-credentials
          restartPolicy: OnFailure
  successfulJobsHistoryLimit: 24
  failedJobsHistoryLimit: 3
```

### ClickHouse (Analytics Database)

**Strategy:** Daily backups with 7-year retention (NCC compliance)

| Backup Type | Frequency | Retention | Storage | Size Estimate |
|-------------|-----------|-----------|---------|--------------|
| Incremental backup | Daily (03:00 WAT) | 90 days | S3 Standard | ~50 GB/day |
| Full backup | Weekly (Sunday 04:00) | 1 year | S3 Standard | ~200 GB |
| Compliance archive | Monthly (1st, 05:00) | **7 years** | S3 Glacier Deep | ~500 GB |
| Schema backup | On every migration | Indefinite | Git repository | < 1 MB |

**Backup Commands:**

```bash
# Daily incremental backup
clickhouse-backup create --config /etc/clickhouse-backup/config.yml daily_$(date +%Y%m%d)

# Upload to S3
clickhouse-backup upload --config /etc/clickhouse-backup/config.yml daily_$(date +%Y%m%d)

# Full backup
clickhouse-backup create --config /etc/clickhouse-backup/config.yml full_$(date +%Y%m%d)
clickhouse-backup upload --config /etc/clickhouse-backup/config.yml full_$(date +%Y%m%d)

# List remote backups
clickhouse-backup list remote

# Verify backup integrity
clickhouse-backup restore_schema --config /etc/clickhouse-backup/config.yml daily_$(date +%Y%m%d) --check
```

**7-Year Retention Policy (NCC Compliance):**

```yaml
# ClickHouse backup lifecycle policy
lifecycle_rules:
  - prefix: "clickhouse/daily/"
    transitions:
      - days: 90
        storage_class: STANDARD_IA
      - days: 365
        storage_class: GLACIER
    expiration:
      days: 2555  # 7 years

  - prefix: "clickhouse/compliance/"
    transitions:
      - days: 30
        storage_class: GLACIER_DEEP_ARCHIVE
    expiration:
      days: 2555  # 7 years
    object_lock:
      mode: COMPLIANCE
      retain_until: "7 years"
```

### DragonflyDB (Real-Time Cache)

**Strategy:** RDB snapshots every 15 minutes + AOF (Append-Only File)

| Backup Type | Frequency | Retention | RPO Impact |
|-------------|-----------|-----------|-----------|
| AOF (Append-Only File) | Continuous (fsync every 1s) | Until compaction | < 1 second |
| RDB Snapshot | Every 15 minutes | 48 hours (192 snapshots) | < 15 minutes |
| RDB to S3 | Every 1 hour | 7 days | < 1 hour |

**Configuration:**

```conf
# DragonflyDB persistence configuration
save 900 1       # Snapshot if 1 key changed in 15 min
save 300 100     # Snapshot if 100 keys changed in 5 min
save 60 10000    # Snapshot if 10000 keys changed in 1 min

appendonly yes
appendfsync everysec

# Snapshot directory
dir /data/dragonfly/
dbfilename dump.rdb
```

**Backup Commands:**

```bash
# Force RDB snapshot
redis-cli -h dragonfly -p 6379 BGSAVE

# Check last save time
redis-cli -h dragonfly -p 6379 LASTSAVE

# Copy snapshot to S3
aws s3 cp /data/dragonfly/dump.rdb \
  s3://voxguard-backups/dragonfly/$(date +%Y%m%d_%H%M)/dump.rdb

# Verify snapshot integrity
redis-check-rdb /data/dragonfly/dump.rdb
```

### Hasura Metadata

**Strategy:** Git-versioned with automated export

| Backup Type | Frequency | Storage | Retention |
|-------------|-----------|---------|-----------|
| Git-versioned metadata | On every migration/change | Git repository | Indefinite |
| Metadata export | Every 6 hours | S3 | 30 days |
| Full Hasura state | Daily | S3 + Git | 90 days |

**Commands:**

```bash
# Export Hasura metadata
hasura metadata export --endpoint $HASURA_ENDPOINT --admin-secret $HASURA_ADMIN_SECRET

# Apply metadata from backup
hasura metadata apply --endpoint $HASURA_ENDPOINT --admin-secret $HASURA_ADMIN_SECRET

# Check metadata consistency
hasura metadata inconsistency list --endpoint $HASURA_ENDPOINT --admin-secret $HASURA_ADMIN_SECRET
```

### Backup Verification Matrix

All backups are verified on a schedule:

| Database | Verification Method | Frequency | Last Verified |
|----------|-------------------|-----------|---------------|
| YugabyteDB | Restore to staging + data integrity check | Weekly | Feb 9, 2026 |
| ClickHouse | Schema restore + sample query validation | Bi-weekly | Feb 2, 2026 |
| DragonflyDB | RDB load + key count comparison | Daily (automated) | Feb 12, 2026 |
| Hasura | Metadata apply to staging | Weekly | Feb 8, 2026 |

---

## Recovery Procedures

### Database Restore

#### YugabyteDB Full Restore

```bash
#!/bin/bash
# yugabyte-restore.sh
# Estimated time: 20-45 minutes depending on data volume

set -euo pipefail

SNAPSHOT_ID=${1:-"latest"}
BACKUP_PATH=${2:-"s3://voxguard-backups/yugabyte/latest/"}

echo "=== YugabyteDB Restore Procedure ==="
echo "Snapshot: $SNAPSHOT_ID"
echo "Source: $BACKUP_PATH"

# Step 1: Stop dependent services
echo "Step 1: Stopping dependent services..."
kubectl scale deployment detection-engine --replicas=0 -n voxguard-prod
kubectl scale deployment management-api --replicas=0 -n voxguard-prod
kubectl scale deployment processing-service --replicas=0 -n voxguard-prod

# Step 2: Import snapshot from S3
echo "Step 2: Importing snapshot..."
yb-admin -master_addresses $YB_MASTER import_snapshot $BACKUP_PATH

# Step 3: Restore snapshot
echo "Step 3: Restoring snapshot..."
yb-admin -master_addresses $YB_MASTER restore_snapshot $SNAPSHOT_ID

# Step 4: Verify data integrity
echo "Step 4: Verifying data integrity..."
ysqlsh -h $YB_HOST -c "SELECT count(*) FROM fraud_alerts;"
ysqlsh -h $YB_HOST -c "SELECT count(*) FROM gateways;"
ysqlsh -h $YB_HOST -c "SELECT count(*) FROM users;"

# Step 5: Restart services in correct order
echo "Step 5: Restarting services..."
kubectl scale deployment management-api --replicas=3 -n voxguard-prod
sleep 30
kubectl scale deployment detection-engine --replicas=4 -n voxguard-prod
sleep 30
kubectl scale deployment processing-service --replicas=2 -n voxguard-prod

echo "=== Restore Complete ==="
```

#### ClickHouse Restore

```bash
#!/bin/bash
# clickhouse-restore.sh
# Estimated time: 30-60 minutes for full restore

set -euo pipefail

BACKUP_NAME=${1:-"latest"}

echo "=== ClickHouse Restore Procedure ==="

# Step 1: Download backup from S3
echo "Step 1: Downloading backup..."
clickhouse-backup download $BACKUP_NAME

# Step 2: Restore schema
echo "Step 2: Restoring schema..."
clickhouse-backup restore_schema $BACKUP_NAME

# Step 3: Restore data
echo "Step 3: Restoring data..."
clickhouse-backup restore $BACKUP_NAME

# Step 4: Verify
echo "Step 4: Verifying..."
clickhouse-client --query "SELECT count() FROM cdr_records"
clickhouse-client --query "SELECT count() FROM detection_events"

echo "=== ClickHouse Restore Complete ==="
```

#### DragonflyDB Restore

```bash
#!/bin/bash
# dragonfly-restore.sh
# Estimated time: 2-5 minutes

set -euo pipefail

RDB_FILE=${1:-"/data/dragonfly/dump.rdb"}

echo "=== DragonflyDB Restore Procedure ==="

# Step 1: Stop DragonflyDB
echo "Step 1: Stopping DragonflyDB..."
kubectl scale statefulset dragonfly --replicas=0 -n voxguard-prod

# Step 2: Copy RDB file
echo "Step 2: Copying RDB snapshot..."
if [[ "$RDB_FILE" == s3://* ]]; then
  aws s3 cp $RDB_FILE /data/dragonfly/dump.rdb
fi

# Step 3: Start DragonflyDB (auto-loads RDB)
echo "Step 3: Starting DragonflyDB..."
kubectl scale statefulset dragonfly --replicas=1 -n voxguard-prod

# Step 4: Verify
echo "Step 4: Verifying..."
sleep 10
redis-cli -h dragonfly -p 6379 DBSIZE
redis-cli -h dragonfly -p 6379 INFO keyspace

echo "=== DragonflyDB Restore Complete ==="
```

### Service Restart Sequence

Services must be restarted in dependency order to prevent cascading failures:

```mermaid
flowchart TD
    subgraph "Phase 1: Data Layer (0-5 min)"
        DB1[YugabyteDB] --> DB2[DragonflyDB]
        DB1 --> DB3[ClickHouse]
    end

    subgraph "Phase 2: Infrastructure (5-10 min)"
        DB2 --> INF1[Hasura GraphQL]
        DB1 --> INF1
        DB2 --> INF2[Prometheus]
        INF2 --> INF3[Grafana]
        INF2 --> INF4[AlertManager]
    end

    subgraph "Phase 3: Core Services (10-15 min)"
        DB2 --> SVC1[Detection Engine x4]
        INF1 --> SVC2[Management API x3]
    end

    subgraph "Phase 4: Supporting Services (15-20 min)"
        SVC2 --> SVC3[Processing Service x2]
        SVC2 --> SVC4[NCC Compliance Service]
    end

    subgraph "Phase 5: Frontend (20-25 min)"
        SVC2 --> FE[Frontend Dashboard]
    end

    subgraph "Phase 6: Verification (25-30 min)"
        FE --> VER[Health Check All Endpoints]
        VER --> SMOKE[Smoke Tests]
        SMOKE --> TRAFFIC[Enable Traffic]
    end
```

**Restart Script:**

```bash
#!/bin/bash
# restart-sequence.sh
set -euo pipefail

NAMESPACE="voxguard-prod"

echo "=== VoxGuard Service Restart Sequence ==="

# Phase 1: Data Layer
echo "Phase 1: Starting data layer..."
kubectl rollout restart statefulset yugabytedb -n $NAMESPACE
kubectl rollout status statefulset yugabytedb -n $NAMESPACE --timeout=300s

kubectl rollout restart statefulset dragonfly -n $NAMESPACE
kubectl rollout status statefulset dragonfly -n $NAMESPACE --timeout=120s

kubectl rollout restart statefulset clickhouse -n $NAMESPACE
kubectl rollout status statefulset clickhouse -n $NAMESPACE --timeout=300s

# Phase 2: Infrastructure
echo "Phase 2: Starting infrastructure..."
kubectl rollout restart deployment hasura -n $NAMESPACE
kubectl rollout status deployment hasura -n $NAMESPACE --timeout=120s

# Phase 3: Core Services
echo "Phase 3: Starting core services..."
kubectl rollout restart deployment detection-engine -n $NAMESPACE
kubectl rollout status deployment detection-engine -n $NAMESPACE --timeout=180s

kubectl rollout restart deployment management-api -n $NAMESPACE
kubectl rollout status deployment management-api -n $NAMESPACE --timeout=180s

# Phase 4: Supporting Services
echo "Phase 4: Starting supporting services..."
kubectl rollout restart deployment processing-service -n $NAMESPACE
kubectl rollout status deployment processing-service -n $NAMESPACE --timeout=180s

# Phase 5: Frontend
echo "Phase 5: Starting frontend..."
kubectl rollout restart deployment web -n $NAMESPACE
kubectl rollout status deployment web -n $NAMESPACE --timeout=120s

# Phase 6: Verification
echo "Phase 6: Running verification..."
./scripts/smoke-tests.sh https://app.voxguard.ng
./scripts/post-deploy-verify.sh https://app.voxguard.ng

echo "=== All Services Restored ==="
```

### DNS Failover

```mermaid
sequenceDiagram
    participant DNS as Global DNS
    participant MON as Monitoring
    participant LAG as Lagos (Primary)
    participant ABJ as Abuja (Secondary)
    participant OPS as Ops Team

    MON->>LAG: Health check (every 10s)
    LAG-->>MON: UNHEALTHY (3 consecutive failures)
    MON->>OPS: Alert: Lagos primary down
    MON->>DNS: Update DNS weight: Lagos=0, Abuja=100
    DNS->>ABJ: Route all traffic to Abuja
    Note over ABJ: Promote read replica to primary
    ABJ-->>MON: HEALTHY
    MON->>OPS: Failover complete - Abuja serving traffic
```

**DNS Configuration:**

```yaml
# Route53 health check and failover
resource "aws_route53_health_check" "lagos_primary" {
  fqdn              = "lagos.voxguard.ng"
  port               = 443
  type               = "HTTPS"
  resource_path      = "/api/health"
  failure_threshold  = 3
  request_interval   = 10
}

resource "aws_route53_record" "voxguard_failover" {
  zone_id = var.zone_id
  name    = "app.voxguard.ng"
  type    = "A"

  failover_routing_policy {
    type = "PRIMARY"
  }

  alias {
    name                   = "lagos-lb.voxguard.ng"
    zone_id                = var.lagos_lb_zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.lagos_primary.id
  set_identifier  = "lagos-primary"
}

resource "aws_route53_record" "voxguard_failover_secondary" {
  zone_id = var.zone_id
  name    = "app.voxguard.ng"
  type    = "A"

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = "abuja-lb.voxguard.ng"
    zone_id                = var.abuja_lb_zone_id
    evaluate_target_health = true
  }

  set_identifier = "abuja-secondary"
}
```

---

## Multi-Region Failover

### Active-Passive Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        VoxGuard Multi-Region DR                         │
│                                                                         │
│  ┌──────────────────────┐    ┌──────────────────────┐                  │
│  │   Lagos (ACTIVE)     │    │   Abuja (PASSIVE)    │                  │
│  │                      │    │                      │                  │
│  │  OpenSIPS x3         │    │  OpenSIPS x1         │                  │
│  │  Detection Engine x4 │───>│  Detection Engine x2 │                  │
│  │  Management API x3   │    │  Management API x1   │                  │
│  │  Processing x2       │    │  Processing x1       │                  │
│  │                      │    │                      │                  │
│  │  YugabyteDB PRIMARY  │───>│  YugabyteDB REPLICA  │                  │
│  │  DragonflyDB PRIMARY │───>│  DragonflyDB REPLICA │                  │
│  │  ClickHouse PRIMARY  │───>│  ClickHouse REPLICA  │                  │
│  └──────────────────────┘    └──────────────────────┘                  │
│           │                           │                                │
│           │                           │                                │
│           ▼                           ▼                                │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                     Asaba (DR STANDBY)                            │  │
│  │                                                                    │  │
│  │  Minimal footprint: 1x each service, database replicas           │  │
│  │  Activated only during full regional disaster                     │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

### Data Replication Lag Targets

| Database | Lagos to Abuja | Lagos to Asaba | Measurement Method |
|----------|---------------|---------------|-------------------|
| YugabyteDB | < 10 seconds | < 30 seconds | `yb-admin get_replication_status` |
| DragonflyDB | < 5 seconds | < 15 seconds | `INFO replication` offset diff |
| ClickHouse | < 60 seconds | < 300 seconds | `system.replicas` log_pointer diff |
| Hasura Metadata | Real-time (git) | Real-time (git) | Git push confirmation |

### Replication Monitoring

```yaml
# Prometheus alerts for replication lag
groups:
  - name: replication_lag
    rules:
      - alert: YugabyteReplicationLagHigh
        expr: yugabyte_replication_lag_seconds > 30
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "YugabyteDB replication lag exceeds 30 seconds"

      - alert: YugabyteReplicationLagCritical
        expr: yugabyte_replication_lag_seconds > 120
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "YugabyteDB replication lag exceeds 2 minutes - data loss risk"

      - alert: DragonflyReplicationLagHigh
        expr: dragonfly_replication_offset_diff > 10000
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "DragonflyDB replication offset drift detected"
```

### Failover Procedures

#### Scenario 1: Single Service Failure (Auto-Recovery)

```bash
# Kubernetes handles automatically via:
# - Liveness probes restart unhealthy pods
# - Readiness probes remove from load balancer
# - ReplicaSets maintain desired pod count
# No manual intervention required
```

#### Scenario 2: Database Failure

```bash
#!/bin/bash
# db-failover.sh - Database failover to Abuja replica

echo "=== Database Failover to Abuja ==="

# Step 1: Confirm primary is down
echo "Step 1: Confirming Lagos primary is unreachable..."
if ysqlsh -h lagos-yb -c "SELECT 1" 2>/dev/null; then
  echo "WARNING: Lagos primary appears responsive. Aborting failover."
  exit 1
fi

# Step 2: Promote Abuja replica
echo "Step 2: Promoting Abuja replica to primary..."
yb-admin -master_addresses abuja-yb-master:7100 \
  change_master_config PROMOTE_REPLICA

# Step 3: Update connection strings
echo "Step 3: Updating service configurations..."
kubectl set env deployment/detection-engine \
  YUGABYTE_URL="postgres://yugabyte:$YB_PASS@abuja-yb:5433/voxguard" \
  -n voxguard-prod

kubectl set env deployment/management-api \
  DATABASE_URL="postgres://yugabyte:$YB_PASS@abuja-yb:5433/voxguard" \
  -n voxguard-prod

# Step 4: Restart services
echo "Step 4: Restarting services with new connection..."
kubectl rollout restart deployment/detection-engine -n voxguard-prod
kubectl rollout restart deployment/management-api -n voxguard-prod

# Step 5: Verify
echo "Step 5: Verifying..."
kubectl rollout status deployment/detection-engine -n voxguard-prod --timeout=180s
./scripts/smoke-tests.sh https://app.voxguard.ng

echo "=== Database Failover Complete ==="
```

#### Scenario 3: Full Regional Failure (Lagos Down)

```bash
#!/bin/bash
# full-regional-failover.sh
# AIDD Tier: T2 - Requires admin approval
# Estimated time: 15-30 minutes

echo "=== FULL REGIONAL FAILOVER: Lagos -> Abuja ==="
echo "This is a T2 operation requiring admin approval"
echo "Estimated completion time: 15-30 minutes"

# Step 1: Verify Lagos is truly down
echo "Step 1: Multi-point Lagos health check..."
LAGOS_CHECKS=0
for endpoint in "lagos-lb:443" "lagos-yb:5433" "lagos-df:6379"; do
  if ! nc -z -w5 ${endpoint%%:*} ${endpoint##*:} 2>/dev/null; then
    ((LAGOS_CHECKS++))
  fi
done

if [ $LAGOS_CHECKS -lt 2 ]; then
  echo "WARNING: Lagos appears partially available ($LAGOS_CHECKS/3 checks failed)"
  echo "Consider targeted failover instead of full regional"
  read -p "Continue with full failover? (yes/no): " CONFIRM
  [ "$CONFIRM" != "yes" ] && exit 1
fi

# Step 2: DNS failover
echo "Step 2: Updating DNS to point to Abuja..."
aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch file://dns-failover-abuja.json

# Step 3: Promote Abuja databases
echo "Step 3: Promoting Abuja database replicas..."
yb-admin -master_addresses abuja-yb-master:7100 change_master_config PROMOTE_REPLICA

# Step 4: Scale up Abuja services
echo "Step 4: Scaling up Abuja services..."
kubectl scale deployment detection-engine --replicas=4 -n voxguard-prod --context abuja
kubectl scale deployment management-api --replicas=3 -n voxguard-prod --context abuja
kubectl scale deployment processing-service --replicas=2 -n voxguard-prod --context abuja

# Step 5: Verify
echo "Step 5: Verification..."
sleep 60
./scripts/smoke-tests.sh https://app.voxguard.ng
./scripts/post-deploy-verify.sh https://app.voxguard.ng

echo "=== Full Regional Failover Complete ==="
echo "Abuja is now serving all production traffic"
echo "ACTION REQUIRED: Plan Lagos recovery and failback"
```

---

## Communication Plan

### Incident Severity Levels

```mermaid
flowchart TD
    INC[Incident Detected] --> SEV{Severity?}

    SEV -->|SEV-1| S1[CRITICAL: Total service outage]
    SEV -->|SEV-2| S2[MAJOR: Partial outage or degradation]
    SEV -->|SEV-3| S3[MINOR: Non-critical component failure]
    SEV -->|SEV-4| S4[LOW: Cosmetic or informational]

    S1 --> N1[Page on-call + CTO + NCC liaison]
    S2 --> N2[Page on-call + Engineering Lead]
    S3 --> N3[Notify engineering Slack channel]
    S4 --> N4[Log in incident tracker]

    N1 --> T1[War room within 15 min]
    N2 --> T2[Response within 30 min]
    N3 --> T3[Response within 2 hours]
    N4 --> T4[Response next business day]
```

### Severity Definitions

| Severity | Definition | Examples | Response Time | Communication Cadence |
|----------|-----------|----------|--------------|----------------------|
| **SEV-1** | Total platform outage; all detection offline; NCC compliance at risk | Full regional failure, database corruption, security breach | 15 min | Every 30 min |
| **SEV-2** | Partial outage; detection degraded (< 50% capacity); single region down | One region offline, ClickHouse down, DragonflyDB failure | 30 min | Every 1 hour |
| **SEV-3** | Non-critical service failure; no detection impact | Dashboard slow, report generation failure, ML training stuck | 2 hours | Every 4 hours |
| **SEV-4** | Cosmetic issue; informational alert | UI glitch, non-critical log errors, metric collection gap | Next business day | On resolution |

### Notification Chain

```
SEV-1 (Critical):
  T+0 min:   PagerDuty → On-Call Engineer
  T+5 min:   Slack #voxguard-incidents → Engineering Team
  T+10 min:  Email → Engineering Lead, CTO
  T+15 min:  War Room (Google Meet) → All responders
  T+30 min:  Email → NCC Liaison (if compliance impact)
  T+60 min:  Status Page Update → External stakeholders

SEV-2 (Major):
  T+0 min:   PagerDuty → On-Call Engineer
  T+5 min:   Slack #voxguard-incidents → Engineering Team
  T+15 min:  Email → Engineering Lead
  T+30 min:  Slack update with ETA

SEV-3 (Minor):
  T+0 min:   Slack #voxguard-alerts → Engineering Team
  T+30 min:  JIRA ticket created
  T+2 hours: Engineer assigned

SEV-4 (Low):
  T+0 min:   JIRA ticket created
  T+1 day:   Triaged in standup
```

### Communication Templates

**SEV-1 Initial Notification:**
```
INCIDENT: [SEV-1] VoxGuard Platform Outage
TIME: [UTC timestamp]
IMPACT: [Description of user/business impact]
STATUS: Investigating
RESPONDERS: [Names]
WAR ROOM: [Meet link]
NEXT UPDATE: [Time]
```

**Status Page Update:**
```
[INVESTIGATING] We are aware of an issue affecting VoxGuard fraud detection services.
Our team is actively investigating. CDR processing may be delayed.
We will provide updates every 30 minutes.
```

---

## Testing Schedule

### DR Drill Calendar

| Quarter | Drill Type | Scope | Date | Duration | Participants |
|---------|-----------|-------|------|----------|-------------|
| Q1 2026 | Tabletop Exercise | Full DR scenario walkthrough | Jan 18, 2026 | 4 hours | Full team |
| Q1 2026 | Database Failover | YugabyteDB replica promotion | Feb 15, 2026 | 2 hours | SRE team |
| Q2 2026 | Full Regional Failover | Lagos to Abuja failover | Apr 18, 2026 | 6 hours | Full team |
| Q2 2026 | Backup Restore | ClickHouse 7-year archive restore | May 10, 2026 | 3 hours | SRE + Compliance |
| Q3 2026 | Chaos Engineering | Random service termination | Jul 18, 2026 | 4 hours | SRE team |
| Q3 2026 | Communication Drill | Notification chain validation | Aug 15, 2026 | 1 hour | All stakeholders |
| Q4 2026 | Full DR Simulation | Complete platform recovery | Oct 18, 2026 | 8 hours | Full team + NCC |
| Q4 2026 | Tabletop Exercise | Lessons learned review | Nov 15, 2026 | 4 hours | Full team |

### Drill Execution Checklist

- [ ] Pre-drill briefing completed (1 day before)
- [ ] Drill scope and success criteria documented
- [ ] Rollback plan ready for drill environment
- [ ] Monitoring dashboards open and recording
- [ ] Communication channels tested
- [ ] Timer started at drill initiation
- [ ] Each recovery step timed individually
- [ ] Data integrity verified after recovery
- [ ] All health checks pass post-recovery
- [ ] Drill report drafted within 48 hours
- [ ] Action items assigned and tracked

### Drill Success Criteria

| Metric | Target | Pass/Fail |
|--------|--------|-----------|
| RTO achieved | < 4 hours | Required |
| RPO achieved | < 1 hour data loss | Required |
| All health checks pass | 100% | Required |
| Data integrity | 99.9%+ consistency | Required |
| Communication chain | All notified within SLA | Required |
| Runbook accuracy | No undocumented steps needed | Advisory |

---

## Runbook Integration

### Runbook Cross-References

| Scenario | Runbook | Location |
|----------|---------|----------|
| General operations | Operations Runbook | [runbook.md](./runbook.md) |
| Service restart | Service Restart Sequence | This document, Section 3 |
| Database restore | Database Recovery | This document, Section 3 |
| DNS failover | DNS Failover Procedure | This document, Section 3 |
| Full regional failover | Regional Failover | This document, Section 4 |
| Security incident | Incident Response | [SECURITY_HARDENING.md](./SECURITY_HARDENING.md) |
| Performance degradation | Performance Tuning | [runbook.md](./runbook.md#performance-tuning) |
| NCC compliance issue | NCC Operations | [runbook.md](./runbook.md#ncc-compliance-operations) |

### Automated Runbook Execution

VoxGuard integrates runbooks with the AIDD autonomous recovery system. Pre-approved runbooks execute automatically based on alert triggers:

```yaml
# Runbook automation configuration
runbooks:
  service_restart:
    trigger: "pod_crash_loop"
    aidd_tier: T0
    auto_execute: true
    max_attempts: 3
    cooldown: 5m

  scale_up:
    trigger: "high_cpu_utilization"
    aidd_tier: T1
    auto_execute: true
    max_replicas: 10
    cooldown: 10m

  database_failover:
    trigger: "primary_db_unreachable"
    aidd_tier: T2
    auto_execute: false  # Requires admin approval
    notification: ["pagerduty", "slack", "email"]

  full_regional_failover:
    trigger: "region_unreachable"
    aidd_tier: T2
    auto_execute: false  # Requires admin approval
    notification: ["pagerduty", "slack", "email", "ncc"]
```

---

## Post-Incident Review Process

### Post-Incident Review (PIR) Timeline

```
Incident Resolved
    │
    ├── T+2 hours:  Initial incident summary posted
    ├── T+24 hours: Timeline reconstruction begins
    ├── T+48 hours: PIR document drafted
    ├── T+72 hours: PIR meeting scheduled
    ├── T+5 days:   PIR meeting conducted
    ├── T+7 days:   Action items assigned in JIRA
    └── T+30 days:  Action items completion review
```

### PIR Document Template

```markdown
# Post-Incident Review: [Incident Title]

## Summary
- **Date:** [Date]
- **Duration:** [Start time - End time]
- **Severity:** [SEV-1/2/3/4]
- **Impact:** [User/business impact summary]
- **Detection Method:** [How was it detected?]
- **Resolution:** [How was it resolved?]

## Timeline
| Time (WAT) | Event |
|------------|-------|
| HH:MM | First alert triggered |
| HH:MM | On-call engineer paged |
| HH:MM | Root cause identified |
| HH:MM | Fix deployed |
| HH:MM | Service restored |
| HH:MM | All-clear declared |

## Root Cause Analysis
[5 Whys or Fishbone analysis]

## What Went Well
- [Item 1]
- [Item 2]

## What Went Poorly
- [Item 1]
- [Item 2]

## Action Items
| ID | Action | Owner | Due Date | Priority |
|----|--------|-------|----------|----------|
| 1  | [Action] | [Owner] | [Date] | P1/P2/P3 |

## Lessons Learned
[Key takeaways]

## DR Plan Updates Required
[Any changes needed to this DR plan]
```

### Blameless Culture Guidelines

1. Focus on systems and processes, not individuals
2. Assume everyone acted with the best information available
3. Identify systemic improvements, not punitive measures
4. Share findings openly to prevent recurrence
5. Update documentation and runbooks based on lessons learned
6. Track action items to completion

---

## AIDD Autonomous Recovery

### Tier-Based Autonomous Actions

VoxGuard's AIDD system enables autonomous recovery for pre-approved operational scenarios, reducing mean time to recovery (MTTR) and minimizing human error during high-stress incidents.

```mermaid
flowchart TD
    ALERT[Alert Triggered] --> CLASS[AIDD Classifier]

    CLASS --> T0{Tier 0?}
    T0 -->|Yes| AUTO0[Auto-Execute Recovery]
    AUTO0 --> LOG0[Log Action + Notify]

    T0 -->|No| T1{Tier 1?}
    T1 -->|Yes| AUTO1[Auto-Execute with Notification]
    AUTO1 --> LOG1[Log Action + Alert Team]

    T1 -->|No| T2{Tier 2?}
    T2 -->|Yes| PAGE[Page Admin for Approval]
    PAGE --> APPROVE{Approved?}
    APPROVE -->|Yes| EXEC[Execute Recovery]
    APPROVE -->|No| MANUAL[Manual Investigation]
    EXEC --> LOG2[Log Action + Full Audit]
```

### Tier 0: Auto-Restart Services (No Approval Required)

Automatic actions for recoverable, low-risk failures:

| Trigger | Action | Max Attempts | Cooldown |
|---------|--------|-------------|----------|
| Pod CrashLoopBackOff | Restart pod | 3 | 5 minutes |
| OOMKilled | Restart with +25% memory | 2 | 10 minutes |
| Health check failure (single pod) | Delete and recreate pod | 3 | 5 minutes |
| Certificate expiry warning | Trigger cert-manager renewal | 1 | 24 hours |
| Log volume spike | Increase Loki retention temporarily | 1 | 1 hour |
| DragonflyDB connection timeout | Restart DragonflyDB client pool | 3 | 2 minutes |

**Implementation:**

```yaml
# Kubernetes-based auto-restart (native)
spec:
  containers:
    - name: detection-engine
      livenessProbe:
        httpGet:
          path: /health
          port: 8080
        initialDelaySeconds: 10
        periodSeconds: 10
        failureThreshold: 3  # Restart after 3 failures
      resources:
        requests:
          memory: "256Mi"
          cpu: "250m"
        limits:
          memory: "512Mi"
          cpu: "1000m"
```

### Tier 1: Scale Up Resources (Notification Required)

Automatic scaling with team notification:

| Trigger | Action | Threshold | Max Scale | Notification |
|---------|--------|-----------|----------|-------------|
| CPU > 80% sustained 5m | HPA scale up | 80% CPU | 10 replicas | Slack |
| Memory > 75% sustained 5m | HPA scale up | 75% memory | 10 replicas | Slack |
| CPS > 120K sustained | Scale detection engine | 120K CPS | 8 replicas | Slack + Email |
| Queue depth > 10K | Scale processing service | 10K messages | 5 replicas | Slack |
| P99 latency > 3ms | Scale detection + cache | 3ms P99 | 8 replicas | Slack |
| DragonflyDB memory > 80% | Trigger eviction policy | 80% memory | N/A | Slack |

**Implementation:**

```yaml
# HorizontalPodAutoscaler
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: detection-engine-hpa
  namespace: voxguard-prod
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: detection-engine
  minReplicas: 4
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 80
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 75
    - type: Pods
      pods:
        metric:
          name: acm_calls_per_second
        target:
          type: AverageValue
          averageValue: "30000"  # Per pod CPS target
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
        - type: Percent
          value: 50
          periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 25
          periodSeconds: 120
```

### Tier 2: Failover to DR Site (Admin Approval Required)

High-impact recovery actions requiring explicit admin authorization:

| Trigger | Action | Approval Required | SLA |
|---------|--------|------------------|-----|
| Primary region unreachable (5 min) | Full regional failover | Admin + CTO | 15 min response |
| Primary database corrupted | Promote DR replica | Admin | 10 min response |
| Security breach detected | Isolate affected services | Admin + Security Lead | 5 min response |
| NCC compliance violation | Emergency compliance mode | Admin + Compliance | 15 min response |
| Data loss detected | Point-in-time recovery | Admin + CTO | 10 min response |

**Approval Workflow:**

```
Alert Fires (T2 Trigger)
    │
    ├── PagerDuty pages Admin on-call
    ├── Slack #voxguard-incidents with one-click approve button
    ├── Email to admin distribution list
    │
    ▼
Admin Reviews (via Slack/PagerDuty/CLI)
    │
    ├── Approves → AIDD executes recovery runbook
    │              └── Full audit trail logged
    │              └── Post-recovery verification
    │              └── Notification to all stakeholders
    │
    └── Rejects → Manual investigation initiated
                  └── Incident commander assigned
                  └── War room opened
```

---

## DR Architecture

### Infrastructure Dependencies

```mermaid
flowchart TD
    subgraph "External Dependencies"
        DNS[Global DNS]
        S3[S3 Object Storage]
        VAULT[HashiCorp Vault]
        NCC_API[NCC ATRS API]
    end

    subgraph "Lagos Primary"
        LB_L[Load Balancer]
        K8S_L[Kubernetes Cluster]
        YB_L[(YugabyteDB)]
        DF_L[(DragonflyDB)]
        CH_L[(ClickHouse)]
    end

    subgraph "Abuja Secondary"
        LB_A[Load Balancer]
        K8S_A[Kubernetes Cluster]
        YB_A[(YugabyteDB Replica)]
        DF_A[(DragonflyDB Replica)]
        CH_A[(ClickHouse Replica)]
    end

    DNS --> LB_L
    DNS -.-> LB_A
    YB_L -->|Sync Repl| YB_A
    DF_L -->|Async Repl| DF_A
    CH_L -->|Async Repl| CH_A
    K8S_L --> S3
    K8S_A --> S3
    K8S_L --> VAULT
    K8S_A --> VAULT
```

### DR Cost Analysis

| Component | Primary (Lagos) | DR (Abuja) | Monthly Cost |
|-----------|-----------------|------------|-------------|
| Kubernetes nodes | 6 nodes (8 vCPU, 32GB) | 3 nodes (8 vCPU, 32GB) | $2,400 |
| Database storage | 2 TB NVMe | 2 TB NVMe (replica) | $800 |
| S3 backup storage | 5 TB (hot + warm) | Shared | $150 |
| S3 Glacier (7-year) | 20 TB (growing) | N/A | $80 |
| Network (cross-region) | N/A | Replication traffic | $200 |
| **Total DR overhead** | | | **$3,630/month** |

---

## Appendix

### A. Key Contacts

| Role | Name | Contact | Backup |
|------|------|---------|--------|
| On-Call Engineer | Rotating | PagerDuty | Secondary on-call |
| Engineering Lead | [TBD] | Slack/Phone | Deputy Lead |
| CTO | [TBD] | Phone (SEV-1 only) | VP Engineering |
| NCC Liaison | [TBD] | Email/Phone | Compliance Officer |
| DBA | [TBD] | Slack/Phone | SRE Team |

### B. External Vendor Contacts

| Vendor | Service | Support Level | Contact |
|--------|---------|--------------|---------|
| Cloud Provider | Infrastructure | 24/7 Premium | Support portal |
| YugabyteDB | Database support | Enterprise | support@yugabyte.com |
| Grafana Labs | Monitoring | Pro | support@grafana.com |
| HashiCorp | Vault | Enterprise | support@hashicorp.com |

### C. Related Documentation

- [ARCHITECTURE.md](./ARCHITECTURE.md) -- System architecture
- [DEPLOYMENT.md](./DEPLOYMENT.md) -- Deployment procedures
- [MULTI_REGION_DEPLOYMENT.md](./MULTI_REGION_DEPLOYMENT.md) -- Multi-region setup
- [OBSERVABILITY.md](./OBSERVABILITY.md) -- Monitoring and alerting
- [SECURITY_HARDENING.md](./SECURITY_HARDENING.md) -- Security controls
- [DATA_RETENTION_ARCHIVAL.md](./DATA_RETENTION_ARCHIVAL.md) -- Data retention policy
- [CICD_PIPELINE.md](./CICD_PIPELINE.md) -- CI/CD pipeline
- [runbook.md](./runbook.md) -- Operations runbook
- [AIDD_APPROVAL_TIERS.md](./AIDD_APPROVAL_TIERS.md) -- AIDD tier definitions

### D. Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | Jan 15, 2026 | Platform Team | Initial DR plan |
| 1.5.0 | Feb 4, 2026 | SRE Team | Added multi-region failover procedures |
| 2.0.0 | Feb 5, 2026 | Platform Team | AIDD autonomous recovery integration |
| 2.1.0 | Feb 12, 2026 | Platform Team | Added 7-year ClickHouse retention, quarterly drill schedule |
