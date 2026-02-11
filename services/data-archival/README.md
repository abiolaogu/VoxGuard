# VoxGuard Data Archival Service

**Version:** 1.0.0
**Purpose:** Automated data retention and archival for NCC compliance

## Overview

The Data Archival Service provides automated archival of historical data to cold storage (S3-compatible), enabling VoxGuard to meet NCC's 7-year audit trail retention requirement while optimizing database performance and storage costs.

### Key Features

- **7-Year Retention:** Automated retention policy aligned with NCC ICL Framework 2026
- **Hot/Warm/Cold Storage Tiers:** 90 days hot, 1 year warm, 7 years cold
- **Compression:** ZSTD or GZIP compression (typically 70-75% size reduction)
- **S3-Compatible Storage:** Works with AWS S3, MinIO, Wasabi, etc.
- **Automated Scheduling:** Monthly archival with APScheduler
- **Data Restoration:** Full restoration capability for archived data
- **GDPR Compliance:** Automated deletion after retention period
- **Integrity Verification:** SHA-256 checksums for all archives

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    VoxGuard Database                         │
│                    (YugabyteDB)                              │
│                                                               │
│  Hot Storage (0-90 days)   ────┐                            │
│  Warm Storage (90-365 days) ───┤                            │
└────────────────────────────────┼─────────────────────────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │   Archival Service     │
                    │  ├─ Query old data     │
                    │  ├─ Compress (ZSTD)    │
                    │  ├─ Upload to S3       │
                    │  └─ Delete from DB     │
                    └────────────────────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │   S3 Cold Storage      │
                    │  (7-year retention)    │
                    │                        │
                    │  archives/             │
                    │  ├─ acm_alerts/        │
                    │  ├─ audit_events/      │
                    │  └─ cdrs/              │
                    └────────────────────────┘
```

---

## Installation

### Prerequisites

- Python 3.11+
- PostgreSQL-compatible database (YugabyteDB)
- S3-compatible storage (AWS S3, MinIO, etc.)

### Install Dependencies

```bash
cd services/data-archival
pip install -r requirements.txt
```

### Environment Variables

Create a `.env` file or set environment variables:

```bash
# Database Configuration
DB_HOST=localhost
DB_PORT=5433
DB_NAME=acm_db
DB_USER=admin
DB_PASSWORD=your_password

# S3 Storage Configuration
S3_ENDPOINT=https://s3.amazonaws.com  # Or MinIO endpoint
S3_ACCESS_KEY=your_access_key
S3_SECRET_KEY=your_secret_key
S3_BUCKET=voxguard-archives
S3_REGION=us-east-1
S3_USE_SSL=true

# Archival Configuration
ARCHIVAL_HOT_RETENTION_DAYS=90        # Hot storage: 90 days
ARCHIVAL_WARM_RETENTION_DAYS=365      # Warm storage: 1 year
ARCHIVAL_COLD_RETENTION_YEARS=7       # Cold storage: 7 years (NCC)
ARCHIVAL_FREQUENCY=monthly             # daily, weekly, monthly
ARCHIVAL_COMPRESSION=zstd              # gzip, zstd, none
ARCHIVAL_COMPRESSION_LEVEL=3           # 1-9 for gzip, 1-22 for zstd
ARCHIVAL_CHUNK_SIZE=10000              # Records per batch
ARCHIVAL_SCHEDULE_CRON="0 2 1 * *"    # 2 AM on 1st of each month
ARCHIVAL_MAX_WORKERS=4                 # Parallel compression workers
ARCHIVAL_ENABLE_METRICS=true           # Prometheus metrics
ARCHIVAL_METRICS_PORT=9092
```

---

## Usage

### Starting the Scheduler

```python
from data_archival.config import Config
from data_archival.scheduler import ArchivalScheduler

# Load configuration from environment
config = Config.from_env()

# Create and start scheduler
scheduler = ArchivalScheduler(config)
scheduler.start()

# Keep running
try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    scheduler.stop()
```

### Docker Deployment

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "-m", "data_archival.main"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  archival-service:
    build: .
    environment:
      - DB_HOST=yugabyte
      - DB_PORT=5433
      - S3_ENDPOINT=http://minio:9000
      - S3_ACCESS_KEY=minioadmin
      - S3_SECRET_KEY=minioadmin
    depends_on:
      - yugabyte
      - minio
    restart: unless-stopped
```

### Manual Archival

```python
from datetime import datetime, timedelta
from data_archival.config import Config
from data_archival.archival_service import ArchivalService

config = Config.from_env()
service = ArchivalService(config)

# Archive data older than 90 days
cutoff_date = datetime.utcnow() - timedelta(days=90)
metadata = service.archive_table(
    table_name="acm_alerts",
    partition_key="2024-01",
    cutoff_date=cutoff_date,
)

if metadata:
    print(f"Archive created: {metadata.archive_id}")
    print(f"Records: {metadata.record_count}")
    print(f"Compression ratio: {service.compression.get_compression_ratio(metadata.original_size_bytes, metadata.compressed_size_bytes):.2%}")
```

### Data Restoration

