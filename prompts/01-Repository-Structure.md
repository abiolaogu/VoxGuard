
# Anti-Call Masking Platform - Repository Structure

Create a monorepo structure for an Anti-Call Masking Platform for Nigerian telecommunications.

## Structure

1. **packages/web** - Refine v4 + Ant Design 5.x + React Query
2. **packages/flutter** - Ferry GraphQL + Riverpod + GoRouter
3. **packages/android** - Jetpack Compose + Apollo Kotlin + Hilt
4. **packages/ios** - SwiftUI + Apollo iOS + TCA
5. **backend/hasura** - Metadata, migrations, seeds
6. **backend/dragonflydb** - Redis replacement configuration
7. **backend/n8n** - Workflow automation

## Core Features

- **CLI Verification** - Real-time caller ID validation
- **Fraud Detection** - CLI spoofing, IRSF, Wangiri detection
- **NCC Compliance** - Nigerian Communications Commission reporting
- **Carrier Integration** - MTN, Glo, Airtel, 9mobile support

Generate all configuration files for pnpm workspaces, docker-compose.yml with DragonflyDB, and GitHub Actions for autonomous codegen.
