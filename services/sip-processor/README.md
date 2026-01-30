# SIP Processor - Anti-Call Masking Platform

Real-time SIP signaling analysis and masking detection service built with FastAPI.

## Features

- **SIP Header Extraction**: Parse CLI and P-Asserted-Identity from SIP INVITE messages
- **CDR Metrics**: Calculate ASR, ALOC, and Overlap Ratio in real-time
- **ML Inference**: XGBoost-based masking attack detection
- **Async-First**: Built on FastAPI with async Redis for maximum throughput

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Run locally
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Run with Docker
docker build -t sip-processor .
docker run -p 8000:8000 sip-processor
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/api/v1/analyze` | POST | Analyze call for masking |
| `/api/v1/metrics/{b_number}` | GET | Get CDR metrics |
| `/api/v1/sip/parse` | POST | Parse raw SIP message |

## Configuration

Environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `REDIS_URL` | `redis://localhost:6379` | Redis connection URL |
| `POSTGRES_URL` | `postgresql://...` | PostgreSQL connection URL |
| `SIP_INTERFACE` | `eth0` | Network interface for capture |
| `SIP_PORT` | `5060` | SIP signaling port |
| `MODEL_PATH` | `models/xgboost_masking.json` | XGBoost model path |

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  SIP Traffic    │────▶│  Signaling       │────▶│  CDR Processor  │
│  (Port 5060)    │     │  Listener        │     │  (Redis)        │
└─────────────────┘     └──────────────────┘     └────────┬────────┘
                                                          │
                        ┌──────────────────┐              │
                        │  XGBoost         │◀─────────────┘
                        │  Inference       │
                        └──────────────────┘
```