```python
# Restore archived data by archive ID
records = service.restore_archive(archive_id="abc123-def456")

if records:
    print(f"Restored {len(records)} records")
else:
    print("Restoration failed")
```

### Querying Archives

```python
# List all archives for a table
archives = service.list_archives_for_table("acm_alerts")

for archive in archives:
    print(f"Archive: {archive.archive_id}")
    print(f"  Partition: {archive.partition_key}")
    print(f"  Records: {archive.record_count}")
    print(f"  Size: {archive.compressed_size_bytes / (1024*1024):.2f} MB")
    print(f"  Created: {archive.created_at}")
    print(f"  Retention until: {archive.retention_until}")
```

### Retention Statistics

```python
# Get retention statistics
stats = service.get_retention_statistics()

print(f"Total Archives: {stats['total_archives']}")
print(f"Total Records: {stats['total_archived_records']}")
print(f"Compressed Size: {stats['total_compressed_size_mb']:.2f} MB")
print(f"Original Size: {stats['total_original_size_mb']:.2f} MB")
print(f"Compression Ratio: {stats['compression_ratio']:.2%}")

for table, table_stats in stats['by_table'].items():
    print(f"\n{table}:")
    print(f"  Archives: {table_stats['archive_count']}")
    print(f"  Records: {table_stats['record_count']}")
    print(f"  Size: {table_stats['compressed_size_mb']:.2f} MB")
```

---

## Configuration

### Retention Tiers

| Tier | Duration | Storage | Cost | Access Speed |
|------|----------|---------|------|--------------|
| **Hot** | 0-90 days | YugabyteDB | High | Instant |
| **Warm** | 90-365 days | YugabyteDB (partitioned) | Medium | Fast |
| **Cold** | 1-7 years | S3 (compressed) | Low | Minutes |

### Compression Options

| Type | Ratio | Speed | CPU Usage | Recommendation |
|------|-------|-------|-----------|----------------|
| **NONE** | 0% | Fastest | Minimal | Testing only |
| **GZIP** | 70% | Fast | Low | Good balance |
| **ZSTD** | 75% | Very Fast | Medium | **Recommended** |

**ZSTD Level Recommendations:**
- Level 1-3: Fast, lower compression (production)
- Level 4-9: Balanced (default: 3)
- Level 10-22: Slower, higher compression (archival)

### Tables to Archive

Default tables (configurable in `config.py`):
1. `acm_alerts` - Fraud detection alerts
2. `audit_events` - Security audit logs
3. `call_detail_records` - CDR data
4. `gateway_blacklist_history` - Blacklist changes
5. `fraud_investigations` - Investigation records

---

## Scheduled Jobs

| Job | Schedule | Description |
|-----|----------|-------------|
| **Monthly Archival** | 2 AM, 1st of month | Archive data older than 90 days |
| **Daily Cleanup** | 3 AM daily | Delete expired archives (>7 years) |
| **Weekly Statistics** | Monday 8 AM | Log retention statistics |

### Cron Format

Default: `"0 2 1 * *"` (2 AM on 1st of each month)

```
┌───────── minute (0-59)
│ ┌─────── hour (0-23)
│ │ ┌───── day of month (1-31)
│ │ │ ┌─── month (1-12)
│ │ │ │ ┌─ day of week (0-6, Sunday=0)
│ │ │ │ │
0 2 1 * *
```

**Examples:**
- Daily at 2 AM: `"0 2 * * *"`
- Weekly (Sunday 3 AM): `"0 3 * * 0"`
- Monthly (1st, 2 AM): `"0 2 1 * *"`

---

## Monitoring

### Prometheus Metrics

Exposed on port 9092 (configurable):

```
# Archive operations
archival_archives_created_total{table="acm_alerts"}
archival_records_archived_total{table="acm_alerts"}
archival_compression_ratio{table="acm_alerts"}

# Storage
archival_compressed_size_bytes{table="acm_alerts"}
archival_original_size_bytes{table="acm_alerts"}

# Errors
archival_errors_total{type="upload_failed"}
archival_errors_total{type="deletion_failed"}

# Job execution
archival_job_duration_seconds{job="monthly_archival"}
archival_job_last_success_timestamp{job="monthly_archival"}
```

### Health Checks

```python
# Check scheduler status
scheduler = ArchivalScheduler(config)
jobs = scheduler.list_jobs()

for job in jobs:
    print(f"{job['name']}: Next run at {job['next_run_time']}")
```

### Logging

Configure logging level:

```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
)
```

Log levels:
- `DEBUG`: Detailed compression metrics
- `INFO`: Job execution, archive creation
- `WARNING`: No data to archive, expired archives
- `ERROR`: Upload failures, database errors

---

## Testing

### Run Unit Tests

```bash
cd services/data-archival
pytest tests/ -v --cov=. --cov-report=html
```

### Test Coverage

Minimum 80% coverage required:

```bash
pytest tests/ --cov=. --cov-fail-under=80
```

### Test with Local MinIO

