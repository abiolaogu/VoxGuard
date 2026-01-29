# NCC Database Connections & Data Exchange
## Anti-Call Masking Detection System

**Version:** 1.0
**Last Updated:** January 2026
**Classification:** Confidential

---

## Table of Contents

1. [Overview](#1-overview)
2. [SFTP Connection](#2-sftp-connection)
3. [Data Formats](#3-data-formats)
4. [Field Mappings](#4-field-mappings)
5. [Data Transformation](#5-data-transformation)
6. [Upload Procedures](#6-upload-procedures)
7. [Error Handling](#7-error-handling)
8. [Monitoring & Alerts](#8-monitoring--alerts)
9. [Security Configuration](#9-security-configuration)

---

## 1. Overview

### 1.1 Purpose

This document describes the technical details for connecting to NCC systems, data format specifications, and field mappings for regulatory report submissions.

### 1.2 Connection Types

| Connection | Protocol | Purpose | Frequency |
|------------|----------|---------|-----------|
| NCC SFTP | SFTP/SSH | Daily report uploads | Daily |
| ATRS API | HTTPS/REST | Real-time incident reporting | Real-time |
| NCC Portal | HTTPS | Annual compliance submission | Annual |

### 1.3 System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     Anti-Call Masking Platform                          │
│                                                                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────────────┐  │
│  │  QuestDB    │───▶│   Report    │───▶│   NCC Uploader Service     │  │
│  │  ClickHouse │    │  Generator  │    │   (ncc-sftp-uploader)      │  │
│  │  YugabyteDB │    │             │    │                            │  │
│  └─────────────┘    └─────────────┘    └─────────────┬───────────────┘  │
│                                                       │                 │
└───────────────────────────────────────────────────────┼─────────────────┘
                                                        │
                          ┌─────────────────────────────┼────────────────┐
                          │                             │                │
                          ▼                             ▼                │
              ┌─────────────────────┐      ┌─────────────────────┐       │
              │   NCC SFTP Server   │      │   NCC ATRS API      │       │
              │   sftp.ncc.gov.ng   │      │ atrs-api.ncc.gov.ng │       │
              │   Port 22           │      │   Port 443          │       │
              └─────────────────────┘      └─────────────────────┘       │
                                                                         │
```

---

## 2. SFTP Connection

### 2.1 Connection Details

| Parameter | Production | Sandbox |
|-----------|------------|---------|
| Host | sftp.ncc.gov.ng | sftp-sandbox.ncc.gov.ng |
| Port | 22 | 22 |
| Protocol | SFTP over SSH | SFTP over SSH |
| Authentication | SSH Key (RSA 4096-bit) | SSH Key |
| Connection Timeout | 30 seconds | 30 seconds |
| Transfer Timeout | 300 seconds | 300 seconds |

### 2.2 Directory Structure

```
/incoming/
└── {ICL_LICENSE}/
    ├── daily/
    │   ├── YYYYMMDD/
    │   │   ├── ACM_DAILY_{LICENSE}_{DATE}.csv
    │   │   ├── ACM_ALERTS_{LICENSE}_{DATE}.csv
    │   │   ├── ACM_TARGETS_{LICENSE}_{DATE}.csv
    │   │   └── ACM_SUMMARY_{LICENSE}_{DATE}.json
    │   └── archive/
    ├── weekly/
    │   └── YYYY-WW/
    │       └── ACM_WEEKLY_{LICENSE}_{YEAR}-{WEEK}.json
    ├── monthly/
    │   └── YYYY-MM/
    │       ├── ACM_MONTHLY_{LICENSE}_{YEAR}-{MONTH}.json
    │       └── ACM_MONTHLY_{LICENSE}_{YEAR}-{MONTH}.pdf
    └── incidents/
        └── {INCIDENT_ID}/
            └── incident_files...
```

### 2.3 SSH Key Setup

```bash
# Generate SSH key pair (if not already done)
ssh-keygen -t rsa -b 4096 -f ncc_sftp_key -C "acm-upload@yourcompany.com"

# Key file permissions
chmod 600 ncc_sftp_key
chmod 644 ncc_sftp_key.pub

# Send public key to NCC for registration
# The public key (ncc_sftp_key.pub) must be registered with NCC
```

### 2.4 Connection Configuration

```yaml
# config/ncc-sftp.yaml
sftp:
  host: sftp.ncc.gov.ng
  port: 22
  username: ${NCC_SFTP_USER}
  private_key_path: /etc/acm/keys/ncc_sftp_key
  known_hosts_path: /etc/acm/keys/known_hosts
  connection_timeout: 30
  transfer_timeout: 300
  retry_attempts: 3
  retry_delay: 60  # seconds
  directories:
    daily: "/incoming/${NCC_ICL_LICENSE}/daily"
    weekly: "/incoming/${NCC_ICL_LICENSE}/weekly"
    monthly: "/incoming/${NCC_ICL_LICENSE}/monthly"
    incidents: "/incoming/${NCC_ICL_LICENSE}/incidents"
```

### 2.5 Known Hosts

```bash
# Add NCC SFTP server to known_hosts
ssh-keyscan -t rsa sftp.ncc.gov.ng >> /etc/acm/keys/known_hosts

# Verify fingerprint matches NCC-provided value
# NCC will provide the expected fingerprint during onboarding
```

---

## 3. Data Formats

### 3.1 CSV Specifications

| Attribute | Specification |
|-----------|---------------|
| Encoding | UTF-8 (no BOM) |
| Delimiter | Comma (,) |
| Quote Character | Double quote (") |
| Escape Character | Double quote (") |
| Line Ending | LF (\n) or CRLF (\r\n) |
| Header | Required, first row |
| Null Values | Empty field (,,) |

### 3.2 JSON Specifications

| Attribute | Specification |
|-----------|---------------|
| Encoding | UTF-8 |
| Date/Time | ISO 8601 with timezone (Z or +00:00) |
| Numbers | No quotes, use decimal point |
| Booleans | lowercase (true, false) |
| Null | JSON null keyword |
| Arrays | Square brackets [] |
| Objects | Curly braces {} |

### 3.3 File Naming Convention

```
ACM_{REPORT_TYPE}_{ICL_LICENSE}_{DATE_COMPONENT}.{EXTENSION}

Examples:
- ACM_DAILY_ICL-NG-2025-001234_20260128.csv
- ACM_ALERTS_ICL-NG-2025-001234_20260128.csv
- ACM_WEEKLY_ICL-NG-2025-001234_2026-W04.json
- ACM_MONTHLY_ICL-NG-2025-001234_2026-01.json
```

---

## 4. Field Mappings

### 4.1 Daily Statistics Mapping

| ACM Internal Field | NCC Field Name | NCC Data Type | Format |
|--------------------|----------------|---------------|--------|
| `stats.calls_processed` | `total_calls_processed` | INTEGER | No separator |
| `stats.alerts.total` | `total_fraud_alerts` | INTEGER | No separator |
| `stats.alerts.critical` | `critical_alerts` | INTEGER | No separator |
| `stats.alerts.high` | `high_alerts` | INTEGER | No separator |
| `stats.alerts.medium` | `medium_alerts` | INTEGER | No separator |
| `stats.alerts.low` | `low_alerts` | INTEGER | No separator |
| `stats.disconnected` | `calls_disconnected` | INTEGER | No separator |
| `metrics.latency_p99` | `detection_latency_p99` | DECIMAL(10,2) | Milliseconds |
| `metrics.latency_avg` | `detection_latency_avg` | DECIMAL(10,2) | Milliseconds |
| `metrics.uptime` | `system_uptime` | DECIMAL(5,3) | Percentage |
| `metrics.false_positive` | `false_positive_rate` | DECIMAL(5,2) | Percentage |

### 4.2 Alert Details Mapping

| ACM Internal Field | NCC Field Name | NCC Data Type | Format |
|--------------------|----------------|---------------|--------|
| `alert.id` | `alert_id` | VARCHAR(64) | Internal ID |
| `alert.detected_at` | `detected_at` | TIMESTAMP | ISO 8601 |
| `alert.severity` | `severity` | ENUM | CRITICAL/HIGH/MEDIUM/LOW |
| `alert.b_number` | `b_number` | VARCHAR(20) | E.164 with + |
| `alert.a_numbers.length` | `a_number_count` | INTEGER | Count |
| `alert.window_ms` | `detection_window_ms` | INTEGER | Milliseconds |
| `alert.action` | `action_taken` | ENUM | DISCONNECTED/BLOCKED/NONE |
| `alert.ncc_id` | `ncc_incident_id` | VARCHAR(64) | NCC reference |

### 4.3 Phone Number Formatting

```python
def format_phone_for_ncc(phone: str) -> str:
    """
    Convert phone number to NCC-required E.164 format.

    Input formats accepted:
    - +2348012345678 (already E.164)
    - 2348012345678 (missing +)
    - 08012345678 (local format)
    - 8012345678 (no prefix)

    Output: +2348012345678
    """
    # Remove any non-digit characters except +
    cleaned = ''.join(c for c in phone if c.isdigit() or c == '+')

    # If starts with +, assume correct format
    if cleaned.startswith('+'):
        return cleaned

    # If starts with 234, add +
    if cleaned.startswith('234'):
        return '+' + cleaned

    # If starts with 0, replace with +234
    if cleaned.startswith('0'):
        return '+234' + cleaned[1:]

    # Otherwise, assume Nigerian number and add +234
    return '+234' + cleaned
```

### 4.4 Severity Mapping

| ACM Severity | NCC Severity | Description |
|--------------|--------------|-------------|
| `critical` | `CRITICAL` | 7+ A-numbers, immediate action |
| `high` | `HIGH` | 5-6 A-numbers, quick response |
| `medium` | `MEDIUM` | 3-4 A-numbers, standard handling |
| `low` | `LOW` | 2 A-numbers, monitoring only |

### 4.5 Action Mapping

| ACM Action | NCC Action | Description |
|------------|------------|-------------|
| `disconnect` | `DISCONNECTED` | Active calls terminated |
| `block` | `BLOCKED` | Pattern blocked for future |
| `alert_only` | `ALERT_GENERATED` | Alert created, no action |
| `whitelist` | `WHITELISTED` | Added to allowlist |

---

## 5. Data Transformation

### 5.1 Transformation Pipeline

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Raw Data      │───▶│   Transform     │───▶│   NCC Format    │
│   (Internal)    │    │   Engine        │    │   (Export)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                      │                      │
        │                      │                      │
        ▼                      ▼                      ▼
   - QuestDB             - Field mapping         - CSV files
   - ClickHouse          - Type conversion       - JSON files
   - YugabyteDB          - Validation            - Checksums
```

### 5.2 SQL Queries for Data Extraction

#### Daily Statistics Query (QuestDB)

```sql
-- Daily statistics from QuestDB
SELECT
    count(*) as total_calls_processed,
    sum(case when fraud_detected then 1 else 0 end) as total_fraud_alerts,
    sum(case when severity = 'critical' then 1 else 0 end) as critical_alerts,
    sum(case when severity = 'high' then 1 else 0 end) as high_alerts,
    sum(case when severity = 'medium' then 1 else 0 end) as medium_alerts,
    sum(case when severity = 'low' then 1 else 0 end) as low_alerts,
    sum(case when action = 'disconnect' then 1 else 0 end) as calls_disconnected,
    percentile_disc(0.99) within group (order by detection_latency_ms) as detection_latency_p99,
    avg(detection_latency_ms) as detection_latency_avg
FROM call_events
WHERE timestamp >= $1 AND timestamp < $2;
```

#### Alert Details Query (ClickHouse)

```sql
-- Alert details from ClickHouse
SELECT
    alert_id,
    detected_at,
    severity,
    b_number,
    length(a_numbers) as a_number_count,
    detection_window_ms,
    action_taken,
    ncc_incident_id
FROM fraud_alerts
WHERE detected_at >= toDateTime('2026-01-28 00:00:00')
  AND detected_at < toDateTime('2026-01-29 00:00:00')
ORDER BY detected_at;
```

### 5.3 Rust Transformation Code

```rust
use serde::{Deserialize, Serialize};

#[derive(Deserialize)]
pub struct InternalAlert {
    pub id: String,
    pub detected_at: DateTime<Utc>,
    pub severity: InternalSeverity,
    pub b_number: String,
    pub a_numbers: Vec<String>,
    pub window_ms: u32,
    pub action: InternalAction,
    pub ncc_id: Option<String>,
}

#[derive(Serialize)]
pub struct NccAlertRecord {
    pub alert_id: String,
    pub detected_at: String,
    pub severity: String,
    pub b_number: String,
    pub a_number_count: usize,
    pub detection_window_ms: u32,
    pub action_taken: String,
    pub ncc_incident_id: String,
}

impl From<InternalAlert> for NccAlertRecord {
    fn from(alert: InternalAlert) -> Self {
        Self {
            alert_id: alert.id,
            detected_at: alert.detected_at.format("%Y-%m-%dT%H:%M:%SZ").to_string(),
            severity: map_severity(alert.severity),
            b_number: format_e164(&alert.b_number),
            a_number_count: alert.a_numbers.len(),
            detection_window_ms: alert.window_ms,
            action_taken: map_action(alert.action),
            ncc_incident_id: alert.ncc_id.unwrap_or_default(),
        }
    }
}

fn map_severity(s: InternalSeverity) -> String {
    match s {
        InternalSeverity::Critical => "CRITICAL",
        InternalSeverity::High => "HIGH",
        InternalSeverity::Medium => "MEDIUM",
        InternalSeverity::Low => "LOW",
    }.to_string()
}

fn map_action(a: InternalAction) -> String {
    match a {
        InternalAction::Disconnect => "DISCONNECTED",
        InternalAction::Block => "BLOCKED",
        InternalAction::AlertOnly => "ALERT_GENERATED",
        InternalAction::Whitelist => "WHITELISTED",
    }.to_string()
}
```

---

## 6. Upload Procedures

### 6.1 Daily Upload Workflow

```python
#!/usr/bin/env python3
"""
NCC Daily Report Upload Service
Runs daily at 05:30 WAT to upload reports for the previous day
"""

import paramiko
import hashlib
import json
from datetime import date, timedelta
from pathlib import Path

class NccUploader:
    def __init__(self, config: dict):
        self.config = config
        self.sftp = None

    def connect(self):
        """Establish SFTP connection to NCC server."""
        transport = paramiko.Transport((
            self.config['host'],
            self.config['port']
        ))

        private_key = paramiko.RSAKey.from_private_key_file(
            self.config['private_key_path']
        )

        transport.connect(
            username=self.config['username'],
            pkey=private_key
        )

        self.sftp = paramiko.SFTPClient.from_transport(transport)

    def upload_daily_reports(self, report_date: date):
        """Upload all daily report files."""
        date_str = report_date.strftime('%Y%m%d')
        remote_dir = f"{self.config['directories']['daily']}/{date_str}"

        # Create remote directory
        try:
            self.sftp.mkdir(remote_dir)
        except IOError:
            pass  # Directory may already exist

        # Files to upload
        files = [
            f"ACM_DAILY_{self.config['license']}_{date_str}.csv",
            f"ACM_ALERTS_{self.config['license']}_{date_str}.csv",
            f"ACM_TARGETS_{self.config['license']}_{date_str}.csv",
            f"ACM_SUMMARY_{self.config['license']}_{date_str}.json",
        ]

        for filename in files:
            local_path = Path(self.config['local_dir']) / filename
            remote_path = f"{remote_dir}/{filename}"

            if local_path.exists():
                self.sftp.put(str(local_path), remote_path)
                print(f"Uploaded: {filename}")
            else:
                print(f"Warning: File not found: {filename}")

    def verify_uploads(self, report_date: date):
        """Verify uploaded files exist and match checksums."""
        date_str = report_date.strftime('%Y%m%d')
        remote_dir = f"{self.config['directories']['daily']}/{date_str}"

        # Read summary for checksums
        summary_file = f"ACM_SUMMARY_{self.config['license']}_{date_str}.json"
        local_summary = Path(self.config['local_dir']) / summary_file

        with open(local_summary) as f:
            summary = json.load(f)

        # Verify each file
        for filename in summary['files']:
            remote_path = f"{remote_dir}/{filename}"
            try:
                attrs = self.sftp.stat(remote_path)
                print(f"Verified: {filename} ({attrs.st_size} bytes)")
            except IOError:
                print(f"Error: File not found on server: {filename}")
                raise

    def close(self):
        """Close SFTP connection."""
        if self.sftp:
            self.sftp.close()


def main():
    config = load_config()
    uploader = NccUploader(config)

    try:
        uploader.connect()

        # Upload yesterday's reports
        report_date = date.today() - timedelta(days=1)
        uploader.upload_daily_reports(report_date)
        uploader.verify_uploads(report_date)

        print(f"Successfully uploaded reports for {report_date}")

    except Exception as e:
        print(f"Upload failed: {e}")
        raise

    finally:
        uploader.close()


if __name__ == "__main__":
    main()
```

### 6.2 Checksum Generation

```python
def generate_checksum(filepath: Path) -> str:
    """Generate SHA-256 checksum for file."""
    sha256 = hashlib.sha256()
    with open(filepath, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            sha256.update(chunk)
    return f"sha256:{sha256.hexdigest()}"


def generate_manifest(files: list, output_path: Path):
    """Generate manifest file with checksums."""
    manifest = {
        'generated_at': datetime.utcnow().isoformat() + 'Z',
        'files': []
    }

    for filepath in files:
        manifest['files'].append({
            'name': filepath.name,
            'size': filepath.stat().st_size,
            'checksum': generate_checksum(filepath)
        })

    with open(output_path, 'w') as f:
        json.dump(manifest, f, indent=2)
```

---

## 7. Error Handling

### 7.1 Connection Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| Connection timeout | Network issue | Retry with backoff |
| Authentication failed | Invalid key | Verify key registration |
| Host key changed | Server changed/MITM | Contact NCC security |
| Permission denied | Wrong directory | Check path configuration |

### 7.2 Retry Logic

```python
import time
from functools import wraps

def retry_with_backoff(max_retries=3, base_delay=60):
    """Decorator for retry with exponential backoff."""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            last_exception = None
            for attempt in range(max_retries):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    last_exception = e
                    if attempt < max_retries - 1:
                        delay = base_delay * (2 ** attempt)
                        print(f"Attempt {attempt + 1} failed: {e}")
                        print(f"Retrying in {delay} seconds...")
                        time.sleep(delay)
            raise last_exception
        return wrapper
    return decorator


@retry_with_backoff(max_retries=3, base_delay=60)
def upload_with_retry(uploader, report_date):
    """Upload with automatic retry on failure."""
    uploader.connect()
    try:
        uploader.upload_daily_reports(report_date)
        uploader.verify_uploads(report_date)
    finally:
        uploader.close()
```

### 7.3 Error Reporting

Failed uploads must be reported internally and to NCC if deadline is missed.

```python
def handle_upload_failure(error: Exception, report_date: date):
    """Handle upload failure with notifications."""
    # Log error
    logger.error(f"Upload failed for {report_date}: {error}")

    # Send internal alert
    send_alert(
        severity="HIGH",
        title=f"NCC Upload Failed: {report_date}",
        details=str(error)
    )

    # If deadline passed, notify NCC
    deadline = datetime.combine(
        report_date + timedelta(days=1),
        time(6, 0)  # 06:00 WAT
    )
    if datetime.now() > deadline:
        submit_late_notification(report_date, error)
```

---

## 8. Monitoring & Alerts

### 8.1 Metrics to Monitor

| Metric | Warning | Critical |
|--------|---------|----------|
| Upload success rate | < 99% | < 95% |
| Upload latency | > 5 min | > 15 min |
| File size change | > 50% | > 100% |
| Checksum failures | Any | Any |
| Connection failures | 2+ | 5+ |

### 8.2 Prometheus Metrics

```yaml
# Prometheus metrics for NCC uploads
ncc_upload_success_total:
  type: counter
  help: Total successful NCC uploads

ncc_upload_failure_total:
  type: counter
  help: Total failed NCC uploads

ncc_upload_latency_seconds:
  type: histogram
  help: Upload latency in seconds
  buckets: [30, 60, 120, 300, 600]

ncc_upload_file_size_bytes:
  type: gauge
  help: Size of uploaded files

ncc_connection_errors_total:
  type: counter
  help: Total SFTP connection errors
```

### 8.3 Alerting Rules

```yaml
# Prometheus alerting rules
groups:
  - name: ncc_upload_alerts
    rules:
      - alert: NccUploadFailed
        expr: increase(ncc_upload_failure_total[1h]) > 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: NCC upload failed
          description: Daily report upload to NCC failed

      - alert: NccUploadLate
        expr: time() - ncc_upload_last_success_timestamp > 86400
        for: 30m
        labels:
          severity: warning
        annotations:
          summary: NCC upload overdue
          description: No successful upload in over 24 hours
```

---

## 9. Security Configuration

### 9.1 Key Management

```yaml
# Kubernetes secret for NCC credentials
apiVersion: v1
kind: Secret
metadata:
  name: ncc-sftp-credentials
  namespace: acm
type: Opaque
data:
  private-key: <base64-encoded-private-key>
  known-hosts: <base64-encoded-known-hosts>
```

### 9.2 Environment Variables

```bash
# Required environment variables
NCC_SFTP_HOST=sftp.ncc.gov.ng
NCC_SFTP_PORT=22
NCC_SFTP_USER=icl_ng_2025_001234
NCC_ICL_LICENSE=ICL-NG-2025-001234

# Key paths
NCC_PRIVATE_KEY_PATH=/etc/acm/keys/ncc_sftp_key
NCC_KNOWN_HOSTS_PATH=/etc/acm/keys/known_hosts
```

### 9.3 Network Security

- Use dedicated egress IP for NCC connections
- Firewall rules to allow only NCC SFTP server
- TLS inspection bypass for NCC traffic
- VPN or dedicated link if available

---

## Appendix A: Troubleshooting Commands

```bash
# Test SFTP connectivity
sftp -v -i /etc/acm/keys/ncc_sftp_key ${NCC_SFTP_USER}@${NCC_SFTP_HOST}

# Verify key permissions
ls -la /etc/acm/keys/

# Check SSH agent
ssh-add -l

# Test DNS resolution
nslookup sftp.ncc.gov.ng

# Check network connectivity
nc -zv sftp.ncc.gov.ng 22

# View known_hosts
cat /etc/acm/keys/known_hosts
```

---

**Document Version:** 1.0
**Classification:** Confidential
**Review Cycle:** Annual
