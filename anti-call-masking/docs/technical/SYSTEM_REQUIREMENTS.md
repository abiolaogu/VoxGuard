# System Requirements Specification
## Anti-Call Masking Detection Platform

**Version:** 2.0
**Last Updated:** January 2026
**Status:** Production
**Classification:** Technical

---

## Table of Contents

1. [Overview](#1-overview)
2. [Hardware Requirements](#2-hardware-requirements)
3. [Software Requirements](#3-software-requirements)
4. [Network Requirements](#4-network-requirements)
5. [Storage Requirements](#5-storage-requirements)
6. [Security Requirements](#6-security-requirements)
7. [High Availability Requirements](#7-high-availability-requirements)
8. [Scaling Requirements](#8-scaling-requirements)
9. [Integration Requirements](#9-integration-requirements)
10. [Environment Specifications](#10-environment-specifications)

---

## 1. Overview

### 1.1 Purpose

This document specifies the infrastructure, hardware, software, and operational requirements for deploying and operating the Anti-Call Masking Detection Platform in production environments.

### 1.2 Scope

Requirements cover:
- Production deployment
- Staging/UAT environments
- Development environments
- Disaster recovery sites

### 1.3 Performance Targets

| Metric | Requirement |
|--------|-------------|
| Detection Latency (P99) | < 1ms |
| Throughput | 150,000+ CPS |
| Availability | 99.99% |
| Recovery Time Objective | 1 hour |
| Recovery Point Objective | 15 minutes |

---

## 2. Hardware Requirements

### 2.1 Detection Engine Nodes

**Minimum per Node:**

| Component | Specification |
|-----------|---------------|
| CPU | 16 cores, 3.0GHz+ (AMD EPYC or Intel Xeon) |
| RAM | 64 GB DDR4-3200 ECC |
| Storage | 500 GB NVMe SSD (OS + Application) |
| Network | 25 Gbps NIC (dual-port for redundancy) |

**Recommended per Node:**

| Component | Specification |
|-----------|---------------|
| CPU | 32 cores, 3.5GHz+ (AMD EPYC 7003 series) |
| RAM | 128 GB DDR4-3200 ECC |
| Storage | 1 TB NVMe SSD (PCIe 4.0) |
| Network | 100 Gbps NIC (dual-port) |

**Node Count:**
- Minimum: 3 nodes (1 active, 2 standby)
- Recommended: 6 nodes (3 active, 3 standby)

### 2.2 DragonflyDB Cache Nodes

**Per Node:**

| Component | Specification |
|-----------|---------------|
| CPU | 8 cores, 3.0GHz+ |
| RAM | 128 GB DDR4-3200 ECC |
| Storage | 256 GB NVMe SSD |
| Network | 25 Gbps NIC |

**Node Count:**
- Minimum: 2 nodes (primary + replica)
- Recommended: 3 nodes (1 primary, 2 replicas)

### 2.3 QuestDB Time-Series Nodes

**Per Node:**

| Component | Specification |
|-----------|---------------|
| CPU | 16 cores, 3.0GHz+ |
| RAM | 64 GB DDR4-3200 ECC |
| Storage | 2 TB NVMe SSD + 10 TB HDD (tiered) |
| Network | 25 Gbps NIC |

**Node Count:**
- Minimum: 2 nodes (active-passive)
- Recommended: 3 nodes (with replication)

### 2.4 YugabyteDB Cluster Nodes

**Per Node:**

| Component | Specification |
|-----------|---------------|
| CPU | 16 cores, 3.0GHz+ |
| RAM | 64 GB DDR4-3200 ECC |
| Storage | 1 TB NVMe SSD (data) + 256 GB SSD (WAL) |
| Network | 25 Gbps NIC |

**Node Count:**
- Minimum: 3 nodes (replication factor 3)
- Recommended: 5 nodes (replication factor 3)

### 2.5 ClickHouse Analytics Nodes

**Per Node:**

| Component | Specification |
|-----------|---------------|
| CPU | 32 cores, 3.0GHz+ |
| RAM | 128 GB DDR4-3200 ECC |
| Storage | 500 GB NVMe SSD (hot) + 50 TB HDD (cold) |
| Network | 25 Gbps NIC |

**Node Count:**
- Minimum: 2 nodes (1 shard, 2 replicas)
- Recommended: 6 nodes (3 shards, 2 replicas each)

### 2.6 Management API Nodes

**Per Node:**

| Component | Specification |
|-----------|---------------|
| CPU | 8 cores, 3.0GHz+ |
| RAM | 32 GB DDR4 |
| Storage | 256 GB SSD |
| Network | 10 Gbps NIC |

**Node Count:**
- Minimum: 2 nodes (load balanced)
- Recommended: 3 nodes (load balanced)

### 2.7 Load Balancer

| Component | Specification |
|-----------|---------------|
| Type | HAProxy or F5 BIG-IP |
| Throughput | 40 Gbps+ |
| Connections | 500,000+ concurrent |
| Redundancy | Active-Active pair |

---

## 3. Software Requirements

### 3.1 Operating System

| Component | Supported Versions |
|-----------|-------------------|
| Primary | Ubuntu 22.04 LTS (recommended) |
| Alternative | RHEL 8.x / Rocky Linux 8.x |
| Kernel | 5.15+ with io_uring support |

**Required Kernel Parameters:**
```
# /etc/sysctl.conf
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
vm.swappiness = 1
vm.overcommit_memory = 1
```

### 3.2 Container Runtime

| Component | Version |
|-----------|---------|
| Docker | 24.0+ |
| containerd | 1.7+ |
| Kubernetes | 1.28+ (if using K8s) |

### 3.3 Database Software

| Component | Version | Purpose |
|-----------|---------|---------|
| DragonflyDB | 1.x | In-memory cache |
| QuestDB | 7.x | Time-series data |
| YugabyteDB | 2.18+ | Distributed SQL |
| ClickHouse | 23.x | Analytics |

### 3.4 Runtime Dependencies

| Component | Version |
|-----------|---------|
| Rust | 1.75+ (build only) |
| glibc | 2.31+ |
| OpenSSL | 3.0+ |
| liburing | 2.x |

### 3.5 Monitoring Stack

| Component | Version | Purpose |
|-----------|---------|---------|
| Prometheus | 2.45+ | Metrics collection |
| Grafana | 10.x | Visualization |
| Alertmanager | 0.26+ | Alert routing |
| Loki | 2.9+ | Log aggregation |

### 3.6 Security Software

| Component | Version | Purpose |
|-----------|---------|---------|
| Vault | 1.15+ | Secrets management |
| cert-manager | 1.13+ | TLS certificates |
| Falco | 0.36+ | Runtime security |

---

## 4. Network Requirements

### 4.1 Bandwidth

| Path | Minimum | Recommended |
|------|---------|-------------|
| SIP Switch → Detection Engine | 10 Gbps | 25 Gbps |
| Detection Engine → Cache | 25 Gbps | 100 Gbps |
| Cache → Time-Series DB | 10 Gbps | 25 Gbps |
| Internal Cluster | 25 Gbps | 100 Gbps |
| External API | 1 Gbps | 10 Gbps |

### 4.2 Latency

| Path | Maximum |
|------|---------|
| SIP Switch → Detection Engine | 2ms |
| Detection Engine → Cache | 0.5ms |
| Cache → Time-Series DB | 5ms |
| Internal Cluster | 1ms |

### 4.3 Network Topology

```
                    ┌─────────────────┐
                    │   Internet      │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │   Firewall      │
                    │   (Layer 7)     │
                    └────────┬────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
    ┌────▼────┐        ┌────▼────┐        ┌────▼────┐
    │  DMZ    │        │ Internal │        │  Mgmt   │
    │ VLAN 10 │        │ VLAN 20  │        │ VLAN 30 │
    └─────────┘        └──────────┘        └─────────┘
```

### 4.4 Required Ports

| Service | Port | Protocol | Direction |
|---------|------|----------|-----------|
| Detection API | 8080 | TCP | Inbound |
| Management API | 8081 | TCP | Inbound |
| Prometheus Metrics | 9090 | TCP | Internal |
| DragonflyDB | 6379 | TCP | Internal |
| QuestDB HTTP | 9000 | TCP | Internal |
| QuestDB ILP | 9009 | TCP | Internal |
| YugabyteDB SQL | 5433 | TCP | Internal |
| ClickHouse HTTP | 8123 | TCP | Internal |
| ClickHouse Native | 9000 | TCP | Internal |
| Grafana | 3000 | TCP | Internal |
| SFTP (NCC) | 22 | TCP | Outbound |
| NCC ATRS API | 443 | TCP | Outbound |

### 4.5 Firewall Rules

**Inbound (from SIP infrastructure):**
- Allow TCP 8080 from SIP switch IPs
- Allow TCP 8081 from management IPs
- Deny all other inbound

**Outbound (to NCC):**
- Allow TCP 443 to api.ncc.gov.ng
- Allow TCP 22 to sftp.ncc.gov.ng
- Allow TCP 443 to atrs.ncc.gov.ng

### 4.6 DNS Requirements

| Record | Type | Purpose |
|--------|------|---------|
| acm.internal | A | Internal cluster access |
| acm-api.internal | A | API endpoint |
| acm-metrics.internal | A | Monitoring |

---

## 5. Storage Requirements

### 5.1 Capacity Planning

| Data Type | Daily Volume | Retention | Total Capacity |
|-----------|--------------|-----------|----------------|
| Call Events | 50 GB | 90 days | 4.5 TB |
| Alerts | 1 GB | 365 days | 365 GB |
| Audit Logs | 5 GB | 5 years | 9 TB |
| Analytics | 10 GB | 365 days | 3.6 TB |
| Metrics | 2 GB | 30 days | 60 GB |
| **Total** | **68 GB** | - | **~18 TB** |

### 5.2 Storage Tiers

| Tier | Technology | Use Case | Performance |
|------|------------|----------|-------------|
| Hot | NVMe SSD | Active data (7 days) | 500K+ IOPS |
| Warm | SATA SSD | Recent data (90 days) | 50K IOPS |
| Cold | HDD/Object | Archive (1+ year) | 1K IOPS |

### 5.3 Backup Requirements

| Data Type | Frequency | Retention | Method |
|-----------|-----------|-----------|--------|
| Configuration | Hourly | 30 days | Snapshot |
| Call Events | Daily | 90 days | Incremental |
| Alerts | Daily | 365 days | Full |
| Audit Logs | Daily | 5 years | Full + Archive |

### 5.4 RAID Configuration

| Node Type | RAID Level | Purpose |
|-----------|------------|---------|
| Detection Engine | RAID 1 | OS + Application |
| Database | RAID 10 | Data volumes |
| Archive | RAID 6 | Cold storage |

---

## 6. Security Requirements

### 6.1 Encryption

| Data State | Standard | Implementation |
|------------|----------|----------------|
| In Transit | TLS 1.3 | All network communication |
| At Rest | AES-256 | All stored data |
| Secrets | AES-256-GCM | HashiCorp Vault |

### 6.2 Authentication

| Component | Method |
|-----------|--------|
| API Access | OAuth 2.0 / API Keys |
| Dashboard | OIDC + MFA |
| Service-to-Service | mTLS |
| Database | Certificate-based |

### 6.3 Authorization

| Model | Implementation |
|-------|----------------|
| API | RBAC with scoped tokens |
| Dashboard | Role-based access |
| Database | Row-level security |

### 6.4 Audit Requirements

| Event Type | Logged Fields |
|------------|---------------|
| Authentication | User, IP, Timestamp, Result |
| Configuration | User, Change, Before/After |
| Alert Actions | User, Alert ID, Action |
| Data Access | User, Query, Rows Returned |

### 6.5 Compliance

| Standard | Requirement |
|----------|-------------|
| NCC CLI Guidelines | Full compliance |
| NDPR | Data protection compliance |
| Data Residency | Nigeria only |

---

## 7. High Availability Requirements

### 7.1 Architecture

```
                     ┌─────────────────────────────────────┐
                     │         Load Balancer (HA)          │
                     │      Active-Active Cluster          │
                     └──────────────┬──────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
   ┌────▼────┐                 ┌────▼────┐                 ┌────▼────┐
   │ Engine  │                 │ Engine  │                 │ Engine  │
   │  Node 1 │                 │  Node 2 │                 │  Node 3 │
   └────┬────┘                 └────┬────┘                 └────┬────┘
        │                           │                           │
        └───────────────────────────┼───────────────────────────┘
                                    │
                     ┌──────────────▼──────────────┐
                     │     DragonflyDB Cluster     │
                     │   Primary + 2 Replicas      │
                     └─────────────────────────────┘
```

### 7.2 Redundancy Requirements

| Component | Minimum Redundancy | Failover Time |
|-----------|-------------------|---------------|
| Detection Engine | N+2 | < 1 second |
| DragonflyDB | 1 Primary + 2 Replicas | < 5 seconds |
| QuestDB | Active-Passive | < 30 seconds |
| YugabyteDB | RF=3 | Automatic |
| Load Balancer | Active-Active | < 1 second |

### 7.3 Failure Scenarios

| Scenario | Impact | Recovery |
|----------|--------|----------|
| Single node failure | None | Automatic |
| Rack failure | Degraded | Automatic |
| Datacenter failure | Failover | Manual (< 1 hour) |
| Region failure | DR activation | < 4 hours |

### 7.4 Health Checks

| Component | Check Type | Interval | Timeout |
|-----------|------------|----------|---------|
| Detection Engine | HTTP /health | 1s | 500ms |
| DragonflyDB | TCP + PING | 1s | 100ms |
| QuestDB | HTTP /status | 5s | 2s |
| YugabyteDB | SQL query | 5s | 2s |

---

## 8. Scaling Requirements

### 8.1 Horizontal Scaling

| Component | Scale Unit | Max Instances |
|-----------|------------|---------------|
| Detection Engine | 50K CPS | 10 |
| Management API | 5K req/s | 5 |
| DragonflyDB | Memory | 5 |
| ClickHouse | 1 shard | 10 shards |

### 8.2 Auto-Scaling Triggers

| Metric | Scale Up | Scale Down |
|--------|----------|------------|
| CPU | > 70% for 2 min | < 30% for 10 min |
| Memory | > 80% for 2 min | < 40% for 10 min |
| CPS | > 80% capacity | < 40% capacity |
| Latency P99 | > 0.8ms | < 0.3ms |

### 8.3 Capacity Planning

| Traffic Level | Detection Nodes | Cache Memory | Storage |
|---------------|-----------------|--------------|---------|
| 50K CPS | 3 | 256 GB | 10 TB |
| 100K CPS | 5 | 512 GB | 20 TB |
| 150K CPS | 7 | 768 GB | 30 TB |
| 200K CPS | 10 | 1 TB | 40 TB |

---

## 9. Integration Requirements

### 9.1 OpenSIPS Integration

| Requirement | Specification |
|-------------|---------------|
| Protocol | HTTP/2 REST API |
| Latency | < 2ms round-trip |
| Timeout | 5ms (with fallback) |
| Authentication | mTLS + API Key |

### 9.2 NCC ATRS Integration

| Requirement | Specification |
|-------------|---------------|
| Protocol | HTTPS REST API |
| Authentication | OAuth 2.0 |
| Report Upload | SFTP with SSH keys |
| Timezone | WAT (UTC+1) |

### 9.3 Monitoring Integration

| System | Protocol | Purpose |
|--------|----------|---------|
| Prometheus | HTTP /metrics | Metrics scraping |
| Grafana | Prometheus DS | Visualization |
| PagerDuty | Webhook | Alert routing |
| Slack | Webhook | Notifications |

---

## 10. Environment Specifications

### 10.1 Production Environment

| Aspect | Specification |
|--------|---------------|
| Location | Primary datacenter (Lagos) |
| Network | Dedicated VLAN |
| Access | VPN + Bastion only |
| Monitoring | 24/7 with alerting |

### 10.2 Disaster Recovery Environment

| Aspect | Specification |
|--------|---------------|
| Location | Secondary datacenter (Abuja) |
| Capacity | 100% of production |
| Replication | Async (< 15 min RPO) |
| Activation | Manual (< 1 hour RTO) |

### 10.3 Staging Environment

| Aspect | Specification |
|--------|---------------|
| Capacity | 25% of production |
| Data | Anonymized production subset |
| Access | Development team |
| Purpose | Pre-production testing |

### 10.4 Development Environment

| Aspect | Specification |
|--------|---------------|
| Deployment | Docker Compose |
| Data | Synthetic test data |
| Access | Developers |
| Purpose | Local development |

**Docker Compose Minimum:**
```yaml
# Minimum development requirements
services:
  detection-engine:
    resources:
      limits:
        cpus: '2'
        memory: 4G
  dragonfly:
    resources:
      limits:
        cpus: '1'
        memory: 2G
  questdb:
    resources:
      limits:
        cpus: '1'
        memory: 2G
```

---

## Appendix A: Hardware Bill of Materials

### Production Cluster (Recommended)

| Component | Quantity | Unit Cost (Est.) | Total |
|-----------|----------|------------------|-------|
| Detection Engine Server | 6 | $15,000 | $90,000 |
| DragonflyDB Server | 3 | $12,000 | $36,000 |
| QuestDB Server | 3 | $12,000 | $36,000 |
| YugabyteDB Server | 5 | $12,000 | $60,000 |
| ClickHouse Server | 6 | $15,000 | $90,000 |
| Management API Server | 3 | $8,000 | $24,000 |
| Load Balancer | 2 | $20,000 | $40,000 |
| Network Switches | 4 | $10,000 | $40,000 |
| **Total Hardware** | - | - | **$416,000** |

### DR Site (Additional)

| Component | Quantity | Unit Cost (Est.) | Total |
|-----------|----------|------------------|-------|
| Full replica of production | 1 | $416,000 | $416,000 |
| **Total DR** | - | - | **$416,000** |

---

## Appendix B: Software Licensing

| Software | License Type | Annual Cost (Est.) |
|----------|--------------|-------------------|
| DragonflyDB | Open Source | $0 |
| QuestDB | Open Source | $0 |
| YugabyteDB | Open Source | $0 |
| ClickHouse | Open Source | $0 |
| Grafana | Open Source | $0 |
| Prometheus | Open Source | $0 |
| HashiCorp Vault | Enterprise (optional) | $50,000 |
| **Total Software** | - | **$0 - $50,000** |

---

## Appendix C: Compliance Checklist

- [ ] All servers located in Nigeria (data residency)
- [ ] TLS 1.3 enabled on all endpoints
- [ ] AES-256 encryption at rest enabled
- [ ] Audit logging configured (5-year retention)
- [ ] NCC SFTP connectivity tested
- [ ] NCC ATRS API credentials configured
- [ ] Backup procedures documented and tested
- [ ] DR failover procedures documented and tested
- [ ] Security audit completed
- [ ] Penetration test completed

---

**Document Classification:** Internal Technical
**Review Cycle:** Quarterly
**Next Review:** April 2026
