
Create a monorepo structure for an Anti-Call Masking Platform following Domain-Driven Design.

Create the following structure:
1. packages/web - Refine v4 + Ant Design 5.x + React Query
2. packages/flutter - Ferry GraphQL + Riverpod + GoRouter
3. packages/android - Jetpack Compose + Apollo Kotlin + Hilt
4. packages/ios - SwiftUI + Apollo iOS + TCA
5. backend/hasura - Metadata, migrations, seeds
6. backend/dragonflydb - Redis replacement configuration
7. backend/n8n - Workflow automation

Include DDD bounded contexts: AntiMasking, Remittance, Marketplace, Identity

Generate all configuration files for pnpm workspaces, docker-compose.yml with DragonflyDB, and GitHub Actions for autonomous codegen.

