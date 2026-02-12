# VoxGuard Enterprise Architecture Roadmap

**Version:** 1.0
**Date:** February 12, 2026
**Status:** Approved
**Owner:** VoxGuard Architecture Board
**Classification:** Confidential -- Internal Use Only
**AIDD Compliance:** Tier 0 (Documentation)

---

## Document Control

| Field | Value |
|-------|-------|
| Document ID | VG-EAR-2026-001 |
| Version | 1.0 |
| Author | VoxGuard Architecture Board |
| Reviewed By | CTO, Engineering Leads, Security Architect |
| Approved By | Executive Steering Committee |
| Effective Date | February 12, 2026 |
| Next Review | August 2026 |

### Revision History

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 0.1 | January 10, 2026 | Architecture Board | Initial draft |
| 0.5 | January 25, 2026 | CTO | Technical review |
| 0.9 | February 5, 2026 | Security Architect | Security architecture review |
| 1.0 | February 12, 2026 | Steering Committee | Final approval |

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Current State Architecture](#2-current-state-architecture)
3. [Target State Architecture](#3-target-state-architecture)
4. [Migration Path](#4-migration-path)
5. [Technology Standards](#5-technology-standards)
6. [Integration Points](#6-integration-points)
7. [Data Architecture](#7-data-architecture)
8. [Security Architecture](#8-security-architecture)
9. [Scalability Plan](#9-scalability-plan)
10. [Future Capabilities](#10-future-capabilities)
11. [AIDD Integration Points](#11-aidd-integration-points)
12. [Architecture Governance](#12-architecture-governance)

---

## 1. Executive Summary

This Enterprise Architecture Roadmap defines the architectural vision, current state, target state, and evolution path for the VoxGuard Anti-Call Masking & Voice Network Fraud Detection Platform. The roadmap spans from the platform's current state (February 2026) through the fully realized target architecture (December 2027), with clear intermediate states and migration strategies.

### 1.1 Architecture Vision

VoxGuard's architecture is designed around four core principles:

1. **Performance-First:** Sub-millisecond detection latency at 150K+ CPS requires every architectural decision to prioritize throughput and latency.
2. **Domain-Driven Design (DDD):** Rich domain models with bounded contexts ensure business logic encapsulation and team autonomy.
3. **Hexagonal Architecture (Ports & Adapters):** Infrastructure independence allows database, cache, and protocol changes without domain logic modification.
4. **Event-Driven CQRS:** Separated command and query paths enable independent scaling of write-heavy detection and read-heavy analytics workloads.

### 1.2 Architecture Maturity Model

| Level | State | Timeline | Characteristics |
|-------|-------|----------|-----------------|
| L1 | **Current** | Feb 2026 | Core detection engine, management API, basic dashboard, single-region |
| L2 | **Phase 1 Target** | Jun 2026 | Full detection suite, NCC integration, production-hardened, single-region GA |
| L3 | **Phase 2 Target** | Oct 2026 | ML pipeline, advanced analytics, multi-region, NCC certified |
| L4 | **Strategic Target** | Dec 2027 | Multi-operator, international integration, blockchain audit, autonomous response |

---

## 2. Current State Architecture

### 2.1 Architecture Overview (As-Is, February 2026)

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              EXTERNAL INTERFACES                                 │
│                                                                                  │
│  ┌───────────────────┐  ┌───────────────────┐  ┌───────────────────┐           │
│  │ Voice Switches     │  │ NCC ATRS API      │  │ MNP Database      │           │
│  │ (Kamailio/OpenSIPS)│  │ (REST + SFTP)     │  │ (Lookup Service)  │           │
│  └─────────┬─────────┘  └─────────┬─────────┘  └─────────┬─────────┘           │
└────────────┼─────────────────────┼─────────────────────┼───────────────────────┘
             │ SIP Events           │ Reports              │ CLI Validation
             ▼                      ▼                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              APPLICATION LAYER                                   │
│                                                                                  │
│  ┌────────────────────────┐  ┌─────────────────────┐  ┌──────────────────────┐ │
│  │ Detection Engine (Rust)│  │ Management API (Go) │  │ ML Pipeline (Python) │ │
│  │ ~30K lines             │  │ ~11.5K lines        │  │ ~8.6K lines          │ │
│  │                        │  │                     │  │                      │ │
│  │ • CLI Masking Detect   │  │ • Alert CRUD        │  │ • Model Training     │ │
│  │ • SIM-Box Detect       │  │ • Gateway Mgmt      │  │ • Feature Extraction │ │
│  │ • Sliding Window       │  │ • User/Auth Mgmt    │  │ • Online Inference   │ │
│  │ • Gateway Blacklist    │  │ • NCC Reporting     │  │ • CDR Parsing        │ │
│  │ • Real-Time Scoring    │  │ • MNP Integration   │  │ • Anomaly Detection  │ │
│  │                        │  │                     │  │                      │ │
│  │ DDD + Hexagonal Arch   │  │ DDD + Clean Arch    │  │ DDD + Pipeline Arch  │ │
│  └────────────┬───────────┘  └──────────┬──────────┘  └──────────┬───────────┘ │
│               │                          │                        │              │
│               │         ┌────────────────┤                        │              │
│               │         │  Hasura GraphQL │                        │              │
│               │         │  (Data Gateway) │                        │              │
│               │         └────────┬───────┘                        │              │
└───────────────┼──────────────────┼────────────────────────────────┼──────────────┘
                │                  │                                │
┌───────────────┼──────────────────┼────────────────────────────────┼──────────────┐
│               ▼                  ▼                                ▼              │
│                              DATA LAYER                                          │
│                                                                                  │
│  ┌────────────────────┐  ┌─────────────────────┐  ┌──────────────────────┐     │
│  │ DragonflyDB        │  │ YugabyteDB          │  │ ClickHouse           │     │
│  │ (Hot Cache)        │  │ (ACID Transactions) │  │ (OLAP Analytics)     │     │
│  │                    │  │                     │  │                      │     │
│  │ • Sliding windows  │  │ • Alerts            │  │ • CDR analytics      │     │
│  │ • Session state    │  │ • Gateways          │  │ • Trend analysis     │     │
│  │ • Rate limiting    │  │ • Users & RBAC      │  │ • Historical queries │     │
│  │ • MNP cache        │  │ • Compliance data   │  │ • Aggregation        │     │
│  │ • Blacklists       │  │ • Audit logs        │  │                      │     │
│  └────────────────────┘  └─────────────────────┘  └──────────────────────┘     │
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────┐     │
│  │ S3-Compatible Cold Storage (Archival -- 7-Year Retention)              │     │
│  └────────────────────────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────────────────────────┘
                │
┌───────────────┼──────────────────────────────────────────────────────────────────┐
│               ▼                                                                  │
│                            PRESENTATION LAYER                                    │
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────┐     │
│  │ Operator Dashboard (React + TypeScript + Refine + Ant Design)          │     │
│  │                                                                        │     │
│  │ • Fraud Alert Console        • Gateway Management                     │     │
│  │ • Real-Time Analytics        • Compliance Reporting                   │     │
│  │ • System Health Dashboard    • User Administration                    │     │
│  └────────────────────────────────────────────────────────────────────────┘     │
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────┐     │
│  │ Observability (Prometheus + Grafana + OpenTelemetry)                    │     │
│  └────────────────────────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Current State Assessment

| Dimension | Status | Maturity | Notes |
|-----------|--------|----------|-------|
| Detection Engine (Rust) | Implemented | High | Core CLI masking + SIM-box detection operational; <1ms P99 achieved |
| Management API (Go) | Implemented | High | CRUD operations, Hasura GraphQL, RBAC functional |
| ML Pipeline (Python) | In Progress | Medium | Model training pipeline operational; online inference in development |
| Dashboard (React) | Implemented | Medium | Alert console, gateway management, basic analytics live |
| NCC ATRS Integration | In Progress | Medium | API integration developed; sandbox testing underway |
| Multi-Region | Designed | Low | Architecture designed; single-region deployment only |
| Data Platform | Implemented | High | Three-tier storage operational; archival system configured |
| Security | Implemented | High | mTLS, JWT, RBAC, Vault, audit logging operational |
| Observability | Implemented | Medium | Prometheus + Grafana operational; distributed tracing in progress |

### 2.3 Current Bounded Contexts

| Context | Language | Responsibility | Domain Objects |
|---------|----------|---------------|----------------|
| **Detection Context** | Rust | Real-time fraud detection and scoring | Call, FraudAlert, Gateway, ThreatLevel, MSISDN, IPAddress, FraudScore, DetectionWindow |
| **Management Context** | Go | Platform administration and operations | Gateway, FraudAlert, Blacklist, NCCReport, Settlement, User, Role |
| **Processing Context** | Python | ML model training, CDR parsing, inference | CDRRecord, FeatureVector, ModelVersion, InferenceResult, AnomalyScore |
| **Presentation Context** | TypeScript | Operator dashboard and visualization | AlertView, GatewayView, AnalyticsWidget, ComplianceReport, UserSession |

### 2.4 Current Technology Debt

| Item | Severity | Impact | Remediation Plan |
|------|----------|--------|-----------------|
| Wangiri detection not yet implemented | Medium | Detection coverage gap for one-ring fraud | Phase 1 M3 deliverable |
| IRSF detection requires GSMA feed integration | Medium | Cannot score international destination risk | Phase 2 with GSMA partnership |
| ClickHouse analytics queries not optimized for 7-year range | Low | Slow historical queries beyond 1 year | Materialized views + partitioning |
| OpenTelemetry distributed tracing incomplete | Low | Cross-service debugging limited | Phase 1 M4 deliverable |
| Single-region deployment | High | No geographic redundancy or failover | Phase 2 M9 deliverable |

---

## 3. Target State Architecture

### 3.1 Phase 2 Target Architecture (October 2026)

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                           GLOBAL TRAFFIC MANAGEMENT                                   │
│                                                                                       │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐                   │
│  │ DNS-Based Routing │  │ Global Load      │  │ Traffic Policy   │                   │
│  │ (GeoDNS)         │  │ Balancer         │  │ Engine           │                   │
│  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘                   │
└───────────┼─────────────────────┼─────────────────────┼──────────────────────────────┘
            │                     │                     │
            ▼                     ▼                     ▼
┌──────────────────────┐ ┌──────────────────────┐ ┌──────────────────────┐
│   LAGOS REGION       │ │   ABUJA REGION       │ │   ASABA REGION       │
│   (Primary)          │ │   (Replica)          │ │   (DR Site)          │
│                      │ │                      │ │                      │
│ ┌──────────────────┐ │ │ ┌──────────────────┐ │ │ ┌──────────────────┐ │
│ │ Kubernetes Cluster│ │ │ │ Kubernetes Cluster│ │ │ │ Kubernetes Cluster│ │
│ │                  │ │ │ │                  │ │ │ │                  │ │
│ │ Detection (4x)   │ │ │ │ Detection (2x)   │ │ │ │ Detection (2x)   │ │
│ │ Mgmt API (3x)    │ │ │ │ Mgmt API (2x)    │ │ │ │ Mgmt API (2x)    │ │
│ │ ML Service (2x)  │ │ │ │ ML Service (1x)  │ │ │ │ ML Service (1x)  │ │
│ │ Dashboard (2x)   │ │ │ │ Dashboard (1x)   │ │ │ │ Dashboard (1x)   │ │
│ │ Hasura (2x)      │ │ │ │ Hasura (1x)      │ │ │ │ Hasura (1x)      │ │
│ │                  │ │ │ │                  │ │ │ │                  │ │
│ │ DragonflyDB (P)  │ │ │ │ DragonflyDB (R)  │ │ │ │ DragonflyDB (R)  │ │
│ │ YugabyteDB (P)   │ │ │ │ YugabyteDB (R)   │ │ │ │ YugabyteDB (R)   │ │
│ │ ClickHouse (P)   │ │ │ │ ClickHouse (R)   │ │ │ │ ClickHouse (R)   │ │
│ └──────────────────┘ │ │ └──────────────────┘ │ │ └──────────────────┘ │
│                      │ │                      │ │                      │
│ Traffic: 70%         │ │ Traffic: 15%         │ │ Traffic: 15%         │
└──────────┬───────────┘ └──────────┬───────────┘ └──────────┬───────────┘
           │                        │                        │
           └────────────────────────┼────────────────────────┘
                                    │
                    ┌───────────────▼───────────────┐
                    │   Cross-Region Replication     │
                    │   • DragonflyDB: Async (ms)    │
                    │   • YugabyteDB: Sync (Raft)    │
                    │   • ClickHouse: Async (min)    │
                    └───────────────────────────────┘
```

### 3.2 Strategic Target Architecture (December 2027)

The strategic target extends the Phase 2 architecture with:

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                         STRATEGIC ADDITIONS (Phase 3+)                                │
│                                                                                       │
│  ┌───────────────────────┐  ┌───────────────────────┐  ┌──────────────────────────┐ │
│  │ Multi-Operator        │  │ International          │  │ Blockchain Audit         │ │
│  │ Tenant Isolation      │  │ Fraud Intelligence     │  │ Trail                    │ │
│  │                       │  │ Exchange               │  │                          │ │
│  │ • Per-tenant configs  │  │ • GSMA FMG feed        │  │ • Immutable evidence     │ │
│  │ • Isolated data       │  │ • i3Forum integration  │  │ • Regulatory proof       │ │
│  │ • Shared detection    │  │ • Cross-border alerts  │  │ • Settlement disputes    │ │
│  │ • Consolidated billing│  │ • Threat intelligence  │  │ • Smart contract audit   │ │
│  └───────────────────────┘  └───────────────────────┘  └──────────────────────────┘ │
│                                                                                       │
│  ┌───────────────────────┐  ┌───────────────────────┐  ┌──────────────────────────┐ │
│  │ Advanced AI/ML        │  │ Real-Time Streaming    │  │ Autonomous Response      │ │
│  │ Models                │  │ Analytics              │  │ Engine                   │ │
│  │                       │  │                        │  │                          │ │
│  │ • Deep learning fraud │  │ • Apache Kafka Streams │  │ • Auto-mitigation        │ │
│  │ • Graph neural nets   │  │ • Real-time dashboards │  │ • Policy-driven actions  │ │
│  │ • Federated learning  │  │ • Complex event proc   │  │ • AIDD-governed          │ │
│  │ • Adversarial defense │  │ • Predictive alerts    │  │ • Human override         │ │
│  └───────────────────────┘  └───────────────────────┘  └──────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

### 3.3 Target State Capability Matrix

| Capability | Phase 1 (Jun 2026) | Phase 2 (Oct 2026) | Phase 3 (Jun 2027) | Strategic (Dec 2027) |
|-----------|--------------------|--------------------|--------------------|--------------------|
| CLI Masking Detection | Full | Full + ML | Full + Deep Learning | Adversarial-Resistant |
| SIM-Box Detection | Full | Full + ML | Graph-Based | Federated Learning |
| Wangiri Detection | Basic | Full + ML | Full | Full |
| IRSF Detection | Basic | Full (GSMA feed) | Cross-Border | International Network |
| Traffic Anomaly | Rule-Based | Statistical + ML | Predictive | Autonomous Response |
| NCC Compliance | Automated Reporting | Certified | Real-Time Dashboard | Blockchain Proof |
| Multi-Region | Single Region | 3 Regions | 3 Regions + Edge | West Africa Coverage |
| Multi-Operator | Single Tenant | Single Tenant | Multi-Tenant | SaaS Platform |
| Analytics | Basic Dashboards | OLAP + Trends | Streaming Analytics | Predictive Analytics |
| AI/ML Models | Rule Engine | Scoring Models | Deep Learning | Autonomous AI |
| International | None | GSMA Feed | i3Forum Integration | Global Network |
| Audit Trail | Database Logs | Immutable Logs | Blockchain-Backed | Smart Contract Audit |

---

## 4. Migration Path

### 4.1 Migration Phases

```
CURRENT STATE                   PHASE 1 TARGET               PHASE 2 TARGET
(Feb 2026)                      (Jun 2026)                   (Oct 2026)
┌────────────────┐              ┌────────────────┐           ┌────────────────┐
│ • Core engine  │   Sprint     │ • Full detect  │  Sprint   │ • ML pipeline  │
│ • Basic API    │   cycles     │ • ATRS integ   │  cycles   │ • Multi-region │
│ • Basic UI     │ ──────────>  │ • Prod-ready   │ ────────> │ • NCC certified│
│ • Single region│              │ • Single region│           │ • Full OLAP    │
│ • No ML        │              │ • No ML (yet)  │           │ • Advanced UI  │
└────────────────┘              └────────────────┘           └────────────────┘
                                                                     │
                                                                     │
                                STRATEGIC TARGET                     │
                                (Dec 2027)                           │
                                ┌────────────────┐                  │
                                │ • Multi-tenant │    Quarterly     │
                                │ • International│    releases      │
                                │ • Blockchain   │ <────────────────┘
                                │ • Advanced AI  │
                                │ • Autonomous   │
                                └────────────────┘
```

### 4.2 Phase 1 Migration Plan (February - June 2026)

| Sprint | Duration | Focus | Key Activities | Exit Criteria |
|--------|----------|-------|---------------|---------------|
| S1-S2 | 4 weeks | Foundation | Infrastructure hardening, CI/CD, database optimization, security audit | All environments operational, CI/CD green |
| S3-S4 | 4 weeks | Detection Completion | Wangiri detection, IRSF basic detection, traffic anomaly rules | All 5 fraud types detectable |
| S5-S6 | 4 weeks | NCC Integration | ATRS API integration, report generation, SFTP delivery, sandbox testing | NCC sandbox validation passed |
| S7-S8 | 4 weeks | Dashboard Enhancement | Advanced analytics views, compliance dashboards, alert workflows | Fraud analyst UAT passed |
| S9-S10 | 4 weeks | Production Hardening | Performance optimization, load testing (150K CPS), security penetration test | Performance and security benchmarks met |
| S11-S12 | 4 weeks | GA Deployment | Production deployment at first ICL, operational handover, monitoring setup | 30-day production stability |

### 4.3 Phase 2 Migration Plan (July - October 2026)

| Sprint | Duration | Focus | Key Activities | Exit Criteria |
|--------|----------|-------|---------------|---------------|
| S13-S14 | 4 weeks | ML Pipeline | Model training pipeline, feature store, model registry, A/B testing framework | ML pipeline operational in staging |
| S15-S16 | 4 weeks | ML Integration | Online inference integration with detection engine, fraud scoring API | 99.8% accuracy on validation set |
| S17-S18 | 4 weeks | Multi-Region Foundation | Second/third region provisioning, cross-region replication, failover testing | All 3 regions operational |
| S19-S20 | 4 weeks | Multi-Region GA & Certification | Traffic distribution, failover validation (RTO/RPO), NCC certification package | NCC certification submitted |

### 4.4 Migration Risk Mitigation

| Risk | Mitigation | Rollback Strategy |
|------|-----------|-------------------|
| Detection engine regression during enhancement | Feature flags for new detection types; parallel operation with old/new logic | Disable new detection via feature flag; revert to previous release |
| Database schema migration failures | Blue-green deployment with YugabyteDB online DDL; migration tested in staging | YugabyteDB supports online rollback; maintain backward-compatible schema |
| NCC ATRS integration failures | Dual-path: automated API + manual SFTP fallback; sandbox testing before production | Manual report generation and SFTP upload; operator compliance team on standby |
| Multi-region replication lag | DragonflyDB async replication with conflict resolution; YugabyteDB Raft consensus | Single-region operation (Lagos primary); manual failover if needed |

---

## 5. Technology Standards

### 5.1 Language Standards

| Language | Version | Usage | Coding Standards | Justification |
|----------|---------|-------|-----------------|---------------|
| **Rust** | Stable 1.75+ | Detection engine (30K lines) | `rustfmt` + `clippy`; zero `unsafe` in domain layer; `#[deny(clippy::all)]` | Zero-cost abstractions, memory safety without GC, predictable latency |
| **Go** | 1.22+ | Management API (11.5K lines) | `gofmt` + `golangci-lint`; interface-driven design; structured logging (slog) | Fast compilation, excellent concurrency, strong standard library, ecosystem maturity |
| **Python** | 3.11+ | ML pipeline (8.6K lines) | `ruff` + `mypy`; type hints required; `pytest` for testing | ML ecosystem (scikit-learn, PyTorch), data processing libraries, rapid prototyping |
| **TypeScript** | 5.0+ | Frontend dashboard | ESLint + Prettier; strict mode enabled; no `any` types | Type safety, IDE support, React ecosystem compatibility |
| **SQL** | ANSI SQL + extensions | Database queries | Parameterized queries only; no raw string concatenation; migration-managed schemas | Standard data access; YugabyteDB (PostgreSQL-compatible), ClickHouse SQL |

### 5.2 Framework Standards

| Framework | Version | Usage | Configuration |
|-----------|---------|-------|---------------|
| **Tokio** | 1.x | Rust async runtime | Multi-threaded runtime; work-stealing scheduler; io_uring on Linux |
| **Actix-Web** | 4.x | Rust HTTP framework (optional) | Used for health checks and internal APIs only |
| **Chi** | 5.x | Go HTTP router | Middleware chain: logging, auth, CORS, rate limiting |
| **GORM** | 2.x | Go ORM | AutoMigrate disabled in production; explicit migrations only |
| **FastAPI** | 0.100+ | Python API framework | Async endpoints; Pydantic v2 models; OpenAPI documentation |
| **React** | 18+ | Frontend UI library | Strict mode; concurrent features enabled |
| **Refine** | 4.x | React admin framework | Data provider: Hasura GraphQL; auth provider: custom JWT |
| **Ant Design** | 5.x | React UI components | Custom theme tokens; dark mode support |

### 5.3 Database Standards

| Database | Version | Role | Configuration Standards |
|----------|---------|------|----------------------|
| **DragonflyDB** | 1.x | Hot cache, session store, rate limiting | Cluster mode for HA; maxmemory-policy: allkeys-lfu; persistence: append-only |
| **ClickHouse** | 24.x | OLAP analytics, historical queries | ReplicatedMergeTree engine; TTL-based partitioning; materialized views for common aggregations |
| **YugabyteDB** | 2.x | ACID transactions, relational data | RF=3 across 3 regions; YSQL (PostgreSQL-compatible); connection pooling via PgBouncer |
| **S3-Compatible** | - | Cold archival storage (7-year) | AES-256 encryption at rest; versioning enabled; lifecycle policies for cost optimization |

### 5.4 Infrastructure Standards

| Component | Technology | Version | Standard |
|-----------|-----------|---------|----------|
| Container Runtime | Kubernetes | 1.28+ | Managed Kubernetes; namespace isolation per environment; resource quotas enforced |
| Package Management | Helm | 3.x | All deployments via Helm charts; values files per environment; no `kubectl apply` in production |
| GitOps | ArgoCD | 2.x | Declarative deployments; automated sync for staging; manual sync for production |
| CI/CD | GitHub Actions | - | Required checks: lint, test, security scan, build; branch protection on main |
| Secrets | HashiCorp Vault | Enterprise | Transit engine for encryption; auto-unseal; audit logging enabled |
| Observability | Prometheus + Grafana | - | Prometheus for metrics; Grafana for dashboards; Loki for logs; Tempo for traces |
| Tracing | OpenTelemetry | 1.x | Instrumentation in all services; W3C trace context propagation; 10% sampling in production |
| GraphQL Gateway | Hasura | v2 | Role-based permissions; real-time subscriptions; remote schemas for custom resolvers |
| Service Mesh | - | N/A | Not required in Phase 1/2; evaluate Istio/Linkerd for Phase 3 multi-tenant |
| Message Queue | - | N/A | Direct inter-service communication via gRPC; evaluate Kafka for Phase 3 streaming |

### 5.5 Protocol Standards

| Protocol | Standard | Usage | Requirements |
|----------|----------|-------|-------------|
| **SIP** | RFC 3261 | Voice switch integration | TLS for signaling; SIP event parsing for call metadata extraction |
| **SIGTRAN** | RFC 4666 (M3UA) | SS7 over IP integration | For legacy interconnect switches still using SS7 signaling |
| **gRPC** | - | Inter-service communication | Protobuf schemas; mutual TLS; deadline propagation |
| **GraphQL** | October 2021 Spec | Frontend data access | Via Hasura; subscriptions for real-time updates |
| **REST** | OpenAPI 3.1 | External API exposure | JSON payloads; API versioning in URL path; rate limiting |
| **SFTP** | SSH File Transfer | NCC report delivery | Key-based authentication; automated upload scheduling |

---

## 6. Integration Points

### 6.1 Voice Switch Integration

#### 6.1.1 Class 4 Switches (Transit/Tandem)

| Switch Vendor | Protocol | Integration Method | Data Extracted |
|--------------|----------|-------------------|----------------|
| **Kamailio** | SIP + MI/RPC | Event Route + JSON-RPC (`dlg.end_dlg`) | Call-ID, From (A-number), To (B-number), Source IP, Timestamp |
| **OpenSIPS** | SIP + MI | Event Route + MI (`dlg_end_dlg`) | Call-ID, From, To, Source IP, Timestamp, Route Set |
| **FreeSWITCH** | SIP + ESL | Event Socket Layer (TCP 8021) | Call UUID, Caller-ID, Destination, Source IP, Channel Variables |
| **Generic SIP** | SIP (RFC 3261) | SIP INVITE inspection via proxy | Standard SIP headers per RFC 3261 |

#### 6.1.2 Class 5 Switches (Access/Subscriber)

| Integration Point | Method | Purpose |
|------------------|--------|---------|
| CDR Export | Periodic file transfer (CSV/ASN.1) | Historical analysis, ML training data |
| Real-Time Events | SIP event hooks | Call setup/teardown notifications |
| Call Control | SIP BYE injection | Fraudulent call disconnection |

#### 6.1.3 Integration Data Flow

```
Voice Switch                    VoxGuard Detection Engine
     │                                    │
     │  1. SIP INVITE received            │
     │──────────────────────────────────> │
     │     (A-number, B-number,           │
     │      Source IP, Call-ID)           │
     │                                    │
     │                                    │  2. Validate CLI
     │                                    │     Check DragonflyDB cache
     │                                    │     Check MNP database
     │                                    │     Run sliding window
     │                                    │     Compute fraud score
     │                                    │
     │  3a. ALLOW (score < threshold)     │
     │ <───────────────────────────────── │
     │     (< 1ms total)                  │
     │                                    │
     │  3b. BLOCK (score >= threshold)    │
     │ <───────────────────────────────── │
     │     SIP 403 Forbidden              │
     │                                    │
     │  3c. FLAG (score in gray zone)     │
     │ <───────────────────────────────── │
     │     ALLOW + create alert           │
```

### 6.2 NCC ATRS Integration

| Report Type | Method | Frequency | Format | Endpoint |
|-------------|--------|-----------|--------|----------|
| Daily Statistics | ATRS REST API + SFTP | Daily by 06:00 WAT | CSV + JSON | `POST /api/v1/reports/daily` |
| Weekly Summary | ATRS REST API | Weekly (Monday 12:00 WAT) | JSON | `POST /api/v1/reports/weekly` |
| Monthly Compliance | ATRS REST API + Portal | Monthly (5th of month) | JSON + PDF | `POST /api/v1/reports/monthly` |
| Incident Report | ATRS REST API | Per event (within 4 hours for critical) | JSON | `POST /api/v1/incidents` |
| Annual Compliance | NCC Portal | Annual (January 31st) | PDF + attachments | Manual portal upload |

### 6.3 MNP Database Integration

| Aspect | Specification |
|--------|--------------|
| **Protocol** | REST API over mTLS |
| **Lookup Latency** | Target: <5ms; SLA: <10ms P99 |
| **Caching Strategy** | Local DragonflyDB cache with 24-hour TTL; cache-aside pattern |
| **Fallback** | If MNP unavailable, flag as "MNP_UNVERIFIED" and allow with reduced confidence |
| **Data** | Number range, current operator, porting date, porting status |
| **Update Frequency** | Real-time for individual lookups; daily bulk sync for cache warming |

### 6.4 Operator BSS/OSS Integration

| System | Integration | Protocol | Data |
|--------|------------|----------|------|
| Billing System | CDR reconciliation | REST API / File Transfer | Call charges, settlements, adjustments |
| CRM | Fraud case escalation | Webhook notifications | Alert details, affected subscribers |
| Trouble Ticketing | Incident creation | REST API (ServiceNow/Remedy) | Fraud incidents, severity, resolution tracking |
| Network Inventory | Gateway registration | REST API | Gateway metadata, IP ranges, capacity |
| Settlement System | Dispute management | REST API | Fraud-impacted calls, financial impact |

### 6.5 Integration Architecture Patterns

| Pattern | Used For | Implementation |
|---------|----------|---------------|
| **Synchronous Request-Response** | CLI validation, MNP lookup, fraud scoring | gRPC (internal), REST (external) |
| **Event-Driven** | Alert propagation, audit logging, NCC notifications | Domain events via internal event bus |
| **File Transfer** | CDR ingestion, NCC SFTP reports, bulk MNP import | SFTP + S3-compatible storage |
| **Cache-Aside** | MNP data, gateway metadata, blacklists | DragonflyDB with configurable TTL |
| **Circuit Breaker** | External service calls (MNP, NCC, BSS) | Resilience4j pattern; fallback to cached/degraded |

---

## 7. Data Architecture

### 7.1 Data Tier Model

```
┌─────────────────────────────────────────────────────────────────────┐
│                        HOT TIER (0-24 hours)                        │
│                          DragonflyDB                                │
│                                                                     │
│  Purpose: Real-time detection state, session management             │
│  Latency: <0.1ms reads, <0.2ms writes                              │
│  Capacity: 128GB per node (3 nodes)                                 │
│  Data:                                                              │
│    • Sliding window counters (5s, 30s, 60s windows)                │
│    • Active session state (call-in-progress tracking)               │
│    • MNP cache (24h TTL, ~50M entries)                              │
│    • Gateway blacklist (real-time sync)                              │
│    • Rate limiting counters                                         │
│    • Detection result cache (5m TTL)                                │
│                                                                     │
│  Eviction: LFU (Least Frequently Used)                              │
│  Replication: Async to Abuja/Asaba replicas                         │
│  Hit Rate Target: >99%                                              │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ Materialized (async)
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      WARM TIER (1-90 days)                          │
│                         YugabyteDB + ClickHouse                     │
│                                                                     │
│  YugabyteDB (ACID, transactional):                                 │
│    • Fraud alerts (active, under investigation)                     │
│    • Gateway configurations and metadata                            │
│    • User accounts, roles, permissions                              │
│    • NCC compliance reports (pending, submitted)                    │
│    • Settlement disputes                                            │
│    • Audit log entries (recent)                                     │
│    Latency: <5ms reads, <10ms writes                                │
│    Replication: Raft consensus (3 regions)                          │
│                                                                     │
│  ClickHouse (OLAP, analytical):                                    │
│    • CDR records (aggregated and detail)                            │
│    • Detection event time series                                    │
│    • Performance metrics history                                    │
│    • Fraud pattern analytics                                        │
│    • Traffic volume statistics                                      │
│    Latency: <100ms for aggregation queries                          │
│    Compression: ~10:1 ratio with LZ4                                │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ Monthly archival job (1st of month, 02:00 WAT)
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      COLD TIER (90 days - 7 years)                  │
│                      S3-Compatible Object Storage                   │
│                                                                     │
│  Purpose: NCC-mandated 7-year retention                             │
│  Format: Parquet (compressed, columnar)                             │
│  Compression: ZSTD (~75% size reduction)                            │
│  Integrity: SHA-256 checksum per archive file                       │
│  Encryption: AES-256 at rest                                        │
│  Access: Read-only restore to ClickHouse for historical queries     │
│                                                                     │
│  Data Archived:                                                     │
│    • CDR records older than 90 days                                 │
│    • Resolved fraud alerts older than 90 days                       │
│    • Submitted NCC reports                                          │
│    • Detection event history                                        │
│    • System metrics history                                         │
│                                                                     │
│  Lifecycle:                                                         │
│    90 days - 1 year:  Standard storage                              │
│    1 year - 3 years:  Infrequent access                             │
│    3 years - 7 years: Archive storage                               │
│    >7 years:          Auto-deleted (NDPA compliance)                │
└─────────────────────────────────────────────────────────────────────┘
```

### 7.2 Data Flow Architecture

| Data Flow | Source | Destination | Protocol | Latency Target | Volume |
|-----------|--------|-------------|----------|---------------|--------|
| SIP Event Ingestion | Voice Switches | Detection Engine (Rust) | SIP/gRPC | <0.5ms | 150K events/sec |
| Detection State Write | Detection Engine | DragonflyDB | Redis Protocol | <0.1ms | 150K ops/sec |
| Alert Persistence | Detection Engine | YugabyteDB | PostgreSQL | <5ms | ~100 alerts/sec |
| Analytics Ingestion | Detection Engine | ClickHouse | HTTP Batch Insert | <1s (batched) | 150K rows/sec |
| GraphQL Queries | Dashboard | Hasura -> YugabyteDB | GraphQL | <50ms | ~1K queries/sec |
| ML Feature Extraction | ClickHouse | ML Pipeline | SQL Query | <5s | Batch (hourly) |
| NCC Report Generation | YugabyteDB + ClickHouse | ATRS API | REST + SFTP | N/A | Daily/Weekly/Monthly |
| Archival | YugabyteDB + ClickHouse | S3 Cold Storage | S3 API | N/A | Monthly batch |

### 7.3 Data Retention Policy

| Data Category | Hot (DragonflyDB) | Warm (YugabyteDB/ClickHouse) | Cold (S3) | Total Retention |
|--------------|-------------------|------------------------------|-----------|-----------------|
| Sliding Window State | 5s-60s | N/A | N/A | Real-time only |
| Active Sessions | Duration of call | N/A | N/A | Call duration |
| Fraud Alerts | 24 hours (cache) | 90 days (active) | 7 years | 7 years |
| CDR Records | N/A | 90 days (detail) | 7 years | 7 years |
| Audit Logs | N/A | 90 days (queryable) | 7 years | 7 years |
| NCC Reports | N/A | 1 year (active) | 7 years | 7 years |
| ML Training Data | N/A | 1 year | 3 years | 3 years |
| Performance Metrics | 24 hours (cache) | 90 days (Prometheus) | 1 year | 1 year |
| Gateway Metadata | Indefinite (cache) | Indefinite (source of truth) | N/A | Platform lifetime |
| User Data | Session duration | Active + 90 days post-deletion | 7 years (audit) | 7 years (audit) |

### 7.4 Data Sovereignty

All data processing and storage is confined to Nigerian territory:

| Region | Facility | Data Stored | Backup Location |
|--------|----------|-------------|-----------------|
| Lagos | MDXi Lekki Data Center | Primary copy of all data | Abuja, Asaba |
| Abuja | Galaxy Backbone | Read replica, regional analytics | Lagos (reverse replication) |
| Asaba | Regional Data Center | DR replica, archival storage | Lagos (reverse replication) |

Cross-border data transfer is prohibited except for:
- Aggregated, anonymized fraud statistics shared with GSMA (NDPA-compliant)
- International fraud intelligence feeds (received, not shared)

---

## 8. Security Architecture

### 8.1 Security Architecture Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│                        SECURITY PERIMETER                             │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ WAF + DDoS Protection (Layer 7)                              │   │
│  └──────────────────────┬───────────────────────────────────────┘   │
│                          │                                           │
│  ┌──────────────────────▼───────────────────────────────────────┐   │
│  │ API Gateway (Rate Limiting, IP Allowlisting)                 │   │
│  └──────────────────────┬───────────────────────────────────────┘   │
│                          │                                           │
│  ┌──────────────────────▼───────────────────────────────────────┐   │
│  │ Authentication Layer                                         │   │
│  │                                                              │   │
│  │  • RS256 JWT (asymmetric signing)                            │   │
│  │  • Refresh token rotation (7-day lifetime)                   │   │
│  │  • MFA support (TOTP)                                        │   │
│  │  • Session management (DragonflyDB)                          │   │
│  └──────────────────────┬───────────────────────────────────────┘   │
│                          │                                           │
│  ┌──────────────────────▼───────────────────────────────────────┐   │
│  │ Authorization Layer (RBAC)                                   │   │
│  │                                                              │   │
│  │  Roles: SYSTEM_ADMIN, COMPLIANCE_OFFICER, FRAUD_ANALYST,     │   │
│  │         NOC_ENGINEER, VIEWER, API_SERVICE                    │   │
│  │                                                              │   │
│  │  Enforcement: Hasura role-based permissions + Go middleware   │   │
│  └──────────────────────┬───────────────────────────────────────┘   │
│                          │                                           │
│  ┌──────────────────────▼───────────────────────────────────────┐   │
│  │ Service-to-Service Security                                  │   │
│  │                                                              │   │
│  │  • mTLS for all internal communication                       │   │
│  │  • Certificate rotation via Vault PKI                        │   │
│  │  • Service identity verification                             │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ Data Security                                                │   │
│  │                                                              │   │
│  │  • Encryption at rest: AES-256 (databases, S3 archives)      │   │
│  │  • Encryption in transit: TLS 1.3 (all connections)          │   │
│  │  • Field-level encryption: PII fields via Vault Transit      │   │
│  │  • Key management: HashiCorp Vault auto-unseal               │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ Audit & Compliance                                           │   │
│  │                                                              │   │
│  │  • Immutable audit logs (append-only, SHA-256 chain)         │   │
│  │  • 7-year retention in tamper-evident storage                 │   │
│  │  • AIDD tier logging for all operations                      │   │
│  │  • Real-time audit stream to SIEM                            │   │
│  └──────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
```

### 8.2 Authentication & Authorization

| Aspect | Implementation | Standard |
|--------|---------------|----------|
| **JWT Signing** | RS256 (RSA-SHA256, 2048-bit key) | RFC 7519 |
| **Token Lifetime** | Access: 15 minutes; Refresh: 7 days | OWASP Guidelines |
| **Key Storage** | Private key in HashiCorp Vault; public key distributed | Vault Transit Engine |
| **MFA** | TOTP (RFC 6238) with backup codes | Required for SYSTEM_ADMIN and COMPLIANCE_OFFICER roles |
| **Password Policy** | 12+ chars, complexity requirements, bcrypt (cost=12) | NIST SP 800-63B |
| **RBAC** | 6 predefined roles with granular permissions | Hasura role-based permissions + Go middleware |
| **API Keys** | HMAC-SHA256 signed, scope-limited, rotatable | For service-to-service (BSS/OSS integration) |

### 8.3 RBAC Role Matrix

| Permission | SYSTEM_ADMIN | COMPLIANCE_OFFICER | FRAUD_ANALYST | NOC_ENGINEER | VIEWER | API_SERVICE |
|-----------|:---:|:---:|:---:|:---:|:---:|:---:|
| View dashboards | Yes | Yes | Yes | Yes | Yes | No |
| View alerts | Yes | Yes | Yes | Yes | Yes | Yes (own scope) |
| Manage alerts | Yes | Yes | Yes | No | No | No |
| Block gateway | Yes | No | Yes | No | No | No |
| Submit NCC report | Yes | Yes | No | No | No | No |
| Manage users | Yes | No | No | No | No | No |
| System configuration | Yes | No | No | Yes (limited) | No | No |
| View audit logs | Yes | Yes | No | No | No | No |
| API access | Yes | Yes | Yes | Yes | No | Yes |
| AIDD Tier 2 operations | Yes | No | No | No | No | No |

### 8.4 Network Security

| Layer | Control | Implementation |
|-------|---------|---------------|
| Perimeter | WAF + DDoS protection | Cloud WAF with Nigerian-specific rule set |
| Transport | TLS 1.3 minimum | All external and internal connections |
| Internal | mTLS between services | Vault PKI-issued certificates, 24-hour rotation |
| Database | Network isolation | Private subnets, security group rules, no public access |
| Kubernetes | Network policies | Namespace isolation, pod-to-pod restrictions, egress filtering |
| Monitoring | IDS/IPS | Network traffic analysis for anomalous patterns |

### 8.5 Threat Model Summary

| Threat | Attack Vector | Control | Residual Risk |
|--------|--------------|---------|---------------|
| Unauthorized API access | Credential theft, brute force | JWT + MFA + rate limiting + IP allowlist | Low |
| Data exfiltration | Compromised service, insider threat | Encryption at rest, RBAC, audit logging, DLP | Low |
| Man-in-the-middle | Network interception | mTLS everywhere, certificate pinning | Very Low |
| Injection attacks | SQL injection, XSS, command injection | Parameterized queries, CSP headers, input validation | Very Low |
| Denial of service | Volumetric DDoS, application-layer attack | WAF, rate limiting, auto-scaling, geographic filtering | Low |
| Privilege escalation | Exploiting authorization flaws | RBAC enforcement at API gateway and database, least privilege | Low |

---

## 9. Scalability Plan

### 9.1 Horizontal Scaling Architecture

```
                    Load Balancer (Layer 4)
                           │
              ┌────────────┼────────────┐
              │            │            │
        ┌─────▼─────┐ ┌───▼─────┐ ┌───▼─────┐
        │ Detection  │ │Detection│ │Detection│    Stateless
        │ Engine #1  │ │Engine #2│ │Engine #N│    Scale Out
        └─────┬──────┘ └───┬─────┘ └───┬─────┘
              │            │            │
              └────────────┼────────────┘
                           │
                    DragonflyDB Cluster
                    (Shared State)
```

### 9.2 Scaling Dimensions

| Component | Scaling Strategy | Current Capacity | Max Capacity | Scaling Trigger |
|-----------|-----------------|-----------------|--------------|-----------------|
| **Detection Engine** | Horizontal (stateless pods) | 4 pods = 150K CPS | 16 pods = 600K CPS | CPU >70% or CPS per pod >40K |
| **Management API** | Horizontal (stateless pods) | 3 pods | 12 pods | Request latency P99 >100ms or error rate >0.1% |
| **ML Inference** | Horizontal (GPU-optional pods) | 2 pods | 8 pods | Inference latency P99 >10ms |
| **DragonflyDB** | Vertical (memory) + horizontal (cluster) | 3 nodes x 128GB | 9 nodes x 256GB | Memory usage >80% or hit rate <99% |
| **YugabyteDB** | Horizontal (add nodes) | 3 nodes (RF3) | 9 nodes (RF3) | Write latency P99 >50ms or storage >70% |
| **ClickHouse** | Horizontal (add shards) | 3 nodes | 12 nodes (4 shards x 3 replicas) | Query latency >5s for standard aggregations |
| **Hasura** | Horizontal (stateless pods) | 2 pods | 8 pods | GraphQL response time P99 >200ms |
| **Dashboard** | Horizontal (CDN + pods) | 2 pods + CDN | 4 pods + CDN | N/A (frontend is CDN-served) |

### 9.3 Auto-Scaling Configuration

| Component | Metric | Scale Up Threshold | Scale Down Threshold | Cooldown | Min Pods | Max Pods |
|-----------|--------|-------------------|---------------------|----------|----------|----------|
| Detection Engine | CPU Utilization | >70% for 2 min | <30% for 10 min | 3 min | 4 | 16 |
| Management API | Request Rate | >5000 req/s per pod | <1000 req/s per pod | 5 min | 3 | 12 |
| ML Inference | Inference Latency | P99 >10ms for 5 min | P99 <3ms for 15 min | 10 min | 2 | 8 |

### 9.4 Capacity Planning (18-Month Projection)

| Quarter | Projected CPS | Detection Pods | DragonflyDB Nodes | YugabyteDB Nodes | ClickHouse Nodes |
|---------|--------------|----------------|-------------------|-------------------|------------------|
| Q1 2026 | 100K | 4 | 3 | 3 | 3 |
| Q2 2026 | 150K | 4 | 3 | 3 | 3 |
| Q3 2026 | 175K | 6 | 3 | 3 | 3 |
| Q4 2026 | 200K | 6 | 6 | 3 | 6 |
| Q1 2027 | 250K | 8 | 6 | 6 | 6 |
| Q2 2027 | 300K | 10 | 6 | 6 | 9 |

### 9.5 Multi-Region Scaling

| Region | Role | Traffic Share | Failover Priority | Resources |
|--------|------|--------------|-------------------|-----------|
| Lagos | Primary | 70% | N/A (primary) | Full stack: 4x detection, 3x API, primary databases |
| Abuja | Active Replica | 15% | First failover target | Reduced: 2x detection, 2x API, read replicas |
| Asaba | DR + Active Replica | 15% | Second failover target | Reduced: 2x detection, 2x API, read replicas |

**Failover Procedure:**
1. Health check failure detected on primary region (3 consecutive failures, 10-second interval)
2. DNS weight shifted to Abuja (100% traffic) within 30 seconds
3. Abuja YugabyteDB promoted to primary via Raft leader election
4. DragonflyDB in Abuja becomes writable
5. Asaba begins receiving 20% traffic from Abuja
6. Estimated total failover time: <30 seconds for DNS, <15 minutes for full database promotion

---

## 10. Future Capabilities

### 10.1 AI/ML Roadmap

| Phase | Timeline | Capability | Model Type | Training Data | Expected Impact |
|-------|----------|-----------|------------|---------------|-----------------|
| **ML v1** | Aug 2026 | Fraud scoring (supervised) | Gradient boosted trees (XGBoost) | 6 months CDR + labeled fraud data | 99.8% accuracy, replace manual thresholds |
| **ML v2** | Jan 2027 | Anomaly detection (unsupervised) | Isolation Forest + Autoencoders | 12 months traffic patterns | Detect novel fraud patterns, reduce FN by 50% |
| **ML v3** | Jun 2027 | Deep learning fraud detection | LSTM/Transformer for sequence modeling | Full historical dataset | Temporal pattern recognition, predictive alerting |
| **ML v4** | Dec 2027 | Graph-based fraud networks | Graph Neural Networks (GNN) | Call graph + gateway relationships | Detect organized fraud rings and SIM farm networks |
| **ML v5** | 2028 | Federated learning | Federated averaging across operators | Multi-operator (privacy-preserving) | Cross-operator fraud intelligence without data sharing |

#### ML Model Lifecycle

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│  Train   │──>│ Evaluate │──>│ Register │──>│  Deploy  │──>│ Monitor  │
│          │   │          │   │          │   │          │   │          │
│ Offline  │   │ Accuracy │   │ Model    │   │ Canary   │   │ Drift    │
│ Pipeline │   │ >99.8%   │   │ Registry │   │ Rollout  │   │ Detection│
└──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘
      ▲                                                           │
      │                     Feedback Loop                         │
      └───────────────────────────────────────────────────────────┘
```

### 10.2 Real-Time Analytics Roadmap

| Phase | Timeline | Capability | Technology | Use Case |
|-------|----------|-----------|------------|----------|
| **Analytics v1** | Sep 2026 | OLAP dashboards | ClickHouse + Grafana | Historical trend analysis, monthly KPI reporting |
| **Analytics v2** | Mar 2027 | Streaming analytics | Apache Kafka Streams | Real-time fraud trend monitoring, live dashboards |
| **Analytics v3** | Sep 2027 | Complex event processing | Apache Flink | Multi-event pattern detection, predictive alerting |
| **Analytics v4** | 2028 | Predictive analytics | Custom ML models | Fraud volume prediction, capacity planning, risk scoring |

### 10.3 Blockchain Audit Trail Roadmap

| Phase | Timeline | Capability | Technology | Benefit |
|-------|----------|-----------|------------|---------|
| **Blockchain v1** | Q2 2027 | Audit log anchoring | Hyperledger Fabric (permissioned) | Tamper-evident proof of audit log integrity |
| **Blockchain v2** | Q4 2027 | Smart contract audit | Hyperledger Fabric chaincode | Automated compliance verification, dispute resolution |
| **Blockchain v3** | 2028 | Cross-operator audit | Multi-org Hyperledger network | Shared fraud evidence with cryptographic proof |

### 10.4 Additional Future Capabilities

| Capability | Timeline | Description | Business Value |
|-----------|----------|-------------|---------------|
| **SMS Fraud Detection** | Q1 2027 | Extend platform to detect A2P fraud, SMS spoofing, grey routes | New revenue stream; regulatory requirement likely by 2028 |
| **Voice Biometrics** | Q3 2027 | Speaker verification for high-value call authentication | Premium feature for financial institution interconnects |
| **5G Integration** | 2028 | Support for 5G voice (VoNR) and network slicing | Future-proof platform as Nigerian 5G deployment progresses |
| **West Africa Expansion** | Q2 2027 | Ghana (NCA), Kenya (CA) regulatory integration | Regional market expansion; 3x addressable market |
| **Managed Service Offering** | Q1 2027 | SaaS deployment with shared infrastructure | Lower barrier to entry for smaller ICL operators |
| **API Marketplace** | Q3 2027 | Expose fraud intelligence as a service via API | Additional revenue stream; ecosystem building |

### 10.5 Technology Evolution Considerations

| Current Technology | Potential Evolution | Trigger | Timeline |
|-------------------|--------------------|---------|---------|
| DragonflyDB | Redis Cluster (if DragonflyDB licensing changes) | Licensing/pricing change | Monitored |
| ClickHouse | Apache Doris or StarRocks (if performance gaps) | Query performance at scale | Evaluate Q4 2026 |
| YugabyteDB | CockroachDB (if geo-distribution gaps) | Multi-region consistency issues | Monitored |
| Hasura v2 | Hasura v3 or Apollo Federation | Feature requirements, vendor direction | Evaluate Q2 2027 |
| Kubernetes | Nomad (if complexity exceeds value) | Operational burden | Monitored |
| gRPC | Connect-RPC (gRPC-compatible, browser-native) | Frontend-to-backend gRPC needs | Evaluate Q3 2026 |

---

## 11. AIDD Integration Points

### 11.1 AIDD in Architecture Decisions

The AIDD governance framework integrates with the architecture at the following points:

| Architecture Layer | AIDD Integration | Implementation |
|-------------------|-----------------|----------------|
| **API Gateway** | Tier enforcement on all API endpoints | Go middleware reads operation tier from route metadata; enforces confirmation/approval headers |
| **Detection Engine** | Auto-blocking rate limits | Circuit breaker: max 100 auto-blocks/hour (Tier 1); all blocking beyond threshold requires human Tier 1 confirmation |
| **GraphQL Gateway** | Mutation-level tier classification | Hasura permissions encode AIDD tiers; Tier 2 mutations require admin role + approval header |
| **Frontend Dashboard** | Visual tier indicators | Tier 0: no badge; Tier 1: yellow "Confirm" badge with dialog; Tier 2: red "Admin Approval" badge with reason textarea |
| **CI/CD Pipeline** | Deployment tier classification | Tier 0: docs/tests auto-merge; Tier 1: feature PRs require review; Tier 2: infra/auth PRs require admin approval |
| **Audit System** | Tier-tagged audit entries | Every operation logged with: `{actor, action, tier, timestamp, justification, reversible}` |
| **Observability** | Tier distribution monitoring | Grafana dashboard showing T0/T1/T2 action distribution; alerts on anomalous T2 volumes |

### 11.2 AIDD-Governed Autonomous Operations

| Operation | AIDD Tier | Automation Level | Human Involvement |
|-----------|-----------|------------------|-------------------|
| Traffic monitoring and dashboard updates | T0 | Fully autonomous | None (read-only) |
| Alert generation from detection engine | T0 | Fully autonomous | None (informational) |
| Performance auto-scaling | T0 | Fully autonomous | Notified; can override |
| Individual gateway blocking (fraud score >= 0.95) | T1 | Semi-autonomous | Analyst reviews within 1 hour; can reverse |
| Detection threshold adjustment | T1 | Manual with suggestion | AI suggests; human confirms |
| NCC report generation (draft) | T1 | Semi-autonomous | Compliance officer reviews before submission |
| NCC report submission (to ATRS) | T2 | Manual only | Admin approval with documented reason |
| Database migration execution | T2 | Manual only | Admin approval + staged rollout |
| User role/permission changes | T2 | Manual only | Admin approval + audit log |
| Bulk gateway operations | T2 | Manual only | Admin approval + impact assessment |

### 11.3 AIDD Architecture Decision Records

All architecture decisions are classified by AIDD tier:

| ADR Category | Tier | Governance |
|-------------|------|-----------|
| Documentation and standard updates | T0 | Auto-approved; version controlled |
| Technology selection for non-critical components | T1 | Architecture Board review |
| Core technology changes (language, database, framework) | T2 | Steering Committee approval |
| Security architecture changes | T2 | Security Architect + Admin approval |
| Data architecture changes (retention, sovereignty) | T2 | Compliance + Admin approval |
| Integration pattern changes | T1 | Architecture Board review |

---

## 12. Architecture Governance

### 12.1 Architecture Review Board

| Member | Role | Responsibility |
|--------|------|---------------|
| CTO | Chair | Final architecture decisions, technology strategy |
| Engineering Lead (Rust) | Member | Detection engine architecture, performance |
| Engineering Lead (Go) | Member | Management API architecture, integration patterns |
| ML Lead | Member | ML pipeline architecture, model deployment |
| Security Architect | Member | Security architecture, threat modeling |
| DevOps Lead | Member | Infrastructure architecture, deployment |
| Compliance Lead | Advisory | Regulatory impact of architecture decisions |

### 12.2 Architecture Review Process

1. **Architecture Decision Record (ADR):** All significant decisions documented as ADRs in `docs/adr/` directory.
2. **Review Trigger:** Any change to bounded context boundaries, data store selection, integration patterns, or security controls.
3. **Review Cadence:** Bi-weekly Architecture Review Board meetings; ad-hoc for urgent decisions.
4. **Decision Criteria:** Performance impact, security implications, compliance requirements, maintenance burden, vendor risk, AIDD tier classification.

### 12.3 Technology Radar

| Quadrant | Technology | Status | Notes |
|----------|-----------|--------|-------|
| **Adopt** | Rust (detection), Go (API), Python (ML), React/TypeScript (UI) | In use | Core stack; stable |
| **Adopt** | DragonflyDB, ClickHouse, YugabyteDB | In use | Data tier; proven |
| **Adopt** | Hasura, Kubernetes, Vault, Prometheus/Grafana | In use | Infrastructure; stable |
| **Trial** | Apache Kafka Streams | Planned Q1 2027 | Streaming analytics |
| **Trial** | Hyperledger Fabric | Planned Q2 2027 | Blockchain audit trail |
| **Trial** | Graph Neural Networks | Planned Q2 2027 | Fraud network detection |
| **Assess** | Apache Flink | Evaluate Q3 2027 | Complex event processing |
| **Assess** | Service mesh (Istio/Linkerd) | Evaluate Q1 2027 | Multi-tenant isolation |
| **Assess** | WebAssembly (WASM) | Evaluate Q4 2027 | Edge detection engine |
| **Hold** | Microservice decomposition of detection engine | Deferred | Monolith-first approach for latency; evaluate when CPS >500K |

### 12.4 Compliance Alignment

This Enterprise Architecture Roadmap is maintained in alignment with:
- **NCC ICL Framework 2026:** All architecture decisions must support regulatory compliance.
- **NDPA 2023:** Data architecture must enforce Nigerian data sovereignty.
- **ISO 27001:** Security architecture controls mapped to ISO 27001 Annex A.
- **SOC 2 Type II:** Service organization controls integrated into architecture design.
- **AIDD Governance:** Architecture changes follow AIDD tiered approval process.

---

*This Enterprise Architecture Roadmap is a living document maintained under version control and subject to bi-annual review by the Architecture Review Board. Changes follow the AIDD governance framework defined in Section 11.*
