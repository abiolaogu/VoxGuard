# API Developer Manual
## Anti-Call Masking Detection System

**Version:** 1.0.0
**Last Updated:** November 2024
**API Version:** v1

---

## Table of Contents

1. [Introduction](#introduction)
2. [Authentication](#authentication)
3. [API Endpoints](#api-endpoints)
4. [Data Models](#data-models)
5. [Integration Guide](#integration-guide)
6. [Code Examples](#code-examples)
7. [Error Handling](#error-handling)
8. [Rate Limiting](#rate-limiting)
9. [Webhooks](#webhooks)
10. [SDKs](#sdks)

---

## 1. Introduction

### 1.1 Overview
The Anti-Call Masking API provides programmatic access to submit call events, retrieve fraud alerts, and manage detection configuration.

### 1.2 Base URLs

| Environment | URL |
|-------------|-----|
| Production | `https://api.acm.yourcompany.com/api/v1` |
| Staging | `https://api-staging.acm.yourcompany.com/api/v1` |
| Development | `http://localhost:8080/api/v1` |

### 1.3 API Standards
- RESTful design principles
- JSON request/response format
- UTF-8 encoding
- ISO 8601 timestamps
- HTTP status codes for errors

---

## 2. Authentication

### 2.1 API Keys

All API requests require authentication via API key.

```bash
# Include API key in header
curl -H "Authorization: Bearer YOUR_API_KEY" \
     https://api.acm.yourcompany.com/api/v1/health
```

### 2.2 Obtaining API Keys

1. Login to Admin Dashboard
2. Navigate to Settings → API Keys
3. Click "Generate New Key"
4. Save the key securely (shown only once)

### 2.3 Key Permissions

| Scope | Description |
|-------|-------------|
| `events:write` | Submit call events |
| `alerts:read` | Read fraud alerts |
| `alerts:write` | Update alert status |
| `config:read` | Read configuration |
| `config:write` | Update configuration |
| `admin:*` | Full administrative access |

### 2.4 JWT Authentication (OAuth 2.0)

For user-based authentication:

```bash
# Get token
curl -X POST https://api.acm.yourcompany.com/auth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "client_credentials",
    "client_id": "YOUR_CLIENT_ID",
    "client_secret": "YOUR_CLIENT_SECRET"
  }'

# Response
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

---

## 3. API Endpoints

### 3.1 Health & Status

#### GET /health
Check API health status.

```bash
curl https://api.acm.yourcompany.com/api/v1/health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-11-26T10:30:00Z",
  "version": "1.0.0",
  "components": {
    "database": "healthy",
    "kdb": "healthy",
    "cache": "healthy"
  }
}
```

#### GET /ready
Check system readiness.

```bash
curl https://api.acm.yourcompany.com/api/v1/ready
```

---

### 3.2 Call Events

#### POST /fraud/events
Submit a single call event for fraud detection.

**Request:**
```bash
curl -X POST https://api.acm.yourcompany.com/api/v1/fraud/events \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "call_id": "call-uuid-12345",
    "a_number": "+15551234567",
    "b_number": "+15559876543",
    "timestamp": "2024-11-26T10:30:00Z",
    "status": "active",
    "carrier_id": "carrier-uuid",
    "switch_id": "sbc-01",
    "direction": "inbound",
    "source_ip": "192.168.1.100"
  }'
```

**Response (200 OK):**
```json
{
  "status": "accepted",
  "call_id": "call-uuid-12345",
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
  "call_id": "call-uuid-12345",
  "detection_result": {
    "detected": true,
    "threat_level": "critical",
    "distinct_a_numbers": 7,
    "alert_id": "alert-uuid-67890",
    "action": "disconnect_initiated"
  }
}
```

#### POST /fraud/events/batch
Submit multiple call events in batch.

**Request:**
```bash
curl -X POST https://api.acm.yourcompany.com/api/v1/fraud/events/batch \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "events": [
      {
        "call_id": "call-1",
        "a_number": "+15551111111",
        "b_number": "+15559999999",
        "status": "active"
      },
      {
        "call_id": "call-2",
        "a_number": "+15552222222",
        "b_number": "+15559999999",
        "status": "active"
      }
    ]
  }'
```

**Response:**
```json
{
  "status": "accepted",
  "processed": 2,
  "failed": 0,
  "results": [
    {"call_id": "call-1", "accepted": true},
    {"call_id": "call-2", "accepted": true}
  ]
}
```

---

### 3.3 Fraud Alerts

#### GET /fraud/alerts
Retrieve fraud alerts with filtering.

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `status` | string | Filter by status (new, investigating, resolved) |
| `severity` | string | Filter by severity (critical, high, medium, low) |
| `start_time` | datetime | Start of time range |
| `end_time` | datetime | End of time range |
| `b_number` | string | Filter by B-number |
| `limit` | int | Max results (default 100) |
| `offset` | int | Pagination offset |

**Request:**
```bash
curl "https://api.acm.yourcompany.com/api/v1/fraud/alerts?status=new&severity=critical&limit=10" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

**Response:**
```json
{
  "alerts": [
    {
      "alert_id": "alert-uuid-67890",
      "alert_type": "multicall_masking",
      "b_number": "+15559876543",
      "a_numbers": [
        "+15551111111",
        "+15552222222",
        "+15553333333",
        "+15554444444",
        "+15555555555"
      ],
      "call_count": 5,
      "severity": "critical",
      "status": "new",
      "detected_at": "2024-11-26T10:30:00Z",
      "detection_window_ms": 4200,
      "source_ips": ["192.168.1.100", "192.168.1.101"]
    }
  ],
  "pagination": {
    "total": 45,
    "limit": 10,
    "offset": 0,
    "has_more": true
  }
}
```

#### GET /fraud/alerts/{alert_id}
Get detailed information about a specific alert.

```bash
curl https://api.acm.yourcompany.com/api/v1/fraud/alerts/alert-uuid-67890 \
  -H "Authorization: Bearer YOUR_API_KEY"
```

#### PATCH /fraud/alerts/{alert_id}
Update alert status.

```bash
curl -X PATCH https://api.acm.yourcompany.com/api/v1/fraud/alerts/alert-uuid-67890 \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "investigating",
    "assigned_to": "analyst@example.com",
    "notes": "Investigating source IPs"
  }'
```

---

### 3.4 Call Disconnect

#### POST /fraud/disconnect
Request disconnection of fraudulent calls.

**Request:**
```bash
curl -X POST https://api.acm.yourcompany.com/api/v1/fraud/disconnect \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "call_ids": ["call-1", "call-2", "call-3"],
    "alert_id": "alert-uuid-67890",
    "reason": "fraud_detected"
  }'
```

**Response:**
```json
{
  "requested": 3,
  "disconnected": 3,
  "failed": 0,
  "results": [
    {"call_id": "call-1", "success": true},
    {"call_id": "call-2", "success": true},
    {"call_id": "call-3", "success": true}
  ]
}
```

---

### 3.5 Analytics & Statistics

#### GET /fraud/calls/stats
Get call statistics.

```bash
curl "https://api.acm.yourcompany.com/api/v1/fraud/calls/stats?period=1h" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

**Response:**
```json
{
  "period": "1h",
  "total_calls": 15420,
  "active_calls": 245,
  "alerts_generated": 12,
  "calls_disconnected": 45,
  "top_targeted_b_numbers": [
    {"b_number": "+15551234567", "attack_count": 5},
    {"b_number": "+447891234567", "attack_count": 3}
  ],
  "calls_per_second": 42.8
}
```

#### GET /kdb/traffic
Get real-time traffic analytics.

```bash
curl "https://api.acm.yourcompany.com/api/v1/kdb/traffic?minutes=5" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

### 3.6 Configuration

#### GET /fraud/config
Get current detection configuration.

```bash
curl https://api.acm.yourcompany.com/api/v1/fraud/config \
  -H "Authorization: Bearer YOUR_API_KEY"
```

**Response:**
```json
{
  "enabled": true,
  "detection_window_seconds": 5,
  "threshold": 5,
  "auto_disconnect": true,
  "cooldown_seconds": 60,
  "webhook_url": "https://hooks.example.com/acm"
}
```

#### PUT /fraud/config
Update detection configuration.

```bash
curl -X PUT https://api.acm.yourcompany.com/api/v1/fraud/config \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "threshold": 7,
    "auto_disconnect": true
  }'
```

---

## 4. Data Models

### 4.1 CallEvent

```typescript
interface CallEvent {
  call_id: string;          // Required: Unique call identifier
  a_number: string;         // Required: Source number (E.164)
  b_number: string;         // Required: Destination number (E.164)
  timestamp?: string;       // Optional: ISO 8601 (default: now)
  status: CallStatus;       // Required: Call status
  carrier_id?: string;      // Optional: Carrier UUID
  switch_id?: string;       // Optional: Switch identifier
  direction?: Direction;    // Optional: inbound|outbound
  source_ip?: string;       // Optional: Source IP address
  sip_method?: string;      // Optional: SIP method
}

enum CallStatus {
  RINGING = "ringing",
  ACTIVE = "active",
  COMPLETED = "completed",
  DISCONNECTED = "disconnected"
}

enum Direction {
  INBOUND = "inbound",
  OUTBOUND = "outbound"
}
```

### 4.2 FraudAlert

```typescript
interface FraudAlert {
  alert_id: string;
  alert_type: AlertType;
  b_number: string;
  a_numbers: string[];
  call_ids: string[];
  call_count: number;
  severity: Severity;
  status: AlertStatus;
  detected_at: string;
  detection_window_ms: number;
  source_ips: string[];
  assigned_to?: string;
  resolved_at?: string;
  notes?: string;
}

enum AlertType {
  MULTICALL_MASKING = "multicall_masking",
  VELOCITY = "velocity",
  PATTERN = "pattern"
}

enum Severity {
  CRITICAL = "critical",
  HIGH = "high",
  MEDIUM = "medium",
  LOW = "low"
}

enum AlertStatus {
  NEW = "new",
  INVESTIGATING = "investigating",
  RESOLVED = "resolved",
  FALSE_POSITIVE = "false_positive"
}
```

---

## 5. Integration Guide

### 5.1 SIP Integration

#### FreeSWITCH Event Socket

```lua
-- FreeSWITCH ESL script
session:answer()

local call_id = session:getVariable("uuid")
local a_number = session:getVariable("caller_id_number")
local b_number = session:getVariable("destination_number")

-- Send to ACM API
local api = require("api_client")
local result = api.submit_event({
  call_id = call_id,
  a_number = a_number,
  b_number = b_number,
  status = "active"
})

if result.detected then
  session:hangup("CALL_REJECTED")
end
```

#### Kamailio Integration

```kamailio
# kamailio.cfg
route[FRAUD_CHECK] {
    $var(call_id) = $ci;
    $var(a_number) = $fU;
    $var(b_number) = $rU;

    # HTTP async request to ACM
    http_async_query(
        "http://carrier-api:8080/api/v1/fraud/events",
        "POST",
        "{\"call_id\":\"$var(call_id)\",\"a_number\":\"$var(a_number)\",\"b_number\":\"$var(b_number)\",\"status\":\"active\"}",
        "FRAUD_RESPONSE"
    );
}

route[FRAUD_RESPONSE] {
    if ($http_rs == 200) {
        jansson_get("detection_result.detected", "$http_rb", "$var(detected)");
        if ($var(detected) == "true") {
            send_reply("603", "Decline");
            exit;
        }
    }
}
```

### 5.2 Real-time Streaming

#### WebSocket Connection

```javascript
const ws = new WebSocket('wss://api.acm.yourcompany.com/ws/alerts');

ws.onopen = () => {
  ws.send(JSON.stringify({
    type: 'subscribe',
    channel: 'alerts',
    filters: { severity: ['critical', 'high'] }
  }));
};

ws.onmessage = (event) => {
  const alert = JSON.parse(event.data);
  console.log('New alert:', alert);
};
```

---

## 6. Code Examples

### 6.1 Python

```python
import requests
from datetime import datetime

class ACMClient:
    def __init__(self, api_key: str, base_url: str = "https://api.acm.yourcompany.com/api/v1"):
        self.api_key = api_key
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update({
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        })

    def submit_call_event(self, call_id: str, a_number: str, b_number: str,
                          status: str = "active") -> dict:
        """Submit a call event for fraud detection."""
        payload = {
            "call_id": call_id,
            "a_number": a_number,
            "b_number": b_number,
            "status": status,
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
        response = self.session.post(f"{self.base_url}/fraud/events", json=payload)
        response.raise_for_status()
        return response.json()

    def get_alerts(self, status: str = None, severity: str = None,
                   limit: int = 100) -> list:
        """Retrieve fraud alerts."""
        params = {"limit": limit}
        if status:
            params["status"] = status
        if severity:
            params["severity"] = severity

        response = self.session.get(f"{self.base_url}/fraud/alerts", params=params)
        response.raise_for_status()
        return response.json()["alerts"]

    def disconnect_calls(self, call_ids: list, alert_id: str = None) -> dict:
        """Disconnect fraudulent calls."""
        payload = {
            "call_ids": call_ids,
            "reason": "fraud_detected"
        }
        if alert_id:
            payload["alert_id"] = alert_id

        response = self.session.post(f"{self.base_url}/fraud/disconnect", json=payload)
        response.raise_for_status()
        return response.json()

# Usage
client = ACMClient("your-api-key")

# Submit call event
result = client.submit_call_event(
    call_id="call-123",
    a_number="+15551234567",
    b_number="+15559876543"
)

if result.get("detection_result", {}).get("detected"):
    print(f"Fraud detected! Alert ID: {result['detection_result']['alert_id']}")

# Get critical alerts
alerts = client.get_alerts(status="new", severity="critical")
for alert in alerts:
    print(f"Alert: {alert['alert_id']} - {len(alert['a_numbers'])} A-numbers")
```

### 6.2 Node.js

```javascript
const axios = require('axios');

class ACMClient {
  constructor(apiKey, baseUrl = 'https://api.acm.yourcompany.com/api/v1') {
    this.client = axios.create({
      baseURL: baseUrl,
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      }
    });
  }

  async submitCallEvent(callId, aNumber, bNumber, status = 'active') {
    const response = await this.client.post('/fraud/events', {
      call_id: callId,
      a_number: aNumber,
      b_number: bNumber,
      status: status,
      timestamp: new Date().toISOString()
    });
    return response.data;
  }

  async getAlerts(filters = {}) {
    const response = await this.client.get('/fraud/alerts', { params: filters });
    return response.data.alerts;
  }

  async disconnectCalls(callIds, alertId = null) {
    const response = await this.client.post('/fraud/disconnect', {
      call_ids: callIds,
      alert_id: alertId,
      reason: 'fraud_detected'
    });
    return response.data;
  }
}

// Usage
const client = new ACMClient('your-api-key');

(async () => {
  // Submit call event
  const result = await client.submitCallEvent(
    'call-123',
    '+15551234567',
    '+15559876543'
  );

  if (result.detection_result?.detected) {
    console.log(`Fraud detected! Alert ID: ${result.detection_result.alert_id}`);
  }

  // Get alerts
  const alerts = await client.getAlerts({ status: 'new', severity: 'critical' });
  alerts.forEach(alert => {
    console.log(`Alert: ${alert.alert_id} - ${alert.a_numbers.length} A-numbers`);
  });
})();
```

### 6.3 Go

```go
package main

import (
    "bytes"
    "encoding/json"
    "fmt"
    "net/http"
    "time"
)

type ACMClient struct {
    APIKey  string
    BaseURL string
    Client  *http.Client
}

type CallEvent struct {
    CallID    string `json:"call_id"`
    ANumber   string `json:"a_number"`
    BNumber   string `json:"b_number"`
    Status    string `json:"status"`
    Timestamp string `json:"timestamp"`
}

type DetectionResult struct {
    Detected   bool   `json:"detected"`
    AlertID    string `json:"alert_id,omitempty"`
    ThreatLevel string `json:"threat_level"`
}

type EventResponse struct {
    Status          string          `json:"status"`
    CallID          string          `json:"call_id"`
    DetectionResult DetectionResult `json:"detection_result"`
}

func NewACMClient(apiKey string) *ACMClient {
    return &ACMClient{
        APIKey:  apiKey,
        BaseURL: "https://api.acm.yourcompany.com/api/v1",
        Client:  &http.Client{Timeout: 10 * time.Second},
    }
}

func (c *ACMClient) SubmitCallEvent(callID, aNumber, bNumber string) (*EventResponse, error) {
    event := CallEvent{
        CallID:    callID,
        ANumber:   aNumber,
        BNumber:   bNumber,
        Status:    "active",
        Timestamp: time.Now().UTC().Format(time.RFC3339),
    }

    body, _ := json.Marshal(event)
    req, _ := http.NewRequest("POST", c.BaseURL+"/fraud/events", bytes.NewBuffer(body))
    req.Header.Set("Authorization", "Bearer "+c.APIKey)
    req.Header.Set("Content-Type", "application/json")

    resp, err := c.Client.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    var result EventResponse
    json.NewDecoder(resp.Body).Decode(&result)
    return &result, nil
}

func main() {
    client := NewACMClient("your-api-key")

    result, err := client.SubmitCallEvent("call-123", "+15551234567", "+15559876543")
    if err != nil {
        panic(err)
    }

    if result.DetectionResult.Detected {
        fmt.Printf("Fraud detected! Alert ID: %s\n", result.DetectionResult.AlertID)
    }
}
```

---

## 7. Error Handling

### 7.1 Error Response Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request parameters",
    "details": [
      {
        "field": "a_number",
        "message": "Must be in E.164 format"
      }
    ],
    "request_id": "req-uuid-12345"
  }
}
```

### 7.2 Error Codes

| HTTP Code | Error Code | Description |
|-----------|------------|-------------|
| 400 | `VALIDATION_ERROR` | Invalid request parameters |
| 401 | `UNAUTHORIZED` | Missing or invalid API key |
| 403 | `FORBIDDEN` | Insufficient permissions |
| 404 | `NOT_FOUND` | Resource not found |
| 409 | `CONFLICT` | Resource conflict |
| 429 | `RATE_LIMITED` | Too many requests |
| 500 | `INTERNAL_ERROR` | Server error |
| 503 | `SERVICE_UNAVAILABLE` | Service temporarily unavailable |

### 7.3 Retry Strategy

```python
import time
from functools import wraps

def retry_with_backoff(max_retries=3, base_delay=1):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(max_retries):
                try:
                    return func(*args, **kwargs)
                except requests.exceptions.RequestException as e:
                    if attempt == max_retries - 1:
                        raise
                    delay = base_delay * (2 ** attempt)
                    time.sleep(delay)
        return wrapper
    return decorator

@retry_with_backoff(max_retries=3)
def submit_event(client, event):
    return client.submit_call_event(**event)
```

---

## 8. Rate Limiting

### 8.1 Limits

| Endpoint | Rate Limit | Burst |
|----------|------------|-------|
| POST /fraud/events | 1000/sec | 100 |
| POST /fraud/events/batch | 100/sec | 10 |
| GET /fraud/alerts | 100/sec | 20 |
| POST /fraud/disconnect | 50/sec | 10 |

### 8.2 Rate Limit Headers

```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 995
X-RateLimit-Reset: 1700000000
```

---

## 9. Webhooks

### 9.1 Webhook Events

| Event | Description |
|-------|-------------|
| `alert.created` | New fraud alert generated |
| `alert.updated` | Alert status changed |
| `call.disconnected` | Fraudulent call disconnected |
| `threshold.exceeded` | Detection threshold exceeded |

### 9.2 Webhook Payload

```json
{
  "event": "alert.created",
  "timestamp": "2024-11-26T10:30:00Z",
  "data": {
    "alert_id": "alert-uuid-67890",
    "alert_type": "multicall_masking",
    "b_number": "+15559876543",
    "a_numbers": ["+15551111111", "+15552222222"],
    "severity": "critical"
  },
  "signature": "sha256=..."
}
```

### 9.3 Webhook Verification

```python
import hmac
import hashlib

def verify_webhook(payload: bytes, signature: str, secret: str) -> bool:
    expected = hmac.new(
        secret.encode(),
        payload,
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(f"sha256={expected}", signature)
```

---

## 10. SDKs

### 10.1 Official SDKs

| Language | Repository |
|----------|------------|
| Python | `pip install acm-client` |
| Node.js | `npm install @acm/client` |
| Go | `go get github.com/acm/go-client` |
| Java | Maven: `com.acm:acm-client` |

### 10.2 Community SDKs

- Ruby: `gem install acm-ruby`
- PHP: `composer require acm/client`
- .NET: `dotnet add package ACM.Client`

---

## Appendix: OpenAPI Specification

Full OpenAPI 3.0 specification available at:
`https://api.acm.yourcompany.com/api/v1/openapi.json`

---

**Document Version:** 1.0.0
**API Version:** v1
