# ACM Detection Engine Performance Requirements

## Target Performance Metrics

| Metric | Target | Current Status |
|--------|--------|----------------|
| **Calls Per Second (CPS)** | 150,000+ | Pending benchmark |
| **Detection Latency (P50)** | <0.5ms | Pending benchmark |
| **Detection Latency (P99)** | <1ms | Pending benchmark |
| **Cache Hit Rate** | >99% | Pending benchmark |
| **Time-Series Ingestion** | 1.5M rows/sec | QuestDB ILP implemented |
| **Memory Usage** | <512MB per node | Pending benchmark |

## Architecture Optimizations

### 1. Sliding Window Detection (DragonflyDB)
- **Connection Pooling**: 32 multiplexed connections per node
- **Pipeline Mode**: Batched operations for atomicity
- **Key Design**: `window:{b_number}` with TTL = detection window
- **Data Structure**: Sets for O(1) distinct caller count

### 2. Time-Series Ingestion (QuestDB)
- **Protocol**: InfluxDB Line Protocol (ILP) over TCP
- **Format**: `calls,b_number=X,source_ip=Y a_number="Z" timestamp_ns`
- **Batching**: 1000 rows per batch with 100ms flush interval
- **Target**: 1.5M rows/second ingestion rate

### 3. Persistent Storage (YugabyteDB)
- **Connection Pool**: sqlx with max 100 connections
- **Indexes**: Composite index on `(b_number, timestamp)`
- **Partitioning**: Time-based partitioning by day
- **Geo-Distribution**: Multi-region replication for HA

### 4. Rust Optimizations
- **Zero-Copy**: Value objects avoid allocations where possible
- **SIMD**: xxHash for fast hashing
- **Async Runtime**: tokio with work-stealing scheduler
- **Build Profile**: LTO + codegen-units=1 for release

## Benchmark Commands

```bash
# Run all benchmarks
cargo bench

# Run specific benchmark group
cargo bench -- msisdn

# Generate HTML report
cargo bench -- --save-baseline main

# Run with flamegraph
cargo flamegraph --bench detection_benchmark
```

## Performance Testing Scenarios

### Scenario 1: Normal Traffic
- 50K CPS sustained for 60 seconds
- Random Nigerian numbers (+234)
- 1% fraud rate

### Scenario 2: Masking Attack
- 5 distinct A-numbers calling same B-number within 5 seconds
- Triggered 100 times per second
- Verify alert generation within 10ms

### Scenario 3: Peak Load
- 200K CPS burst for 10 seconds
- Measure latency degradation
- Verify no message loss

### Scenario 4: Gateway Overload
- 1000 calls/sec from single source IP
- Verify gateway rate limiting
- Measure blacklist propagation time

## Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 8 cores | 16+ cores |
| RAM | 16 GB | 32 GB |
| NVMe SSD | 500 GB | 1 TB |
| Network | 10 Gbps | 25 Gbps |

## Monitoring Metrics

Prometheus metrics exposed at `/metrics`:

- `acm_calls_total{status,region}` - Total calls processed
- `acm_detection_latency_seconds{region}` - Detection latency histogram
- `acm_alerts_total{fraud_type,severity,region}` - Alerts generated
- `acm_cache_operations_total{operation,result}` - Cache hit/miss
- `acm_active_calls` - Current calls in detection window
- `acm_pending_alerts` - Unacknowledged alerts count
