# User Manual
## Anti-Call Masking Detection System - Dashboard Guide

**Version:** 1.0
**Last Updated:** January 2026
**Audience:** Dashboard Users, Operators, Supervisors

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Getting Started](#2-getting-started)
3. [Dashboard Overview](#3-dashboard-overview)
4. [Alert Management](#4-alert-management)
5. [Analytics & Reports](#5-analytics--reports)
6. [Configuration](#6-configuration)
7. [Mobile App](#7-mobile-app)
8. [Keyboard Shortcuts](#8-keyboard-shortcuts)
9. [Troubleshooting](#9-troubleshooting)
10. [FAQ](#10-faq)

---

## 1. Introduction

### 1.1 About the System

The Anti-Call Masking Detection System protects your telecommunications network from CLI spoofing attacks. When multiple different caller IDs (A-numbers) attempt to reach the same destination (B-number) within a short time window, the system automatically detects and alerts you.

### 1.2 What is Call Masking?

Call masking (CLI spoofing) occurs when fraudsters:
- Use multiple fake caller IDs to call the same number
- Attempt to bypass fraud detection systems
- Target specific individuals or businesses
- Conduct social engineering attacks

### 1.3 How the System Helps

- **Real-time Detection**: Identifies attacks within milliseconds
- **Automatic Protection**: Can disconnect fraudulent calls automatically
- **Alert Dashboard**: Visual monitoring of threats
- **Compliance**: Meets NCC regulatory requirements

---

## 2. Getting Started

### 2.1 Accessing the Dashboard

**Web Access:**
1. Open your browser (Chrome, Firefox, Safari, or Edge)
2. Navigate to: `https://acm.yourcompany.com`
3. Enter your username and password
4. Complete two-factor authentication (if enabled)

**Mobile Access:**
1. Download "ACM Monitor" from App Store or Play Store
2. Enter server URL: `acm.yourcompany.com`
3. Login with your credentials

### 2.2 First-Time Setup

Upon first login:
1. Change your temporary password
2. Set up two-factor authentication
3. Configure notification preferences
4. Review the quick start guide

### 2.3 User Roles

| Role | Permissions |
|------|-------------|
| **Viewer** | View dashboard, alerts, and reports |
| **Operator** | View + acknowledge alerts |
| **Analyst** | Operator + investigate, whitelist |
| **Supervisor** | Analyst + configure settings |
| **Admin** | Full system access |

### 2.4 Password Requirements

- Minimum 12 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character
- Changed every 90 days

---

## 3. Dashboard Overview

### 3.1 Main Dashboard Layout

```
┌─────────────────────────────────────────────────────────────────────────┐
│  [Logo]  Anti-Call Masking Dashboard    [Notifications] [User Menu]    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                      Key Metrics Bar                              │  │
│  │  Active: 245  │  Alerts: 12  │  CPS: 45.2  │  Uptime: 99.99%    │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  ┌─────────────────────────┐  ┌─────────────────────────────────────┐  │
│  │    Real-Time Feed       │  │       Alert Map                     │  │
│  │                         │  │                                     │  │
│  │  10:23 CRITICAL Alert   │  │   [Geographic visualization of     │  │
│  │  10:21 HIGH Alert       │  │    attack origins and targets]     │  │
│  │  10:15 Calls blocked    │  │                                     │  │
│  │  10:12 Pattern detected │  │                                     │  │
│  │                         │  │                                     │  │
│  └─────────────────────────┘  └─────────────────────────────────────┘  │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                   Traffic Timeline Chart                        │   │
│  │   [Line chart showing calls per second over last hour]          │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Key Metrics Explained

| Metric | Description | Normal Range |
|--------|-------------|--------------|
| **Active Calls** | Currently active calls in system | 100-1000 |
| **Alerts Today** | Fraud alerts generated today | 0-50 |
| **CPS** | Calls processed per second | 20-150 |
| **Uptime** | System availability | 99.9%+ |
| **Detection Rate** | Successful fraud detections | 99%+ |

### 3.3 Navigation Menu

- **Dashboard** - Main monitoring view
- **Alerts** - Alert queue and history
- **Analytics** - Charts and statistics
- **Reports** - Generate and download reports
- **Configuration** - Settings (role-dependent)
- **Help** - Documentation and support

### 3.4 Status Indicators

| Icon | Meaning |
|------|---------|
| 🟢 Green | System healthy, no critical alerts |
| 🟡 Yellow | Warning - elevated activity |
| 🔴 Red | Critical alert requires attention |
| ⚪ Gray | Component offline or unavailable |

---

## 4. Alert Management

### 4.1 Alert List View

Navigate to **Alerts** to see all fraud alerts:

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Alerts                                         [Filter] [Export]       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ 🔴 CRITICAL │ ACM-2026-001234 │ +2348012345678 │ 7 A-numbers   │   │
│  │    10:23:45 │ Status: NEW     │ Window: 4.2s   │ [View] [Ack]  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ 🟠 HIGH     │ ACM-2026-001233 │ +2348023456789 │ 5 A-numbers   │   │
│  │    10:21:12 │ Status: ACK     │ Window: 3.8s   │ [View]        │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Alert Severity Levels

| Severity | Color | A-Numbers | Response Time |
|----------|-------|-----------|---------------|
| **CRITICAL** | 🔴 Red | 7+ | Immediate |
| **HIGH** | 🟠 Orange | 5-6 | Within 15 min |
| **MEDIUM** | 🟡 Yellow | 3-4 | Within 30 min |
| **LOW** | 🟢 Green | 2 | Within 1 hour |

### 4.3 Viewing Alert Details

Click on any alert to see full details:

**Alert Information:**
- Alert ID and timestamp
- Targeted B-number
- All A-numbers involved
- Detection window duration
- Source IP addresses
- Actions taken

**Investigation Tools:**
- View call timeline
- Check B-number history
- See related alerts
- Geographic visualization

### 4.4 Alert Actions

| Action | Description | Required Role |
|--------|-------------|---------------|
| **Acknowledge** | Take ownership of alert | Operator+ |
| **Investigate** | Start formal investigation | Analyst+ |
| **Disconnect** | Terminate active calls | Analyst+ |
| **Block** | Block A-number pattern | Analyst+ |
| **Whitelist** | Add to whitelist | Analyst+ |
| **Escalate** | Send to supervisor | Operator+ |
| **Resolve** | Mark as handled | Analyst+ |
| **False Positive** | Mark as incorrect | Analyst+ |

### 4.5 Filtering Alerts

Filter options:
- **Status**: New, Acknowledged, Investigating, Resolved
- **Severity**: Critical, High, Medium, Low
- **Date Range**: Custom date selection
- **B-Number**: Search by targeted number
- **Assigned To**: Filter by analyst

### 4.6 Bulk Actions

Select multiple alerts for bulk operations:
1. Check boxes next to alerts
2. Click "Bulk Actions"
3. Choose action (Acknowledge All, Export, etc.)

---

## 5. Analytics & Reports

### 5.1 Real-Time Analytics

Access via **Analytics** > **Real-Time**:

**Available Charts:**
- Calls per second (live)
- Alerts by severity (pie chart)
- Top targeted B-numbers
- Detection latency histogram
- Geographic heat map

### 5.2 Historical Analytics

Access via **Analytics** > **Historical**:

**Time Ranges:**
- Last 24 hours
- Last 7 days
- Last 30 days
- Custom range

**Analysis Options:**
- Trend analysis
- Peak traffic times
- Attack patterns
- False positive rate

### 5.3 Generating Reports

Access via **Reports** > **Generate**:

**Report Types:**
| Report | Description | Frequency |
|--------|-------------|-----------|
| Daily Summary | Yesterday's statistics | Daily |
| Weekly Digest | Week's overview | Weekly |
| Monthly Report | Full monthly analysis | Monthly |
| Custom Report | User-defined parameters | On demand |

**Steps to Generate:**
1. Select report type
2. Choose date range
3. Select metrics to include
4. Choose format (PDF, CSV, Excel)
5. Click "Generate"
6. Download when ready

### 5.4 Scheduled Reports

Set up automatic report delivery:
1. Go to **Reports** > **Scheduled**
2. Click "New Schedule"
3. Select report type
4. Set frequency (daily, weekly, monthly)
5. Enter email recipients
6. Save schedule

---

## 6. Configuration

### 6.1 Notification Preferences

Access via **Settings** > **Notifications**:

**Email Notifications:**
- Critical alerts: Immediate
- High alerts: Digest (hourly)
- Daily summary: 08:00 WAT

**Push Notifications (Mobile):**
- Critical: Enabled
- High: Enabled
- Medium: Disabled
- Low: Disabled

### 6.2 Dashboard Customization

**Customize Your View:**
1. Click "Customize" on dashboard
2. Drag and drop widgets
3. Resize as needed
4. Add/remove metrics
5. Save layout

**Available Widgets:**
- Alert feed
- Traffic chart
- Top targets
- System health
- Geographic map
- Quick stats

### 6.3 Whitelist Management

Access via **Configuration** > **Whitelist** (Analyst+ role):

**Adding to Whitelist:**
1. Click "Add Entry"
2. Enter B-number
3. Provide reason
4. Set expiration (optional)
5. Submit for approval

**Whitelist Use Cases:**
- Call centers with high volume
- Conference bridges
- IVR systems
- Known business numbers

### 6.4 Alert Thresholds

View current thresholds (Supervisor+ to modify):

| Parameter | Current Value | Description |
|-----------|---------------|-------------|
| Detection Threshold | 5 | A-numbers to trigger |
| Detection Window | 5 seconds | Time window |
| Auto-disconnect | Enabled | Auto-terminate calls |
| Cooldown Period | 60 seconds | Between alerts |

---

## 7. Mobile App

### 7.1 App Features

- Real-time alert notifications
- Dashboard view
- Alert acknowledgment
- Quick actions
- Offline alert queue

### 7.2 Installing the App

**iOS:**
1. Open App Store
2. Search "ACM Monitor"
3. Download and install
4. Open and configure

**Android:**
1. Open Play Store
2. Search "ACM Monitor"
3. Download and install
4. Open and configure

### 7.3 App Configuration

1. Launch app
2. Enter server URL
3. Login with credentials
4. Enable push notifications
5. Set notification preferences

### 7.4 Using the App

**Main Views:**
- **Dashboard**: Summary metrics
- **Alerts**: Alert list and actions
- **Quick Actions**: Common operations

**Responding to Alerts:**
1. Receive push notification
2. Tap to open alert
3. Review details
4. Take action (Acknowledge, etc.)

---

## 8. Keyboard Shortcuts

### 8.1 Global Shortcuts

| Shortcut | Action |
|----------|--------|
| `G` + `D` | Go to Dashboard |
| `G` + `A` | Go to Alerts |
| `G` + `R` | Go to Reports |
| `G` + `S` | Go to Settings |
| `/` | Focus search |
| `?` | Show shortcuts help |
| `Esc` | Close modal/dialog |

### 8.2 Alert View Shortcuts

| Shortcut | Action |
|----------|--------|
| `J` | Next alert |
| `K` | Previous alert |
| `A` | Acknowledge |
| `I` | Start investigation |
| `D` | Disconnect calls |
| `E` | Escalate |
| `N` | Add note |
| `R` | Generate report |

### 8.3 Dashboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `1-9` | Switch time range |
| `F` | Toggle fullscreen |
| `Space` | Pause/resume updates |
| `M` | Toggle map view |

---

## 9. Troubleshooting

### 9.1 Common Issues

**Can't Login:**
- Verify username and password
- Check Caps Lock
- Clear browser cache
- Try incognito/private mode
- Contact IT if locked out

**Dashboard Not Loading:**
- Check internet connection
- Refresh the page
- Try different browser
- Clear browser cache

**Alerts Not Updating:**
- Check connection indicator
- Verify WebSocket connection
- Refresh the page
- Check network firewall

**Mobile App Issues:**
- Update to latest version
- Check server URL
- Re-login if needed
- Reinstall if persistent

### 9.2 Browser Requirements

| Browser | Minimum Version |
|---------|-----------------|
| Chrome | 90+ |
| Firefox | 88+ |
| Safari | 14+ |
| Edge | 90+ |

**Enable These Features:**
- JavaScript
- Cookies
- WebSocket connections
- Notifications (optional)

### 9.3 Getting Help

**In-App Help:**
- Click Help icon (?)
- Access documentation
- View tutorials

**Support Channels:**
- Email: support@yourcompany.com
- Phone: +234-XXX-XXX-XXXX
- Internal ticket system

---

## 10. FAQ

### General Questions

**Q: What is a "masking attack"?**
A: A masking attack occurs when fraudsters use multiple different caller IDs to call the same destination, typically within seconds. This is done to evade detection and overwhelm the target.

**Q: How fast does the system detect attacks?**
A: The system detects attacks within milliseconds (typically under 1ms) and generates alerts immediately.

**Q: What happens when an attack is detected?**
A: The system can automatically disconnect fraudulent calls, generate alerts, and notify operators. The response depends on your configuration.

### Alert Questions

**Q: What should I do when I see a CRITICAL alert?**
A: Immediately acknowledge the alert, verify it's not a false positive, and take appropriate action (disconnect calls, block pattern if needed).

**Q: How do I know if it's a false positive?**
A: Check if the B-number is a known call center, conference bridge, or legitimate high-volume number. Look for patterns that suggest normal business activity.

**Q: Can I bulk-acknowledge alerts?**
A: Yes, select multiple alerts using checkboxes and use the "Bulk Actions" menu.

### Configuration Questions

**Q: How do I add a number to the whitelist?**
A: Go to Configuration > Whitelist, click "Add Entry", enter the B-number and reason, then submit. This requires Analyst role or higher.

**Q: Can I change the detection threshold?**
A: Threshold changes require Supervisor role. Contact your supervisor or admin to request changes.

**Q: How do I change my notification preferences?**
A: Go to Settings > Notifications to customize email and push notification settings.

### Technical Questions

**Q: What does "CPS" mean?**
A: CPS stands for "Calls Per Second" - the number of call events the system processes each second.

**Q: Why does my session timeout?**
A: For security, sessions timeout after 30 minutes of inactivity. You'll need to log in again.

**Q: Is my data secure?**
A: Yes, all data is encrypted in transit (TLS 1.3) and at rest (AES-256). Access is controlled by role-based permissions.

---

## Appendix A: Glossary

| Term | Definition |
|------|------------|
| **A-Number** | The calling party's phone number (source) |
| **B-Number** | The called party's phone number (destination) |
| **CLI** | Calling Line Identification |
| **CPS** | Calls Per Second |
| **Detection Window** | Time period for counting distinct A-numbers |
| **False Positive** | Alert for legitimate traffic |
| **Masking Attack** | Multiple A-numbers calling same B-number |
| **Threshold** | Number of A-numbers to trigger alert |
| **Whitelist** | Approved numbers exempt from detection |

---

**Document Version:** 1.0
**Classification:** Internal Use Only
