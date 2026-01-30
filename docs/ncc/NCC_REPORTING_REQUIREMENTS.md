# NCC Reporting Requirements
## Anti-Call Masking Detection System

**Version:** 1.0
**Last Updated:** January 2026
**Regulatory Authority:** Nigerian Communications Commission

---

## Table of Contents

1. [Overview](#1-overview)
2. [Daily Reports](#2-daily-reports)
3. [Weekly Reports](#3-weekly-reports)
4. [Monthly Reports](#4-monthly-reports)
5. [Incident Reports](#5-incident-reports)
6. [Annual Compliance Report](#6-annual-compliance-report)
7. [Report Formats](#7-report-formats)
8. [Submission Procedures](#8-submission-procedures)
9. [Validation & Acknowledgment](#9-validation--acknowledgment)
10. [Archival Requirements](#10-archival-requirements)

---

## 1. Overview

### 1.1 Purpose

This document specifies the reporting requirements mandated by the Nigerian Communications Commission (NCC) for ICL-licensed fraud detection service providers. Compliance with these requirements is mandatory for maintaining operational authorization.

### 1.2 Reporting Schedule

| Report Type | Frequency | Deadline | Submission Method |
|-------------|-----------|----------|-------------------|
| Daily Operations | Daily | 06:00 WAT | SFTP + ATRS API |
| Weekly Summary | Weekly | Monday 12:00 WAT | ATRS API |
| Monthly Compliance | Monthly | 5th of month | ATRS API + Portal |
| Incident Reports | Per event | Varies by severity | ATRS API |
| Annual Compliance | Annual | January 31st | NCC Portal |

### 1.3 Reporting Authority

Reports must be submitted under the authority of:
- **Primary**: Designated Compliance Officer
- **Backup**: Operations Manager
- **Escalation**: Managing Director (for critical incidents)

---

## 2. Daily Reports

### 2.1 Submission Requirements

- **Deadline**: 06:00 WAT (West Africa Time) following day
- **Format**: CSV + JSON summary
- **Delivery**: Automated SFTP upload
- **Acknowledgment**: Required within 4 hours

### 2.2 Report Content

#### 2.2.1 Daily Statistics File

**Filename**: `ACM_DAILY_{ICL_LICENSE}_{YYYYMMDD}.csv`

```csv
metric_name,metric_value,unit,timestamp
total_calls_processed,12547823,count,2026-01-28T23:59:59Z
total_fraud_alerts,47,count,2026-01-28T23:59:59Z
critical_alerts,5,count,2026-01-28T23:59:59Z
high_alerts,12,count,2026-01-28T23:59:59Z
medium_alerts,18,count,2026-01-28T23:59:59Z
low_alerts,12,count,2026-01-28T23:59:59Z
calls_disconnected,23,count,2026-01-28T23:59:59Z
detection_latency_p99,0.82,milliseconds,2026-01-28T23:59:59Z
detection_latency_avg,0.45,milliseconds,2026-01-28T23:59:59Z
system_uptime,99.998,percent,2026-01-28T23:59:59Z
false_positive_rate,0.21,percent,2026-01-28T23:59:59Z
```

#### 2.2.2 Alert Details File

**Filename**: `ACM_ALERTS_{ICL_LICENSE}_{YYYYMMDD}.csv`

```csv
alert_id,detected_at,severity,b_number,a_number_count,detection_window_ms,action_taken,ncc_incident_id
ALT-2026-0001234,2026-01-28T10:23:45Z,CRITICAL,+2348012345678,7,4200,DISCONNECTED,NCC-2026-01-0001234
ALT-2026-0001235,2026-01-28T11:15:22Z,HIGH,+2348023456789,5,3800,BLOCKED,NCC-2026-01-0001235
```

#### 2.2.3 Top Targets File

**Filename**: `ACM_TARGETS_{ICL_LICENSE}_{YYYYMMDD}.csv`

```csv
rank,b_number,incident_count,total_a_numbers,first_incident,last_incident
1,+2348012345678,5,23,2026-01-28T08:15:00Z,2026-01-28T22:30:00Z
2,+2348023456789,3,12,2026-01-28T10:00:00Z,2026-01-28T18:45:00Z
```

### 2.3 JSON Summary

**Filename**: `ACM_SUMMARY_{ICL_LICENSE}_{YYYYMMDD}.json`

```json
{
  "report_date": "2026-01-28",
  "icl_license": "ICL-NG-2025-001234",
  "generated_at": "2026-01-29T05:30:00Z",
  "statistics": {
    "total_calls_processed": 12547823,
    "fraud_alerts": {
      "total": 47,
      "by_severity": {
        "critical": 5,
        "high": 12,
        "medium": 18,
        "low": 12
      }
    },
    "actions": {
      "calls_disconnected": 23,
      "patterns_blocked": 8
    },
    "performance": {
      "detection_latency_p99_ms": 0.82,
      "detection_latency_avg_ms": 0.45,
      "system_uptime_percent": 99.998
    },
    "quality": {
      "false_positive_rate_percent": 0.21,
      "detection_accuracy_percent": 99.79
    }
  },
  "files": [
    "ACM_DAILY_ICL-NG-2025-001234_20260128.csv",
    "ACM_ALERTS_ICL-NG-2025-001234_20260128.csv",
    "ACM_TARGETS_ICL-NG-2025-001234_20260128.csv"
  ],
  "checksum": {
    "algorithm": "SHA-256",
    "value": "a1b2c3d4e5f6..."
  }
}
```

---

## 3. Weekly Reports

### 3.1 Submission Requirements

- **Deadline**: Monday 12:00 WAT (for preceding week)
- **Format**: JSON via ATRS API
- **Period**: Sunday 00:00 to Saturday 23:59 WAT

### 3.2 Report Content

```json
{
  "report_type": "WEEKLY_SUMMARY",
  "icl_license": "ICL-NG-2025-001234",
  "period": {
    "start": "2026-01-19T00:00:00Z",
    "end": "2026-01-25T23:59:59Z"
  },
  "statistics": {
    "total_calls_processed": 87835761,
    "daily_average_calls": 12547966,
    "peak_cps": 152340,
    "fraud_alerts": {
      "total": 312,
      "daily_breakdown": [
        {"date": "2026-01-19", "count": 42},
        {"date": "2026-01-20", "count": 38},
        {"date": "2026-01-21", "count": 51},
        {"date": "2026-01-22", "count": 45},
        {"date": "2026-01-23", "count": 55},
        {"date": "2026-01-24", "count": 48},
        {"date": "2026-01-25", "count": 33}
      ]
    },
    "actions": {
      "calls_disconnected": 156,
      "patterns_blocked": 42,
      "operators_notified": 12
    }
  },
  "trend_analysis": {
    "week_over_week_change_percent": -5.2,
    "new_patterns_identified": 2,
    "recurring_targets": [
      {"b_number": "+2348012345678", "incident_count": 12}
    ]
  },
  "performance": {
    "average_uptime_percent": 99.997,
    "average_detection_latency_ms": 0.48,
    "sla_compliance": true
  },
  "notable_incidents": [
    {
      "incident_id": "NCC-2026-01-0001234",
      "description": "Coordinated attack on banking hotline",
      "severity": "CRITICAL",
      "resolution": "Blocked source IP range"
    }
  ]
}
```

---

## 4. Monthly Reports

### 4.1 Submission Requirements

- **Deadline**: 5th day of following month by 18:00 WAT
- **Format**: JSON + PDF Executive Summary
- **Delivery**: ATRS API + NCC Portal upload

### 4.2 Report Content

#### 4.2.1 Statistical Summary

```json
{
  "report_type": "MONTHLY_COMPLIANCE",
  "icl_license": "ICL-NG-2025-001234",
  "period": {
    "month": "2026-01",
    "start": "2026-01-01T00:00:00Z",
    "end": "2026-01-31T23:59:59Z"
  },
  "operational_statistics": {
    "total_calls_processed": 387524891,
    "daily_average": 12500802,
    "peak_daily": 15234567,
    "peak_cps": 178234,
    "fraud_alerts": {
      "total": 1247,
      "by_severity": {
        "critical": 89,
        "high": 312,
        "medium": 534,
        "low": 312
      },
      "by_type": {
        "cli_spoofing": 892,
        "wangiri": 123,
        "irsf": 89,
        "other": 143
      }
    },
    "actions_taken": {
      "calls_disconnected": 623,
      "patterns_blocked": 156,
      "operators_notified": 45,
      "numbers_blacklisted": 234
    }
  },
  "performance_metrics": {
    "system_availability": {
      "uptime_percent": 99.995,
      "planned_downtime_minutes": 120,
      "unplanned_downtime_minutes": 12
    },
    "detection_performance": {
      "latency_p50_ms": 0.42,
      "latency_p95_ms": 0.68,
      "latency_p99_ms": 0.85,
      "detection_accuracy_percent": 99.82
    },
    "capacity_utilization": {
      "average_cpu_percent": 45,
      "peak_cpu_percent": 78,
      "average_memory_percent": 52
    }
  },
  "quality_metrics": {
    "false_positive_rate_percent": 0.18,
    "false_negative_rate_percent": 0.02,
    "operator_feedback_incorporated": 12
  },
  "financial_impact": {
    "estimated_fraud_prevented_ngn": 125000000,
    "calculation_methodology": "Based on average call duration and termination rates"
  }
}
```

#### 4.2.2 Executive Summary (PDF)

The PDF must include:

1. **Cover Page**
   - Company name and ICL license number
   - Report period
   - Submission date
   - Authorized signatory

2. **Executive Overview**
   - Key achievements
   - Major incidents
   - Performance highlights

3. **Statistical Summary**
   - Calls processed
   - Fraud detected
   - Actions taken

4. **Trend Analysis**
   - Month-over-month comparison
   - Emerging patterns
   - Geographic distribution

5. **Compliance Statement**
   - Attestation of data accuracy
   - Signature of Compliance Officer

---

## 5. Incident Reports

### 5.1 Severity-Based Timelines

| Severity | Initial Report | Full Report | Updates |
|----------|----------------|-------------|---------|
| CRITICAL | 1 hour | 24 hours | Every 4 hours |
| HIGH | 4 hours | 48 hours | Daily |
| MEDIUM | 24 hours | 7 days | Weekly |
| LOW | Weekly summary | Monthly | Monthly |

### 5.2 Critical Incident Definition

An incident is CRITICAL when any of the following apply:
- 10+ simultaneous attacks from same source
- Attack on government or emergency numbers
- Attack affecting 1000+ B-numbers
- System availability drops below 99%
- Data breach suspected
- Attack coordinated across multiple operators

### 5.3 Incident Report Template

```json
{
  "report_type": "INCIDENT_REPORT",
  "incident_id": "NCC-2026-01-0001234",
  "internal_reference": "ALT-2026-0001234",
  "icl_license": "ICL-NG-2025-001234",
  "report_stage": "INITIAL",
  "submitted_at": "2026-01-29T10:45:00Z",
  "incident_details": {
    "detected_at": "2026-01-29T10:23:45Z",
    "incident_type": "CLI_SPOOFING",
    "severity": "CRITICAL",
    "description": "Coordinated multicall masking attack targeting banking sector hotline"
  },
  "technical_details": {
    "b_number": "+2348012345678",
    "b_number_owner": "First Bank Nigeria",
    "a_numbers_count": 23,
    "detection_window_ms": 4200,
    "source_ips": ["192.168.1.0/24"],
    "source_country": "Unknown (VPN detected)"
  },
  "impact_assessment": {
    "calls_affected": 23,
    "estimated_duration_seconds": 45,
    "customer_impact": "Brief service disruption",
    "financial_impact_ngn": 0
  },
  "actions_taken": {
    "automated": [
      {"action": "ALERT_GENERATED", "timestamp": "2026-01-29T10:23:45Z"},
      {"action": "CALLS_DISCONNECTED", "timestamp": "2026-01-29T10:23:46Z"}
    ],
    "manual": [
      {"action": "ANALYST_REVIEW", "timestamp": "2026-01-29T10:28:00Z"},
      {"action": "IP_BLOCKED", "timestamp": "2026-01-29T10:30:00Z"}
    ]
  },
  "root_cause": {
    "preliminary": "VoIP gateway with spoofed CLIs",
    "confirmed": null,
    "investigation_status": "IN_PROGRESS"
  },
  "recommendations": [
    "Block IP range at upstream level",
    "Notify affected B-number owner",
    "Cross-operator coordination for source identification"
  ],
  "contacts": {
    "submitted_by": "John Doe, SOC Analyst",
    "authorized_by": "Jane Smith, Compliance Officer",
    "contact_phone": "+2348099999999"
  }
}
```

### 5.4 Follow-up Reports

Full reports must include:
- Complete root cause analysis
- All remediation actions taken
- Lessons learned
- Preventive measures implemented
- Cross-operator coordination outcomes

---

## 6. Annual Compliance Report

### 6.1 Submission Requirements

- **Deadline**: January 31st
- **Format**: PDF + JSON data appendix
- **Delivery**: NCC Portal with notarized signature

### 6.2 Required Sections

1. **Company Information**
   - Legal entity details
   - ICL license information
   - Key personnel changes
   - Infrastructure changes

2. **Annual Statistics**
   - Total calls processed
   - Total fraud detected
   - Month-by-month breakdown
   - Year-over-year comparison

3. **Compliance Attestation**
   - Technical requirements met
   - Data protection compliance
   - Security audit results
   - Training completed

4. **System Performance**
   - Availability metrics
   - Capacity metrics
   - Performance improvements

5. **Incident Summary**
   - Total incidents by severity
   - Major incident summaries
   - Resolution statistics

6. **Future Plans**
   - Planned improvements
   - Capacity expansion
   - New capabilities

### 6.3 Certification Statement

```
ANNUAL COMPLIANCE CERTIFICATION

I, [Full Name], in my capacity as [Title] of [Company Name],
holder of Interconnect Clearing License [ICL Number],
hereby certify that:

1. The information contained in this Annual Compliance Report
   is true and accurate to the best of my knowledge.

2. [Company Name] has operated its Anti-Call Masking Detection
   System in compliance with NCC regulations throughout the
   reporting period.

3. All mandatory reports were submitted within required timelines.

4. Data protection and privacy requirements were maintained.

5. System availability met or exceeded required thresholds.

Signed: ___________________
Date: ___________________
Corporate Seal: ___________________
```

---

## 7. Report Formats

### 7.1 CSV Requirements

- Encoding: UTF-8
- Delimiter: Comma (,)
- Line ending: LF or CRLF
- Header row: Required
- Quote character: Double quote (") for fields containing commas
- Date format: ISO 8601 (YYYY-MM-DDTHH:MM:SSZ)
- Phone format: E.164 with + prefix

### 7.2 JSON Requirements

- Encoding: UTF-8
- Date format: ISO 8601
- Numbers: No quotes for numeric values
- Null: Use JSON null, not empty string
- Pretty print: Optional

### 7.3 PDF Requirements

- Format: PDF/A-1b (archival)
- Resolution: 300 DPI minimum for images
- Font embedding: Required
- Digital signature: Required for annual report
- Maximum size: 50MB

---

## 8. Submission Procedures

### 8.1 SFTP Upload (Daily Reports)

```bash
# SFTP connection details
Host: sftp.ncc.gov.ng
Port: 22
Directory: /incoming/{ICL_LICENSE}/daily/

# File naming convention
ACM_{REPORT_TYPE}_{ICL_LICENSE}_{YYYYMMDD}.{ext}

# Upload command example
sftp -i /path/to/private_key ncc_upload@sftp.ncc.gov.ng <<EOF
cd /incoming/ICL-NG-2025-001234/daily/
put ACM_DAILY_ICL-NG-2025-001234_20260128.csv
put ACM_ALERTS_ICL-NG-2025-001234_20260128.csv
put ACM_TARGETS_ICL-NG-2025-001234_20260128.csv
put ACM_SUMMARY_ICL-NG-2025-001234_20260128.json
bye
EOF
```

### 8.2 ATRS API Submission

See [NCC_API_INTEGRATION.md](./NCC_API_INTEGRATION.md) for detailed API usage.

### 8.3 Portal Submission

1. Navigate to https://portal.ncc.gov.ng
2. Login with ICL credentials
3. Select "Compliance Reports"
4. Choose report type
5. Upload files
6. Complete attestation form
7. Submit and record confirmation number

---

## 9. Validation & Acknowledgment

### 9.1 Automatic Validation

Reports undergo automatic validation for:
- File format compliance
- Required fields present
- Data type validation
- Checksum verification
- Timeline compliance

### 9.2 Acknowledgment Timeline

| Report Type | Validation | Acknowledgment |
|-------------|------------|----------------|
| Daily SFTP | 1 hour | 4 hours |
| Weekly API | 30 minutes | 2 hours |
| Monthly API | 2 hours | 24 hours |
| Incident | 15 minutes | 1 hour |

### 9.3 Rejection Handling

If a report is rejected:
1. Review rejection reason
2. Correct the issue
3. Resubmit with same filename + "_v2" suffix
4. Document correction in notes

---

## 10. Archival Requirements

### 10.1 Retention Periods

| Data Type | Retention | Storage |
|-----------|-----------|---------|
| Daily reports | 2 years | Hot storage |
| Weekly reports | 3 years | Warm storage |
| Monthly reports | 7 years | Cold storage |
| Incident reports | 10 years | Cold storage |
| Annual reports | Permanent | Archive |

### 10.2 Archive Format

- All reports: Original format + PDF copy
- Integrity: SHA-256 checksum stored
- Location: Nigeria-based data center
- Backup: Geographically separated

### 10.3 Retrieval Procedure

Archived reports must be retrievable within:
- Hot storage: 1 hour
- Warm storage: 4 hours
- Cold storage: 24 hours

---

## Appendix A: Sample Report Templates

### A.1 Daily Report Automation Script

```python
#!/usr/bin/env python3
"""
Daily NCC Report Generator
Generates and submits daily compliance reports to NCC
"""

import csv
import json
import hashlib
from datetime import date, timedelta
import paramiko

def generate_daily_report(report_date: date):
    # Gather statistics from database
    stats = query_daily_statistics(report_date)

    # Generate CSV files
    generate_statistics_csv(stats, report_date)
    generate_alerts_csv(report_date)
    generate_targets_csv(report_date)

    # Generate JSON summary with checksum
    summary = generate_summary_json(stats, report_date)

    # Upload to NCC SFTP
    upload_to_ncc(report_date)

    # Submit to ATRS API
    submit_to_atrs(summary)

if __name__ == "__main__":
    yesterday = date.today() - timedelta(days=1)
    generate_daily_report(yesterday)
```

---

**Document Version:** 1.0
**Classification:** Confidential
**Review Cycle:** Annual
