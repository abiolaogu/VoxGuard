# Voice Switch Integration Guide

## Overview

This document describes the integration between the Anti-Call Masking Detection System (kdb+) and the Voice-Switch-IM platform. The integration enables real-time fraud detection for SIP calls passing through the Voice Switch infrastructure.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Voice-Switch-IM                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌───────────────┐    ┌───────────────┐    ┌───────────────┐       │
│  │ Kamailio SBC  │───▶│ Kamailio C4   │───▶│ OpenSIPS C5   │       │
│  │  (5060/UDP)   │    │    Router     │    │   Services    │       │
│  └───────────────┘    └───────────────┘    └───────────────┘       │
│         │                                                           │
│         │ SIP Events                                                │
│         ▼                                                           │
│  ┌───────────────────────────────────────┐                         │
│  │           Carrier API (Go)            │                         │
│  │              :8080                    │                         │
│  │  ┌─────────────────────────────────┐  │                         │
│  │  │     Fraud Detection Handler     │  │                         │
│  │  │   POST /api/v1/fraud/events     │  │                         │
│  │  │   POST /api/v1/fraud/disconnect │  │                         │
│  │  └─────────────────────────────────┘  │                         │
│  └────────────────────┬──────────────────┘                         │
│                       │ HTTP/JSON                                   │
└───────────────────────┼─────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Anti-Call Masking (kdb+)                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌───────────────────────────────────────┐                         │
│  │         HTTP API Server (:5000)       │                         │
│  │  ┌─────────────┐  ┌─────────────────┐ │                         │
│  │  │ POST /event │  │ GET /alerts     │ │                         │
│  │  │ GET /health │  │ GET /stats      │ │                         │
│  │  └─────────────┘  └─────────────────┘ │                         │
│  └────────────────────┬──────────────────┘                         │
│                       │                                             │
│  ┌────────────────────▼──────────────────┐                         │
│  │        Detection Engine (q)           │                         │
│  │  • 5-second sliding window            │                         │
│  │  • 5+ distinct A-numbers = fraud      │                         │
│  │  • Nanosecond precision               │                         │
│  └────────────────────┬──────────────────┘                         │
│                       │                                             │
│  ┌────────────────────▼──────────────────┐                         │
│  │       Actions (Disconnect/Block)      │──────┐                  │
│  └───────────────────────────────────────┘      │                  │
│                                                  │                  │
└──────────────────────────────────────────────────┼──────────────────┘
                                                   │
                                                   │ HTTP POST
                                                   ▼
                                    POST /api/v1/fraud/disconnect
                                        (to Carrier API)
```

## API Endpoints

### Carrier API (Voice Switch) → Fraud Detection (kdb+)

#### POST /event
Submit a single call event for fraud detection.

```json
{
  "call_id": "abc123-def456",
  "a_number": "+15551234567",
  "b_number": "+15559876543",
  "timestamp": "2024-01-15T10:30:00Z",
  "status": "active",
  "switch_id": "kamailio-sbc"
}
```

Response:
```json
{
  "status": "processed",
  "detected": true,
  "alert_id": "alert-789"
}
```

#### POST /events/batch
Submit multiple call events in a batch.

```json
{
  "events": [
    {"call_id": "call1", "a_number": "A001", "b_number": "B999", "status": "active"},
    {"call_id": "call2", "a_number": "A002", "b_number": "B999", "status": "active"}
  ]
}
```

#### GET /health
Health check endpoint.

```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "version": "1.0.0"
}
```

#### GET /alerts
Get recent fraud alerts.

```json
[
  {
    "alert_id": "abc-123",
    "b_number": "+15559876543",
    "a_numbers": ["+15551111111", "+15552222222"],
    "call_count": 5,
    "severity": "high",
    "detected_at": "2024-01-15T10:30:00Z"
  }
]
```

#### GET /stats
Get detection statistics.

```json
{
  "processed_total": 10000,
  "alerts_total": 15,
  "active_calls": 45,
  "avg_latency_ms": 0.5
}
```

### Fraud Detection (kdb+) → Carrier API (Voice Switch)

#### POST /api/v1/fraud/disconnect
Disconnect fraudulent calls.

```json
{
  "call_ids": ["call1", "call2", "call3"],
  "alert_id": "alert-789",
  "reason": "fraud_detected"
}
```

Response:
```json
{
  "requested": 3,
  "disconnected": 3,
  "failed": 0,
  "results": [
    {"call_id": "call1", "success": true},
    {"call_id": "call2", "success": true},
    {"call_id": "call3", "success": true}
  ]
}
```

## Configuration

### Environment Variables

#### Fraud Detection Service (kdb+)

| Variable | Default | Description |
|----------|---------|-------------|
| `DETECTION_WINDOW_SEC` | 5 | Detection window in seconds |
| `DETECTION_THRESHOLD` | 5 | Minimum A-numbers for detection |
| `SWITCH_PROTOCOL` | voiceswitch | Switch protocol type |
| `VOICE_SWITCH_API_URL` | http://carrier-api:8080/api/v1 | Voice Switch API URL |
| `HTTP_PORT` | 5000 | HTTP server port |
| `WEBHOOK_URL` | - | Alert webhook URL |
| `LOG_LEVEL` | INFO | Log level |

#### Carrier API (Go)

| Variable | Default | Description |
|----------|---------|-------------|
| `FRAUD_DETECTION_URL` | http://fraud-detection:5000 | Fraud detection service URL |
| `KAMAILIO_MI_URL` | http://kamailio-sbc:5060 | Kamailio MI interface URL |

## Docker Compose Integration

The fraud detection service is included in the Voice-Switch-IM docker-compose.yml:

```yaml
fraud-detection:
  build:
    context: ../Anti_Call-Masking/anti-call-masking
    dockerfile: Dockerfile
  environment:
    DETECTION_WINDOW_SEC: "5"
    DETECTION_THRESHOLD: "5"
    SWITCH_PROTOCOL: "voiceswitch"
    VOICE_SWITCH_API_URL: "http://carrier-api:8080/api/v1"
  ports:
    - "5000:5000"
    - "9090:9090"
  networks:
    private:
      ipv4_address: 172.16.238.20
