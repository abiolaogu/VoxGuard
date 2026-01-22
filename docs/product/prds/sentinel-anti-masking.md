# Product Requirements Document: Sentinel Anti-Call Masking Engine

## 1. Executive Summary

**Project Name:** Sentinel
**Version:** 1.0.0
**Status:** Approved for Development
**Owner:** BillyRonks Global

### Vision
Sentinel is a high-performance batch processing and analysis engine designed to detect SIM Box fraud (CLI Spoofing) through comprehensive analysis of Call Detail Records (CDR) and historical patterns. It complements the existing real-time SIP signaling analysis by providing deep historical insights and pattern-based fraud detection.

### Problem Statement
Telecommunications fraud through SIM Box operations and CLI spoofing costs the industry billions annually. While real-time detection catches active attacks, sophisticated fraudsters evade detection through:
- Low-and-slow attack patterns spread over time
- Geographic arbitrage using multiple prefixes
- Behavioral mimicry that appears legitimate in isolation

**Sentinel addresses these challenges through:**
1. Batch processing of historical CDR data
2. Multi-dimensional pattern analysis
3. Integration with existing real-time detection infrastructure

---

## 2. Architecture & Tech Stack

### Integration with Existing Stack

Sentinel leverages our Python-based infrastructure:

```
┌─────────────────────────────────────────────────┐
│           Existing Infrastructure                │
├─────────────────────────────────────────────────┤
│ • sip-processor/     (Real-time FastAPI)        │
│ • lumadb/            (PostgreSQL/YugabyteDB)    │
│ • analytics/         (Detection algorithms)      │
│ • verification/      (STIR/SHAKEN)              │
└─────────────────────────────────────────────────┘
                       ↕
┌─────────────────────────────────────────────────┐
│            NEW: Sentinel Engine                  │
├─────────────────────────────────────────────────┤
│ • CDR Batch Ingestion                           │
│ • Historical Pattern Analysis                    │
│ • Rule Engine (Short Duration High Frequency)   │
│ • Alert Generation & Storage                     │
└─────────────────────────────────────────────────┘
```

### Technology Choices

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| **Data Processing** | Polars + Pandas | High-performance dataframe operations for large CDR datasets |
| **API Framework** | FastAPI | Consistency with existing sip-processor, async support |
| **Database** | PostgreSQL via lumadb | Leverage existing DB abstraction layer |
| **Job Scheduling** | APScheduler | Python-native, lightweight task scheduling |
| **CSV Parsing** | Python csv + Polars | Native performance for standard CDR formats |
| **Pattern Detection** | Custom Python rules + NumPy | Fast vectorized operations on call patterns |

---

## 3. Data Architecture

### 3.1 Input Schema: CDR CSV Format

```csv
call_date,call_time,caller_number,callee_number,duration_seconds,call_direction,termination_cause
2024-01-15,14:32:15,+2348012345678,+2349087654321,125,outbound,NORMAL_CLEARING
2024-01-15,14:35:42,+2348012345678,+2349076543210,2,outbound,NORMAL_CLEARING
```

**Required Fields:**
- `call_date` (YYYY-MM-DD)
- `call_time` (HH:MM:SS)
- `caller_number` (E.164 format)
- `callee_number` (E.164 format)
- `duration_seconds` (integer)

**Optional Fields:**
- `call_direction` (inbound/outbound)
- `termination_cause`
- `location_code`

### 3.2 Database Schema

#### Table: `call_records`
```sql
CREATE TABLE call_records (
    id SERIAL PRIMARY KEY,
    call_timestamp TIMESTAMP NOT NULL,
    caller_number VARCHAR(20) NOT NULL,
    callee_number VARCHAR(20) NOT NULL,
    duration_seconds INTEGER NOT NULL,
    call_direction VARCHAR(10),
    termination_cause VARCHAR(50),
    location_code VARCHAR(10),
    processed_at TIMESTAMP DEFAULT NOW(),
    INDEX idx_caller_timestamp (caller_number, call_timestamp),
    INDEX idx_callee (callee_number),
    INDEX idx_timestamp (call_timestamp)
);
```

