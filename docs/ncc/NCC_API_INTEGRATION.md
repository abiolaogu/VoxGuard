# NCC API Integration Guide
## ATRS (Automated Trouble Reporting System) Integration

**Version:** 1.0
**Last Updated:** January 2026
**API Version:** ATRS v2.1

---

## Table of Contents

1. [Overview](#1-overview)
2. [Authentication](#2-authentication)
3. [API Endpoints](#3-api-endpoints)
4. [Data Models](#4-data-models)
5. [Integration Workflows](#5-integration-workflows)
6. [Error Handling](#6-error-handling)
7. [Rate Limiting](#7-rate-limiting)
8. [Security Requirements](#8-security-requirements)
9. [Testing & Certification](#9-testing--certification)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Overview

### 1.1 Purpose

This document describes the integration between the Anti-Call Masking Detection System and the NCC's Automated Trouble Reporting System (ATRS). The ATRS serves as the central platform for:

- Fraud incident reporting
- Real-time alert sharing
- Compliance data submission
- Cross-operator coordination

### 1.2 Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Anti-Call Masking Platform                      │
│                                                                     │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────────┐  │
│  │  Detection  │───▶│   NCC       │───▶│  ATRS API Client       │  │
│  │   Engine    │    │  Adapter    │    │  (ncc-integration)     │  │
│  └─────────────┘    └─────────────┘    └───────────┬─────────────┘  │
│                                                     │               │
└─────────────────────────────────────────────────────┼───────────────┘
                                                      │
                                                      │ HTTPS/TLS 1.3
                                                      │
                    ┌─────────────────────────────────▼───────────────┐
                    │                                                 │
                    │           NCC ATRS Platform                     │
                    │           https://atrs-api.ncc.gov.ng           │
                    │                                                 │
                    │  ┌─────────────┐  ┌─────────────┐  ┌─────────┐  │
                    │  │   Fraud     │  │  Compliance │  │ Cross-  │  │
                    │  │  Reporting  │  │   Portal    │  │ Operator│  │
                    │  └─────────────┘  └─────────────┘  └─────────┘  │
                    │                                                 │
                    └─────────────────────────────────────────────────┘
```

### 1.3 Integration Types

| Type | Description | Frequency |
|------|-------------|-----------|
| Real-time | Immediate fraud alerts | Per incident |
| Batch | Daily/monthly reports | Scheduled |
| Query | Status checks, lookups | On demand |
| Webhook | NCC notifications | Event-driven |

---

## 2. Authentication

### 2.1 OAuth 2.0 Client Credentials Flow

The ATRS uses OAuth 2.0 for authentication with client credentials grant.

```
┌─────────────┐                              ┌─────────────┐
│  ACM Client │                              │  ATRS Auth  │
└──────┬──────┘                              └──────┬──────┘
       │                                            │
       │  POST /oauth/token                         │
       │  + client_id                               │
       │  + client_secret                           │
       │  + grant_type=client_credentials           │
       │─────────────────────────────────────────▶  │
       │                                            │
       │  {                                         │
       │    "access_token": "...",                  │
       │    "token_type": "Bearer",                 │
       │    "expires_in": 3600                      │
       │  }                                         │
       │◀─────────────────────────────────────────  │
       │                                            │
```

### 2.2 Token Request

```bash
curl -X POST https://atrs-api.ncc.gov.ng/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=${NCC_CLIENT_ID}" \
  -d "client_secret=${NCC_CLIENT_SECRET}" \
  -d "scope=fraud:write fraud:read compliance:write"
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "fraud:write fraud:read compliance:write"
}
```

### 2.3 Token Scopes

| Scope | Description | Required For |
|-------|-------------|--------------|
| `fraud:write` | Submit fraud reports | Real-time alerts |
| `fraud:read` | Query fraud data | Lookups |
| `compliance:write` | Submit compliance reports | Daily/monthly reports |
| `compliance:read` | Query compliance status | Status checks |
| `operator:query` | Cross-operator queries | Coordinated response |

### 2.4 Token Management

```rust
// Rust implementation example
pub struct AtrsClient {
    client_id: String,
    client_secret: String,
    token: Option<AccessToken>,
    token_expiry: Option<Instant>,
}

impl AtrsClient {
    pub async fn ensure_token(&mut self) -> Result<&str> {
        if self.is_token_expired() {
            self.refresh_token().await?;
        }
        Ok(self.token.as_ref().unwrap().as_str())
    }

    fn is_token_expired(&self) -> bool {
        match self.token_expiry {
            Some(expiry) => Instant::now() > expiry - Duration::from_secs(60),
            None => true,
        }
    }
}
```

### 2.5 Credential Storage

Credentials MUST be stored securely:

```yaml
# Kubernetes Secret
apiVersion: v1
kind: Secret
metadata:
  name: ncc-credentials
type: Opaque
data:
  client-id: <base64-encoded>
  client-secret: <base64-encoded>
  icl-license: <base64-encoded>
```

---

## 3. API Endpoints

### 3.1 Base URL

| Environment | URL |
|-------------|-----|
| Production | `https://atrs-api.ncc.gov.ng/v2` |
| Sandbox | `https://atrs-sandbox.ncc.gov.ng/v2` |

### 3.2 Fraud Reporting Endpoints

#### POST /fraud/incidents

Submit a fraud incident (real-time alert).

**Request:**
```bash
curl -X POST https://atrs-api.ncc.gov.ng/v2/fraud/incidents \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "X-ICL-License: ${NCC_ICL_LICENSE}" \
  -H "X-Request-ID: $(uuidgen)" \
  -d '{
    "incident_type": "CLI_SPOOFING",
    "severity": "CRITICAL",
    "detected_at": "2026-01-29T10:30:00Z",
    "b_number": "+2348012345678",
    "a_numbers": [
      "+2347011111111",
      "+2347022222222",
      "+2347033333333",
      "+2347044444444",
      "+2347055555555"
    ],
    "detection_window_ms": 4200,
    "source_ips": ["192.168.1.100", "192.168.1.101"],
    "actions_taken": ["ALERT_GENERATED", "CALLS_DISCONNECTED"],
    "metadata": {
      "detection_engine_version": "2.0.0",
      "confidence_score": 0.98
    }
  }'
```

**Response (201 Created):**
```json
{
  "incident_id": "NCC-2026-01-0001234",
  "status": "RECEIVED",
  "acknowledgment_time": "2026-01-29T10:30:01Z",
  "assigned_analyst": null,
  "next_action": "PENDING_REVIEW"
}
```

#### GET /fraud/incidents/{incident_id}

Query incident status.

**Request:**
```bash
curl -X GET https://atrs-api.ncc.gov.ng/v2/fraud/incidents/NCC-2026-01-0001234 \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

**Response:**
```json
{
  "incident_id": "NCC-2026-01-0001234",
  "incident_type": "CLI_SPOOFING",
  "severity": "CRITICAL",
  "status": "INVESTIGATING",
  "detected_at": "2026-01-29T10:30:00Z",
  "acknowledged_at": "2026-01-29T10:30:01Z",
  "assigned_analyst": "analyst@ncc.gov.ng",
  "updates": [
    {
      "timestamp": "2026-01-29T10:45:00Z",
      "action": "CROSS_OPERATOR_QUERY",
      "notes": "Requested source operator information"
    }
  ]
}
```

#### GET /fraud/incidents

List incidents with filtering.

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `start_date` | datetime | Filter start |
| `end_date` | datetime | Filter end |
| `status` | string | RECEIVED, INVESTIGATING, RESOLVED |
| `severity` | string | CRITICAL, HIGH, MEDIUM, LOW |
| `page` | int | Page number |
| `per_page` | int | Results per page (max 100) |

### 3.3 Compliance Reporting Endpoints

#### POST /compliance/reports/daily

Submit daily compliance report.

**Request:**
```bash
curl -X POST https://atrs-api.ncc.gov.ng/v2/compliance/reports/daily \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "report_date": "2026-01-28",
    "icl_license": "${NCC_ICL_LICENSE}",
    "statistics": {
      "total_calls_processed": 12500000,
      "fraud_alerts_generated": 45,
      "alerts_by_severity": {
        "critical": 5,
        "high": 12,
        "medium": 18,
        "low": 10
      },
      "calls_disconnected": 23,
      "detection_latency_p99_ms": 0.8,
      "system_uptime_percent": 99.998
    },
    "top_targeted_numbers": [
      {"b_number": "+234801234567", "incident_count": 5},
      {"b_number": "+234802345678", "incident_count": 3}
    ],
    "checksum": "sha256:abc123..."
  }'
```

**Response (202 Accepted):**
```json
{
  "report_id": "RPT-2026-01-28-001234",
  "status": "PROCESSING",
  "validation_status": "PENDING"
}
```

#### POST /compliance/reports/monthly

Submit monthly compliance report.

**Request:**
```json
{
  "report_month": "2026-01",
  "icl_license": "${NCC_ICL_LICENSE}",
  "executive_summary": "...",
  "statistics": {
    "total_calls_processed": 387500000,
    "fraud_alerts_generated": 1247,
    "estimated_fraud_prevented_ngn": 45000000,
    "average_detection_latency_ms": 0.75,
    "average_uptime_percent": 99.995
  },
  "trend_analysis": {
    "month_over_month_change": -5.2,
    "new_patterns_identified": 2,
    "false_positive_rate": 0.18
  },
  "attachments": [
    {
      "name": "detailed_statistics.csv",
      "content_type": "text/csv",
      "data_base64": "..."
    }
  ]
}
```

### 3.4 Cross-Operator Query Endpoints

#### POST /operators/query

Query other operators about suspicious traffic.

**Request:**
```json
{
  "query_type": "SOURCE_IDENTIFICATION",
  "target_operator_code": "MTN-NG",
  "a_numbers": ["+2347011111111", "+2347022222222"],
  "incident_reference": "NCC-2026-01-0001234",
  "justification": "Suspected CLI spoofing attack"
}
```

**Response:**
```json
{
  "query_id": "QRY-2026-0001234",
  "status": "PENDING",
  "expected_response_time": "2026-01-29T14:30:00Z"
}
```

### 3.5 Webhook Registration

#### POST /webhooks

Register for NCC notifications.

**Request:**
```json
{
  "endpoint_url": "https://acm.example.com/ncc/webhook",
  "events": [
    "incident.status_changed",
    "compliance.report_validated",
    "operator.query_response",
    "alert.new_pattern"
  ],
  "secret": "webhook_signing_secret"
}
```

---

## 4. Data Models

### 4.1 Incident Types

```typescript
enum IncidentType {
  CLI_SPOOFING = "CLI_SPOOFING",
  WANGIRI = "WANGIRI",
  IRSF = "IRSF",
  REVENUE_FRAUD = "REVENUE_FRAUD",
  SIM_BOX = "SIM_BOX",
  OTHER = "OTHER"
}
```

### 4.2 Severity Levels

```typescript
enum Severity {
  CRITICAL = "CRITICAL",  // Immediate attention required
  HIGH = "HIGH",          // Response within 4 hours
  MEDIUM = "MEDIUM",      // Response within 24 hours
  LOW = "LOW"             // Informational
}
```

### 4.3 Incident Status

```typescript
enum IncidentStatus {
  RECEIVED = "RECEIVED",
  ACKNOWLEDGED = "ACKNOWLEDGED",
  INVESTIGATING = "INVESTIGATING",
  CROSS_OPERATOR = "CROSS_OPERATOR",
  RESOLVED = "RESOLVED",
  CLOSED = "CLOSED"
}
```

### 4.4 Full Incident Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "FraudIncident",
  "type": "object",
  "required": ["incident_type", "severity", "detected_at", "b_number", "a_numbers"],
  "properties": {
    "incident_type": {
      "type": "string",
      "enum": ["CLI_SPOOFING", "WANGIRI", "IRSF", "REVENUE_FRAUD", "SIM_BOX", "OTHER"]
    },
    "severity": {
      "type": "string",
      "enum": ["CRITICAL", "HIGH", "MEDIUM", "LOW"]
    },
    "detected_at": {
      "type": "string",
      "format": "date-time"
    },
    "b_number": {
      "type": "string",
      "pattern": "^\\+[0-9]{10,15}$"
    },
    "a_numbers": {
      "type": "array",
      "items": {
        "type": "string",
        "pattern": "^\\+[0-9]{10,15}$"
      },
      "minItems": 1,
      "maxItems": 100
    },
    "detection_window_ms": {
      "type": "integer",
      "minimum": 0
    },
    "source_ips": {
      "type": "array",
      "items": {
        "type": "string",
        "format": "ipv4"
      }
    },
    "actions_taken": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": ["ALERT_GENERATED", "CALLS_DISCONNECTED", "PATTERN_BLOCKED", "OPERATOR_NOTIFIED"]
      }
    },
    "metadata": {
      "type": "object",
      "additionalProperties": true
    }
  }
}
```

---

## 5. Integration Workflows

### 5.1 Real-Time Incident Reporting

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Detection     │     │   NCC Adapter   │     │   ATRS API      │
│    Engine       │     │                 │     │                 │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         │  Fraud Detected       │                       │
         │──────────────────────▶│                       │
         │                       │                       │
         │                       │  Validate & Enrich    │
         │                       │◀──────────────────────│
         │                       │                       │
         │                       │  POST /fraud/incidents│
         │                       │──────────────────────▶│
         │                       │                       │
         │                       │  201 Created          │
         │                       │◀──────────────────────│
         │                       │                       │
         │  Incident ID          │                       │
         │◀──────────────────────│                       │
         │                       │                       │
```

### 5.2 Batch Report Submission

```python
# Daily report workflow
async def submit_daily_report(report_date: date):
    # 1. Gather statistics from databases
    stats = await gather_daily_statistics(report_date)

    # 2. Generate report payload
    report = DailyReport(
        report_date=report_date,
        statistics=stats,
        top_targeted=await get_top_targets(report_date),
        checksum=calculate_checksum(stats)
    )

    # 3. Submit to ATRS
    response = await atrs_client.submit_daily_report(report)

    # 4. Store submission record
    await store_submission_record(response)

    # 5. Handle validation response (async via webhook)
    return response.report_id
```

### 5.3 Webhook Processing

```rust
#[post("/ncc/webhook")]
async fn handle_ncc_webhook(
    payload: web::Json<WebhookPayload>,
    signature: web::Header<XWebhookSignature>,
) -> impl Responder {
    // 1. Verify signature
    if !verify_signature(&payload, &signature, &WEBHOOK_SECRET) {
        return HttpResponse::Unauthorized();
    }

    // 2. Process event
    match payload.event_type.as_str() {
        "incident.status_changed" => {
            handle_incident_update(&payload.data).await;
        }
        "compliance.report_validated" => {
            handle_report_validation(&payload.data).await;
        }
        "operator.query_response" => {
            handle_operator_response(&payload.data).await;
        }
        _ => log::warn!("Unknown event type: {}", payload.event_type),
    }

    HttpResponse::Ok()
}
```

---

## 6. Error Handling

### 6.1 Error Response Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid phone number format",
    "details": [
      {
        "field": "a_numbers[2]",
        "message": "Must be in E.164 format"
      }
    ],
    "request_id": "req-uuid-12345",
    "timestamp": "2026-01-29T10:30:00Z"
  }
}
```

### 6.2 Error Codes

| Code | HTTP Status | Description | Action |
|------|-------------|-------------|--------|
| `UNAUTHORIZED` | 401 | Invalid/expired token | Refresh token |
| `FORBIDDEN` | 403 | Insufficient scope | Check permissions |
| `VALIDATION_ERROR` | 400 | Invalid request data | Fix and retry |
| `RATE_LIMITED` | 429 | Too many requests | Backoff and retry |
| `DUPLICATE` | 409 | Duplicate incident | Use existing ID |
| `NOT_FOUND` | 404 | Resource not found | Verify ID |
| `SERVER_ERROR` | 500 | ATRS internal error | Retry with backoff |
| `MAINTENANCE` | 503 | Scheduled maintenance | Wait and retry |

### 6.3 Retry Strategy

```rust
async fn submit_with_retry<T>(
    operation: impl Fn() -> Future<Output = Result<T>>,
    max_retries: u32,
) -> Result<T> {
    let mut attempt = 0;
    loop {
        match operation().await {
            Ok(result) => return Ok(result),
            Err(e) if is_retryable(&e) && attempt < max_retries => {
                let delay = calculate_backoff(attempt);
                tokio::time::sleep(delay).await;
                attempt += 1;
            }
            Err(e) => return Err(e),
        }
    }
}

fn calculate_backoff(attempt: u32) -> Duration {
    // Exponential backoff with jitter
    let base = Duration::from_secs(2u64.pow(attempt));
    let jitter = rand::random::<u64>() % 1000;
    base + Duration::from_millis(jitter)
}
```

---

## 7. Rate Limiting

### 7.1 Rate Limits

| Endpoint | Limit | Window |
|----------|-------|--------|
| POST /fraud/incidents | 100 | per minute |
| GET /fraud/incidents | 300 | per minute |
| POST /compliance/reports/* | 10 | per hour |
| POST /operators/query | 20 | per hour |

### 7.2 Rate Limit Headers

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1706526600
```

### 7.3 Handling Rate Limits

```python
async def handle_rate_limit(response):
    if response.status_code == 429:
        reset_time = int(response.headers.get('X-RateLimit-Reset'))
        wait_seconds = reset_time - time.time()
        logger.warning(f"Rate limited. Waiting {wait_seconds}s")
        await asyncio.sleep(wait_seconds)
        return True  # Retry
    return False
```

---

## 8. Security Requirements

### 8.1 Transport Security

- TLS 1.3 required
- Certificate pinning recommended
- Client certificate authentication for production

### 8.2 Request Signing

All requests should include:
- `X-Request-ID`: Unique request identifier
- `X-Timestamp`: Request timestamp
- `X-Signature`: HMAC-SHA256 signature (optional but recommended)

```python
def sign_request(method, path, body, timestamp, secret):
    message = f"{method}\n{path}\n{timestamp}\n{hash_body(body)}"
    return hmac.new(
        secret.encode(),
        message.encode(),
        hashlib.sha256
    ).hexdigest()
```

### 8.3 IP Whitelisting

Provide NCC with static IP addresses for whitelisting:
- Primary: Production egress IPs
- DR: Disaster recovery egress IPs

---

## 9. Testing & Certification

### 9.1 Sandbox Environment

- URL: `https://atrs-sandbox.ncc.gov.ng/v2`
- Credentials: Provided during onboarding
- Features: Full API with synthetic data

### 9.2 Certification Process

1. **Integration Development**: Build against sandbox
2. **Functional Testing**: Verify all endpoints
3. **Load Testing**: Demonstrate capacity
4. **Security Audit**: NCC security review
5. **Certification**: Receive production credentials

### 9.3 Test Scenarios

| Test | Expected Result |
|------|-----------------|
| Submit valid incident | 201 Created |
| Submit duplicate | 409 Conflict |
| Invalid token | 401 Unauthorized |
| Rate limit exceeded | 429 Too Many Requests |
| Daily report submission | 202 Accepted |
| Webhook delivery | 200 OK within 5s |

---

## 10. Troubleshooting

### 10.1 Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| 401 Unauthorized | Token expired | Refresh token |
| Connection timeout | Network issue | Check connectivity to NCC |
| 400 Bad Request | Schema violation | Validate against schema |
| Missing incidents | Query filter issue | Check date range |

### 10.2 Logging

Log all ATRS interactions:
```json
{
  "timestamp": "2026-01-29T10:30:00Z",
  "request_id": "req-uuid-12345",
  "method": "POST",
  "endpoint": "/fraud/incidents",
  "status": 201,
  "latency_ms": 245,
  "incident_id": "NCC-2026-01-0001234"
}
```

### 10.3 Health Check

```bash
# Check ATRS connectivity
curl -X GET https://atrs-api.ncc.gov.ng/v2/health \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

---

## Appendix A: Code Examples

### A.1 Rust Client

```rust
use reqwest::Client;
use serde::{Deserialize, Serialize};

pub struct AtrsClient {
    client: Client,
    base_url: String,
    token: String,
}

impl AtrsClient {
    pub async fn submit_incident(&self, incident: &FraudIncident) -> Result<IncidentResponse> {
        let response = self.client
            .post(&format!("{}/fraud/incidents", self.base_url))
            .bearer_auth(&self.token)
            .json(incident)
            .send()
            .await?;

        response.json().await
    }
}
```

### A.2 Python Client

```python
import aiohttp
from dataclasses import dataclass

class AtrsClient:
    def __init__(self, base_url: str, client_id: str, client_secret: str):
        self.base_url = base_url
        self.client_id = client_id
        self.client_secret = client_secret
        self.token = None

    async def submit_incident(self, incident: dict) -> dict:
        await self._ensure_token()
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{self.base_url}/fraud/incidents",
                json=incident,
                headers={"Authorization": f"Bearer {self.token}"}
            ) as response:
                return await response.json()
```

---

**Document Version:** 1.0
**API Version:** ATRS v2.1
**Classification:** Confidential
