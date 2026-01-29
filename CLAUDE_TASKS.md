# Anti-Call Masking Platform - Task Guide

> Generate the complete platform using Claude Code CLI or Desktop

---

## Quick Start

```bash
# Run all tasks sequentially
./batch-run-anti-masking.sh

# Or run individual task with Claude CLI
claude -p "$(cat CLAUDE_TASKS.md | sed -n '/## Task 1/,/## Task 2/p')"
```

---

## Task 1: Initialize Monorepo ✅

Create monorepo for Anti-Call Masking Platform with DDD structure.

### Completed
- [x] pnpm workspace configuration
- [x] packages/web - Refine v4 + Ant Design 5.x
- [x] packages/flutter - Ferry + Riverpod + GoRouter  
- [x] packages/android - Jetpack Compose + Apollo + Hilt
- [x] packages/ios - SwiftUI + Apollo + TCA
- [x] backend/hasura - Metadata, migrations, seeds
- [x] infrastructure/docker - Docker Compose with all services

### Bounded Contexts
- `AntiMasking` - CLI verification, fraud detection
- `Remittance` - Money transfer to Nigeria
- `Marketplace` - Diaspora services
- `Identity` - Authentication, KYC

---

## Task 2: Backend Infrastructure ✅

Set up YugabyteDB schema, Hasura metadata, DragonflyDB caching.

### Database Schema
```sql
-- Core tables created
anti_masking.call_verifications
anti_masking.fraud_alerts
anti_masking.carriers
remittance.corridors
remittance.transactions
remittance.recipients
marketplace.listings
marketplace.categories
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
- [x] Dashboard with real-time stats
- [x] Call Verification management
- [x] Remittance tracking
- [x] Marketplace listings

### Nigerian Components
- [x] `NigerianBankSelect` - 30+ banks with brand colors
- [x] `NigerianStateSelect` - 37 states grouped by zone
- [x] `NigerianPhoneInput` - +234 formatting, carrier detection
- [x] `CurrencyDisplay` - NGN/USD/GBP with flags

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
│   ├── remittance/
│   └── marketplace/
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
- [x] Orbit MVI architecture

### iOS (Swift)
- [x] SwiftUI views with animations
- [x] The Composable Architecture (TCA)
- [x] Apollo iOS GraphQL
- [x] Unit tests with TCA testing

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

## Task 7: Nigerian Features ✅

Remittance corridors, bank integration, marketplace.

### Remittance Corridors
| Source | Target | Fee |
|--------|--------|-----|
| USA | Nigeria | 1.5% + $2.99 |
| UK | Nigeria | 1.5% + £2.49 |
| Canada | Nigeria | 1.5% + C$3.49 |
| Germany | Nigeria | 1.5% + €2.49 |
| South Africa | Nigeria | 2.0% + R4.99 |

### Nigerian Banks (30+)
Commercial: GTBank, First Bank, Zenith, UBA, Access, FCMB, Fidelity...
Digital: Kuda, OPay, PalmPay, Moniepoint, Carbon

### Marketplace Categories
Bill Payment • School Fees • Rent Payment • Food & Groceries • Electronics • Vehicles • Property • Fashion • Home Services • Healthcare

---

## Repository Convergence (Recommended)

```
billyrinks-platform/                    # Main monorepo
├── apps/
│   ├── hustlex/                        # Existing HustleX
│   ├── vendor-platform/                # Existing Vendor Platform
│   ├── anti-call-masking/              # ← This project
│   └── global-fintech/                 # Existing Global FinTech
├── packages/                           # Shared across all apps
│   ├── shared-domain/                  # Common domain models
│   ├── shared-ui/                      # Design system
│   └── shared-utils/                   # Utilities
└── infrastructure/                     # Shared infra
    ├── hasura/                         # Unified Hasura
    ├── dragonflydb/                    # Shared cache
    └── n8n/                            # Workflow automation
```

### Benefits
- Shared Nigerian reference data across apps
- Unified authentication/identity
- Common design system
- Single Hasura instance with multiple schemas
- Reusable GraphQL fragments

---

## Usage with Claude

### CLI Mode
```bash
# Run specific task
claude -p "Complete Task 3: Web Portal with Nigerian components"

# Continue from context
claude --continue "Fix the TypeScript errors in NigerianBankSelect"
```

### Desktop Mode
1. Open this file in Claude Desktop
2. Select a task section
3. Use "Work on this" to generate code

### Cowork Mode
```bash
# Multi-agent collaboration
cowork start --agents 3 --tasks CLAUDE_TASKS.md
```
