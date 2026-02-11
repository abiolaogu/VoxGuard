# VoxGuard Web Dashboard - User Guide

**Version:** 2.0.0
**Date:** February 3, 2026
**Status:** Production Ready

---

## Table of Contents

1. [Overview](#overview)
2. [Accessing the Dashboard](#accessing-the-dashboard)
3. [Dashboard Home](#dashboard-home)
4. [Alert Management](#alert-management)
5. [Gateway Management](#gateway-management)
6. [User Management](#user-management)
7. [Analytics](#analytics)
8. [Settings](#settings)
9. [External Tools](#external-tools)
10. [Best Practices](#best-practices)
11. [Troubleshooting](#troubleshooting)

---

## Overview

The VoxGuard Web Dashboard is your central hub for monitoring, investigating, and managing call masking fraud detection across the Nigerian telecommunications network.

### Primary User Roles

1. **Fraud Analysts** - Review and triage fraud alerts, investigate suspicious patterns
2. **NOC Engineers** - Monitor system health, manage infrastructure
3. **Compliance Officers** - Generate reports, audit trails, regulatory submissions
4. **System Administrators** - User management, configuration

### Key Capabilities

- **Real-time monitoring** of fraud alerts with <1 second latency
- **Interactive investigation** tools for alert triage
- **Gateway blacklisting** for confirmed fraud sources
- **Comprehensive analytics** with 24-hour trend analysis
- **Quick access** to external monitoring tools (Grafana, Prometheus, etc.)

---

## Accessing the Dashboard

### Login

1. Navigate to the dashboard URL (default: http://localhost:5173 in development)
2. Enter your credentials on the login page
3. Click "Sign In"

**Default Credentials (Development):**
- Username: `admin@voxguard.ng`
- Password: `admin123` (⚠️ Change in production!)

### Authentication

- Sessions are JWT-based with 24-hour expiration
- Tokens stored securely in browser storage
- Automatic redirect to login on session expiration
- Role-based access control (RBAC) enforced

---

## Dashboard Home

The Dashboard Home provides an at-a-glance view of system status and recent activity.

### Statistics Cards

Four real-time metrics displayed at the top:

1. **New Alerts** (Blue) - Unreviewed fraud alerts requiring attention
2. **Critical Alerts** (Red) - High-severity threats with pulsing indicator
3. **Investigating** (Yellow) - Alerts currently under investigation
4. **Confirmed** (Red) - Verified fraud incidents

**Real-time Updates:** Counts update automatically via WebSocket subscriptions.

### Quick Access Toolbar

One-click access to external monitoring tools:

- **Grafana** - Visual metrics and dashboards
- **Prometheus** - Time-series metrics and alerting
- **QuestDB** - Time-series database console
- **ClickHouse** - OLAP database query interface
- **YugabyteDB** - Distributed SQL database
- **Homer SIP** - SIP message capture and analysis

Click any button to open the tool in a new browser tab.

### Charts & Visualizations

#### 1. Alert Trends (24h)
- **Type:** Multi-line time series chart
- **Data:** Alert volume over last 24 hours
- **Breakdown:** By severity (Critical, High, Medium)
- **Use Case:** Identify peak fraud periods, detect anomalies

#### 2. Alerts by Severity
- **Type:** Pie chart
- **Data:** Distribution of alerts by severity level
- **Color Coding:**
  - 🔴 Critical - Immediate action required
  - 🟠 High - Priority investigation
  - 🟡 Medium - Standard review
  - 🔵 Low - Monitoring only
- **Use Case:** Resource allocation for investigation teams

#### 3. Traffic Overview
- **Type:** Area chart
- **Data:** Call volume metrics
- **Metrics:** Total calls, flagged calls, blocked calls
- **Use Case:** Understand overall traffic patterns vs fraud rates

### Recent Alerts Table

Displays the 10 most recent alerts with:

- **Time:** Relative timestamp (e.g., "5 minutes ago")
- **B-Number:** Called number (clickable to view details)
- **Severity:** Color-coded severity badge
- **Status:** Current investigation status
- **Score:** Threat score (0-100%)

**Actions:**
- Click B-Number to view full alert details
- Click "View All →" to see complete alert list

---

## Alert Management

### Alert List View

**Path:** `/alerts`

Comprehensive table of all fraud alerts with advanced filtering:

#### Columns

- **ID** - Unique alert identifier
- **B-Number** - Called/destination number
- **A-Number** - Calling/source number
- **Severity** - Threat level (Critical/High/Medium/Low)
- **Status** - Investigation status
- **Threat Score** - ML model confidence (0-100%)
- **Carrier** - Network operator
- **Created At** - Detection timestamp
- **Actions** - View/Edit buttons

#### Filters

- **Severity Filter** - Multi-select: Critical, High, Medium, Low
- **Status Filter** - Multi-select: New, Investigating, Confirmed, Resolved, False Positive
- **Date Range** - Custom date picker
- **Carrier Filter** - Filter by network operator
- **Search** - Full-text search on phone numbers

#### Bulk Actions

- **Export to CSV** - Download filtered results
- **Bulk Status Update** - Change status for multiple alerts
- **Mass Investigation** - Assign multiple alerts to analyst

### Alert Detail View

**Path:** `/alerts/show/:id`

Deep dive into individual alert with:

#### Call Details Section

- **A-Number** - Source number with carrier lookup
- **B-Number** - Destination number with MNP check
- **Call Duration** - Length of call attempt
- **Timestamp** - Exact detection time with timezone
- **Gateway Info** - Originating gateway ID and IP

#### Detection Analysis

- **Threat Score** - Overall fraud probability (0-100%)
- **Detection Method** - Rule-based, ML model, or hybrid
- **Matched Rules** - List of triggered detection rules
- **Risk Factors** - Specific fraud indicators:
  - CLI vs IP country mismatch
  - SIM-box behavioral patterns
  - Known fraudulent number database match
  - Abnormal call volume patterns

#### SIP Metadata

- **Call-ID** - SIP session identifier
- **From Header** - SIP From field
- **To Header** - SIP To field
- **Via Headers** - Call routing path
- **User-Agent** - Device/software identifier

#### Investigation History

Timeline of all actions taken:
- Status changes
- Analyst comments
- Gateway blacklist actions
- Resolution decisions

#### Actions

- **Update Status** - Change investigation status
- **Add Comment** - Document investigation notes
- **Blacklist Gateway** - Block source gateway
- **False Positive** - Mark as non-fraud
- **Export Report** - Generate PDF investigation report

### Alert Edit View

**Path:** `/alerts/edit/:id`

Quick status and metadata updates:

- **Status Dropdown** - Change investigation status
- **Severity Override** - Adjust threat level (with justification)
- **Analyst Assignment** - Assign to team member
- **Investigation Notes** - Add detailed comments
- **Tags** - Custom categorization labels

**Save Actions:**
- **Save & Next** - Update and move to next alert
- **Save & Close** - Update and return to list
- **Cancel** - Discard changes

---

## Gateway Management

### Gateway List View

**Path:** `/gateways`

Manage voice gateways and interconnect partners:

#### Table Columns

- **Gateway ID** - Unique identifier
- **Name** - Friendly gateway name
- **IP Address** - Gateway IP or hostname
- **Carrier** - Associated network operator
- **Status** - Active, Suspended, Blacklisted
- **Risk Score** - Historical fraud rate (0-100%)
- **Last Seen** - Most recent call timestamp
- **Total Calls** - Call volume (lifetime)
- **Fraud Rate** - Percentage of fraudulent calls
- **Actions** - View/Edit/Blacklist

#### Filters

- **Status Filter** - Active, Suspended, Blacklisted
- **Carrier Filter** - Filter by operator
- **Risk Score Range** - Slider to filter by risk level
- **Search** - Gateway name or IP search

### Gateway Detail View

**Path:** `/gateways/show/:id`

Comprehensive gateway profile:

#### Basic Information

- **Gateway Name** - Friendly identifier
- **IP Address** - IPv4/IPv6 address
- **Port** - SIP port (typically 5060/5061)
- **Protocol** - UDP/TCP/TLS
- **Carrier** - Network operator
- **Location** - Geographic location
- **Contact** - Technical contact info

#### Statistics

- **Total Calls** - Lifetime call volume
- **Fraud Alerts** - Number of triggered alerts
- **Fraud Rate** - Percentage calculation
- **Average Threat Score** - Mean ML confidence
- **Blacklist Status** - Current blocking status
- **First Seen** - Initial detection date
- **Last Activity** - Most recent call

#### Alert History

Table of all alerts originating from this gateway:
- Chronological list
- Severity breakdown
- Investigation status
- Quick links to alert details

#### Actions

- **Blacklist Gateway** - Block all calls from this source
- **Whitelist Gateway** - Remove from blacklist
- **Suspend Temporarily** - Pause routing (reversible)
- **Generate Report** - PDF report for compliance
- **Export Call Records** - CSV download

### Gateway Create View

**Path:** `/gateways/create`

Add new gateway to monitoring system:

#### Required Fields

- **Gateway Name** - Unique, descriptive name
- **IP Address** - Valid IPv4/IPv6
- **Carrier** - Select from operator list
- **Status** - Initial status (typically Active)

#### Optional Fields

- **Port** - Default 5060
- **Protocol** - Default UDP
- **Location** - Geographic info
- **Notes** - Additional context

**Validation:**
- IP address format check
- Duplicate gateway detection
- Required field enforcement

### Gateway Edit View

**Path:** `/gateways/edit/:id`

Modify gateway configuration:

- Update gateway metadata
- Change blacklist status
- Adjust risk score manually (with audit trail)
- Add investigation notes

---

## User Management

### User List View

**Path:** `/users`

Manage dashboard user accounts:

#### Table Columns

- **Name** - Full name
- **Email** - Login email address
- **Role** - Fraud Analyst, NOC Engineer, Compliance Officer, Admin
- **Status** - Active, Inactive, Locked
- **Last Login** - Most recent session
- **Created At** - Account creation date
- **Actions** - View/Edit/Deactivate

#### Roles & Permissions

| Role | Permissions |
|------|-------------|
| **Fraud Analyst** | View alerts, update status, add comments |
| **NOC Engineer** | All analyst permissions + gateway management |
| **Compliance Officer** | All analyst permissions + report generation |
| **Admin** | All permissions + user management |

### User Detail View

**Path:** `/users/show/:id`

User profile and activity:

- **Basic Info** - Name, email, phone
- **Role & Status** - Current role assignment
- **Login History** - Session timestamps and IPs
- **Activity Log** - Alert investigations, status changes
- **Audit Trail** - All actions taken

### User Create View

**Path:** `/users/create`

Create new user account:

#### Required Fields

- **Full Name**
- **Email Address** - Must be unique
- **Password** - Minimum 8 characters, complexity requirements
- **Role** - Select from available roles

#### Optional Fields

- **Phone Number** - For 2FA or notifications
- **Department** - Organizational unit
- **Notes** - Additional context

**Security:**
- Password strength validation
- Email verification sent
- Initial login forces password change

### User Edit View

**Path:** `/users/edit/:id`

Modify user account:

- Update profile information
- Change role assignment (Admin only)
- Reset password
- Activate/Deactivate account
- View audit log

---

## Analytics

**Path:** `/analytics`

Advanced fraud analytics and business intelligence:

### Key Metrics

- **Total Alerts (30 days)** - Volume trend
- **Detection Accuracy** - True positive rate
- **Average Response Time** - Time to investigation
- **Top Fraud Sources** - Geographic or gateway breakdown

### Visualizations

1. **Fraud Trend Analysis** - Multi-week comparison
2. **Carrier-wise Distribution** - Alerts by operator
3. **Time-of-Day Patterns** - Peak fraud hours
4. **ML Model Performance** - Accuracy, precision, recall over time

### Reports

- **Daily Summary** - Automated daily report generation
- **Weekly Executive Report** - High-level KPIs
- **NCC Compliance Report** - Regulatory submission format
- **Custom Report Builder** - Ad-hoc analysis

### Export Options

- **CSV** - Raw data export
- **PDF** - Formatted report with charts
- **JSON** - API-compatible format

---

## Settings

**Path:** `/settings`

Configure dashboard preferences and system settings:

### General Settings

- **Time Zone** - Set preferred timezone
- **Date Format** - Choose date display format
- **Language** - Interface language (English default)
- **Notifications** - Enable/disable alert notifications

### Display Preferences

- **Theme** - Light/Dark mode toggle
- **Density** - Compact/Standard/Comfortable
- **Chart Colors** - Customize color scheme
- **Default View** - Set startup page

### Alert Configuration

- **Auto-Refresh Interval** - Real-time update frequency
- **Alert Sound** - Enable/disable audio alerts
- **Severity Thresholds** - Customize threat score ranges
- **Default Filters** - Pre-set filter preferences

### Integration Settings

- **API Keys** - Manage external integrations
- **Webhook URLs** - Configure alert webhooks
- **SMTP Settings** - Email notification config
- **Slack Integration** - Alert channel configuration

### Security Settings

- **Session Timeout** - Auto-logout duration
- **2FA Configuration** - Two-factor authentication
- **IP Whitelist** - Restrict access by IP
- **Audit Log Retention** - Log storage duration

---

## External Tools

### Grafana

**Purpose:** Visual metrics dashboards and alerting

**Key Dashboards:**
- VoxGuard System Health
- Detection Engine Performance
- Database Metrics (QuestDB, YugabyteDB)
- Network Traffic Overview

**Access:** Click "Grafana" in Quick Access toolbar

### Prometheus

**Purpose:** Metrics collection and alerting rules

**Key Metrics:**
- `voxguard_alerts_total` - Total alerts by severity
- `voxguard_detection_latency_p99` - P99 detection latency
- `voxguard_calls_per_second` - Throughput metrics
- `voxguard_database_query_duration` - DB performance

**Access:** Click "Prometheus" in Quick Access toolbar

### QuestDB

**Purpose:** Time-series database for call detail records (CDRs)

**Use Cases:**
- Query historical CDRs
- Analyze call patterns
- Export data for compliance
- Run custom SQL queries

**Access:** Click "QuestDB" in Quick Access toolbar

### ClickHouse

**Purpose:** OLAP database for analytics queries

**Use Cases:**
- Complex aggregation queries
- Multi-dimensional analysis
- Large-scale data exports
- Custom reporting

**Access:** Click "ClickHouse" in Quick Access toolbar

### YugabyteDB

**Purpose:** Distributed SQL database (PostgreSQL-compatible)

**Use Cases:**
- Production database access
- Schema management
- Data consistency checks
- Backup management

**Access:** Click "YugabyteDB" in Quick Access toolbar

### Homer SIP

**Purpose:** SIP message capture and VoIP troubleshooting

**Use Cases:**
- SIP trace analysis
- Call flow debugging
- Protocol compliance verification
- VoIP quality monitoring

**Access:** Click "Homer SIP" in Quick Access toolbar

---

## Best Practices

### For Fraud Analysts

1. **Triage Workflow**
   - Start with Critical severity alerts
   - Review alerts in chronological order
   - Document investigation notes for all decisions
   - Use bulk actions for efficiency

2. **Investigation Process**
   - Verify MNP data for called numbers
   - Check gateway fraud history
   - Review SIP metadata for anomalies
   - Correlate with external threat intelligence

3. **Decision Making**
   - False Positive: Clear non-fraud with justification
   - Confirmed: Blacklist gateway and escalate
   - Investigating: Add comments and continue analysis

### For NOC Engineers

1. **System Monitoring**
   - Check dashboard every 30 minutes
   - Monitor Critical alert counts
   - Review Grafana system health dashboards
   - Set up Prometheus alerts for P99 latency spikes

2. **Gateway Management**
   - Audit high-risk gateways weekly
   - Review blacklist effectiveness
   - Coordinate with carriers on suspicious gateways
   - Document all blacklist actions

### For Compliance Officers

1. **Reporting**
   - Generate daily summary reports
   - Export NCC compliance data by 5 PM daily
   - Maintain 7-year audit trail
   - Document settlement disputes

2. **Audit Trail**
   - Verify all alert resolutions have justifications
   - Review user activity logs monthly
   - Export compliance reports for NCC submission
   - Archive historical data quarterly

---

## Troubleshooting

### Common Issues

#### 1. Dashboard Not Loading

**Symptoms:** Blank page, loading spinner indefinitely

**Solutions:**
- Check browser console for errors (F12)
- Verify Hasura GraphQL endpoint is accessible
- Clear browser cache and reload (Ctrl+Shift+R)
- Check network connectivity

#### 2. Real-Time Updates Not Working

**Symptoms:** Alert counts not updating, no live data

**Solutions:**
- Check WebSocket connection in Network tab
- Verify `VITE_HASURA_WS_ENDPOINT` configuration
- Check firewall allows WebSocket connections
- Refresh page to re-establish subscription

#### 3. Authentication Failures

**Symptoms:** "Invalid credentials" or automatic logout

**Solutions:**
- Verify username and password
- Check JWT token expiration (24 hours default)
- Clear localStorage and re-login
- Contact admin if account is locked

#### 4. Slow Performance

**Symptoms:** Laggy UI, slow page loads

**Solutions:**
- Check network latency to backend services
- Reduce auto-refresh intervals in Settings
- Clear browser cache
- Disable browser extensions
- Check system resources (CPU, memory)

#### 5. Charts Not Displaying

**Symptoms:** Empty chart areas, broken visualizations

**Solutions:**
- Check browser console for JavaScript errors
- Verify data is available for selected time range
- Refresh page
- Try different time range or filters
- Check Hasura data connectivity

### Error Messages

#### "GraphQL Error: Unauthorized"

**Cause:** JWT token expired or invalid

**Solution:** Log out and log back in

#### "Network Error: Failed to fetch"

**Cause:** Backend service unavailable

**Solution:** Check service status, contact NOC team

#### "Subscription Error: Connection closed"

**Cause:** WebSocket connection lost

**Solution:** Refresh page to re-establish connection

### Getting Help

1. **Documentation** - Check this guide and README files
2. **Factory Protocol** - Review `CLAUDE.md` for system guidelines
3. **Issue Tracker** - Create GitHub issue with error details
4. **NOC Team** - Contact for infrastructure issues
5. **Admin** - Contact for user/permission issues

---

## Appendix

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl + K` | Open command palette (Refine Kbar) |
| `Ctrl + /` | Toggle sidebar |
| `Esc` | Close modal/dialog |

### Browser Support

- ✅ Chrome 90+ (Recommended)
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Edge 90+
- ⚠️ Internet Explorer: Not supported

### Mobile Support

The dashboard is responsive and works on mobile devices:
- Optimized for tablets (iPad, Android tablets)
- Functional on smartphones (limited features)
- Best experience on desktop/laptop

### Accessibility

- WCAG 2.1 Level AA compliance target
- Keyboard navigation support
- Screen reader compatible
- High contrast mode available

---

**Document Version:** 1.0
**Last Updated:** 2026-02-03
**Next Review:** 2026-03-03
**Owner:** Factory Autonomous System
**Contact:** fraud-ops@voxguard.ng
