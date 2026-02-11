# NCC Integration Service

Automated compliance reporting and ATRS API integration for the Nigerian Communications Commission (NCC).

## Overview

This service handles all NCC compliance automation requirements as specified in PRD Section P0-2:

- ✅ **ATRS API Client**: OAuth 2.0 authentication and real-time incident reporting
- ✅ **SFTP CDR Uploader**: Automated daily uploads to NCC servers
- ✅ **Report Generator**: NCC-compliant CSV and JSON report generation
- ✅ **Compliance Scheduler**: Automated daily, weekly, and monthly report submission

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                  NCC Integration Service                     │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────┐      ┌─────────────────┐              │
│  │   Scheduler    │─────▶│ Report Generator│              │
│  │  (APScheduler) │      │   (PostgreSQL)  │              │
│  └────────────────┘      └─────────────────┘              │
│         │                         │                         │
│         ▼                         ▼                         │
│  ┌────────────────┐      ┌─────────────────┐              │
│  │ ATRS API Client│      │  SFTP Uploader  │              │
│  │  (OAuth 2.0)   │      │   (Paramiko)    │              │
│  └────────────────┘      └─────────────────┘              │
│         │                         │                         │
└─────────┼─────────────────────────┼─────────────────────────┘
          │                         │
          ▼                         ▼
    ┌──────────┐            ┌──────────────┐
    │   ATRS   │            │   NCC SFTP   │
    │   API    │            │    Server    │
    └──────────┘            └──────────────┘
```

## Features

### 1. Real-Time Incident Reporting

Automatically submits fraud incidents to NCC ATRS API:

```python
from ncc_integration import AtrsClient, IncidentType, Severity

async with AtrsClient(config.atrs) as client:
    response = await client.submit_incident(
        incident_type=IncidentType.CLI_SPOOFING,
        severity=Severity.CRITICAL,
        detected_at=datetime.utcnow(),
        b_number="+2348012345678",
        a_numbers=["+2347011111111", "+2347022222222"],
        detection_window_ms=4200,
        source_ips=["192.168.1.100"],
        actions_taken=["CALLS_DISCONNECTED"],
    )
    print(f"Incident ID: {response['incident_id']}")
```

### 2. Daily Report Automation

Generates and submits reports daily at 05:30 WAT:

- `ACM_DAILY_{LICENSE}_{YYYYMMDD}.csv` - Statistics
- `ACM_ALERTS_{LICENSE}_{YYYYMMDD}.csv` - Alert details
- `ACM_TARGETS_{LICENSE}_{YYYYMMDD}.csv` - Top targets
- `ACM_SUMMARY_{LICENSE}_{YYYYMMDD}.json` - JSON summary with SHA-256 checksum

### 3. SFTP Upload

Secure SFTP uploads with:
- SSH key authentication
- Atomic file transfers (temp → final)
- Upload verification
- Automatic retry on failure

### 4. Compliance Scheduler

Automated scheduling for:
- **Daily reports**: 05:30 WAT (due 06:00 WAT)
- **Weekly reports**: Monday 11:00 WAT (due 12:00 WAT)
- **Monthly reports**: 5th at 16:00 WAT (due 18:00 WAT)

## Installation

```bash
cd services/ncc-integration
pip install -r requirements.txt
```

## Configuration

Set the following environment variables:

### ATRS API Configuration

```bash
# Environment (sandbox or production)
export NCC_ENVIRONMENT=sandbox

# OAuth 2.0 Credentials
export NCC_CLIENT_ID=your-client-id
export NCC_CLIENT_SECRET=your-client-secret
export NCC_ICL_LICENSE=ICL-NG-2025-001234
```

### SFTP Configuration

```bash
export NCC_SFTP_HOST=sftp.ncc.gov.ng
export NCC_SFTP_PORT=22
export NCC_SFTP_USER=ncc_upload
export NCC_SFTP_KEY_PATH=/etc/ncc/id_rsa
```

### Database Configuration

```bash
export POSTGRES_HOST=localhost
export POSTGRES_PORT=5432
export POSTGRES_DB=voxguard
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=your-password
```

### Scheduler Configuration

```bash
# Cron expressions (default shown)
export NCC_DAILY_CRON="30 4 * * *"      # 05:30 WAT (04:30 UTC)
export NCC_WEEKLY_CRON="0 10 * * MON"   # Monday 11:00 WAT
export NCC_MONTHLY_CRON="0 15 5 * *"    # 5th at 16:00 WAT
export NCC_TIMEZONE="Africa/Lagos"
```

## Usage

### Running the Scheduler

```bash
python -m ncc_integration.scheduler
```

### Manual Report Generation

```python
from datetime import date
from ncc_integration import ComplianceScheduler, ComplianceConfig

config = ComplianceConfig.from_env()
scheduler = ComplianceScheduler(config)

# Trigger daily report for yesterday
await scheduler.trigger_daily_report()

# Trigger report for specific date
await scheduler.trigger_daily_report(date(2026, 1, 28))
```

### Direct API Usage

```python
from ncc_integration import AtrsClient, AtrsConfig

config = AtrsConfig.from_env()

async with AtrsClient(config) as client:
    # Check health
    healthy = await client.health_check()

    # Submit incident
    response = await client.submit_incident(...)

    # Query incident status
    incident = await client.get_incident("NCC-2026-01-0001234")

    # Submit daily report
    await client.submit_daily_report(
        report_date="2026-01-28",
        statistics={...},
        top_targeted_numbers=[...],
        checksum="sha256:...",
    )
```

## Testing

Run the test suite:

```bash
pytest tests/ -v --cov=ncc_integration
```

## NCC Compliance Status

| Requirement | Status | Evidence |
|-------------|--------|----------|
| ATRS API client | ✅ Complete | `atrs_client.py` |
| OAuth 2.0 authentication | ✅ Complete | Auto-refresh with 60s buffer |
| Daily SFTP uploads | ✅ Complete | `sftp_uploader.py` |
| Report generation | ✅ Complete | `report_generator.py` |
| Automated scheduling | ✅ Complete | `scheduler.py` |
| SHA-256 checksums | ✅ Complete | All reports include checksums |
| Audit trail | ✅ Complete | Comprehensive logging |
| Retry logic | ✅ Complete | Exponential backoff |
| Rate limiting | ✅ Complete | 429 handling with backoff |

## Documentation

- [NCC API Integration Guide](../../docs/ncc/NCC_API_INTEGRATION.md)
- [NCC Compliance Specification](../../docs/ncc/NCC_COMPLIANCE_SPECIFICATION.md)
- [NCC Reporting Requirements](../../docs/ncc/NCC_REPORTING_REQUIREMENTS.md)

## Architecture Notes

### OAuth Token Management

- Tokens refresh automatically 60 seconds before expiry
- Thread-safe token storage
- Automatic retry on 401 errors

### SFTP Upload Strategy

- Atomic transfers using temp files
- Size verification before final rename
- Connection pooling for batch uploads

### Report Generation

- Queries PostgreSQL for CDR statistics
- Generates NCC-compliant CSV files
- Calculates SHA-256 checksums
- JSON summaries with all metadata

### Error Handling

- Exponential backoff for transient errors
- Rate limit detection and handling
- Comprehensive logging for audit trail
- Failure notifications (TODO: integrate with alerting system)

## Future Enhancements

- [ ] Weekly report aggregation (currently placeholder)
- [ ] Monthly report with PDF generation
- [ ] Webhook endpoint for NCC notifications
- [ ] Integration with monitoring/alerting system
- [ ] Support for incident follow-up reports
- [ ] Cross-operator query support

## License

Confidential - VoxGuard Internal Use Only
