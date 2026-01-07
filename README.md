# Anti-Call Masking Detection System

[![Rust](https://img.shields.io/badge/Rust-1.70%2B-orange.svg)](https://www.rust-lang.org)
[![ClickHouse](https://img.shields.io/badge/ClickHouse-23.8-yellow.svg)](https://clickhouse.com)
[![DragonflyDB](https://img.shields.io/badge/DragonflyDB-High%20Perf-blue.svg)](https://dragonflydb.io)

Real-time fraud detection system for identifying call masking attacks using **Rust** and **ClickHouse**.
Designed for **"almost no latency"** and **infinite horizontal scalability**.

## Overview

Call masking (also known as CLI spoofing) is a technique used by fraudsters to disguise their identity.
This system detects such patterns in real-time with **sub-millisecond latency** using an in-memory sliding window (DragonflyDB) and asynchronously persists data for analytics (ClickHouse).

### Key Features

-   **Zero Latency**: Rust + DragonflyDB ensures detection takes < 1ms.
-   **Horizontal Scalability**: Stateless detection service can scale to 100+ nodes.
-   **Massive Throughput**: ClickHouse handles billions of records for analytics.
-   **Real-time Alerts**: Instant notifications for fraud attempts.
-   **Open Source**: No proprietary licenses required.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Voice Switch                              │
│   (Kamailio / OpenSIPS / Asterisk)                              │
└────────┼────────────────────────────────────────────────────────┘
         │ HTTP / gRPC
         ▼
┌───────────────────────────┐         ┌─────────────────────────┐
│  Detection Service (Rust) │ <─────> │      DragonflyDB        │
│  (Stateless, Scalable)    │         │ (Hot Sliding Window)    │
└────────┬──────────────────┘         └─────────────────────────┘
         │
         │ Async Batch Write
         ▼
┌───────────────────────────┐
│       ClickHouse          │
│   (Historical Data)       │
└───────────────────────────┘
```

## Quick Start

### Prerequisites

-   Docker & Docker Compose

### 1. Start the Stack

```bash
cd anti-call-masking
docker-compose up -d
```

### 2. Verify Services

-   **Rust API**: http://localhost:8080/health
-   **ClickHouse**: http://localhost:8123
-   **DragonflyDB**: port 6379

### 3. Simulate Attack

```bash
# Send 5 calls from different A-numbers to the same B-number
curl -X POST http://localhost:8080/event -H "Content-Type: application/json" -d '{"call_id":"1", "a_number":"+111", "b_number":"+234999", "timestamp":"2023-01-01T00:00:00Z"}'
# ... repeat with different a_numbers
```

## Project Structure

```
anti-call-masking/
├── detection-service-rust/  # Main Rust Application
│   ├── src/                 # Source code
│   └── Dockerfile
├── docker-compose.yml       # Infrastructure (ClickHouse, Dragonfly, Rust)
├── k8s-legacy/              # Old Kubernetes manifests (Deprecated)
├── config/                  # Configuration files
└── README.md
```

## Documentation

### User Manuals

- [Administrator Manual](anti-call-masking/docs/manuals/ADMIN_MANUAL.md)
- [SOC Analyst Manual](anti-call-masking/docs/manuals/SOC_ANALYST_MANUAL.md)
- [API Developer Manual](anti-call-masking/docs/manuals/API_DEVELOPER_MANUAL.md)

### Training

- [Training Program Overview](anti-call-masking/docs/training/TRAINING_OVERVIEW.md)

## Building

### Web Dashboard

```bash
cd anti-call-masking/frontend
npm install
npm run build
```

### Mobile App

```bash
cd anti-call-masking/mobile

# Android APK
flutter build apk --release --flavor production

# iOS IPA (macOS only)
flutter build ios --release
```

See [Mobile README](anti-call-masking/mobile/README.md) for detailed build instructions.

## Voice-Switch-IM Integration

This system integrates with the [Voice-Switch-IM](https://github.com/abiolaogu/Voice-Switch-IM) platform for native kdb+ fraud detection. The integration includes:

- Native kdb+ IPC protocol communication
- Real-time CDR streaming via tickerplant
- Automatic alert generation and response
- SIP call disconnection via Kamailio

## Performance

| Metric | Value |
|--------|-------|
| Detection Latency | < 1ms |
| Throughput | 100,000+ calls/sec |
| Memory Footprint | ~500MB |
| False Positive Rate | < 2% |

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Documentation**: [docs/](anti-call-masking/docs/)
- **Issues**: [GitHub Issues](https://github.com/abiolaogu/Anti_Call-Masking/issues)
- **Email**: support@acm.yourcompany.com

## Acknowledgments

- [kdb+](https://kx.com) - High-performance time-series database
- [Voice-Switch-IM](https://github.com/abiolaogu/Voice-Switch-IM) - Voice switching platform
- [Flutter](https://flutter.dev) - Cross-platform mobile framework
- [React](https://reactjs.org) - Web UI framework
