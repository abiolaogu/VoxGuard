# Technical Specification
## Anti-Call Masking Detection System

**Version:** 2.0
**Last Updated:** January 2026
**Status:** Production

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Architecture](#2-architecture)
3. [Detection Algorithm](#3-detection-algorithm)
4. [API Specification](#4-api-specification)
5. [Data Models](#5-data-models)
6. [Database Schema](#6-database-schema)
7. [Performance Specifications](#7-performance-specifications)
8. [Security Specifications](#8-security-specifications)
9. [Integration Specifications](#9-integration-specifications)
10. [Deployment Specifications](#10-deployment-specifications)

---

## 1. System Overview

### 1.1 Purpose

The Anti-Call Masking Detection System (ACM) is a real-time fraud detection platform designed to identify and mitigate CLI spoofing attacks in telecommunications networks. It detects patterns where multiple distinct A-numbers (caller IDs) target the same B-number (destination) within a configurable time window.

### 1.2 Key Capabilities

| Capability | Specification |
|------------|---------------|
| Detection Latency | < 1ms (P99) |
| Throughput | 150,000+ CPS |
| Detection Accuracy | 99.8%+ |
| False Positive Rate | < 0.2% |
| Availability | 99.99% |

### 1.3 Technology Stack

| Component | Technology | Version |
|-----------|------------|---------|
| Detection Engine | Rust | 1.75+ |
| Management API | Go | 1.21+ |
| Real-time Cache | DragonflyDB | 1.14+ |
| Time-Series DB | QuestDB | 7.4+ |
| Relational DB | YugabyteDB | 2.20+ |
| Analytics DB | ClickHouse | 24.1+ |
| SIP Server | OpenSIPS | 3.4+ |
| Monitoring | Prometheus/Grafana | Latest |

---

## 2. Architecture

### 2.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      Anti-Call Masking Platform                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        External Interface                            │   │
│  │                                                                      │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐   │   │
│  │  │   OpenSIPS   │  │  REST API    │  │    WebSocket             │   │   │
│  │  │   (SIP)      │  │  (HTTP)      │  │    (Real-time)           │   │   │
│  │  │   :5060      │  │  :8080       │  │    :8080/ws              │   │   │
│  │  └──────────────┘  └──────────────┘  └──────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      Detection Engine (Rust)                         │   │
│  │                                                                      │   │
│  │  ┌────────────────┐  ┌────────────────┐  ┌────────────────────┐    │   │
│  │  │ Event Handler  │  │ Detection Core │  │  Action Executor   │    │   │
│  │  │                │  │                │  │                    │    │   │
│  │  │ - Validation   │  │ - Window Mgmt  │  │ - Disconnect       │    │   │
│  │  │ - Normalization│  │ - Threshold    │  │ - Block            │    │   │
│  │  │ - Routing      │  │ - Alert Gen    │  │ - Notify           │    │   │
│  │  └────────────────┘  └────────────────┘  └────────────────────┘    │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        Data Layer                                    │   │
│  │                                                                      │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐    │   │
│  │  │ DragonflyDB│  │  QuestDB   │  │ YugabyteDB │  │ ClickHouse │    │   │
│  │  │            │  │            │  │            │  │            │    │   │
│  │  │ Real-time  │  │ Time-series│  │ Persistent │  │ Analytics  │    │   │
│  │  │ Cache      │  │ Metrics    │  │ Storage    │  │ Warehouse  │    │   │
│  │  │ :6379      │  │ :8812,9009 │  │ :5433      │  │ :8123      │    │   │
│  │  └────────────┘  └────────────┘  └────────────┘  └────────────┘    │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                           Call Event Processing Flow                         │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────────────────────┐    │
│  │   SIP/HTTP  │────▶│   Event     │────▶│      Validation             │    │
│  │   Request   │     │   Parser    │     │  - E.164 format             │    │
│  └─────────────┘     └─────────────┘     │  - Required fields          │    │
│                                          │  - Rate limiting            │    │
│                                          └──────────────┬──────────────┘    │
│                                                         │                    │
│                                                         ▼                    │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                    DragonflyDB (Real-time State)                     │    │
│  │                                                                      │    │
│  │  Key: b_number:{b_number}                                            │    │
│  │  Value: {                                                            │    │
│  │    a_numbers: ["+234...", "+234..."],                                │    │
│  │    first_seen: timestamp,                                            │    │
│  │    last_seen: timestamp                                              │    │
│  │  }                                                                   │    │
│  │  TTL: detection_window + 1s                                          │    │
│  │                                                                      │    │
│  └──────────────────────────────┬──────────────────────────────────────┘    │
│                                 │                                            │
│                                 ▼                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                      Detection Logic                                 │    │
│  │                                                                      │    │
│  │  IF distinct_a_numbers >= threshold                                  │    │
│  │     AND window_duration <= detection_window                          │    │
│  │     AND NOT whitelisted(b_number)                                    │    │
│  │  THEN                                                                │    │
│  │     generate_alert()                                                 │    │
│  │     IF auto_disconnect THEN disconnect_calls()                       │    │
│  │                                                                      │    │
│  └──────────────────────────────┬──────────────────────────────────────┘    │
│                                 │                                            │
│                    ┌────────────┴────────────┐                              │
│                    │                         │                              │
│                    ▼                         ▼                              │
│  ┌─────────────────────────┐  ┌─────────────────────────────────────────┐  │
│  │   Alert Pipeline        │  │        Metrics Pipeline                  │  │
│  │                         │  │                                          │  │
│  │  - YugabyteDB (persist) │  │  - QuestDB (time-series)                │  │
│  │  - NCC (report)         │  │  - Prometheus (metrics)                 │  │
│  │  - Webhook (notify)     │  │  - ClickHouse (analytics)               │  │
│  │                         │  │                                          │  │
│  └─────────────────────────┘  └─────────────────────────────────────────┘  │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

### 2.3 Component Responsibilities

| Component | Responsibility | Language | Protocol |
|-----------|---------------|----------|----------|
| Detection Engine | Core fraud detection | Rust | HTTP/gRPC |
| DragonflyDB | Real-time state management | - | Redis |
| QuestDB | Time-series storage | - | ILP/SQL |
| YugabyteDB | Persistent storage | - | PostgreSQL |
| ClickHouse | Historical analytics | - | HTTP/Native |
| OpenSIPS | SIP processing | C | SIP |
| Management API | Configuration, reporting | Go | HTTP |

---

## 3. Detection Algorithm

### 3.1 Algorithm Overview

The core detection algorithm uses a sliding window approach:

```
FUNCTION process_call_event(event):
    b_number = event.b_number
    a_number = event.a_number
    timestamp = event.timestamp

    // Check whitelist
    IF is_whitelisted(b_number):
        RETURN result(status="whitelisted")

    // Get or create B-number state
    state = cache.get_or_create(b_number)

    // Add A-number to set (automatic deduplication)
    state.add_a_number(a_number, timestamp)

    // Clean expired entries
    state.expire_old_entries(detection_window)

    // Check detection threshold
    IF state.distinct_a_count >= threshold:
        IF state.window_duration <= detection_window:
            alert = create_alert(b_number, state.a_numbers)
            persist_alert(alert)

            IF auto_disconnect_enabled:
                disconnect_calls(b_number)

            RETURN result(status="fraud_detected", alert=alert)

    RETURN result(status="clean")
```

### 3.2 Detection Parameters

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `detection_threshold` | 5 | 3-20 | Minimum distinct A-numbers |
| `detection_window_seconds` | 5 | 1-30 | Time window for detection |
| `cooldown_seconds` | 60 | 30-300 | Between alerts for same B-number |
| `auto_disconnect` | true | - | Automatically disconnect calls |
| `max_a_numbers_tracked` | 100 | 50-500 | Max A-numbers per B-number |

### 3.3 Severity Calculation

```rust
fn calculate_severity(distinct_a_numbers: usize) -> Severity {
    match distinct_a_numbers {
        0..=4  => Severity::Low,
        5..=6  => Severity::High,
        _      => Severity::Critical,
    }
}
```

### 3.4 Performance Characteristics

| Metric | Target | Achieved |
|--------|--------|----------|
| Detection Latency (P50) | < 0.5ms | 0.42ms |
| Detection Latency (P99) | < 1ms | 0.85ms |
| Memory per B-number | < 1KB | ~500 bytes |
| Cache Operations | O(1) | O(1) |

---

## 4. API Specification

### 4.1 API Overview

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/api/v1/fraud/events` | POST | Submit call event |
| `/api/v1/fraud/events/batch` | POST | Batch submit events |
| `/api/v1/fraud/alerts` | GET | Query alerts |
| `/api/v1/fraud/alerts/{id}` | GET | Get alert details |
| `/api/v1/fraud/disconnect` | POST | Disconnect calls |
| `/api/v1/config` | GET/PATCH | Configuration |
| `/api/v1/whitelist` | GET/POST/DELETE | Whitelist management |

### 4.2 Event Submission

**Endpoint:** `POST /api/v1/fraud/events`

**Request:**
```json
{
  "call_id": "uuid-v4",
  "a_number": "+2348012345678",
  "b_number": "+2348098765432",
  "timestamp": "2026-01-29T10:30:00Z",
  "status": "active",
  "source_ip": "192.168.1.100",
  "carrier_id": "carrier-uuid"
}
```

**Response (200 OK):**
```json
{
  "status": "accepted",
  "call_id": "uuid-v4",
  "detection_result": {
    "detected": false,
    "threat_level": "low",
    "distinct_a_numbers": 1
  }
}
```

**Response (200 OK - Fraud Detected):**
```json
{
  "status": "accepted",
  "call_id": "uuid-v4",
  "detection_result": {
    "detected": true,
    "threat_level": "critical",
    "distinct_a_numbers": 7,
    "alert_id": "alert-uuid",
    "action": "disconnect_initiated"
  }
}
```

### 4.3 Alert Query

**Endpoint:** `GET /api/v1/fraud/alerts`

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `status` | string | Filter by status |
| `severity` | string | Filter by severity |
| `start_time` | datetime | Start of range |
| `end_time` | datetime | End of range |
| `b_number` | string | Filter by B-number |
| `limit` | int | Max results (default 100) |
| `offset` | int | Pagination offset |

**Response:**
```json
{
  "alerts": [
    {
      "alert_id": "alert-uuid",
      "alert_type": "multicall_masking",
      "severity": "critical",
      "b_number": "+2348098765432",
      "a_numbers": ["+2348011111111", "+2348022222222", ...],
      "detection_window_ms": 4200,
      "detected_at": "2026-01-29T10:30:00Z",
      "status": "new"
    }
  ],
  "pagination": {
    "total": 45,
    "limit": 100,
    "offset": 0,
    "has_more": false
  }
}
```

### 4.4 Error Responses

**Error Format:**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid phone number format",
    "details": [
      {
        "field": "a_number",
        "message": "Must be in E.164 format"
      }
    ],
    "request_id": "req-uuid"
  }
}
```

**Error Codes:**
| Code | HTTP | Description |
|------|------|-------------|
| `VALIDATION_ERROR` | 400 | Invalid request |
| `UNAUTHORIZED` | 401 | Authentication required |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `RATE_LIMITED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |

---

## 5. Data Models

### 5.1 Call Event

```typescript
interface CallEvent {
  call_id: string;           // Unique call identifier (UUID)
  a_number: string;          // Source number (E.164)
  b_number: string;          // Destination number (E.164)
  timestamp: string;         // ISO 8601 timestamp
  status: CallStatus;        // Call status
  source_ip?: string;        // Source IP address
  carrier_id?: string;       // Carrier identifier
  switch_id?: string;        // Switch identifier
  sip_method?: string;       // SIP method
}

enum CallStatus {
  RINGING = "ringing",
  ACTIVE = "active",
  COMPLETED = "completed",
  DISCONNECTED = "disconnected"
}
```

### 5.2 Fraud Alert

```typescript
interface FraudAlert {
  alert_id: string;           // Unique alert ID (UUID)
  alert_type: AlertType;      // Type of fraud
  severity: Severity;         // Alert severity
  b_number: string;           // Targeted B-number
  a_numbers: string[];        // Source A-numbers
  call_ids: string[];         // Associated call IDs
  detection_window_ms: number;// Detection window duration
  detected_at: string;        // Detection timestamp
  status: AlertStatus;        // Alert status
  source_ips?: string[];      // Source IPs
  ncc_incident_id?: string;   // NCC reference
  assigned_to?: string;       // Assigned analyst
  resolved_at?: string;       // Resolution timestamp
  resolution_notes?: string;  // Resolution notes
}

enum AlertType {
  MULTICALL_MASKING = "multicall_masking",
  WANGIRI = "wangiri",
  IRSF = "irsf"
}

enum Severity {
  LOW = "low",
  MEDIUM = "medium",
  HIGH = "high",
  CRITICAL = "critical"
}

enum AlertStatus {
  NEW = "new",
  ACKNOWLEDGED = "acknowledged",
  INVESTIGATING = "investigating",
  RESOLVED = "resolved",
  FALSE_POSITIVE = "false_positive"
}
```

### 5.3 Configuration

```typescript
interface DetectionConfig {
  detection_enabled: boolean;
  detection_threshold: number;
  detection_window_seconds: number;
  auto_disconnect: boolean;
  cooldown_seconds: number;
  max_a_numbers_tracked: number;
  ncc_reporting_enabled: boolean;
}
```

---

## 6. Database Schema

### 6.1 YugabyteDB (Persistent Storage)

```sql
-- Fraud alerts table
CREATE TABLE fraud_alerts (
    alert_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    b_number VARCHAR(20) NOT NULL,
    a_numbers JSONB NOT NULL,
    call_ids JSONB NOT NULL DEFAULT '[]',
    detection_window_ms INTEGER NOT NULL,
    detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status VARCHAR(20) NOT NULL DEFAULT 'new',
    source_ips JSONB DEFAULT '[]',
    ncc_incident_id VARCHAR(64),
    assigned_to VARCHAR(255),
    resolved_at TIMESTAMPTZ,
    resolution_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_alerts_b_number ON fraud_alerts(b_number);
CREATE INDEX idx_alerts_detected_at ON fraud_alerts(detected_at DESC);
CREATE INDEX idx_alerts_status ON fraud_alerts(status);
CREATE INDEX idx_alerts_severity ON fraud_alerts(severity);

-- Whitelist table
CREATE TABLE whitelist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    b_number VARCHAR(20) NOT NULL UNIQUE,
    reason VARCHAR(255) NOT NULL,
    created_by VARCHAR(255) NOT NULL,
    approved_by VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_whitelist_b_number ON whitelist(b_number) WHERE is_active = TRUE;

-- Blocked patterns table
CREATE TABLE blocked_patterns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pattern VARCHAR(50) NOT NULL,
    pattern_type VARCHAR(20) NOT NULL, -- 'prefix', 'exact', 'regex'
    reason VARCHAR(255) NOT NULL,
    created_by VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE
);

-- Audit log
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    user_id VARCHAR(255) NOT NULL,
    action VARCHAR(50) NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    resource_id VARCHAR(255),
    old_value JSONB,
    new_value JSONB,
    ip_address INET
);

CREATE INDEX idx_audit_timestamp ON audit_log(timestamp DESC);
CREATE INDEX idx_audit_user ON audit_log(user_id, timestamp DESC);
```

### 6.2 QuestDB (Time-Series)

```sql
-- Call events time-series
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

-- Detection metrics time-series
CREATE TABLE detection_metrics (
    metric_name SYMBOL,
    value DOUBLE,
    labels STRING,
    timestamp TIMESTAMP
) TIMESTAMP(timestamp) PARTITION BY HOUR;

-- System metrics
CREATE TABLE system_metrics (
    service SYMBOL,
    metric SYMBOL,
    value DOUBLE,
    timestamp TIMESTAMP
) TIMESTAMP(timestamp) PARTITION BY HOUR;
```

### 6.3 ClickHouse (Analytics)

```sql
-- Historical alerts for analytics
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
    resolution_time_seconds Nullable(UInt32),
    was_false_positive UInt8
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(detected_at)
ORDER BY (detected_at, alert_id);

-- Daily statistics materialized view
CREATE MATERIALIZED VIEW daily_stats_mv
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(date)
ORDER BY (date, severity)
AS SELECT
    toDate(detected_at) AS date,
    severity,
    count() AS alert_count,
    sum(a_number_count) AS total_a_numbers,
    avg(detection_window_ms) AS avg_window_ms
FROM fraud_alerts_analytics
GROUP BY date, severity;

-- Hourly traffic statistics
CREATE MATERIALIZED VIEW hourly_traffic_mv
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(hour)
ORDER BY hour
AS SELECT
    toStartOfHour(timestamp) AS hour,
    count() AS call_count,
    uniq(b_number) AS unique_b_numbers,
    sum(fraud_detected) AS fraud_count
FROM call_events_ch
GROUP BY hour;
```

### 6.4 DragonflyDB (Cache Structure)

```
# B-number state
Key: b_number:{b_number}
Type: Hash
Fields:
  - a_numbers: JSON array of A-numbers with timestamps
  - first_seen: Timestamp of first call
  - last_seen: Timestamp of last call
  - alert_generated: Boolean flag
TTL: detection_window + 1 second

# Whitelist cache
Key: whitelist:{b_number}
Type: String
Value: "1" (exists = whitelisted)
TTL: None (synced from database)

# Rate limiting
Key: ratelimit:{client_ip}
Type: String
Value: Request count
TTL: 1 second

# Configuration cache
Key: config:detection
Type: Hash
Fields: All configuration parameters
TTL: 60 seconds (refreshed)
```

---

## 7. Performance Specifications

### 7.1 Throughput Requirements

| Metric | Requirement | Achieved |
|--------|-------------|----------|
| Peak CPS | 150,000 | 178,000 |
| Sustained CPS | 100,000 | 150,000 |
| Batch Processing | 10,000/batch | 15,000/batch |
| Concurrent Connections | 10,000 | 15,000 |

### 7.2 Latency Requirements

| Operation | P50 | P95 | P99 | Max |
|-----------|-----|-----|-----|-----|
| Event Processing | 0.42ms | 0.65ms | 0.85ms | 5ms |
| Cache Lookup | 0.05ms | 0.08ms | 0.12ms | 1ms |
| Alert Persistence | 2ms | 5ms | 10ms | 50ms |
| API Response | 1ms | 3ms | 5ms | 20ms |

### 7.3 Memory Requirements

| Component | Minimum | Recommended | Maximum |
|-----------|---------|-------------|---------|
| Detection Engine | 2 GB | 4 GB | 8 GB |
| DragonflyDB | 4 GB | 8 GB | 16 GB |
| QuestDB | 4 GB | 8 GB | 16 GB |
| YugabyteDB | 4 GB | 8 GB | 16 GB |
| ClickHouse | 4 GB | 8 GB | 16 GB |

### 7.4 Storage Requirements

| Data Type | Growth Rate | Retention | Storage/Month |
|-----------|-------------|-----------|---------------|
| Call Events | 150K/sec | 30 days | ~500 GB |
| Alerts | ~1000/day | 7 years | ~10 GB/year |
| Metrics | 100K/min | 30 days | ~50 GB |
| Audit Logs | 10K/day | 5 years | ~5 GB/year |

---

## 8. Security Specifications

### 8.1 Authentication

| Method | Use Case |
|--------|----------|
| API Key | Service-to-service |
| JWT (OAuth 2.0) | User authentication |
| mTLS | Internal service mesh |

### 8.2 Authorization

| Role | Permissions |
|------|-------------|
| viewer | Read alerts, dashboards |
| operator | + Acknowledge alerts |
| analyst | + Whitelist, investigate |
| supervisor | + Configuration |
| admin | Full access |

### 8.3 Encryption

| Data | At Rest | In Transit |
|------|---------|------------|
| PII (phone numbers) | AES-256 | TLS 1.3 |
| Database | AES-256 | TLS 1.3 |
| Backups | AES-256 | TLS 1.3 |
| API Keys | AES-256 | TLS 1.3 |

### 8.4 Network Security

- All internal traffic encrypted (mTLS)
- WAF for external API endpoints
- DDoS protection at edge
- Network segmentation (VLANs)
- Firewall rules for each component

---

## 9. Integration Specifications

### 9.1 SIP Integration (OpenSIPS)

```
# OpenSIPS to ACM Detection Engine
Protocol: HTTP POST
Endpoint: /api/v1/fraud/events
Format: JSON
Timeout: 100ms
Retry: 1
Async: Recommended

# ACM to OpenSIPS (Disconnect)
Protocol: MI (Management Interface)
Endpoint: /mi/dlg_end_dlg
Method: HTTP POST
```

### 9.2 NCC Integration

| System | Protocol | Frequency |
|--------|----------|-----------|
| ATRS API | HTTPS REST | Real-time |
| SFTP | SFTP/SSH | Daily |
| Portal | HTTPS | Manual |

### 9.3 Monitoring Integration

```yaml
# Prometheus scrape config
- job_name: 'acm-detection-engine'
  scrape_interval: 5s
  static_configs:
    - targets: ['acm-engine:9090']
  metrics_path: /metrics
```

### 9.4 Alerting Integration

| Channel | Integration |
|---------|-------------|
| PagerDuty | Webhook |
| Slack | Webhook |
| Email | SMTP |
| SMS | API (Twilio/Termii) |

---

## 10. Deployment Specifications

### 10.1 Container Specifications

```yaml
# Detection Engine
acm-engine:
  image: acm/detection-engine:2.0
  resources:
    requests:
      cpu: 2
      memory: 2Gi
    limits:
      cpu: 4
      memory: 4Gi
  replicas: 2-10 (HPA)

# DragonflyDB
dragonfly:
  image: docker.dragonflydb.io/dragonflydb/dragonfly:v1.14
  resources:
    limits:
      memory: 8Gi
  args:
    - --maxmemory=6gb
    - --proactor_threads=4
```

### 10.2 Kubernetes Resources

| Resource | Specification |
|----------|---------------|
| Namespace | fraud-detection |
| Service Account | acm-service-account |
| ConfigMap | acm-config |
| Secret | acm-secrets |
| HPA | acm-engine-hpa |
| PDB | acm-engine-pdb |

### 10.3 Health Checks

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

---

## Appendix A: Phone Number Formats

| Format | Example | Validation |
|--------|---------|------------|
| E.164 | +2348012345678 | Required |
| Local | 08012345678 | Converted |
| International | 2348012345678 | Converted |

---

**Document Version:** 2.0
**Classification:** Technical
**Review Cycle:** Quarterly
