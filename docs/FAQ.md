# VoxGuard FAQ & Troubleshooting Guide

**Version:** 2.1
**Last Updated:** February 2026
**Platform:** VoxGuard Anti-Call Masking & Voice Network Fraud Detection
**Audience:** All Users (Operators, Analysts, Supervisors, Administrators)

---

## Table of Contents

1. [General](#1-general)
2. [Dashboard](#2-dashboard)
3. [Alerts](#3-alerts)
4. [Case Management](#4-case-management)
5. [CDR Browser](#5-cdr-browser)
6. [Reports](#6-reports)
7. [Settings](#7-settings)
8. [ML Models](#8-ml-models)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. General

### Q: What is VoxGuard?

**A:** VoxGuard is an enterprise Anti-Call Masking and Voice Network Fraud Detection Platform. It monitors telecommunications traffic in real time to detect CLI spoofing, Wangiri callback fraud, International Revenue Share Fraud (IRSF), SIM box bypass, and other voice network fraud schemes. VoxGuard combines rule-based detection engines with machine learning models to protect telco operators and ensure compliance with NCC (Nigerian Communications Commission) regulations.

---

### Q: What fraud types does VoxGuard detect?

**A:** VoxGuard detects the following fraud categories:

| Fraud Type | Description |
|---|---|
| **CLI Spoofing / Call Masking** | Multiple fake caller IDs targeting the same destination within a short window |
| **Wangiri (Callback Fraud)** | Short-duration "missed call" attacks designed to trick subscribers into calling premium-rate numbers |
| **IRSF** | International Revenue Share Fraud through artificially inflated traffic to revenue-sharing destinations |
| **SIM Box / Bypass Fraud** | International calls illegally terminated as local calls via SIM banks |
| **Revenue Leakage** | Interconnect billing discrepancies and under-reported traffic |
| **Multi-Call Pattern Abuse** | Anomalous call patterns suggesting coordinated fraudulent activity |

---

### Q: What is AIDD?

**A:** AIDD stands for **Autonomous Intelligence-Driven Development**. It is VoxGuard's tiered approval framework that governs how automated and manual operations are authorized:

| Tier | Name | Behavior |
|---|---|---|
| **Tier 0** | Auto-Approve (Read-Only) | No confirmation needed. Used for viewing dashboards, alerts, analytics, ML model status, and exporting reports. |
| **Tier 1** | Require Confirmation | Requires explicit user confirmation. Used for blocking numbers, creating/updating fraud rules, toggling traffic controls, confirming false/true positives, generating NCC reports, and creating settlement disputes. |
| **Tier 2** | Require Admin Approval | Requires a SYSTEM_ADMIN role and a written reason. Used for submitting compliance reports to NCC, escalating disputes to NCC, importing MNP data, running bulk deletes, and modifying auth settings. |

In the UI, Tier 1 operations display a yellow "Confirm" badge, and Tier 2 operations display a red "Admin Approval" badge with a lock icon.

---

### Q: What are the supported languages?

**A:** VoxGuard supports 10 languages. You can switch languages at any time from the header language selector or via **Settings > Language & Region**.

| Code | Language | Direction |
|---|---|---|
| `en` | English | LTR |
| `fr` | Francais | LTR |
| `pt` | Portugues | LTR |
| `ha` | Hausa | LTR |
| `yo` | Yoruba | LTR |
| `ig` | Igbo | LTR |
| `ar` | Arabic | RTL |
| `es` | Espanol | LTR |
| `zh` | Chinese | LTR |
| `sw` | Kiswahili | LTR |

---

## 2. Dashboard

### Q: How do I read the dashboard?

**A:** The main dashboard presents four real-time statistic cards at the top:

1. **New Alerts** (blue) -- Unreviewed fraud alerts requiring attention.
2. **Critical Alerts** (red, pulsing) -- High-severity threats needing immediate response.
3. **Investigating** (yellow) -- Alerts currently under active investigation.
4. **Confirmed** (red) -- Verified fraud incidents.

Below the cards you will find:
- **Alert Trends (24h)** -- A multi-line time-series chart showing alert volume by severity over the last 24 hours.
- **Severity Distribution** -- A pie chart breaking down alerts by Critical, High, Medium, and Low.
- **Traffic Area Chart** -- An area chart visualizing call volume and anomalous traffic patterns.

All metrics update automatically via WebSocket subscriptions. If the connection indicator in the header turns gray, the real-time feed has disconnected (see Troubleshooting).

---

### Q: What do severity levels mean?

**A:** VoxGuard uses four severity levels:

| Severity | Color | Meaning | Expected Response Time |
|---|---|---|---|
| **Critical** | Red | Active, high-confidence fraud with immediate revenue impact (7+ A-numbers or threat score above 90) | Immediate |
| **High** | Orange | Strong fraud indicators requiring prompt investigation (5-6 A-numbers or threat score 70-89) | Within 15 minutes |
| **Medium** | Yellow | Suspicious patterns that merit review (3-4 A-numbers or threat score 50-69) | Within 30 minutes |
| **Low** | Green | Minor anomalies, often informational (2 A-numbers or threat score below 50) | Within 1 hour |

---

### Q: How do I customize the dashboard view?

**A:**
1. Click the **Customize** button on the dashboard page.
2. Drag and drop widgets to rearrange the layout.
3. Resize widgets by dragging their edges.
4. Add or remove widgets (Alert feed, Traffic chart, Top targets, System health, Geographic map, Quick stats).
5. Click **Save Layout** to persist your configuration.

Your layout is saved per-user and will persist across sessions. You can also toggle between light and dark mode using the theme switch in the header.

---

## 3. Alerts

### Q: How do I investigate an alert?

**A:**
1. Navigate to **Alerts** from the sidebar menu.
2. Click on any alert row to open the alert detail view.
3. Review the alert information: alert ID, timestamp, targeted B-number, all involved A-numbers, detection window duration, source gateway, and threat score.
4. Use the investigation tools: view the call timeline, check B-number history, see related alerts, and view geographic visualization.
5. Click **Investigate** to take formal ownership of the alert (requires Analyst role or above).
6. Add investigation notes as you work.
7. When finished, mark the alert as **Resolved** or **False Positive**.

---

### Q: How do I mark false positives?

**A:**
1. Open the alert detail view by clicking on the alert.
2. Click the **False Positive** action button.
3. Provide a reason for the false positive classification (e.g., "Known call center", "Conference bridge", "IVR system").
4. Submit. The alert status changes to "False Positive" and the system uses this feedback to improve future detection accuracy.

Requires **Analyst** role or higher. False positive data is also fed back to the ML models during retraining to reduce future false positives.

---

### Q: How do I bulk-resolve alerts?

**A:**
1. Navigate to the **Alerts** list view.
2. Select multiple alerts by checking the checkboxes next to each alert row.
3. Click the **Bulk Actions** dropdown button at the top of the list.
4. Choose the desired action: **Acknowledge All**, **Resolve All**, **Export Selected**, or **Assign To**.
5. Confirm the action when prompted.

Note: Bulk-resolving critical alerts may require Supervisor approval depending on your organization's AIDD tier configuration.

---

## 4. Case Management

### Q: How do I create a case?

**A:**
1. Navigate to **Cases** from the sidebar menu.
2. Click the **+ New Case** button.
3. Fill in the case details:
   - **Title**: A descriptive name (e.g., "CLI Spoofing Ring -- MTN Routes").
   - **Description**: Detailed description of the suspected fraud.
   - **Severity**: Critical, High, Medium, or Low.
   - **Fraud Type**: Select from CLI Spoofing, Wangiri, IRSF, SIM Box, Revenue Fraud, or Other.
   - **Assignee**: The analyst responsible for the investigation.
4. Click **Create**. The case is created with status "Open".

---

### Q: How do I link alerts to cases?

**A:** There are two methods:

**From the Alert Detail View:**
1. Open an alert.
2. Click **Link to Case**.
3. Select an existing case from the dropdown or create a new one.

**From the Case Detail View:**
1. Open a case.
2. In the "Linked Alerts" section, click **Add Alert**.
3. Search for and select the alerts to link.

Linked alerts automatically contribute their data (A-numbers, B-numbers, timestamps, estimated losses) to the case summary.

---

### Q: How do I escalate a case?

**A:**
1. Open the case detail view.
2. Click the **Escalate** button.
3. Select the escalation target (e.g., a supervisor, the NCC compliance team, or cross-operator investigation).
4. Provide an escalation reason.
5. Confirm. The case status changes to "Escalated" and the assigned escalation target is notified.

Escalation to NCC is a **Tier 2 (Admin Approval)** operation and requires SYSTEM_ADMIN authorization with a written reason.

---

### Q: What are the case statuses?

**A:**

| Status | Description |
|---|---|
| **Open** | Newly created, awaiting assignment or initial review |
| **Investigating** | Actively under investigation by an assigned analyst |
| **Escalated** | Escalated to a supervisor, NCC, or cross-operator team |
| **Resolved** | Investigation complete, fraud confirmed and mitigated |
| **Closed** | Case closed with no further action required |
| **False Positive** | Case determined to be non-fraudulent |

---

## 5. CDR Browser

### Q: How do I search CDRs?

**A:**
1. Navigate to **CDR Browser** from the sidebar menu.
2. Use the search filters at the top of the page:
   - **A-Number**: Filter by the calling party number (supports partial match).
   - **B-Number**: Filter by the called party number (supports partial match).
   - **Date Range**: Select start and end dates using the date picker.
   - **Country**: Filter by originating country.
   - **Gateway**: Filter by the gateway that handled the call.
   - **Call Type**: Filter by voice, SMS, or data.
   - **Direction**: Filter by inbound, outbound, or local.
3. Click **Search** to apply filters. Results display in a sortable, paginated table.

---

### Q: How do I export CDR data?

**A:**
1. Apply your desired filters in the CDR Browser.
2. Click the **Export** button (download icon) at the top right of the results table.
3. Select the export format: **CSV**, **Excel**, or **PDF**.
4. The file downloads to your browser's default download location.

Note: Large exports (100,000+ records) are processed asynchronously. You will receive a notification when the file is ready for download. If exports fail, see the Troubleshooting section.

---

### Q: How do I link CDRs to cases?

**A:**
1. In the CDR Browser, select one or more CDR records using the checkboxes.
2. Click **Link to Case** from the actions toolbar.
3. Select an existing case or create a new one.
4. The selected CDRs are attached as evidence to the case and appear in the case detail under "Linked CDRs".

---

## 6. Reports

### Q: How do I generate an NCC report?

**A:**
1. Navigate to **Reports** from the sidebar menu.
2. In the "Generate New Report" form, select **Monthly NCC Submission** as the report type.
3. Select the reporting period (month).
4. Choose the output format (PDF is required for NCC submissions).
5. Click **Generate Report**.
6. Once generated, review the report for accuracy.
7. To submit to NCC, click **Submit to NCC** on the generated report -- this is a **Tier 2 (Admin Approval)** operation.

NCC daily reports are automatically generated at 06:00 WAT if auto-reporting is enabled in **Settings > API & Integration**.

---

### Q: How do I schedule recurring reports?

**A:**
1. Navigate to **Reports**.
2. After configuring a report in the "Generate New Report" form, click the **Schedule** button (clock icon) instead of "Generate".
3. Set the recurrence frequency: **Daily**, **Weekly**, or **Monthly**.
4. Optionally add email recipients for automatic delivery.
5. Click **Save Schedule**. Scheduled reports appear in the report history table with a "Schedule" badge.

To manage existing schedules, look for reports with the schedule indicator in the history table and click to edit or delete the schedule.

---

### Q: What report formats are available?

**A:**

| Format | Best For |
|---|---|
| **PDF** | NCC submissions, executive summaries, printing |
| **Excel (.xlsx)** | Detailed data analysis, pivot tables, custom calculations |
| **CSV** | Data integration, importing into other tools, large datasets |

All report types (Daily Fraud Summary, Weekly Trend Report, Monthly NCC Submission, Custom Report) support all three formats.

---

## 7. Settings

### Q: How do I change the language?

**A:** There are two methods:

**Quick Switch (Header):**
1. Click the globe/language icon in the top-right area of the header.
2. Select your preferred language from the dropdown.
3. The interface updates immediately.

**Settings Page:**
1. Navigate to **Settings** from the sidebar menu.
2. Click the **Language & Region** tab.
3. Select your preferred language.
4. Click **Save**.

Your language preference is saved to local storage and persists across sessions. The language key is stored as `voxguard-language` in your browser.

---

### Q: How do I change the currency?

**A:**
1. Navigate to **Settings > Language & Region**.
2. In the Currency section, select your preferred currency (NGN, USD, EUR, GBP, etc.).
3. Click **Save**. All monetary values across the platform (estimated losses, revenue protected, KPI figures) will display in the selected currency with appropriate formatting.

You can also use the currency switcher in the header for quick changes.

---

### Q: How do I configure detection thresholds?

**A:** (Requires Supervisor or Admin role)
1. Navigate to **Settings**.
2. Click the **Detection** tab.
3. Adjust the following thresholds:
   - **CPM Warning Level**: Calls per minute that trigger a warning (default: 40).
   - **CPM Critical Level**: Calls per minute that trigger a critical alert (default: 60).
   - **ACD Warning Level**: Average call duration below which a warning is triggered (default: 10 seconds).
   - **ACD Critical Level**: Average call duration below which a critical alert is triggered (default: 5 seconds).
   - **Threat Score Threshold**: Score above which alerts are marked high priority (default: 70%).
   - **Auto-Block**: Enable/disable automatic blocking and set the auto-block threshold (default: 90%).
4. Click **Save Detection Settings**.

---

### Q: How do I set up email and Slack notifications?

**A:**
1. Navigate to **Settings**.
2. Click the **Notifications** tab.
3. **For Email:**
   - Toggle **Enable Email Alerts** on.
   - Enter recipient email addresses (comma-separated).
4. **For Slack:**
   - Toggle **Enable Slack Alerts** on.
   - Paste your Slack webhook URL (format: `https://hooks.slack.com/services/...`).
5. Configure **Notification Cooldown** to set the minimum time between repeated notifications for the same alert (default: 5 minutes).
6. Toggle **Sound for Critical Alerts** on/off for browser audio notifications.
7. Click **Save Notification Settings**.

---

## 8. ML Models

### Q: How do I view model performance?

**A:**
1. Navigate to **ML Dashboard** from the sidebar menu.
2. Each deployed model displays a card showing:
   - **Model Name and Version** (e.g., "Fraud Detector v3.2.1")
   - **Status**: Active, Shadow, or Retired
   - **Key Metrics**: Accuracy, AUC (Area Under Curve), F1 Score
   - **Operational Stats**: Predictions today, average latency (ms)
   - **Feature Count**: Number of input features used
   - **Last Trained**: Date and time of the most recent training run
3. Click on any model card for a detailed view with historical performance charts.

---

### Q: How do I trigger retraining?

**A:** (Requires Admin role)
1. Navigate to **ML Dashboard**.
2. Find the model you want to retrain.
3. Click the **Retrain** button on the model card.
4. Confirm the retraining request. This is a **Tier 1 (Confirm)** operation.
5. The model enters a "Retraining" state. Training progress is displayed on the model card.
6. Once retraining completes, the new version is deployed in **Shadow Mode** for validation before being promoted to active.

Retraining is also triggered automatically on a schedule (typically weekly) or when model drift is detected.

---

### Q: What is shadow mode?

**A:** Shadow mode is a deployment strategy where a newly trained ML model receives live production traffic and makes predictions, but its predictions are **not used for automated actions** (such as blocking or alerting). Instead, shadow predictions are logged and compared against the active model's predictions.

This allows the operations team to:
- Validate the new model's accuracy on real traffic before promotion.
- Compare false positive and false negative rates between the active and shadow models.
- Roll back safely if the shadow model underperforms.

Once the shadow model is validated, an Admin can promote it to **Active** status, replacing the previous version. The previous model moves to **Retired** status.

---

## 9. Troubleshooting

### Page not loading

**Symptoms:** Blank white screen, spinner that never finishes, or "Application Error" message.

**Solutions:**
1. Check your internet connection.
2. Hard-refresh the page: `Ctrl+Shift+R` (Windows/Linux) or `Cmd+Shift+R` (Mac).
3. Clear your browser cache and cookies for the VoxGuard domain.
4. Try a different browser (Chrome 90+, Firefox 88+, Safari 14+, Edge 90+).
5. Ensure JavaScript and cookies are enabled.
6. Check if your organization's VPN or firewall is blocking WebSocket connections.
7. If the problem persists, contact your system administrator.

---

### Alerts not updating

**Symptoms:** Alert counts remain static, real-time feed is stale, the connection indicator in the header is gray.

**Solutions:**
1. Check the WebSocket connection indicator in the header. Green = connected; Gray = disconnected.
2. Refresh the page to re-establish the WebSocket connection.
3. Verify that your network allows WebSocket connections (port 443 or the configured WebSocket port).
4. Check your browser console (`F12` > Console tab) for connection error messages.
5. If behind a corporate proxy, ensure WebSocket passthrough is enabled.
6. Contact your administrator if the backend services may be down.

---

### Export failing

**Symptoms:** Export button does not respond, download never starts, or the downloaded file is empty/corrupted.

**Solutions:**
1. Ensure your browser allows downloads from the VoxGuard domain (check popup blocker settings).
2. For large exports (100,000+ records), wait for the async notification -- large files take time to generate.
3. Try reducing the date range or applying more specific filters to reduce the export size.
4. Try a different export format (CSV tends to be fastest for large datasets).
5. Clear your browser cache and try again.
6. Check that you have sufficient disk space on your local machine.
7. If the issue persists, ask your administrator to check the export service logs.

---

### Login issues

**Symptoms:** "Invalid credentials" error, page redirects to login repeatedly, session expires unexpectedly.

**Solutions:**
1. Verify your username and password. Passwords are case-sensitive.
2. Check that Caps Lock is not enabled.
3. If your account is locked after multiple failed attempts, wait 15 minutes or contact your administrator.
4. Clear browser cookies for the VoxGuard domain and try again.
5. Try an incognito/private browsing window to rule out extension conflicts.
6. Ensure your account has not been deactivated by an administrator.
7. If using two-factor authentication, verify that your authenticator app's time is synchronized.
8. Sessions expire after 24 hours of inactivity. Re-login is expected behavior.

---

### Language not changing

**Symptoms:** Selecting a new language has no visible effect, or the interface partially changes language.

**Solutions:**
1. After selecting a language, allow 1-2 seconds for the interface to re-render.
2. Hard-refresh the page (`Ctrl+Shift+R` / `Cmd+Shift+R`) after changing the language.
3. Check that your browser allows local storage. VoxGuard stores the language preference under the key `voxguard-language` in localStorage.
4. Clear localStorage for the VoxGuard domain: open browser DevTools (`F12`), go to Application > Local Storage, and delete the `voxguard-language` key, then re-select your language.
5. If using an incognito/private window, language preferences will not persist across sessions.
6. Ensure your browser is not overriding the page language via a translation extension (e.g., Google Translate).

---

### Currency format incorrect

**Symptoms:** Monetary values show the wrong currency symbol, wrong decimal separators, or incorrect formatting.

**Solutions:**
1. Navigate to **Settings > Language & Region** and verify the correct currency is selected.
2. Click **Save** even if the currency appears correct -- this forces a re-application of the formatting.
3. Hard-refresh the page after saving.
4. Currency formatting follows the locale conventions of your selected language. If you want NGN formatting with English labels, ensure both Language and Currency are set correctly.
5. If you see raw numbers without formatting (e.g., "8500000" instead of "8,500,000 NGN"), this may indicate a rendering error. Clear cache and refresh.
6. Contact your administrator if custom currency configurations have been set at the system level.

---

**Document Version:** 2.1
**Classification:** Internal Use Only
**Last Updated:** February 2026
