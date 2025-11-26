# Voice-Switch-IM Integration Files

This directory contains the Go source files needed to integrate the Anti-Call Masking fraud detection system with the [Voice-Switch-IM](https://github.com/abiolaogu/Voice-Switch-IM) platform.

## Files

### `call.go`
Data models for call events and fraud alerts. Add this to:
```
Voice-Switch-IM/backend/internal/model/call.go
```

### `fraud_handler.go`
API handlers for fraud detection integration. Add this to:
```
Voice-Switch-IM/backend/internal/api/fraud_handler.go
```

### `router.go.patch`
Updated router with fraud routes registered. The key change to add to your router.go:
```go
// Register fraud detection routes
api.RegisterFraudRoutes(v1, cfg.Logger)
```

## Docker Compose Changes

Add the following service to your docker-compose.yml:

```yaml
# kdb+ Fraud Detection Service - Anti-Call Masking System
fraud-detection:
  build:
    context: ../Anti_Call-Masking/anti-call-masking
    dockerfile: Dockerfile
  environment:
    DETECTION_WINDOW_SEC: "5"
    DETECTION_THRESHOLD: "5"
    SWITCH_PROTOCOL: "voiceswitch"
    VOICE_SWITCH_API_URL: "http://carrier-api:8080/api/v1"
    REDIS_URL: "redis://dragonfly:6379/1"
    WEBHOOK_URL: "http://carrier-api:8080/api/v1/fraud/alerts/webhook"
  ports:
    - "5000:5000"
    - "9090:9090"
  depends_on:
    dragonfly:
      condition: service_healthy
  networks:
    private:
      ipv4_address: 172.16.238.20
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
    interval: 10s
    timeout: 5s
    retries: 5
  volumes:
    - fraud-detection-data:/app/data
    - fraud-detection-logs:/app/logs
```

And add volumes:
```yaml
volumes:
  fraud-detection-data:
  fraud-detection-logs:
```

Also add to carrier-api environment:
```yaml
FRAUD_DETECTION_URL: "http://fraud-detection:5000"
KAMAILIO_MI_URL: "http://kamailio-sbc:5060"
```

## Integration Steps

1. Copy the Go files to their respective locations in Voice-Switch-IM
2. Update Voice-Switch-IM's router.go to register fraud routes
3. Update docker-compose.yml with the fraud-detection service
4. Build and deploy: `docker-compose up -d --build`

## Testing

After deployment, verify the integration:

```bash
# Check fraud detection health
curl http://localhost:5000/health

# Submit test call event
curl -X POST http://localhost:8080/api/v1/fraud/events \
  -H "Content-Type: application/json" \
  -d '{"call_id":"test1","a_number":"A001","b_number":"B999","status":"active"}'

# Check detection stats
curl http://localhost:5000/stats
```