#### Table: `suspicious_patterns`
```sql
CREATE TABLE suspicious_patterns (
    id SERIAL PRIMARY KEY,
    pattern_type VARCHAR(50) NOT NULL,
    suspect_number VARCHAR(20) NOT NULL,
    detection_timestamp TIMESTAMP DEFAULT NOW(),
    confidence_score FLOAT NOT NULL,
    metadata JSONB,
    INDEX idx_suspect_number (suspect_number),
    INDEX idx_pattern_type (pattern_type),
    INDEX idx_timestamp (detection_timestamp)
);
```

#### Table: `sentinel_fraud_alerts`
```sql
CREATE TABLE sentinel_fraud_alerts (
    id SERIAL PRIMARY KEY,
    alert_type VARCHAR(50) NOT NULL,
    suspect_number VARCHAR(20) NOT NULL,
    alert_severity VARCHAR(20) NOT NULL, -- LOW, MEDIUM, HIGH, CRITICAL
    evidence_summary TEXT NOT NULL,
    call_count INTEGER,
    unique_destinations INTEGER,
    avg_duration_seconds FLOAT,
    detection_rule VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    reviewed BOOLEAN DEFAULT FALSE,
    reviewer_notes TEXT,
    INDEX idx_suspect (suspect_number),
    INDEX idx_severity (alert_severity),
    INDEX idx_created (created_at),
    INDEX idx_reviewed (reviewed)
);
```

---

## 4. Core Features

### 4.1 CDR Ingestion Pipeline

**Capability:** Parse and ingest standard CDR CSV files into the database.

**Requirements:**
- Support files up to 1M records
- Validate E.164 phone number format
- Handle missing optional fields gracefully
- Deduplicate records based on (caller, callee, timestamp)
- Batch insert for performance (1000 records/batch)

**API Endpoint:**
```
POST /api/v1/sentinel/ingest
Content-Type: multipart/form-data

Request Body: cdr_file (CSV file)
Response: {
  "status": "success",
  "records_processed": 45000,
  "records_inserted": 44998,
  "duplicates_skipped": 2,
  "processing_time_seconds": 12.3
}
```

### 4.2 Pattern Detection: Short Duration High Frequency (SDHF)

**Rule Definition:** Flag numbers making > 50 calls to unique destinations within 24 hours where average call duration < 3 seconds.

**Detection Logic:**
```python
# Pseudo-code
for caller in recent_callers:
    calls_24h = get_calls_last_24h(caller)
    unique_destinations = count_unique(calls_24h.callee_number)
    avg_duration = mean(calls_24h.duration_seconds)

    if unique_destinations > 50 and avg_duration < 3:
        create_alert(
            type="SDHF_SIMBOX",
            suspect=caller,
            severity="HIGH",
            evidence={
                "call_count": len(calls_24h),
                "unique_destinations": unique_destinations,
                "avg_duration": avg_duration
            }
        )
```

**API Endpoint:**
```
POST /api/v1/sentinel/detect/sdhf
Request Body: {
  "time_window_hours": 24,
  "min_unique_destinations": 50,
  "max_avg_duration_seconds": 3
}

Response: {
  "alerts_generated": 3,
  "suspects": ["+2348012345678", "+2349087654321", "+2347065432109"]
}
```

### 4.3 Real-Time Event Receiver

**Capability:** Accept real-time call events from external systems for immediate analysis.

**API Endpoint:**
```
POST /api/v1/sentinel/events/call
Content-Type: application/json

Request Body: {
  "caller_number": "+2348012345678",
  "callee_number": "+2349087654321",
  "duration_seconds": 2,
  "call_direction": "outbound",
  "timestamp": "2024-01-15T14:32:15Z"
}

Response: {
  "status": "accepted",
  "event_id": "evt_abc123",
  "risk_score": 0.73
}
```

### 4.4 Alert Management API

**List Alerts:**
```
GET /api/v1/sentinel/alerts?severity=HIGH&reviewed=false&limit=50
```

**Mark as Reviewed:**
```
PATCH /api/v1/sentinel/alerts/{alert_id}
Request Body: {
  "reviewed": true,
  "reviewer_notes": "False positive - corporate call center"
}
```

---

## 5. Non-Functional Requirements

### Performance
- Ingest 100K CDR records in < 30 seconds
- SDHF detection scan completes in < 60 seconds for 1M records
- API response time < 500ms (p95)

