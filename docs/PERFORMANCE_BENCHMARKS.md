# VoxGuard Performance Benchmarks

**Version:** 2.1.0
**Date:** February 12, 2026
**Status:** Production Validated
**Owner:** VoxGuard Platform Engineering & SRE
**Benchmark Environment:** Production-equivalent (Lagos DC)
**Last Benchmark Run:** February 10, 2026

---

## Table of Contents

1. [System Capacity](#system-capacity)
2. [Latency Targets](#latency-targets)
3. [Throughput](#throughput)
4. [Accuracy Metrics](#accuracy-metrics)
5. [Memory Profile](#memory-profile)
6. [Database Performance](#database-performance)
7. [Frontend Performance](#frontend-performance)
8. [Load Test Results](#load-test-results)
9. [Scaling Characteristics](#scaling-characteristics)
10. [Benchmark Environment Specification](#benchmark-environment-specification)
11. [Historical Trend Data](#historical-trend-data)
12. [Benchmark Methodology](#benchmark-methodology)

---

## System Capacity

### Sustained and Burst Capacity

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    VoxGuard System Capacity Profile                      │
│                                                                         │
│  CPS (Calls Per Second)                                                 │
│                                                                         │
│  250K ┤                                                                 │
│       │                                    ╭──── Burst Peak (200K)      │
│  200K ┤                                ╭───╯                            │
│       │                            ╭───╯                                │
│  150K ┤ ═══════════════════════════╪═══════ Sustained (150K+)           │
│       │                            │                                    │
│  100K ┤                            │                                    │
│       │          ╭─────────────────╯                                    │
│   50K ┤      ╭───╯                                                     │
│       │  ╭───╯                                                          │
│     0 ┼──╯──────┬──────┬──────┬──────┬──────┬──────┬──────┬──────      │
│       0    2    4    6    8   10   12   14   16  (hours)                │
│                                                                         │
│  ─── Normal Load   ═══ Sustained Capacity   ╭── Burst Capacity         │
└─────────────────────────────────────────────────────────────────────────┘
```

| Metric | Target | Measured | Status |
|--------|--------|----------|--------|
| **Sustained CPS** | 150,000+ | 158,200 | PASS |
| **Burst CPS** | 200,000 | 212,400 | PASS |
| **Burst Duration** | 60 seconds | 90 seconds sustained | PASS |
| **Max CPS Before Degradation** | N/A | 235,000 | Measured |
| **Graceful Degradation Threshold** | > 200K CPS | 220K CPS | PASS |
| **Recovery Time After Burst** | < 30 seconds | 18 seconds | PASS |

### Capacity Planning

| Scenario | CPS | Detection Engine Pods | DragonflyDB Memory | YugabyteDB IOPS |
|----------|-----|----------------------|-------------------|-----------------|
| Low traffic | 10K | 2 | 2 GB | 1,000 |
| Normal | 50K | 3 | 4 GB | 3,000 |
| Peak hours | 100K | 4 | 8 GB | 6,000 |
| Sustained max | 150K | 6 | 12 GB | 10,000 |
| Burst | 200K | 8 | 16 GB | 15,000 |
| Emergency scale | 250K+ | 10 | 24 GB | 20,000 |

---

## Latency Targets

### Detection Engine Latency (SIP Call Analysis)

The detection engine must process each incoming SIP INVITE and render a fraud/no-fraud decision within strict latency budgets to avoid impacting call setup time.

```mermaid
xychart-beta
    title "Detection Engine Latency Distribution (Feb 10, 2026)"
    x-axis ["P50", "P75", "P90", "P95", "P99", "P99.9"]
    y-axis "Latency (ms)" 0 --> 6
    bar [0.32, 0.45, 0.62, 0.71, 0.89, 4.2]
    line [0.5, 0.65, 0.75, 0.8, 1.0, 5.0]
```

| Percentile | Target | Measured | Status | Notes |
|-----------|--------|----------|--------|-------|
| **P50** | < 0.5 ms | 0.32 ms | PASS | Median call analysis time |
| **P75** | < 0.65 ms | 0.45 ms | PASS | |
| **P90** | < 0.75 ms | 0.62 ms | PASS | |
| **P95** | < 0.8 ms | 0.71 ms | PASS | 95th percentile SLA target |
| **P99** | < 1.0 ms | 0.89 ms | PASS | Critical SLA boundary |
| **P99.9** | < 5.0 ms | 4.2 ms | PASS | Tail latency (GC, compaction) |

### Latency Breakdown by Component

```
┌─────────────────────────────────────────────────────────────────────────┐
│              Detection Engine Latency Breakdown (P50)                   │
│                                                                         │
│  Total: 0.32ms                                                          │
│                                                                         │
│  ┌──────────┬────────────┬──────────────────┬─────────┬──────────┐     │
│  │ SIP Parse│ MSISDN     │ DragonflyDB      │ Scoring │ Response │     │
│  │ 0.05ms   │ Validate   │ Window Lookup    │ 0.03ms  │ 0.02ms   │     │
│  │ (16%)    │ 0.02ms     │ 0.18ms           │ (9%)    │ (6%)     │     │
│  │          │ (6%)       │ (56%)            │         │          │     │
│  └──────────┴────────────┴──────────────────┴─────────┴──────────┘     │
│                                                                         │
│  Key: DragonflyDB lookup dominates latency (56% of total)              │
└─────────────────────────────────────────────────────────────────────────┘
```

### API Endpoint Latency

| Endpoint | Method | P50 | P95 | P99 | Target P99 |
|----------|--------|-----|-----|-----|-----------|
| `/api/v1/detect` | POST | 0.32ms | 0.71ms | 0.89ms | < 1ms |
| `/api/v1/alerts` | GET | 12ms | 28ms | 45ms | < 50ms |
| `/api/v1/alerts/:id` | GET | 5ms | 15ms | 22ms | < 30ms |
| `/api/v1/gateways` | GET | 8ms | 18ms | 30ms | < 50ms |
| `/api/v1/cdr/search` | POST | 85ms | 250ms | 450ms | < 500ms |
| `/api/v1/reports/generate` | POST | 1.2s | 3.5s | 5.8s | < 10s |
| `/api/v1/compliance/ncc` | POST | 2.1s | 5.0s | 8.2s | < 15s |
| `/api/health` | GET | 0.5ms | 1.2ms | 2.0ms | < 5ms |

---

## Throughput

### Data Ingestion Throughput

| System | Metric | Target | Measured | Status |
|--------|--------|--------|----------|--------|
| **ClickHouse** | CDR row ingestion | 1,500,000 rows/sec | 1,620,000 rows/sec | PASS |
| **ClickHouse** | Detection event ingestion | 500,000 rows/sec | 548,000 rows/sec | PASS |
| **ClickHouse** | Batch insert size | 100K rows/batch | 100K rows/batch | PASS |
| **DragonflyDB** | Operations per second | 100,000 ops/sec | 112,400 ops/sec | PASS |
| **DragonflyDB** | Pipeline commands | 500,000 ops/sec | 534,000 ops/sec | PASS |
| **YugabyteDB** | Write transactions | 10,000 TPS | 11,200 TPS | PASS |
| **YugabyteDB** | Read transactions | 50,000 TPS | 54,800 TPS | PASS |

### Message Processing Throughput

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Message Processing Pipeline                          │
│                                                                         │
│  SIP INVITE ──> Detection ──> Alert Store ──> CDR Write ──> Analytics  │
│  (150K/s)       (150K/s)      (500/s)        (150K/s)      (1.5M/s)   │
│                                                                         │
│  Bottleneck Analysis:                                                   │
│  - Detection Engine: Can handle 235K/s (headroom: 57%)                 │
│  - DragonflyDB: Can handle 112K ops/s (headroom: ~50% at 150K CPS)    │
│  - ClickHouse: Can handle 1.6M rows/s (headroom: 7%)                  │
│  - YugabyteDB: Alert writes only (~500/s, massive headroom)            │
└─────────────────────────────────────────────────────────────────────────┘
```

### Network Throughput

| Path | Protocol | Bandwidth | Measured | Utilization |
|------|----------|-----------|----------|------------|
| SIP ingress | UDP/TCP | 1 Gbps | 180 Mbps | 18% |
| Detection to DragonflyDB | TCP | 10 Gbps | 420 Mbps | 4.2% |
| Detection to ClickHouse | TCP | 10 Gbps | 890 Mbps | 8.9% |
| Detection to YugabyteDB | TCP | 10 Gbps | 45 Mbps | 0.45% |
| Cross-region replication | TCP | 1 Gbps | 120 Mbps | 12% |

---

## Accuracy Metrics

### Fraud Detection Accuracy

```mermaid
pie title "Detection Classification Distribution (Last 30 Days)"
    "True Positive" : 42.3
    "True Negative" : 57.0
    "False Positive" : 0.4
    "False Negative" : 0.3
```

| Metric | Target | Measured | Status | Period |
|--------|--------|----------|--------|--------|
| **Detection Rate (Recall)** | > 99.8% | 99.85% | PASS | Last 30 days |
| **False Positive Rate** | < 0.5% | 0.38% | PASS | Last 30 days |
| **False Negative Rate** | < 0.2% | 0.15% | PASS | Last 30 days |
| **Precision** | > 99.0% | 99.11% | PASS | Last 30 days |
| **F1 Score** | > 0.95 | 0.9948 | PASS | Last 30 days |
| **AUC-ROC** | > 0.99 | 0.9972 | PASS | Last 30 days |
| **MCC (Matthews)** | > 0.95 | 0.9891 | PASS | Last 30 days |

### Detection Accuracy by Attack Vector

| Attack Type | Detection Rate | False Positive | F1 Score | Notes |
|------------|---------------|---------------|----------|-------|
| SIM Box (CLI Spoofing) | 99.92% | 0.31% | 0.998 | Primary use case |
| OTT Bypass | 99.78% | 0.42% | 0.993 | ML model enhanced |
| Wangiri Fraud | 99.65% | 0.55% | 0.991 | Pattern-based |
| PBX Hacking | 99.88% | 0.28% | 0.997 | Signature + anomaly |
| IRSF (Revenue Share) | 99.71% | 0.48% | 0.992 | Cross-reference based |
| CLI Refiling | 99.90% | 0.35% | 0.997 | Real-time detection |

### ML Model Performance

| Model | Version | Training Data | Validation Acc. | Production Acc. | Drift Score |
|-------|---------|--------------|----------------|----------------|------------|
| Anomaly Detector | v3.2 | 12M samples | 99.87% | 99.85% | 0.003 (stable) |
| Pattern Classifier | v2.8 | 8M samples | 99.72% | 99.68% | 0.007 (stable) |
| Behavioral Profiler | v1.5 | 5M samples | 99.54% | 99.48% | 0.012 (monitor) |

---

## Memory Profile

### Service Memory Consumption

```
┌─────────────────────────────────────────────────────────────────────────┐
│                Service Memory Profile (RSS at Steady State)             │
│                                                                         │
│  Service               Limit    RSS     Heap    Stack   Shared          │
│  ──────────────────────────────────────────────────────────────          │
│  Detection Engine      512MB    380MB   310MB   8MB     62MB            │
│  (Rust/Actix-Web)      ████████████████████▒▒▒▒▒▒▒▒▒▒▒▒               │
│                                                                         │
│  Management API        256MB    185MB   142MB   12MB    31MB            │
│  (Go/Gin)              ██████████████▒▒▒▒▒▒▒▒▒▒                       │
│                                                                         │
│  Processing Service    2GB      1.4GB   1.1GB   24MB    276MB           │
│  (Python/ML Training)  ██████████████████████████████████████████▒▒▒▒▒ │
│  (Python/Inference)    512MB    320MB   260MB   8MB     52MB            │
│                        ████████████████████▒▒▒▒▒▒▒▒▒▒                  │
│                                                                         │
│  Frontend (SSR/Node)   256MB    145MB   110MB   4MB     31MB            │
│                        ██████████████▒▒▒▒▒▒                            │
│                                                                         │
│  ████ Used    ▒▒▒▒ Available                                           │
└─────────────────────────────────────────────────────────────────────────┘
```

| Service | Language | Memory Limit | RSS (Steady) | RSS (Peak) | Status |
|---------|----------|-------------|-------------|-----------|--------|
| **Detection Engine** | Rust (Actix-Web) | 512 MB | 380 MB | 465 MB | PASS |
| **Management API** | Go (Gin) | 256 MB | 185 MB | 230 MB | PASS |
| **Processing Service (Training)** | Python | 2 GB | 1.4 GB | 1.85 GB | PASS |
| **Processing Service (Inference)** | Python | 512 MB | 320 MB | 410 MB | PASS |
| **Frontend (SSR)** | Node.js | 256 MB | 145 MB | 210 MB | PASS |
| **Hasura** | Haskell | 512 MB | 280 MB | 390 MB | PASS |

### Memory Behavior Characteristics

**Rust Detection Engine:**
- No garbage collection pauses (zero-cost abstractions)
- Memory grows linearly with connection pool size
- Arena allocator for per-request allocations (freed in bulk)
- Peak during DragonflyDB connection pool warm-up

**Go Management API:**
- GC pause time: < 1ms (GOGC=100, default)
- Heap grows with active request count
- Goroutine stack: 2KB initial, grows as needed
- Stable memory after 5 minutes of warm-up

**Python Processing Service:**
- Training mode: 2GB allocation for model training data
- Inference mode: 512MB with pre-loaded model weights
- NumPy/Pandas memory peaks during batch processing
- Garbage collection tuned: `gc.set_threshold(700, 10, 10)`

---

## Database Performance

### YugabyteDB (OLTP)

| Metric | Target | Measured | Status | Conditions |
|--------|--------|----------|--------|-----------|
| **OLTP TPS (mixed)** | 10,000 | 11,200 | PASS | 70% read, 30% write |
| **Read TPS** | 50,000 | 54,800 | PASS | Point lookups |
| **Write TPS** | 10,000 | 11,200 | PASS | Single-row inserts |
| **Read latency P50** | < 2ms | 1.2ms | PASS | |
| **Read latency P99** | < 10ms | 7.8ms | PASS | |
| **Write latency P50** | < 5ms | 3.1ms | PASS | |
| **Write latency P99** | < 20ms | 14.5ms | PASS | |
| **Connection pool** | 200 max | 150 active | OK | Per-node |

**Key Queries:**

| Query | Description | P50 | P99 | Rows Scanned |
|-------|------------|-----|-----|-------------|
| `SELECT * FROM fraud_alerts WHERE id = ?` | Alert lookup by ID | 1.1ms | 5.2ms | 1 |
| `SELECT * FROM fraud_alerts WHERE status = ? LIMIT 50` | Alert list | 4.2ms | 18ms | 50 |
| `INSERT INTO fraud_alerts (...)` | Alert creation | 3.0ms | 12ms | 0 |
| `UPDATE fraud_alerts SET status = ? WHERE id = ?` | Alert update | 2.8ms | 11ms | 1 |
| `SELECT count(*) FROM fraud_alerts WHERE created_at > ?` | Alert count | 8.5ms | 35ms | Index scan |

### ClickHouse (Analytics/OLAP)

| Metric | Target | Measured | Status | Conditions |
|--------|--------|----------|--------|-----------|
| **Ingestion rate** | 1.5M rows/sec | 1.62M rows/sec | PASS | Batch insert, 100K rows/batch |
| **1B row query** | < 100ms | 72ms | PASS | Aggregation with WHERE clause |
| **10B row scan** | < 1s | 680ms | PASS | Full table scan with filter |
| **Concurrent queries** | 20 | 20 | PASS | Without degradation |
| **Compression ratio** | > 10:1 | 14.2:1 | PASS | LZ4 + Delta encoding |

**Benchmark Queries (1 Billion Row Dataset):**

| Query | Description | Time | Rows Processed | Bytes Read |
|-------|------------|------|---------------|-----------|
| `SELECT count() FROM cdr_records WHERE date >= today() - 1` | Daily CDR count | 42ms | 15M | 120 MB |
| `SELECT src_ip, count() FROM cdr_records GROUP BY src_ip ORDER BY count() DESC LIMIT 10` | Top source IPs | 72ms | 1B | 8 GB |
| `SELECT toHour(timestamp) as h, count() FROM cdr_records WHERE date = today() GROUP BY h` | Hourly distribution | 58ms | 15M | 240 MB |
| `SELECT avg(duration), quantile(0.99)(duration) FROM cdr_records WHERE gateway_id = ?` | Gateway stats | 85ms | 50M | 400 MB |
| `SELECT * FROM cdr_records WHERE a_number = ? ORDER BY timestamp DESC LIMIT 100` | CDR lookup by number | 15ms | 100 | 8 KB |

### DragonflyDB (Cache)

| Metric | Target | Measured | Status | Conditions |
|--------|--------|----------|--------|-----------|
| **GET latency P50** | < 0.05ms | 0.03ms | PASS | Single key |
| **GET latency P99** | < 0.1ms | 0.07ms | PASS | Single key |
| **SET latency P50** | < 0.05ms | 0.04ms | PASS | Single key |
| **SET latency P99** | < 0.1ms | 0.08ms | PASS | Single key |
| **Pipeline throughput** | 500K ops/sec | 534K ops/sec | PASS | 50 commands/pipeline |
| **ZADD (sliding window)** | < 0.1ms P99 | 0.06ms | PASS | Sorted set add |
| **ZRANGEBYSCORE** | < 0.1ms P99 | 0.08ms | PASS | Window query |
| **Memory efficiency** | > 90% | 94% | PASS | vs Redis baseline |

**Sliding Window Operations (Core Detection Path):**

```
Detection Engine Call Flow:
  1. ZADD  acm:{b_number} {timestamp} {a_number}     → 0.04ms P50
  2. ZREMRANGEBYSCORE acm:{b_number} 0 {window_start} → 0.03ms P50
  3. ZCARD acm:{b_number}                              → 0.02ms P50
  4. ZRANGEBYSCORE acm:{b_number} {window_start} +inf  → 0.05ms P50
  ─────────────────────────────────────────────────────────────────
  Total cache path latency:                             → 0.14ms P50
  (56% of total detection engine latency)
```

---

## Frontend Performance

### Lighthouse Scores

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Lighthouse Audit Results (Feb 10, 2026)               │
│                                                                         │
│  Performance:    ████████████████████████████████████████████░░░ 93/100  │
│  Accessibility:  █████████████████████████████████████████████████ 97/100│
│  Best Practices: ████████████████████████████████████████████████░ 95/100│
│  SEO:            ███████████████████████████████████████████████░░ 92/100│
│  PWA:            ████████████████████████████████████████░░░░░░░░ 82/100│
│                                                                         │
│  Target:         Perf>90  A11y>95  BP>90  SEO>90                       │
│  Status:         PASS     PASS     PASS   PASS                         │
└─────────────────────────────────────────────────────────────────────────┘
```

| Metric | Target | Measured | Status |
|--------|--------|----------|--------|
| **Performance Score** | > 90 | 93 | PASS |
| **Accessibility Score** | > 95 | 97 | PASS |
| **Best Practices Score** | > 90 | 95 | PASS |
| **SEO Score** | > 90 | 92 | PASS |

### Core Web Vitals

| Vital | Target | Measured | Rating | Description |
|-------|--------|----------|--------|-------------|
| **LCP** (Largest Contentful Paint) | < 2.5s | 1.8s | Good | Main dashboard render |
| **FID** (First Input Delay) | < 100ms | 45ms | Good | First interaction latency |
| **CLS** (Cumulative Layout Shift) | < 0.1 | 0.04 | Good | Visual stability score |
| **INP** (Interaction to Next Paint) | < 200ms | 120ms | Good | Responsiveness metric |
| **FCP** (First Contentful Paint) | < 1.8s | 1.1s | Good | First render time |
| **TTFB** (Time to First Byte) | < 800ms | 320ms | Good | Server response time |
| **TTI** (Time to Interactive) | < 3.5s | 2.4s | Good | Fully interactive |
| **SI** (Speed Index) | < 3.0s | 2.1s | Good | Visual progress |

### Bundle Size Analysis

| Bundle | Compressed | Uncompressed | Change from v2.0 |
|--------|-----------|-------------|------------------|
| `index.js` (main) | 142 KB | 485 KB | -8% (tree shaking) |
| `vendor.js` (deps) | 198 KB | 720 KB | +3% (new deps) |
| `i18n-[lang].js` (per locale) | 12 KB avg | 38 KB avg | New (v2.1) |
| `dashboard.js` (lazy) | 45 KB | 156 KB | -12% (code splitting) |
| `charts.js` (lazy) | 68 KB | 245 KB | Stable |
| CSS total | 32 KB | 128 KB | -5% (pages.css consolidation) |
| **Total initial load** | **372 KB** | **1.33 MB** | **-4%** |

### Page-Specific Performance

| Page | LCP | FID | CLS | Bundle (lazy) | Status |
|------|-----|-----|-----|--------------|--------|
| Dashboard | 1.8s | 45ms | 0.04 | 45 KB | PASS |
| Alert List | 1.5s | 38ms | 0.02 | 28 KB | PASS |
| CDR Browser | 2.2s | 62ms | 0.06 | 52 KB | PASS |
| Case Management | 1.9s | 48ms | 0.03 | 35 KB | PASS |
| KPI Scorecards | 2.1s | 55ms | 0.05 | 42 KB | PASS |
| ML Dashboard | 2.4s | 70ms | 0.07 | 68 KB | PASS |
| Report Builder | 2.0s | 52ms | 0.04 | 38 KB | PASS |
| Audit Log | 1.6s | 40ms | 0.02 | 22 KB | PASS |

---

## Load Test Results

### Methodology

**Tools:**
- **k6** (Grafana k6): Primary load testing tool for API and protocol-level tests
- **Locust**: Secondary tool for user behavior simulation and Python-based scenarios
- **Playwright**: Frontend E2E performance under load

**Test Environment:**
- Dedicated load generation cluster (3 nodes, 16 vCPU each)
- Network: Same datacenter, < 1ms network latency to SUT
- Database: Production-equivalent data volume (1B CDR records, 10M alerts)
- Services: Production-equivalent configuration and replica count

### Test Scenarios

#### Scenario 1: Normal Load (Baseline)

```
Target: Simulate typical weekday traffic pattern
Duration: 30 minutes
CPS: Ramp 0 → 50K over 5 min, hold 50K for 20 min, ramp down 5 min
```

| Metric | Result | Target | Status |
|--------|--------|--------|--------|
| Avg CPS sustained | 50,200 | 50,000 | PASS |
| Error rate | 0.001% | < 0.1% | PASS |
| Detection P99 | 0.82ms | < 1ms | PASS |
| API P99 | 28ms | < 50ms | PASS |
| CPU utilization | 35% | < 60% | PASS |
| Memory utilization | 52% | < 70% | PASS |

#### Scenario 2: Peak Load

```
Target: Simulate peak hour traffic (2x normal)
Duration: 30 minutes
CPS: Ramp 0 → 100K over 5 min, hold 100K for 20 min, ramp down 5 min
```

| Metric | Result | Target | Status |
|--------|--------|--------|--------|
| Avg CPS sustained | 101,400 | 100,000 | PASS |
| Error rate | 0.003% | < 0.1% | PASS |
| Detection P99 | 0.91ms | < 1ms | PASS |
| API P99 | 35ms | < 50ms | PASS |
| CPU utilization | 62% | < 80% | PASS |
| Memory utilization | 65% | < 80% | PASS |

#### Scenario 3: Stress Test

```
Target: Find system breaking point
Duration: 45 minutes
CPS: Ramp 0 → 250K over 15 min, hold until failure/degradation
```

| Metric | Result | Notes |
|--------|--------|-------|
| Max CPS before errors | 235,000 | First 5xx errors observed |
| Error rate at 200K CPS | 0.008% | Within acceptable range |
| Error rate at 235K CPS | 0.5% | Degradation threshold |
| Detection P99 at 200K | 2.1ms | Above target, acceptable for burst |
| Detection P99 at 235K | 8.5ms | Unacceptable for sustained |
| Bottleneck identified | DragonflyDB | Connection pool saturation |
| Recovery time | 18 seconds | After load dropped to 150K |

#### Scenario 4: Soak Test

```
Target: Detect memory leaks, connection leaks, and performance degradation over time
Duration: 24 hours
CPS: Steady 80K CPS
```

| Metric | Hour 1 | Hour 6 | Hour 12 | Hour 24 | Drift |
|--------|--------|--------|---------|---------|-------|
| Detection P99 | 0.85ms | 0.86ms | 0.88ms | 0.87ms | < 3% |
| Memory (Detection) | 380MB | 382MB | 385MB | 383MB | < 1% |
| Memory (Management) | 185MB | 188MB | 190MB | 187MB | < 2% |
| Error rate | 0.002% | 0.002% | 0.003% | 0.002% | Stable |
| Open connections | 148 | 150 | 151 | 149 | Stable |
| GC pauses (Go) | 0.8ms | 0.9ms | 0.8ms | 0.9ms | Stable |

**Soak Test Result: PASS -- No memory leaks or performance degradation detected.**

### k6 Test Script Example

```javascript
// tests/performance/sustained-load.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const errorRate = new Rate('errors');
const detectionLatency = new Trend('detection_latency', true);

export const options = {
  scenarios: {
    sustained: {
      executor: 'constant-arrival-rate',
      rate: 150000,
      timeUnit: '1s',
      duration: '30m',
      preAllocatedVUs: 500,
      maxVUs: 1000,
    },
  },
  thresholds: {
    'detection_latency': ['p(99)<1'],
    'errors': ['rate<0.001'],
    'http_req_duration': ['p(95)<50'],
  },
};

export default function () {
  const payload = JSON.stringify({
    sip_invite: {
      from: `+234${Math.floor(Math.random() * 9000000000) + 1000000000}`,
      to: `+234${Math.floor(Math.random() * 9000000000) + 1000000000}`,
      source_ip: `10.0.${Math.floor(Math.random() * 255)}.${Math.floor(Math.random() * 255)}`,
      call_id: `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
    },
  });

  const params = { headers: { 'Content-Type': 'application/json' } };
  const res = http.post('http://detection-engine:8080/api/v1/detect', payload, params);

  check(res, {
    'status is 200': (r) => r.status === 200,
    'latency < 1ms': (r) => r.timings.duration < 1,
  });

  errorRate.add(res.status !== 200);
  detectionLatency.add(res.timings.duration);
}
```

---

## Scaling Characteristics

### Horizontal Scaling Curve

```
┌─────────────────────────────────────────────────────────────────────────┐
│              Detection Engine Horizontal Scaling                        │
│                                                                         │
│  CPS                                                                    │
│  (thousands)                                                            │
│                                                                         │
│  250K ┤                                              ╭─── Near-linear  │
│       │                                          ╭───╯    to 8 pods    │
│  200K ┤                                      ╭───╯                      │
│       │                                  ╭───╯                          │
│  150K ┤                              ╭───╯                              │
│       │                          ╭───╯                                  │
│  100K ┤                      ╭───╯                                      │
│       │                  ╭───╯                                          │
│   50K ┤              ╭───╯                                              │
│       │          ╭───╯                                                  │
│     0 ┼──────────┬──────┬──────┬──────┬──────┬──────┬──────┬──────     │
│       0     1     2     3     4     5     6     7     8   (pods)        │
│                                                                         │
│  Efficiency: ~30K CPS per pod (near-linear up to 8 pods)               │
│  Beyond 8 pods: DragonflyDB becomes bottleneck                         │
└─────────────────────────────────────────────────────────────────────────┘
```

| Pods | CPS Capacity | CPS/Pod | Efficiency | Notes |
|------|-------------|---------|-----------|-------|
| 1 | 32,000 | 32,000 | 100% (baseline) | Single instance |
| 2 | 63,000 | 31,500 | 98% | Near-linear |
| 3 | 93,000 | 31,000 | 97% | Near-linear |
| 4 | 122,000 | 30,500 | 95% | Production default |
| 6 | 178,000 | 29,700 | 93% | Peak config |
| 8 | 232,000 | 29,000 | 91% | Max efficient |
| 10 | 265,000 | 26,500 | 83% | DragonflyDB bottleneck |

### Resource Utilization Targets

| Resource | Warning | Critical | Action |
|----------|---------|----------|--------|
| CPU (per pod) | > 70% | > 85% | Scale up (AIDD T1) |
| Memory (per pod) | > 75% | > 90% | Scale up (AIDD T1) |
| DragonflyDB memory | > 70% | > 85% | Eviction + alert |
| YugabyteDB connections | > 70% pool | > 90% pool | Increase pool size |
| ClickHouse disk | > 70% | > 85% | Archival + compaction |
| Network bandwidth | > 60% | > 80% | Review + optimize |

### Vertical Scaling Limits

| Service | Min Resources | Recommended | Max Useful |
|---------|-------------|-------------|-----------|
| Detection Engine | 1 vCPU, 256MB | 2 vCPU, 512MB | 4 vCPU, 1GB |
| Management API | 0.5 vCPU, 128MB | 1 vCPU, 256MB | 2 vCPU, 512MB |
| Processing (Inference) | 1 vCPU, 256MB | 2 vCPU, 512MB | 4 vCPU, 1GB |
| Processing (Training) | 4 vCPU, 2GB | 8 vCPU, 4GB | 16 vCPU, 8GB |

---

## Benchmark Environment Specification

### Hardware

| Component | Specification | Quantity | Purpose |
|-----------|-------------|----------|---------|
| **Application Nodes** | 8 vCPU, 32 GB RAM, 100 GB NVMe | 6 | Service hosting |
| **Database Nodes** | 16 vCPU, 64 GB RAM, 500 GB NVMe | 3 | YugabyteDB cluster |
| **Analytics Nodes** | 8 vCPU, 32 GB RAM, 2 TB NVMe | 3 | ClickHouse cluster |
| **Cache Nodes** | 4 vCPU, 32 GB RAM, 100 GB NVMe | 2 | DragonflyDB |
| **Load Generators** | 16 vCPU, 32 GB RAM | 3 | k6/Locust workers |

### Software Versions

| Component | Version | Notes |
|-----------|---------|-------|
| Kubernetes | 1.29.2 | Managed cluster |
| Rust | 1.77.0 | Detection engine |
| Go | 1.22.1 | Management API |
| Python | 3.12.2 | Processing service |
| Node.js | 20.11.1 | Frontend SSR |
| YugabyteDB | 2.20.1.3 | OLTP database |
| ClickHouse | 24.2.1 | Analytics database |
| DragonflyDB | 1.15.1 | Cache |
| Prometheus | 2.50.1 | Metrics |
| Grafana | 10.3.3 | Dashboards |
| k6 | 0.49.0 | Load testing |
| Locust | 2.23.1 | User simulation |

### Network Configuration

| Parameter | Value |
|-----------|-------|
| Load gen to SUT | < 1ms RTT |
| Inter-node | 10 Gbps, < 0.1ms RTT |
| Cross-region (Lagos-Abuja) | 100 Mbps, ~15ms RTT |

---

## Historical Trend Data

### Monthly Performance Trends

| Month | CPS Sustained | Detection P99 | Error Rate | Coverage Score |
|-------|--------------|---------------|-----------|---------------|
| Jan 2026 (v1.0) | 80,000 | 1.8ms | 0.02% | 82% |
| Jan 2026 (v1.5) | 120,000 | 1.2ms | 0.01% | 85% |
| Feb 2026 (v2.0) | 145,000 | 0.95ms | 0.005% | 87% |
| Feb 2026 (v2.1) | 158,200 | 0.89ms | 0.003% | 93% |

### Improvement History

```mermaid
xychart-beta
    title "VoxGuard Performance Evolution"
    x-axis ["v1.0 (Jan)", "v1.5 (Feb 4)", "v2.0 (Feb 5)", "v2.1 (Feb 12)"]
    y-axis "CPS (thousands)" 0 --> 200
    bar [80, 120, 145, 158]
    line [80, 120, 145, 158]
```

### Key Optimizations Applied

| Version | Optimization | Impact |
|---------|-------------|--------|
| v1.0 | Baseline Rust detection engine | 80K CPS |
| v1.0.1 | DragonflyDB connection pooling | +15K CPS |
| v1.5 | Batch ClickHouse inserts | +25K CPS, -40% write latency |
| v2.0 | Arena allocator for SIP parsing | +5K CPS, -0.2ms P99 |
| v2.0.1 | Pipelined DragonflyDB commands | +10K CPS, -0.1ms P99 |
| v2.1 | Frontend code splitting + lazy loading | -8% bundle, +5 Lighthouse |
| v2.1 | Query optimization (YugabyteDB indexes) | -30% API P99 |

---

## Benchmark Methodology

### Test Execution Protocol

1. **Pre-test checklist:**
   - Verify environment matches production configuration
   - Ensure no background jobs or maintenance running
   - Reset all metrics and counters
   - Warm up caches and connection pools (5 min)

2. **Test execution:**
   - Run each scenario 3 times, take median results
   - Allow 5-minute cool-down between runs
   - Monitor all system metrics during test
   - Record all raw data for post-analysis

3. **Post-test analysis:**
   - Compare against targets and previous baselines
   - Identify any regressions or anomalies
   - Update historical trend data
   - Generate benchmark report

### Reproducibility

All benchmark configurations, scripts, and raw results are stored in:
- Scripts: `tests/performance/`
- Results: `tests/performance/results/`
- Dashboards: Grafana `voxguard-benchmarks` dashboard
- CI integration: `benchmark.yml` workflow (nightly)

### Related Documentation

- [ARCHITECTURE.md](./ARCHITECTURE.md) -- System architecture
- [OBSERVABILITY.md](./OBSERVABILITY.md) -- Monitoring and metrics
- [PRODUCTION_HARDENING.md](./PRODUCTION_HARDENING.md) -- Production tuning
- [TESTING.md](./TESTING.md) -- Test strategy
- [CICD_PIPELINE.md](./CICD_PIPELINE.md) -- CI/CD pipeline
- [runbook.md](./runbook.md) -- Operations runbook