```

## Detection Algorithm

The system detects multicall masking attacks using a sliding window algorithm:

1. **Sliding Window**: 5-second window (configurable)
2. **Threshold**: 5+ distinct A-numbers calling the same B-number
3. **Real-time**: Nanosecond precision timestamps
4. **Auto-disconnect**: Automatically terminates fraudulent calls

### Example Detection Scenario

```
Time    A-Number    B-Number    Detection
-----   --------    --------    ---------
T+0.0   A001        B999        No (1 caller)
T+0.5   A002        B999        No (2 callers)
T+1.0   A003        B999        No (3 callers)
T+1.5   A004        B999        No (4 callers)
T+2.0   A005        B999        DETECTED (5 callers)
                                → Disconnect all 5 calls
                                → Block pattern
```

## Monitoring

### Prometheus Metrics

Available at `:9090/metrics`:

- `fraud_calls_processed_total` - Total calls processed
- `fraud_alerts_generated_total` - Total fraud alerts
- `fraud_disconnects_total` - Total calls disconnected
- `fraud_detection_latency_ms` - Detection latency histogram

### Grafana Dashboard

Import the dashboard from `grafana/dashboard.json` for visualization.

## Troubleshooting

### Connection Issues

1. Check network connectivity:
   ```bash
   docker exec fraud-detection curl -s http://carrier-api:8080/health
   ```

2. Verify fraud detection is running:
   ```bash
   docker logs fraud-detection
   ```

3. Check for errors in carrier-api:
   ```bash
   docker logs carrier-api | grep fraud
   ```

### Detection Not Triggering

1. Verify calls are being received:
   ```bash
   curl http://localhost:5000/stats
   ```

2. Check detection configuration:
   ```bash
   curl http://localhost:5000/config
   ```

3. Test with simulation:
   ```q
   // In kdb+ console
   .fraud.switch.enableSimulation[]
   .fraud.switch.simulateAttack["B123";5;0]
   ```

### Performance Issues

1. Check latency metrics:
   ```bash
   curl http://localhost:5000/stats | jq '.avg_latency_ms'
   ```

2. Monitor memory usage:
   ```bash
   docker stats fraud-detection
   ```

## Security Considerations

1. **Network Isolation**: Fraud detection runs on internal network only
2. **No Sensitive Data**: Call content is not captured
3. **Rate Limiting**: API has built-in rate limiting
4. **Audit Logging**: All actions are logged

## Support

For issues or questions:
- GitHub Issues: https://github.com/abiolaogu/Anti_Call-Masking/issues
- Voice-Switch-IM: https://github.com/abiolaogu/Voice-Switch-IM
