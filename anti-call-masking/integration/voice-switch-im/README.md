# Voice-Switch-IM Integration Files

This directory contains integration files for the Anti-Call Masking fraud detection system with [Voice-Switch-IM](https://github.com/abiolaogu/Voice-Switch-IM).

## Native kdb+ Integration

As of the latest Voice-Switch-IM update, the anti-call masking detection is now **natively integrated** into the Voice Switch kdb+ analytics engine. This provides:

- **Higher Performance**: Uses kdb+ IPC protocol for sub-millisecond detection
- **Unified Architecture**: Fraud detection runs alongside CDR analytics
- **Simplified Deployment**: No separate fraud detection container needed

## Files Overview

### Go Backend Files (for reference/fallback)

- `call.go` - Call event and fraud alert data models
- `fraud_handler.go` - HTTP API handlers for fraud detection
- `router.go.patch` - Router configuration

### kdb+ Scripts (Now Integrated)

The anti-call masking logic is now in `Voice-Switch-IM/kdb/scripts/anti_call_masking.q`:

```q
// Key functions:
.acm.processCall[cdrRecord]     // Process a call for masking detection
.acm.getThreatLevel[`B12345]    // Get threat level for B-number
.acm.getElevatedThreats[]       // Get all elevated threats
.acm.getStats[]                 // Get detection statistics
.acm.setThreshold[5]            // Set detection threshold
.acm.setWindow[5]               // Set window in seconds
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Voice-Switch-IM                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │                 kdb+ Analytics Engine (:5000/:5001)           │ │
│  │  ┌─────────────────────┐  ┌─────────────────────┐            │ │
│  │  │ CDR Analytics       │  │ Anti-Call Masking   │            │ │
│  │  │ - carrierStats      │  │ - .acm.processCall  │            │ │
│  │  │ - destStats         │  │ - .acm.checkMasking │            │ │
│  │  │ - qosMetrics        │  │ - .acm.raiseAlert   │            │ │
│  │  └─────────────────────┘  └─────────────────────┘            │ │
│  │                                                               │ │
│  │  Tables: cdr, fraudAlert, carrierMetrics, activeCalls        │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                              │                                      │
│  ┌───────────────────────────▼───────────────────────────────────┐ │
│  │              Carrier API (Go) :8080                           │ │
│  │  - Uses native kdb+ IPC client                                │ │
│  │  - /api/v1/fraud/* endpoints for HTTP access                  │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

## Configuration

### Environment Variables (carrier-api)

```yaml
# kdb+ Connection
KDB_HOST: kdb
KDB_PORT: "5000"                      # IPC port
FRAUD_DETECTION_URL: "http://kdb:5001" # HTTP port

# Kamailio for call disconnect
KAMAILIO_MI_URL: "http://kamailio-sbc:5060"
```

### Detection Parameters

Set in kdb+ via IPC or HTTP:

```bash
# Via HTTP
curl -X POST http://kdb:5001/acm/config \
  -d '{"threshold":5,"window_seconds":5}'

# Via kdb+ IPC
q) .acm.setThreshold[5]
q) .acm.setWindow[5]
```

## API Endpoints

### kdb+ HTTP API (:5001)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/alerts` | GET | Get fraud alerts |
| `/acm/threats` | GET | Get elevated threats |
| `/acm/threat?b_number=X` | GET | Get threat level for B-number |
| `/acm/stats` | GET | Get detection statistics |
| `/acm/alerts?minutes=60` | GET | Get recent anti-call masking alerts |

### Carrier API (:8080)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/fraud/events` | POST | Submit call event |
| `/api/v1/fraud/events/batch` | POST | Submit batch events |
| `/api/v1/fraud/disconnect` | POST | Disconnect fraudulent calls |
| `/api/v1/fraud/calls/active` | GET | List active calls |
| `/api/v1/fraud/alerts` | GET | Get fraud alerts |
| `/api/v1/fraud/health` | GET | Fraud subsystem health |

## Testing

```bash
# Check kdb+ health
curl http://localhost:5001/health

# Check anti-call masking stats
curl http://localhost:5001/acm/stats

# Submit test call via carrier-api
curl -X POST http://localhost:8080/api/v1/fraud/events \
  -H "Content-Type: application/json" \
  -d '{"call_id":"test1","a_number":"A001","b_number":"B999","status":"active"}'

# Get elevated threats
curl http://localhost:5001/acm/threats
```

## Migration from Standalone Fraud Detection

If you were previously running the standalone fraud-detection container:

1. Remove the `fraud-detection` service from docker-compose.yml
2. Update `FRAUD_DETECTION_URL` to point to kdb+ HTTP API (`http://kdb:5001`)
3. The kdb+ service now includes anti-call masking detection natively
4. Deploy: `docker-compose up -d --build`
