# Changelog

All notable changes to the VoxGuard platform will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Placeholder for upcoming features and improvements.

### Changed
- Placeholder for changes to existing functionality.

### Deprecated
- Placeholder for features that will be removed in future releases.

### Removed
- Placeholder for features removed in this release.

### Fixed
- Placeholder for bug fixes.

### Security
- Placeholder for security-related changes.

---

## [2.1.0] - 2026-02-12

### Added
- **Internationalization (i18n):** Full multi-language support for 10 languages — English, French, Spanish, Portuguese, Arabic, Hausa, Yoruba, Igbo, Swahili, and Pidgin English. Language switching is available via the user settings panel and persists across sessions.
- **Case Management page** (`/cases`): End-to-end fraud case lifecycle management with status tracking (Open, Investigating, Escalated, Resolved, Closed), assignment workflows, and case notes with audit trails.
- **CDR Analysis page** (`/cdr-analysis`): Call Detail Record analysis interface with advanced filtering, pattern visualization, anomaly highlighting, and exportable reports for regulatory compliance.
- **KPI Dashboard page** (`/kpi-dashboard`): Real-time Key Performance Indicator dashboard displaying detection rates, false positive ratios, mean time to detect (MTTD), mean time to respond (MTTR), and system throughput metrics with configurable time ranges.
- **Audit Trail page** (`/audit-trail`): Comprehensive audit logging viewer with filterable event streams, user activity tracking, change diffs, and tamper-evident log verification for NCC compliance.
- **ML Model Management page** (`/ml-models`): Machine learning model lifecycle management interface for viewing deployed models, monitoring model drift, comparing model performance, and triggering retraining pipelines.
- **Reports page** (`/reports`): Configurable reporting engine with scheduled report generation, multiple export formats (PDF, CSV, Excel), and pre-built report templates for regulatory submissions.
- **`ErrorBoundary` component:** Global React error boundary with graceful fallback UI, error reporting to the monitoring stack, and automatic recovery options. Wraps all route-level components.
- **`useVoxGuardData` hook:** Custom React hook providing a unified data-fetching interface across the application. Abstracts Refine's data provider with VoxGuard-specific defaults including automatic retry, caching, and real-time subscription support via Hasura.
- **`pages.css` stylesheet:** Consolidated page-level styles providing consistent layout, spacing, typography, and responsive breakpoints across all new pages. Follows the VoxGuard design system tokens.

### Changed
- Upgraded Refine framework to latest stable release for improved data provider performance.
- Improved sidebar navigation to accommodate new pages with collapsible section groups.

### Fixed
- Resolved intermittent WebSocket disconnection in Hasura real-time subscriptions under high load.
- Fixed date-range picker timezone handling in dashboard filters.

---

## [2.0.0] - 2026-02-05

