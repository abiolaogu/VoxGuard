# API Reference

## Detection Engine API (Rust)

Base URL: `http://localhost:8080`

### Endpoints

#### Health Check
```http
GET /health
```
Returns service health status.

#### Register Call
```http
POST /api/v1/calls
Content-Type: application/json

{
  "a_number": "+2348012345678",
  "b_number": "+2348098765432",
  "source_ip": "192.168.1.1",
  "call_id": "uuid-string"
}
```
Registers a call and performs fraud detection. Returns alert if fraud detected.

#### Get Alert
```http
GET /api/v1/alerts/{alert_id}
```
Returns alert details.

#### Acknowledge Alert
```http
POST /api/v1/alerts/{alert_id}/acknowledge
Content-Type: application/json

{
  "user_id": "analyst-1"
}
```

#### Resolve Alert
```http
POST /api/v1/alerts/{alert_id}/resolve
Content-Type: application/json

{
  "user_id": "analyst-1",
  "resolution": "confirmed_fraud",
  "notes": "Verified CLI masking attack"
}
```

---

## Management API (Go)

Base URL: `http://localhost:8081`

### Gateway Management

#### List Gateways
```http
GET /api/v1/gateways
```

#### Create Gateway
```http
POST /api/v1/gateways
Content-Type: application/json

{
  "name": "Lagos Gateway 1",
  "ip_address": "10.0.0.1",
  "carrier_name": "MTN Nigeria",
  "gateway_type": "local"
}
```

#### Update Thresholds
```http
PATCH /api/v1/gateways/{id}/thresholds
Content-Type: application/json

{
  "fraud_threshold": 0.75,
  "cpm_limit": 100,
  "acd_threshold": 15.0
}
```

#### Blacklist Gateway
```http
POST /api/v1/gateways/{id}/blacklist
Content-Type: application/json

{
  "reason": "Fraud detected",
  "expires_at": "2026-02-01T00:00:00Z"
}
```

### Fraud Alerts

#### List Pending Alerts
```http
GET /api/v1/alerts?status=pending
```

#### Get Dashboard Summary
```http
GET /api/v1/dashboard
```

### MNP Lookup

#### Lookup MSISDN
```http
GET /api/v1/mnp/lookup/{msisdn}
```
Returns carrier information for a Nigerian number.

### Blacklist

#### Add to Blacklist
```http
POST /api/v1/blacklist
Content-Type: application/json

{
  "entry_type": "msisdn",
  "value": "+2348012345678",
  "reason": "Confirmed fraud"
}
```

#### Check Blacklist
```http
GET /api/v1/blacklist/check/{value}
```

---

## Metrics API

### Prometheus Metrics
```http
GET /metrics
```

Available metrics:
- `acm_calls_total{status,region}` - Total calls processed
- `acm_detection_latency_seconds{region}` - Detection latency histogram
- `acm_alerts_total{fraud_type,severity,region}` - Alerts generated
- `acm_cache_operations_total{operation,result}` - Cache hit/miss
- `acm_active_calls` - Current calls in detection window
- `acm_pending_alerts` - Unacknowledged alerts count