### Scalability
- Handle databases with 50M+ call records
- Support concurrent API requests (min 10 requests/sec)

### Reliability
- Database transaction rollback on ingestion errors
- Graceful handling of malformed CSV files
- Comprehensive error logging

### Security
- API authentication via JWT tokens
- Rate limiting: 100 requests/minute per API key
- SQL injection prevention (parameterized queries)

---

## 6. Integration Points

### With Existing Systems

1. **lumadb Integration**
   - Use existing `lumadb.database` module for all DB operations
   - Follow established connection pooling patterns
   - Reuse existing migration framework

2. **sip-processor Coordination**
   - Sentinel focuses on batch/historical analysis
   - sip-processor handles real-time signaling
   - Cross-reference alerts via shared `fraud_alerts` table

3. **Frontend Dashboard**
   - Expose RESTful APIs for alert visualization
   - Provide WebSocket stream for real-time alert notifications

### External Systems

- **Ingestion Sources:** FTP/SFTP servers, S3 buckets, direct API uploads
- **Alert Destinations:** Email (SMTP), Slack webhooks, PagerDuty

---

## 7. Development Phases

### Phase 1: Foundation (Sprint 1)
- [x] PRD Creation (this document)
- [ ] Database migration files
- [ ] Basic CDR ingestion endpoint
- [ ] Unit tests for parser

### Phase 2: Detection Engine (Sprint 2)
- [ ] SDHF rule implementation
- [ ] Alert generation logic
- [ ] Integration with lumadb
- [ ] Mock data generator (5K records)

### Phase 3: API & Integration (Sprint 3)
- [ ] Real-time event receiver
- [ ] Alert management endpoints
- [ ] Frontend API integration
- [ ] End-to-end testing

### Phase 4: Production Hardening (Sprint 4)
- [ ] Performance optimization
- [ ] Production deployment configs
- [ ] Monitoring & alerting setup
- [ ] Documentation

---

## 8. Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Detection Accuracy | > 90% true positive rate | Manual review of 100 alerts/week |
| False Positive Rate | < 10% | Alert review feedback |
| Processing Throughput | 100K records in < 30s | Automated benchmark tests |
| API Uptime | 99.9% | Prometheus monitoring |
| Alert Response Time | < 5 minutes from detection | Alert timestamp vs creation time |

---

## 9. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Large CSV files cause memory issues | HIGH | Stream processing with chunked reads (10K rows/chunk) |
| Database growth impacts query performance | MEDIUM | Implement data retention policy (archive > 90 days) |
| False positives overwhelm analysts | HIGH | Implement confidence scoring, ML-based filtering in v2 |
| Integration conflicts with sip-processor | MEDIUM | Clear API boundaries, shared DB schema reviews |

---

## 10. Future Enhancements (v2.0)

1. **Machine Learning Models**
   - Replace rule-based detection with XGBoost classifier
   - Training pipeline using labeled historical data

2. **Geographic Analysis**
   - Detect prefix-based routing anomalies
   - International call pattern analysis

3. **Behavioral Profiling**
   - Build caller "fingerprints" over time
   - Detect sudden behavioral changes

4. **Distributed Processing**
   - Apache Spark/Dask for multi-TB datasets
   - Horizontal scaling across worker nodes

---

## Appendix A: Sample Detection Rules

### Rule 1: SDHF (Short Duration High Frequency)
```python
{
  "rule_id": "SDHF_001",
  "name": "SIM Box Detection",
  "threshold": {
    "time_window": "24h",
    "min_calls": 50,
    "max_avg_duration": 3,
    "unique_destinations": true
  },
  "severity": "HIGH"
}
```

### Rule 2: Geographic Anomaly
```python
{
  "rule_id": "GEO_001",
  "name": "Cross-Border Abuse",
  "threshold": {
    "min_international_calls": 100,
    "time_window": "1h",
    "suspicious_prefixes": ["+1", "+44", "+971"]
  },
  "severity": "MEDIUM"
}
```

---

**Document Control:**
- Created: 2026-01-22
- Last Updated: 2026-01-22
- Version: 1.0.0
- Status: APPROVED
- Next Review: 2026-02-22
