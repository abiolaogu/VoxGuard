# VoxGuard Documentation Index

**Version:** 1.0
**Date:** February 12, 2026
**Total Documents:** 57 markdown files across 7 directories
**AIDD Compliance:** Tier 0 (Documentation)

---

## Quick Navigation

| Need | Document | Path |
|------|----------|------|
| **New to VoxGuard?** | README | [`../README.md`](../README.md) |
| **Setting up dev environment?** | Environment Setup | [`ENVIRONMENT_SETUP.md`](ENVIRONMENT_SETUP.md) |
| **Understanding the architecture?** | Solution Architecture Document | [`technical/SAD.md`](technical/SAD.md) |
| **Working with APIs?** | API Reference | [`API_REFERENCE.md`](API_REFERENCE.md) |
| **Contributing code?** | Contributing Guide | [`../CONTRIBUTING.md`](../CONTRIBUTING.md) |
| **Deploying to production?** | Deployment Guide | [`DEPLOYMENT.md`](DEPLOYMENT.md) |
| **Responding to incidents?** | Runbook | [`runbook.md`](runbook.md) |
| **NCC compliance questions?** | NCC Compliance Spec | [`ncc/NCC_COMPLIANCE_SPECIFICATION.md`](ncc/NCC_COMPLIANCE_SPECIFICATION.md) |
| **Designing UI screens?** | Figma Make Prompts | [`design/FIGMA_MAKE_PROMPTS.md`](design/FIGMA_MAKE_PROMPTS.md) |

---

## 1. Project & Strategic Documents

Business-level documents defining project scope, objectives, and governance.

| Document | Path | Lines | Description |
|----------|------|-------|-------------|
| **Business Requirements Document** | [`BRD.md`](BRD.md) | 623 | Business needs, objectives, ROI analysis, stakeholder analysis, risk assessment |
| **Product Requirements Document** | [`PRD.md`](PRD.md) | 1,046 | Product features, implementation status, technical architecture, roadmap |
| **Enterprise Architecture Roadmap** | [`EA_ROADMAP.md`](EA_ROADMAP.md) | 960 | Architecture vision, current/target state, migration path, technology radar |
| **Project Charter** | [`PROJECT_CHARTER.md`](PROJECT_CHARTER.md) | 576 | Project scope, milestones, budget, organizational structure, AIDD governance |
| **Compliance & Regulatory Matrix** | [`COMPLIANCE_MATRIX.md`](COMPLIANCE_MATRIX.md) | 613 | 140 requirements across NCC, NDPA, GDPR, SOC 2, ISO 27001, PCI-DSS |

---

## 2. Technical & Architecture Documents

Core engineering documents for system design and implementation.

| Document | Path | Lines | Description |
|----------|------|-------|-------------|
| **Solution Architecture Document** | [`technical/SAD.md`](technical/SAD.md) | 1,454 | Comprehensive architecture: C4 diagrams, domain models, data flows, ADRs, deployment topology |
| **API Reference** | [`API_REFERENCE.md`](API_REFERENCE.md) | 1,710 | Complete API docs: Detection Engine (Rust), Management API (Go), GraphQL (Hasura), NCC Compliance (Python) |
| **Database Schema** | [`technical/DATABASE_SCHEMA.md`](technical/DATABASE_SCHEMA.md) | 1,282 | Polyglot schema: YugabyteDB, DragonflyDB, ClickHouse tables, indexes, partitioning, Hasura mapping |
| **Infrastructure as Code** | [`technical/IAC_DOCUMENTATION.md`](technical/IAC_DOCUMENTATION.md) | 1,980 | Kubernetes, Helm charts, Docker builds, database configs, observability stack, CI/CD, secrets management |
| **Security Architecture** | [`technical/SECURITY_ARCHITECTURE.md`](technical/SECURITY_ARCHITECTURE.md) | 1,047 | Threat model, authentication, authorization, network security, audit logging, incident response |
| **Technical Specification** | [`technical/TECHNICAL_SPEC.md`](technical/TECHNICAL_SPEC.md) | 849 | Detection algorithm, API spec, data models, performance specs, deployment specs |
| **System Requirements** | [`technical/SYSTEM_REQUIREMENTS.md`](technical/SYSTEM_REQUIREMENTS.md) | 634 | Hardware, software, network, storage, HA, scaling, environment specifications |
| **Architecture Overview** | [`ARCHITECTURE.md`](ARCHITECTURE.md) | 164 | Quick reference: DDD bounded contexts, domain events, deployment topology |
| **Technical Architecture** | [`technical/ARCHITECTURE.md`](technical/ARCHITECTURE.md) | 165 | Quick reference: Stream processing architecture, components, data flow |
| **Hardware Requirements** | [`technical/HARDWARE_REQUIREMENTS.md`](technical/HARDWARE_REQUIREMENTS.md) | 40 | Quick reference: Deployment profiles (PoC, Production, Hyperscale) |
| **Technical Documentation** | [`VOXGUARD_TECHNICAL_DOCUMENTATION.md`](VOXGUARD_TECHNICAL_DOCUMENTATION.md) | -- | Consolidated technical overview |