### Added
- **VoxGuard standalone platform launch:** Complete rewrite and launch as an independent telecommunications fraud detection platform, decoupled from prior monolithic architecture.
- **Refine + Ant Design frontend:** Built the entire frontend on the [Refine](https://refine.dev/) framework with [Ant Design](https://ant.design/) component library, providing a modern, accessible, and responsive admin interface.
- **Security pages (7 total):**
  - **Login page** (`/login`): Secure authentication with support for username/password and SSO integration.
  - **Registration page** (`/register`): User self-registration with email verification and admin approval workflow.
  - **Forgot Password page** (`/forgot-password`): Password reset flow with time-limited, single-use tokens delivered via email.
  - **Two-Factor Authentication page** (`/2fa`): TOTP-based two-factor authentication setup and verification using authenticator apps.
  - **Role Management page** (`/roles`): Role-based access control (RBAC) configuration interface for defining roles, permissions, and resource-level access policies.
  - **User Management page** (`/users`): Administrative user management with bulk operations, status management, and activity summaries.
  - **Session Management page** (`/sessions`): Active session viewer with remote session termination, idle timeout configuration, and concurrent session limits.
- **NCC Compliance module:** Built-in compliance checks and reporting aligned with Nigerian Communications Commission (NCC) regulatory requirements for telecommunications fraud detection and prevention.
- **Dashboard** (`/dashboard`): Executive-level overview dashboard with real-time fraud detection statistics, alert summaries, system health indicators, and trend visualizations.
- **Hasura GraphQL integration:** Full integration with Hasura for real-time GraphQL subscriptions, role-based data access, and automatic CRUD operations.
- **Theming and branding:** VoxGuard custom theme with light/dark mode support, consistent color palette, and branded assets.

### Changed
- Migrated from REST-based data fetching to GraphQL via Hasura data provider.
- Replaced legacy component library with Ant Design for consistent UI/UX patterns.

### Security
- Implemented Content Security Policy (CSP) headers.
- Added rate limiting on authentication endpoints.
- Enabled HTTPS-only cookie flags for session tokens.
- Input sanitization applied to all user-facing forms.

---

## [1.5.0] - 2026-02-04

### Added
- **Prometheus metrics collection:** Instrumented all backend services (Rust, Go, Python) with Prometheus client libraries, exposing application-level metrics (request latency, error rates, queue depths, detection counts) on `/metrics` endpoints.
- **Grafana dashboards:** Pre-built Grafana dashboard suite with panels for:
  - System overview (CPU, memory, network, disk)
  - Detection engine performance (CPS throughput, P50/P95/P99 latency)
  - API gateway metrics (request rate, error rate, response times)
  - ML pipeline metrics (inference latency, model accuracy, feature drift)
  - Database performance (query latency, connection pool utilization, replication lag)
- **Tempo distributed tracing:** Integrated Grafana Tempo for distributed trace collection across all services. Trace context propagation via OpenTelemetry SDK with automatic span creation for HTTP, gRPC, and database operations.
- **AlertManager configuration:** Defined alerting rules for critical operational scenarios:
  - Detection engine latency exceeding SLA thresholds
  - Service health check failures
  - Database replication lag exceeding acceptable limits
  - Disk space and memory utilization warnings
  - ML model accuracy degradation alerts
- **Structured logging:** Standardized JSON-structured logging across all services with correlation IDs for cross-service request tracing.
- **Health check endpoints:** Added `/health` and `/ready` endpoints to all services for Kubernetes liveness and readiness probes.

### Changed
- Refactored service initialization to include OpenTelemetry tracer and meter providers.
- Updated Docker Compose configuration to include the full observability stack (Prometheus, Grafana, Tempo, AlertManager).

---

## [1.0.0] - 2026-01-15

### Added
- **Rust detection engine:** High-performance, real-time fraud detection engine built in Rust using Actix-Web and Tokio. Capable of processing 150,000+ calls per second (CPS) with sub-millisecond P99 latency. Implements rule-based detection with support for:
  - SIMBox / bypass fraud detection via voice fingerprint analysis
  - Wangiri (one-ring) fraud pattern detection
  - International Revenue Share Fraud (IRSF) detection
  - CLI spoofing detection
  - Unusual call pattern anomaly detection
- **Go management API:** RESTful management API built in Go for administrative operations including:
  - Rule management (CRUD operations for detection rules)
  - Configuration management (system-wide settings)
  - User and role management endpoints
  - Report generation and export
  - Webhook management for external integrations
- **Python ML pipeline:** Machine learning pipeline built in Python for advanced fraud detection including:
  - Feature engineering from CDR data
  - Model training with scikit-learn and XGBoost
  - Real-time inference serving via FastAPI
  - Model versioning and A/B testing support
  - Automated retraining triggers based on drift detection
- **DragonflyDB caching layer:** High-throughput, Redis-compatible caching layer using DragonflyDB for detection rule caching, session state, and rate limiting.
- **ClickHouse analytics database:** Columnar analytics database for CDR storage, historical query analysis, and reporting workloads.
- **YugabyteDB operational database:** Distributed SQL database for transactional workloads including user management, case records, and audit logs.
- **Hasura GraphQL layer:** Auto-generated GraphQL API over YugabyteDB with real-time subscriptions and role-based access control.
- **Docker Compose development environment:** Full local development environment with all services orchestrated via Docker Compose.
- **CI/CD pipeline:** GitHub Actions pipeline with build, test, lint, and deploy stages for all services.
- **Infrastructure as Code:** Terraform configurations for cloud deployment targeting AWS (EKS, RDS, ElastiCache, S3).
- **Monorepo tooling:** pnpm workspaces and Turborepo configuration for efficient monorepo management with dependency-aware task execution.

---

[Unreleased]: https://github.com/<org>/VoxGuard/compare/v2.1.0...HEAD
[2.1.0]: https://github.com/<org>/VoxGuard/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/<org>/VoxGuard/compare/v1.5.0...v2.0.0
[1.5.0]: https://github.com/<org>/VoxGuard/compare/v1.0.0...v1.5.0
[1.0.0]: https://github.com/<org>/VoxGuard/releases/tag/v1.0.0

## 2026-02-18 - Frontend Stack Standardization

- Added unified frontend stack scaffolding for web, flutter, android, and ios.
- Added GraphQL schema/codegen scripts and CI workflows for metadata/schema triggers.
- Added docs for architecture and code generation workflow.
