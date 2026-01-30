# VoxGuard - Voice Network Fraud Detection Platform

This directory contains the core VoxGuard platform components.

## Components

| Directory | Language | Description |
|-----------|----------|-------------|
| `frontend/` | TypeScript | Admin Dashboard (Refine + Ant Design + GraphQL) |
| `database/` | SQL | YugabyteDB schema and migrations |
| `detection-service-rust/` | Rust | High-performance fraud detection engine |
| `management-api/` | Go | Management API with DDD bounded contexts |
| `sip-processor/` | Python | SIP message processing and inference |

## Quick Start

### Frontend Dashboard
```bash
cd frontend
npm install
npm run dev
# Open http://localhost:3000
```

### Docker Compose (Full Stack)
```bash
docker-compose up -d
# Services: YugabyteDB, Hasura, ClickHouse, QuestDB, etc.
```

### Hasura Console
```bash
open http://localhost:8082/console
# Admin secret: see .env file
```

## Demo Accounts

| Email | Password | Role |
|-------|----------|------|
| admin@acm.com | demo123 | Admin |
| analyst@acm.com | demo123 | Analyst |
| developer@acm.com | demo123 | Developer |
| viewer@acm.com | demo123 | Viewer |

## Documentation

See the root [README.md](../README.md) for full documentation.
