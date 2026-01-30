# SOC Analyst Manual
## Anti-Call Masking Detection System

**Version:** 1.0.0
**Last Updated:** November 2024

---

## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Understanding Call Masking Fraud](#understanding-call-masking-fraud)
4. [Dashboard Overview](#dashboard-overview)
5. [Alert Investigation](#alert-investigation)
6. [Response Procedures](#response-procedures)
7. [Reporting](#reporting)
8. [Best Practices](#best-practices)

---

## 1. Introduction

### 1.1 Purpose
This manual guides Security Operations Center (SOC) analysts in effectively using the Anti-Call Masking Detection System to identify, investigate, and respond to multicall masking fraud attacks.

### 1.2 Your Role
As a SOC Analyst, you are responsible for:
- Monitoring real-time fraud alerts
- Investigating suspicious call patterns
- Escalating confirmed fraud incidents
- Documenting investigation findings
- Recommending preventive measures

### 1.3 Access Requirements
- SOC Analyst role credentials
- Access to the Admin Dashboard
- Mobile app for on-call monitoring

---

## 2. Getting Started

### 2.1 Logging In

**Web Dashboard:**
1. Navigate to `https://acm.yourcompany.com`
2. Enter your username and password
3. Complete MFA verification
4. You will see the SOC Analyst Dashboard

**Mobile App:**
1. Download "ACM Monitor" from App Store/Play Store
2. Enter server URL: `acm.yourcompany.com`
3. Login with your credentials
4. Enable push notifications for alerts

### 2.2 Dashboard Layout

```
┌─────────────────────────────────────────────────────────────────────┐
│  [Logo]  Anti-Call Masking Monitor    [Notifications] [Profile]    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────────┐ │
│  │ Active      │  │ Alerts      │  │ Detection   │  │ Calls/Sec  │ │
│  │ Calls: 245  │  │ Today: 12   │  │ Rate: 99.8% │  │ CPS: 45.2  │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └────────────┘ │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    Real-Time Alert Feed                      │  │
│  │  ┌───────────────────────────────────────────────────────┐   │  │
│  │  │ 🔴 CRITICAL | B-Number: +1555123456 | 7 A-Numbers     │   │  │
│  │  │    Detected: 10:23:45 | Status: NEW                   │   │  │
│  │  └───────────────────────────────────────────────────────┘   │  │
│  │  ┌───────────────────────────────────────────────────────┐   │  │
│  │  │ 🟡 HIGH | B-Number: +447891234567 | 5 A-Numbers       │   │  │
│  │  │    Detected: 10:21:12 | Status: INVESTIGATING         │   │  │
│  │  └───────────────────────────────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌────────────────────────┐  ┌───────────────────────────────────┐ │
│  │   Threat Map           │  │   Top Targeted B-Numbers          │ │
│  │   [Geographic View]    │  │   1. +1555123456 (7 attacks)      │ │
│  │                        │  │   2. +447891234567 (5 attacks)    │ │
│  │                        │  │   3. +234801234567 (3 attacks)    │ │
│  └────────────────────────┘  └───────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. Understanding Call Masking Fraud

### 3.1 What is Multicall Masking?

Multicall masking is a fraud technique where attackers:
1. Use multiple distinct CLI (A-numbers) to call the same destination (B-number)
2. Calls occur within a very short time window (typically < 5 seconds)
3. Purpose: Bypass fraud detection, overwhelm recipient, or conduct social engineering

### 3.2 Attack Patterns

| Pattern | Description | Severity |
|---------|-------------|----------|
| **Spray Attack** | 5+ A-numbers to 1 B-number in < 5 sec | CRITICAL |
| **Sequential Masking** | Rotating A-numbers in sequence | HIGH |
| **Burst Pattern** | Sudden spike in calls to B-number | HIGH |
| **Low-and-Slow** | Calls just under threshold | MEDIUM |

### 3.3 Indicators of Compromise (IOCs)

- Multiple distinct source numbers targeting single destination
- Calls originating from single IP but different CLIs
- Abnormal call timing patterns
- High call attempt-to-answer ratio
- Geographic impossibility (calls from distant locations simultaneously)

---

## 4. Dashboard Overview

### 4.1 Key Metrics

| Metric | Description | Normal Range |
|--------|-------------|--------------|
| **Active Calls** | Currently in-progress calls | 100-500 |
| **Alerts Today** | Total alerts generated | < 20 |
| **Detection Rate** | Successful detections | > 99% |
| **CPS** | Calls per second | 20-100 |
| **Avg Latency** | Detection latency | < 10ms |

### 4.2 Alert Severity Levels

| Level | Color | Distinct A-Numbers | Response Time |
|-------|-------|-------------------|---------------|
| CRITICAL | 🔴 Red | 7+ | Immediate (< 5 min) |
| HIGH | 🟠 Orange | 5-6 | < 15 min |
| MEDIUM | 🟡 Yellow | 3-4 | < 30 min |
| LOW | 🟢 Green | 2 | < 1 hour |

### 4.3 Navigating the Interface

**Main Menu:**
- **Dashboard**: Real-time monitoring
- **Alerts**: Alert queue and history
- **Investigations**: Active cases
- **Reports**: Analytics and exports
- **Settings**: Notification preferences

---

## 5. Alert Investigation

### 5.1 Initial Triage

When an alert appears:

1. **Assess Severity**: Check the number of distinct A-numbers
2. **Check Timing**: Verify the detection window
3. **Review Context**: Look at the targeted B-number

### 5.2 Investigation Workflow

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│   Alert      │───▶│   Triage     │───▶│  Investigate │───▶│   Resolve    │
│   Received   │    │   (2 min)    │    │  (15 min)    │    │   (5 min)    │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
                           │                    │                    │
                           ▼                    ▼                    ▼
                    - Check severity     - Analyze calls     - Document
                    - Assign priority    - Check IOCs        - Escalate/Close
                    - Take ownership     - Correlate data    - Recommend
```

### 5.3 Detailed Investigation Steps

**Step 1: Open Alert Details**
```
Click on alert → View Details

Alert Information:
├── Alert ID: ACM-2024-001234
├── Detected At: 2024-11-26 10:23:45 UTC
├── B-Number: +15551234567
├── Distinct A-Numbers: 7
├── Detection Window: 4.2 seconds
└── Status: NEW
```

**Step 2: Analyze Source Numbers**
```
A-Numbers Involved:
├── +14151234567 (Call at 10:23:41, IP: 192.168.1.10)
├── +14251234568 (Call at 10:23:42, IP: 192.168.1.10)
├── +14351234569 (Call at 10:23:42, IP: 192.168.1.10)
├── +14451234570 (Call at 10:23:43, IP: 192.168.1.11)
├── +14551234571 (Call at 10:23:44, IP: 192.168.1.11)
├── +14651234572 (Call at 10:23:44, IP: 192.168.1.12)
└── +14751234573 (Call at 10:23:45, IP: 192.168.1.12)

Analysis:
- Same IP pattern indicates coordinated attack
- Sequential number pattern (+1 increment)
- All calls within 4 seconds
```

**Step 3: Check Historical Data**
```sql
-- Query previous incidents for this B-number
SELECT * FROM fraud_alerts
WHERE b_number = '+15551234567'
AND time > now() - interval '30 days'
ORDER BY time DESC;
```

**Step 4: Correlate with Other Data**
- Check if B-number is a known target
- Look for related alerts from same source IPs
- Review carrier patterns

### 5.4 Investigation Checklist

- [ ] Alert severity confirmed
- [ ] All A-numbers documented
- [ ] Source IPs identified
- [ ] Call timing analyzed
- [ ] Historical patterns checked
- [ ] Related alerts reviewed
- [ ] B-number owner notified (if applicable)
- [ ] Calls disconnected (if confirmed fraud)
- [ ] Investigation notes documented

---

## 6. Response Procedures

### 6.1 Immediate Response (CRITICAL)

**Time: < 5 minutes**

1. **Acknowledge Alert**
   ```
   Click "Acknowledge" → Add analyst name → Confirm
   ```

2. **Verify Active Attack**
   ```
   Check "Active Calls" → Filter by B-number → Verify ongoing calls
   ```

3. **Execute Disconnect (if authorized)**
   ```
   Select calls → Click "Disconnect All" → Confirm action
   ```

4. **Block Pattern (if confirmed fraud)**
   ```
   Actions → "Block A-Numbers" → Select duration → Apply
   ```

### 6.2 Standard Response (HIGH/MEDIUM)

**Time: < 15-30 minutes**

1. Acknowledge and assign
2. Complete investigation checklist
3. Document findings
4. Determine if legitimate or fraudulent
5. Take appropriate action
6. Update alert status

### 6.3 Response Actions

| Action | When to Use | Authorization |
|--------|-------------|---------------|
| **Acknowledge** | All alerts | Self |
| **Investigate** | All alerts | Self |
| **Disconnect** | Confirmed fraud | Team Lead |
| **Block Pattern** | Repeated attacks | Team Lead |
| **Whitelist** | False positive | Manager |
| **Escalate** | Unknown/complex | Self |

### 6.4 Escalation Matrix

| Condition | Escalate To | Method |
|-----------|-------------|--------|
| > 10 A-numbers | SOC Manager | Immediate call |
| Financial impact suspected | Fraud Team | Ticket + call |
| Customer complaint | Account Manager | Ticket |
| System issue | IT Operations | Incident ticket |
| Unknown attack type | Security Team | Email + ticket |

---

## 7. Reporting

### 7.1 Shift Reports

Generate at end of each shift:

```
Daily Shift Report - [Date]
Analyst: [Name]
Shift: [Time Range]

Summary:
├── Total Alerts: 15
├── CRITICAL: 2 (resolved)
├── HIGH: 5 (3 resolved, 2 investigating)
├── MEDIUM: 6 (resolved)
├── LOW: 2 (resolved)
├── False Positives: 1
└── Escalations: 1

Notable Incidents:
1. ACM-2024-001234: Spray attack on +15551234567
   - 7 distinct A-numbers
   - Calls disconnected
   - Pattern blocked for 24h

Recommendations:
- Consider adjusting threshold for carrier X
- Monitor B-number +447891234567 for repeat attacks
```

### 7.2 Incident Reports

For CRITICAL incidents:

```
Incident Report: ACM-2024-001234

1. Executive Summary
   - Multicall masking attack detected and mitigated
   - 7 fraudulent calls disconnected
   - No financial impact

2. Timeline
   10:23:41 - First fraudulent call initiated
   10:23:45 - Detection triggered (7 A-numbers)
   10:24:02 - Alert acknowledged by analyst
   10:24:15 - All calls disconnected
   10:24:30 - Pattern blocked

3. Technical Details
   [Include A-numbers, IPs, timing analysis]

4. Root Cause
   - Attacker used VoIP gateway with CLI spoofing
   - Source IP traced to known fraud network

5. Recommendations
   - Add source IP range to blacklist
   - Notify upstream carrier
```

### 7.3 Weekly Analytics

Access via: Reports → Weekly Summary

Key metrics:
- Total alerts by severity
- Average response time
- False positive rate
- Top targeted B-numbers
- Most common attack patterns

---

## 8. Best Practices

### 8.1 Monitoring Tips

- **Stay Alert**: Monitor dashboard during high-traffic periods
- **Quick Response**: Aim for < 2 min acknowledgment
- **Document Everything**: Notes help future investigations
- **Know Your Patterns**: Learn normal vs. abnormal traffic

### 8.2 Investigation Tips

- Always verify before taking action
- Check for false positives (conference calls, call centers)
- Look for patterns across multiple alerts
- Correlate with external threat intelligence

### 8.3 Communication Guidelines

- Use standardized terminology
- Provide clear, concise updates
- Escalate early when uncertain
- Keep stakeholders informed

### 8.4 Common False Positives

| Scenario | Indicators | Action |
|----------|------------|--------|
| Conference call setup | Sequential timing, same carrier | Whitelist |
| Call center campaign | Business hours, known numbers | Verify with carrier |
| Callback service | Customer-initiated, varied timing | Monitor |

---

## Quick Reference Card

### Alert Response Times
- 🔴 CRITICAL: < 5 min
- 🟠 HIGH: < 15 min
- 🟡 MEDIUM: < 30 min
- 🟢 LOW: < 1 hour

### Keyboard Shortcuts
- `A` - Acknowledge selected alert
- `I` - Open investigation panel
- `D` - Disconnect calls (requires confirmation)
- `E` - Escalate alert
- `N` - Add note
- `R` - Generate report

### Emergency Contacts
- SOC Manager: ext. 1234
- Security Team: ext. 5678
- IT Operations: ext. 9012

---

**Document Version:** 1.0.0
**Classification:** Internal Use Only
