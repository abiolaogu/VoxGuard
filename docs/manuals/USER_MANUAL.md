# VoxGuard User Manual

## Anti-Call Masking & Voice Network Fraud Detection Platform

**Version:** 2.1
**Last Updated:** February 2026
**Audience:** Dashboard Users, Fraud Analysts, Operators, Supervisors, Compliance Officers

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Getting Started](#2-getting-started)
3. [Dashboard](#3-dashboard)
4. [Alert Management](#4-alert-management)
5. [Case Management](#5-case-management)
6. [CDR Browser](#6-cdr-browser)
7. [KPI Scorecard](#7-kpi-scorecard)
8. [Security Pages](#8-security-pages)
9. [NCC Compliance](#9-ncc-compliance)
10. [Audit Log](#10-audit-log)
11. [ML Dashboard](#11-ml-dashboard)
12. [Report Builder](#12-report-builder)
13. [Settings](#13-settings)
14. [AIDD Tier System](#14-aidd-tier-system)
15. [Keyboard Shortcuts](#15-keyboard-shortcuts)
16. [Troubleshooting](#16-troubleshooting)
17. [Glossary](#17-glossary)

---

## 1. Introduction

### 1.1 About VoxGuard

VoxGuard is an enterprise Anti-Call Masking and Voice Network Fraud Detection Platform designed for telecommunications operators. It provides real-time detection of CLI spoofing, Wangiri callback fraud, IRSF (International Revenue Share Fraud), SIM box bypass, revenue leakage, and other voice network fraud schemes.

The platform combines high-throughput rule-based detection engines (built on Rust + QuestDB + DragonflyDB + YugabyteDB) with machine learning models to deliver sub-millisecond fraud detection at scale.

### 1.2 Key Capabilities

- **Real-time Fraud Detection**: Sub-millisecond detection of call masking attacks and voice fraud patterns.
- **Case Management**: Full investigative workflow from alert triage to resolution.
- **CDR Browser**: Search, filter, and export Call Detail Records across all gateways.
- **KPI Scorecards**: At-a-glance operational health metrics with trend analysis.
- **ML-Powered Scoring**: Machine learning models for fraud probability scoring and anomaly detection.
- **NCC Compliance**: Automated regulatory report generation and submission to the Nigerian Communications Commission.
- **Internationalization**: Full UI support for 10 languages including RTL (Arabic).
- **Multi-Currency**: Display monetary values in NGN, USD, EUR, GBP, and other currencies.
- **Audit Trail**: Comprehensive logging of all user and system actions with 7-year retention.
- **Report Builder**: Generate, schedule, and export custom reports in PDF, Excel, and CSV.

### 1.3 User Roles

| Role | Permissions |
|------|-------------|
| **Viewer** | View dashboards, alerts, analytics, and reports |
| **Operator** | Viewer + acknowledge alerts, view cases |
| **Analyst** | Operator + investigate alerts, manage cases, whitelist/blacklist, CDR search, mark false positives |
| **Supervisor** | Analyst + configure detection settings, approve escalations, manage report schedules |
| **Admin** | Full system access including user management, ML model administration, AIDD Tier 2 operations |

### 1.4 Supported Browsers

| Browser | Minimum Version |
|---------|-----------------|
| Chrome | 90+ |
| Firefox | 88+ |
| Safari | 14+ |
| Edge | 90+ |

JavaScript, cookies, and WebSocket connections must be enabled.

---

## 2. Getting Started

### 2.1 Logging In

1. Open your browser and navigate to your organization's VoxGuard URL (e.g., `https://voxguard.yourcompany.com`).
2. Enter your username (email) and password on the login page.
3. Complete two-factor authentication if enabled for your account.
4. Click **Sign In**.

<!-- Screenshot: Login page showing the VoxGuard logo, email/password fields, "Sign In" button, and the dark/light theme toggle. -->

**First-Time Login:**
- Change your temporary password when prompted.
- Set up two-factor authentication if required by your organization.
- Configure your notification preferences in Settings.

**Session Duration:** JWT-based sessions expire after 24 hours of inactivity. You will be redirected to the login page automatically.

### 2.2 Dashboard Overview on First Login

After logging in, you are directed to the main **Dashboard** page. The interface consists of:

- **Header**: VoxGuard logo, breadcrumb navigation, language switcher, currency switcher, theme toggle (light/dark), notification bell, and user menu.
- **Sidebar**: Collapsible navigation menu with links to all platform sections.
- **Content Area**: The active page content.

<!-- Screenshot: Full dashboard layout showing the header with language/currency switchers, the collapsible sidebar, and the main content area with statistic cards and charts. -->

### 2.3 Navigation

The sidebar menu provides access to all sections:

| Menu Item | Description |
|-----------|-------------|
| **Dashboard** | Main monitoring overview |
| **Alerts** | Alert queue, detail views, and investigation |
| **Cases** | Case management and investigation workflows |
| **CDR Browser** | Call Detail Record search and export |
| **KPI Scorecard** | Key performance indicators and trends |
| **Security** | RVS Dashboard, Composite Scoring, Lists, Multi-Call Detection, Revenue Fraud, Traffic Control, False Positives |
| **NCC** | NCC Compliance reports and MNP Lookup |
| **Audit Log** | System and user activity log |
| **ML Dashboard** | Machine learning model monitoring |
| **Reports** | Report generation, scheduling, and history |
| **Gateways** | Gateway monitoring and management |
| **Users** | User management (Admin only) |
| **Analytics** | Historical charts and statistics |
| **Settings** | System configuration |

Click the collapse button at the top of the sidebar to minimize it to icon-only mode, giving more horizontal space to the content area.

### 2.4 Language and Currency Selection

**Language:**
- Click the globe icon in the header to open the language selector.
- Choose from 10 available languages: English, Francais, Portugues, Hausa, Yoruba, Igbo, Arabic, Espanol, Chinese, Kiswahili.
- The UI updates immediately. Arabic switches the layout direction to RTL.
- Your preference is persisted in browser local storage.

**Currency:**
- Click the currency icon in the header or go to **Settings > Language & Region**.
- Select your preferred currency. All monetary values (estimated losses, revenue protected, KPI figures) update accordingly.

---

## 3. Dashboard

The Dashboard is the central monitoring hub. It provides a real-time overview of fraud detection activity.

### 3.1 Statistic Cards

Four key metrics are displayed at the top of the dashboard:

| Card | Color | Description |
|------|-------|-------------|
| **New Alerts** | Blue | Unreviewed fraud alerts requiring attention |
| **Critical Alerts** | Red (pulsing) | High-severity threats needing immediate response |
| **Investigating** | Yellow | Alerts currently under active investigation |
| **Confirmed** | Red | Verified fraud incidents |

All counts update automatically via WebSocket subscriptions.

<!-- Screenshot: Dashboard statistic cards showing "New Alerts: 12", "Critical Alerts: 3" (with pulsing animation), "Investigating: 5", "Confirmed: 2". -->

### 3.2 Charts and Visualizations

**Alert Trends (24h)**
- Type: Multi-line time-series chart.
- Shows alert volume over the last 24 hours, broken down by severity (Critical, High, Medium).
- Hover over any point for exact count and timestamp.

**Severity Distribution**
- Type: Pie chart.
- Displays the proportion of alerts at each severity level.
- Click any segment to filter the alerts list by that severity.

**Traffic Area Chart**
- Type: Stacked area chart.
- Shows total call volume and the anomalous traffic overlay.
- Useful for identifying traffic spikes correlated with fraud activity.

<!-- Screenshot: Dashboard charts section showing the Alert Trends line chart, Severity Distribution pie chart, and Traffic Area chart arranged in a responsive grid layout. -->

### 3.3 Quick Access Toolbar

One-click buttons provide access to external monitoring tools (opens in new tabs):

| Tool | Purpose |
|------|---------|
| **Grafana** | Visual metrics dashboards |
| **Prometheus** | Time-series metrics and alerting |
| **QuestDB** | Time-series database console |
| **ClickHouse** | OLAP query interface |
| **YugabyteDB** | Distributed SQL database |
| **Homer SIP** | SIP message capture and analysis |

### 3.4 Quick Actions

From the dashboard you can:
- Click any statistic card to navigate to the filtered alerts list.
- Click chart segments to drill down into specific categories.
- Use the refresh button to force an immediate data update.

---

## 4. Alert Management

### 4.1 Alert List

Navigate to **Alerts** to view the alert queue.

<!-- Screenshot: Alert list page showing a table with columns for Severity (color-coded tag), Alert ID, B-Number, A-Number Count, Detection Window, Status, Assigned To, and Timestamp. Filter controls are visible at the top. -->

**Columns:**

| Column | Description |
|--------|-------------|
| **Severity** | Color-coded tag (Critical/High/Medium/Low) |
| **Alert ID** | Unique identifier (e.g., ACM-2026-001234) |
| **B-Number** | The targeted phone number |
| **A-Numbers** | Count of distinct calling numbers detected |
| **Window** | Detection window duration in seconds |
| **Status** | New, Acknowledged, Investigating, Resolved, False Positive |
| **Assigned To** | The analyst handling the alert |
| **Timestamp** | When the alert was generated |

### 4.2 Filtering Alerts

Use the filter controls at the top of the list:

- **Status**: New, Acknowledged, Investigating, Resolved, False Positive.
- **Severity**: Critical, High, Medium, Low.
- **Date Range**: Select start and end dates.
- **B-Number**: Search by targeted phone number.
- **Assigned To**: Filter by analyst name.

Filters can be combined. Active filters are shown as removable tags below the filter bar.

### 4.3 Alert Detail View

Click any alert row to open the detail view.

<!-- Screenshot: Alert detail page showing the alert header (ID, severity badge, timestamp), the targeted B-number, a list of all involved A-numbers with their source gateways, a call timeline visualization, the geographic origin map, and action buttons along the bottom. -->

**Information Displayed:**
- Alert ID, severity, and status
- Targeted B-number and all involved A-numbers
- Detection window duration
- Source gateway(s) and IP addresses
- Threat score (composite score from ML models and rules)
- Call timeline visualization
- Geographic visualization of attack origins
- Related alerts (if any)
- Investigation notes and history

### 4.4 Alert Actions

| Action | Description | Required Role | AIDD Tier |
|--------|-------------|---------------|-----------|
| **Acknowledge** | Take ownership of the alert | Operator+ | 0 |
| **Investigate** | Start a formal investigation | Analyst+ | 0 |
| **Disconnect** | Terminate active fraudulent calls | Analyst+ | 1 |
| **Block** | Block the A-number pattern | Analyst+ | 1 |
| **Whitelist** | Add B-number to whitelist (known legitimate) | Analyst+ | 1 |
| **Escalate** | Send to supervisor or NCC | Operator+ | 1 (to supervisor) / 2 (to NCC) |
| **Link to Case** | Attach alert to an existing or new case | Analyst+ | 0 |
| **Resolve** | Mark as handled | Analyst+ | 0 |
| **False Positive** | Mark as incorrect detection | Analyst+ | 1 |

### 4.5 Bulk Actions

1. Select multiple alerts using the checkboxes in the leftmost column.
2. Click the **Bulk Actions** dropdown.
3. Choose: Acknowledge All, Resolve All, Export Selected, or Assign To.
4. Confirm when prompted.

---

## 5. Case Management

Cases are the primary mechanism for tracking fraud investigations from initial detection through resolution.

### 5.1 Case List

Navigate to **Cases** from the sidebar.

<!-- Screenshot: Case list page showing a table with columns for Case ID, Title, Status (color-coded tag), Severity, Fraud Type, Assignee, Linked Alerts count, Estimated Loss (currency-formatted), and timestamps. A "+ New Case" button is visible at the top right. Search and filter controls are at the top. -->

**Columns:**

| Column | Description |
|--------|-------------|
| **Case ID** | Unique identifier (e.g., CASE-2025-001) |
| **Title** | Descriptive case name |
| **Status** | Open, Investigating, Escalated, Resolved, Closed, False Positive |
| **Severity** | Critical, High, Medium, Low |
| **Fraud Type** | CLI Spoofing, Wangiri, IRSF, SIM Box, Revenue Fraud, Other |
| **Assignee** | Responsible analyst |
| **Linked Alerts** | Number of alerts linked to this case |
| **Estimated Loss** | Total estimated financial impact (formatted in selected currency) |
| **Created** | Case creation date |
| **Updated** | Last modification date |

### 5.2 Creating a Case

1. Click the **+ New Case** button.
2. Fill in the form:
   - **Title**: Descriptive name.
   - **Description**: Detailed description of the suspected fraud.
   - **Severity**: Critical, High, Medium, or Low.
   - **Fraud Type**: Select from the dropdown.
   - **Assignee**: Select the responsible analyst.
3. Click **Create**.

### 5.3 Case Detail View

Click any case row to open the detail view.

<!-- Screenshot: Case detail page showing the case header (ID, title, status badge, severity badge), description, assignee, fraud type, estimated loss, a "Linked Alerts" section with a table of associated alerts, a "Linked CDRs" section, a "Notes" section with a timeline of investigation notes, and action buttons (Investigate, Escalate, Resolve, Close). -->

The case detail view includes:
- **Summary**: Case metadata, status, severity, assignee, estimated loss.
- **Linked Alerts**: Table of all alerts linked to this case.
- **Linked CDRs**: Call Detail Records attached as evidence.
- **Notes**: Chronological timeline of investigation notes with author and timestamp.
- **Activity Log**: History of all status changes and actions taken on the case.

### 5.4 Adding Notes

1. In the case detail view, scroll to the **Notes** section.
2. Type your investigation note in the text area.
3. Click **Add Note**. The note is saved with your username and the current timestamp.

Notes support plain text. Each note records the author name and timestamp automatically.

### 5.5 Escalating a Case

1. Open the case detail view.
2. Click **Escalate**.
3. Select the escalation target:
   - **Supervisor**: Internal escalation for higher-authority review.
   - **NCC**: Regulatory escalation for cross-operator investigation (Tier 2).
   - **Cross-Operator**: Request cooperation from another telecom operator.
4. Provide a reason for escalation.
5. Confirm. The case status changes to "Escalated".

### 5.6 Resolving a Case

1. Open the case detail view.
2. Click **Resolve**.
3. Provide a resolution summary describing the outcome and actions taken.
4. The case status changes to "Resolved". Resolved cases remain searchable and accessible for audit purposes.

---

## 6. CDR Browser

The CDR (Call Detail Record) Browser allows you to search, filter, and export raw call records across all gateways.

### 6.1 Searching CDRs

Navigate to **CDR Browser** from the sidebar.

<!-- Screenshot: CDR Browser page showing filter controls at the top (A-Number input, B-Number input, Date Range picker, Country dropdown, Gateway dropdown) and a data table below with columns for CDR ID, A-Number, B-Number, Start Time, End Time, Duration, Call Type, Direction, Gateway, Country, and Status. -->

**Available Filters:**

| Filter | Description |
|--------|-------------|
| **A-Number** | Calling party number (partial match supported) |
| **B-Number** | Called party number (partial match supported) |
| **Date Range** | Start and end date/time range |
| **Country** | Originating country |
| **Gateway** | Gateway that handled the call |
| **Call Type** | Voice, SMS, or Data |
| **Direction** | Inbound, Outbound, or Local |
| **Status** | Completed, Failed, or Dropped |

Enter your search criteria and the results table updates automatically. Columns are sortable by clicking the column header.

### 6.2 Understanding CDR Fields

| Field | Description |
|-------|-------------|
| **CDR ID** | Unique record identifier |
| **A-Number** | Calling party phone number (source) |
| **B-Number** | Called party phone number (destination) |
| **Start Time** | Call initiation timestamp |
| **End Time** | Call termination timestamp |
| **Duration** | Call duration in seconds |
| **Call Type** | Voice, SMS, or Data |
| **Direction** | Inbound, Outbound, or Local |
| **Gateway** | The network gateway that processed the call |
| **Country** | Country of origin for the A-Number |
| **Status** | Completed, Failed, or Dropped |

### 6.3 Exporting CDR Data

1. Apply your desired filters.
2. Click the **Export** button (download icon).
3. Select the format: CSV, Excel, or PDF.
4. The export downloads to your browser. For datasets exceeding 100,000 records, the export is processed asynchronously and a notification is sent when the file is ready.

### 6.4 Linking CDRs to Cases

1. Select one or more CDR records using the checkboxes.
2. Click **Link to Case** from the toolbar.
3. Select an existing case or create a new one.
4. The CDRs appear in the case detail under "Linked CDRs".

---

## 7. KPI Scorecard

The KPI Scorecard provides a consolidated view of key operational metrics with trend indicators.

### 7.1 Accessing the Scorecard

Navigate to **KPI Scorecard** from the sidebar.

<!-- Screenshot: KPI Scorecard page showing a period selector (24h / 7d / 30d segments) at the top, followed by a grid of 8 KPI cards. Each card shows an icon, the metric name, the current value, and a trend indicator (green up arrow for positive trends, red up arrow for negative trends). -->

### 7.2 Understanding the Metrics

| Metric | Description | Good Trend |
|--------|-------------|------------|
| **Detection Rate** | Percentage of fraud successfully detected (target: 95%+) | Up |
| **False Positive Rate** | Percentage of alerts that are false positives (target: below 5%) | Down |
| **MTTI (Mean Time to Investigate)** | Average time from alert creation to investigation start | Down |
| **MTTR (Mean Time to Resolve)** | Average time from alert creation to resolution | Down |
| **Revenue Protected** | Estimated monetary value of fraud prevented (in selected currency) | Up |
| **Active Cases** | Number of open/investigating cases | Down (fewer is better) |
| **Model Accuracy** | Current ML model accuracy score | Up |
| **Alert Volume** | Total number of alerts generated in the period | Down (fewer is better) |

Each metric card displays:
- The metric value with appropriate formatting (percentage, currency, duration, count).
- A trend indicator showing the change compared to the previous period.
- A color-coded arrow: green if the trend is positive, red if negative.

### 7.3 Period Selection

Use the segmented control at the top to switch between time periods:
- **24h**: Last 24 hours of data.
- **7d**: Last 7 days of data.
- **30d**: Last 30 days of data.

Metrics and trends recalculate immediately when you change the period.

---

## 8. Security Pages

The Security section provides specialized views for different fraud detection and prevention capabilities.

### 8.1 RVS Dashboard

**Route:** `/security/rvs-dashboard`

The Real-time Verification System (RVS) Dashboard monitors the health and performance of the route verification infrastructure. It displays:
- RVS health status badge (Healthy, Degraded, Down).
- Verification success/failure rates.
- Latency metrics for route verification queries.
- Recent verification events.

<!-- Screenshot: RVS Dashboard page showing a large health status badge ("Healthy" in green) at the top, followed by verification rate charts and a table of recent verification events with their outcomes. -->

### 8.2 Composite Scoring

**Route:** `/security/composite-scoring`

The Composite Scoring page displays the multi-factor fraud risk scores for phone numbers and call patterns. It combines:
- Rule-based detection scores.
- ML model probability scores.
- Historical behavior analysis.
- Network intelligence signals.

Each composite score is visualized as a gauge (0-100) with color zones: green (0-49 low risk), yellow (50-69 medium risk), orange (70-89 high risk), red (90-100 critical risk).

<!-- Screenshot: Composite Scoring page showing a gauge visualization for a selected phone number, with the composite score needle pointing to 78 (High Risk zone). Below the gauge, a breakdown table shows the individual scoring components and their contributions. -->

### 8.3 Lists Management

**Route:** `/security/lists-manage`

Manage whitelist and blacklist entries:
- **Whitelist**: Trusted numbers exempt from detection (call centers, conference bridges, IVR systems).
- **Blacklist**: Known fraudulent numbers or patterns that are automatically blocked.

Actions:
- Add, edit, or remove entries.
- Set expiration dates for temporary entries.
- Import/export lists in CSV format.
- View list history and audit trail.

### 8.4 Multi-Call Detection

**Route:** `/security/multicall-detection`

Displays real-time multi-call pattern analysis:
- Identifies when multiple different A-numbers are calling the same B-number within a detection window.
- Shows the A-number count, detection window, B-number, and alert status.
- Provides visual timeline of the detection event.

### 8.5 Revenue Fraud

**Route:** `/security/revenue-fraud`

Monitors two primary revenue fraud types:

**Wangiri (Callback Fraud):**
- Displays detected Wangiri incidents.
- Shows the premium-rate numbers being used.
- Provides a "Block" action to prevent further callbacks.

**IRSF (International Revenue Share Fraud):**
- Shows suspicious international traffic patterns.
- Identifies revenue-sharing destination numbers.
- Estimates financial impact of ongoing IRSF activity.

<!-- Screenshot: Revenue Fraud page showing two tabs: "Wangiri" and "IRSF". The Wangiri tab displays a table of incidents with columns for ID, Source Range, Premium Number, Call Count, Estimated Loss, and a "Block" action button. -->

### 8.6 Traffic Control

**Route:** `/security/traffic-control`

Manage traffic control rules:
- Create rules to block, throttle, or monitor specific traffic patterns.
- Toggle rules on/off.
- View rule match counts and effectiveness.
- AIDD Tier 1 badges are displayed for toggle operations.

### 8.7 False Positives

**Route:** `/security/false-positives`

Review and manage false positive reports:
- View all alerts marked as false positives.
- Analyze false positive patterns to identify detection rule improvements.
- Confirm or reclassify false positive determinations.

---

## 9. NCC Compliance

### 9.1 NCC Compliance Page

**Route:** `/ncc/compliance`

The NCC Compliance page provides tools for generating and managing regulatory reports for the Nigerian Communications Commission.

<!-- Screenshot: NCC Compliance page showing sections for "Pending Reports", "Submitted Reports", and "Disputes". Each report row shows the report type, period, status, submission date, and action buttons. -->

**Report Types:**
- **Daily Incident Report**: Auto-generated daily summary of fraud incidents.
- **Monthly Compliance Report**: Comprehensive monthly report with statistics, trends, and actions taken.
- **Incident Reports**: Individual incident reports filed within SLA timeframes.

**Disputes:**
- Create settlement disputes for interconnect billing discrepancies.
- Track dispute status through the NCC adjudication process.
- Escalation to NCC is a Tier 2 operation.

### 9.2 MNP Lookup

**Route:** `/ncc/mnp-lookup`

The Mobile Number Portability (MNP) Lookup tool allows you to:
- Look up the current network operator for any Nigerian mobile number.
- Verify porting status and history.
- Bulk lookup for investigation purposes.

---

## 10. Audit Log

### 10.1 Viewing the Audit Log

Navigate to **Audit Log** from the sidebar.

<!-- Screenshot: Audit Log page showing filter controls (search text, user dropdown, action type dropdown, date range picker) and a table with columns for Audit ID, Timestamp, User, Action (color-coded tag), Resource, Details, and IP Address. -->

The audit log records every action performed within the platform, both by users and by the system itself.

**Logged Action Types:**

| Action | Color | Description |
|--------|-------|-------------|
| **CREATE** | Green | New record created |
| **UPDATE** | Blue | Existing record modified |
| **DELETE** | Red | Record removed |
| **EXECUTE** | Purple | System operation executed (e.g., ML retraining) |
| **EXPORT** | Cyan | Data exported |
| **BLOCK** | Orange | Traffic pattern blocked |
| **LOGIN** | Gray | User authentication event |
| **BACKUP** | Blue | Database backup completed |
| **ROTATE** | Gray | Token or credential rotation |

### 10.2 Searching and Filtering

- **Search Text**: Full-text search across resource names and details.
- **User Filter**: Filter by specific user or "system" for automated actions.
- **Action Type Filter**: Filter by action type (CREATE, UPDATE, DELETE, etc.).
- **Date Range**: Filter by date range.

### 10.3 Exporting Audit Logs

1. Apply your desired filters.
2. Click the **Export** button (download icon).
3. Select the format: CSV or Excel.
4. The export downloads to your browser.

Audit logs are retained for 7 years in compliance with regulatory requirements. Archived logs older than 90 days are stored in cold storage but remain searchable.

---

## 11. ML Dashboard

The ML Dashboard provides visibility into the machine learning models powering VoxGuard's fraud detection.

### 11.1 Model Overview

Navigate to **ML Dashboard** from the sidebar.

<!-- Screenshot: ML Dashboard page showing a grid of model cards. Each card displays the model name, version, status badge (Active in green, Shadow in yellow, Retired in gray), key metrics (Accuracy, AUC, F1), operational stats (Predictions Today, Avg Latency), and action buttons (Retrain, View Details). An AIDD Tier badge is visible on the Retrain button. -->

Each model card displays:

| Field | Description |
|-------|-------------|
| **Model Name** | Descriptive name (e.g., "Fraud Detector", "CLI Spoofing Classifier") |
| **Version** | Current deployed version |
| **Status** | Active (in production), Shadow (testing), or Retired (decommissioned) |
| **Accuracy** | Overall prediction accuracy |
| **AUC** | Area Under the ROC Curve (discrimination ability) |
| **F1 Score** | Harmonic mean of precision and recall |
| **Features Count** | Number of input features used by the model |
| **Predictions Today** | Number of predictions made today |
| **Avg Latency** | Average prediction latency in milliseconds |
| **Last Trained** | Date and time of the most recent training run |
| **A/B Test Status** | Current A/B test status (if applicable) |

### 11.2 Understanding Model Status

| Status | Badge Color | Description |
|--------|-------------|-------------|
| **Active** | Green | The model is in production and its predictions drive alerts and automated actions. |
| **Shadow** | Yellow | The model receives live traffic and makes predictions, but predictions are logged only -- not acted upon. Used for validation before promotion. |
| **Retired** | Gray | The model is no longer in use. Retained for audit and comparison purposes. |

### 11.3 Model Metrics Explained

- **Accuracy**: The percentage of predictions that were correct. Target: above 92%.
- **AUC (Area Under Curve)**: Measures the model's ability to distinguish between fraud and legitimate traffic. 1.0 is perfect; 0.5 is random. Target: above 0.95.
- **F1 Score**: Balances precision (avoiding false positives) and recall (catching all fraud). Target: above 0.90.
- **Avg Latency**: The time it takes for the model to return a prediction. Target: below 50ms.

### 11.4 Triggering Retraining

(Admin role required)
1. Click the **Retrain** button on a model card.
2. Confirm the retraining request (Tier 1 operation).
3. The model enters a "Retraining" state with a progress indicator.
4. Upon completion, the new version is deployed in Shadow mode.
5. After validation, an Admin can promote the shadow model to Active.

---

## 12. Report Builder

The Report Builder provides tools for generating, scheduling, and downloading reports.

### 12.1 Generating a Report

Navigate to **Reports** from the sidebar.

<!-- Screenshot: Report Builder page showing two sections: "Generate New Report" form on the left (with Report Type dropdown, Date Range picker, Format radio buttons, and Generate/Schedule buttons) and "Report History" table on the right (with columns for Report ID, Type, Date Range, Format, Status, Generated At, Size, Schedule, and Download button). -->

**Steps:**
1. Select the **Report Type**:
   - Daily Fraud Summary
   - Weekly Trend Report
   - Monthly NCC Submission
   - Custom Report
2. Select the **Date Range** using the date picker.
3. Choose the **Format**: PDF, Excel, or CSV.
4. Click **Generate Report**.
5. The report appears in the history table with status "Pending" while it generates.
6. Once complete, the status changes to "Generated" and a **Download** button appears.

### 12.2 Scheduling Reports

1. Configure the report type, date range, and format as above.
2. Instead of clicking "Generate", click the **Schedule** button.
3. Set the recurrence: Daily, Weekly, or Monthly.
4. Optionally add email recipients for automatic delivery.
5. Click **Save Schedule**.

Scheduled reports are generated automatically and appear in the history table with a schedule indicator.

### 12.3 Report History

The history table shows all generated and scheduled reports:

| Column | Description |
|--------|-------------|
| **Report ID** | Unique identifier (e.g., RPT-001) |
| **Report Type** | Type of report |
| **Date Range** | Period covered by the report |
| **Format** | PDF, Excel, or CSV |
| **Status** | Generated (downloadable), Pending (in progress), Failed (error) |
| **Generated At** | Timestamp of generation |
| **Size** | File size |
| **Schedule** | Recurrence indicator (Daily, Weekly, Monthly) if scheduled |

### 12.4 Downloading Reports

Click the **Download** button on any report with "Generated" status. The file downloads to your browser's default download location.

---

## 13. Settings

Access settings via the **Settings** link in the sidebar. The settings page is organized into 5 tabs.

### 13.1 Detection Tab

Configure fraud detection thresholds and automatic actions.

<!-- Screenshot: Settings page showing the Detection tab active. The form displays "Calls Per Minute (CPM) Thresholds" with Warning Level and Critical Level number inputs, "Average Call Duration (ACD) Thresholds" with Warning and Critical level inputs, "Threat Score" with an Alert Threshold input, and "Automatic Actions" with an Auto-Block toggle and threshold. Save and Reset buttons are at the bottom. -->

**Configurable Parameters:**

| Parameter | Default | Description |
|-----------|---------|-------------|
| CPM Warning Level | 40 calls/min | Triggers a warning-level alert |
| CPM Critical Level | 60 calls/min | Triggers a critical-level alert |
| ACD Warning Level | 10 seconds | Warns when average call duration drops below this |
| ACD Critical Level | 5 seconds | Critical alert when ACD drops below this |
| Threat Score Threshold | 70% | Alerts above this score are marked high priority |
| Auto-Block Enabled | Off | Automatically block numbers exceeding the threshold |
| Auto-Block Threshold | 90% | Numbers above this threat score are auto-blocked |

**Note:** Modifying detection settings requires Supervisor or Admin role. A caution warning is displayed when enabling auto-block, as it may affect legitimate traffic.

### 13.2 Notifications Tab

Configure how you receive alerts about fraud detections.

**Email Notifications:**
- Toggle email alerts on/off.
- Set recipient email addresses (comma-separated).

**Slack Integration:**
- Toggle Slack alerts on/off.
- Enter the Slack webhook URL.

**Browser Notifications:**
- Toggle sound for critical alerts.
- Set the notification cooldown period (minimum time between repeated notifications for the same alert, default: 5 minutes).

### 13.3 API & Integration Tab

Configure API rate limits and external integrations.

**API Configuration:**
- Rate limit (requests per minute, default: 1000).
- Timeout (seconds, default: 30).
- Retry attempts (default: 3).

**NCC Compliance Reporting:**
- Toggle automatic NCC reporting on/off.
- Enter the NCC API key.

### 13.4 Language & Region Tab

Configure interface language and regional formatting preferences.

<!-- Screenshot: Settings page showing the Language & Region tab active. The form displays a language selector dropdown with 10 language options, a currency selector, a timezone selector, and date/number format preview showing how values will be displayed. -->

**Settings:**
- **Language**: Select from 10 supported languages.
- **Currency**: Select the display currency for all monetary values.
- **Date Format**: Preview of date formatting in the selected locale.
- **Number Format**: Preview of number formatting (decimal separators, grouping).

### 13.5 External Portals Tab

Quick access to all VoxGuard monitoring, analytics, and administration portals.

**Available Services** (grouped by category):
- **Monitoring**: Grafana, Prometheus, Homer SIP
- **Databases**: QuestDB, ClickHouse, YugabyteDB
- **Infrastructure**: Additional operational portals

Each service card shows:
- Service name and description.
- URL (clickable to open in a new tab).
- Health status indicator (after running a health check).
- Default credentials (for development environments).

Click **Check Health** to verify connectivity to all external services.

---

## 14. AIDD Tier System

VoxGuard uses the AIDD (Autonomous Intelligence-Driven Development) tier system to govern operation approvals. As an end user, you will encounter AIDD badges on certain action buttons.

### 14.1 What You See in the UI

| Badge | Color | Meaning | What Happens |
|-------|-------|---------|--------------|
| No badge | -- | Tier 0: Read-only, no confirmation needed | Action executes immediately |
| **Confirm** | Yellow | Tier 1: Confirmation required | A confirmation dialog appears before the action is executed |
| **Admin Approval** (with lock icon) | Red | Tier 2: Admin approval required | An approval dialog appears requiring SYSTEM_ADMIN role and a written reason |

### 14.2 Common Operations by Tier

**Tier 0 (No badge):**
- Viewing dashboards, alerts, cases, CDRs, analytics
- Acknowledging alerts
- Viewing ML model status
- Exporting reports (read-only)

**Tier 1 (Yellow "Confirm" badge):**
- Blocking a phone number
- Creating/updating/deleting a fraud detection rule
- Toggling a traffic control rule
- Confirming a false positive or true positive
- Disconnecting a single fraudulent call
- Generating an NCC compliance report
- Creating a settlement dispute

**Tier 2 (Red "Admin Approval" badge):**
- Submitting a compliance report to NCC
- Escalating a settlement dispute to NCC
- Importing MNP data (bulk database update)
- Bulk delete operations
- Modifying authentication/authorization settings

---

## 15. Keyboard Shortcuts

### 15.1 Global Shortcuts

| Shortcut | Action |
|----------|--------|
| `G` then `D` | Go to Dashboard |
| `G` then `A` | Go to Alerts |
| `G` then `R` | Go to Reports |
| `G` then `S` | Go to Settings |
| `/` | Focus the search bar |
| `?` | Show keyboard shortcuts help |
| `Esc` | Close the current modal or dialog |

### 15.2 Alert View Shortcuts

| Shortcut | Action |
|----------|--------|
| `J` | Next alert |
| `K` | Previous alert |
| `A` | Acknowledge the selected alert |
| `I` | Start investigation |
| `D` | Disconnect calls |
| `E` | Escalate |
| `N` | Add a note |
| `R` | Generate report |

### 15.3 Dashboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `1`-`9` | Switch time range |
| `F` | Toggle fullscreen |
| `Space` | Pause/resume real-time updates |
| `M` | Toggle map view |

---

## 16. Troubleshooting

### 16.1 Page Not Loading

- Check your internet connection.
- Hard-refresh: `Ctrl+Shift+R` (Windows/Linux) or `Cmd+Shift+R` (Mac).
- Clear browser cache and cookies for the VoxGuard domain.
- Try a different supported browser.
- Verify JavaScript and cookies are enabled.
- Check if your VPN or firewall blocks WebSocket connections.

### 16.2 Alerts Not Updating

- Check the WebSocket connection indicator in the header (green = connected, gray = disconnected).
- Refresh the page to re-establish the WebSocket connection.
- Verify your network allows WebSocket connections.
- Check your browser console for error messages (`F12` > Console).

### 16.3 Export Failing

- Ensure your browser allows downloads from the VoxGuard domain.
- For large exports, wait for the asynchronous notification.
- Reduce the date range or apply more specific filters.
- Try CSV format for large datasets.
- Clear browser cache and retry.

### 16.4 Login Issues

- Verify username and password (case-sensitive).
- Check Caps Lock.
- Wait 15 minutes if locked out after failed attempts, or contact your administrator.
- Clear cookies and try incognito/private mode.
- Sessions expire after 24 hours of inactivity.

### 16.5 Language Not Changing

- Allow 1-2 seconds for the UI to re-render.
- Hard-refresh after changing language.
- Check that localStorage is enabled in your browser.
- Clear the `voxguard-language` key from localStorage via browser DevTools.

### 16.6 Currency Format Incorrect

- Verify the correct currency in **Settings > Language & Region**.
- Click Save to force re-application, then hard-refresh.
- Currency formatting follows the selected language's locale conventions.

### 16.7 Getting Help

- **In-App**: Click the Help icon (?) in the header for documentation and tutorials.
- **Email**: Contact support@yourcompany.com.
- **Phone**: +234-XXX-XXX-XXXX.
- **Internal Ticket System**: Submit a support ticket through your organization's helpdesk.

---

## 17. Glossary

| Term | Definition |
|------|------------|
| **A-Number** | The calling party's phone number (source) |
| **ACD** | Average Call Duration |
| **AIDD** | Autonomous Intelligence-Driven Development (tiered approval framework) |
| **AUC** | Area Under the ROC Curve (ML model performance metric) |
| **B-Number** | The called party's phone number (destination) |
| **CDR** | Call Detail Record |
| **CLI** | Calling Line Identification |
| **CPM** | Calls Per Minute |
| **CPS** | Calls Per Second |
| **Detection Window** | Time period during which distinct A-numbers are counted for a given B-number |
| **F1 Score** | Harmonic mean of precision and recall (ML metric) |
| **False Positive** | An alert generated for legitimate (non-fraudulent) traffic |
| **IRSF** | International Revenue Share Fraud |
| **KPI** | Key Performance Indicator |
| **MNP** | Mobile Number Portability |
| **MTTI** | Mean Time to Investigate |
| **MTTR** | Mean Time to Resolve |
| **NCC** | Nigerian Communications Commission |
| **RVS** | Real-time Verification System |
| **Shadow Mode** | ML model deployment where predictions are logged but not acted upon |
| **SIM Box** | Equipment used to illegally terminate international calls as local calls |
| **Threshold** | Configurable limit that triggers an alert when exceeded |
| **Wangiri** | "One ring and cut" -- callback fraud using premium-rate numbers |
| **Whitelist** | Approved numbers or patterns exempt from fraud detection |

---

**Document Version:** 2.1
**Classification:** Internal Use Only
**Last Updated:** February 2026
