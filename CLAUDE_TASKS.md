# Anti-Call Masking Platform - Task Guide

> NCC-compliant platform for detecting and preventing CLI spoofing and call masking fraud in Nigerian telecommunications.

---

## Quick Start

```bash
# Start development environment
cd packages/web && npm run dev

# Run tests
npm test
```

---

## Task 1: Initialize Monorepo ✅

Create monorepo for Anti-Call Masking Platform with NCC compliance structure.

### Completed
- [x] pnpm workspace configuration
- [x] packages/web - Refine v4 + Ant Design 5.x
- [x] packages/flutter - Ferry + Riverpod + GoRouter  
- [x] packages/android - Jetpack Compose + Apollo + Hilt
- [x] packages/ios - SwiftUI + Apollo + TCA
- [x] backend/hasura - Metadata, migrations, seeds
- [x] infrastructure/docker - Docker Compose with all services

### Core Features
- **CLI Verification** - Real-time caller ID validation
- **Fraud Detection** - ML-based spoofing detection
- **NCC Reporting** - Automated compliance reports
- **Carrier Integration** - Multi-MNO support (MTN, Glo, Airtel, 9mobile)

---

## Task 2: Backend Infrastructure ✅

Set up YugabyteDB schema, Hasura metadata, DragonflyDB caching.

### Database Schema
```sql
-- Core Anti-Masking tables
anti_masking.call_verifications
anti_masking.fraud_alerts
anti_masking.carriers
anti_masking.gateways
anti_masking.blacklist

-- Fraud Prevention tables
fraud_prevention.cli_verifications
fraud_prevention.irsf_destinations
fraud_prevention.irsf_incidents
fraud_prevention.wangiri_incidents
fraud_prevention.wangiri_campaigns

-- Reference tables
reference.nigerian_states
reference.nigerian_banks
```

### Hasura Configuration
- [x] Table metadata with custom column names
- [x] Relationships (object + array)
- [x] Select/Insert/Update/Delete permissions
- [x] Event triggers for domain events
- [x] Real-time subscriptions

---

## Task 3: Web Portal ✅

Build Refine v4 + Ant Design 5.x web portal.

### Features
- [x] Dashboard with real-time fraud stats
- [x] Call Verification management
- [x] Fraud Alert monitoring
- [x] Gateway health tracking
- [x] CLI Integrity verification
- [x] IRSF detection
- [x] Wangiri detection

### Nigerian Components
- [x] `NigerianPhoneInput` - +234 formatting, carrier detection
- [x] `NigerianStateSelect` - 37 states grouped by zone
- [x] `NairaDisplay` - Currency formatting

---

## Task 4: Flutter App ✅

Create Flutter app with Clean Architecture.

### Architecture
```
lib/
├── core/           # DI, routing, theme
├── features/
│   ├── anti_masking/
│   │   ├── data/         # Datasources, repositories
│   │   ├── domain/       # Entities, use cases
│   │   └── presentation/ # Providers, pages, widgets
│   └── fraud_prevention/
│       ├── domain/entities/    # CLI, IRSF, Wangiri entities
│       └── presentation/       # Dashboard, providers
└── shared/         # Common widgets, utils
```

### Stack
- Ferry GraphQL with codegen
- Riverpod state management
- GoRouter navigation
- Freezed for immutable models

---

## Task 5: Native Apps ✅

### Android (Kotlin)
- [x] Jetpack Compose UI
- [x] Apollo Kotlin GraphQL
- [x] Hilt dependency injection
- [x] Fraud Dashboard screen

### iOS (Swift)
- [x] SwiftUI views with animations
- [x] The Composable Architecture (TCA)
- [x] Apollo iOS GraphQL
- [x] FraudDashboard feature

---

## Task 6: Autonomous Pipeline ✅

GitHub Actions workflow for autonomous code generation.

### Triggers
```yaml
on:
  push:
    paths:
      - 'backend/hasura/metadata/**'
      - 'backend/hasura/migrations/**'
      - 'packages/shared/contracts/*.graphql'
  workflow_dispatch:
    inputs:
      force_regenerate: true
```

### Pipeline Phases
1. 🔍 Detect Changes
2. 📡 Introspect Schema
3. 🌐🤖📱🍎 Parallel Generation
4. 🛡️ Quality Gates
5. 📝 Create PR
6. 📢 Notifications
7. ⏪ Rollback (on failure)

---

## Task 7: Fraud Prevention ✅

Comprehensive fraud detection and prevention.

### CLI Spoofing Detection
| Type | Description |
|------|-------------|
| SS7 CPN Mismatch | Signaling vs presented number |
| SIP P-Asserted-Identity | SIP header validation |
| Neighbor Spoofing | Similar number patterns |
| STIR/SHAKEN | Cryptographic verification |

### IRSF Detection (International Revenue Share Fraud)
- High-risk destination monitoring (+960 Maldives, +881 Satellite)
- Traffic pumping detection
- Revenue loss calculation

### Wangiri Detection (One-Ring Fraud)
- Ultra-short ring detection (<2s)
- Campaign identification
- Callback blocking

---

## NCC Compliance

### Required Reports
- Daily fraud incident summaries
- Monthly compliance reports
- Real-time alert notifications

### Nigerian MNO Integration
| Carrier | Prefix | Status |
|---------|--------|--------|
| MTN | 0803, 0806, 0813, 0816, 0703, 0706, 0903, 0906 | ✅ |
| Glo | 0805, 0807, 0815, 0811, 0705, 0905 | ✅ |
| Airtel | 0802, 0808, 0812, 0701, 0708, 0902, 0907, 0901 | ✅ |
| 9mobile | 0809, 0817, 0818, 0909, 0908 | ✅ |

---

## Web Portal URLs

| Page | URL |
|------|-----|
| Dashboard | http://localhost:3003/dashboard |
| Fraud Alerts | http://localhost:3003/anti-masking/fraud-alerts |
| Call Log | http://localhost:3003/anti-masking/calls |
| Gateways | http://localhost:3003/anti-masking/gateways |
| Fraud Prevention | http://localhost:3003/fraud-prevention |
| CLI Integrity | http://localhost:3003/fraud-prevention/cli-integrity |
| IRSF Detection | http://localhost:3003/fraud-prevention/irsf |
| Wangiri Detection | http://localhost:3003/fraud-prevention/wangiri |
