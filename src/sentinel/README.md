# Sentinel: Anti-Call Masking Analysis Engine

## Overview

Sentinel is the high-performance batch processing and historical analysis engine for the Anti-Call Masking Platform. It complements the real-time SIP signaling analysis by providing deep insights from Call Detail Records (CDR) and detecting fraud patterns that emerge over time.

## Architecture Position

```
┌──────────────────────────────────────────────────────────┐
│                    Factory Ecosystem                      │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  ┌─────────────────┐      ┌──────────────────┐          │
│  │  sip-processor  │◄────►│  Sentinel Engine │          │
│  │   (Real-time)   │      │  (Batch/History) │          │
│  └────────┬────────┘      └─────────┬────────┘          │
│           │                          │                    │
│           └──────────┬───────────────┘                   │
│                      ▼                                    │
│              ┌──────────────┐                            │
│              │    lumadb    │                            │
│              │ (PostgreSQL) │                            │
│              └──────────────┘                            │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

## Key Responsibilities

1. **CDR Batch Ingestion**
   - Parse and validate CSV files containing call detail records
   - Handle large files (up to 1M records) efficiently
   - Store normalized data in the shared database

2. **Pattern Detection**
   - Identify SIM Box fraud through Short Duration High Frequency (SDHF) analysis
   - Detect geographic routing anomalies
   - Flag behavioral changes in caller patterns

3. **Alert Generation**
   - Create actionable fraud alerts with confidence scores
   - Store evidence for analyst review
   - Integrate with notification systems

4. **Real-time Event Processing**
   - Accept incoming call events from external systems
   - Perform immediate risk scoring
   - Trigger alerts when thresholds are exceeded

## Integration with Factory Components

### With `anti-call-masking/sip-processor/`
- **Complementary Analysis:** sip-processor handles live SIP signaling; Sentinel analyzes historical patterns
- **Shared Database:** Both write to the same fraud detection tables
- **Cross-referencing:** Sentinel can enrich sip-processor alerts with historical context

### With `anti-call-masking/lumadb/`
- **Database Abstraction:** Use lumadb's connection pooling and query builders
- **Migration Integration:** Sentinel's tables follow lumadb's migration conventions
- **Transaction Management:** Leverage existing transaction patterns for consistency

### With Factory CI/CD
- **Tier Classification:** This module is Tier 1 (Features/Logic) → Requires review before merge
- **Testing:** Follows universal test framework (`scripts/universal/universal_test.py`)
- **Deployment:** Integrates with existing Docker Compose stack

## Module Structure

```
src/sentinel/
├── README.md              (This file)
├── main.py                (Entry point, FastAPI app initialization)
├── config.py              (Configuration management)
├── ingestion/
│   ├── __init__.py
│   ├── parser.py          (CDR CSV parsing logic)
│   └── validator.py       (Data validation rules)
├── detection/
│   ├── __init__.py
│   ├── rules.py           (Detection rule definitions)
│   └── sdhf.py            (Short Duration High Frequency detector)
├── database/
│   ├── __init__.py
│   ├── models.py          (SQLAlchemy models)
│   └── migrations/        (Database migration files)
└── api/
    ├── __init__.py
    ├── routes.py          (API endpoints)
    └── schemas.py         (Pydantic request/response models)
```

## Quick Start

### Prerequisites
```bash
# Ensure you have Python 3.10+ and dependencies installed
pip install -r requirements.txt
```

### Running Locally
```bash
# From repository root
cd src/sentinel
uvicorn main:app --reload --host 0.0.0.0 --port 8001
```

### API Documentation
Once running, visit:
- Swagger UI: `http://localhost:8001/docs`
- ReDoc: `http://localhost:8001/redoc`

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/api/v1/sentinel/ingest` | POST | Upload CDR CSV file |
| `/api/v1/sentinel/detect/sdhf` | POST | Run SDHF detection |
| `/api/v1/sentinel/events/call` | POST | Submit real-time call event |
| `/api/v1/sentinel/alerts` | GET | List fraud alerts |
| `/api/v1/sentinel/alerts/{id}` | PATCH | Update alert status |

## Database Tables

Sentinel creates and manages:
- `call_records` - Normalized CDR data
- `suspicious_patterns` - Detected fraud patterns
- `sentinel_fraud_alerts` - Actionable alerts for review

See `docs/product/prds/sentinel-anti-masking.md` for detailed schema definitions.

## Development Workflow

1. **Feature Development**
   - Follow "vibe coding" principles (speed is life)
   - Write tests alongside implementation
   - Use type hints (Python 3.10+ syntax)

2. **Testing**
   ```bash
   pytest tests/sentinel/
   ```

3. **Code Quality**
   ```bash
   # Run universal linter
   python scripts/universal/universal_lint.py
   ```

4. **Database Migrations**
   ```bash
   # Create new migration
   alembic revision -m "description"

   # Apply migrations
   alembic upgrade head
   ```

## Performance Considerations

- **Batch Processing:** Use Polars for dataframe operations (faster than Pandas)
- **Database Queries:** Leverage PostgreSQL indexes on (`caller_number`, `call_timestamp`)
- **Memory Management:** Stream large CSV files in chunks (10K rows at a time)
- **Concurrency:** FastAPI's async endpoints handle concurrent requests efficiently

## Security

- **API Authentication:** All endpoints require JWT bearer tokens (except `/health`)
- **Rate Limiting:** 100 requests/minute per API key
- **Input Validation:** All inputs validated via Pydantic schemas
- **SQL Injection Prevention:** Use parameterized queries only

## Monitoring

Key metrics exposed:
- `sentinel_cdr_records_processed_total` - Total records ingested
- `sentinel_alerts_generated_total` - Alerts created by type
- `sentinel_api_request_duration_seconds` - API latency
- `sentinel_detection_scan_duration_seconds` - Analysis performance

## Contributing

1. Create issues using the Factory issue templates
2. Assign issues to `@copilot` for automated implementation
3. Follow the Assembly Line tiers for merge approvals
4. Security/Infrastructure changes require admin approval

## Related Documentation

- [Product Requirements Document](../../docs/product/prds/sentinel-anti-masking.md)
- [Developer Manual](../../docs/DEVELOPER_MANUAL.md)
- [Copilot Playbook](../../docs/COPILOT_PLAYBOOK.md)
- [Factory Constitution](../../CLAUDE.md)

## Support

For questions or issues:
1. Check existing GitHub issues
2. Review the Developer Manual
3. Create a new issue with `@claude` mention

---

**Status:** Active Development
**Owner:** BillyRonks Global
**Version:** 1.0.0
**Last Updated:** 2026-01-22
