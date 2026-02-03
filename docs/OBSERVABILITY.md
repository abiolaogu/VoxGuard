# VoxGuard Observability & Monitoring System

## Overview

VoxGuard's observability system provides comprehensive monitoring, distributed tracing, and SLA tracking to ensure system reliability and performance. This document covers all monitoring components, dashboards, alerts, and operational procedures.

---

## Architecture

### Components

1. **Prometheus** - Metrics collection and alerting
2. **Grafana** - Visualization and dashboards
3. **Tempo** - Distributed tracing
4. **Alert Manager** - Alert routing and notification

### Metrics Flow

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   OpenSIPS      │────▶│   Prometheus    │────▶│    Grafana      │
│  (Voice Switch) │     │   (Metrics DB)  │     │  (Dashboards)   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
┌─────────────────┐              │                        │
│ Detection Engine│──────────────┘                        │
│      (ACM)      │                                       │
└─────────────────┘                                       │
┌─────────────────┐     ┌─────────────────┐             │
│  Management API │────▶│  AlertManager   │─────────────┘
└─────────────────┘     └─────────────────┘
```

### Tracing Flow

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   OpenSIPS      │────▶│      Tempo      │────▶│    Grafana      │
│  (OTLP/Jaeger)  │     │  (Trace Store)  │     │  (Trace View)   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
┌─────────────────┐              │
│ Detection Engine│──────────────┘
│   (Rust spans)  │
└─────────────────┘
```

---

## Grafana Dashboards

VoxGuard includes three pre-configured dashboards covering all system components.

### 1. Voice Switch Dashboard

**UID:** `voxguard-voice-switch`
**Refresh:** 10 seconds
**Purpose:** Monitor OpenSIPS, HAProxy, and circuit breaker health

#### Panels

**Status Overview (Row 1):**
- Circuit Breaker Status (CLOSED/OPEN/HALF_OPEN)
- Current CPS (Calls Per Second)
- OpenSIPS Availability (%)
- Active SIP Dialogs
- Call Failure Rate (%)

**Performance (Row 2):**
- Call Processing Rate (CPS over time)
  - Total CPS
  - Successful CPS
  - Rejected CPS (ACM blocked)
  - Failed CPS
- SIP Processing Latency (P50/P95/P99/P99.9)

**Circuit Breaker (Row 3):**
- Circuit Breaker Metrics
  - Total Requests
  - Successful Requests
  - Failed Requests
  - Rejected Requests (Circuit Open)
- SIP Response Codes (5min distribution)

**Load Balancer (Row 4):**
- HAProxy Load Balancer Sessions
  - Current Sessions per backend
  - Max Sessions per backend
- HAProxy Backend Server Status (Table)
  - UP/DOWN status per server

#### Key Metrics

- **Circuit Breaker State:** 0=CLOSED, 1=OPEN, 2=HALF_OPEN
- **CPS:** Rate of call processing (target: 500-1000 sustained)
- **Availability:** Target 99.99%+ (1 hour downtime = 0.9999)
- **SIP Latency:** Target P99 < 100ms

#### Alerts Shown

- Circuit breaker OPEN (critical)
- High call failure rate (>5%)
- OpenSIPS instance down
- HAProxy backend down

---

### 2. Detection Engine Dashboard

**UID:** `voxguard-detection-engine`
**Refresh:** 10 seconds
**Purpose:** Monitor fraud detection performance and alert generation

#### Panels

**Status Overview (Row 1):**
- Critical Alerts (Total)
- High Alerts (Total)
- Detection Latency P95 (Target: <1ms)
- Cache Hit Rate (%)

**Alert Generation (Row 2):**
- Alert Rate by Severity (Time series)
  - Critical Alerts/sec
  - High Alerts/sec
  - Medium Alerts/sec
  - Low Alerts/sec
- Detection Latency Percentiles (P50/P95/P99/P99.9)

**Throughput (Row 3):**
- Call Processing Throughput
  - Calls Processed/sec
  - Masked Calls/sec (flagged as fraud)
- Alert Distribution by Severity (Pie chart)

**Infrastructure (Row 4):**
- Database Connection Pool
  - Active Connections
  - Idle Connections
  - Max Connections
- Call Masking Rate (Target: <5%)

#### Key Metrics

- **Detection Latency:** Sub-millisecond fraud detection (target: <1ms P95)
- **Alert Rate:** Monitoring for alert storms (>10 critical/sec triggers alert)
- **Cache Hit Rate:** Target 80%+ for performance
- **Call Masking Rate:** Percentage of calls flagged as fraud (target: <5%)

