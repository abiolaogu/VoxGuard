# VoxGuard — Figma Make Design Prompts

> Comprehensive high-fidelity design prompts for generating all VoxGuard UI screens in Figma Make.
> VoxGuard is an Anti-Call Masking & Voice Network Fraud Detection Platform for Nigerian ICLs (Interconnect Clearinghouses).

---

## Table of Contents

1. [Brand System & Design Tokens](#brand-system--design-tokens)
2. [Global Components](#global-components)
3. [Screen Prompts (31 total)](#screen-prompts)
   - [01 Login Page](#01-login-page)
   - [02 Dashboard](#02-dashboard)
   - [03 Alerts List](#03-alerts-list)
   - [04 Alert Detail / Show](#04-alert-detail--show)
   - [05 Alert Edit](#05-alert-edit)
   - [06 Gateways List](#06-gateways-list)
   - [07 Gateway Detail](#07-gateway-detail)
   - [08 Gateway Create / Edit](#08-gateway-create--edit)
   - [09 Users List](#09-users-list)
   - [10 User Detail](#10-user-detail)
   - [11 User Create / Edit](#11-user-create--edit)
   - [12 Analytics](#12-analytics)
   - [13 Settings](#13-settings)
   - [14 RVS Dashboard](#14-rvs-dashboard)
   - [15 Composite Scoring](#15-composite-scoring)
   - [16 Lists Management](#16-lists-management)
   - [17 Multi-Call Detection](#17-multi-call-detection)
   - [18 Revenue Fraud](#18-revenue-fraud)
   - [19 Traffic Control](#19-traffic-control)
   - [20 False Positives](#20-false-positives)
   - [21 NCC Compliance](#21-ncc-compliance)
   - [22 MNP Lookup](#22-mnp-lookup)
   - [23 Case Management List](#23-case-management-list)
   - [24 Case Detail](#24-case-detail)
   - [25 CDR Browser](#25-cdr-browser)
   - [26 KPI Scorecard](#26-kpi-scorecard)
   - [27 Audit Log](#27-audit-log)
   - [28 ML Model Dashboard](#28-ml-model-dashboard)
   - [29 Report Builder](#29-report-builder)
   - [30 Class 4 Switch Report](#30-class-4-switch-report)
   - [31 Class 5 Switch Report](#31-class-5-switch-report)

---

## Brand System & Design Tokens

### Color Palette (VG_COLORS)

```
PRIMARY PALETTE
  primary:        #1B4F72  (Deep Blue — Trust & Security)
  primaryLight:   #2E86AB
  primaryDark:    #154360

SECONDARY PALETTE
  secondary:      #17A2B8  (Teal — Technology & Innovation)
  secondaryLight: #20C997
  secondaryDark:  #138496

ACCENT PALETTE
  accent:         #E67E22  (Orange — Alert & Attention)
  accentLight:    #F39C12
  accentDark:     #D35400

STATUS COLORS
  success:        #28A745
  warning:        #FFC107
  error:          #DC3545
  info:           #17A2B8

SEVERITY COLORS (for alert badges)
  CRITICAL:       bg #DC3545, text #FFFFFF
  HIGH:           bg #E67E22, text #FFFFFF
  MEDIUM:         bg #FFC107, text #000000
  LOW:            bg #17A2B8, text #FFFFFF

STATUS COLORS (for alert status badges)
  NEW:            bg #17A2B8, text #FFFFFF
  INVESTIGATING:  bg #FFC107, text #FFFFFF
  CONFIRMED:      bg #DC3545, text #FFFFFF
  RESOLVED:       bg #28A745, text #FFFFFF
  FALSE_POSITIVE: bg #6C757D, text #FFFFFF

FRAUD TYPE COLORS
  CLI Spoofing:   #722ED1
  Wangiri:        #E67E22
  IRSF:           #DC3545
  SIM Box:        #17A2B8
  Traffic Anomaly:#6C757D

DECISION COLORS (Composite Scoring)
  allow:          #28A745
  block:          #DC3545
  review:         #FFC107

NEUTRALS (Light Mode)
  background:     #F8F9FA
  surface:        #FFFFFF
  textPrimary:    #212529
  textSecondary:  #6C757D
  border:         #DEE2E6

NEUTRALS (Dark Mode)
  background:     #141414
  surface:        #1F1F1F
  textPrimary:    #FFFFFF
  textSecondary:  #A0A0A0
  border:         #303030
  siderBg:        #001529
  headerBg:       #1F1F1F
  tableHeaderBg:  #1D1D1D
  tableRowHover:  #2A2A2A

AIDD TIER BADGE COLORS
  T0:             Ant Design "default" (blue-ish gray) — auto-merge safe
  T1:             Ant Design "warning" (amber) — requires review
  T2:             Ant Design "error" (red) — requires admin approval
```

### Typography

```
Font Family:       'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif
Monospace:         'JetBrains Mono', monospace (for phone numbers, IPs, scores, code)
Font Weights:      300 (Light), 400 (Regular), 500 (Medium), 600 (Semi-Bold), 700 (Bold)

SCALE
  Page Title:      24px, font-weight 700, color textPrimary
  Page Subtitle:   14px, font-weight 400, color textSecondary
  Card Title:      16px, font-weight 600
  Section Label:   14px, font-weight 600, text-transform uppercase, letter-spacing 0.5px
  Body Text:       14px, font-weight 400
  Small Text:      12px
  Tiny Text:       10-11px (timestamps, captions)
  Metric Number:   32px, font-weight 700, JetBrains Mono
  Stat Value:      20-24px, font-weight 600
  Badge/Tag Text:  11-12px, font-weight 600
  Sidebar Title:   Level 5, font-weight 700, color #FFFFFF, letter-spacing -0.5px
  Sidebar Sub:     10px, uppercase, letter-spacing 1px, color rgba(255,255,255,0.65)
```

### Spacing & Shapes

```
Border Radius:     6px (default), 8px (cards), 10px (badges/pills), 12px (login card)
Page Padding:      24px
Card Padding:      16-24px
Gutter:            16px (standard), 24px (large sections)
Header Height:     64px
Sidebar Width:     200px (expanded), 80px (collapsed)
Box Shadow:        0 2px 0 rgba(27,79,114,0.1) (buttons), 0 8px 32px rgba(0,0,0,0.2) (login card)
```

### Responsive Breakpoints

```
Mobile:   xs  — max-width 767px  (single column, stacked cards)
Tablet:   sm  — 768px-1023px     (2-column grid)
Desktop:  lg  — 1024px+          (full layout with sidebar)
```

### Transitions & Micro-Interactions

```
Page Entry:        .acm-fade-in — opacity 0->1 over 300ms ease-in
Hover on Cards:    elevation increase, subtle border color change
Hover on Rows:     background #F5F5F5 (light) / #2A2A2A (dark)
Button States:     default -> hover (darken 10%) -> active (darken 20%) -> disabled (opacity 0.5)
Loading:           Ant Design Spin component, skeleton screens for tables/cards/charts
Focus:             2px solid #1B4F72 outline, 2px offset (keyboard navigation)
Badge Pulse:       processing badge with pulsing animation for active critical alerts
Toggle Switch:     smooth 200ms slide transition
Dropdown Open:     fade + slide down 150ms
```

---

## Global Components

### G1: Application Header

```
Design a horizontal application header bar, 64px tall, full width.
Background: #FFFFFF (light) / #1F1F1F (dark).
Bottom border: 1px solid #DEE2E6 (light) / 1px solid #303030 (dark).
Content is right-aligned using a horizontal Space with "middle" gap.

Elements from left to right:
1. Language Switcher — Ant Design Select, width 130px, size "small",
   suffix icon: GlobalOutlined.
   Options (10 languages):
   - en: "English"
   - fr: "Francais"
   - pt: "Portugues"
   - ha: "Hausa"
   - yo: "Yoruba"
   - ig: "Igbo"
   - ar: "العربية" (RTL support)
   - es: "Espanol"
   - zh: "中文"
   - sw: "Kiswahili"

2. Currency Switcher — Ant Design Select, width 100px, size "small",
   suffix icon: DollarOutlined, showSearch enabled.
   Options (20 currencies):
   - NGN (Nigerian Naira), USD, EUR, GBP, GHS, KES, ZAR,
     XOF, XAF, EGP, TZS, UGX, CNY, SAR, AED, INR, BRL, CAD, AUD, JPY.
   Each option label shows currency code, title tooltip shows full name with symbol.
   Search filters by code or name.

3. Theme Toggle — icon-only Button, type "text", fontSize 18.
   Shows SunOutlined (in dark mode) or MoonOutlined (in light mode).
   Tooltip: "Light Mode" / "Dark Mode".

4. Portal Hub — Button opening a dropdown of external service links grouped by category:
   Categories: Monitoring (Grafana, Prometheus), Databases (YugabyteDB),
   Analytics (ClickHouse, QuestDB), SIP Analysis (Homer), Administration (Hasura Console).
   Each item shows icon, name, and description. Opens in new tab.

5. Notifications Dropdown — Badge wrapping a BellOutlined button.
   Badge count shows unresolved alert count (real-time via subscription).
   Badge color: #DC3545 if critical alerts exist, else #FFC107.
   Dropdown (min-width 340px) contains:
   - Header row: "Notifications" text + blue Tag showing unread count
   - Divider
   - Notification cards (max 4 visible), each with:
     - Icon (WarningOutlined red, FileTextOutlined blue, SyncOutlined green)
     - Title (13px bold)
     - Unread dot: 6px circle, #17A2B8, inline with title
     - Description (11px secondary)
     - Timestamp (10px secondary)
   - Divider
   - "View all notifications" link centered, 12px secondary with RightOutlined arrow
   Clicking "View all" navigates to /alerts.

6. User Menu — Dropdown with arrow, placement bottomRight.
   Trigger shows: Avatar (small, 32px, #1B4F72 background, UserOutlined fallback),
   user name (13px bold), role (11px secondary, capitalize).
   Menu items:
   - Profile (UserOutlined icon)
   - Settings (SettingOutlined icon)
   - Divider
   - Logout (LogoutOutlined icon, danger red)

Accessibility: All buttons have aria-label. Dropdown triggered by click.
Keyboard: Tab through all header elements, Enter/Space to activate.
i18n: All labels use t() from react-i18next.

Dark mode: Background #1F1F1F, border #303030, text colors invert.
Mobile (<768px): Language/Currency switchers collapse to icon-only.
Tablet (768-1024px): Full layout maintained.
```

### G2: Sidebar Navigation

```
Design a collapsible vertical sidebar using Ant Design ThemedSiderV2.
Width: 200px expanded, 80px collapsed. Position: fixed left. Full viewport height.
Background: #154360 (light mode) / #001529 (dark mode).

Brand Section (top):
- Link to /dashboard, no text decoration.
- Expanded: SafetyCertificateOutlined icon (28px, color #17A2B8) + text block:
  "VoxGuard" (level 5 heading, white, bold 700, letter-spacing -0.5px)
  "FRAUD DETECTION" (10px, uppercase, letter-spacing 1px, rgba(255,255,255,0.65))
  Padding: 12px 16px.
- Collapsed: Icon only, centered, padding 12px 8px.

Menu Items (Ant Design Menu, dark theme):
  darkItemBg: #154360, darkItemSelectedBg: #1B4F72, darkItemHoverBg: #1B4F72.
  Font: 14px, white text.

  Top-level items:
  1. Dashboard          — DashboardOutlined
  2. Alerts             — AlertOutlined (with Badge count for unresolved alerts)
  3. Gateways           — ApiOutlined
  4. Security (parent)  — SafetyCertificateOutlined, expandable submenu:
     - RVS Dashboard
     - Composite Scoring
     - Lists Management
     - Multi-Call Detection
     - Revenue Fraud
     - Traffic Control
     - False Positives
     - Cases (FolderOpenOutlined)
  5. CDR Browser        — DatabaseOutlined
  6. KPI Scorecard      — LineChartOutlined
  7. NCC Compliance     — FileTextOutlined
  8. MNP Lookup         — SwapOutlined
  9. Audit Log          — AuditOutlined
  10. ML Dashboard      — RobotOutlined
  11. Reports           — FileSearchOutlined
  12. Users             — UserOutlined
  13. Analytics         — BarChartOutlined
  14. Settings          — SettingOutlined

Active state: selected item has #1B4F72 background with left 3px accent border.
Hover state: background transitions to #1B4F72 over 150ms.
Collapse toggle: bottom of sidebar, chevron icon.

Accessibility: role="navigation", aria-label="Main navigation".
Each menu item has aria-current="page" when active.
Mobile: Sidebar becomes a hamburger drawer overlay.
```

### G3: Error Boundary

```
Design an error fallback screen using Ant Design Result component.
Status: "error".
Title: "Something went wrong" — 24px bold.
SubTitle: "An error occurred while rendering this page. Please try again." — 14px secondary.
Two buttons centered:
  1. "Try Again" — type="primary", #1B4F72 background. Resets error state.
  2. "Go to Dashboard" — default button. Navigates to /dashboard.
Background: inherits from page (white/dark surface).
Centered vertically and horizontally in the content area.
Icon: Ant Design error icon (red circle with X), 72px.
```

### G4: Loading States

```
Skeleton Screens:
- Table Skeleton: 5 rows of animated gray bars matching column widths.
  Header row with darker skeleton. Pulse animation left-to-right shimmer.
- Card Skeleton: Rectangle with rounded corners (8px), animated shimmer.
  Metric area: large bar (32px height), label bar (14px height) above it.
- Chart Skeleton: Rectangular area with wavy line skeleton, axis labels as small bars.
- Full Page Spinner: Ant Design Spin size="large", centered with 48px padding.

All skeletons use:
  Light mode: #F0F0F0 base, #E0E0E0 shimmer
  Dark mode: #2A2A2A base, #3A3A3A shimmer
  Animation: 1.5s ease-in-out infinite pulse
```

### G5: Empty States

```
For each data type, an empty state illustration + message:
- Alerts: Shield icon (64px, #1B4F72) + "No alerts found" + "All clear! No fraud alerts match your current filters."
- Cases: Folder icon (64px) + "No cases yet" + "Create a case to start tracking fraud investigations."
- CDR Records: Phone icon + "No call records" + "Adjust your search criteria or date range."
- Audit Log: File icon + "No audit entries" + "Activity will appear here as users interact with the system."
- Reports: Document icon + "No reports generated" + "Use the form above to generate your first report."
- ML Models: Robot icon + "No models deployed" + "Contact your ML engineering team to deploy models."
Button below message: contextual action (e.g., "Clear Filters", "Create Case").
All text centered. Icon color: #1B4F72.
```

### G6: Toast Notifications

```
Ant Design notification/message system. Top-right position, 4.5s auto-dismiss.
Variants:
  Success: Left border 3px #28A745, CheckCircleOutlined green icon.
  Error:   Left border 3px #DC3545, CloseCircleOutlined red icon.
  Warning: Left border 3px #FFC107, WarningOutlined amber icon.
  Info:    Left border 3px #17A2B8, InfoCircleOutlined teal icon.
Each shows: icon, bold title (14px), description (12px secondary), close X button.
Shadow: 0 4px 12px rgba(0,0,0,0.15).
Border-radius: 6px.
Width: 384px max.
```

### G7: AIDD Tier Badge Component

```
A small pill-shaped Tag component with tooltip.
  T0: Ant Design "default" color, text "AIDD T0", no icon.
       Tooltip: "Tier 0 -- Auto-merge safe (documentation, tests, text)"
  T1: Ant Design "warning" color (amber), text "AIDD T1", LockOutlined icon.
       Tooltip: "Tier 1 -- Requires review (features, logic, blocking actions)"
  T2: Ant Design "error" color (red), text "AIDD T2", SafetyCertificateOutlined icon.
       Tooltip: "Tier 2 -- Requires admin approval (auth, payments, infra)"

Compact variant: No icon, shorter label ("T0"/"T1"/"T2"), smaller font (10px), padding 0 4px.
Full variant: With icon, font 11px, padding 1px 6px, font-weight 600, border-radius 10px (pill).
```

---

## Screen Prompts

### 01: Login Page

```
Design a full-screen login page for the VoxGuard fraud detection platform.

LAYOUT:
- Full viewport height, centered vertically and horizontally.
- Background: linear-gradient(135deg, #154360 0%, #1B4F72 50%, #2E86AB 100%).
- Single white Card centered, max-width 400px, border-radius 12px, no border,
  box-shadow: 0 8px 32px rgba(0,0,0,0.2). Padding: 24px.

LOGO & BRANDING (centered, margin-bottom 32px):
- SafetyCertificateOutlined icon, 48px, color #1B4F72.
- Below icon: "VoxGuard" as level-3 heading, color #1B4F72, margin 0.
- Below heading: "Voice Network Fraud Detection" in 14px secondary text.

ERROR ALERT:
- Ant Design Alert, type "error", showIcon, closable.
- Appears above form when login fails. Message: "Invalid email or password".
- Margin-bottom 24px. Hidden by default.

LOGIN FORM (vertical layout, size "large", no required marks):
- Email field: Input with UserOutlined prefix (#6C757D), placeholder "Email address",
  autoComplete="email". Validation: required + email format.
- Password field: Input.Password with LockOutlined prefix (#6C757D),
  placeholder "Password", autoComplete="current-password". Validation: required.
- Submit button: "Sign In", type="primary", block, height 44px,
  backgroundColor #1B4F72. Loading state shows spinner + "Signing In...".
  Disabled state: opacity 0.5, cursor not-allowed.
- Below button: "Forgot password?" link, centered, color #2E86AB.

DEMO ACCOUNTS SECTION:
- Divider with centered text: "Demo Accounts" (12px secondary).
- 3 full-width buttons stacked with 8px gap:
  - "Login as Admin" — default style
  - "Login as Analyst" — default style
  - "Login as Viewer" — default style
  All disabled during loading.

FOOTER:
- Centered, margin-top 24px: "VoxGuard (c) 2026 | Nigerian ICL Compliance" (11px secondary).

BUTTON STATES:
- Default: #1B4F72 bg, white text, subtle shadow.
- Hover: darken to #154360.
- Active: darken to #0D2F44.
- Loading: spinner icon replaces text, bg unchanged.
- Disabled: opacity 0.5.

DARK MODE: Not applicable (login always uses gradient background).
MOBILE (<768px): Card becomes full-width with 16px margin, border-radius 8px.
ACCESSIBILITY: Form has aria-label="Login form". Inputs have aria-required="true".
  Tab order: email -> password -> submit -> forgot link -> demo buttons.
  Focus ring: 2px solid #2E86AB.
i18n: All text uses t() function keys: login.title, login.email, login.password,
  login.signIn, login.forgotPassword, login.demoAccounts, login.asAdmin, etc.
```

### 02: Dashboard

```
Design the main dashboard page for VoxGuard fraud detection platform.

LAYOUT:
- Standard authenticated layout: Sidebar (left) + Header (top) + Content area.
- Content padding: 24px. Class: "acm-fade-in" for entry animation.

PAGE HEADER:
- Title: "Dashboard" — level-3 heading, 24px bold, margin-bottom 4px.
- Subtitle: "Real-time monitoring of call masking detection" — 14px secondary.

STAT CARDS ROW (Row with 16px gutter, margin-bottom 24px):
4 cards in responsive grid: xs=24, sm=12, lg=6.
Each card: class "acm-stats-card", bordered=false, Ant Design Statistic component.

  Card 1 — "New Alerts":
    Value: dynamic count (e.g., "23"), color #17A2B8.
    Prefix icon: AlertOutlined, color #17A2B8.
    Loading skeleton when data pending.

  Card 2 — "Critical Alerts":
    Value: dynamic count (e.g., "5"), color #DC3545.
    Prefix icon: ExclamationCircleOutlined, color #DC3545.
    Suffix: pulsing Badge (status="processing") when count > 0.

  Card 3 — "Investigating":
    Value: dynamic count (e.g., "12"), color #FFC107.
    Prefix icon: ClockCircleOutlined, color #FFC107.

  Card 4 — "Confirmed":
    Value: dynamic count (e.g., "8"), color #DC3545.
    Prefix icon: CheckCircleOutlined, color #DC3545.

QUICK ACCESS BAR (Card, size "small", bordered=false, margin-bottom 24px, padding 12px 16px):
- Label: AppstoreOutlined + "Quick Access:" (12px secondary).
- Row of small buttons with colored borders:
  - Grafana (LineChartOutlined, #1B4F72 border)
  - Prometheus (ExclamationCircleOutlined, #FFC107 border)
  - QuestDB (DatabaseOutlined, #28A745 border)
  - ClickHouse (DatabaseOutlined, #17A2B8 border)
  - YugabyteDB (DatabaseOutlined, #FFC107 border)
  - Homer SIP (PhoneOutlined, #E67E22 border)
  Each button: size "small", icon + label + ExportOutlined (10px). Opens new tab.
  Tooltip on hover: "Open {name} in new tab".

CHARTS ROW (Row with 16px gutter, margin-bottom 24px):
  Left (xs=24, lg=16):
    Card title: "Alert Trends (24h)", bordered=false.
    Extra: 3 color badges — Critical (#DC3545), High (#E67E22), Medium (#FFC107).
    Content: Area chart (ApexCharts) showing alert volume over 24 hours.
    Three stacked area series by severity. X-axis: hourly timestamps. Y-axis: count.
    Smooth curves, 50% opacity fills.

  Right (xs=24, lg=8):
    Card title: "Alerts by Severity", bordered=false.
    Content: Donut/Pie chart showing distribution:
    - Critical: #DC3545
    - High: #E67E22
    - Medium: #FFC107
    - Low: #17A2B8
    Center text: total count. Legend below chart.

BOTTOM ROW (Row with 16px gutter):
  Left (xs=24, lg=12):
    Card title: "Traffic Overview", bordered=false.
    Content: Stacked area chart showing total calls, flagged calls, blocked calls over time.
    Colors: #1B4F72 (total), #E67E22 (flagged), #DC3545 (blocked).
    X-axis: hourly. Y-axis: call count.

  Right (xs=24, lg=12):
    Card title: "Recent Alerts", bordered=false.
    Extra: "View All ->" link (12px secondary) navigating to /alerts.
    Content: Compact table, no pagination, size "small", scroll-x enabled.
    Columns:
    - Time: relative time "2 min ago" (12px secondary), tooltip shows full datetime
    - B-Number: bold text, clickable link to /alerts/show/:id
    - Severity: colored Tag (CRITICAL=red bg, HIGH=orange bg, MEDIUM=yellow bg, LOW=teal bg)
    - Status: colored Tag (NEW=teal, INVESTIGATING=amber, CONFIRMED=red, RESOLVED=green)
    - Score: percentage text, color-coded (>=80 red, >=60 orange, else yellow), font-weight 600
    Max 10 rows. Loading spinner when fetching. Rows poll every 10 seconds.
    Critical rows get class "ant-table-row-critical" with subtle red left border.

DARK MODE: All cards use #1F1F1F surface. Chart backgrounds transparent.
  Chart grid lines: #303030. Text: #FFFFFF / #A0A0A0.
MOBILE: All columns stack to single column (xs=24). Quick access bar wraps.
ACCESSIBILITY: Charts have aria-label descriptions. Table has role="grid".
i18n: All labels use t() function.
```

### 03: Alerts List

```
Design a filterable alerts table page for VoxGuard.

LAYOUT:
- Authenticated layout with sidebar + header. Content area with 24px padding.
- Uses Refine <List> component wrapper with custom header buttons.

PAGE HEADER:
- Title: "Alert Management" — provided by Refine List component.
- Header buttons: "Refresh" button (ReloadOutlined icon) + default Refine buttons.

STATS ROW (Row, 16px gutter, margin-bottom 16px):
  2 small stat cards in xs=12, sm=6 grid:
  - "New Alerts": count with AlertOutlined (#17A2B8), fontSize 20.
  - "Critical": count with ExclamationCircleOutlined (#DC3545),
    value turns red when count > 0.

ALERTS TABLE (Ant Design Table, size "middle", scroll-x 1200px):
  Columns:
  1. Time (width 160px, sortable):
     Formatted "MMM DD, HH:mm". Tooltip shows full "YYYY-MM-DD HH:mm:ss".
     Font: 12px.

  2. B-Number (filterable):
     FilterDropdown with Input (SearchOutlined prefix, width 200px).
     Text: bold, copyable (clipboard icon on hover).

  3. A-Number:
     Text: copyable, normal weight.

  4. Severity (width 100px, filterable):
     FilterDropdown with Select (mode="multiple", options: Critical/High/Medium/Low).
     Renders as Tag with severity colors (no border, bold text):
     - CRITICAL: bg #DC3545, text white
     - HIGH: bg #E67E22, text white
     - MEDIUM: bg #FFC107, text black
     - LOW: bg #17A2B8, text white

  5. Status (width 130px, filterable):
     FilterDropdown with Select (mode="multiple",
       options: New/Investigating/Confirmed/Resolved/False Positive).
     Renders as Tag with status colors (no border):
     - NEW: bg #17A2B8, text white
     - INVESTIGATING: bg #FFC107, text white
     - CONFIRMED: bg #DC3545, text white
     - RESOLVED: bg #28A745, text white
     - FALSE_POSITIVE: bg #6C757D, text white

  6. Score (width 80px, sortable):
     Percentage text, bold, color-coded:
     >=80: #DC3545, >=60: #E67E22, else: #FFC107.

  7. Detection (width 140px):
     Detection type text (12px secondary), underscores replaced with spaces.

  8. Carrier (width 120px, ellipsis on overflow).

  9. Actions (width 100px, fixed right):
     Space with ShowButton (eye icon, hideText) + EditButton (edit icon, hideText).
     Both size="small".

TABLE FEATURES:
- Default sort: created_at DESC.
- Default filter: status NOT IN [RESOLVED, FALSE_POSITIVE].
- Pagination: 20 per page, Ant Design pagination with page size changer.
- Live mode: "auto" — real-time updates via subscription.
- Sync with URL location (filters appear in query string).
- Critical rows: class "ant-table-row-critical" with subtle left red border.
- Bulk actions row (future): checkbox column, bulk resolve/assign dropdown.

LOADING: Table shows Ant Design loading spinner overlay.
EMPTY: "No alerts found" with shield icon and "Clear Filters" button.
DARK MODE: Table header bg #1D1D1D, row hover #2A2A2A, text white.
MOBILE: Horizontal scroll enabled. Columns collapse to essential (Time, B-Number, Severity, Actions).
ACCESSIBILITY: Table has aria-label="Alerts table". Sort buttons have aria-sort.
  FilterDropdown has aria-expanded. Actions have aria-label="View alert" / "Edit alert".
i18n: All column headers and filter labels use t().
```

### 04: Alert Detail / Show

```
Design an alert detail page showing full investigation information.

LAYOUT:
- Authenticated layout. Wrapped in Refine <Show> component.
- Two-column layout: main content (xs=24, lg=16) + sidebar (xs=24, lg=8).
- Gutter: 24px both directions.

HEADER:
- Refine Show header with custom button: "Update Status" (primary, EditOutlined icon).

LOADING STATE:
- Centered Spin size="large" with 48px padding.

ERROR STATE:
- Ant Design Alert type="error", message "Error", description "Failed to load alert details".

MAIN CONTENT COLUMN (left):
  Card, bordered=false.

  BADGE ROW (Space, margin-bottom 24px):
  - Severity Tag: large (14px, padding 4px 12px), severity colors, no border.
  - Status Tag: large (14px, padding 4px 12px), status colors, no border.
  - "Threat Score:" label (secondary) + score value (18px bold, color-coded).

  DESCRIPTIONS (Ant Design Descriptions, bordered, columns: xs=1, sm=2):
  - B-Number (Destination): 16px bold, copyable
  - A-Number (Source): copyable
  - Detection Type: underscores replaced with spaces
  - Route Type: or "Unknown"
  - CLI Status: or "Unknown"
  - Carrier: or "Unknown"
  - Created: formatted "YYYY-MM-DD HH:mm:ss"
  - Last Updated: formatted "YYYY-MM-DD HH:mm:ss"

  NOTES SECTION (conditional, shown if notes exist):
  - Divider with left-aligned label: "Notes"
  - Paragraph with pre-wrap whitespace preservation.

SIDEBAR COLUMN (right):
  Card 1 — "Activity Timeline" (bordered=false):
  - Ant Design Timeline component.
  - Each item has colored dot icon:
    - STATUS_CHANGED: ClockCircleOutlined (#FFC107)
    - ASSIGNED: UserOutlined (#17A2B8)
    - RESOLVED: CheckCircleOutlined (#28A745)
    - NOTE_ADDED: EditOutlined (#1B4F72)
  - Content: action name (12px bold, underscores to spaces),
    "by {user_name}" (11px secondary),
    old_value -> new_value transition (11px),
    timestamp (10px secondary, "MMM DD, HH:mm").
  - Empty state: "No activity recorded" (secondary text).

  Card 2 — "Quick Actions" (bordered=false, margin-top 16px):
  - Vertical Space, full width.
  - "Mark as Resolved" button: primary, block, CheckCircleOutlined,
    bg #28A745. Hidden when status is RESOLVED.
  - "Mark as False Positive" button: default, block, CloseCircleOutlined.
    Hidden when status is FALSE_POSITIVE.
  Both navigate to /alerts/edit/:id.

  Card 3 — "External Analysis Tools" (margin-top 16px):
  - List of contextual deep links:
    - "View Carrier Metrics" -> Grafana (LineChartOutlined)
    - "View Alert Metrics" -> Prometheus (FireOutlined)
    - "Query Call History" -> QuestDB (FieldTimeOutlined)
    - "View SIP Traces" -> Homer (PhoneOutlined)
    - "Historical Analysis" -> ClickHouse (TableOutlined)
    - "View Raw Data" -> Hasura (ApiOutlined)
  Each link: icon + label + description + ExportOutlined. Opens new tab.

DARK MODE: Cards use #1F1F1F. Timeline dots maintain their colors.
MOBILE: Two columns stack vertically. Sidebar cards appear below main content.
ACCESSIBILITY: Descriptions table has scope attributes. Timeline has role="list".
  Buttons have descriptive aria-labels.
i18n: All labels use t().
```

### 05: Alert Edit

```
Design an alert edit page for updating status, assignment, and notes.

LAYOUT:
- Authenticated layout. Wrapped in Refine <Edit> component with save button.
- Two-column layout: info sidebar (xs=24, lg=8) + edit form (xs=24, lg=16).
- Gutter: 24px.

LEFT COLUMN — "Alert Information" Card (read-only):
  Vertical stack of info fields:
  - Severity: Tag with severity colors, margin-top 4px.
  - Divider (12px vertical margin).
  - B-Number: bold text.
  - A-Number: normal text.
  - Divider.
  - Threat Score: 18px bold, color-coded (>=80 red, >=60 orange, else yellow).
  - Detection Type: underscores replaced with spaces.
  - Carrier: or "Unknown".
  - Divider.
  - Created: "YYYY-MM-DD HH:mm:ss" (12px).
  Each field: label (secondary text) above value.

RIGHT COLUMN — "Update Alert" Card:
  Form (Refine useForm, vertical layout):

  Field 1 — Status (required):
    Select, size "large", placeholder "Select status".
    Options:
    - New (value: NEW)
    - Investigating (value: INVESTIGATING)
    - Confirmed (value: CONFIRMED)
    - Resolved (value: RESOLVED)
    - False Positive (value: FALSE_POSITIVE)

  Field 2 — Assigned To:
    Select with async user search (useSelect from Refine).
    Filters: is_active=true, role IN [admin, analyst].
    allowClear, size "large", placeholder "Select analyst to assign".

  Field 3 — Notes:
    TextArea, 6 rows, showCount, maxLength 2000.
    Placeholder: "Enter investigation notes, findings, or actions taken..."
    Extra text: "Add any relevant notes or findings about this alert".

  STATUS GUIDE (below form):
  - Divider with left-aligned label: "Status Guide".
  - Vertical list:
    - [blue Tag] NEW — Alert just detected, awaiting review
    - [orange Tag] INVESTIGATING — Under active investigation
    - [red Tag] CONFIRMED — Verified as call masking attempt
    - [green Tag] RESOLVED — Action taken, issue resolved
    - [default Tag] FALSE POSITIVE — Not a real threat

SAVE BUTTON: Refine default, redirects to show page on success.

DARK MODE: Cards #1F1F1F, form inputs have #303030 borders.
MOBILE: Columns stack. Info card appears above form.
ACCESSIBILITY: Form fields have aria-required. Select has aria-expanded.
  Status guide items have role="listitem".
i18n: All labels use t(). Status options translated.
```

### 06: Gateways List

```
Design a gateway management table page for VoxGuard.

LAYOUT:
- Authenticated layout. Refine <List> wrapper.

PAGE HEADER:
- Title: "Gateways" with "Create" button (primary, PlusOutlined).

TABLE (Ant Design Table, size "middle"):
  Columns:
  1. Name: bold text, clickable link to gateway detail.
  2. IP Address: monospace font (JetBrains Mono), copyable.
  3. Carrier: carrier name.
  4. Protocol: Tag — SIP (blue), H.323 (purple), SS7 (orange).
  5. Status: Tag with dot indicator:
     - ACTIVE: green dot + green Tag "ACTIVE"
     - INACTIVE: gray dot + default Tag "INACTIVE"
     - MAINTENANCE: amber dot + warning Tag "MAINTENANCE"
     - ERROR: red dot + red Tag "ERROR"
  6. Health: Progress bar (0-100%), color: green >=80, yellow >=50, red <50.
  7. Call Volume: Mini sparkline chart (60px wide) showing last 24h volume trend.
     Inline SVG or tiny area chart.
  8. Last Seen: relative time ("5 min ago"), tooltip with full timestamp.
  9. Actions: ShowButton + EditButton (hideText, size small).

TABLE FEATURES:
- Sortable by: Name, Status, Call Volume, Last Seen.
- Pagination: 20 per page with size changer.
- Row hover highlights.

LOADING: Skeleton table rows.
EMPTY: ApiOutlined icon + "No gateways configured" + "Add Gateway" button.
DARK MODE: Standard dark table treatment.
MOBILE: Horizontal scroll. Essential columns: Name, Status, Actions.
ACCESSIBILITY: Table has caption. Status indicators have aria-label.
i18n: All labels use t().
```

### 07: Gateway Detail

```
Design a gateway detail page with connection info and performance metrics.

LAYOUT:
- Authenticated layout. Refine <Show> wrapper.
- Two-column: main (xs=24, lg=16) + sidebar (xs=24, lg=8).

MAIN COLUMN:
  Card 1 — "Connection Information" (Descriptions, bordered, 2 columns):
  - Gateway Name, IP Address (monospace, copyable), Port, Protocol,
    Carrier, Region, Status (colored Tag), Created, Last Modified.

  Card 2 — "Performance Metrics" (margin-top 16px):
  - Row of 4 mini stat cards:
    - Total Calls (24h): number with PhoneOutlined
    - ASR (Answer-Seizure Ratio): percentage with green/red indicator
    - ACD (Average Call Duration): seconds with clock icon
    - Active Channels: number with capacity indicator
  - Below: Line chart showing call volume and ASR trend over 24 hours.

  Card 3 — "Call Statistics" (margin-top 16px):
  - Bar chart: calls by hour, grouped by direction (inbound/outbound).
  - Colors: inbound #1B4F72, outbound #17A2B8.

SIDEBAR:
  Card 1 — "Status & Health":
  - Large status badge. Health percentage with circular progress.
  - Uptime: "99.97%". Last heartbeat: relative time.

  Card 2 — "Blacklist Status":
  - Shows if gateway IP or routes appear on any blacklists.
  - List of matched blacklist entries (if any) with Tag indicators.
  - "Clean" badge (green) if no matches.

  Card 3 — "Quick Actions":
  - "Edit Gateway" button (primary).
  - "Disable Gateway" button (danger, warning modal confirmation).
  - "View CDRs" button navigates to CDR Browser pre-filtered.

DARK MODE: Standard dark card treatment.
MOBILE: Columns stack vertically.
ACCESSIBILITY: Descriptions table scoped headers. Charts have alt text.
i18n: All labels use t().
```

### 08: Gateway Create / Edit

```
Design a gateway form page for creating and editing gateways.

LAYOUT:
- Authenticated layout. Refine <Create> or <Edit> wrapper.
- Single centered card, max-width 720px.

FORM (vertical layout):
  Section 1 — "Basic Information":
  - Gateway Name: Input, required. Placeholder "e.g., GW-MTN-01".
  - Carrier: Select dropdown with carrier options (MTN Nigeria, Airtel Nigeria,
    Glo Mobile, 9mobile, Ntel, International Transit).
  - Description: TextArea, 3 rows.

  Section 2 — "Connection Details":
  - IP Address: Input with IP validation, monospace font.
    Placeholder "e.g., 10.0.1.100". Required.
  - Port: InputNumber, default 5060. Range 1-65535.
  - Protocol: Select — SIP, H.323, SS7. Required.
  - Region: Select — Lagos, Abuja, Port Harcourt, Kano, International.

  Section 3 — "Thresholds & Limits":
  - Max Concurrent Calls: InputNumber, default 100.
  - CPM Warning Threshold: InputNumber (Calls Per Minute), default 35.
  - CPM Critical Threshold: InputNumber, default 50.
  - ASR Warning Threshold: InputNumber (percentage), default 30.
  - Blacklist Auto-Block: Switch toggle.

  Section 4 — "Status":
  - Status: Radio group — Active, Inactive, Maintenance.

BUTTONS:
- "Save" (primary) + "Cancel" (default, navigates back).
- Save has loading state.

VALIDATION: Real-time validation with error messages below fields.
  IP format: regex validated. Port: number range. Thresholds: min/max limits.

DARK MODE: Form fields have #303030 borders, #1F1F1F background.
MOBILE: Full width form. Sections stack vertically.
ACCESSIBILITY: All inputs have labels. Required fields marked with aria-required.
  Error messages linked via aria-describedby.
i18n: All labels and validation messages use t().
```

### 09: Users List

```
Design a user management table page.

LAYOUT:
- Authenticated layout. Refine <List> wrapper.

PAGE HEADER:
- Title: "Users" with "Create User" button (primary, PlusOutlined).

TABLE (size "middle"):
  Columns:
  1. Avatar + Name: 32px Avatar (initials or photo) + bold name text.
  2. Email: text, copyable.
  3. Role: Tag with color:
     - admin: red Tag "ADMIN"
     - analyst: blue Tag "ANALYST"
     - viewer: default Tag "VIEWER"
     - operator: green Tag "OPERATOR"
  4. Status: Badge dot + text:
     - active: green dot "Active"
     - inactive: gray dot "Inactive"
     - locked: red dot "Locked"
  5. Last Login: relative time, tooltip full datetime. "Never" if null.
  6. Created: date format "MMM DD, YYYY".
  7. Actions: ShowButton + EditButton (hideText, size small).

TABLE FEATURES:
- Filterable by role (Select multi), status (Select multi).
- Searchable by name/email (Input with SearchOutlined).
- Sortable by Name, Role, Last Login, Created.
- Pagination: 20 per page.

DARK MODE: Standard dark table.
MOBILE: Horizontal scroll. Essential columns: Name, Role, Status, Actions.
ACCESSIBILITY: Avatar has alt text. Table has caption.
i18n: All labels use t().
```

### 10: User Detail

```
Design a user detail/profile page.

LAYOUT:
- Two-column: profile (xs=24, lg=8) + content (xs=24, lg=16).

LEFT — Profile Card:
- Large Avatar (80px), centered.
- Name (20px bold), email (14px secondary), role Tag.
- Status Badge (active/inactive/locked).
- "Edit User" button (primary, block).
- Divider.
- Quick stats: Total Alerts Handled, Cases Assigned, Last Active.

RIGHT:
  Tab bar: Activity | Permissions | Linked Cases

  Activity Tab:
  - Timeline of recent actions (last 30 days):
    Each: action icon + description + timestamp.
    Actions: login, status change, case update, alert review, settings change.

  Permissions Tab:
  - Grouped checkbox list showing effective permissions:
    - Alerts: View, Edit, Delete, Assign
    - Gateways: View, Create, Edit, Delete
    - Cases: View, Create, Edit, Escalate
    - Reports: View, Generate, Export
    - Settings: View, Modify
    - ML Models: View, Retrain (AIDD T2 badge)
    - Users: View, Create, Edit, Delete (AIDD T2 badge)
  Read-only view (checkmarks for granted permissions).

  Linked Cases Tab:
  - Small table: Case ID, Title, Status Tag, Role (Lead/Contributor), Date.

DARK MODE: Standard treatment.
MOBILE: Columns stack. Profile card on top.
ACCESSIBILITY: Tabs have aria-selected. Permissions list has role="list".
i18n: All labels use t().
```

### 11: User Create / Edit

```
Design a user form page for creating and editing users.

LAYOUT:
- Authenticated layout. Refine <Create> or <Edit> wrapper.
- Single centered card, max-width 640px.

FORM (vertical layout):
  Section 1 — "User Information":
  - Name: Input, required.
  - Email: Input with email validation, required.
  - Password: Input.Password (create only, hidden on edit).
    Strength indicator bar below.

  Section 2 — "Role & Access":
  - Role: Select dropdown (required):
    - Admin — full access (description text below)
    - Analyst — investigate and manage alerts/cases
    - Operator — monitor and acknowledge
    - Viewer — read-only access
  - AIDD T2 badge next to Role selector (admin/user management requires T2).

  Section 3 — "Permissions" (shown when role != admin):
  - Grouped checkboxes:
    - Alerts: [x] View, [x] Edit, [ ] Delete, [x] Assign
    - Cases: [x] View, [x] Create, [x] Edit, [ ] Escalate
    - Gateways: [x] View, [ ] Create, [ ] Edit, [ ] Delete
    - Reports: [x] View, [x] Generate, [ ] Export
    - Settings: [x] View, [ ] Modify
  Auto-populated based on role selection but manually overridable.

  Section 4 — "Status":
  - Status: Radio group — Active, Inactive.
  - Account Locked: Switch (edit only).

BUTTONS: "Save" (primary) + "Cancel". Loading state on save.

DARK MODE: Standard form treatment.
MOBILE: Full-width form.
ACCESSIBILITY: All fields labeled. Checkboxes in fieldsets with legends.
i18n: All labels use t().
```

### 12: Analytics

```
Design a multi-chart analytics dashboard page.

LAYOUT:
- Authenticated layout. Full-width content.

PAGE HEADER:
- Title: "Analytics" — 24px bold.
- Subtitle: "Fraud detection performance metrics and trends" — 14px secondary.
- Header controls (right-aligned):
  - Date Range Picker (RangePicker).
  - Metric Selector: Select dropdown with options:
    Alert Volume, Threat Score Distribution, Detection Rate,
    False Positive Rate, Revenue Impact, Call Volume.
  - Refresh button.

CHART GRID (2x2 on desktop, single column on mobile):
  Top-left: Line Chart — "Alert Trend"
  - Multiple lines: Critical (red), High (orange), Medium (yellow), Low (teal).
  - X-axis: dates. Y-axis: count. Tooltip on hover with exact values.
  - Smooth curves, 2px stroke width.

  Top-right: Bar Chart — "Alerts by Detection Type"
  - Vertical bars grouped by type: CLI Spoofing (#722ED1), Wangiri (#E67E22),
    IRSF (#DC3545), SIM Box (#17A2B8), Traffic Anomaly (#6C757D).
  - X-axis: type. Y-axis: count.

  Bottom-left: Area Chart — "Call Traffic Volume"
  - Stacked areas: Total (#1B4F72), Flagged (#E67E22), Blocked (#DC3545).
  - X-axis: hourly/daily based on date range. Y-axis: call count.
  - 40% opacity fills.

  Bottom-right: Pie Chart — "Resolution Distribution"
  - Slices: Resolved (#28A745), Investigating (#FFC107),
    Confirmed (#DC3545), False Positive (#6C757D).
  - Donut style with center showing total. Legend to the right.

Each chart: Card wrapper, bordered=false, title in card header.
ApexCharts or Recharts library.

DARK MODE: Chart backgrounds transparent. Grid lines #303030. Labels white.
MOBILE: Charts stack in single column, full width.
ACCESSIBILITY: Each chart has aria-label with description. Data table fallback for screen readers.
i18n: All labels use t().
```

### 13: Settings

```
Design a settings page with 5 tabs.

LAYOUT:
- Authenticated layout. Ant Design Tabs component at top.
- Content within each tab scrolls independently.

TAB 1 — "Detection" (SafetyCertificateOutlined icon):
  Card: "Detection Thresholds"
  Form fields:
  - CPM Warning Threshold: InputNumber (default 35) + Slider (0-100).
  - CPM Critical Threshold: InputNumber (default 50) + Slider (0-100).
  - Threat Score Block Threshold: InputNumber (default 80) + Slider (0-100).
  - Minimum Call Duration (sec): InputNumber (default 3).
  - Short Call Threshold (sec): InputNumber (default 5).
  - Wangiri Ring Duration Max (sec): InputNumber (default 4).
  Each field has helper text explaining the threshold.
  "Save Thresholds" button (primary). AIDD T1 badge next to save.
  "Reset to Defaults" button (default).

TAB 2 — "Notifications" (BellOutlined icon):
  Card: "Notification Channels"
  - Email Notifications: Switch (on/off) + email input for recipients (Tags mode).
  - Slack Integration: Switch + webhook URL input + "Test Connection" button.
  - Browser Push: Switch + permission request button.
  - SMS Alerts: Switch + phone number input (critical only).

  Card: "Notification Rules"
  - Table: Event Type | Channels | Severity Filter | Status
  - Events: New Alert, Status Change, Threshold Breach, System Error, Report Ready.
  - Each row has checkboxes for Email/Slack/Browser/SMS + severity multi-select.

TAB 3 — "API & Integration" (ApiOutlined icon):
  Card: "API Keys"
  - Table: Key Name, Key (masked ****), Created, Last Used, Status, Revoke button.
  - "Generate New Key" button (primary). AIDD T2 badge.

  Card: "Webhooks"
  - Table: URL, Events, Status (active/inactive toggle), Last Triggered, Delete.
  - "Add Webhook" button.

  Card: "External Services Health"
  - Grid of service cards (from EXTERNAL_SERVICES config):
    Each: icon, name, URL, status indicator (green/red dot), latency,
    "Open" button. Categories: Monitoring, Databases, Analytics, SIP, Admin.

TAB 4 — "Language & Region" (GlobalOutlined icon):
  Card: "Language"
  - Language dropdown with 10 languages:
    English, Francais, Portugues, Hausa, Yoruba, Igbo,
    العربية (Arabic with RTL note), Espanol, 中文, Kiswahili.
  - Note: "Changing language updates all UI text via react-i18next."

  Card: "Currency"
  - Currency selector with search (20 currencies):
    NGN, USD, EUR, GBP, GHS, KES, ZAR, XOF, XAF, EGP,
    TZS, UGX, CNY, SAR, AED, INR, BRL, CAD, AUD, JPY.
  - Preview: "Sample: {formatted amount}" showing selected currency formatting.

  Card: "Regional Settings"
  - Timezone: Select with search (Africa/Lagos default).
  - Date Format: Radio group — DD/MM/YYYY, MM/DD/YYYY, YYYY-MM-DD.
  - Number Format: Radio group — 1,234.56 | 1.234,56

TAB 5 — "External Portals" (AppstoreOutlined icon):
  Grid of service cards (2 columns on desktop):
  Each card shows:
  - Service icon (colored) + name (bold) + description (secondary).
  - URL (monospace, small).
  - Health indicator: green dot "Connected" or red dot "Unreachable"
    with last check timestamp.
  - "Open Portal" button (opens new tab).
  - Category badge (Monitoring/Database/Analytics/SIP/Admin).

  Services: Grafana, Prometheus, Hasura Console, YugabyteDB,
  ClickHouse, QuestDB Console, Homer SIP Capture.

"Save Settings" button at bottom of each tab. AIDD T1 badge on detection/notifications.

DARK MODE: Standard form/card treatment.
MOBILE: Tabs become vertical or scrollable horizontal.
ACCESSIBILITY: Tabs have aria-role="tablist". Form fields fully labeled.
i18n: All labels use t().
```

### 14: RVS Dashboard

```
Design a Real-time Verification Service (RVS) dashboard page.

LAYOUT:
- Authenticated layout, full content area. Class: "acm-fade-in".

PAGE HEADER:
- Title: "RVS Dashboard" — 24px bold.
- Subtitle: "Real-time Verification Service monitoring" — 14px secondary.
- Tabs: Overview | Verifications | Configuration.

TOP METRIC CARDS (Row, 4 cards, xs=24 sm=12 lg=6):
  1. RVS Status: green Tag "CONNECTED" (or red "DISCONNECTED").
  2. Latency: "23ms" with trend arrow.
  3. Uptime: "99.97%" with green text.
  4. Circuit Breaker: Tag "CLOSED" (green) or "OPEN" (red) or "HALF-OPEN" (amber).

OVERVIEW TAB:
  Row 1 (16px gutter):
  - Left (lg=16): Area Chart — "Verification Trend (30 Days)"
    Two series: Verifications (blue #1B4F72 area) + Blocked (red #DC3545 area).
    X-axis: daily. Y-axis: count. Smooth curves, 40% opacity fill.

  - Right (lg=8): Donut Chart — "HLR Distribution"
    Segments: Valid (green #28A745), Invalid (red #DC3545),
    Unknown (gray #6C757D), Ported (yellow #FFC107).
    Center: total count. Legend below.

  Row 2: Table — "Recent Verifications"
  Columns: ID, Calling #, Called #, RVS Score (color-coded badge 0-100),
  HLR Status (Valid/Invalid/Unknown/Ported tags), Network, Country,
  Response Time (ms), Cached (Yes/No tag), Timestamp.
  Pagination: 10 per page.

CONFIGURATION TAB:
  Card 1 — "Feature Flags":
  - List of feature toggles, each row:
    - Feature name + description
    - Toggle Switch (on/off)
    - Phase indicator chip: Shadow (blue), Composite (amber), Active (green)
  - Features: RVS Verification, HLR Lookup, Number Portability Check,
    ML Fraud Scoring, Composite Decision Engine.

  Card 2 — "ML Model Status" (3 model cards in row):
  Each card: Model name, version Tag, accuracy percentage,
  status badge (active green / shadow blue / retired gray), features count.

  Card 3 — "Detection Engine Health":
  4 inline metrics: P99 Latency (ms), Calls/sec, Cache Hit Rate (%),
  Uptime (%). Each with trend indicator.

DARK MODE: Standard. Chart backgrounds transparent.
MOBILE: Charts stack. Table scrolls horizontally.
ACCESSIBILITY: Charts have aria-labels. Toggles have aria-checked.
i18n: All text uses t().
```

### 15: Composite Scoring

```
Design a composite fraud scoring analytics page.

LAYOUT:
- Authenticated layout. Class: "acm-fade-in".

PAGE HEADER:
- Title: "Composite Scoring" — 24px bold.
- Subtitle: "Multi-factor fraud score analysis" — 14px secondary.

SUMMARY STATS ROW (4 cards, responsive):
  1. Total Decisions: count, number format.
  2. Average Score: number (e.g., "67.3"), color-coded.
  3. Block Rate: percentage (e.g., "12.4%"), red text.
  4. Average Latency: milliseconds (e.g., "45ms").

SCORE DISTRIBUTION CHART:
  Card: "Score Distribution"
  Histogram chart: X-axis 0-100 score bins (10-point buckets).
  Y-axis: count. Bar colors gradient from green (low) through yellow to red (high).
  Vertical reference lines at thresholds (50=review, 80=block).

DECISIONS TABLE:
  Card: "Recent Decisions"
  Columns:
  1. Call ID: monospace text.
  2. VoxGuard Score: number, color-coded.
  3. RVS Score: number, color-coded.
  4. Composite Score: large bold number 0-100, background gradient
     (green 0-50, yellow 50-80, red 80-100).
  5. Decision: Tag:
     - Allow: green Tag, CheckCircleOutlined
     - Block: red Tag, StopOutlined
     - Review: yellow Tag, WarningOutlined
  6. Latency: milliseconds.
  7. Contributing Factors: row of small chips, each showing
     factor name + contribution percentage.
     e.g., [CLI Mismatch 35%] [Short Duration 25%] [Known Pattern 20%] [New Route 20%].
     Chips colored by contribution weight.

TABLE FEATURES: Sortable by Composite Score, Decision, Latency.
  Pagination: 20 per page.

DARK MODE: Standard. Histogram uses darker grid.
MOBILE: Chart full width. Table scrolls horizontally.
ACCESSIBILITY: Histogram has aria-label. Factor chips have title attributes.
i18n: All text uses t().
```

### 16: Lists Management

```
Design a blacklist/whitelist management page.

LAYOUT:
- Authenticated layout. Class: "acm-fade-in".

PAGE HEADER:
- Title: "Lists Management" — 24px bold.

SYNC STATUS BAR (top, full width):
  Horizontal bar showing: last sync direction icon (arrows),
  "Last Sync: 5 min ago", entries pushed: 12, entries pulled: 8,
  errors: 0 (or red count if >0). SyncStatusBar component.
  Background: subtle info blue (#E6F7FF).

TAB BAR: Blacklist | Whitelist
  Active tab has #1B4F72 underline indicator.

TOOLBAR:
  - "Add Entry" button (primary, PlusOutlined) — opens modal.
  - "Import CSV" button (default, UploadOutlined).
  - Search Input (SearchOutlined prefix, width 250px).

ADD ENTRY MODAL:
  Modal with form:
  - Pattern: Input, placeholder "+23480*" or exact number. Required.
  - Pattern Type: Select dropdown:
    - Prefix (matches beginning)
    - Exact (exact match)
    - Regex (regular expression)
  - Reason: TextArea, 2 rows. Required.
  - Expires: DatePicker (optional, for temporary entries).
  Modal buttons: "Add" (primary) + "Cancel".

DATA TABLE:
  Columns:
  1. Pattern: monospace font (JetBrains Mono), bold.
  2. Type: Tag:
     - prefix: blue Tag "PREFIX"
     - exact: green Tag "EXACT"
     - regex: purple Tag "REGEX"
  3. Reason: text, ellipsis on overflow.
  4. Added By: username.
  5. Hit Count: number, bold if > 0.
  6. Expires: date or "Never" in secondary text.
  7. Source: Tag:
     - manual: default Tag "MANUAL"
     - auto: amber Tag "AUTO"
     - rvs_sync: blue Tag "RVS_SYNC"
  8. Actions: Delete button (danger, confirmation popconfirm).

Pagination: 20 per page with size changer.

DARK MODE: Standard dark table/modal.
MOBILE: Table scrolls horizontally.
ACCESSIBILITY: Modal has aria-modal. Table has caption.
i18n: All text uses t().
```

### 17: Multi-Call Detection

```
Design a multi-call fraud detection monitoring page.

LAYOUT:
- Authenticated layout. Class: "acm-fade-in".

PAGE HEADER:
- Title: "Multi-Call Detection" — 24px bold.

ALERT BANNER (conditional, shown when high-risk patterns detected):
  Ant Design Alert, type "error", showIcon (WarningOutlined),
  message: "Active High-Risk Patterns Detected",
  description: "3 patterns with risk score above 0.8 require immediate attention."
  Banner style, closable=false.

FILTER BAR:
  Horizontal row:
  - Status: Select dropdown — Active, Resolved, Monitoring. Default: Active.
  - Minimum Risk Score: Slider (0 to 1, step 0.1, default 0). Shows value label.
  - Time Window: Range slider (1-60 minutes).
  - Reset Filters button.

DATA TABLE:
  Columns:
  1. B-Number: monospace font (JetBrains Mono), bold.
  2. Call Count: number.
  3. Unique A-Numbers: number.
  4. Time Window: "X minutes".
  5. Risk Score: 0-1 decimal, displayed with color gradient background:
     0-0.3 green, 0.3-0.6 yellow, 0.6-0.8 orange, 0.8-1.0 red.
     Font: bold, white text on colored background pill.
  6. Status: Tag:
     - active: red Tag with pulse animation "ACTIVE"
     - resolved: green Tag "RESOLVED"
     - monitoring: blue Tag "MONITORING"
  7. Source IPs: expandable list or truncated with "+N more" indicator.
  8. Fraud Type: text.
  9. Actions:
     - "Block" button (red, small, StopOutlined). Confirmation popconfirm.
     - "Resolve" button (green, small, CheckCircleOutlined).

TABLE FEATURES: Sortable by Risk Score, Call Count, Time Window.
  Pagination: 20 per page.

DARK MODE: Standard. Risk score gradient maintained.
MOBILE: Table scrolls. Filter bar wraps vertically.
ACCESSIBILITY: Slider has aria-valuemin/max/now. Alert banner has role="alert".
i18n: All text uses t().
```

### 18: Revenue Fraud

```
Design a revenue fraud detection page with Wangiri and IRSF tabs.

LAYOUT:
- Authenticated layout. Class: "acm-fade-in".

PAGE HEADER:
- Title: "Revenue Fraud" — 24px bold.
- Subtitle: "Wangiri and IRSF fraud monitoring" — 14px secondary.

SUMMARY CARDS ROW (4 cards, responsive xs=24 sm=12 lg=6):
  1. Active Wangiri: count, PhoneOutlined icon, amber accent.
  2. Active IRSF: count, DollarOutlined icon, red accent.
  3. Total Revenue at Risk: currency-formatted amount (user's chosen currency),
     bold, red text. e.g., "NGN 2,450,000".
  4. Blocked Today: count, green accent, ShieldOutlined.

TAB BAR: Wangiri | IRSF

WANGIRI TAB:
  Table columns:
  1. Calling Number: monospace, with flag icon for country.
  2. Country: country name + small flag.
  3. Ring Duration: seconds (e.g., "2.3s"), red if < 3s.
  4. Callback Count: number.
  5. Revenue Risk: currency formatted (user's currency), red text for high values.
     Uses formatCurrency() from useLocale hook.
  6. Status: Tag — active (red), blocked (gray), monitoring (blue).
  7. Actions: "Block" button (red, small). Confirmation dialog:
     "Block number +234...? This will add it to the blacklist."

IRSF TAB:
  Table columns:
  1. Destination: phone number range, monospace.
  2. Country: with flag icon.
  3. Total Minutes: number, formatted.
  4. Total Cost: currency formatted (user's currency).
  5. Pump Pattern: Tag:
     - short_stop: amber Tag "SHORT STOP"
     - long_duration: red Tag "LONG DURATION"
     - sequential: purple Tag "SEQUENTIAL"
  6. Status: Tag — active (red), blocked (gray), monitoring (blue).
  7. Actions: "Block Route" button (red), "Investigate" button (blue).

Both tables: Pagination 20/page, sortable by Revenue Risk / Total Cost.

DARK MODE: Standard. Currency amounts maintain red color.
MOBILE: Tables scroll. Summary cards stack.
ACCESSIBILITY: Flag icons have alt text for country. Currency values have aria-label.
i18n: All text uses t(). Amounts formatted per locale.
```

### 19: Traffic Control

```
Design a traffic control rules management page.

LAYOUT:
- Authenticated layout. Class: "acm-fade-in".

PAGE HEADER:
- Title: "Traffic Control" — 24px bold.
- "Create Rule" button (primary, PlusOutlined) — opens modal.

RULES TABLE:
  Columns:
  1. Rule Name: bold text.
  2. Description: secondary text, ellipsis.
  3. Enabled: Toggle Switch (inline, immediate effect with confirmation).
     AIDD T1 badge next to critical rule toggles.
  4. Priority: number, sortable. Drag handle for reordering (future).
  5. Action: Tag:
     - allow: green Tag "ALLOW"
     - block: red Tag "BLOCK"
     - rate_limit: yellow Tag "RATE LIMIT"
     - alert: blue Tag "ALERT"
  6. Conditions: count number (e.g., "3 conditions").
     Expandable row shows condition cards.
  7. Hit Count: number, bold.
  8. Last Hit: relative time.
  9. Actions: Edit button + Delete button (danger, popconfirm).

EXPANDED ROW (condition detail):
  Cards showing conditions:
  Each condition: [Field] [Operator] [Value]
  e.g., [Country] [equals] [Sierra Leone]
  e.g., [Call Duration] [less than] [5 seconds]
  e.g., [CLI Pattern] [matches] [+23280*]

CREATE RULE MODAL (large modal, 640px width):
  Form:
  - Rule Name: Input, required.
  - Description: TextArea, 2 rows.
  - Action: Select — Allow, Block, Rate Limit, Alert.
  - Priority: InputNumber (1-100).
  - Conditions Builder:
    Dynamic form list. Each condition row:
    - Field: Select (Country, CLI Pattern, Call Duration, Source IP,
      Gateway, Carrier, Time of Day, Call Count).
    - Operator: Select (equals, not_equals, greater_than, less_than,
      matches, contains, in_list).
    - Value: Input (context-sensitive based on Field).
    - Remove button (MinusCircleOutlined).
    "Add Condition" button (PlusOutlined, dashed).

Modal buttons: "Create Rule" (primary) + "Cancel".

DARK MODE: Standard. Toggle switches maintain colors.
MOBILE: Table scrolls. Modal becomes full-screen drawer.
ACCESSIBILITY: Toggles have aria-checked. Condition builder has fieldset.
i18n: All text uses t().
```

### 20: False Positives

```
Design a false positive review page.

LAYOUT:
- Authenticated layout. Class: "acm-fade-in".

PAGE HEADER:
- Title: "False Positive Review" — 24px bold.
- Subtitle: "Review and classify detection accuracy" — 14px secondary.

BEHAVIORAL PROFILE CARD (shown when a row is selected/expanded):
  Card with header "Behavioral Profile":
  - Avg Daily Calls: number
  - Avg Call Duration: seconds
  - Typical Destinations: list of countries/ranges
  - Activity Hours: bar chart (24 hours, highlighting active periods)
  - Risk Trend: small sparkline (30 days) with trend arrow

DATA TABLE:
  Columns:
  1. Alert Type: Tag with fraud type color:
     - CLI Spoofing (#722ED1), Wangiri (#E67E22), IRSF (#DC3545),
       SIM Box (#17A2B8), Traffic Anomaly (#6C757D).
  2. Calling Number: monospace.
  3. Called Number: monospace.
  4. Original Score: number (0-100), color-coded.
  5. Confidence: 0-1 value shown as horizontal progress bar:
     - Bar fill: green (>0.8), yellow (0.5-0.8), red (<0.5).
     - Width proportional to confidence value.
     - Numeric value shown to the right.
  6. Detection Method: text.
  7. Matched Patterns: row of small chips (Tags):
     e.g., [CLI Mismatch] [Short Duration] [New Route].
     Max 3 shown, "+N more" expandable.
  8. Status: Tag:
     - pending: blue Tag "PENDING"
     - confirmed_fp: green Tag "CONFIRMED FP"
     - confirmed_tp: red Tag "CONFIRMED TP"
     - disputed: amber Tag "DISPUTED"
  9. Actions (Space):
     - "Confirm FP" button (green, CheckCircleOutlined, small).
     - "Confirm TP" button (red, CloseCircleOutlined, small).
     - "Dispute" button (amber, QuestionCircleOutlined, small).
     Each has popconfirm with reason input.

TABLE FEATURES: Filterable by Alert Type, Status, Confidence range.
  Sortable by Confidence, Original Score, Status.
  Pagination: 20 per page.

DARK MODE: Standard. Confidence bars maintain colors.
MOBILE: Table scrolls. Profile card appears as drawer.
ACCESSIBILITY: Progress bars have aria-valuenow. Action buttons have aria-label.
i18n: All text uses t().
```

### 21: NCC Compliance

```
Design an NCC (Nigerian Communications Commission) compliance page.

LAYOUT:
- Authenticated layout. Class: "acm-fade-in".

PAGE HEADER:
- Title: "NCC Compliance" — 24px bold.
- Subtitle: "Nigerian Communications Commission regulatory reporting" — 14px secondary.

TAB BAR: Reports | Disputes

REPORTS TAB:
  Table columns:
  1. Report ID: monospace text.
  2. Report Type: Tag — Monthly (blue), Quarterly (purple), Incident (red), Ad-Hoc (default).
  3. Period: date range text.
  4. Status: Tag:
     - draft: default "DRAFT"
     - ready: blue "READY"
     - submitted: green "SUBMITTED"
     - acknowledged: teal "ACKNOWLEDGED"
     - rejected: red "REJECTED"
  5. Created: formatted date.
  6. Submitted: formatted date or "--".
  7. Amount: currency formatted in user's chosen currency (fines/penalties).
  8. Actions:
     - "Submit to NCC" button (primary, small, SendOutlined).
       Only visible when status = "ready".
       AIDD T2 badge (regulatory submission requires admin approval).
     - "Download" button (default, small, DownloadOutlined).
     - "View" button (link, EyeOutlined).

DISPUTES TAB:
  Table columns:
  1. Dispute ID: text.
  2. Related Report: link to report.
  3. Filed By: operator name.
  4. Issue: text, ellipsis.
  5. Amount Disputed: currency formatted (user's currency).
  6. Status: Tag — open (blue), under_review (amber), resolved (green), escalated (red).
  7. Filed Date: formatted date.
  8. Actions:
     - "Escalate" button (danger, small, ExclamationCircleOutlined).
       AIDD T1 badge.
     - "View Details" button (link).

Both tables: Pagination 10/page, sortable by date and status.

DARK MODE: Standard.
MOBILE: Tables scroll. Tabs remain horizontal.
ACCESSIBILITY: Tables have captions. Submit buttons have aria-label with report ID.
i18n: All text uses t(). Amounts use formatCurrency() with user locale.
```

### 22: MNP Lookup

```
Design a Mobile Number Portability lookup page.

LAYOUT:
- Authenticated layout. Padding 24px.

PAGE HEADER:
- Title: "MNP Lookup" — 24px bold (level 3).
- Subtitle: "Mobile Number Portability database lookup and data import" — 14px secondary.

SEARCH & ACTIONS (Card header area):
  - Card title: "MNP Records ({count})" showing filtered count.
  - Card extra (right side):
    - Search Input: placeholder "Search MSISDN or network",
      SearchOutlined prefix, width 220px, allowClear.
    - "Import MNP Data" button (primary, UploadOutlined).
      AIDD T2 badge (compact) — data import requires admin approval.

RESULT TABLE:
  Columns:
  1. MSISDN: monospace font, e.g., "+2348012345678".
  2. Donor Network: e.g., "MTN Nigeria".
  3. Recipient Network: e.g., "Airtel Nigeria".
  4. Ported Date: formatted date.
  5. Status: Tag:
     - active: green Tag "ACTIVE"
     - pending: orange Tag "PENDING"
     - expired: default Tag "EXPIRED"

  Table: size "small", default pagination.

SEARCH RESULT CARD (shown when searching a single number, future enhancement):
  Card showing detailed lookup result:
  - Number: large monospace text.
  - Current Network: with operator logo/icon.
  - Portability Status: "Ported" (amber) or "Original" (green).
  - Carrier History: timeline showing port events with dates.
  - HLR Status: Valid/Invalid/Unknown.

DARK MODE: Standard card and table treatment.
MOBILE: Full-width card. Table scrolls.
ACCESSIBILITY: Search input has aria-label. Table has caption.
i18n: All labels should use t() but current implementation has hardcoded English.
```

### 23: Case Management List

```
Design a fraud case management list page.

LAYOUT:
- Authenticated layout. Class: "vg-page-wrapper acm-fade-in".

PAGE HEADER:
- Title: "Case Management" — 24px bold (using t('cases.title')).
- Subtitle: "Fraud investigation case tracking" (using t('cases.subtitle')).

FILTER BAR (class "vg-filter-bar", horizontal, wrapping):
  - Search Input: placeholder t('common.search'), SearchOutlined prefix, width 250px.
  - Status Select: placeholder t('common.status'), allowClear, width 150px.
    Options: Open, Investigating, Escalated, Resolved, Closed.
  - Severity Select: placeholder t('cases.severity'), allowClear, width 150px.
    Options: Critical, High, Medium, Low.
  - "Create Case" button (primary, PlusOutlined).

DATA TABLE (Card wrapper):
  Columns:
  1. Case ID: bold text (e.g., "CASE-2025-001").
  2. Title (Name): text, ellipsis on overflow.
  3. Severity: Tag with color:
     - critical: red "CRITICAL"
     - high: orange "HIGH"
     - medium: gold "MEDIUM"
     - low: blue "LOW"
  4. Status: Tag with color:
     - open: blue "OPEN"
     - investigating: processing (animated) "INVESTIGATING"
     - escalated: orange "ESCALATED"
     - resolved: green "RESOLVED"
     - closed: default "CLOSED"
  5. Assignee: name text.
  6. Fraud Type: purple Tag (e.g., "CLI Spoofing", "Wangiri", "IRSF", "SIM Box").
  7. Estimated Loss: currency formatted using formatCurrency(loss, currency).
     e.g., "NGN 1,250,000" or "$8,500".
  8. Created Date: formatted using formatDate(date, 'short').
  9. Actions:
     - "View" button (link style, small, EyeOutlined) navigating to /cases/:id.
     - AIDD T1 badge (compact) — case actions require review.

  Table: size "small", pagination pageSize 10.

CREATE CASE MODAL:
  Modal title: t('cases.createCase').
  Form (vertical layout):
  - Name (title): Input, required.
  - Description: TextArea, 3 rows, required.
  - Severity: Select — Critical, High, Medium, Low. Required.
  - Fraud Type: Select — CLI Spoofing, Wangiri, IRSF, SIM Box, Traffic Anomaly. Required.
  - Assignee: Input (or Select with user list).
  Modal buttons: OK (submits form) + Cancel.
  Success: toast notification t('cases.caseCreated').

DARK MODE: Standard card/table treatment.
MOBILE: Filter bar wraps vertically. Table scrolls horizontally.
ACCESSIBILITY: Modal has aria-modal="true". Form fields have aria-required.
i18n: All text uses t() with keys from cases.* and common.* namespaces.
```

### 24: Case Detail

```
Design a full fraud case investigation detail page.

LAYOUT:
- Authenticated layout. Class: "vg-page-wrapper acm-fade-in".

BACK NAVIGATION:
- "Back" button (ArrowLeftOutlined icon) navigating to /cases.

CASE HEADER (flex row, space-between):
  Left side:
  - Title: "{CASE-ID}: {case title}" — level 3 heading, margin-bottom 4px.
  - Tag row (Space):
    - Severity Tag (colored): "CRITICAL" / "HIGH" / etc.
    - Status Tag (colored): "INVESTIGATING" / "ESCALATED" / etc.
    - Fraud Type Tag (purple): "CLI Spoofing" / "Wangiri" / etc.
    - AIDD T1 badge (compact).

  Right side (Space):
  - Status Change Select (width 160px):
    Options: Open, Investigating, Escalated, Resolved, Closed.
    onChange triggers status update + success toast.
  - "Escalate" button (danger, ExclamationCircleOutlined).
    Only shown when status is not escalated/resolved/closed.
  - "Resolve" button (primary, CheckCircleOutlined).
    Only shown when status is not resolved/closed.

CONTENT (vertical Space, full width, size "large"):

  Card 1 — Description (title: t('common.description')):
  - Descriptions component (bordered, size "small", responsive columns xs=1 sm=2 lg=3):
    - Case ID
    - Assignee
    - Fraud Type
    - Estimated Loss: red bold text, currency formatted (formatCurrency with case currency).
    - Created Date: formatted
    - Linked Alerts: row of blue Tags (e.g., [ALT-001] [ALT-002] [ALT-003])
  - Below descriptions: Paragraph with full case description text.
  - Resolution section (conditional, shown if case.resolution exists):
    Divider + "Resolution:" label (bold) + resolution text.

  Card 2 — Timeline (title: t('cases.timeline')):
  - Ant Design Timeline component.
  - Each item:
    - Colored dot: blue for "System" author, green for all others.
    - Children content:
      - Author name (bold) + timestamp (12px secondary, margin-left 8px).
      - Note content as Paragraph (margin-top 4px).
  - Items listed chronologically.

  Card 3 — Add Note (title: t('cases.addNote')):
  - TextArea, 3 rows, placeholder t('cases.addNote').
  - "Add Note" button (primary, PlusOutlined, margin-top 12px).
    Disabled when textarea is empty (whitespace-only counts as empty).
    onClick: adds note to timeline, clears textarea, shows success toast.

  Card 4 — Linked Alerts (title: t('cases.linkedAlerts')):
  - Ant Design List, size "small".
  - Each item: blue Tag with alert ID + "View" link button navigating to /alerts/show/:id.

DARK MODE: Standard card treatment.
MOBILE: Header becomes stacked (title above actions). Cards full width.
ACCESSIBILITY: Timeline has role="list". Status select has aria-label.
  Buttons have descriptive aria-labels.
i18n: All text uses t() with cases.* and common.* keys.
```

### 25: CDR Browser

```
Design a Call Detail Record browser page with search and filtering.

LAYOUT:
- Authenticated layout. Class: "vg-page-wrapper acm-fade-in".

PAGE HEADER:
- Title: "CDR Browser" — 24px bold (t('cdr.title')).
- Subtitle: "Search and analyze call detail records" (t('cdr.subtitle')).

FILTER BAR (inside Card, class "vg-filter-bar"):
  Horizontal row, wrapping:
  - A-Number Input: placeholder t('cdr.aNumber'), SearchOutlined prefix, width 200px.
  - B-Number Input: placeholder t('cdr.bNumber'), SearchOutlined prefix, width 200px.
  - Date Range Picker: RangePicker, size "middle".
  - Country Select: placeholder t('cdr.country'), allowClear, width 150px.
    Dynamic options from data (Nigeria, Sierra Leone, UK, US, China, Kenya, etc.).
  - Gateway Select: placeholder t('cdr.gateway'), allowClear, width 150px.
    Dynamic options (GW-MTN-01, GW-INTL-01, GW-INTL-02, GW-GLO-01, etc.).
  - "Export CSV" button (default, DownloadOutlined).
    Exports filtered results as CSV file download.

SUMMARY STATS (Space, margin-bottom 16px):
  - "Total Records: {count}" — secondary text + bold count.
  - "Avg Duration: {formatted}" — secondary text + bold duration.
    Duration formatted as "Xm Ys" or "Xs".

RESULTS TABLE:
  Columns:
  1. ID: small text (e.g., "CDR-001").
  2. A-Number (Calling): monospace text (t('cdr.aNumber')).
  3. B-Number (Called): monospace text (t('cdr.bNumber')).
  4. Start Time: formatted with formatDate(d, 'long') — full datetime.
  5. Duration: formatted "Xm Ys", sortable.
     Sorter compares raw seconds.
  6. Direction: Tag:
     - inbound: blue Tag "INBOUND"
     - outbound: green Tag "OUTBOUND"
     - local: default Tag "LOCAL"
  7. Gateway: text (t('cdr.gateway')).
  8. Country: text (t('cdr.country')).
  9. Status: Tag:
     - completed: green Tag "COMPLETED"
     - failed: red Tag "FAILED"
     - no_answer: default Tag "NO ANSWER"

  Table: size "small", pagination with pageSize 20 and showSizeChanger.

CSV EXPORT: Generates CSV with headers:
  ID, A-Number, B-Number, Start Time, Duration (s), Direction, Gateway, Country, Status.
  Downloads as "cdr_export.csv".

DARK MODE: Standard table/card treatment.
MOBILE: Filter bar wraps. Table scrolls horizontally.
ACCESSIBILITY: Inputs have aria-label. Table has caption. Export button has aria-label.
i18n: All text uses t() with cdr.* and common.* keys.
```

### 26: KPI Scorecard

```
Design a KPI scorecard page with 8 metric cards and period selector.

LAYOUT:
- Authenticated layout. Class: "vg-page-wrapper acm-fade-in".

PAGE HEADER (flex, space-between):
  Left:
  - Title: "KPI Scorecard" (t('kpi.title')) — 24px bold.
  - Subtitle: "Key performance indicators" (t('kpi.subtitle')) — 14px secondary.

  Right:
  - Segmented Control (Ant Design Segmented component):
    Options: "24h" (t('kpi.period24h')) | "7d" (t('kpi.period7d')) | "30d" (t('kpi.period30d')).
    Default: "24h".

KPI CARDS GRID (Row, gutter 16px, 2x4 layout: xs=24 sm=12 lg=6):

  Each card: Ant Design Card, hoverable, class "acm-stats-card".
  Interior centered layout:

  1. Detection Rate:
     Icon: SafetyCertificateOutlined (24px, #1B4F72).
     Label: t('kpi.detectionRate') — secondary text.
     Value: "97.2%" — 32px font-weight 700. JetBrains Mono.
     Trend: ArrowUpOutlined green + "1.3% vs prev period".

  2. False Positive Rate:
     Icon: WarningOutlined.
     Value: "3.8%".
     Trend: ArrowDownOutlined green (down is good) + "0.5%".

  3. MTTI (Mean Time to Identify):
     Icon: ClockCircleOutlined.
     Value: "12 min".
     Trend: ArrowDownOutlined green (lower is better) + "3".

  4. MTTR (Mean Time to Resolve):
     Icon: ClockCircleOutlined.
     Value: "4.2 hrs".
     Trend: ArrowDownOutlined green + "0.8".

  5. Revenue Protected:
     Icon: DollarOutlined.
     Value: currency formatted (e.g., "NGN 8,500,000") using formatCurrency().
     Trend: ArrowUpOutlined green + "12%".

  6. Active Cases:
     Icon: FolderOpenOutlined.
     Value: "7".
     Trend: ArrowUpOutlined RED (more cases is bad) + "2".

  7. Model Accuracy:
     Icon: RobotOutlined.
     Value: "94.6%".
     Trend: ArrowUpOutlined green + "0.3%".

  8. Alert Volume:
     Icon: AlertOutlined.
     Value: "156".
     Trend: ArrowUpOutlined RED (more alerts may be bad) + "23".

  TREND COLOR LOGIC:
  - If trendIsGood=true: color #28A745 (green).
  - If trendIsGood=false: color #DC3545 (red).
  - Arrow direction (up/down) is independent of good/bad.

  CARD LAYOUT:
  - Icon: 24px, centered, #1B4F72 color, margin-bottom 8px.
  - Label: secondary text, centered.
  - Value: 32px bold, centered, margin-top 8px, line-height 1.2.
  - Trend: 14px, centered, margin-top 8px, colored text.

DATA CHANGES BY PERIOD:
  7d: Higher totals, different trends.
  30d: Much higher totals (e.g., revenue "NGN 185,000,000").

DARK MODE: Cards use #1F1F1F. Icon color stays #1B4F72. Text inverts.
MOBILE: Grid becomes 2 columns (sm=12) then single column (xs=24).
ACCESSIBILITY: Each card has aria-label with full metric description.
  Trend arrows have aria-label "increasing" / "decreasing".
i18n: All labels use t() with kpi.* keys. Values use formatCurrency/formatNumber.
```

### 27: Audit Log

```
Design a searchable audit log page.

LAYOUT:
- Authenticated layout. Class: "vg-page-wrapper acm-fade-in".

PAGE HEADER:
- Title: "Audit Log" (t('audit.title')) — 24px bold.
- Subtitle: "System activity and change tracking" (t('audit.subtitle')) — 14px secondary.

FILTER BAR (inside Card, class "vg-filter-bar"):
  Horizontal row:
  - Search Input: placeholder t('common.search'), SearchOutlined prefix, width 250px.
    Searches in details and resource fields.
  - User Dropdown: placeholder t('audit.filterByUser'), allowClear, width 180px.
    Dynamic options from unique users in data (e.g., adebayo.okonkwo, fatima.hassan, system, admin).
  - Action Type Dropdown: placeholder t('audit.filterByAction'), allowClear, width 150px.
    Dynamic options from unique actions.
  - Date Range Picker: RangePicker.
  - "Export CSV" button (DownloadOutlined).
    Downloads filtered results as "audit_log_export.csv".

DATA TABLE:
  Columns:
  1. Timestamp (width 200px): formatted with formatDate(ts, 'long').
     Full datetime including seconds.
  2. User (width 150px): username text (monospace for system accounts).
  3. Action (width 100px): Color-coded Tag:
     - CREATE: green Tag
     - UPDATE: blue Tag
     - DELETE: red Tag
     - EXECUTE: purple Tag
     - EXPORT: cyan Tag
     - BLOCK: orange Tag
     - LOGIN: default (gray) Tag
     - BACKUP: geekblue Tag
     - ROTATE: default Tag
  4. Resource (width 200px): resource path (e.g., "case/CASE-2025-001", "alert/ALT-025").
  5. Details: description text, ellipsis on overflow. Expandable on click.
  6. IP Address (width 130px): monospace text.

  Table: size "small", pagination pageSize 20 with showSizeChanger.

CSV EXPORT FORMAT:
  Headers: Timestamp, User, Action, Resource, Details, IP Address.
  Details field wrapped in quotes for CSV safety.
  Downloads as "audit_log_export.csv".

SAMPLE DATA (for design mockup):
  - adebayo.okonkwo: UPDATE case status
  - fatima.hassan: CREATE critical alert
  - system: EXECUTE ML retrain
  - chukwu.emeka: DELETE expired blacklist entry
  - system: BLOCK traffic pattern (orange tag)
  - admin: LOGIN from new IP
  - system: BACKUP database

DARK MODE: Standard table. Action tags maintain their distinct colors.
MOBILE: Table scrolls horizontally. Filter bar wraps.
ACCESSIBILITY: Table has caption "Audit log entries". Tags have role="status".
i18n: All text uses t() with audit.* and common.* keys.
```

### 28: ML Model Dashboard

```
Design a machine learning model management dashboard.

LAYOUT:
- Authenticated layout. Class: "vg-page-wrapper acm-fade-in".

PAGE HEADER:
- Title: "ML Dashboard" (t('ml.title')) — 24px bold.
- Subtitle: "Machine learning model performance and management" (t('ml.subtitle')) — 14px secondary.

SUMMARY STATS ROW (Row, gutter 16px, margin 24px top/bottom, 3 cards xs=24 sm=8):
  1. Active Models: Statistic with RobotOutlined prefix. Value: count (e.g., "4").
  2. Predictions Today: Statistic with ExperimentOutlined prefix. Value: total (e.g., "32,660").
  3. Avg Accuracy: Statistic with Badge (status="success") prefix.
     Value: calculated average as percentage (e.g., "93.5%"). Precision 1 decimal.

MODEL CARDS GRID (Row, gutter 16px, 2-column layout: xs=24 lg=12):

  Each model card (Ant Design Card):

  CARD HEADER:
  - Title: RobotOutlined icon + model name (bold) + version Tag + status Tag:
    - active: green Tag "ACTIVE"
    - shadow: blue Tag "SHADOW"
    - retired: default Tag "RETIRED"
  - Extra (right side, for non-retired models):
    - "Retrain" button (small, ReloadOutlined icon).
      Triggers retrain with success toast t('ml.retrainRequested').
    - AIDD T2 badge (compact) — model retraining requires admin approval.

  CARD BODY:
  Row of 3 Circular Progress Indicators (Ant Design Progress type="circle", size 80px):
  - Accuracy: percentage (e.g., 94.6%).
    Stroke color: green (#28A745) if >=90%, yellow (#FFC107) if >=80%, red (#DC3545) if <80%.
    Label: t('ml.accuracy').
  - AUC: percentage (e.g., 98.2%).
    Stroke color: #1B4F72.
    Label: t('ml.auc').
  - F1 Score: percentage (e.g., 93.1%).
    Stroke color: #17A2B8.
    Label: t('ml.f1Score').

  METRICS LIST (below progress indicators, margin-top 16px):
  Class "vg-model-metric" — each row is flex space-between:
  - Features Count: t('ml.featureCount') -> bold number (e.g., "47").
  - Last Trained: t('ml.lastTrained') -> formatted date (short).
  - Predictions Today (non-retired only): label -> formatted number.
  - Avg Latency (non-retired only): label -> "23ms".
  - A/B Test Status (conditional): t('ml.abTestStatus') -> blue Tag
    (e.g., "Running -- 20% traffic split").

SAMPLE MODELS (for mockup):
  1. Fraud Detector v3.2.1 — active, 94.6% acc, 98.2% AUC, 93.1% F1, 47 features, 12,450 predictions.
  2. CLI Spoofing Classifier v2.1.0 — active, 92.3% acc, 96.5% AUC, 90.8% F1, 32 features.
  3. Wangiri Pattern Detector v1.8.3 — active, 95.8% acc, 99.1% AUC, 94.4% F1, 28 features.
  4. Fraud Detector v3.3.0-beta — shadow, 95.1% acc, A/B test running.
  5. IRSF Risk Scorer v1.5.0 — active, 91.2% acc, 35 features.
  6. Traffic Anomaly Detector v2.0.1 — retired, 87.6% acc, 0 predictions.

DARK MODE: Cards use #1F1F1F. Progress circle track uses #303030.
MOBILE: Model cards stack to single column.
ACCESSIBILITY: Progress circles have aria-valuenow/min/max.
  Retrain buttons have aria-label "Retrain {model name}".
i18n: All text uses t() with ml.* keys. Numbers use formatNumber().
```

### 29: Report Builder

```
Design a report generation and history page.

LAYOUT:
- Authenticated layout. Class: "vg-page-wrapper acm-fade-in".

PAGE HEADER:
- Title: "Report Builder" (t('reports.title')) — 24px bold.
- Subtitle: "Generate and schedule fraud detection reports" (t('reports.subtitle')) — 14px secondary.

GENERATE REPORT CARD (PlusOutlined icon in title):
  Form (vertical layout):

  ROW 1 (class "vg-filter-bar", horizontal):
  - Report Type: Select dropdown (min-width 220px):
    - Daily Fraud Summary (t('reports.dailyFraudSummary'))
    - Weekly Trend Report (t('reports.weeklyTrend'))
    - Monthly NCC Submission (t('reports.monthlyNcc'))
    - Custom (t('reports.custom'))
    Default: daily_fraud.

  - Date Range: RangePicker.

  - Format: Radio.Group with Radio.Button style:
    - PDF | CSV | Excel
    Default: pdf.

  ROW 2:
  - Schedule: Radio.Group with Radio.Button style:
    - One-time (t('reports.oneTime'))
    - Daily (t('reports.daily'))
    - Weekly (t('reports.weekly'))
    - Monthly (t('reports.monthly'))
    Default: one_time.

  ROW 3:
  - "Generate Report" button (primary, FileTextOutlined icon).
    Loading state on submit. Success toast: t('reports.reportGenerated').

DIVIDER.

REPORT HISTORY CARD (ScheduleOutlined icon in title):
  Table columns:
  1. ID: small text (e.g., "RPT-001").
  2. Report Type (t('reports.reportType')): text.
  3. Date Range (t('reports.dateRange')): text.
  4. Format (t('reports.format')): Tag (e.g., "PDF", "CSV", "Excel").
  5. Status: Tag:
     - generated: green Tag (t('reports.generated'))
     - pending: processing (animated) Tag (t('reports.pending'))
     - failed: red Tag (t('reports.failed'))
  6. Generated At: formatted date (short).
  7. Size: text (e.g., "2.4 MB", "--" if pending).
  8. Schedule: blue Tag if scheduled (e.g., "Daily", "Monthly"), else "--" secondary text.
  9. Actions:
     - "Download" button (link style, small, DownloadOutlined).
       Only visible when status = "generated".

  Table: size "small", pagination pageSize 10.

DARK MODE: Standard form/table treatment.
MOBILE: Form fields stack vertically. Table scrolls.
ACCESSIBILITY: Radio groups have aria-label. Form has aria-label.
i18n: All text uses t() with reports.* and common.* keys.
```

### 30: Class 4 Switch Report

```
Design a Class 4 (transit/tandem) switch analytics report page.

LAYOUT:
- Authenticated layout. Class: "vg-page-wrapper acm-fade-in".

PAGE HEADER:
- Title: "Class 4 Switch Report" — 24px bold.
- Subtitle: "Transit switch trunk group analysis and route performance" — 14px secondary.
- Date range picker (top right).

SECTION 1 — TRUNK GROUP ANALYSIS:
  Card: "Trunk Group Performance"
  Table columns:
  - Trunk Group ID, Name, Direction (inbound/outbound tag), Active Channels,
    Max Channels, Utilization (progress bar %), ASR (%), ACD (seconds), NER (%).
  Row highlight: red background tint if utilization > 90%.

SECTION 2 — ROUTE PERFORMANCE:
  Card: "Route Performance Metrics"
  Row of 4 stat cards:
  - Total Routes Active: number.
  - Average ASR: percentage with color (green >45%, yellow >30%, red <30%).
  - Average ACD: seconds.
  - Average NER: percentage.

  Below: Table of routes:
  - Route Name, Destination Prefix, Carrier, ASR %, ACD (s), NER %,
    Total Calls, Revenue, Cost, Margin %. Color code: negative margin in red.

SECTION 3 — ASR / ACD / NER CHARTS:
  Row of 3 charts (xs=24 lg=8 each):
  - ASR Trend: Line chart over time, green reference line at 45%.
  - ACD Trend: Line chart, blue.
  - NER Trend: Line chart, teal.
  X-axis: hourly/daily. Y-axis: percentage or seconds.

SECTION 4 — CDR SUMMARY BY ROUTE:
  Card: "CDR Summary"
  Table: Route, Total CDRs, Completed, Failed, Short Calls (<6s),
  Long Calls (>30min), Avg Duration, Total Minutes.
  Sortable by all numeric columns.

SECTION 5 — INTERCONNECT BILLING SUMMARY:
  Card: "Billing Summary"
  Table: Carrier, Direction, Total Minutes, Rate/Min, Total Revenue, Total Cost,
  Net Revenue. Currency formatted. Totals row at bottom (bold).

SECTION 6 — TRAFFIC VOLUME HEATMAP:
  Card: "Traffic Volume Heatmap"
  Heatmap grid: X-axis = hour (0-23), Y-axis = day of week (Mon-Sun).
  Cell color intensity: low traffic (light blue) to high traffic (deep blue #1B4F72).
  Hover shows exact count. Color scale legend on right.

SECTION 7 — CAPACITY UTILIZATION GAUGES:
  Row of gauge charts (4-6 per row):
  Each: circular gauge showing trunk utilization percentage.
  Color: green <60%, yellow 60-80%, red >80%.
  Label: trunk group name below.

DARK MODE: Standard. Heatmap uses darker base colors.
MOBILE: Sections stack. Charts full width. Tables scroll.
ACCESSIBILITY: Charts have aria-labels. Heatmap cells have title attributes.
i18n: All text uses t().
```

### 31: Class 5 Switch Report

```
Design a Class 5 (local/subscriber) switch analytics report page.

LAYOUT:
- Authenticated layout. Class: "vg-page-wrapper acm-fade-in".

PAGE HEADER:
- Title: "Class 5 Switch Report" — 24px bold.
- Subtitle: "Subscriber fraud analytics and call pattern analysis" — 14px secondary.
- Date range picker + subscriber search input (top right).

SECTION 1 — SUBSCRIBER FRAUD ANALYTICS:
  Card: "Fraud Risk by Subscriber"
  Table columns:
  - Subscriber ID (monospace), MSISDN, Plan Type (Tag: prepaid/postpaid),
    Risk Score (0-100 color-coded pill), Total Calls (24h), Flagged Calls,
    Revenue (currency), Anomaly Count, Actions (View Profile button).
  Sortable by Risk Score. Top 50 highest risk shown by default.
  Row color: subtle red tint for risk score > 80.

SECTION 2 — PER-SUBSCRIBER CALL PATTERNS:
  Card: "Call Pattern Analysis" (shown when a subscriber is selected)
  - Subscriber header: MSISDN, name, plan, join date.
  - Daily call volume bar chart (last 30 days).
  - Call time distribution: 24-hour histogram (when calls are made).
  - Destination analysis: top 10 destinations (pie chart).
  - Average call duration trend line.

SECTION 3 — LOCAL / TOLL / INTERNATIONAL BREAKDOWN:
  Card: "Traffic Type Distribution"
  Row of 3 donut charts:
  - By Call Count: Local (blue), Toll (teal), International (orange).
  - By Duration: same breakdown.
  - By Revenue: same breakdown.
  Summary table below: Type, Call Count, %, Total Minutes, %, Revenue, %.

SECTION 4 — FEATURE USAGE ANALYSIS:
  Card: "Supplementary Service Usage"
  Table columns:
  - Feature Name: Call Forwarding, 3-Way Calling, Call Waiting,
    Voicemail, Do Not Disturb, Call Barring.
  - Active Subscribers: count.
  - Usage Events (24h): count.
  - Fraud Risk Flag: Tag (normal=green, suspicious=amber, high_risk=red).
    Call forwarding to international numbers = suspicious.
    Excessive 3-way calling = suspicious.
  - Details: expandable row with usage patterns.

SECTION 5 — SUBSCRIBER ANOMALY DETECTION:
  Card: "Anomaly Alerts"
  Table: Subscriber ID, MSISDN, Anomaly Type (Tag: volume_spike, new_destination,
  off_hours_activity, sudden_intl, feature_abuse), Confidence (0-1 bar),
  Detected At, Status (Tag: new/investigating/resolved), Actions.

  Anomaly types with icons:
  - volume_spike: ArrowUpOutlined
  - new_destination: GlobalOutlined
  - off_hours_activity: ClockCircleOutlined
  - sudden_intl: PhoneOutlined
  - feature_abuse: WarningOutlined

SECTION 6 — REVENUE PER SUBSCRIBER CHARTS:
  Card: "Revenue Analytics"
  - Bar chart: Top 20 subscribers by revenue (horizontal bars).
  - Line chart: Average revenue per subscriber trend (monthly).
  - Scatter plot: Revenue vs. Call Count (identify outliers).
    Outlier points highlighted in red with tooltip.

DARK MODE: Standard. Charts use transparent backgrounds.
MOBILE: Sections stack. Charts full width. Tables scroll horizontally.
ACCESSIBILITY: All charts have aria-labels. Tables have captions.
i18n: All text uses t().
```

---

## Design System Reference: Common Patterns

### Table Pattern

```
All VoxGuard tables follow this pattern:
- Ant Design Table component, size "small" or "middle".
- Bordered=false (borderless rows).
- Row hover: #F5F5F5 (light) / #2A2A2A (dark).
- Header: #FAFAFA (light) / #1D1D1D (dark).
- Pagination: bottom right, with page size changer (10, 20, 50).
- Scroll-x enabled on mobile via scroll={{ x: true }} or specific width.
- Loading: built-in Ant Design table loading overlay.
- Empty: custom empty state with icon + message + action button.
- Monospace font (JetBrains Mono) for: phone numbers, IPs, IDs, scores.
- Severity/Status columns always use colored Tags with no border.
- Action columns: fixed right, compact icon buttons.
```

### Card Pattern

```
All VoxGuard cards follow:
- Ant Design Card, bordered=false.
- Border-radius: 8px (borderRadiusLG).
- Shadow: none (flat design) or subtle on hover.
- Title: 16px semi-bold.
- Body padding: 24px.
- Class "acm-stats-card" for metric cards (centered content, hover effect).
```

### Form Pattern

```
All VoxGuard forms follow:
- Vertical layout.
- Size: "large" for main forms, default for inline/modal forms.
- Required mark: hidden (requiredMark={false}).
- Validation: real-time, errors below fields in red.
- Submit button: primary, with loading spinner.
- Cancel button: default, navigates back.
- Sectioned with headings or Dividers for long forms.
```

### Page Layout Pattern

```
Every authenticated page follows:
- Sidebar (fixed left, 200px/80px) + Header (fixed top, 64px) + Content (scrollable).
- Content area: padding 24px.
- Page wrapper class: "vg-page-wrapper acm-fade-in".
- Page title: level 3 heading + secondary subtitle below.
- Content sections wrapped in Cards or directly in the content area.
- Responsive: content fills available space, cards use Row/Col grid.
```

### Color-Coding Quick Reference

```
USE THESE COLORS CONSISTENTLY:
- Green (#28A745): success, resolved, active, allow, good trend
- Red (#DC3545): error, critical, block, delete, bad trend, danger
- Amber (#FFC107): warning, investigating, medium severity, review
- Blue (#17A2B8): info, new, low severity, teal accents
- Orange (#E67E22): high severity, accent, Wangiri, block action
- Purple (#722ED1): CLI Spoofing, special tags, fraud type
- Gray (#6C757D): default, false positive, traffic anomaly, disabled
- Deep Blue (#1B4F72): primary brand, icons, chart primary series
```

---

## Internationalization (i18n) Note

All visible text in every screen uses the `react-i18next` `t()` function. Key namespaces:

```
common.*      — Shared labels (search, status, actions, save, cancel, back, view, etc.)
login.*       — Login page strings
dashboard.*   — Dashboard labels
alerts.*      — Alert management strings + severity labels
gateways.*    — Gateway management strings
users.*       — User management strings
analytics.*   — Analytics page strings
settings.*    — Settings page strings (all 5 tabs)
security.*    — All security sub-page strings
ncc.*         — NCC compliance strings
cases.*       — Case management strings
cdr.*         — CDR browser strings
kpi.*         — KPI scorecard strings
audit.*       — Audit log strings
ml.*          — ML dashboard strings
reports.*     — Report builder strings
```

Supported languages: English, French, Portuguese, Hausa, Yoruba, Igbo, Arabic (RTL), Spanish, Chinese, Swahili.

When Arabic is selected, the entire layout flips to RTL direction.

---

## Accessibility Checklist (Every Screen)

```
1. ARIA Labels: All interactive elements have descriptive aria-labels.
2. Keyboard Navigation: Full Tab + Enter/Space support. Focus indicators visible (2px #1B4F72 outline).
3. Screen Reader: Tables have captions. Charts have text alternatives. Images have alt text.
4. Color Contrast: All text meets WCAG 2.1 AA contrast ratios (4.5:1 body, 3:1 large).
5. Focus Management: Modals trap focus. Page navigation moves focus to main content.
6. Semantic HTML: Headings in correct hierarchy. Lists use proper list elements.
7. Error Handling: Form errors linked to inputs via aria-describedby.
8. Live Regions: Real-time alert counts use aria-live="polite".
9. Motion: Respects prefers-reduced-motion for animations.
10. Touch Targets: Minimum 44x44px for mobile tap targets.
```
