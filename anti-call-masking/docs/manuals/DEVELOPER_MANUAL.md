# Developer Manual
## Anti-Call Masking Detection System

**Version:** 2.0
**Last Updated:** January 2026
**Architecture:** Rust + QuestDB + DragonflyDB + YugabyteDB

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Architecture Overview](#2-architecture-overview)
3. [Development Environment](#3-development-environment)
4. [Domain-Driven Design](#4-domain-driven-design)
5. [Coding Standards](#5-coding-standards)
6. [API Development](#6-api-development)
7. [Database Schema](#7-database-schema)
8. [Testing Guide](#8-testing-guide)
9. [CI/CD Pipeline](#9-cicd-pipeline)
10. [Performance Optimization](#10-performance-optimization)
11. [Debugging & Profiling](#11-debugging--profiling)
12. [Contributing Guidelines](#12-contributing-guidelines)

---

## 1. Introduction

### 1.1 Purpose

This manual provides comprehensive guidance for developers working on the Anti-Call Masking Detection System. It covers architecture, coding standards, testing practices, and deployment procedures following XP, DDD, and TDD principles.

### 1.2 Target Audience

- Backend Developers (Rust, Go)
- Frontend Developers (React, TypeScript)
- Database Developers
- DevOps Engineers
- QA Engineers

### 1.3 Technology Stack

| Layer | Technology | Version |
|-------|------------|---------|
| Detection Engine | Rust | 1.75+ |
| Management API | Go | 1.21+ |
| Frontend | React + TypeScript | 18.x |
| Cache | DragonflyDB | 1.14+ |
| Time-Series DB | QuestDB | 7.4+ |
| Relational DB | YugabyteDB | 2.20+ |
| Analytics DB | ClickHouse | 24.1+ |
| Monitoring | Prometheus + Grafana | Latest |

---

## 2. Architecture Overview

### 2.1 System Components

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Anti-Call Masking Platform                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        Presentation Layer                            │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │   │
│  │  │  Web UI      │  │  Mobile App  │  │  REST API    │               │   │
│  │  │  (React)     │  │  (React Nat) │  │  (Go)        │               │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘               │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        Application Layer                             │   │
│  │  ┌──────────────────────────────────────────────────────────────┐   │   │
│  │  │                Detection Engine (Rust)                        │   │   │
│  │  │  ┌────────────┐  ┌────────────┐  ┌────────────┐              │   │   │
│  │  │  │ Event      │  │ Detection  │  │ Action     │              │   │   │
│  │  │  │ Processor  │  │ Algorithm  │  │ Executor   │              │   │   │
│  │  │  └────────────┘  └────────────┘  └────────────┘              │   │   │
│  │  └──────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        Domain Layer                                  │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │   │
│  │  │  Fraud       │  │  Compliance  │  │  Gateway     │               │   │
│  │  │  Domain      │  │  Domain      │  │  Domain      │               │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘               │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        Infrastructure Layer                          │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐    │   │
│  │  │ DragonflyDB│  │  QuestDB   │  │ YugabyteDB │  │ ClickHouse │    │   │
│  │  └────────────┘  └────────────┘  └────────────┘  └────────────┘    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Data Flow

```
1. Call Event Received (SIP/HTTP)
        │
        ▼
2. Event Validation & Normalization
        │
        ▼
3. Cache Lookup (DragonflyDB)
   - Get current B-number state
   - Check whitelist
        │
        ▼
4. Detection Algorithm
   - Count distinct A-numbers
   - Check time window
   - Calculate threat level
        │
        ▼
5. Alert Decision
   ├── No Alert → Update cache, log event
   │
   └── Alert Generated
            │
            ▼
6. Action Execution
   - Disconnect calls (OpenSIPS)
   - Block pattern (DragonflyDB)
   - Notify operators
        │
        ▼
7. Persistence
   - QuestDB (real-time analytics)
   - YugabyteDB (alert records)
   - ClickHouse (historical)
        │
        ▼
8. NCC Reporting (if enabled)
```

---

## 3. Development Environment

### 3.1 Prerequisites

```bash
# Rust toolchain
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup default stable
rustup component add rustfmt clippy

# Go toolchain
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Node.js (for frontend)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

### 3.2 Repository Setup

```bash
# Clone repository
git clone https://github.com/yourorg/anti-call-masking.git
cd anti-call-masking

# Install pre-commit hooks
pip install pre-commit
pre-commit install

# Start development databases
docker-compose -f docker-compose.dev.yml up -d

# Build Rust detection engine
cd detection-service-rust
cargo build

# Build Go management API
cd ../management-api
go build ./...

# Build frontend
cd ../frontend
npm install
npm run dev
```

### 3.3 IDE Configuration

#### VS Code Extensions
```json
{
  "recommendations": [
    "rust-lang.rust-analyzer",
    "golang.go",
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "ms-azuretools.vscode-docker"
  ]
}
```

#### Rust Analyzer Settings
```json
{
  "rust-analyzer.checkOnSave.command": "clippy",
  "rust-analyzer.cargo.features": "all"
}
```

### 3.4 Environment Variables

```bash
# .env.development
DATABASE_URL=postgres://opensips:dev_password@localhost:5433/opensips
DRAGONFLY_URL=redis://localhost:6379
QUESTDB_URL=postgres://admin:quest@localhost:8812/qdb
CLICKHOUSE_URL=http://localhost:8123

RUST_LOG=debug,acm_detection=trace
RUST_BACKTRACE=1

# Detection config
ACM_DETECTION_THRESHOLD=5
ACM_DETECTION_WINDOW_SECONDS=5
```

---

## 4. Domain-Driven Design

### 4.1 Bounded Contexts

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Anti-Call Masking Domain                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────┐  │
│  │  Fraud Context  │  │ Compliance Ctx  │  │    Gateway Context      │  │
│  │                 │  │                 │  │                         │  │
│  │  - CallEvent    │  │  - NCCReport    │  │  - SIPGateway           │  │
│  │  - FraudAlert   │  │  - DailyStats   │  │  - Carrier              │  │
│  │  - Detection    │  │  - Incident     │  │  - Route                │  │
│  │  - Whitelist    │  │  - Audit        │  │  - RateLimit            │  │
│  │                 │  │                 │  │                         │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────┘  │
│           │                   │                       │                 │
│           └───────────────────┼───────────────────────┘                 │
│                               │                                         │
│                        Shared Kernel                                    │
│              (PhoneNumber, Timestamp, UserId)                           │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Fraud Domain Entities

```rust
// src/domain/fraud/entity/call_event.rs

/// A telephony call event for fraud detection
#[derive(Debug, Clone)]
pub struct CallEvent {
    pub call_id: CallId,
    pub a_number: PhoneNumber,
    pub b_number: PhoneNumber,
    pub timestamp: Timestamp,
    pub status: CallStatus,
    pub source_ip: Option<IpAddr>,
    pub carrier_id: Option<CarrierId>,
}

impl CallEvent {
    pub fn new(
        call_id: CallId,
        a_number: PhoneNumber,
        b_number: PhoneNumber,
    ) -> Result<Self, DomainError> {
        // Validation logic
        if a_number == b_number {
            return Err(DomainError::InvalidCallEvent(
                "A-number cannot equal B-number".into()
            ));
        }

        Ok(Self {
            call_id,
            a_number,
            b_number,
            timestamp: Timestamp::now(),
            status: CallStatus::Active,
            source_ip: None,
            carrier_id: None,
        })
    }
}

/// A fraud alert generated by the detection system
#[derive(Debug, Clone)]
pub struct FraudAlert {
    pub alert_id: AlertId,
    pub alert_type: AlertType,
    pub severity: Severity,
    pub b_number: PhoneNumber,
    pub a_numbers: Vec<PhoneNumber>,
    pub detection_window_ms: u32,
    pub detected_at: Timestamp,
    pub status: AlertStatus,
    pub ncc_incident_id: Option<String>,
}

impl FraudAlert {
    pub fn create_masking_alert(
        b_number: PhoneNumber,
        a_numbers: Vec<PhoneNumber>,
        window_ms: u32,
    ) -> Self {
        let severity = Self::calculate_severity(a_numbers.len());

        Self {
            alert_id: AlertId::generate(),
            alert_type: AlertType::MulticallMasking,
            severity,
            b_number,
            a_numbers,
            detection_window_ms: window_ms,
            detected_at: Timestamp::now(),
            status: AlertStatus::New,
            ncc_incident_id: None,
        }
    }

    fn calculate_severity(a_number_count: usize) -> Severity {
        match a_number_count {
            0..=4 => Severity::Low,
            5..=6 => Severity::High,
            _ => Severity::Critical,
        }
    }
}
```

### 4.3 Domain Services

```rust
// src/domain/fraud/service/detection_service.rs

pub struct DetectionService {
    config: DetectionConfig,
    cache: Arc<dyn CacheRepository>,
    alert_repository: Arc<dyn AlertRepository>,
}

impl DetectionService {
    pub async fn process_event(&self, event: CallEvent) -> Result<DetectionResult> {
        // 1. Check whitelist
        if self.cache.is_whitelisted(&event.b_number).await? {
            return Ok(DetectionResult::Whitelisted);
        }

        // 2. Update B-number state in cache
        let state = self.cache
            .add_a_number(&event.b_number, &event.a_number)
            .await?;

        // 3. Check detection threshold
        if state.distinct_a_numbers >= self.config.threshold {
            let window_ms = state.window_duration_ms();

            if window_ms <= self.config.window_ms {
                // Fraud detected!
                let alert = FraudAlert::create_masking_alert(
                    event.b_number.clone(),
                    state.a_numbers.clone(),
                    window_ms,
                );

                self.alert_repository.save(&alert).await?;

                return Ok(DetectionResult::FraudDetected(alert));
            }
        }

        Ok(DetectionResult::Clean)
    }
}
```

### 4.4 Repository Interfaces

```rust
// src/domain/fraud/repository/alert_repository.rs

#[async_trait]
pub trait AlertRepository: Send + Sync {
    async fn save(&self, alert: &FraudAlert) -> Result<()>;
    async fn find_by_id(&self, id: &AlertId) -> Result<Option<FraudAlert>>;
    async fn find_by_b_number(
        &self,
        b_number: &PhoneNumber,
        since: Timestamp,
    ) -> Result<Vec<FraudAlert>>;
    async fn update_status(
        &self,
        id: &AlertId,
        status: AlertStatus,
    ) -> Result<()>;
}

#[async_trait]
pub trait CacheRepository: Send + Sync {
    async fn add_a_number(
        &self,
        b_number: &PhoneNumber,
        a_number: &PhoneNumber,
    ) -> Result<BNumberState>;
    async fn get_state(&self, b_number: &PhoneNumber) -> Result<Option<BNumberState>>;
    async fn is_whitelisted(&self, b_number: &PhoneNumber) -> Result<bool>;
    async fn add_to_whitelist(
        &self,
        b_number: &PhoneNumber,
        reason: String,
        expires_at: Option<Timestamp>,
    ) -> Result<()>;
}
```

---

## 5. Coding Standards

### 5.1 Rust Standards

```rust
// Good: Descriptive names, proper error handling
pub async fn process_call_event(
    event: CallEvent,
    detection_service: &DetectionService,
) -> Result<DetectionResult, ProcessingError> {
    event.validate()?;

    let result = detection_service
        .process_event(event)
        .await
        .map_err(ProcessingError::DetectionFailed)?;

    Ok(result)
}

// Bad: Unclear names, panic on error
pub async fn proc(e: CallEvent, ds: &DetectionService) -> DetectionResult {
    ds.process_event(e).await.unwrap()
}
```

### 5.2 Error Handling

```rust
// Define domain-specific errors
#[derive(Debug, thiserror::Error)]
pub enum DetectionError {
    #[error("Cache error: {0}")]
    CacheError(#[from] CacheError),

    #[error("Repository error: {0}")]
    RepositoryError(#[from] RepositoryError),

    #[error("Invalid configuration: {0}")]
    ConfigError(String),

    #[error("Detection timeout")]
    Timeout,
}

// Use Result types consistently
pub type DetectionResult<T> = std::result::Result<T, DetectionError>;
```

### 5.3 Go Standards

```go
// Good: Clear error handling, context usage
func (s *AlertService) GetAlerts(
    ctx context.Context,
    filter AlertFilter,
) ([]Alert, error) {
    if err := filter.Validate(); err != nil {
        return nil, fmt.Errorf("invalid filter: %w", err)
    }

    alerts, err := s.repo.FindByFilter(ctx, filter)
    if err != nil {
        return nil, fmt.Errorf("failed to fetch alerts: %w", err)
    }

    return alerts, nil
}
```

### 5.4 Code Review Checklist

- [ ] No hardcoded values (use configuration)
- [ ] Proper error handling with context
- [ ] Unit tests for new code
- [ ] Integration tests for external dependencies
- [ ] No security vulnerabilities (SQL injection, etc.)
- [ ] Performance considerations addressed
- [ ] Documentation updated

---

## 6. API Development

### 6.1 REST API Design

```yaml
# OpenAPI 3.0 specification
openapi: 3.0.0
info:
  title: ACM Detection API
  version: 1.0.0

paths:
  /api/v1/fraud/events:
    post:
      summary: Submit call event
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CallEvent'
      responses:
        '200':
          description: Event processed
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/DetectionResult'
```

### 6.2 Request/Response Models

```rust
// Rust API models
#[derive(Debug, Serialize, Deserialize)]
pub struct CallEventRequest {
    pub call_id: String,
    pub a_number: String,
    pub b_number: String,
    #[serde(default = "Utc::now")]
    pub timestamp: DateTime<Utc>,
    #[serde(default)]
    pub status: String,
}

#[derive(Debug, Serialize)]
pub struct DetectionResponse {
    pub status: String,
    pub call_id: String,
    pub detection_result: DetectionResultDto,
}

#[derive(Debug, Serialize)]
pub struct DetectionResultDto {
    pub detected: bool,
    pub threat_level: String,
    pub distinct_a_numbers: usize,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub alert_id: Option<String>,
}
```

### 6.3 API Handlers

```rust
// Axum handler example
pub async fn submit_event(
    State(state): State<AppState>,
    Json(request): Json<CallEventRequest>,
) -> Result<Json<DetectionResponse>, ApiError> {
    // Validate request
    let event = CallEvent::try_from(request)?;

    // Process event
    let result = state.detection_service
        .process_event(event.clone())
        .await?;

    // Build response
    let response = DetectionResponse {
        status: "accepted".to_string(),
        call_id: event.call_id.to_string(),
        detection_result: result.into(),
    };

    Ok(Json(response))
}
```

---

## 7. Database Schema

### 7.1 YugabyteDB Schema

```sql
-- Core tables for persistent storage

CREATE TABLE fraud_alerts (
    alert_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    b_number VARCHAR(20) NOT NULL,
    a_numbers JSONB NOT NULL,
    detection_window_ms INTEGER NOT NULL,
    detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status VARCHAR(20) NOT NULL DEFAULT 'NEW',
    ncc_incident_id VARCHAR(64),
    assigned_to VARCHAR(255),
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_alerts_b_number ON fraud_alerts(b_number);
CREATE INDEX idx_alerts_detected_at ON fraud_alerts(detected_at);
CREATE INDEX idx_alerts_status ON fraud_alerts(status);

CREATE TABLE whitelist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    b_number VARCHAR(20) NOT NULL UNIQUE,
    reason VARCHAR(255) NOT NULL,
    created_by VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

CREATE INDEX idx_whitelist_b_number ON whitelist(b_number);
```

### 7.2 QuestDB Schema

```sql
-- Time-series tables for real-time analytics

CREATE TABLE call_events (
    call_id SYMBOL,
    a_number SYMBOL,
    b_number SYMBOL,
    status SYMBOL,
    source_ip SYMBOL,
    carrier_id SYMBOL,
    detection_latency_us LONG,
    fraud_detected BOOLEAN,
    timestamp TIMESTAMP
) TIMESTAMP(timestamp) PARTITION BY DAY;

CREATE TABLE detection_metrics (
    metric_name SYMBOL,
    value DOUBLE,
    labels STRING,
    timestamp TIMESTAMP
) TIMESTAMP(timestamp) PARTITION BY HOUR;
```

### 7.3 ClickHouse Schema

```sql
-- Analytics tables for historical analysis

CREATE TABLE fraud_alerts_analytics
(
    alert_id UUID,
    alert_type LowCardinality(String),
    severity LowCardinality(String),
    b_number String,
    a_number_count UInt32,
    detection_window_ms UInt32,
    detected_at DateTime,
    resolved_at Nullable(DateTime),
    resolution_time_seconds Nullable(UInt32)
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(detected_at)
ORDER BY (detected_at, alert_id);

-- Materialized view for daily statistics
CREATE MATERIALIZED VIEW daily_stats_mv
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(date)
ORDER BY (date, severity)
AS SELECT
    toDate(detected_at) AS date,
    severity,
    count() AS alert_count,
    sum(a_number_count) AS total_a_numbers
FROM fraud_alerts_analytics
GROUP BY date, severity;
```

---

## 8. Testing Guide

### 8.1 Test-Driven Development Workflow

```
1. Write failing test (Red)
       │
       ▼
2. Write minimal code to pass (Green)
       │
       ▼
3. Refactor while keeping tests green
       │
       ▼
4. Repeat
```

### 8.2 Unit Tests (Rust)

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use mockall::predicate::*;

    #[tokio::test]
    async fn test_detection_triggers_alert_when_threshold_exceeded() {
        // Arrange
        let mut mock_cache = MockCacheRepository::new();
        let mut mock_alerts = MockAlertRepository::new();

        mock_cache
            .expect_is_whitelisted()
            .returning(|_| Ok(false));

        mock_cache
            .expect_add_a_number()
            .returning(|_, _| Ok(BNumberState {
                distinct_a_numbers: 6,
                a_numbers: vec![/* ... */],
                first_seen: Timestamp::now(),
            }));

        mock_alerts
            .expect_save()
            .times(1)
            .returning(|_| Ok(()));

        let service = DetectionService::new(
            Arc::new(mock_cache),
            Arc::new(mock_alerts),
            DetectionConfig::default(),
        );

        let event = CallEvent::new(
            CallId::generate(),
            PhoneNumber::parse("+2348011111111").unwrap(),
            PhoneNumber::parse("+2348099999999").unwrap(),
        ).unwrap();

        // Act
        let result = service.process_event(event).await;

        // Assert
        assert!(matches!(result, Ok(DetectionResult::FraudDetected(_))));
    }

    #[test]
    fn test_severity_calculation() {
        assert_eq!(FraudAlert::calculate_severity(4), Severity::Low);
        assert_eq!(FraudAlert::calculate_severity(5), Severity::High);
        assert_eq!(FraudAlert::calculate_severity(7), Severity::Critical);
    }
}
```

### 8.3 Integration Tests

```rust
// tests/integration/detection_test.rs

#[tokio::test]
async fn test_full_detection_flow() {
    // Setup test database containers
    let db = TestDatabase::new().await;
    let cache = TestCache::new().await;

    let service = create_test_service(&db, &cache).await;

    // Simulate attack: 7 distinct A-numbers to same B-number
    let b_number = PhoneNumber::parse("+2348099999999").unwrap();

    for i in 1..=7 {
        let event = CallEvent::new(
            CallId::generate(),
            PhoneNumber::parse(&format!("+234801{:06}", i)).unwrap(),
            b_number.clone(),
        ).unwrap();

        let result = service.process_event(event).await.unwrap();

        if i >= 5 {
            assert!(matches!(result, DetectionResult::FraudDetected(_)));
        } else {
            assert!(matches!(result, DetectionResult::Clean));
        }
    }

    // Verify alert was persisted
    let alerts = db.get_alerts_for_b_number(&b_number).await;
    assert_eq!(alerts.len(), 1);
    assert_eq!(alerts[0].severity, Severity::Critical);
}
```

### 8.4 Performance Tests

```rust
// benches/detection_benchmark.rs

use criterion::{criterion_group, criterion_main, Criterion};

fn detection_benchmark(c: &mut Criterion) {
    let rt = tokio::runtime::Runtime::new().unwrap();
    let service = rt.block_on(create_benchmark_service());

    c.bench_function("process_event", |b| {
        b.iter(|| {
            rt.block_on(async {
                let event = create_random_event();
                service.process_event(event).await
            })
        })
    });
}

criterion_group!(benches, detection_benchmark);
criterion_main!(benches);
```

### 8.5 Running Tests

```bash
# Run all tests
cargo test

# Run with coverage
cargo tarpaulin --out Html

# Run benchmarks
cargo bench

# Run integration tests
cargo test --features integration

# Go tests
go test ./...
go test -race ./...
go test -cover ./...
```

---

## 9. CI/CD Pipeline

### 9.1 GitHub Actions Workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  rust:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Rust
        uses: dtolnay/rust-action@stable

      - name: Check formatting
        run: cargo fmt --check

      - name: Clippy
        run: cargo clippy -- -D warnings

      - name: Test
        run: cargo test --all-features

      - name: Build release
        run: cargo build --release

  go:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.21'

      - name: Test
        run: go test -race ./...

      - name: Build
        run: go build ./...

  integration:
    needs: [rust, go]
    runs-on: ubuntu-latest
    services:
      dragonfly:
        image: docker.dragonflydb.io/dragonflydb/dragonfly:latest
        ports: [6379:6379]
      yugabyte:
        image: yugabytedb/yugabyte:latest
        ports: [5433:5433]
    steps:
      - uses: actions/checkout@v4
      - name: Run integration tests
        run: cargo test --features integration
```

### 9.2 Deployment Pipeline

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build Docker images
        run: |
          docker build -t acm/detection-engine:${{ github.ref_name }} \
            -f detection-service-rust/Dockerfile .
          docker build -t acm/management-api:${{ github.ref_name }} \
            -f management-api/Dockerfile .

      - name: Push to registry
        run: |
          docker push acm/detection-engine:${{ github.ref_name }}
          docker push acm/management-api:${{ github.ref_name }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Kubernetes
        run: |
          kubectl set image deployment/acm-engine \
            acm-engine=acm/detection-engine:${{ github.ref_name }}
```

---

## 10. Performance Optimization

### 10.1 Profiling

```bash
# CPU profiling with perf
perf record -g ./target/release/acm-detection
perf report

# Memory profiling with valgrind
valgrind --tool=massif ./target/release/acm-detection

# Async profiling with tokio-console
RUSTFLAGS="--cfg tokio_unstable" cargo run
tokio-console
```

### 10.2 Optimization Techniques

```rust
// Use batch processing
pub async fn process_events_batch(
    &self,
    events: Vec<CallEvent>,
) -> Vec<DetectionResult> {
    // Process in parallel with bounded concurrency
    let results = futures::stream::iter(events)
        .map(|event| self.process_event(event))
        .buffer_unordered(100)
        .collect::<Vec<_>>()
        .await;

    results.into_iter().collect()
}

// Use connection pooling
let pool = PgPoolOptions::new()
    .max_connections(32)
    .min_connections(4)
    .acquire_timeout(Duration::from_secs(5))
    .connect(&database_url)
    .await?;
```

---

## 11. Debugging & Profiling

### 11.1 Logging

```rust
// Use structured logging
use tracing::{info, warn, error, instrument};

#[instrument(skip(self), fields(call_id = %event.call_id))]
pub async fn process_event(&self, event: CallEvent) -> Result<DetectionResult> {
    info!(b_number = %event.b_number, "Processing call event");

    // ... processing logic

    if let DetectionResult::FraudDetected(ref alert) = result {
        warn!(
            alert_id = %alert.alert_id,
            severity = ?alert.severity,
            "Fraud detected"
        );
    }

    Ok(result)
}
```

### 11.2 Debug Endpoints

```rust
// Development-only debug endpoints
#[cfg(debug_assertions)]
pub fn debug_routes() -> Router {
    Router::new()
        .route("/debug/cache", get(dump_cache))
        .route("/debug/metrics", get(internal_metrics))
        .route("/debug/config", get(show_config))
}
```

---

## 12. Contributing Guidelines

### 12.1 Branching Strategy

```
main          ─────●─────●─────●─────●─────
               │       │       │
develop       ─●───●───●───●───●───●───●───
               │   │   │   │
feature/*     ─●───●───┘   │
                           │
hotfix/*      ─────────────●───────────────
```

### 12.2 Commit Messages

```
type(scope): short description

Longer description if needed.

Fixes #123
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### 12.3 Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No new warnings
```

---

**Document Version:** 2.0
**Classification:** Internal Use Only