#### Alerts Shown

- Detection engine down (critical)
- High detection latency (P95 > 500ms)
- High call masking rate (>5%)
- Low cache hit rate (<80%)

---

### 3. SLA Monitoring Dashboard

**UID:** `voxguard-sla-monitoring`
**Refresh:** 1 minute
**Purpose:** Track 99.99% uptime SLA and error budgets

#### Panels

**SLA Gauges (Row 1):**
- System Availability (24h) - Target: 99.99%
- System Availability (7d) - Target: 99.99%
- System Availability (30d) - Target: 99.99%
- Monthly Downtime (Max: 52.56 minutes for 99.99%)

**Availability Trends (Row 2):**
- Component Availability (1h rolling average)
  - Voice Switch (OpenSIPS)
  - Detection Engine
  - Management API
  - YugabyteDB
  - DragonflyDB

**Performance SLAs (Row 3):**
- Latency SLA
  - Detection P95 (Target: <1ms)
  - Detection P99 (Target: <1ms)
  - SIP P95 (Target: <100ms)
  - SIP P99 (Target: <100ms)
- Error Rate SLA (Target: <1%)
  - SIP Error Rate
  - Detection Error Rate
  - API Error Rate (5xx)

**Compliance Report (Row 4):**
- SLA Compliance Report by Component (Table)
  - Component name
  - 24h Availability
  - 7d Availability
  - 30d Availability
  - Color-coded cells (red <99.99%, green ≥99.99%)

#### SLA Targets

| Metric | Target | Monthly Budget |
|--------|--------|----------------|
| Uptime | 99.99% | 52.56 min downtime |
| Daily Uptime | 99.99% | 1.44 min downtime |
| Detection Latency (P95) | <1ms | - |
| SIP Latency (P95) | <100ms | - |
| Error Rate | <1% | - |

#### Alerts Shown

- SLA availability violation (<99.99%)
- SLA latency violation (P95 > target)
- SLA error rate violation (>1%)
- Monthly downtime budget exceeded
- Daily downtime budget warning

---

## Distributed Tracing (Tempo)

### Configuration

**Location:** `monitoring/tempo/tempo.yaml`

**Receivers:**
- Jaeger (thrift_http, gRPC, thrift_binary, thrift_compact)
- OpenTelemetry (HTTP, gRPC)

**Ports:**
- HTTP API: 3200
- gRPC: 9096
- Jaeger thrift_http: 14268
- Jaeger gRPC: 14250
- OTLP HTTP: 4318
- OTLP gRPC: 4317

### Retention

- **Block Retention:** 7 days (168 hours)
- **Compaction Window:** 1 hour
- **Trace Idle Period:** 30 seconds

### Instrumentation

**OpenSIPS (Voice Switch):**
```c
// Trace context propagation via SIP headers
$var(trace_id) = $(hdr(X-Trace-Id));
$var(span_id) = $(hdr(X-Span-Id));
```

**Detection Engine (Rust):**
```rust
use opentelemetry::trace::Tracer;

#[tracing::instrument]
async fn detect_fraud(call: &Call) -> Result<Alert, Error> {
    let span = tracing::span!(Level::INFO, "detect_fraud", call.id = %call.id);
    // Detection logic
}
```

**Management API (Go):**
```go
import "go.opentelemetry.io/otel"

ctx, span := otel.Tracer("management-api").Start(ctx, "ProcessAlert")
defer span.End()
```

### Service Graph

Tempo generates service dependency graphs automatically using span metadata. View in Grafana → Explore → Tempo → Service Graph.

**Expected Services:**
- `opensips` → `acm-detection-engine` → `yugabytedb`
- `opensips` → `dragonfly` (circuit breaker state)
- `management-api` → `yugabytedb`
- `management-api` → `clickhouse`

---

## Prometheus Alerts

### Alert Groups

VoxGuard has **6 alert groups** with **42 rules total**:

1. **voxguard-critical** (3 rules)
2. **voxguard-warning** (4 rules)
3. **voxguard-ncc-compliance** (2 rules)
4. **voxguard-infrastructure** (3 rules)
5. **voxguard-circuit-breaker** (4 rules) ⭐ NEW
6. **voxguard-sla** (5 rules) ⭐ NEW
7. **voxguard-voice-switch** (6 rules) ⭐ NEW

### Critical Alerts

