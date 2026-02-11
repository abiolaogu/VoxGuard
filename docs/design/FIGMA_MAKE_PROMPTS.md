# VoxGuard — Figma Make Design Prompts

> Design prompts for generating VoxGuard UI screens in Figma Make.

## Prompt 15: VoxGuard Security Platform

### Screen: RVS Dashboard
```
Design a fraud detection dashboard for "VoxGuard RVS" with:
- Top metric cards: RVS Status (green connected badge), Latency (23ms), Uptime (99.97%), Circuit Breaker (closed/open badge)
- Area chart showing "Verification Trend (30 Days)" with two series: Verifications (blue) and Blocked (red)
- Donut chart showing "HLR Distribution" with Valid (green), Invalid (red), Unknown (gray), Ported (yellow)
- Data table: Recent Verifications with columns ID, Calling #, Called #, RVS Score (color badge), HLR Status, Network, Country, Response Time, Cached, Timestamp
- Tabs: Overview | Verifications | Configuration
- Configuration tab shows Feature Flags list with toggle switches and phase indicators (Shadow/Composite/Active)
- ML Model Status section with 3 model cards showing name, version, accuracy %, status badge, features count
- Detection Engine Health section with P99 Latency, Calls/sec, Cache Hit Rate, Uptime metrics
- Dark mode compatible with CSS variables
```

### Screen: Composite Scoring
```
Design a composite fraud scoring page with:
- Summary stats: Total Decisions, Average Score, Block Rate, Average Latency
- Data table with columns: Call ID, VoxGuard Score, RVS Score, Composite Score (color-coded 0-100), Decision (Allow green / Block red / Review yellow), Latency, Contributing Factors
- Each factor shown as a small chip with name and contribution percentage
- Score distribution histogram chart
```

### Screen: Lists Management
```
Design a whitelist/blacklist management page with:
- Tab bar: Blacklist | Whitelist
- Add Entry button with modal form (Pattern, Pattern Type dropdown, Reason)
- Data table: Pattern, Type (prefix/exact/regex badge), Reason, Added By, Hit Count, Expires, Source (manual/auto/rvs_sync badges), Delete action
- Import CSV button
- Sync status bar at top showing last sync direction, entries pushed/pulled, errors
```

### Screen: Multi-Call Detection
```
Design a multi-call fraud detection page with:
- Alert banner for active high-risk patterns
- Data table: B-Number (monospace), Call Count, Unique A-Numbers, Time Window (minutes), Risk Score (color gradient 0-1), Status (active/resolved/monitoring badges), Source IPs, Fraud Type
- Action buttons: Block (red), Resolve (green) per row
- Filter bar: Status, Minimum Risk Score slider, Time Window range
```

### Screen: Revenue Fraud
```
Design a revenue fraud page with two tabs:
- Wangiri tab: Table with Calling Number, Country (with flag icon), Ring Duration (seconds), Callback Count, Revenue Risk (currency formatted, red for high), Status, Block button
- IRSF tab: Table with Destination, Country, Total Minutes, Total Cost, Pump Pattern (short_stop/long_duration/sequential badges), Status
- Summary cards at top: Active Wangiri, Active IRSF, Total Revenue at Risk, Blocked Today
```

### Screen: Traffic Control
```
Design a traffic control rules page with:
- Create Rule button opening a form modal
- Data table: Rule Name, Description, Enabled (toggle switch), Priority (sortable), Action (allow green / block red / rate_limit yellow / alert blue badges), Conditions count, Hit Count, Last Hit, Edit/Delete actions
- Rule detail view showing conditions as cards: Field, Operator, Value
```

### Screen: False Positives
```
Design a false positive review page with:
- Data table: Alert Type badge, Calling Number, Called Number, Original Score, Confidence (0-1 color bar), Detection Method, Matched Patterns (chip list), Status (pending/confirmed_fp/confirmed_tp/disputed badges)
- Review actions: Confirm FP (green), Confirm TP (red), Dispute (yellow)
- Behavioral profile card showing avg daily calls, avg call duration, typical destinations, activity hours, risk trend
```
