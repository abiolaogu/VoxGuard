# VoxGuard Project Charter

**Version:** 1.0
**Date:** February 12, 2026
**Status:** Approved
**Classification:** Confidential -- Internal Use Only
**AIDD Compliance:** Tier 0 (Documentation)

---

## Document Control

| Field | Value |
|-------|-------|
| Document ID | VG-CHR-2026-001 |
| Version | 1.0 |
| Author | VoxGuard Project Management Office |
| Approved By | Executive Steering Committee |
| Effective Date | February 12, 2026 |

### Revision History

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 0.1 | January 8, 2026 | PMO | Initial draft |
| 0.5 | January 22, 2026 | Steering Committee | Review comments incorporated |
| 1.0 | February 12, 2026 | Executive Sponsor | Final approval |

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Purpose & Justification](#2-purpose--justification)
3. [Objectives & Deliverables](#3-objectives--deliverables)
4. [Scope Statement](#4-scope-statement)
5. [Key Stakeholders](#5-key-stakeholders)
6. [High-Level Requirements](#6-high-level-requirements)
7. [Milestones](#7-milestones)
8. [Budget Summary](#8-budget-summary)
9. [Risks](#9-risks)
10. [Organizational Structure](#10-organizational-structure)
11. [Approval Authority](#11-approval-authority)
12. [AIDD Governance Framework](#12-aidd-governance-framework)
13. [Charter Acceptance](#13-charter-acceptance)

---

## 1. Project Overview

| Field | Detail |
|-------|--------|
| **Project Name** | VoxGuard -- Anti-Call Masking & Voice Network Fraud Detection Platform |
| **Project ID** | VG-2026-001 |
| **Project Sponsor** | BillyRonks Global, Executive Board |
| **Project Manager** | VoxGuard Platform Lead |
| **Start Date** | January 2, 2026 |
| **Target Completion** | October 31, 2026 (Phase 1 + Phase 2) |
| **Priority** | Critical -- Regulatory Deadline Driven |
| **Program Affiliation** | BillyRonks Global -- Telecom Fraud Prevention Program |

### 1.1 Project Summary

VoxGuard is an enterprise-grade Anti-Call Masking (ACM) and Voice Network Fraud Detection Platform designed for Nigerian Interconnect Clearing Houses (ICLs). The platform provides real-time detection and prevention of voice network fraud -- including CLI masking, SIM-box fraud, Wangiri schemes, International Revenue Share Fraud (IRSF), and traffic anomalies -- at carrier-grade scale (150,000+ calls per second) with sub-millisecond latency.

The project is driven by the NCC ICL Framework 2026, which mandates that all ICL license holders deploy certified fraud detection systems by Q3 2026. VoxGuard will be the first Nigerian-developed platform to meet these requirements while delivering performance that exceeds international benchmarks.

### 1.2 Project Sponsor Statement

> "VoxGuard represents a strategic investment in Nigeria's telecommunications integrity. By combining world-class engineering (Rust, Go, Python) with deep regulatory expertise, we are building a platform that protects both operator revenue and subscriber trust. This project is critical to BillyRonks Global's positioning as the definitive technology partner for Nigerian ICL operators."

---

## 2. Purpose & Justification

### 2.1 Business Problem

Nigerian telecommunications operators and ICLs face escalating losses from voice network fraud, estimated at $3.2 billion annually. Existing fraud detection solutions suffer from three fundamental limitations:

1. **Inadequate performance:** Legacy systems introduce 50-200ms detection latency, allowing fraudulent calls to connect and complete before detection occurs.
2. **Insufficient accuracy:** Rule-based systems produce 3-8% false positive rates, causing legitimate call blocking that damages operator reputation and subscriber experience.
3. **Manual compliance:** NCC reporting is performed manually by compliance teams, resulting in missed deadlines, incomplete data, and regulatory penalties.

### 2.2 Strategic Justification

| Justification Category | Description |
|----------------------|-------------|
| **Regulatory Compliance** | NCC ICL Framework 2026 mandates certified fraud detection for all ICL holders by Q3 2026. Non-compliance results in license suspension, effectively ending operations. |
| **Revenue Protection** | Each percentage point of fraud detection improvement translates to $30M-$50M in protected revenue across the Nigerian ICL ecosystem. |
| **Market Opportunity** | 14 licensed ICL operators require ACM solutions. No existing Nigerian-developed platform meets NCC 2026 requirements, creating a $45M-$60M addressable market. |
| **Competitive Moat** | VoxGuard's performance profile (150K CPS, <1ms P99, 99.8% accuracy) creates a significant technical barrier to competition from generic fraud detection vendors. |
| **National Interest** | Telecommunications fraud undermines Nigeria's digital economy goals. VoxGuard contributes to national infrastructure protection. |

### 2.3 Alignment with Organizational Strategy

| Strategic Goal | VoxGuard Contribution |
|---------------|----------------------|
| Become the leading telecom fraud prevention provider in West Africa | VoxGuard is the flagship product, establishing technical credibility and market presence |
| Build deep regulatory partnerships with NCC | NCC certification and ATRS integration create ongoing regulatory engagement |
| Develop world-class engineering capabilities in Nigeria | VoxGuard's Rust/Go/Python stack builds local capacity in high-performance systems engineering |
| Create recurring revenue streams from enterprise SaaS | VoxGuard platform licensing provides predictable annual revenue per ICL deployment |

---

## 3. Objectives & Deliverables

### 3.1 Project Objectives

| ID | Objective | Measurable Target | Timeline |
|----|-----------|-------------------|----------|
| OBJ-01 | Deliver a production-ready fraud detection engine | 150K+ CPS, <1ms P99 latency, 99.8% detection accuracy | June 2026 |
| OBJ-02 | Achieve full NCC ICL Framework 2026 compliance | NCC certification issued; 100% ATRS integration operational | October 2026 |
| OBJ-03 | Deploy at first ICL operator | 30-day production stability period completed successfully | June 2026 |
| OBJ-04 | Reduce operator fraud losses by 85%+ | Measurable fraud reduction validated by pre/post deployment comparison | September 2026 |
| OBJ-05 | Automate NCC compliance reporting | 100% automated submission for daily, weekly, and monthly reports | May 2026 |
| OBJ-06 | Deploy multi-region infrastructure | Three-region (Lagos, Abuja, Asaba) deployment with <15 min RTO | October 2026 |

### 3.2 Key Deliverables

| ID | Deliverable | Description | Owner | Target Date |
|----|-------------|-------------|-------|-------------|
| DEL-01 | **Detection Engine** | Rust-based real-time fraud detection engine (30K lines) with CLI masking, SIM-box, Wangiri, IRSF, and traffic anomaly detection | Engineering Lead | March 2026 |
| DEL-02 | **Management API** | Go-based RESTful and GraphQL API (11.5K lines) for platform administration, alert management, user management, and gateway operations | Engineering Lead | March 2026 |
| DEL-03 | **ML Pipeline** | Python-based ML pipeline (8.6K lines) for fraud scoring model training, evaluation, deployment, and online inference | ML Lead | August 2026 |
| DEL-04 | **Operator Dashboard** | React + TypeScript + Refine + Ant Design web application with role-based views for fraud analysts, NOC engineers, compliance officers, and executives | Frontend Lead | April 2026 |
| DEL-05 | **GraphQL Gateway** | Hasura-powered unified data access layer providing real-time subscriptions and type-safe queries over YugabyteDB | Engineering Lead | March 2026 |
| DEL-06 | **NCC ATRS Integration** | Automated integration with NCC Automated Trouble Reporting System for daily, weekly, monthly, and incident reports | Compliance Lead | May 2026 |
| DEL-07 | **Data Platform** | Three-tier storage architecture: DragonflyDB (hot cache), ClickHouse (OLAP analytics), YugabyteDB (ACID transactions) with 7-year retention | Data Lead | April 2026 |
| DEL-08 | **Observability Stack** | Prometheus + Grafana + OpenTelemetry monitoring, logging, and distributed tracing for all platform components | DevOps Lead | April 2026 |
| DEL-09 | **Multi-Region Deployment** | Kubernetes-orchestrated deployment across Lagos (primary), Abuja (replica), Asaba (DR) with automatic failover | DevOps Lead | October 2026 |
| DEL-10 | **Security Framework** | mTLS, RS256 JWT, RBAC, HashiCorp Vault secrets management, immutable audit logging | Security Lead | March 2026 |
| DEL-11 | **Documentation Suite** | BRD, PRD, Architecture docs, API reference, deployment guides, operator training materials, NCC compliance specs | PMO | Ongoing |
| DEL-12 | **NCC Certification Package** | Complete certification package including test results, compliance evidence, and operational procedures | Compliance Lead | October 2026 |

---

## 4. Scope Statement

### 4.1 In Scope

**Fraud Detection Capabilities:**
- CLI masking / caller ID spoofing detection
- SIM-box gateway farm detection
- Wangiri (one-ring) fraud detection
- International Revenue Share Fraud (IRSF) detection
- Traffic anomaly and traffic pumping detection
- Real-time gateway blacklisting and call disconnection

**Platform Components:**
- Rust detection engine (core processing)
- Go management API (administration and operations)
- Python ML pipeline (model training and inference)
- React operator dashboard (web-based UI)
- Hasura GraphQL gateway (data access layer)
- Three-tier database architecture (DragonflyDB, ClickHouse, YugabyteDB)
- NCC ATRS integration (automated regulatory reporting)
- Kubernetes deployment infrastructure
- Observability and monitoring stack

**Integration Points:**
- Class 4/5 voice switches (Kamailio, OpenSIPS, FreeSWITCH) via SIP/SIGTRAN
- NCC ATRS API (REST + SFTP)
- MNP database lookups
- Operator BSS/OSS systems
- CDR ingestion feeds

**Deployment:**
- Multi-region Nigerian deployment (Lagos, Abuja, Asaba)
- Production, staging, and development environments
- CI/CD pipeline with automated testing

### 4.2 Out of Scope

- SMS, USSD, or data network fraud detection
- Voice switch operation or management
- Billing system replacement or modification
- Subscriber-facing mobile or web applications
- Physical infrastructure procurement
- International settlement dispute resolution
- Legal prosecution support (beyond evidence provision)
- Operator staff recruitment or permanent staffing

### 4.3 Scope Management

Scope changes will be managed through the following process:

1. **Change Request Submission:** Any stakeholder may submit a change request via the project management system.
2. **Impact Assessment:** Engineering and compliance leads assess technical, schedule, budget, and regulatory impact.
3. **AIDD Tier Classification:** Change is classified per AIDD governance (Tier 0/1/2).
4. **Approval:**
   - Tier 0 changes (documentation, tests): Auto-approved by PM
   - Tier 1 changes (features, logic): Product Owner approval
   - Tier 2 changes (architecture, compliance, security): Steering Committee approval
5. **Implementation:** Approved changes are scheduled into the next sprint cycle.

---

## 5. Key Stakeholders

### 5.1 Stakeholder Register

| Stakeholder | Role | Organization | Responsibility | Communication Frequency |
|-------------|------|-------------|----------------|------------------------|
| BillyRonks Global Executive Board | Project Sponsor | BillyRonks Global | Strategic direction, funding approval, risk escalation | Monthly steering committee |
| VoxGuard Platform Lead | Project Manager | BillyRonks Global | Day-to-day project management, resource allocation, schedule management | Daily standups, weekly reports |
| Chief Technology Officer | Technical Authority | BillyRonks Global | Architecture decisions, technology standards, performance targets | Bi-weekly architecture reviews |
| NCC Technical Division | Regulatory Partner | Nigerian Communications Commission | ATRS API specifications, certification requirements, compliance guidance | Monthly liaison meetings |
| ICL Operator CTOs | Customer Representatives | Licensed ICL Operators | Requirements validation, UAT, production deployment coordination | Bi-weekly engagement |
| Fraud Analysis Team Lead | User Champion (Analysts) | ICL Operators | Analyst workflow requirements, false positive feedback, feature prioritization | Weekly user feedback |
| NOC Manager | User Champion (Operations) | ICL Operators | Operational requirements, monitoring needs, incident response procedures | Weekly operations review |
| Compliance Officer | Regulatory Lead | BillyRonks Global | NCC compliance requirements, audit preparation, report validation | Weekly compliance review |
| Security Architect | Security Authority | BillyRonks Global | Security design review, penetration testing, threat modeling | Bi-weekly security reviews |
| DevOps Lead | Infrastructure Authority | BillyRonks Global | Deployment architecture, CI/CD, multi-region operations | Daily standups |

### 5.2 RACI Matrix

| Activity | Sponsor | PM | CTO | NCC | ICL Ops | Eng Lead | Compliance |
|----------|---------|-----|-----|-----|---------|----------|------------|
| Project Funding | **A** | I | C | I | I | I | I |
| Architecture Decisions | I | C | **A** | I | C | **R** | C |
| Sprint Planning | I | **A** | C | I | C | **R** | C |
| Detection Engine Development | I | C | C | I | I | **R/A** | I |
| NCC ATRS Integration | I | C | C | **A** | I | **R** | **R** |
| Dashboard Development | I | C | I | I | **A** | **R** | I |
| Security Implementation | I | C | **A** | I | I | **R** | C |
| Compliance Certification | **A** | C | C | **R** | C | I | **R** |
| Production Deployment | I | **A** | C | I | **R** | **R** | C |
| Operational Handover | I | **A** | C | I | **R** | **R** | C |

*R = Responsible, A = Accountable, C = Consulted, I = Informed*

---

## 6. High-Level Requirements

### 6.1 Functional Requirements

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| FR-01 | System shall detect CLI masking (caller ID spoofing) in real time by validating A-number against source IP, gateway registration, and MNP records | P0 | NCC CLI Integrity Guidelines 2024 |
| FR-02 | System shall detect SIM-box fraud using sliding window analysis (5-second window, 5+ distinct A-numbers threshold) with configurable parameters | P0 | NCC Fraud Prevention Framework 2023 |
| FR-03 | System shall detect Wangiri fraud by identifying short-duration call bursts (< 3 seconds) targeting premium-rate number ranges | P1 | GSMA Fraud Management Guidelines |
| FR-04 | System shall detect IRSF by analyzing destination distribution against known high-risk international number ranges | P1 | ITU-T E.156, GSMA FMG |
| FR-05 | System shall detect traffic anomalies using statistical baseline modeling with configurable deviation thresholds | P1 | NCC ICL Framework 2026 |
| FR-06 | System shall provide real-time gateway blacklisting with immediate effect on call routing | P0 | NCC CLI Integrity Guidelines 2024 |
| FR-07 | System shall automatically generate and submit NCC reports (daily, weekly, monthly, incident) via ATRS API | P0 | NCC ICL Framework 2026 |
| FR-08 | System shall provide role-based web dashboard for fraud analysts, NOC engineers, compliance officers, and executives | P0 | Operator Requirements |
| FR-09 | System shall maintain immutable audit logs with 7-year retention for all detection events and operator actions | P0 | NCC ICL Framework 2026, NDPA |
| FR-10 | System shall support MNP database lookups for CLI validation with sub-5ms response time | P1 | NCC Numbering Regulations 2019 |

### 6.2 Non-Functional Requirements

| ID | Requirement | Target | Priority |
|----|-------------|--------|----------|
| NFR-01 | **Throughput:** Process 150,000+ calls per second sustained | 150K+ CPS | P0 |
| NFR-02 | **Latency:** Detection decision within 1ms at P99 | <1ms P99 | P0 |
| NFR-03 | **Accuracy:** Overall detection accuracy across all fraud types | 99.8% | P0 |
| NFR-04 | **Availability:** System uptime across all components | 99.99% | P0 |
| NFR-05 | **Cache Hit Rate:** DragonflyDB cache effectiveness | >99% | P0 |
| NFR-06 | **Recovery Time:** Mean time to recovery from component failure | <15 min MTTR | P0 |
| NFR-07 | **Failover:** Automatic failover between regions | <30 sec | P0 |
| NFR-08 | **Disaster Recovery:** Recovery point and time objectives | RPO <1 min, RTO <15 min | P0 |
| NFR-09 | **Scalability:** Horizontal scaling without downtime | Linear scaling to 500K CPS | P1 |
| NFR-10 | **Security:** End-to-end encryption for all data in transit and at rest | mTLS + AES-256 | P0 |

### 6.3 Technical Requirements

| ID | Requirement | Specification |
|----|-------------|---------------|
| TR-01 | Detection engine implemented in Rust | Rust stable (1.75+), async runtime (Tokio), zero-copy parsing |
| TR-02 | Management API implemented in Go | Go 1.22+, Chi router, GORM, structured logging |
| TR-03 | ML pipeline implemented in Python | Python 3.11+, scikit-learn, PyTorch, FastAPI |
| TR-04 | Frontend implemented in React + TypeScript | React 18+, TypeScript 5+, Refine framework, Ant Design 5 |
| TR-05 | Hot cache using DragonflyDB | DragonflyDB 1.x, cluster mode, 99%+ hit rate target |
| TR-06 | OLAP analytics using ClickHouse | ClickHouse 24.x, columnar storage, real-time aggregation |
| TR-07 | ACID transactions using YugabyteDB | YugabyteDB 2.x, distributed SQL, multi-region replication |
| TR-08 | GraphQL gateway using Hasura | Hasura v2, real-time subscriptions, role-based permissions |
| TR-09 | Container orchestration using Kubernetes | Kubernetes 1.28+, Helm charts, GitOps (ArgoCD) |
| TR-10 | Secrets management using HashiCorp Vault | Vault Enterprise, transit engine, auto-unseal |

---

## 7. Milestones

### 7.1 Milestone Schedule

```
2026
Jan          Feb          Mar          Apr          May          Jun
|------------|------------|------------|------------|------------|------------|
 M1 Arch      M2 Infra     M3 Engine    M4 Dashboard  M5 ATRS      M6 Phase1
 Complete     Ready        Alpha        MVP          Integration   GA
                                                                    ▼
Jul          Aug          Sep          Oct          Nov          Dec
|------------|------------|------------|------------|------------|------------|
 M7 ML        M8 Analytics  M9 Multi     M10 NCC      M11 Scale    M12 Phase2
 Pipeline     Dashboard    Region       Certified    Ops          Complete
```

### 7.2 Milestone Details

| ID | Milestone | Date | Exit Criteria | Dependencies |
|----|-----------|------|---------------|--------------|
| M1 | Architecture Complete | Jan 31, 2026 | Architecture docs approved, tech stack finalized, infrastructure design signed off, AIDD governance established | None |
| M2 | Infrastructure Ready | Feb 28, 2026 | Kubernetes clusters deployed across 3 regions, CI/CD pipeline operational, database instances provisioned, Vault configured | M1 |
| M3 | Detection Engine Alpha | Mar 15, 2026 | Rust engine processing 100K CPS, <2ms P99, CLI masking + SIM-box detection functional, unit test coverage >85% | M2 |
| M4 | Dashboard MVP | Apr 30, 2026 | React dashboard with alert list, gateway management, user management, basic analytics; fraud analyst UAT passed | M3 |
| M5 | NCC ATRS Integration | May 15, 2026 | Automated daily/weekly/monthly reporting; NCC sandbox validation passed; SFTP delivery confirmed | M3, M4 |
| M6 | Phase 1 GA | Jun 30, 2026 | Production deployment at first ICL; 150K CPS sustained; <1ms P99; 30-day stability; operational handover complete | M3, M4, M5 |
| M7 | ML Pipeline v1 | Aug 15, 2026 | Python ML pipeline deployed; fraud scoring model achieving 99.8% accuracy on validation set; online inference integrated | M6 |
| M8 | Analytics Dashboard | Sep 15, 2026 | ClickHouse OLAP integration; trend analysis; executive reporting; 3x analyst productivity validated | M6, M7 |
| M9 | Multi-Region GA | Oct 15, 2026 | Three-region deployment operational; failover tested (RTO <15 min, RPO <1 min); traffic distribution active | M6 |
| M10 | NCC Certification | Oct 31, 2026 | NCC ICL Framework 2026 certification issued; all compliance requirements documented and verified | M5, M6, M7, M9 |
| M11 | Scale Operations | Nov 30, 2026 | Second ICL operator deployed; operational runbooks validated; support team trained | M10 |
| M12 | Phase 2 Complete | Dec 31, 2026 | All Phase 2 deliverables accepted; performance benchmarks met; customer satisfaction survey completed | M7-M11 |

### 7.3 Critical Path

The following milestones are on the critical path (zero float):

```
M1 (Architecture) --> M2 (Infrastructure) --> M3 (Detection Engine) --> M6 (Phase 1 GA) --> M10 (NCC Certification)
```

Any delay to milestones on the critical path directly impacts the NCC certification deadline (October 2026).

---

## 8. Budget Summary

### 8.1 Budget Overview

| Category | Phase 1 (H1 2026) | Phase 2 (H2 2026) | Total |
|----------|-------------------|-------------------|-------|
| **Personnel** | $800,000 | $600,000 | $1,400,000 |
| **Infrastructure** | $180,000 | $180,000 | $360,000 |
| **Third-Party Licenses** | $50,000 | $50,000 | $100,000 |
| **Professional Services** | $100,000 | $50,000 | $150,000 |
| **NCC Certification** | $30,000 | $70,000 | $100,000 |
| **Training & Travel** | $25,000 | $25,000 | $50,000 |
| **Contingency (15%)** | $177,750 | $146,250 | $324,000 |
| **Total** | **$1,362,750** | **$1,121,250** | **$2,484,000** |

### 8.2 Personnel Breakdown

| Role | Count | Duration | Monthly Cost | Total |
|------|-------|----------|-------------|-------|
| Engineering Lead (Rust) | 1 | 12 months | $15,000 | $180,000 |
| Senior Rust Engineer | 2 | 12 months | $13,000 | $312,000 |
| Go Engineer | 1 | 12 months | $12,000 | $144,000 |
| Python / ML Engineer | 1 | 10 months | $13,000 | $130,000 |
| Frontend Engineer (React) | 1 | 10 months | $11,000 | $110,000 |
| DevOps / SRE Engineer | 1 | 12 months | $12,000 | $144,000 |
| Security Engineer | 1 | 6 months | $14,000 | $84,000 |
| Project Manager | 1 | 12 months | $10,000 | $120,000 |
| QA Engineer | 1 | 8 months | $9,500 | $76,000 |
| Compliance Specialist | 1 | 6 months | $10,000 | $60,000 |
| **Total Personnel** | **10** | | | **$1,360,000** |

### 8.3 Infrastructure Costs (Annual)

| Component | Monthly Cost | Annual Cost | Notes |
|-----------|-------------|-------------|-------|
| Kubernetes Clusters (3 regions) | $12,000 | $144,000 | 3x clusters, 8-12 nodes each |
| DragonflyDB Instances | $3,000 | $36,000 | High-memory instances, replicated |
| YugabyteDB Cluster | $4,000 | $48,000 | 3-node RF3, geo-distributed |
| ClickHouse Cluster | $3,000 | $36,000 | 3-node cluster, columnar storage |
| Hasura Cloud | $2,000 | $24,000 | Enterprise plan, HA deployment |
| Networking & Load Balancers | $2,000 | $24,000 | Cross-region networking |
| Monitoring & Observability | $1,500 | $18,000 | Grafana Cloud, Prometheus, logging |
| HashiCorp Vault | $1,500 | $18,000 | Enterprise license, HA mode |
| S3-Compatible Cold Storage | $500 | $6,000 | Archival storage, 7-year retention |
| CI/CD Infrastructure | $500 | $6,000 | GitHub Actions, build runners |
| **Total Infrastructure** | **$30,000** | **$360,000** | |

### 8.4 Budget Authority

| Expenditure Level | Approval Authority |
|-------------------|--------------------|
| < $5,000 | Project Manager |
| $5,000 - $25,000 | CTO |
| $25,000 - $100,000 | Executive Sponsor |
| > $100,000 | Executive Board |

---

## 9. Risks

### 9.1 Risk Register

| ID | Risk | Category | Probability | Impact | Severity | Mitigation | Contingency | Owner |
|----|------|----------|------------|--------|----------|------------|-------------|-------|
| R-01 | NCC certification process takes longer than planned, pushing past Q3 2026 deadline | Regulatory | Medium (40%) | High | **High** | Early NCC engagement; iterative certification approach; pre-certification testing in sandbox | Deploy in "monitoring-only" mode pending certification; apply for NCC extension | Compliance Lead |
| R-02 | Detection engine performance degrades under sustained 150K CPS load with realistic traffic patterns | Technical | Low (20%) | Critical | **High** | Continuous load testing with production-representative traffic; 33% capacity headroom; profiling and optimization sprints | Horizontal scaling; traffic shunting to reduce per-node load; emergency performance engineering | Engineering Lead |
| R-03 | ML model accuracy drops below 99% due to adversarial fraud pattern evolution | Technical | Medium (35%) | High | **High** | Continuous retraining pipeline; human-in-the-loop feedback; model monitoring with drift detection; ensemble methods | Fall back to rule-based detection; increase analyst manual review; accelerate model retraining cycle | ML Lead |
| R-04 | ICL operator integration delayed due to legacy switch configurations or internal change management processes | Business | Medium (40%) | Medium | **Medium** | Generic SIP event interface; vendor-agnostic design; pre-built adapters for Kamailio/OpenSIPS/FreeSWITCH; professional services | Offer managed integration service; provide dedicated integration engineer per operator | Product Lead |
| R-05 | Security breach compromising call detail records or subscriber data | Security | Low (15%) | Critical | **High** | mTLS everywhere; RBAC; Vault secrets management; penetration testing; SOC 2 compliance; immutable audit logs | Incident response plan activated; NCC notification within 72 hours; forensic analysis; affected party notification | Security Lead |
| R-06 | Key engineer departure during critical development phase | Organizational | Medium (30%) | Medium | **Medium** | Comprehensive documentation; pair programming; AIDD-compliant codebase; knowledge sharing sessions; competitive compensation | Rapid hiring from Nigerian tech talent pool; consultant engagement; scope reprioritization | PM |
| R-07 | Nigerian data center infrastructure outage exceeding RTO | Infrastructure | Medium (25%) | High | **Medium** | Three-region deployment; automatic failover; RPO <1 min; backup power and connectivity at all sites | Activate DR site; manual failover procedures; communicate with operators | DevOps Lead |
| R-08 | Budget overrun exceeding 15% contingency due to scope creep or infrastructure costs | Financial | Medium (30%) | Medium | **Medium** | Strict scope management via AIDD tiers; monthly budget reviews; infrastructure cost monitoring with alerts | Scope reduction to P0 deliverables only; defer P1/P2 to Phase 3; seek additional funding | PM / Sponsor |
| R-09 | Competitor launches certified ACM product before VoxGuard GA | Market | Low (15%) | Medium | **Low** | Accelerated development timeline; unique performance advantages (latency, accuracy); NCC relationship | Differentiate on performance; offer competitive pricing; highlight Nigerian-developed advantage | Product Lead |
| R-10 | DragonflyDB or other open-source dependency introduces breaking change or licensing change | Technical | Low (10%) | Medium | **Low** | Pin dependency versions; maintain compatibility test suite; evaluate alternatives | Migrate to Redis-compatible alternative; fork if necessary | Engineering Lead |

### 9.2 Risk Management Process

1. **Identification:** Risks are identified during sprint retrospectives, architecture reviews, and stakeholder meetings.
2. **Assessment:** Each risk is scored on probability (1-5) and impact (1-5) to determine severity.
3. **Mitigation Planning:** High and Critical severity risks require documented mitigation and contingency plans.
4. **Monitoring:** Risk register is reviewed bi-weekly during project status meetings.
5. **Escalation:** Critical risks are escalated to the Executive Sponsor within 24 hours.
6. **Closure:** Risks are closed when probability drops to negligible or the risk event window passes.

---

## 10. Organizational Structure

### 10.1 Project Organization

```
                    ┌──────────────────────────┐
                    │    Executive Sponsor      │
                    │  (BillyRonks Global Board)│
                    └────────────┬─────────────┘
                                 │
                    ┌────────────▼─────────────┐
                    │    Steering Committee     │
                    │  (Sponsor, CTO, PM,      │
                    │   Compliance Lead)        │
                    └────────────┬─────────────┘
                                 │
                    ┌────────────▼─────────────┐
                    │    Project Manager        │
                    │  (VoxGuard Platform Lead) │
                    └────────────┬─────────────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
┌─────────▼─────────┐ ┌─────────▼─────────┐ ┌─────────▼─────────┐
│  Engineering Pod   │ │  Platform Pod      │ │  Compliance Pod    │
│                    │ │                    │ │                    │
│ - Rust Engineers   │ │ - DevOps/SRE       │ │ - Compliance Spec  │
│ - Go Engineer      │ │ - Frontend Eng     │ │ - QA Engineer      │
│ - Python/ML Eng    │ │ - Security Eng     │ │ - Technical Writer │
└────────────────────┘ └────────────────────┘ └────────────────────┘
```

### 10.2 Decision-Making Authority

| Decision Type | Authority | Escalation Path |
|--------------|-----------|-----------------|
| Daily technical decisions | Engineering Lead | CTO |
| Sprint scope and priority | Product Manager | Steering Committee |
| Architecture changes | CTO | Steering Committee |
| Budget expenditures (< $5K) | Project Manager | CTO |
| Compliance interpretations | Compliance Lead | NCC liaison |
| Security exceptions | Security Lead | CTO + Compliance |
| Scope changes (Tier 0/1) | Product Manager | PM |
| Scope changes (Tier 2) | Steering Committee | Executive Sponsor |
| Project timeline changes | Steering Committee | Executive Sponsor |
| Vendor/partner agreements | CTO + PM | Executive Sponsor |

---

## 11. Approval Authority

### 11.1 Charter Approval

This Project Charter must be approved by the following authorities before project execution begins:

| Authority | Role | Approval Scope |
|-----------|------|---------------|
| Executive Board | Project Sponsor | Strategic alignment, funding, organizational commitment |
| Chief Technology Officer | Technical Authority | Architecture, technology stack, performance targets |
| Compliance Officer | Regulatory Authority | NCC compliance approach, data protection strategy |
| Project Manager | Execution Authority | Schedule, resource allocation, delivery approach |

### 11.2 Change Authority

Changes to this charter require approval commensurate with the impact:

| Change Category | Approval Required |
|----------------|-------------------|
| Schedule adjustment (< 2 weeks) | Project Manager |
| Schedule adjustment (> 2 weeks) | Steering Committee |
| Budget increase (< 10%) | CTO |
| Budget increase (> 10%) | Executive Sponsor |
| Scope addition (P0 item) | Steering Committee |
| Scope addition (P1/P2 item) | Project Manager |
| Objective change | Executive Sponsor |
| Team structure change | CTO + PM |

### 11.3 Termination Authority

Project termination or indefinite suspension requires Executive Board approval with documented justification including:
- Sunk cost analysis
- In-progress work disposition
- Stakeholder notification plan
- Lessons learned documentation

---

## 12. AIDD Governance Framework

### 12.1 Overview

VoxGuard follows the Autonomous Intelligence-Driven Development (AIDD) governance model, which establishes tiered approval requirements for all development and operational activities. This framework applies to both human and autonomous agents (including Claude Code, CI/CD pipelines, and automated operations).

### 12.2 AIDD Tier Definitions

| Tier | Name | Description | Approval Mechanism |
|------|------|-------------|-------------------|
| **T0** | Auto-Approve | Read-only operations: documentation, test execution, analytics viewing, report generation (draft) | No approval required; logged automatically |
| **T1** | Confirm | State-modifying operations with limited blast radius: single gateway blocks, rule changes, alert acknowledgment, individual call disconnection | Explicit confirmation required (`X-Confirm: true` header) |
| **T2** | Admin Approval | Irreversible or high-impact operations: NCC report submission, MNP bulk import, database migration, auth settings changes, bulk operations | SYSTEM_ADMIN role + documented reason (`X-Admin-Approval` header) |

### 12.3 AIDD Application to Project Charter

| Charter Area | AIDD Tier | Governance Rule |
|-------------|-----------|-----------------|
| Documentation updates (BRD, PRD, Architecture) | T0 | Auto-merged via CI/CD; version controlled |
| Feature development and code changes | T1 | Pull request required; CI checks must pass; code review |
| Detection threshold modifications | T1 | Staged rollout; performance validation before production |
| NCC compliance report generation (draft) | T1 | Confirmation dialog in dashboard |
| NCC compliance report submission (to ATRS) | T2 | Admin approval with documented reason |
| Database schema migrations | T2 | Admin approval; tested in staging; rollback plan documented |
| Security configuration changes | T2 | Security architect review + admin approval |
| Infrastructure scaling operations | T1 | Automated within configured limits; manual beyond limits |
| Budget expenditure authorization | T1 (< $5K) / T2 (> $5K) | Aligned with Section 8.4 budget authority |

### 12.4 Autonomous Operation Boundaries

The following guardrails apply to all autonomous agents operating within the VoxGuard project:

1. **No autonomous NCC submissions:** Regulatory report submissions to NCC ATRS always require human admin approval, regardless of confidence level.
2. **Conservative auto-blocking:** Autonomous gateway blacklisting requires fraud score >= 0.95; all other blocking requires analyst confirmation.
3. **Rate-limited automation:** Autonomous operations are rate-limited (100 auto-blocks/hour, 1000 auto-alerts/hour) with circuit breakers.
4. **Full auditability:** Every autonomous action generates an immutable audit log entry with: agent identity, action performed, AIDD tier, timestamp, justification, and reversibility status.
5. **Rollback guarantee:** All T1 autonomous actions must be reversible within 5 minutes. T2 actions are never automated.
6. **Human override:** Human operators can override any autonomous decision immediately via the dashboard or API.

### 12.5 Compliance Monitoring

AIDD compliance is monitored through:
- **Automated audit log analysis:** Weekly reports on T0/T1/T2 action distribution
- **Anomaly detection:** Alerts when autonomous action rates exceed established baselines
- **Quarterly AIDD review:** Steering Committee reviews AIDD effectiveness and adjusts tier boundaries
- **NCC audit readiness:** AIDD audit trail maintained as part of NCC compliance evidence

---

## 13. Charter Acceptance

By signing below, the undersigned acknowledge they have reviewed this Project Charter and agree to the project objectives, scope, budget, timeline, and governance framework described herein.

### 13.1 Approval Signatures

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Executive Sponsor | _________________ | _________________ | ____/____/2026 |
| Chief Technology Officer | _________________ | _________________ | ____/____/2026 |
| Project Manager | _________________ | _________________ | ____/____/2026 |
| Compliance Officer | _________________ | _________________ | ____/____/2026 |
| NCC Liaison (Advisory) | _________________ | _________________ | ____/____/2026 |

### 13.2 Distribution List

| Recipient | Organization | Copy Type |
|-----------|-------------|-----------|
| Executive Board Members | BillyRonks Global | Controlled Copy |
| Engineering Team Leads | BillyRonks Global | Controlled Copy |
| NCC Technical Division | NCC | Information Copy |
| ICL Operator CTOs (Top 3) | Various | Information Copy (redacted) |

---

*This Project Charter is a living document maintained under version control and subject to the AIDD governance framework. Changes follow the change authority process defined in Section 11.2.*