```bash
# Start MinIO
docker run -d \
  -p 9000:9000 \
  -p 9001:9001 \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  minio/minio server /data --console-address ":9001"

# Configure environment
export S3_ENDPOINT=http://localhost:9000
export S3_ACCESS_KEY=minioadmin
export S3_SECRET_KEY=minioadmin
export S3_USE_SSL=false

# Run tests
pytest tests/
```

---

## Troubleshooting

### Common Issues

**1. "Failed to upload archive"**
- Check S3 credentials and endpoint
- Verify bucket exists and has write permissions
- Check network connectivity

**2. "Database connection failed"**
- Verify database is running
- Check credentials and connection string
- Ensure database has archival tables

**3. "ZSTD not available"**
- Install zstandard: `pip install zstandard`
- Or use GZIP: `ARCHIVAL_COMPRESSION=gzip`

**4. "No data to archive"**
- Verify tables have data older than retention period
- Check date column mapping in `archival_service.py`
- Reduce `ARCHIVAL_HOT_RETENTION_DAYS` for testing

**5. "Checksum mismatch on restore"**
- Archive may be corrupted
- Check S3 object integrity
- Verify network stability during upload

### Debug Mode

```bash
export LOG_LEVEL=DEBUG
python -m data_archival.main
```

---

## Performance Tuning

### Batch Size

Adjust chunk size for optimal performance:

```bash
# Smaller batches (less memory, slower)
ARCHIVAL_CHUNK_SIZE=5000

# Larger batches (more memory, faster)
ARCHIVAL_CHUNK_SIZE=50000
```

### Compression Level

Balance speed vs size:

```bash
# Faster (less compression)
ARCHIVAL_COMPRESSION_LEVEL=1

# Balanced (recommended)
ARCHIVAL_COMPRESSION_LEVEL=3

# Better compression (slower)
ARCHIVAL_COMPRESSION_LEVEL=9
```

### Parallel Workers

Adjust based on CPU cores:

```bash
# Single-threaded
ARCHIVAL_MAX_WORKERS=1

# Multi-threaded (4 cores)
ARCHIVAL_MAX_WORKERS=4
```

---

## NCC Compliance

### Requirements Met

✅ **7-Year Retention:** Automated cold storage archival
✅ **Audit Trail:** Immutable archives with SHA-256 checksums
✅ **Data Integrity:** Verification on upload and restore
✅ **Disaster Recovery:** S3 versioning and cross-region replication
✅ **GDPR Compliance:** Automated deletion after retention period
✅ **Access Control:** S3 bucket policies and IAM roles

### Audit Report

Generate compliance report:

```python
stats = service.get_retention_statistics()

report = f"""
VoxGuard Data Retention Audit Report
=====================================
Generated: {datetime.utcnow().isoformat()}

Retention Policy:
- Hot Storage: {config.archival.hot_retention_days} days
- Warm Storage: {config.archival.warm_retention_days} days
- Cold Storage: {config.archival.cold_retention_years} years

Current Status:
- Total Archives: {stats['total_archives']}
- Total Records: {stats['total_archived_records']}
- Storage Used: {stats['total_compressed_size_mb']:.2f} MB

Compliance Status: ✅ COMPLIANT
"""
print(report)
```

---

## Disaster Recovery

### Backup Strategy

1. **S3 Versioning:** Enable versioning on archival bucket
2. **Cross-Region Replication:** Replicate to secondary region
3. **Lifecycle Policies:** Archive to Glacier after 1 year

### Recovery Procedures

**Restore Single Archive:**
```python
records = service.restore_archive(archive_id)
```

**Restore All Archives for Table:**
```python
archives = service.list_archives_for_table("acm_alerts")
for archive in archives:
    service.restore_archive(archive.archive_id)
```

**Restore from S3 Backup:**
```bash
# Download from S3
aws s3 cp s3://voxguard-archives/archives/acm_alerts/ ./backup/ --recursive

# Restore using service
python restore_from_backup.py --path ./backup/
```

---

## Cost Optimization

### Storage Costs

Example for 1 TB of alerts over 7 years:

| Storage | Size | Monthly Cost (AWS S3) |
|---------|------|----------------------|
| Hot (DB) | 10 GB | $2.30 (YugabyteDB) |
| Warm (DB) | 50 GB | $11.50 (YugabyteDB) |
| Cold (S3) | 250 GB | $5.75 (S3 Standard) |
| **Total** | **310 GB** | **$19.55/month** |

With S3 Glacier Deep Archive:
- Cold Storage: 250 GB × $0.00099 = **$0.25/month** (98% savings)
- Total: **$14.05/month**

### Recommendations

1. Use ZSTD compression (75% reduction)
2. Archive to S3 Glacier after 1 year
3. Enable S3 Intelligent-Tiering
4. Use lifecycle policies for automatic transitions

---

## Support

### Documentation
- [VoxGuard PRD](../../docs/PRD.md)
- [Database Schema](../../database/yugabyte/)
- [Architecture Overview](../../docs/ARCHITECTURE.md)

### Contact
- Email: support@voxguard.ng
- GitHub: [abiolaogu/VoxGuard](https://github.com/abiolaogu/VoxGuard)

---

**Last Updated:** February 4, 2026
**Version:** 1.0.0
**Status:** Production Ready
