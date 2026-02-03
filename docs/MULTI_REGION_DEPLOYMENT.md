# VoxGuard Multi-Region Deployment Guide

**Version:** 1.0
**Date:** February 3, 2026
**Status:** Production Ready
**Owner:** VoxGuard Platform Team

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Deployment Steps](#deployment-steps)
5. [Database Replication](#database-replication)
6. [Load Balancing](#load-balancing)
7. [Monitoring](#monitoring)
8. [Failover Procedures](#failover-procedures)
9. [Performance Tuning](#performance-tuning)
10. [Troubleshooting](#troubleshooting)
11. [Disaster Recovery](#disaster-recovery)

---

## Overview

### Purpose

This guide describes the deployment and operation of VoxGuard across three Nigerian regions for high availability, disaster recovery, and regulatory compliance (NCC data residency requirements).

### Regional Distribution

| Region | Role | Infrastructure | Purpose |
|--------|------|----------------|---------|
| **Lagos** | Primary | 3x OpenSIPS, 4x ACM, Primary DB | 70% traffic, primary writes, main data center |
| **Abuja** | Replica | 1x OpenSIPS, 2x ACM, Read replica | 15% traffic, regional reads, failover target |
| **Asaba** | Replica | 1x OpenSIPS, 2x ACM, Read replica | 15% traffic, regional reads, DR site |

### Key Features

- **Geographic Distribution:** Three regions across Nigeria
- **High Availability:** 99.99% uptime SLA
- **Automatic Failover:** <30 seconds recovery time
- **Data Replication:** Real-time replication (DragonflyDB) and geo-distributed consensus (YugabyteDB)
- **Regional Load Balancing:** Traffic distribution based on geography and weights
- **Disaster Recovery:** RPO <1 minute, RTO <15 minutes

---

## Architecture

### High-Level Topology

```
                                   ┌─────────────────┐
                                   │   Global DNS    │
                                   │  / Route Policy │
                                   └────────┬────────┘
                                            │
                         ┌──────────────────┼──────────────────┐
                         │                  │                  │
                    ┌────▼─────┐      ┌────▼─────┐      ┌────▼─────┐
                    │  Lagos   │      │  Abuja   │      │  Asaba   │
                    │  Region  │      │  Region  │      │  Region  │
                    └────┬─────┘      └────┬─────┘      └────┬─────┘
                         │                  │                  │
          ┌──────────────┼──────────────┐   │                  │
          │              │              │   │                  │
     ┌────▼────┐    ┌────▼────┐   ┌────▼───┴─┐           ┌────▼────┐
     │OpenSIPS │    │OpenSIPS │   │OpenSIPS  │           │OpenSIPS │
     │   x3    │    │ Lagos-3 │   │ Abuja-1  │           │ Asaba-1 │
     └────┬────┘    └────┬────┘   └────┬─────┘           └────┬────┘
          │              │              │                      │
          └──────────────┼──────────────┤                      │
                         │              │                      │
                    ┌────▼────┐    ┌────▼─────┐          ┌────▼─────┐
                    │   ACM   │    │   ACM    │          │   ACM    │
                    │ Engine  │    │  Engine  │          │  Engine  │
                    │   x4    │    │    x2    │          │    x2    │
                    └────┬────┘    └────┬─────┘          └────┬─────┘
                         │              │                      │
          ┌──────────────┼──────────────┼──────────────────────┤
          │              │              │                      │
     ┌────▼────┐    ┌────▼────┐   ┌────▼─────┐          ┌────▼─────┐
     │Yugabyte │    │Dragonfly│   │Yugabyte  │          │Yugabyte  │
     │ Primary │    │ Primary │   │ Replica  │          │ Replica  │
     │  (RF=3) │    │(Replicas│   │  (Read)  │          │  (Read)  │
     └─────────┘    └─────────┘   └──────────┘          └──────────┘

                    Primary Data Center        Replica Regions
```

### Network Configuration

#### VPC CIDR Blocks

- **Lagos:** `10.0.0.0/16`
  - Public Subnet: `10.0.1.0/24`
  - Private Subnet: `10.0.10.0/24`
  - Database Subnet: `10.0.20.0/24`

- **Abuja:** `10.1.0.0/16`
  - Public Subnet: `10.1.1.0/24`
  - Private Subnet: `10.1.10.0/24`
  - Database Subnet: `10.1.20.0/24`

- **Asaba:** `10.2.0.0/16`
  - Public Subnet: `10.2.1.0/24`
  - Private Subnet: `10.2.10.0/24`
  - Database Subnet: `10.2.20.0/24`

#### Inter-Region Connectivity

- **VPN Mesh:** Site-to-site VPN between all regions
- **Latency Requirements:**
  - Lagos ↔ Abuja: <20ms
  - Lagos ↔ Asaba: <30ms
  - Abuja ↔ Asaba: <25ms
- **Bandwidth:** Minimum 1 Gbps per inter-region link

---

## Prerequisites

### Infrastructure Requirements

**Per Region:**
- Kubernetes cluster v1.28+
- Minimum 5 worker nodes (production)
- 64 CPU cores total
- 256 GB RAM total
- 2 TB SSD storage

**Networking:**
- VPN gateway for inter-region connectivity
- Public IP addresses for external SIP traffic
- DNS resolution for internal services

**Security:**
- TLS certificates for SIP TLS
- VPN certificates for site-to-site connectivity
- Secret management system (Kubernetes Secrets or Vault)

### Software Requirements

- Terraform v1.6+
- kubectl v1.28+
- helm v3.12+
- YugabyteDB Operator v2.18+
- DragonflyDB v1.13+
- HAProxy v2.9+
- OpenSIPS v3.4+

---

## Deployment Steps

### Step 1: Prepare Terraform State Backend

```bash
# Create S3 bucket for Terraform state (if using AWS)
aws s3api create-bucket \
  --bucket voxguard-terraform-state \
  --region af-south-1 \
  --create-bucket-configuration LocationConstraint=af-south-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket voxguard-terraform-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name voxguard-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region af-south-1

# Update backend configuration in main.tf
cd infrastructure/terraform
# Uncomment the backend "s3" block and configure
```

### Step 2: Configure Variables

Create `terraform.tfvars`:

```hcl
environment = "production"

vpc_cidrs = {
  lagos = "10.0.0.0/16"
  abuja = "10.1.0.0/16"
  asaba = "10.2.0.0/16"
}

circuit_breaker_config = {
  failure_threshold = 5
  timeout_seconds   = 30
  success_threshold = 2
}

grafana_admin_password = "CHANGE_THIS_PASSWORD"

enable_auto_scaling           = true
enable_pod_disruption_budget  = true
enable_network_policies       = true
enable_disaster_recovery      = true
enable_encryption_at_rest     = true
enable_encryption_in_transit  = true

alert_email = "ops@voxguard.ng"

# Optional: Slack webhook for alerts
# alert_slack_webhook = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

### Step 3: Initialize Terraform

```bash
cd infrastructure/terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan -out=tfplan

# Review the plan carefully
less tfplan
```

### Step 4: Deploy Infrastructure

```bash
# Apply Terraform configuration
terraform apply tfplan

# This will deploy:
# - VPC and networking in all three regions
# - DragonflyDB clusters with replication
# - YugabyteDB clusters with geo-distribution
# - OpenSIPS instances
# - ACM detection engines
# - Regional load balancers
# - Monitoring stack (Prometheus, Grafana, Tempo)

# Deployment time: ~30-45 minutes
```

### Step 5: Verify Deployment

```bash
# Check regional endpoints
terraform output regional_endpoints

# Check database endpoints
terraform output database_endpoints

# Check load balancer endpoint
terraform output load_balancer_endpoint

# Verify Kubernetes deployments
kubectl get pods --all-namespaces

# Check service health
kubectl get svc -n voxguard-prod
```

### Step 6: Configure Database Replication

See [Database Replication](#database-replication) section below.

### Step 7: Validate Load Balancing

```bash
# Access HAProxy stats page
open http://<haproxy-lb-ip>:8404/stats

# Test SIP connectivity to each region
sipsak -s sip:<lagos-opensips-ip>:5060
sipsak -s sip:<abuja-opensips-ip>:5060
sipsak -s sip:<asaba-opensips-ip>:5060

# Test global load balancer
sipsak -s sip:<global-lb-ip>:5060
```

### Step 8: Configure Monitoring

```bash
# Access Grafana
open http://<grafana-endpoint>

# Import multi-region dashboards
# Located in: monitoring/grafana/dashboards/multi-region/

# Configure alert rules
kubectl apply -f monitoring/prometheus/alerts/multi-region-alerts.yml

# Verify alerts are firing
kubectl logs -n voxguard-monitoring deployment/prometheus -f
```

---

## Database Replication

### DragonflyDB Replication

DragonflyDB uses master-replica replication for cache and session state.

#### Architecture

- **Primary (Lagos):** 1 master node accepting writes
- **Replicas (Abuja, Asaba):** Read-only replicas with async replication

#### Configuration

Configuration file: `infrastructure/dragonfly/replication.conf`

#### Deployment

```bash
# Deploy DragonflyDB primary (Lagos)
kubectl apply -f infrastructure/dragonfly/replication.conf

# Verify primary is running
kubectl get pods -n voxguard-prod -l role=primary

# Deploy replicas (Abuja, Asaba)
kubectl apply -f infrastructure/dragonfly/replication.conf

# Verify replication status
kubectl exec -n voxguard-prod dragonfly-primary-0 -- \
  redis-cli -a $DRAGONFLY_PASSWORD INFO replication

# Expected output:
# role:master
# connected_slaves:2
# slave0:ip=<abuja-ip>,port=6379,state=online,offset=xxxxx,lag=0
# slave1:ip=<asaba-ip>,port=6379,state=online,offset=xxxxx,lag=1
```

#### Monitoring Replication Lag

```bash
# Check replication lag (should be <100ms)
kubectl exec -n voxguard-prod dragonfly-replica-0 -- \
  redis-cli -a $DRAGONFLY_PASSWORD INFO replication | grep master_last_io_seconds_ago

# Monitor lag continuously
watch -n 1 "kubectl exec -n voxguard-prod dragonfly-replica-0 -- \
  redis-cli -a $DRAGONFLY_PASSWORD INFO replication | grep master_last_io_seconds_ago"
```

#### Failover

```bash
# Promote Abuja replica to master (manual failover)
kubectl exec -n voxguard-prod dragonfly-replica-0 -- \
  redis-cli -a $DRAGONFLY_PASSWORD REPLICAOF NO ONE

# Update application to point to new master
# Update ConfigMap with new master endpoint
kubectl edit configmap voxguard-config -n voxguard-prod

# Restart applications to pick up new endpoint
kubectl rollout restart deployment -n voxguard-prod
```

---

### YugabyteDB Geo-Distribution

YugabyteDB uses Raft consensus for strong consistency across regions.

#### Architecture

- **Replication Factor:** 3 (data replicated to 3 nodes)
- **Leader Preference:** Lagos for write operations
- **Read Replicas:** Abuja and Asaba for low-latency reads

#### Configuration

Configuration file: `infrastructure/yugabyte/multi-region.conf`

#### Deployment

```bash
# Deploy YugabyteDB cluster
kubectl apply -f infrastructure/yugabyte/multi-region.conf

# Wait for cluster to be ready (5-10 minutes)
kubectl wait --for=condition=Ready pod -l app=yb-tserver -n yb-platform --timeout=600s

# Verify cluster status
kubectl exec -n yb-platform yb-master-0 -- \
  yb-admin list_all_tablet_servers

# Check replication status
kubectl exec -n yb-platform yb-tserver-0 -- \
  ysqlsh -h localhost -c "SELECT * FROM yb_replication_status();"
```

#### Create Geo-Partitioned Tables

```sql
-- Connect to YugabyteDB
kubectl exec -it -n yb-platform yb-tserver-0 -- \
  ysqlsh -h localhost -U yugabyte -d voxguard

-- Create tablespaces for each region
CREATE TABLESPACE lagos_tablespace WITH (
  replica_placement='{"num_replicas":3, "placement_blocks":[
    {"cloud":"on-premise","region":"lagos","zone":"lagos-az1","min_num_replicas":1},
    {"cloud":"on-premise","region":"lagos","zone":"lagos-az2","min_num_replicas":1},
    {"cloud":"on-premise","region":"abuja","zone":"abuja-az1","min_num_replicas":1}
  ]}'
);

CREATE TABLESPACE abuja_tablespace WITH (
  replica_placement='{"num_replicas":2, "placement_blocks":[
    {"cloud":"on-premise","region":"abuja","zone":"abuja-az1","min_num_replicas":1},
    {"cloud":"on-premise","region":"lagos","zone":"lagos-az1","min_num_replicas":1}
  ]}'
);

CREATE TABLESPACE asaba_tablespace WITH (
  replica_placement='{"num_replicas":2, "placement_blocks":[
    {"cloud":"on-premise","region":"asaba","zone":"asaba-az1","min_num_replicas":1},
    {"cloud":"on-premise","region":"lagos","zone":"lagos-az1","min_num_replicas":1}
  ]}'
);

-- Create partitioned table
CREATE TABLE fraud_alerts (
  alert_id UUID PRIMARY KEY,
  timestamp TIMESTAMP,
  severity VARCHAR(20),
  source_number VARCHAR(20),
  destination_number VARCHAR(20),
  gateway_id UUID,
  region VARCHAR(20)
) PARTITION BY LIST (region);

-- Create partitions
CREATE TABLE fraud_alerts_lagos PARTITION OF fraud_alerts
  FOR VALUES IN ('lagos') TABLESPACE lagos_tablespace;

CREATE TABLE fraud_alerts_abuja PARTITION OF fraud_alerts
  FOR VALUES IN ('abuja') TABLESPACE abuja_tablespace;

CREATE TABLE fraud_alerts_asaba PARTITION OF fraud_alerts
  FOR VALUES IN ('asaba') TABLESPACE asaba_tablespace;
```

#### Monitoring Replication

```bash
# Check tablet distribution
kubectl exec -n yb-platform yb-tserver-0 -- \
  ysqlsh -h localhost -c "SELECT * FROM yb_local_tablets;"

# Monitor leader distribution
kubectl exec -n yb-platform yb-master-0 -- \
  yb-admin get_load_balancer_state

# Check replication lag (should be <10ms)
kubectl exec -n yb-platform yb-tserver-0 -- \
  ysqlsh -h localhost -c "SELECT * FROM yb_replication_status();"
```

---

## Load Balancing

### Regional Load Balancer (HAProxy)

Configuration file: `infrastructure/haproxy/multi-region.cfg`

#### Deployment

```bash
# Deploy HAProxy
kubectl apply -f infrastructure/haproxy/multi-region.cfg

# Verify deployment
kubectl get pods -n voxguard-prod -l app=haproxy

# Check service endpoint
kubectl get svc -n voxguard-prod haproxy-global

# Access stats page
open http://<haproxy-external-ip>:8404/stats
```

#### Traffic Distribution

| Region | Weight | Expected Traffic | Reasoning |
|--------|--------|------------------|-----------|
| Lagos  | 70%    | ~700 CPS         | Primary data center, lowest latency |
| Abuja  | 15%    | ~150 CPS         | Regional traffic from North-Central |
| Asaba  | 15%    | ~150 CPS         | Regional traffic from South-South |

#### Health Checks

- **Method:** SIP OPTIONS ping
- **Interval:** 10 seconds
- **Timeout:** 5 seconds
- **Rise threshold:** 2 successful checks
- **Fall threshold:** 5 failed checks

#### Session Affinity

- **Method:** Source IP hashing
- **Timeout:** 30 minutes
- **Purpose:** Keep SIP dialogs on same server

#### Circuit Breaker

- **Threshold:** 5 consecutive failures
- **Action:** Mark server down, redirect to backup
- **Recovery:** Automatic after server recovers

---

## Monitoring

### Metrics

**Key Metrics to Monitor:**

1. **Regional Availability**
   - Metric: `up{region="<region>"}`
   - Target: 100% (1.0)
   - Alert: < 99.99% over 5 minutes

2. **Replication Lag**
   - DragonflyDB: `dragonfly_replication_lag_ms`
   - YugabyteDB: `yb_replication_lag_ms`
   - Target: < 100ms
   - Alert: > 500ms

3. **Cross-Region Latency**
   - Metric: `inter_region_latency_ms{from="<region>",to="<region>"}`
   - Target: Lagos↔Abuja <20ms, Lagos↔Asaba <30ms
   - Alert: > 2x target

4. **Traffic Distribution**
   - Metric: `haproxy_server_current_sessions{backend="opensips_global",server="<server>"}`
   - Target: 70/15/15 ratio
   - Alert: Deviation > 20%

5. **Failover Events**
   - Metric: `haproxy_backend_down_total`
   - Target: 0 events
   - Alert: Any event

### Dashboards

**Grafana Dashboards:**

1. **Multi-Region Overview** (`multi-region-overview.json`)
   - Regional availability heatmap
   - Traffic distribution by region
   - Replication lag time series
   - Failover event timeline

2. **Database Replication** (`database-replication.json`)
   - DragonflyDB replication lag
   - YugabyteDB tablet distribution
   - Leader distribution by region
   - Read/write latency by region

3. **Load Balancer** (`load-balancer.json`)
   - Backend server status
   - Session count by region
   - Health check success rate
   - Circuit breaker state

### Alerts

**Critical Alerts:**

```yaml
# Region down
- alert: RegionDown
  expr: up{region=~"lagos|abuja|asaba"} == 0
  for: 1m
  severity: critical

# High replication lag
- alert: HighReplicationLag
  expr: dragonfly_replication_lag_ms > 500
  for: 5m
  severity: warning

# Cross-region connectivity lost
- alert: CrossRegionConnectivityLost
  expr: inter_region_latency_ms > 1000
  for: 2m
  severity: critical

# All backends down in region
- alert: AllBackendsDown
  expr: sum(haproxy_backend_up{backend="opensips_lagos"}) == 0
  for: 30s
  severity: critical
```

---

## Failover Procedures

### Scenario 1: Lagos Region Failure

**Symptoms:**
- All Lagos OpenSIPS instances unreachable
- HAProxy health checks failing
- Replication from Lagos stopped

**Automated Response:**
1. HAProxy marks all Lagos backends as DOWN
2. Traffic redirects to Abuja and Asaba (50/50 split)
3. Alerts fire: `RegionDown`, `AllBackendsDown`

**Manual Steps:**

```bash
# 1. Verify Lagos is indeed down
kubectl get nodes --context=lagos-cluster

# 2. Promote Abuja DragonflyDB to master
kubectl exec -n voxguard-prod dragonfly-replica-0 --context=abuja-cluster -- \
  redis-cli -a $DRAGONFLY_PASSWORD REPLICAOF NO ONE

# 3. Update application configuration
kubectl edit configmap voxguard-config -n voxguard-prod --context=abuja-cluster
# Change DRAGONFLY_PRIMARY_HOST to Abuja endpoint

# 4. Change YugabyteDB leader preference to Abuja
kubectl exec -n yb-platform yb-master-0 --context=abuja-cluster -- \
  yb-admin change_leader_election_preferred_zones on-premise.abuja.abuja-az1

# 5. Scale up Abuja and Asaba OpenSIPS instances
kubectl scale deployment opensips --replicas=3 -n voxguard-prod --context=abuja-cluster
kubectl scale deployment opensips --replicas=2 -n voxguard-prod --context=asaba-cluster

# 6. Monitor traffic distribution
watch -n 1 "curl -s http://<haproxy-ip>:8404/stats | grep opensips"

# 7. Notify stakeholders
# Send alert via email/Slack with status and ETA
```

**Recovery:**

```bash
# 1. Bring Lagos region back online
kubectl get nodes --context=lagos-cluster

# 2. Reconfigure DragonflyDB replication
kubectl exec -n voxguard-prod dragonfly-primary-0 --context=lagos-cluster -- \
  redis-cli -a $DRAGONFLY_PASSWORD REPLICAOF <abuja-ip> 6379

# 3. Sync data and promote Lagos back to primary
# Wait for replication to catch up
kubectl exec -n voxguard-prod dragonfly-primary-0 --context=lagos-cluster -- \
  redis-cli -a $DRAGONFLY_PASSWORD INFO replication | grep master_sync_in_progress

# Once synced, promote Lagos
kubectl exec -n voxguard-prod dragonfly-primary-0 --context=lagos-cluster -- \
  redis-cli -a $DRAGONFLY_PASSWORD REPLICAOF NO ONE

# 4. Restore YugabyteDB leader preference
kubectl exec -n yb-platform yb-master-0 --context=lagos-cluster -- \
  yb-admin change_leader_election_preferred_zones on-premise.lagos.lagos-az1

# 5. Update HAProxy to restore Lagos backends
# HAProxy will automatically detect healthy backends and resume traffic

# 6. Restore normal capacity in Abuja/Asaba
kubectl scale deployment opensips --replicas=1 -n voxguard-prod --context=abuja-cluster
kubectl scale deployment opensips --replicas=1 -n voxguard-prod --context=asaba-cluster
```

---

### Scenario 2: Database Replication Failure

**Symptoms:**
- High replication lag (>1000ms)
- `HighReplicationLag` alert firing
- Read replicas serving stale data

**Diagnosis:**

```bash
# Check DragonflyDB replication status
kubectl exec -n voxguard-prod dragonfly-replica-0 -- \
  redis-cli -a $DRAGONFLY_PASSWORD INFO replication

# Check YugabyteDB replication status
kubectl exec -n yb-platform yb-tserver-0 -- \
  ysqlsh -h localhost -c "SELECT * FROM yb_replication_status();"

# Check network connectivity
kubectl exec -n voxguard-prod dragonfly-replica-0 -- \
  ping -c 5 dragonfly-primary.voxguard-prod.svc.cluster.local
```

**Resolution:**

```bash
# For DragonflyDB: Force full resync
kubectl exec -n voxguard-prod dragonfly-replica-0 -- \
  redis-cli -a $DRAGONFLY_PASSWORD REPLICAOF NO ONE

kubectl exec -n voxguard-prod dragonfly-replica-0 -- \
  redis-cli -a $DRAGONFLY_PASSWORD REPLICAOF dragonfly-primary 6379

# For YugabyteDB: Trigger tablet rebalancing
kubectl exec -n yb-platform yb-master-0 -- \
  yb-admin set_load_balancer_enabled 1

# Monitor replication recovery
watch -n 1 "kubectl exec -n voxguard-prod dragonfly-replica-0 -- \
  redis-cli -a $DRAGONFLY_PASSWORD INFO replication | grep master_sync_in_progress"
```

---

## Performance Tuning

### Cross-Region Latency Optimization

**1. Enable TCP Fast Open**

```bash
# On all OpenSIPS nodes
sysctl -w net.ipv4.tcp_fastopen=3
echo "net.ipv4.tcp_fastopen=3" >> /etc/sysctl.conf
```

**2. Optimize TCP Window Size**

```bash
# Increase TCP buffer sizes for high-latency links
sysctl -w net.core.rmem_max=16777216
sysctl -w net.core.wmem_max=16777216
sysctl -w net.ipv4.tcp_rmem="4096 87380 16777216"
sysctl -w net.ipv4.tcp_wmem="4096 65536 16777216"
```

**3. Enable BBR Congestion Control**

```bash
# Enable BBR for better throughput on high-latency links
sysctl -w net.core.default_qdisc=fq
sysctl -w net.ipv4.tcp_congestion_control=bbr
```

### Database Performance

**DragonflyDB:**

```bash
# Increase thread count for high throughput
--proactor_threads=8

# Optimize memory eviction
--maxmemory-policy=allkeys-lru

# Enable pipeline mode for batched writes
# Application-side: Use redis-py pipeline()
```

**YugabyteDB:**

```sql
-- Optimize for write-heavy workload
ALTER TABLE fraud_alerts SET (
  tablet_split_size_threshold_mb = 512,
  tablet_split_low_phase_shard_count_per_node = 8
);

-- Create covering indexes to avoid random reads
CREATE INDEX idx_alerts_covering ON fraud_alerts (timestamp DESC)
  INCLUDE (severity, source_number, destination_number);

-- Enable query plan caching
SET pg_stat_statements.track = all;
```

### Load Balancer Tuning

**HAProxy:**

```cfg
# Increase connection limits
global
    maxconn 100000

# Reduce health check overhead
    default-server inter 20s  # Increase from 10s

# Enable kernel socket splicing for zero-copy forwarding
    tune.options tcp-splice

# Optimize stick-table size
backend opensips_global
    stick-table type ip size 200k expire 60m  # Increase size and TTL
```

---

## Troubleshooting

### High Cross-Region Latency

**Symptoms:**
- Replication lag > 100ms
- Slow writes from replicas
- Users experiencing high latency

**Diagnosis:**

```bash
# Measure network latency between regions
kubectl run -it --rm ping-test --image=busybox --restart=Never -- \
  ping -c 10 opensips-abuja-1.voxguard.internal

# Check for packet loss
kubectl run -it --rm mtr-test --image=mtr --restart=Never -- \
  mtr --report --report-cycles=100 opensips-lagos-1.voxguard.internal

# Monitor VPN tunnel status
# (Command depends on VPN solution - e.g., WireGuard, IPsec)
wg show  # For WireGuard
```

**Resolution:**

1. Check VPN tunnel health and restart if needed
2. Verify ISP/network provider SLA compliance
3. Consider increasing bandwidth between regions
4. Enable compression for replication traffic
5. Optimize database queries to reduce cross-region calls

---

### Split-Brain Scenario

**Symptoms:**
- Both Lagos and Abuja believe they are primary
- Data inconsistency between regions
- Replication stopped

**Prevention:**

Use YugabyteDB's built-in Raft consensus (prevents split-brain automatically).

For DragonflyDB, use Redis Sentinel:

```bash
# Deploy Sentinel on 3+ nodes
kubectl apply -f infrastructure/dragonfly/sentinel.yaml

# Sentinel will automatically elect a new master if current master is unreachable
```

**Recovery:**

```bash
# 1. Identify true primary (most recent data)
kubectl exec -n voxguard-prod dragonfly-primary-0 --context=lagos-cluster -- \
  redis-cli -a $DRAGONFLY_PASSWORD INFO persistence | grep rdb_last_save_time

kubectl exec -n voxguard-prod dragonfly-replica-0 --context=abuja-cluster -- \
  redis-cli -a $DRAGONFLY_PASSWORD INFO persistence | grep rdb_last_save_time

# 2. Designate node with latest data as primary
# 3. Force other node to replicate
kubectl exec -n voxguard-prod dragonfly-replica-0 --context=abuja-cluster -- \
  redis-cli -a $DRAGONFLY_PASSWORD REPLICAOF <lagos-ip> 6379

# 4. Wait for full sync
# 5. Update application configuration
```

---

## Disaster Recovery

### Backup Strategy

**Frequency:**
- **Full Backup:** Daily at 02:00 WAT
- **Incremental Backup:** Every 6 hours
- **Retention:** 30 days online, 7 years archived (NCC compliance)

**Backup Locations:**
- Primary: Object storage in Lagos region
- Replica: Object storage in Abuja region
- Archive: Cold storage (S3 Glacier or equivalent)

### Backup Procedures

**DragonflyDB Backup:**

```bash
# Automated backup script (run via CronJob)
#!/bin/bash
BACKUP_DIR=/backups/dragonfly/$(date +%Y%m%d-%H%M%S)
mkdir -p $BACKUP_DIR

# Trigger background save
kubectl exec -n voxguard-prod dragonfly-primary-0 -- \
  redis-cli -a $DRAGONFLY_PASSWORD BGSAVE

# Wait for save to complete
while true; do
  SAVE_STATUS=$(kubectl exec -n voxguard-prod dragonfly-primary-0 -- \
    redis-cli -a $DRAGONFLY_PASSWORD LASTSAVE)
  if [ "$SAVE_STATUS" != "$LAST_SAVE" ]; then
    break
  fi
  sleep 5
done

# Copy RDB file
kubectl cp voxguard-prod/dragonfly-primary-0:/data/dump.rdb $BACKUP_DIR/dump.rdb

# Compress and upload
tar -czf $BACKUP_DIR/dragonfly-backup.tar.gz $BACKUP_DIR/dump.rdb
aws s3 cp $BACKUP_DIR/dragonfly-backup.tar.gz s3://voxguard-backups/dragonfly/
```

**YugabyteDB Backup:**

```bash
# Create snapshot
kubectl exec -n yb-platform yb-master-0 -- \
  yb-admin create_snapshot ysql.voxguard

# List snapshots
SNAPSHOT_ID=$(kubectl exec -n yb-platform yb-master-0 -- \
  yb-admin list_snapshots | grep voxguard | awk '{print $4}')

# Export to object storage
kubectl exec -n yb-platform yb-master-0 -- \
  yb-admin export_snapshot $SNAPSHOT_ID s3://voxguard-backups/yugabyte/$(date +%Y%m%d)/
```

### Recovery Procedures

**Full System Recovery (All Regions Down):**

```bash
# 1. Restore infrastructure
cd infrastructure/terraform
terraform apply -auto-approve

# 2. Restore DragonflyDB
aws s3 cp s3://voxguard-backups/dragonfly/latest/dragonfly-backup.tar.gz .
tar -xzf dragonfly-backup.tar.gz
kubectl cp dump.rdb voxguard-prod/dragonfly-primary-0:/data/dump.rdb
kubectl delete pod dragonfly-primary-0 -n voxguard-prod  # Restart to load data

# 3. Restore YugabyteDB
SNAPSHOT_ID=<snapshot-id>
kubectl exec -n yb-platform yb-master-0 -- \
  yb-admin import_snapshot s3://voxguard-backups/yugabyte/<date>/ $SNAPSHOT_ID

kubectl exec -n yb-platform yb-master-0 -- \
  yb-admin restore_snapshot $SNAPSHOT_ID

# 4. Verify data integrity
kubectl exec -n yb-platform yb-tserver-0 -- \
  ysqlsh -h localhost -c "SELECT COUNT(*) FROM fraud_alerts;"

# 5. Resume normal operations
kubectl scale deployment --all --replicas=<original-count> -n voxguard-prod
```

---

## Appendix

### Cost Optimization

**Regional Scaling:**
- Scale down Abuja and Asaba during low-traffic hours
- Use spot instances for non-critical workloads
- Implement data retention policies to reduce storage costs

**Example Auto-Scaling Policy:**

```bash
# Scale based on time of day (Nigerian timezone)
kubectl apply -f - <<EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: opensips-hpa-abuja
  namespace: voxguard-prod
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: opensips-abuja
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 25
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 30
      policies:
      - type: Percent
        value: 50
        periodSeconds: 30
EOF
```

---

### Compliance Checklist

**NCC Requirements:**

- [ ] Data residency: All Nigerian call data stored in Nigerian data centers
- [ ] 7-year retention: Backups archived for 7 years (see Backup Strategy)
- [ ] Audit trail: All configuration changes logged
- [ ] Encryption: TLS 1.3 for all inter-region communication
- [ ] High availability: 99.99% uptime SLA met
- [ ] Disaster recovery: RPO <1 minute, RTO <15 minutes
- [ ] ATRS reporting: Automated daily reports from all regions

---

### Additional Resources

- [VoxGuard Architecture Overview](./ARCHITECTURE.md)
- [DragonflyDB Replication Guide](https://dragonflydb.io/docs/replication)
- [YugabyteDB Multi-Region Deployment](https://docs.yugabyte.com/preview/deploy/multi-dc/)
- [HAProxy Configuration Manual](https://www.haproxy.org/download/2.9/doc/configuration.txt)
- [Kubernetes Multi-Cluster Management](https://kubernetes.io/docs/concepts/cluster-administration/federation/)

---

**Document Version History:**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-03 | Claude (Factory AI) | Initial release |

---

**Support Contacts:**

- **Technical Issues:** ops@voxguard.ng
- **Emergency Hotline:** +234-XXX-XXX-XXXX
- **Slack Channel:** #voxguard-ops

---

**End of Document**