### Architecture Decision Records (ADRs)

| ADR | Path | Decision |
|-----|------|----------|
| **ADR-001** | [`adr/001-rust-detection-engine.md`](adr/001-rust-detection-engine.md) | Use Rust for the detection engine (performance-critical path) |
| **ADR-002** | [`adr/002-dragonfly-over-redis.md`](adr/002-dragonfly-over-redis.md) | Use DragonflyDB over Redis for cache layer (multi-threaded performance) |
| **ADR-003** | [`adr/003-hasura-graphql-layer.md`](adr/003-hasura-graphql-layer.md) | Use Hasura for GraphQL API layer (rapid frontend development) |
| **ADR-004** | [`adr/004-aidd-tiered-approvals.md`](adr/004-aidd-tiered-approvals.md) | Implement AIDD tiered approval system for autonomous operations |

---

## 3. Quality & DevOps Documents

Testing, deployment, monitoring, and operational excellence.

| Document | Path | Lines | Description |
|----------|------|-------|-------------|
| **Test Plan** | [`TESTING.md`](TESTING.md) | 518 | Test pyramid, coverage targets (80%+), test types, CI/CD integration, writing guides |
| **CI/CD Pipeline** | [`CICD_PIPELINE.md`](CICD_PIPELINE.md) | 1,501 | Build/test/deploy stages, security scanning, quality gates, rollback procedures |
| **Disaster Recovery** | [`DISASTER_RECOVERY.md`](DISASTER_RECOVERY.md) | 1,276 | RPO/RTO targets, backup strategies, recovery procedures, multi-region failover, DR drills |
| **Performance Benchmarks** | [`PERFORMANCE_BENCHMARKS.md`](PERFORMANCE_BENCHMARKS.md) | 736 | Latency/throughput targets, load test results, scaling characteristics, benchmark methodology |
| **Production Hardening** | [`PRODUCTION_HARDENING.md`](PRODUCTION_HARDENING.md) | 625 | Voice switch hardening, circuit breaker, health checks, scaling, TLS configuration |
| **Observability** | [`OBSERVABILITY.md`](OBSERVABILITY.md) | 702 | Grafana dashboards, Tempo tracing, Prometheus alerts (42 rules), SLA monitoring |
| **Penetration Testing** | [`PENETRATION_TESTING.md`](PENETRATION_TESTING.md) | 902 | OWASP methodology, auth/authz testing, input validation, API security, remediation |
| **Security Hardening** | [`SECURITY_HARDENING.md`](SECURITY_HARDENING.md) | 830 | JWT/RBAC/MFA, Vault secrets, audit logging, network security, compliance mapping |
| **Runbook** | [`runbook.md`](runbook.md) | 575 | Common operations, incident response (5 scenarios), troubleshooting, maintenance, NCC ops |

---

## 4. NCC Compliance Documents

Nigerian Communications Commission regulatory requirements and integration.

| Document | Path | Lines | Description |
|----------|------|-------|-------------|
| **NCC Compliance Specification** | [`ncc/NCC_COMPLIANCE_SPECIFICATION.md`](ncc/NCC_COMPLIANCE_SPECIFICATION.md) | -- | Full NCC ICL Framework 2026 requirements and VoxGuard compliance mapping |
| **NCC API Integration** | [`ncc/NCC_API_INTEGRATION.md`](ncc/NCC_API_INTEGRATION.md) | -- | ATRS API integration, OAuth 2.0 auth, incident submission, report submission |
| **NCC Database Connections** | [`ncc/NCC_DATABASE_CONNECTIONS.md`](ncc/NCC_DATABASE_CONNECTIONS.md) | -- | Database schemas and queries for NCC reporting |
| **NCC Reporting Requirements** | [`ncc/NCC_REPORTING_REQUIREMENTS.md`](ncc/NCC_REPORTING_REQUIREMENTS.md) | -- | Report formats, schedules, SFTP upload procedures, checksums |