| Alert | Trigger | Duration | Impact |
|-------|---------|----------|--------|
| CircuitBreakerOpen | State = OPEN | 1 minute | Fraud detection bypassed |
| OpenSIPSDown | `up{job="opensips"} == 0` | 30 seconds | No call processing |
| DetectionEngineDown | `up{job="acm-detection-engine"} == 0` | 1 minute | No fraud detection |
| HAProxyNoHealthyServers | All servers DOWN | 1 minute | No load balancing |
| SLAAvailabilityViolation | Availability < 99.99% | 5 minutes | SLA breach |

### Warning Alerts

| Alert | Trigger | Duration | Impact |
|-------|---------|----------|--------|
| CircuitBreakerHalfOpen | State = HALF_OPEN | 5 minutes | Partial service degradation |
| SLALatencyViolation | P95 > 1ms | 10 minutes | Performance SLA breach |
| DailyDowntimeBudgetWarning | 24h downtime > 1.44 min | 30 minutes | SLA budget warning |
| HighSIPLatency | P95 > 100ms | 5 minutes | Slow call processing |

### Alert Configuration

**Location:** `monitoring/prometheus/alerts/voxguard-alerts.yml`

**Notification Channels:**
- PagerDuty (critical alerts)
- Slack #voxguard-alerts (all alerts)
- Email oncall@voxguard.ng (critical alerts)

---

## Metrics Reference

### Voice Switch Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `opensips_calls_processed_total` | Counter | Total calls processed |
| `opensips_calls_successful_total` | Counter | Successful calls |
| `opensips_calls_rejected_total` | Counter | Calls rejected by ACM |
| `opensips_failed_calls_total` | Counter | Failed calls (4xx/5xx) |
| `opensips_active_dialogs` | Gauge | Current active SIP dialogs |
| `opensips_sip_latency_seconds` | Histogram | SIP processing latency |
| `opensips_circuit_breaker_state` | Gauge | Circuit breaker state (0/1/2) |
| `opensips_circuit_breaker_total_requests` | Counter | Total circuit breaker requests |
| `opensips_circuit_breaker_success_requests` | Counter | Successful requests |
| `opensips_circuit_breaker_failure_requests` | Counter | Failed requests |
| `opensips_circuit_breaker_rejected_requests` | Counter | Rejected requests (circuit open) |

### Detection Engine Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `acm_calls_processed_total` | Counter | Total calls analyzed |
| `acm_masked_calls_total` | Counter | Calls flagged as fraud |
| `acm_alerts_total{severity}` | Counter | Alerts by severity |
| `acm_detection_latency_seconds` | Histogram | Detection latency |
| `acm_cache_hits_total` | Counter | Cache hits |
| `acm_cache_misses_total` | Counter | Cache misses |
| `acm_db_connection_pool_active` | Gauge | Active DB connections |
| `acm_db_connection_pool_idle` | Gauge | Idle DB connections |
| `acm_db_connection_errors_total` | Counter | DB connection errors |

### HAProxy Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `haproxy_backend_up` | Gauge | Backend up/down (1/0) |
| `haproxy_server_up` | Gauge | Server up/down (1/0) |
| `haproxy_backend_current_sessions` | Gauge | Current sessions |
| `haproxy_backend_max_sessions` | Gauge | Max sessions |

### System Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `up{job}` | Gauge | Service up/down (1/0) |
| `process_resident_memory_bytes` | Gauge | Process memory usage |
| `dragonfly_used_memory_bytes` | Gauge | DragonflyDB memory |
| `yugabyte_replication_lag_seconds` | Gauge | YugabyteDB replication lag |

---

## Operations Guide

### Accessing Dashboards

**Grafana URL:** http://localhost:3000

**Default Credentials:**
- Username: `admin`
- Password: `voxguard_admin_2026`

**Dashboard URLs:**
- Voice Switch: http://localhost:3000/d/voxguard-voice-switch
- Detection Engine: http://localhost:3000/d/voxguard-detection-engine
- SLA Monitoring: http://localhost:3000/d/voxguard-sla-monitoring

### Accessing Traces

1. Open Grafana → Explore
2. Select "Tempo" datasource
3. Query options:
   - Search by Trace ID
   - Search by Service Name
   - Search by Tags (span.status_code, http.status_code)
4. View service graph: Click "Service Graph" tab

### Alert Investigation

#### Circuit Breaker Open

**Alert:** `CircuitBreakerOpen`

