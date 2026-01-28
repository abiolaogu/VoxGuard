# Anti-Call Masking - Core Platform

This directory contains the core Anti-Call Masking platform components.

## Components

| Directory | Language | Description |
|-----------|----------|-------------|
| `detection-service-rust/` | Rust | High-performance fraud detection engine |
| `anti-call-masking-platform/` | Go | Management API with DDD bounded contexts |
| `sip-processor/` | Python | SIP message processing and inference |

## Quick Start

### Rust Detection Engine
```bash
cd detection-service-rust
cargo test    # Run 42 tests
cargo build --release
```

### Go Management API
```bash
cd anti-call-masking-platform
go mod tidy
go test ./...
```

### Python SIP Processor
```bash
cd sip-processor
pip install -r requirements.txt
pytest tests/
```

## Documentation

See the root [README.md](../README.md) for full documentation.