---

## 5. User & Operational Documents

Manuals, training materials, and user-facing documentation.

### User Manuals

| Document | Path | Audience |
|----------|------|----------|
| **User Manual** | [`manuals/USER_MANUAL.md`](manuals/USER_MANUAL.md) | Fraud analysts, operators |
| **Admin Manual** | [`manuals/ADMIN_MANUAL.md`](manuals/ADMIN_MANUAL.md) | System administrators |
| **Developer Manual** | [`manuals/DEVELOPER_MANUAL.md`](manuals/DEVELOPER_MANUAL.md) | Software developers |
| **API Developer Manual** | [`manuals/API_DEVELOPER_MANUAL.md`](manuals/API_DEVELOPER_MANUAL.md) | API consumers and integrators |
| **Operations Manual** | [`manuals/OPERATIONS_MANUAL.md`](manuals/OPERATIONS_MANUAL.md) | NOC engineers, DevOps |
| **SOC Analyst Manual** | [`manuals/SOC_ANALYST_MANUAL.md`](manuals/SOC_ANALYST_MANUAL.md) | Security operations center analysts |
| **Analyst Manual** | [`manuals/ANALYST_MANUAL.md`](manuals/ANALYST_MANUAL.md) | Fraud investigation analysts |

### Training Materials

| Document | Path | Description |
|----------|------|-------------|
| **Training Manual** | [`training/TRAINING_MANUAL.md`](training/TRAINING_MANUAL.md) | Comprehensive training curriculum |
| **Training Overview** | [`training/TRAINING_OVERVIEW.md`](training/TRAINING_OVERVIEW.md) | Training program structure and schedule |
| **Video Training Scripts** | [`training/VIDEO_TRAINING_SCRIPTS.md`](training/VIDEO_TRAINING_SCRIPTS.md) | Scripts for training video production |

### Release & Change Management

| Document | Path | Description |
|----------|------|-------------|
| **Release Notes** | [`RELEASE_NOTES.md`](RELEASE_NOTES.md) | Version history and feature changelog |
| **CHANGELOG** | [`../CHANGELOG.md`](../CHANGELOG.md) | Technical changelog (semver) |
| **FAQ** | [`FAQ.md`](FAQ.md) | Frequently asked questions |

---

## 6. Developer & Onboarding Documents

Getting started, contributing, and development workflow.

| Document | Path | Description |
|----------|------|-------------|
| **README** | [`../README.md`](../README.md) | Project overview, quick start, tech stack |
| **Contributing Guide** | [`../CONTRIBUTING.md`](../CONTRIBUTING.md) | Code style, PR process, commit conventions, AIDD tiers |
| **Environment Setup** | [`ENVIRONMENT_SETUP.md`](ENVIRONMENT_SETUP.md) | Development environment configuration |
| **Deployment Guide** | [`DEPLOYMENT.md`](DEPLOYMENT.md) | Deployment procedures and environment configs |
| **Multi-Region Deployment** | [`MULTI_REGION_DEPLOYMENT.md`](MULTI_REGION_DEPLOYMENT.md) | Lagos/Abuja/Asaba regional deployment |
| **Integration Plan** | [`INTEGRATION_PLAN.md`](INTEGRATION_PLAN.md) | Voice Switch and carrier integration plan |
| **Voice Switch Integration** | [`VOICE_SWITCH_INTEGRATION.md`](VOICE_SWITCH_INTEGRATION.md) | OpenSIPS / Kamailio integration guide |
| **AIDD Approval Tiers** | [`AIDD_APPROVAL_TIERS.md`](AIDD_APPROVAL_TIERS.md) | Autonomous operation tier definitions (T0/T1/T2) |
| **Data Retention & Archival** | [`DATA_RETENTION_ARCHIVAL.md`](DATA_RETENTION_ARCHIVAL.md) | 7-year retention policy, archival strategy |

---

## 7. Design Documents

UI/UX design specifications and design system.

| Document | Path | Lines | Description |
|----------|------|-------|-------------|
| **Figma Make Prompts** | [`design/FIGMA_MAKE_PROMPTS.md`](design/FIGMA_MAKE_PROMPTS.md) | 2,399 | Complete design prompts for 31 screens, brand system, 7 global components, patterns |

### Screens Covered