**Investigation Steps:**
1. Check Voice Switch dashboard → Circuit Breaker Metrics panel
2. Identify failure spike in "Circuit Breaker Metrics" graph
3. Check Detection Engine dashboard → verify ACM engine is UP
4. Review Tempo traces for failed ACM requests:
   ```
   service.name="opensips" AND span.status_code="error"
   ```
5. Check logs:
   ```bash
   docker logs opensips-1 | grep "circuit_breaker"
   ```

**Resolution:**
- If ACM is down: Restart ACM engine
- If ACM is slow: Check database connection pool
- If false positive: Adjust circuit breaker thresholds in `opensips-production.cfg`

**Manual Circuit Reset:**
```bash
# Close circuit breaker manually (DragonflyDB)
docker exec -it dragonflydb redis-cli
> SET circuit_breaker:acm_engine:state 0
> SET circuit_breaker:acm_engine:failure_count 0
```

#### SLA Availability Violation

**Alert:** `SLAAvailabilityViolation`

**Investigation Steps:**
1. Open SLA Monitoring dashboard
2. Check "Component Availability" graph for failing service
3. Identify downtime window
4. Check Prometheus alerts for coinciding alerts (e.g., OpenSIPSDown)
5. Review incident timeline:
   ```promql
   changes(up{job=~"opensips|acm-detection-engine|management-api"}[1h])
   ```

**Resolution:**
- Identify root cause (service crash, OOM, network partition)
- Restore service availability
- Document incident in `docs/incidents/YYYY-MM-DD-incident.md`
- Update runbook if new failure mode

**Downtime Budget Calculation:**
```
Monthly Budget: 30 days * 99.99% = 52.56 minutes
Remaining Budget = 52.56 - (downtime so far this month)
```

Query current month downtime:
```promql
(1 - avg_over_time(up{job=~"opensips|acm-detection-engine|management-api"}[30d])) * 30 * 24 * 60
```

#### High Detection Latency

**Alert:** `SLALatencyViolation`

**Investigation Steps:**
1. Check Detection Engine dashboard → "Detection Latency Percentiles"
2. Identify latency spike timing
3. Check "Database Connection Pool" panel for connection exhaustion
4. Review cache hit rate (low cache hit = high DB load)
5. Check Tempo traces for slow DB queries:
   ```
   service.name="acm-detection-engine" AND duration > 500ms
   ```

**Resolution:**
- Increase DB connection pool size if exhausted
- Warm up cache if cache hit rate dropped
- Analyze slow queries in YugabyteDB:
  ```sql
  SELECT * FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 10;
  ```
- Add database indexes if needed
- Scale ACM engine horizontally (add replicas)

### Performance Tuning

#### Dashboard Performance

If dashboards are slow:
1. Reduce time range (default: 1h → 15m)
2. Increase refresh interval (10s → 30s)
3. Disable auto-refresh when not actively monitoring
4. Use "Explore" view for ad-hoc queries

#### Prometheus Performance

If Prometheus is slow or OOM:
1. Reduce retention (default: 15d)
   ```yaml
   storage:
     tsdb:
       retention.time: 7d
   ```
2. Reduce scrape frequency for low-priority targets
3. Enable remote write to long-term storage (Thanos/Cortex)

#### Tempo Performance

If Tempo is slow:
1. Reduce trace retention (default: 7d → 3d)
2. Increase compaction frequency
3. Use S3/GCS backend instead of local storage
4. Enable sampling (trace 10% of traffic instead of 100%)

---

## Troubleshooting

### Dashboard Not Loading

**Symptom:** Grafana shows "N/A" or "No data" in panels

**Checks:**
1. Verify Prometheus is running:
   ```bash
   docker ps | grep prometheus
   curl http://localhost:9090/api/v1/status/config
   ```
2. Verify Prometheus is scraping targets:
   ```
   curl http://localhost:9090/api/v1/targets
   ```
3. Check Grafana datasource connection:
   - Settings → Datasources → Prometheus → "Test"
4. Verify metrics exist:
   ```bash
   curl http://localhost:9090/api/v1/label/__name__/values | grep opensips
   ```

**Resolution:**
- Restart Prometheus if not running
- Check `prometheus.yml` scrape configs
- Verify service discovery (file_sd, docker_sd, kubernetes_sd)

### Missing Traces

**Symptom:** Tempo shows no traces for a service

**Checks:**
1. Verify Tempo is running:
   ```bash
   docker ps | grep tempo
   curl http://localhost:3200/ready
   ```
