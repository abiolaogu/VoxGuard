# Technical Specification
## Anti-Call Masking System

### 1. API Specification

#### `POST /event`
Submits a call event for processing.

**Request Body** (`application/json`):
```json
{
  "call_id": "uuid-v4",
  "a_number": "+1234567890",
  "b_number": "+0987654321",
  "timestamp": "2023-10-27T10:00:00Z"
}
```

**Response** (`200 OK`):
```json
{
  "status": "processed" | "alert",
  "alert": { ... } // Optional, only if fraud detected
}
```

#### `GET /health`
Liveness probe. Returns `200 OK`.

### 2. Database Schema (ClickHouse)

#### Table: `calls`
| Column | Type | Description |
| :--- | :--- | :--- |
| `call_id` | String | Unique ID |
| `a_number` | String | Caller ID |
| `b_number` | String | Destination Number |
| `timestamp` | DateTime | Event time |

#### Table: `fraud_alerts`
| Column | Type | Description |
| :--- | :--- | :--- |
| `alert_id` | String | Unique Alert ID |
| `b_number` | String | Victim Number |
| `call_count` | UInt32 | Distinct callers detected |
| `created_at` | DateTime | Alert generation time |

### 3. Configuration
Configuration handles via Environment Variables in Kubernetes `ConfigMap`.

| Variable | Default | Description |
| :--- | :--- | :--- |
| `DETECTION_WINDOW_SECONDS` | `5` | Sliding window duration |
| `DETECTION_THRESHOLD` | `5` | Max distinct callers allowed |
| `CLICKHOUSE_URL` | `http://localhost:8123` | ClickHouse Connection |
| `REDIS_URL` | `redis://localhost:6379` | DragonflyDB Connection |