| # | Screen | # | Screen |
|---|--------|---|--------|
| 01 | Login Page | 17 | Multi-Call Detection |
| 02 | Dashboard | 18 | Revenue Fraud |
| 03 | Alerts List | 19 | Traffic Control |
| 04 | Alert Detail | 20 | False Positives |
| 05 | Alert Edit | 21 | NCC Compliance |
| 06 | Gateways List | 22 | MNP Lookup |
| 07 | Gateway Detail | 23 | Case Management List |
| 08 | Gateway Create/Edit | 24 | Case Detail |
| 09 | Users List | 25 | CDR Browser |
| 10 | User Detail | 26 | KPI Scorecard |
| 11 | User Create/Edit | 27 | Audit Log |
| 12 | Analytics | 28 | ML Model Dashboard |
| 13 | Settings | 29 | Report Builder |
| 14 | RVS Dashboard | 30 | Class 4 Switch Report |
| 15 | Composite Scoring | 31 | Class 5 Switch Report |
| 16 | Lists Management | | |

---

## 8. AI & Automation Documents

AI/ML pipeline and autonomous operation documentation.

| Document | Path | Description |
|----------|------|-------------|
| **AI Changelog** | [`AI_CHANGELOG.md`](AI_CHANGELOG.md) | AI-generated changes and decisions log |
| **AI Changelog Update** | [`AI_CHANGELOG_UPDATE.md`](AI_CHANGELOG_UPDATE.md) | Latest AI changelog entries |
| **Dashboard Documentation** | [`DASHBOARD.md`](DASHBOARD.md) | Dashboard feature specifications |

---

## Document Relationships

```
                         ┌─────────────┐
                         │   README    │
                         └──────┬──────┘
                                │
              ┌─────────────────┼─────────────────┐
              │                 │                  │
      ┌───────▼──────┐  ┌──────▼──────┐  ┌───────▼──────┐
      │     BRD      │  │   Charter   │  │  CONTRIBUTING │
      │  (Business)  │  │  (Project)  │  │  (Developer)  │
      └───────┬──────┘  └──────┬──────┘  └───────┬──────┘
              │                │                  │
      ┌───────▼──────┐  ┌──────▼──────┐  ┌───────▼──────┐
      │     PRD      │  │ EA Roadmap  │  │  ENV Setup   │
      │  (Product)   │  │  (Arch)     │  │  (Dev)       │
      └───────┬──────┘  └──────┬──────┘  └───────┬──────┘
              │                │                  │
              └────────────────┼──────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │    SAD (Architecture)│
                    └──────────┬──────────┘
                               │
         ┌──────────┬──────────┼──────────┬──────────┐
         │          │          │          │          │
    ┌────▼───┐ ┌────▼───┐ ┌───▼────┐ ┌───▼────┐ ┌──▼──────┐
    │API Ref │ │DB Schema│ │Security│ │  IaC   │ │Tech Spec│
    └────────┘ └────────┘ └────────┘ └────────┘ └─────────┘
```

---

## Duplicate Document Notes

The following documents have overlapping content. Cross-references have been added.

| Brief Document | Comprehensive Alternative | Recommendation |
|---------------|--------------------------|----------------|
| `ARCHITECTURE.md` (root, 164 lines) | `technical/SAD.md` (1,454 lines) | Use SAD.md for full architecture details |
| `technical/ARCHITECTURE.md` (165 lines) | `technical/SAD.md` (1,454 lines) | Use SAD.md for full architecture details |
| `technical/PRD.md` (518 lines) | `PRD.md` (1,046 lines) | Use root PRD.md for implementation status |
| `technical/HARDWARE_REQUIREMENTS.md` (40 lines) | `technical/SYSTEM_REQUIREMENTS.md` (634 lines) | Use SYSTEM_REQUIREMENTS.md for full specs |

---

## Maintenance Schedule

| Frequency | Documents | Reviewer |
|-----------|-----------|----------|
| **Quarterly** | Compliance Matrix, Security Architecture, Penetration Testing | Security Architect, Compliance Lead |
| **Monthly** | Release Notes, CHANGELOG, AI Changelog | Engineering Lead |
| **Per Sprint** | PRD (implementation status), Runbook, Test Plan | Product Owner, DevOps Lead |
| **Per Architecture Change** | SAD, ADRs, EA Roadmap, IaC Documentation | Architecture Board |
| **Per API Change** | API Reference, Database Schema | Engineering Team |

---

*This index is maintained under version control. Update this file when adding, removing, or significantly modifying documentation.*
