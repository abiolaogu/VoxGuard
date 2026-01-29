# Operations Manual
## Anti-Call Masking Detection System

**Version:** 1.0
**Last Updated:** January 2026
**Audience:** Operations Team, NOC Staff, On-Call Engineers

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Daily Operations](#2-daily-operations)
3. [Monitoring Procedures](#3-monitoring-procedures)
4. [Incident Management](#4-incident-management)
5. [Change Management](#5-change-management)
6. [Capacity Management](#6-capacity-management)
7. [Communication Protocols](#7-communication-protocols)
8. [Escalation Procedures](#8-escalation-procedures)
9. [On-Call Procedures](#9-on-call-procedures)
10. [Business Continuity](#10-business-continuity)

---

## 1. Introduction

### 1.1 Purpose

This manual provides operational procedures for the day-to-day management of the Anti-Call Masking Detection System. It covers monitoring, incident response, maintenance, and escalation protocols.

### 1.2 Scope

This manual covers:
- 24/7 operational monitoring
- Incident detection and response
- System maintenance
- Capacity management
- NCC compliance operations

### 1.3 Operational Model

```
┌─────────────────────────────────────────────────────────────────┐
│                    Operations Structure                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌───────────┐    ┌───────────┐    ┌───────────┐               │
│  │    NOC    │───▶│    L2     │───▶│    L3     │               │
│  │  (24/7)   │    │ (On-Call) │    │ (Expert)  │               │
│  └───────────┘    └───────────┘    └───────────┘               │
│       │                │                │                       │
│       │                │                │                       │
│       ▼                ▼                ▼                       │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │                 Management Team                            │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 1.4 Service Level Objectives

| Metric | Target | Measurement |
|--------|--------|-------------|
| System Availability | 99.99% | Monthly |
| Detection Latency (P99) | < 5ms | Real-time |
| Alert Response Time (Critical) | < 5 min | Per incident |
| NCC Report Delivery | 06:00 WAT daily | Daily |
| Incident Resolution (P1) | < 4 hours | Per incident |

---

## 2. Daily Operations

### 2.1 Shift Schedule

| Shift | Hours (WAT) | Primary Tasks |
|-------|-------------|---------------|
| Morning | 06:00-14:00 | Report review, NCC verification |
| Afternoon | 14:00-22:00 | Peak monitoring, maintenance |
| Night | 22:00-06:00 | Monitoring, report generation |

### 2.2 Shift Handover Checklist

At each shift change:

```markdown
## Shift Handover Report

**Date:** _______________
**Outgoing:** _______________ **Incoming:** _______________

### System Status
- [ ] All services healthy
- [ ] No critical alerts pending
- [ ] NCC reports submitted

### Open Items
1. ________________________________
2. ________________________________
3. ________________________________

### Escalated Issues
1. ________________________________
2. ________________________________

### Notes
_________________________________________________
_________________________________________________

**Signatures:**
Outgoing: _______________ Incoming: _______________
```

### 2.3 Morning Checklist (06:00-07:00 WAT)

1. **System Health Review**
   ```bash
   # Check all services
   curl -s http://localhost:8080/health | jq
   docker-compose ps
   ```

2. **NCC Report Verification**
   ```bash
   # Verify daily report upload
   docker-compose logs --tail=50 ncc-sftp-uploader | grep upload
   ```

3. **Alert Review**
   - Review overnight alerts
   - Check for unacknowledged critical alerts
   - Verify false positive reports

4. **Metric Review**
   - Check Grafana dashboards
   - Verify detection latency within SLA
   - Review system uptime

5. **Capacity Check**
   ```bash
   # Check disk space
   df -h

   # Check database sizes
   docker-compose exec clickhouse clickhouse-client \
     --query="SELECT database, table, formatReadableSize(sum(bytes))
              FROM system.parts GROUP BY database, table"
   ```

### 2.4 Hourly Checks

Every hour:
- Verify alert processing (no backlog)
- Check metrics dashboard for anomalies
- Verify database connectivity
- Review system alerts in Grafana

### 2.5 Daily Maintenance Window

**Schedule:** 02:00-04:00 WAT (if needed)

Maintenance activities:
- Database optimization
- Log rotation
- Security patches
- Configuration updates

**Procedure:**
1. Notify stakeholders 24h in advance
2. Enable maintenance mode
3. Perform maintenance
4. Validate system
5. Disable maintenance mode
6. Notify completion

---

## 3. Monitoring Procedures

### 3.1 Primary Dashboards

| Dashboard | URL | Purpose |
|-----------|-----|---------|
| System Overview | grafana:3000/d/acm-overview | Main KPIs |
| Detection Performance | grafana:3000/d/detection | Latency, throughput |
| Alert Analytics | grafana:3000/d/alerts | Alert patterns |
| Database Health | grafana:3000/d/databases | DB performance |
| NCC Compliance | grafana:3000/d/ncc | Reporting status |

### 3.2 Key Metrics to Monitor

**Real-Time Metrics:**
```promql
# Calls per second
rate(acm_calls_processed_total[1m])

# Detection latency P99
histogram_quantile(0.99, rate(acm_detection_latency_bucket[5m]))

# Alert rate
rate(acm_alerts_total[1m]) * 60

# Error rate
rate(acm_errors_total[5m])
```

**System Health:**
```promql
# DragonflyDB memory
redis_memory_used_bytes / redis_memory_max_bytes * 100

# CPU usage
rate(process_cpu_seconds_total[5m]) * 100

# Memory usage
process_resident_memory_bytes / node_memory_MemTotal_bytes * 100
```

### 3.3 Alert Thresholds

| Alert | Warning | Critical | Action |
|-------|---------|----------|--------|
| Detection Latency | > 2ms | > 5ms | Investigate |
| Error Rate | > 0.1% | > 1% | Immediate |
| Memory Usage | > 75% | > 90% | Scale/Restart |
| Disk Usage | > 70% | > 85% | Cleanup |
| Alert Backlog | > 10 | > 50 | Escalate |
| NCC Upload Delay | > 30min | > 2h | Manual upload |

### 3.4 Prometheus Alerts

Active alerting rules:
```yaml
groups:
  - name: acm-critical
    rules:
      - alert: ACMHighLatency
        expr: histogram_quantile(0.99, rate(acm_detection_latency_bucket[5m])) > 0.005
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: Detection latency exceeds SLA

      - alert: ACMHighErrorRate
        expr: rate(acm_errors_total[5m]) / rate(acm_calls_processed_total[5m]) > 0.01
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: Error rate exceeds 1%

      - alert: NCCUploadFailed
        expr: time() - ncc_last_successful_upload_timestamp > 7200
        labels:
          severity: critical
        annotations:
          summary: NCC upload failed
```

### 3.5 Log Monitoring

**Log Locations:**
```bash
# Application logs
docker-compose logs acm-engine
docker-compose logs management-api

# System logs
journalctl -u docker

# NCC uploader
docker-compose logs ncc-sftp-uploader
```

**Log Search Examples:**
```bash
# Find errors in last hour
docker-compose logs --since 1h acm-engine 2>&1 | grep -i error

# Find detection events
docker-compose logs acm-engine 2>&1 | grep "fraud detected"

# Find NCC uploads
docker-compose logs ncc-sftp-uploader | grep "upload"
```

---

## 4. Incident Management

### 4.1 Incident Classification

| Priority | Description | Response | Resolution |
|----------|-------------|----------|------------|
| P1 - Critical | System down, no detection | 15 min | 4 hours |
| P2 - High | Degraded performance, NCC failure | 30 min | 8 hours |
| P3 - Medium | Minor issues, workaround exists | 2 hours | 24 hours |
| P4 - Low | Cosmetic, documentation | 24 hours | 1 week |

### 4.2 Incident Response Procedure

```
┌──────────────────────────────────────────────────────────────────┐
│                    Incident Response Flow                        │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────┐                                                │
│  │   Detect    │  Alert triggers or user reports                │
│  └──────┬──────┘                                                │
│         │                                                        │
│         ▼                                                        │
│  ┌─────────────┐                                                │
│  │  Classify   │  Determine priority (P1-P4)                    │
│  └──────┬──────┘                                                │
│         │                                                        │
│         ▼                                                        │
│  ┌─────────────┐                                                │
│  │ Communicate │  Notify stakeholders per matrix                │
│  └──────┬──────┘                                                │
│         │                                                        │
│         ▼                                                        │
│  ┌─────────────┐                                                │
│  │ Investigate │  Root cause analysis                           │
│  └──────┬──────┘                                                │
│         │                                                        │
│         ▼                                                        │
│  ┌─────────────┐                                                │
│  │   Resolve   │  Implement fix                                 │
│  └──────┬──────┘                                                │
│         │                                                        │
│         ▼                                                        │
│  ┌─────────────┐                                                │
│  │    Close    │  Document and close ticket                     │
│  └─────────────┘                                                │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### 4.3 Incident Template

```markdown
## Incident Report: INC-YYYY-NNNN

**Priority:** P1/P2/P3/P4
**Status:** Open/Investigating/Resolved/Closed
**Reported:** YYYY-MM-DD HH:MM WAT
**Reported By:** Name

### Summary
Brief description of the incident.

### Impact
- Services affected:
- Users affected:
- Duration:

### Timeline
| Time | Event |
|------|-------|
| HH:MM | Incident detected |
| HH:MM | Investigation started |
| HH:MM | Root cause identified |
| HH:MM | Fix implemented |
| HH:MM | Service restored |

### Root Cause
Description of what caused the incident.

### Resolution
Steps taken to resolve the incident.

### Action Items
1. [ ] Item 1
2. [ ] Item 2

### Lessons Learned
What can be improved to prevent recurrence.
```

### 4.4 Common Incident Runbooks

#### INC-001: Detection Service Unresponsive

**Symptoms:** No calls processed, health check failing

**Steps:**
1. Check service status
   ```bash
   docker-compose ps acm-engine
   ```
2. Check logs for errors
   ```bash
   docker-compose logs --tail=100 acm-engine
   ```
3. Restart service
   ```bash
   docker-compose restart acm-engine
   ```
4. Verify recovery
   ```bash
   curl http://localhost:8080/health
   ```

#### INC-002: NCC Upload Failed

**Symptoms:** Alert "NCC upload failed", no report in SFTP

**Steps:**
1. Check uploader status
   ```bash
   docker-compose logs --tail=100 ncc-sftp-uploader
   ```
2. Test SFTP connectivity
   ```bash
   docker-compose exec ncc-sftp-uploader sftp -v ${NCC_SFTP_HOST}
   ```
3. Manual upload if needed
   ```bash
   docker-compose exec ncc-sftp-uploader /scripts/manual-upload.sh
   ```
4. Notify NCC if deadline missed

#### INC-003: High Detection Latency

**Symptoms:** P99 latency > 5ms

**Steps:**
1. Check DragonflyDB
   ```bash
   redis-cli -p 6379 INFO memory
   redis-cli -p 6379 --latency
   ```
2. Check system resources
   ```bash
   docker stats
   ```
3. If memory high, restart cache
   ```bash
   docker-compose restart dragonfly
   ```
4. Scale if needed

---

## 5. Change Management

### 5.1 Change Classification

| Type | Description | Approval | Window |
|------|-------------|----------|--------|
| Standard | Pre-approved routine | None | Anytime |
| Normal | Non-routine | CAB | Scheduled |
| Emergency | Critical fix | Manager | Immediate |

### 5.2 Standard Changes

Pre-approved changes requiring no additional approval:
- Adding whitelist entries
- Adjusting detection threshold (within limits)
- Adding monitoring alerts
- Updating documentation

### 5.3 Change Request Process

1. **Submit Request** - Create change ticket
2. **Review** - Technical review
3. **Approve** - CAB approval (if Normal)
4. **Schedule** - Maintenance window
5. **Implement** - Execute change
6. **Validate** - Test and verify
7. **Close** - Document outcome

### 5.4 Pre-Change Checklist

```markdown
## Change Checklist

**Change ID:** CHG-YYYY-NNNN
**Date:** YYYY-MM-DD
**Implementer:** Name

### Pre-Implementation
- [ ] Change approved
- [ ] Rollback plan documented
- [ ] Backup completed
- [ ] Stakeholders notified
- [ ] Maintenance window scheduled

### Implementation
- [ ] Step 1 completed
- [ ] Step 2 completed
- [ ] Step N completed

### Validation
- [ ] Health checks pass
- [ ] Metrics normal
- [ ] No new errors
- [ ] User acceptance (if applicable)

### Completion
- [ ] Documentation updated
- [ ] Change ticket closed
- [ ] Stakeholders notified
```

### 5.5 Rollback Procedures

Every change must have a rollback plan:

```bash
# Example: Detection threshold rollback
# Previous value saved before change

# Rollback command
curl -X PATCH http://localhost:8080/api/v1/config \
  -H "Content-Type: application/json" \
  -d '{"detection_threshold": 5}'

# Verify
curl http://localhost:8080/api/v1/config | jq '.detection_threshold'
```

---

## 6. Capacity Management

### 6.1 Current Capacity

| Resource | Current | Threshold | Max |
|----------|---------|-----------|-----|
| CPS | 150K | 120K warning | 175K |
| Memory | 64 GB | 48 GB warning | 64 GB |
| Disk | 2 TB | 1.4 TB warning | 2 TB |
| Connections | 10K | 8K warning | 15K |

### 6.2 Capacity Monitoring

```promql
# CPS utilization
rate(acm_calls_processed_total[5m]) / 150000 * 100

# Memory utilization
sum(container_memory_usage_bytes) / sum(container_spec_memory_limit_bytes) * 100

# Disk utilization
(node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes * 100
```

### 6.3 Capacity Planning

**Monthly Review:**
1. Analyze traffic trends
2. Project growth (20% buffer)
3. Identify bottlenecks
4. Plan scaling actions

**Scaling Triggers:**
| Metric | Trigger | Action |
|--------|---------|--------|
| CPS > 80% | Consistent 1 week | Scale out |
| Memory > 75% | Consistent 3 days | Add memory |
| Disk > 70% | Consistent 1 week | Add storage |

### 6.4 Scaling Procedures

**Horizontal Scaling (Kubernetes):**
```bash
# Scale detection engine
kubectl scale deployment/acm-engine --replicas=4 -n fraud-detection

# Verify
kubectl get pods -n fraud-detection
```

**Vertical Scaling (Docker):**
```yaml
# Update docker-compose.yml
services:
  acm-engine:
    deploy:
      resources:
        limits:
          cpus: '8'
          memory: 8G
```

---

## 7. Communication Protocols

### 7.1 Communication Matrix

| Event | Notify | Method | Timeline |
|-------|--------|--------|----------|
| P1 Incident | All stakeholders | SMS + Call | Immediate |
| P2 Incident | Operations + Manager | Email + Slack | 15 min |
| Planned Maintenance | All users | Email | 24h advance |
| NCC Issue | Compliance + Manager | Email + Call | 1 hour |
| Capacity Alert | Operations | Slack | 2 hours |

### 7.2 Contact Lists

| Role | Primary | Secondary | Email |
|------|---------|-----------|-------|
| Operations Manager | +234-XXX-XXXX | +234-XXX-XXXX | ops@company.com |
| Technical Lead | +234-XXX-XXXX | +234-XXX-XXXX | tech@company.com |
| Security Officer | +234-XXX-XXXX | +234-XXX-XXXX | security@company.com |
| NCC Liaison | +234-XXX-XXXX | - | ncc@company.com |

### 7.3 Status Updates

**During Incidents:**
- Updates every 30 minutes for P1
- Updates every hour for P2
- Updates as needed for P3/P4

**Template:**
```
ACM Status Update - INC-YYYY-NNNN

Status: Investigating/Resolving/Monitoring
Time: YYYY-MM-DD HH:MM WAT

Current Impact:
- [Description of current impact]

Actions Taken:
- [Actions completed]

Next Steps:
- [Planned actions]

ETA: [Estimated resolution time]

Next Update: [Time of next update]
```

---

## 8. Escalation Procedures

### 8.1 Escalation Matrix

```
┌─────────────────────────────────────────────────────────────────┐
│                    Escalation Path                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Time        P1              P2              P3                 │
│  ─────       ──              ──              ──                 │
│  0 min       L1 NOC          L1 NOC          L1 NOC             │
│  15 min      L2 On-Call      -               -                  │
│  30 min      L3 Engineer     L2 On-Call      -                  │
│  1 hour      Ops Manager     L3 Engineer     L2 On-Call         │
│  2 hours     Tech Director   Ops Manager     L3 Engineer        │
│  4 hours     CTO             Tech Director   Ops Manager        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2 Escalation Triggers

**Automatic Escalation:**
- No acknowledgment within SLA
- Resolution exceeds timeline
- Multiple P1/P2 incidents simultaneously

**Manual Escalation:**
- Complex issue requiring expertise
- Cross-team coordination needed
- Business impact escalation

### 8.3 Escalation Procedure

1. **Determine Need** - Issue exceeds capability or timeline
2. **Document** - Current status, actions taken, why escalating
3. **Contact** - Next level per matrix
4. **Handover** - Brief and transfer ownership
5. **Support** - Remain available for questions

---

## 9. On-Call Procedures

### 9.1 On-Call Schedule

| Week | Primary | Secondary | Phone |
|------|---------|-----------|-------|
| W1 | Engineer A | Engineer B | Rotating |
| W2 | Engineer B | Engineer C | Rotating |
| W3 | Engineer C | Engineer A | Rotating |

### 9.2 On-Call Responsibilities

**Primary On-Call:**
- Respond to pages within 15 minutes
- Lead incident response
- Make operational decisions
- Update stakeholders

**Secondary On-Call:**
- Backup if primary unavailable
- Assist on complex incidents
- Escalate if primary unreachable

### 9.3 On-Call Handover

```markdown
## On-Call Handover

**Week:** W## (YYYY-MM-DD to YYYY-MM-DD)
**Outgoing:** Name
**Incoming:** Name

### Open Issues
1. Issue description - Status
2. Issue description - Status

### Scheduled Work
1. Work item - Date/Time
2. Work item - Date/Time

### Known Risks
1. Risk description
2. Risk description

### Handover Notes
Additional context or information.

**Confirmed:**
Outgoing: _______ Date: _______
Incoming: _______ Date: _______
```

### 9.4 On-Call Tools

| Tool | Purpose | Access |
|------|---------|--------|
| PagerDuty | Alerting | Mobile app |
| Slack | Communication | #acm-oncall channel |
| VPN | Secure access | Corporate VPN |
| SSH | Server access | Bastion host |
| Grafana | Monitoring | dashboard.internal |

---

## 10. Business Continuity

### 10.1 Recovery Objectives

| Objective | Target |
|-----------|--------|
| RTO (Recovery Time Objective) | 1 hour |
| RPO (Recovery Point Objective) | 15 minutes |

### 10.2 Disaster Recovery Sites

| Site | Location | Purpose | Capacity |
|------|----------|---------|----------|
| Primary | Lagos DC | Production | 100% |
| DR | Abuja DC | Hot standby | 100% |

### 10.3 Failover Procedure

**Automatic Failover:**
- Health checks fail 3x
- Automatic DNS failover
- Traffic redirects to DR

**Manual Failover:**
1. Confirm primary site issue
2. Notify stakeholders
3. Initiate failover
   ```bash
   kubectl config use-context dr-cluster
   kubectl apply -f k8s/dr-activation.yaml
   ```
4. Update DNS (if manual)
5. Verify services
6. Monitor closely

### 10.4 Failback Procedure

1. Confirm primary site recovered
2. Sync data from DR to primary
3. Verify data integrity
4. Test primary site
5. Schedule failback window
6. Execute failback
7. Verify services
8. Update DNS back to primary

### 10.5 DR Testing Schedule

| Test Type | Frequency | Last Test | Next Test |
|-----------|-----------|-----------|-----------|
| Backup Verification | Weekly | YYYY-MM-DD | YYYY-MM-DD |
| Failover Test | Quarterly | YYYY-MM-DD | YYYY-MM-DD |
| Full DR Exercise | Annual | YYYY-MM-DD | YYYY-MM-DD |

---

## Appendix A: Quick Reference

### Emergency Contacts
| Role | Contact |
|------|---------|
| Operations Manager | +234-XXX-XXX-XXXX |
| Technical Lead | +234-XXX-XXX-XXXX |
| Security Officer | +234-XXX-XXX-XXXX |
| NCC Emergency | +234-XXX-XXX-XXXX |

### Key URLs
| Service | URL |
|---------|-----|
| Dashboard | https://acm.company.com |
| Grafana | https://grafana.company.com |
| PagerDuty | https://company.pagerduty.com |
| Status Page | https://status.company.com |

### Quick Commands
```bash
# Health check
curl http://localhost:8080/health

# Service status
docker-compose ps

# Restart service
docker-compose restart acm-engine

# View logs
docker-compose logs -f --tail=100 acm-engine
```

---

**Document Version:** 1.0
**Classification:** Internal Operations
**Review Cycle:** Quarterly
