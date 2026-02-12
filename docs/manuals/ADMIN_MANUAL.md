# VoxGuard Administrator Manual

## Anti-Call Masking & Voice Network Fraud Detection Platform

**Version:** 2.1
**Last Updated:** February 2026
**Audience:** System Administrators, Platform Administrators, DevOps Engineers
**Architecture:** Rust + QuestDB + DragonflyDB + YugabyteDB | React + Ant Design Frontend

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [User Management](#2-user-management)
3. [Gateway Management](#3-gateway-management)
4. [System Settings](#4-system-settings)
5. [ML Model Administration](#5-ml-model-administration)
6. [Report Administration](#6-report-administration)
7. [Audit and Compliance](#7-audit-and-compliance)
8. [AIDD Administration](#8-aidd-administration)
9. [System Architecture Reference](#9-system-architecture-reference)
10. [Database Administration](#10-database-administration)
11. [Monitoring and Observability](#11-monitoring-and-observability)
12. [Backup and Recovery](#12-backup-and-recovery)
13. [Security Administration](#13-security-administration)
14. [Internationalization Administration](#14-internationalization-administration)
15. [Troubleshooting and Support](#15-troubleshooting-and-support)
16. [Maintenance Procedures](#16-maintenance-procedures)

---

## 1. Introduction

### 1.1 Purpose

This manual provides comprehensive guidance for administrators responsible for managing, configuring, and maintaining the VoxGuard Anti-Call Masking & Voice Network Fraud Detection Platform. It covers both the web-based administration features (React + Ant Design frontend) and the backend infrastructure operations.

### 1.2 Target Audience

- **Platform Administrators**: Manage users, roles, settings, and report schedules through the web UI.
- **System Administrators**: Manage infrastructure, deployments, databases, and monitoring.
- **DevOps Engineers**: Handle CI/CD, scaling, and infrastructure automation.
- **Security Administrators**: Manage access controls, API keys, and audit compliance.
- **Compliance Officers**: Oversee NCC reporting, data retention, and regulatory audit readiness.

### 1.3 Prerequisites

- Familiarity with the VoxGuard User Manual (v2.1).
- Understanding of the AIDD tiered approval framework.
- For infrastructure tasks: Linux system administration, Docker/Kubernetes, PostgreSQL/SQL, and Prometheus/Grafana experience.

### 1.4 System Requirements

| Component | Minimum | Recommended | Production |
|-----------|---------|-------------|------------|
| CPU | 8 cores | 16 cores | 32 cores |
| Memory | 32 GB | 64 GB | 128 GB |
| Storage | 500 GB SSD | 1 TB NVMe | 2 TB NVMe RAID |
| Network | 1 Gbps | 10 Gbps | 25 Gbps |

### 1.5 Admin Access

Admin features are available to users with the **Admin** role. Admin-only sections in the sidebar include:
- **Users**: Full user management.
- **Gateways**: Gateway creation and configuration.
- **Settings**: All settings tabs including detection thresholds and API configuration.
- **ML Dashboard**: Retrain and promote models.
- **Audit Log**: Full access to all audit records.

---

## 2. User Management

### 2.1 Accessing User Management

Navigate to **Users** from the sidebar. This section is available only to Admin-role users.

<!-- Screenshot: User Management list page showing a table with columns for Name, Email, Role (color-coded tag), Status (Active/Inactive badge), Last Login, Created At, and action buttons (View, Edit). A "+ Create User" button is at the top right. -->

### 2.2 Creating Users

1. Click the **+ Create User** button at the top right.
2. Fill in the required fields:
   - **Full Name**: The user's display name.
   - **Email**: Used as the login username. Must be unique.
   - **Role**: Select from Viewer, Operator, Analyst, Supervisor, or Admin.
   - **Password**: Set an initial temporary password (minimum 12 characters, must include uppercase, lowercase, number, and special character).
3. Click **Save**.
4. The user receives an email notification with their credentials and a link to the platform.
5. On first login, the user is prompted to change their temporary password.

### 2.3 Role Definitions and Permissions

| Role | Dashboard | Alerts | Cases | CDR | KPI | Security | NCC | Audit | ML | Reports | Settings | Users | Gateways |
|------|-----------|--------|-------|-----|-----|----------|-----|-------|----|---------|----------|-------|----------|
| **Viewer** | View | View | View | -- | View | View | View | -- | View | View | -- | -- | -- |
| **Operator** | View | View + Ack | View | View | View | View | View | -- | View | View | -- | -- | -- |
| **Analyst** | View | Full | Full | Full | View | Full | Generate | View | View | Generate | -- | -- | -- |
| **Supervisor** | View | Full | Full | Full | View | Full | Full | View | View | Full | Detection, Notifications | -- | View |
| **Admin** | View | Full | Full | Full | View | Full | Full | Full | Full | Full | All | Full | Full |

Legend: "View" = read-only, "Full" = read/write/delete, "Ack" = acknowledge only, "--" = no access.

### 2.4 Editing Users

1. In the user list, click the **Edit** button (pencil icon) next to the user.
2. Modify the desired fields (name, email, role).
3. Click **Save**.

Role changes take effect on the user's next page load or login.

### 2.5 Deactivating Users

1. In the user list, click the **Edit** button next to the user.
2. Toggle the **Active** switch to off.
3. Click **Save**.

Deactivated users:
- Cannot log in.
- Their active sessions are terminated immediately.
- Their data (notes, audit entries, case assignments) is preserved.
- Can be reactivated by toggling the Active switch back on.

**Note:** VoxGuard does not support permanent user deletion to maintain audit trail integrity. Deactivation is the recommended approach for offboarding.

### 2.6 Password Policies

| Policy | Value |
|--------|-------|
| Minimum length | 12 characters |
| Complexity | Uppercase + lowercase + number + special character |
| Expiration | 90 days |
| History | Cannot reuse last 5 passwords |
| Lockout | 5 failed attempts, 15-minute lockout |
| Session timeout | 24 hours of inactivity |

### 2.7 Bulk User Operations

For organizations onboarding multiple users:
1. Prepare a CSV file with columns: `name`, `email`, `role`.
2. Navigate to **Users > Import**.
3. Upload the CSV file.
4. Review the import preview.
5. Click **Import**. Temporary passwords are auto-generated and emailed to each user.

---

## 3. Gateway Management

### 3.1 Accessing Gateway Management

Navigate to **Gateways** from the sidebar.

<!-- Screenshot: Gateway list page showing a table with columns for Gateway ID, Name, Type (SIP/TDM), IP Address, Status (Online/Offline/Degraded badge), Health Score, Last Seen, and action buttons (View, Edit, Blacklist). A "+ Add Gateway" button is at the top right. -->

### 3.2 Adding Gateways

1. Click the **+ Add Gateway** button.
2. Fill in the gateway details:
   - **Name**: Descriptive name (e.g., "GW-MTN-01").
   - **Type**: SIP or TDM.
   - **IP Address**: The gateway's IP address.
   - **Port**: The signaling port (default: 5060 for SIP).
   - **Operator**: The telecom operator this gateway belongs to.
   - **Location**: Physical or logical location description.
3. Click **Save**. The gateway is added and health monitoring begins automatically.

### 3.3 Monitoring Gateway Health

The gateway list displays real-time health information:

| Indicator | Meaning |
|-----------|---------|
| **Online** (green) | Gateway is operational and responding to health checks |
| **Degraded** (yellow) | Gateway is responding but with elevated latency or error rates |
| **Offline** (red) | Gateway is not responding to health checks |

Click any gateway row to open the detail view, which shows:
- Connection history and uptime percentage.
- Traffic volume (calls per second).
- Error rates and latency metrics.
- Alert history for this gateway.
- Blacklist status.

<!-- Screenshot: Gateway detail page showing the gateway name, status badge, IP address, a traffic volume line chart over the last 24 hours, a latency chart, an error rate chart, and an "Alerts from this Gateway" table. Action buttons include Edit, Blacklist, and Disable. -->

### 3.4 Blacklisting a Gateway

When a gateway is confirmed as a fraud source:

1. Open the gateway detail view.
2. Click the **Blacklist** button.
3. Provide a reason for blacklisting.
4. Set the duration: Temporary (specify hours/days) or Permanent.
5. Confirm. This is a **Tier 1 (Confirm)** operation.

Blacklisted gateways:
- All traffic from the gateway is blocked.
- Active calls through the gateway are disconnected.
- The gateway status changes to "Blacklisted" with a red indicator.
- An audit log entry is created.

To remove a blacklist:
1. Open the gateway detail view.
2. Click **Remove Blacklist**.
3. Provide a reason.
4. Confirm.

### 3.5 Editing and Disabling Gateways

**Editing:**
1. Click **Edit** on the gateway.
2. Modify name, IP, port, operator, or location.
3. Click **Save**.

**Disabling:**
1. Click **Disable** to stop monitoring a gateway without removing it.
2. Disabled gateways remain in the list but are grayed out and not monitored.
3. Click **Enable** to resume monitoring.

---

## 4. System Settings

Access via **Settings** in the sidebar. Admins have access to all 5 tabs. Supervisors have access to Detection and Notifications tabs only.

### 4.1 Detection Thresholds

**Tab:** Detection

Configure the fraud detection engine's sensitivity:

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| CPM Warning Level | 40 | 1-100 calls/min | Warning threshold for calls per minute |
| CPM Critical Level | 60 | 1-200 calls/min | Critical threshold for calls per minute |
| ACD Warning Level | 10 | 1-60 seconds | Warning when average call duration drops below this |
| ACD Critical Level | 5 | 1-30 seconds | Critical alert when ACD drops below this |
| Threat Score Threshold | 70 | 1-100% | Alerts above this score marked high priority |
| Auto-Block Enabled | Off | On/Off | Automatically block numbers above the auto-block threshold |
| Auto-Block Threshold | 90 | 80-100% | Threat score above which auto-blocking engages |

**Best Practices:**
- Start with conservative thresholds (higher CPM, lower ACD) and tighten gradually.
- Monitor false positive rates after each threshold change.
- Enable auto-block only after thorough testing in your environment.
- Document threshold changes in the change management process.

**Caution:** Enabling auto-block can disconnect legitimate traffic if thresholds are set too aggressively. Always monitor the false positive rate for 24-48 hours after enabling or adjusting auto-block.

### 4.2 Notification Configuration

**Tab:** Notifications

**Email Notifications:**
- **Enable Email Alerts**: Master toggle for email delivery.
- **Recipients**: Comma-separated list of email addresses that receive alerts.
- Email delivery depends on the backend SMTP configuration.

**Slack Integration:**
- **Enable Slack Alerts**: Master toggle for Slack delivery.
- **Webhook URL**: The Slack incoming webhook URL (format: `https://hooks.slack.com/services/T.../B.../...`).
- To create a webhook, go to your Slack workspace's App settings and create an Incoming Webhook.

**Browser Notifications:**
- **Sound for Critical Alerts**: Plays an audio alert in the browser when a critical alert is received.
- **Notification Cooldown**: Minimum interval between repeated notifications for the same alert (default: 5 minutes, range: 1-60 minutes).

### 4.3 API Settings

**Tab:** API & Integration

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| Rate Limit | 1000 | 100-10,000 req/min | Maximum API requests per minute |
| Timeout | 30 | 5-120 seconds | API request timeout |
| Retry Attempts | 3 | 0-10 | Number of automatic retries on failure |

**NCC Compliance Reporting:**
- **Enable NCC Reporting**: Toggle automatic daily/monthly report generation and submission.
- **NCC API Key**: The API key provided by NCC for the ATRS (Anti-Telecom Fraud Reporting System).
- When enabled, daily reports are generated at 06:00 WAT and monthly reports on the 1st of each month.

### 4.4 Language & Region

**Tab:** Language & Region

Admins can set the default language and currency for the organization. Individual users can override these with their personal preferences.

- **Default Language**: The language used for new users and users who have not set a preference.
- **Default Currency**: The default currency for displaying monetary values.
- **Timezone**: The system timezone for report generation and scheduled tasks (default: WAT - West Africa Time).

### 4.5 External Portals

**Tab:** External Portals

Manage quick-access links to external monitoring tools:

| Service | Default URL | Purpose |
|---------|-------------|---------|
| Grafana | http://localhost:3000 | Metrics dashboards |
| Prometheus | http://localhost:9091 | Time-series metrics |
| QuestDB | http://localhost:9000 | Time-series database console |
| ClickHouse | http://localhost:8123 | OLAP query interface |
| YugabyteDB | http://localhost:7000 | Distributed SQL admin |
| Homer SIP | http://localhost:9080 | SIP capture and analysis |

Click **Check Health** to verify connectivity to all services. Health status is displayed as a green checkmark (healthy) or red X (unhealthy) next to each service card.

---

## 5. ML Model Administration

### 5.1 Overview

Navigate to **ML Dashboard** from the sidebar. Admins have full access to model management operations including retraining, promotion, and A/B testing.

<!-- Screenshot: ML Dashboard showing model cards with Admin-specific action buttons: "Retrain" (with AIDD Tier 1 badge), "Promote" (visible on Shadow models), "Retire" (visible on Active models), and "A/B Test" button. Each card shows model name, version, status badge, accuracy/AUC/F1 metrics, and operational stats. -->

### 5.2 Monitoring Model Performance

Each model card displays:

| Metric | Target | Action if Below Target |
|--------|--------|----------------------|
| Accuracy | Above 92% | Schedule retraining |
| AUC | Above 0.95 | Investigate feature drift |
| F1 Score | Above 0.90 | Review precision/recall balance |
| Avg Latency | Below 50ms | Check infrastructure resources |
| Predictions Today | Varies | Verify model is receiving traffic |

**Signs of Model Degradation:**
- Accuracy dropping below 90% over a 7-day trend.
- F1 score diverging significantly from AUC (indicates class imbalance issues).
- Increasing false positive rate in the KPI Scorecard.
- Average latency exceeding 100ms (indicates resource constraints).

### 5.3 Retraining Triggers

**Manual Retraining:**
1. Click the **Retrain** button on the model card (Tier 1 operation -- confirmation required).
2. The model enters "Retraining" status with a progress indicator.
3. Retraining uses the latest labeled data (confirmed fraud + confirmed false positives).
4. Upon completion, the new version is deployed in **Shadow Mode**.

**Automatic Retraining:**
Retraining is triggered automatically when:
- Scheduled weekly retraining window arrives (configurable, default: Sunday 02:00 WAT).
- Model drift detection identifies significant accuracy degradation.
- Sufficient new labeled training data has accumulated (configurable threshold).

### 5.4 A/B Testing

A/B testing allows comparing two model versions on live traffic:

1. Deploy a new model version in Shadow mode.
2. Click **A/B Test** on the shadow model.
3. Configure the traffic split (e.g., 90% to Active, 10% to Shadow).
4. Monitor comparative metrics over the test period.
5. When satisfied, either **Promote** the shadow model or **Cancel** the A/B test.

A/B test results are visible on the model detail page, showing side-by-side accuracy, false positive rate, and latency comparisons.

### 5.5 Promoting and Retiring Models

**Promoting a Shadow Model:**
1. Verify the shadow model's metrics meet or exceed the active model's performance.
2. Click **Promote** on the shadow model card.
3. Confirm (Tier 1 operation).
4. The shadow model becomes Active; the previous active model becomes Retired.

**Retiring a Model:**
1. Click **Retire** on an active model (only available when another model is ready to take over).
2. Confirm (Tier 1 operation).
3. The model stops receiving traffic but remains in the system for audit purposes.

### 5.6 AIDD Tier 2 Operations for ML

The following ML operations are Tier 2 (require Admin approval with a written reason):
- Deleting a model entirely from the system.
- Modifying model feature configurations.
- Overriding automatic retraining schedules.
- Changing the drift detection sensitivity.

---

## 6. Report Administration

### 6.1 Managing Report Schedules

Navigate to **Reports** from the sidebar.

Admins can view and manage all scheduled reports across the organization (not just their own).

<!-- Screenshot: Report Builder page with the Admin view showing a "Scheduled Reports" section with columns for Report Type, Frequency, Next Run, Recipients, Owner, Status (Active/Paused), and action buttons (Edit, Pause, Delete). -->

**Managing Schedules:**
1. View all active schedules in the report history table (look for the Schedule column).
2. Click a scheduled report to edit its frequency, recipients, or format.
3. Use **Pause** to temporarily stop a schedule without deleting it.
4. Use **Delete** to permanently remove a schedule.

### 6.2 NCC Report Submissions

NCC reports require a two-step process:

**Step 1: Generation (Tier 1)**
1. The report is generated automatically or manually via the Report Builder.
2. Generated reports appear in the history with "Generated" status.

**Step 2: Submission to NCC (Tier 2)**
1. Review the generated report for accuracy.
2. Click **Submit to NCC**.
3. The Admin Approval dialog appears.
4. Enter your SYSTEM_ADMIN credentials and provide a reason/confirmation.
5. The report is submitted to NCC via the configured ATRS API.
6. Status changes to "Submitted" with a timestamp.

**NCC Report Types and Deadlines:**

| Report | Deadline | Auto-Generation |
|--------|----------|-----------------|
| Daily Incident Report | 06:00 WAT next day | Yes (if NCC reporting enabled) |
| Monthly Compliance Report | 5th of following month | Yes (if NCC reporting enabled) |
| Incident Reports | Within SLA (varies) | Manual trigger required |

### 6.3 Report Retention

| Report Type | Retention Period | Storage |
|-------------|-----------------|---------|
| NCC Submissions | 7 years | Cold storage (auto-archived after 90 days) |
| Daily Summaries | 2 years | Warm storage |
| Custom Reports | 1 year | Standard storage |
| Scheduled Reports | 1 year | Standard storage |

---

## 7. Audit and Compliance

### 7.1 Reviewing Audit Logs

Navigate to **Audit Log** from the sidebar. Admins have full access to all audit records; other roles see a filtered view.

<!-- Screenshot: Audit Log page showing the full admin view with all filter options (search text, user selector with all users listed, action type dropdown, resource type dropdown, date range picker) and the audit entries table. -->

**What is Logged:**

Every significant action in the platform is recorded:
- User authentication events (login, logout, failed attempts).
- All CRUD operations on alerts, cases, CDRs, gateways, users, and settings.
- System operations (ML retraining, backups, token rotations).
- Export and report generation events.
- Traffic control rule changes.
- AIDD Tier 1 confirmations and Tier 2 approvals (including the approval reason).

**Each Audit Entry Contains:**

| Field | Description |
|-------|-------------|
| Audit ID | Unique identifier (e.g., AUD-001) |
| Timestamp | Exact date and time of the action |
| User | Username of the actor (or "system" for automated actions) |
| Action | Type of action (CREATE, UPDATE, DELETE, EXECUTE, EXPORT, BLOCK, LOGIN, BACKUP, ROTATE) |
| Resource | The affected resource path (e.g., `case/CASE-2025-001`, `settings/detection`) |
| Details | Human-readable description of what changed |
| IP Address | Source IP address of the actor |

### 7.2 Seven-Year Retention Policy

VoxGuard implements a 7-year retention policy for audit logs and NCC compliance reports:

| Data Age | Storage Tier | Access Method |
|----------|-------------|---------------|
| 0-90 days | Hot storage (primary database) | Direct query via Audit Log page |
| 90 days - 1 year | Warm storage (archived tables) | Query via Audit Log page with date range filter |
| 1-7 years | Cold storage (compressed archives) | Request via Admin > Data Retrieval |

**Automatic Archival:**
- Daily job moves audit entries older than 90 days to warm storage.
- Monthly job moves entries older than 1 year to cold storage.
- Entries older than 7 years are permanently deleted per data retention policy.

### 7.3 NCC Report Submission Tracking

Track all NCC report submissions:

1. Navigate to **NCC > Compliance**.
2. The "Submitted Reports" section shows all reports sent to NCC.
3. Each entry includes: submission timestamp, report type, period, file size, submission status, and the approving admin's name.
4. Click any submission to view the original report and the Tier 2 approval details (including the admin's written reason).

### 7.4 Compliance Checklists

**Daily:**
- [ ] Review new critical and high-severity alerts.
- [ ] Verify daily NCC report was generated and uploaded by 06:00 WAT.
- [ ] Check system health metrics in Grafana/Prometheus.
- [ ] Review error logs for anomalies.

**Weekly:**
- [ ] Review disk space and storage capacity.
- [ ] Verify backup integrity (test restore if needed).
- [ ] Review and clean up expired blacklist/whitelist entries.
- [ ] Review false positive trends and adjust thresholds if needed.

**Monthly:**
- [ ] Verify monthly NCC report submission by the 5th.
- [ ] Review user accounts (deactivate departed employees).
- [ ] Review and rotate API keys approaching expiration.
- [ ] Capacity planning review.
- [ ] Review ML model performance trends.

**Quarterly:**
- [ ] Full access control audit (review all user roles and permissions).
- [ ] Security patch review and application.
- [ ] Disaster recovery test.
- [ ] NCC compliance self-assessment.

---

## 8. AIDD Administration

### 8.1 Understanding AIDD Tiers

AIDD (Autonomous Intelligence-Driven Development) is VoxGuard's tiered approval framework. As an Admin, you are the approval authority for Tier 2 operations.

| Tier | UI Indicator | Who Can Execute | Admin Role |
|------|-------------|-----------------|------------|
| **Tier 0** | No badge | All roles (read-only operations) | No involvement needed |
| **Tier 1** | Yellow "Confirm" badge | Role-appropriate users | No involvement needed (user self-confirms) |
| **Tier 2** | Red "Admin Approval" badge with lock icon | Admin only | You must approve with credentials and written reason |

### 8.2 Tier 2 Approval Workflows

When a Tier 2 operation is triggered:

1. The system presents an **Admin Approval** dialog.
2. The dialog shows:
   - The operation being requested.
   - The user who initiated the request.
   - The affected resources.
3. The Admin must:
   - Authenticate with SYSTEM_ADMIN credentials.
   - Provide a written reason/justification in the reason textarea.
4. Upon approval, the operation executes and is logged in the audit trail with the admin's name and reason.

**Tier 2 Operations:**

| Operation | Impact | Approval Considerations |
|-----------|--------|------------------------|
| Submit NCC report | Regulatory -- cannot be retracted | Verify report accuracy before approving |
| Escalate dispute to NCC | Regulatory -- initiates formal process | Confirm the dispute is valid and documented |
| Import MNP data | Bulk database update | Verify data source and format |
| Bulk delete records | Irreversible data loss | Confirm scope and necessity |
| Modify auth settings | Security impact | Verify change request is authorized |
| Run database migrations | Schema changes | Verify migration has been tested |

### 8.3 Understanding Autonomous Operations

Some VoxGuard operations execute autonomously (without human approval) based on pre-configured rules:

| Autonomous Operation | Trigger | Override |
|---------------------|---------|----------|
| Auto-block (if enabled) | Threat score exceeds auto-block threshold | Disable in Settings > Detection |
| Auto-disconnect (if enabled) | Active call matches confirmed fraud pattern | Disable in Settings > Detection |
| Daily NCC report generation | 06:00 WAT schedule | Disable in Settings > API & Integration |
| ML model retraining | Weekly schedule or drift detection | Override in ML Dashboard |
| Token rotation | Nightly schedule | N/A (security requirement) |
| Database backup | Daily schedule | Configure in backend |

Autonomous operations are logged in the audit trail with user "system" and can be monitored via the Audit Log.

---

## 9. System Architecture Reference

### 9.1 Component Overview

```
+-----------------------------------------------------------------------------+
|                          VoxGuard Platform                                    |
+-----------------------------------------------------------------------------+
|                                                                               |
|  +------------------+     +------------------+     +---------------------+    |
|  |   OpenSIPS       |---->|   ACM Detection  |---->|   Management API    |    |
|  |   (SIP Proxy)    |     |   Engine (Rust)  |     |   (Go)              |    |
|  |   Port 5060      |     |   Port 8080      |     |   Port 8081         |    |
|  +------------------+     +--------+---------+     +---------------------+    |
|                                    |                                          |
|          +-------------------------+-------------------------+                |
|          |                         |                         |                |
|          v                         v                         v                |
|  +------------------+     +------------------+     +------------------+       |
|  |   DragonflyDB    |     |    QuestDB       |     |   YugabyteDB     |       |
|  |   (Cache)        |     |   (TimeSeries)   |     |   (Persistence)  |       |
|  |   Port 6379      |     |   Port 8812      |     |   Port 5433      |       |
|  +------------------+     +------------------+     +------------------+       |
|                                                                               |
|  +-------------------------------------------------------------------+       |
|  |                     Frontend (React + Ant Design)                   |       |
|  |  i18n (10 langs) | Case Mgmt | CDR Browser | KPI | ML Dashboard   |       |
|  |  Report Builder | Audit Log | AIDD Tiers                          |       |
|  +-------------------------------------------------------------------+       |
|                                                                               |
|  +-------------------------------------------------------------------+       |
|  |                     Monitoring Stack                                |       |
|  |  Prometheus | Grafana | Homer SIP | Alertmanager                   |       |
|  +-------------------------------------------------------------------+       |
|                                                                               |
+-----------------------------------------------------------------------------+
```

### 9.2 Data Flow

```
SIP Client --> OpenSIPS --> ACM Engine --> DragonflyDB (real-time detection cache)
                                       --> QuestDB (real-time analytics)
                                       --> YugabyteDB (persistence, cases, users)
                                       --> ClickHouse (historical analytics)
```

### 9.3 Network Ports Reference

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| OpenSIPS | 5060 | UDP/TCP | SIP signaling |
| OpenSIPS | 5061 | TCP/TLS | SIP over TLS |
| ACM Engine | 8080 | HTTP | Detection API |
| Management API | 8081 | HTTP | Management/CRUD API |
| DragonflyDB | 6379 | Redis | Real-time cache |
| QuestDB (ILP) | 9009 | ILP | Time-series ingestion |
| QuestDB (PG) | 8812 | PostgreSQL | Time-series queries |
| QuestDB (Web) | 9000 | HTTP | Web console |
| YugabyteDB | 5433 | PostgreSQL | Persistence queries |
| ClickHouse | 8123 | HTTP | Analytics queries |
| Prometheus | 9091 | HTTP | Metrics collection |
| Grafana | 3000 | HTTP | Dashboard UI |
| Homer SIP | 9080 | HTTP | SIP capture UI |
| Alertmanager | 9093 | HTTP | Alert routing |
| Frontend (dev) | 5173 | HTTP | React dev server |

---

## 10. Database Administration

### 10.1 YugabyteDB (Primary Persistence)

YugabyteDB stores all persistent data: users, cases, alerts, gateways, settings, audit logs, and whitelist/blacklist entries.

```bash
# Connect to YugabyteDB
docker-compose exec yugabyte ysqlsh -U opensips -d opensips

# Check cluster health
docker-compose exec yugabyte yb-admin \
  --master_addresses yugabyte:7100 get_universe_config

# View table sizes
SELECT
    table_name,
    pg_size_pretty(pg_total_relation_size(quote_ident(table_name)))
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY pg_total_relation_size(quote_ident(table_name)) DESC;

# Vacuum tables (run weekly)
VACUUM ANALYZE;
```

### 10.2 QuestDB (Time-Series)

QuestDB stores real-time call events and time-series analytics data.

```bash
# Access QuestDB web console: http://localhost:9000

# Query via PostgreSQL wire protocol
psql -h localhost -p 8812 -U admin

# Check table sizes
SELECT table_name, designatedTimestamp, partitionBy FROM tables();

# Drop old partitions (retention management)
ALTER TABLE call_events DROP PARTITION
WHERE timestamp < dateadd('d', -30, now());
```

### 10.3 ClickHouse (Historical Analytics)

```bash
# Connect to ClickHouse
docker-compose exec clickhouse clickhouse-client

# Check database sizes
SELECT
    database,
    table,
    formatReadableSize(sum(bytes)) as size,
    sum(rows) as rows
FROM system.parts
GROUP BY database, table
ORDER BY sum(bytes) DESC;

# Optimize tables
OPTIMIZE TABLE fraud_alerts FINAL;
```

### 10.4 DragonflyDB (Real-Time Cache)

```bash
# Connect to DragonflyDB
redis-cli -p 6379

# Check memory usage
INFO memory

# Check connected clients
INFO clients

# Flush cache (emergency only -- causes temporary detection delay)
FLUSHDB
```

### 10.5 Data Retention Summary

| Data Type | Hot Storage | Warm Storage | Cold Storage | Total Retention |
|-----------|-------------|-------------|-------------|-----------------|
| Call events (CDRs) | 30 days | 60 days | -- | 90 days |
| Fraud alerts | 90 days | 1 year | 6 years | 7 years |
| Audit logs | 90 days | 1 year | 6 years | 7 years |
| NCC reports | 90 days | 1 year | 6 years | 7 years |
| Cases | 90 days | 1 year | 6 years | 7 years |
| ML model artifacts | 1 year | -- | -- | 1 year |
| Metrics (Prometheus) | 30 days | -- | -- | 30 days |
| Cache (DragonflyDB) | 10 seconds TTL | -- | -- | Real-time only |

---

## 11. Monitoring and Observability

### 11.1 Prometheus Queries

```promql
# Detection latency P99
histogram_quantile(0.99, rate(acm_detection_latency_bucket[5m]))

# Alerts per minute
rate(acm_alerts_total[1m]) * 60

# Calls processed per second
rate(acm_calls_processed_total[1m])

# System uptime
time() - acm_start_time_seconds

# DragonflyDB memory usage percentage
redis_memory_used_bytes / redis_memory_max_bytes * 100

# Active WebSocket connections
acm_websocket_connections_active
```

### 11.2 Grafana Dashboards

Pre-configured dashboards at `http://localhost:3000`:

| Dashboard | Purpose | Key Panels |
|-----------|---------|------------|
| ACM Overview | System health and KPIs | Alert volume, detection rate, uptime |
| Detection Performance | Latency and throughput | P50/P95/P99 latency, CPS, batch sizes |
| Alert Analytics | Fraud patterns and trends | Severity distribution, top targets, geography |
| Database Metrics | DB performance and capacity | Query latency, disk usage, connections |
| SIP Metrics | OpenSIPS performance | SIP transactions, registrations, errors |
| ML Models | Model health | Accuracy trends, prediction volumes, latency |

### 11.3 Health Check Endpoints

```bash
# ACM Engine health
curl -s http://localhost:8080/health | jq

# Expected response:
# {
#   "status": "healthy",
#   "components": {
#     "dragonfly": "connected",
#     "questdb": "connected",
#     "yugabyte": "connected",
#     "opensips": "connected"
#   },
#   "version": "2.1.0",
#   "uptime_seconds": 86400
# }

# Management API health
curl -s http://localhost:8081/health | jq

# Prometheus metrics
curl http://localhost:9091/metrics | head -20
```

### 11.4 Log Management

```bash
# View detection engine logs
docker-compose logs -f acm-engine

# Filter for errors only
docker-compose logs acm-engine 2>&1 | grep -i error

# View all service logs with timestamps
docker-compose logs -t --tail=100

# Export logs to file
docker-compose logs --no-color > /var/log/acm/export_$(date +%Y%m%d).log
```

### 11.5 Alerting Rules

Configure in Prometheus Alertmanager:

| Alert | Condition | Severity | Action |
|-------|-----------|----------|--------|
| HighDetectionLatency | P99 > 100ms for 5 min | Warning | Check DragonflyDB memory |
| ServiceDown | Health check fails for 2 min | Critical | Restart service |
| DiskSpaceLow | Usage > 85% | Warning | Expand storage or archive |
| HighFalsePositiveRate | FP rate > 10% for 1 hour | Warning | Review thresholds |
| ModelDegradation | Accuracy < 90% for 24h | Warning | Schedule retraining |
| NCC ReportOverdue | Daily report not generated by 06:30 WAT | Critical | Manual generation |

---

## 12. Backup and Recovery

### 12.1 Backup Schedule

| Data | Frequency | Method | Retention |
|------|-----------|--------|-----------|
| YugabyteDB | Daily (02:00 WAT) | Full dump | 30 days |
| ClickHouse | Daily (02:30 WAT) | Incremental backup | 30 days |
| Configuration files | Daily (03:00 WAT) | File copy | 30 days |
| ML model artifacts | On each training | Model checkpoint | 1 year |

### 12.2 Backup Script

```bash
#!/bin/bash
# backup.sh - Daily backup script
BACKUP_DIR=/var/backups/acm/$(date +%Y%m%d)
mkdir -p $BACKUP_DIR

# YugabyteDB backup
docker-compose exec -T yugabyte ysql_dump \
  -U opensips opensips > $BACKUP_DIR/yugabyte.sql

# ClickHouse backup
docker-compose exec clickhouse clickhouse-client \
  --query="BACKUP DATABASE acm TO Disk('backups', 'acm_$(date +%Y%m%d)')"

# Configuration backup
cp -r config/ $BACKUP_DIR/config/
cp docker-compose.yml $BACKUP_DIR/
cp .env $BACKUP_DIR/

# Compress
tar -czf $BACKUP_DIR.tar.gz -C /var/backups/acm $(date +%Y%m%d)
rm -rf $BACKUP_DIR

# Upload to remote storage
aws s3 cp $BACKUP_DIR.tar.gz s3://your-bucket/acm-backups/

echo "Backup completed: $BACKUP_DIR.tar.gz"
```

### 12.3 Recovery Procedure

```bash
#!/bin/bash
# restore.sh - Restore from backup
BACKUP_DATE=$1
BACKUP_FILE=/var/backups/acm/${BACKUP_DATE}.tar.gz

# Stop services
docker-compose down

# Extract backup
tar -xzf $BACKUP_FILE -C /tmp/

# Restore YugabyteDB
docker-compose up -d yugabyte
sleep 30
docker-compose exec -T yugabyte ysql \
  -U opensips opensips < /tmp/${BACKUP_DATE}/yugabyte.sql

# Restore configuration
cp /tmp/${BACKUP_DATE}/config/* config/
cp /tmp/${BACKUP_DATE}/docker-compose.yml .
cp /tmp/${BACKUP_DATE}/.env .

# Restart all services
docker-compose up -d

echo "Restore completed from $BACKUP_DATE"
```

### 12.4 Disaster Recovery

| RTO | RPO | Strategy |
|-----|-----|----------|
| 1 hour | 15 minutes | Hot standby in DR site with replication |
| 4 hours | 1 hour | Warm standby with async replication |
| 24 hours | 24 hours | Cold backup restoration from S3 |

---

## 13. Security Administration

### 13.1 Authentication

- JWT-based authentication with 24-hour token expiration.
- Tokens stored securely in browser storage with httpOnly flags.
- RBAC (Role-Based Access Control) enforced on all API endpoints.
- Two-factor authentication support (TOTP).

### 13.2 TLS Configuration

```yaml
# Configure TLS for OpenSIPS
opensips:
  tls:
    certificate: /etc/opensips/tls/server.crt
    private_key: /etc/opensips/tls/server.key
    ca_certificate: /etc/opensips/tls/ca.crt
    verify_client: optional
    ciphers: "HIGH:!aNULL:!MD5"
```

All data in transit is encrypted with TLS 1.3. All data at rest is encrypted with AES-256.

### 13.3 API Key Management

```bash
# Generate API key
curl -X POST http://localhost:8081/api/v1/auth/keys \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "External Integration",
    "scopes": ["events:write", "alerts:read"],
    "expires_in_days": 365
  }'

# List API keys
curl http://localhost:8081/api/v1/auth/keys \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Revoke API key
curl -X DELETE http://localhost:8081/api/v1/auth/keys/{key_id} \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### 13.4 Network Security

```bash
# Firewall rules (UFW example)
sudo ufw allow from 10.0.0.0/8 to any port 8080   # ACM Engine (internal)
sudo ufw allow from 10.0.0.0/8 to any port 5060    # SIP signaling
sudo ufw deny from any to any port 6379             # DragonflyDB (internal only)
sudo ufw deny from any to any port 5433             # YugabyteDB (internal only)
sudo ufw deny from any to any port 8812             # QuestDB (internal only)
```

### 13.5 Security Best Practices

- Rotate all API keys every 365 days (or sooner if compromised).
- Review user access quarterly; deactivate accounts for departed employees immediately.
- Enable two-factor authentication for all Admin and Supervisor accounts.
- Never expose database ports (6379, 5433, 8812) to the public network.
- Conduct penetration testing annually.
- Monitor the audit log for unusual access patterns (failed logins, after-hours activity).

---

## 14. Internationalization Administration

### 14.1 Supported Languages

VoxGuard supports 10 languages. The i18n system uses i18next with JSON translation files.

| Code | Language | Direction | File |
|------|----------|-----------|------|
| `en` | English | LTR | `src/i18n/locales/en.json` |
| `fr` | Francais | LTR | `src/i18n/locales/fr.json` |
| `pt` | Portugues | LTR | `src/i18n/locales/pt.json` |
| `ha` | Hausa | LTR | `src/i18n/locales/ha.json` |
| `yo` | Yoruba | LTR | `src/i18n/locales/yo.json` |
| `ig` | Igbo | LTR | `src/i18n/locales/ig.json` |
| `ar` | Arabic | RTL | `src/i18n/locales/ar.json` |
| `es` | Espanol | LTR | `src/i18n/locales/es.json` |
| `zh` | Chinese | LTR | `src/i18n/locales/zh.json` |
| `sw` | Kiswahili | LTR | `src/i18n/locales/sw.json` |

### 14.2 Language Detection Order

The system detects the user's language in this order:
1. **localStorage**: Key `voxguard-language` (set when user changes language).
2. **Browser navigator**: The browser's default language setting.
3. **Fallback**: English (`en`).

### 14.3 RTL Support

Arabic (`ar`) triggers Right-to-Left layout direction. The entire UI layout mirrors automatically, including:
- Sidebar position (moves to right).
- Text alignment.
- Icon positioning.
- Form layouts.

### 14.4 Adding New Languages

To add a new language:
1. Create a new JSON translation file in `src/i18n/locales/` (e.g., `de.json`).
2. Copy the structure from `en.json` and translate all values.
3. Import the new file in `src/i18n/index.ts`.
4. Add the language to the `supportedLanguages` array with `code`, `label`, and `dir`.
5. Add the resource to the `i18n.init()` resources object.
6. Rebuild and deploy the frontend.

---

## 15. Troubleshooting and Support

### 15.1 Common Admin Issues

| Symptom | Likely Cause | Solution |
|---------|-------------|----------|
| Users cannot log in | Account locked or deactivated | Check user status in Users list; reactivate or wait for lockout to expire |
| Settings changes not taking effect | Browser cache | Instruct user to hard-refresh (`Ctrl+Shift+R`) |
| NCC report not generated | NCC reporting disabled or API key invalid | Check Settings > API & Integration; verify NCC API key |
| ML model stuck in "Retraining" | Training job failed | Check backend logs; restart the ML service if needed |
| Gateway showing "Offline" | Network issue or gateway down | Ping the gateway IP; check firewall rules; verify the gateway is running |
| Audit log entries missing | Archival job ran | Check warm/cold storage; adjust date range filter |
| High false positive rate | Thresholds too aggressive | Increase CPM thresholds and ACD thresholds in Settings > Detection |
| Export timeout | Dataset too large | Advise user to narrow date range or add filters |

### 15.2 Backend Diagnostic Commands

```bash
# Check all service statuses
docker-compose ps

# Check container resource usage
docker stats

# Check network connectivity between services
docker-compose exec acm-engine ping dragonfly
docker-compose exec acm-engine ping questdb
docker-compose exec acm-engine ping yugabyte

# Check logs for errors
docker-compose logs --tail=100 | grep -i error

# Database connection test
docker-compose exec acm-engine /health-check.sh

# Test detection endpoint
curl -X POST http://localhost:8080/api/v1/fraud/events \
  -H "Content-Type: application/json" \
  -d '{"call_id":"test-123","a_number":"+2348012345678","b_number":"+2348098765432","status":"active"}'
```

### 15.3 Emergency Procedures

**Emergency Service Restart:**
```bash
docker-compose restart acm-engine
```

**Clear Real-Time Cache (last resort -- causes temporary detection gap):**
```bash
redis-cli -p 6379 FLUSHDB
```

**Disable Detection Temporarily:**
```bash
curl -X PATCH http://localhost:8080/api/v1/config \
  -d '{"detection_enabled": false}'
```

**Force NCC Report Generation:**
```bash
docker-compose exec ncc-sftp-uploader /scripts/generate-daily-report.sh
```

### 15.4 Support Escalation Path

| Level | Contact | Response Time | Scope |
|-------|---------|---------------|-------|
| L1 | In-app help / helpdesk | 4 hours | User issues, password resets, access requests |
| L2 | Platform admin team | 2 hours | Configuration issues, report problems, data queries |
| L3 | Engineering team | 1 hour | Backend failures, data corruption, security incidents |
| L4 | Vendor support | Per SLA | Infrastructure failures, database issues, critical bugs |

**Emergency Contact:** +234-XXX-XXX-XXXX (24/7 for Critical issues)

---

## 16. Maintenance Procedures

### 16.1 Daily Maintenance Checklist

- [ ] Review critical and high-severity alerts on the dashboard.
- [ ] Verify system health via Grafana/Prometheus (all services green).
- [ ] Confirm daily NCC report generated and uploaded by 06:00 WAT.
- [ ] Review error logs for anomalies.
- [ ] Check DragonflyDB memory usage (should be below 80%).

### 16.2 Weekly Maintenance Checklist

- [ ] Review disk space across all services.
- [ ] Verify backup integrity (spot-check a recent backup).
- [ ] Review and clean up expired whitelist/blacklist entries.
- [ ] Check ML model performance metrics for drift.
- [ ] Review false positive rates and adjust thresholds if needed.

### 16.3 Monthly Maintenance Checklist

- [ ] Verify monthly NCC compliance report submitted by the 5th.
- [ ] Audit user accounts (deactivate departed employees, review role assignments).
- [ ] Review and rotate API keys approaching expiration.
- [ ] Apply security patches to all components.
- [ ] Capacity planning review (disk, memory, CPU trends).
- [ ] Rotate logs and archive old data.
- [ ] Review and optimize database queries.

### 16.4 Scheduled Maintenance Window

```
Maintenance Window: Sunday 02:00-04:00 WAT
Emergency Contact: +234-XXX-XXX-XXXX
Notification: 24 hours advance notice required

Procedure:
1. Send maintenance notification to all users (24h advance).
2. Enable maintenance mode in the application.
3. Perform updates, patches, and optimizations.
4. Run validation tests (health checks, smoke tests).
5. Disable maintenance mode.
6. Send completion notification to all users.
```

### 16.5 Version Upgrade Procedure

1. **Pre-Upgrade:**
   - Take a full backup of all databases.
   - Review release notes for breaking changes.
   - Test the upgrade in a staging environment.
   - Schedule the upgrade during the maintenance window.
   - Notify all users.

2. **Upgrade:**
   - Enable maintenance mode.
   - Pull new container images.
   - Run database migrations (Tier 2 operation).
   - Restart all services.
   - Run health checks and smoke tests.

3. **Post-Upgrade:**
   - Disable maintenance mode.
   - Monitor error logs for 1 hour.
   - Verify all dashboards and features are functioning.
   - Notify users of completion.
   - Document the upgrade in the change log.

---

## Appendix A: Quick Reference

### Essential Commands

```bash
# Service management
docker-compose ps                        # Check service status
docker-compose logs -f <service>         # Tail service logs
docker-compose restart <service>         # Restart a service
docker-compose down && docker-compose up -d  # Full restart

# Health checks
curl http://localhost:8080/health         # ACM Engine
curl http://localhost:8081/health         # Management API
curl http://localhost:9091/metrics        # Prometheus metrics

# Configuration
curl http://localhost:8080/api/v1/config  # View current config
```

### Key File Locations

| File | Purpose |
|------|---------|
| `.env` | Environment variables (secrets, config) |
| `docker-compose.yml` | Service definitions |
| `config/` | Application configuration files |
| `src/i18n/locales/` | Translation files (frontend) |
| `/var/backups/acm/` | Backup storage |
| `/var/log/acm/` | Application logs |

### Default Credentials (Development Only)

| Service | Username | Password |
|---------|----------|----------|
| VoxGuard | admin@voxguard.ng | admin123 |
| Grafana | admin | (set in .env) |
| QuestDB | admin | admin |
| YugabyteDB | opensips | (set in .env) |

**WARNING:** Change all default credentials before deploying to production.

---

**Document Version:** 2.1
**Classification:** Internal Use Only -- Restricted to Administrators
**Last Updated:** February 2026