2. Check if service is instrumented:
   ```bash
   # OpenSIPS - check for OTLP exporter config
   grep "otlp" /etc/opensips/opensips-production.cfg

   # Rust - check for tracing subscriber
   grep "opentelemetry" services/detection-engine/Cargo.toml
   ```
3. Verify receiver is enabled in `tempo.yaml`:
   ```yaml
   distributor:
     receivers:
       otlp:
         protocols:
           grpc:
             endpoint: 0.0.0.0:4317
   ```
4. Test OTLP endpoint:
   ```bash
   curl -X POST http://localhost:4318/v1/traces -H "Content-Type: application/json" -d '{}'
   ```

**Resolution:**
- Add OpenTelemetry instrumentation to service
- Configure OTLP exporter endpoint (http://tempo:4318)
- Restart service after instrumentation

### Alert Not Firing

**Symptom:** Expected alert does not fire despite metric exceeding threshold

**Checks:**
1. Verify alert rule is loaded:
   ```bash
   curl http://localhost:9090/api/v1/rules | jq '.data.groups[].rules[] | select(.name=="CircuitBreakerOpen")'
   ```
2. Check alert state (Inactive/Pending/Firing):
   ```
   http://localhost:9090/alerts
   ```
3. Evaluate alert expression manually:
   ```promql
   opensips_circuit_breaker_state{service="acm_engine"} == 1
   ```
4. Check `for` duration not yet elapsed
5. Verify AlertManager is receiving alerts:
   ```bash
   curl http://localhost:9093/api/v2/alerts
   ```

**Resolution:**
- Fix alert expression syntax errors
- Reload Prometheus: `curl -X POST http://localhost:9090/-/reload`
- Check AlertManager routing config
- Verify notification channel (Slack, PagerDuty) is configured

---

## Best Practices

### Dashboard Usage

1. **Start with SLA Dashboard** for overall system health
2. **Drill down** to component dashboards when issues detected
3. **Use time range selector** to analyze historical incidents
4. **Create custom dashboards** for specific troubleshooting
5. **Export dashboards** as JSON for version control

### Alert Fatigue Prevention

1. **Tune thresholds** based on actual system behavior (not guesses)
2. **Use `for` duration** to avoid flapping alerts (transient spikes)
3. **Group related alerts** to avoid duplicate notifications
4. **Implement alert inhibition** (e.g., if OpenSIPS is down, suppress HAProxy alerts)
5. **Review and remove** obsolete alerts quarterly

### Metric Naming

Follow Prometheus naming conventions:
- **Counters:** `_total` suffix (e.g., `opensips_calls_processed_total`)
- **Gauges:** No suffix (e.g., `opensips_active_dialogs`)
- **Histograms:** `_seconds` or `_bytes` with `_bucket`, `_sum`, `_count`
- **Summary:** `_seconds` or `_bytes` with quantiles

### Trace Sampling

For high-traffic systems (>1000 CPS):
1. Enable head-based sampling (trace 10% of requests)
2. Always trace errors (100% sampling for failures)
3. Use tail-based sampling (Tempo TraceQL) for complex queries

---

## Maintenance

### Daily Tasks

- Review SLA dashboard for compliance
- Acknowledge and investigate critical alerts
- Check Prometheus storage usage (<80% full)

### Weekly Tasks

- Review alert firing frequency (tune noisy alerts)
- Check dashboard performance (optimize slow queries)
- Rotate logs and traces (if not automated)

### Monthly Tasks

- Export SLA report for stakeholders
- Review and update alert thresholds
- Audit datasource credentials (rotate passwords)
- Update dashboard screenshots in documentation

### Quarterly Tasks

- Performance review: identify bottlenecks
- Cost review: reduce retention if needed
- Feature review: evaluate new Grafana plugins
- Documentation review: update runbooks

---

## References

- [Prometheus Best Practices](https://prometheus.io/docs/practices/naming/)
- [Grafana Dashboard Design](https://grafana.com/docs/grafana/latest/dashboards/)
- [OpenTelemetry Specification](https://opentelemetry.io/docs/specs/otel/)
- [SLA Calculation Guide](https://uptime.is/99.99)
- [VoxGuard PRD](./PRD.md) - Section 5.1 P1-1 Observability requirements

---

## Support

For observability issues:
- **Slack:** #voxguard-sre
- **Email:** sre@voxguard.ng
- **On-call:** PagerDuty rotation (https://voxguard.pagerduty.com)

**Emergency Contact:** +234-XXX-XXX-XXXX (24/7 NOC)
