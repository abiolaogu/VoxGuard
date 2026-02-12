# VoxGuard Business Requirements Document (BRD)

**Version:** 1.0
**Date:** February 12, 2026
**Status:** Approved
**Owner:** BillyRonks Global
**Classification:** Confidential -- Internal Use Only
**AIDD Compliance:** Tier 0 (Documentation)

---

## Document Control

| Field | Value |
|-------|-------|
| Document ID | VG-BRD-2026-001 |
| Version | 1.0 |
| Author | VoxGuard Product Team |
| Reviewed By | Platform Architecture Board |
| Approved By | BillyRonks Global Executive Team |
| Effective Date | February 12, 2026 |
| Next Review | August 2026 |

### Revision History

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 0.1 | January 5, 2026 | Product Team | Initial draft |
| 0.5 | January 20, 2026 | Architecture Board | Technical review |
| 0.9 | February 3, 2026 | Compliance Team | Regulatory review |
| 1.0 | February 12, 2026 | Executive Team | Final approval |

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Business Context](#2-business-context)
3. [Business Objectives](#3-business-objectives)
4. [Stakeholder Analysis](#4-stakeholder-analysis)
5. [Scope](#5-scope)
6. [Success Metrics & KPIs](#6-success-metrics--kpis)
7. [Business Rules](#7-business-rules)
8. [Constraints & Assumptions](#8-constraints--assumptions)
9. [ROI Analysis](#9-roi-analysis)
10. [Risk Assessment](#10-risk-assessment)
11. [Timeline & Milestones](#11-timeline--milestones)
12. [AIDD Compliance](#12-aidd-compliance)
13. [Appendices](#13-appendices)

---

## 1. Executive Summary

### 1.1 Purpose

This Business Requirements Document defines the business needs, objectives, and justification for the VoxGuard Anti-Call Masking & Voice Network Fraud Detection Platform. VoxGuard is an enterprise-grade platform purpose-built for Nigerian Interconnect Clearing Houses (ICLs) to detect, prevent, and report telecommunications fraud in real time.

### 1.2 Problem Statement

The Nigerian telecommunications sector loses an estimated $3.2 billion annually to voice network fraud, including CLI masking (caller ID spoofing), SIM-box bypass fraud, Wangiri (one-ring) schemes, and International Revenue Share Fraud (IRSF). Current detection systems deployed by ICLs suffer from:

- **High latency:** Legacy rule-based systems introduce 50-200ms detection delays, allowing fraudulent calls to connect before detection.
- **Low accuracy:** False positive rates exceeding 5% cause legitimate call blocking and customer complaints.
- **Poor scalability:** Existing platforms cannot sustain the 150,000+ calls per second (CPS) throughput required during peak periods.
- **Compliance gaps:** Manual NCC reporting processes result in missed deadlines and regulatory penalties.
- **Fragmented tooling:** Operators use disparate, disconnected systems for detection, reporting, and analytics.

### 1.3 Proposed Solution

VoxGuard delivers a unified, high-performance fraud detection platform with the following differentiators:

- **Sub-millisecond detection:** Rust-based detection engine achieving <1ms P99 latency at 150K+ CPS.
- **ML-augmented accuracy:** Python ML pipeline delivering 99.8% detection accuracy with <0.5% false positive rate.
- **Automated compliance:** End-to-end NCC ATRS integration with automated daily, weekly, and monthly reporting.
- **Unified operator console:** React-based dashboard providing fraud analysts, NOC engineers, and compliance officers with role-specific views.
- **Seven-year audit trail:** Immutable, tiered data architecture meeting NCC retention mandates.

### 1.4 Business Impact

| Impact Area | Current State | Target State |
|-------------|---------------|--------------|
| Revenue Leakage | $150M-$300M annually per major ICL | Reduction by 85-95% |
| Detection Latency | 50-200ms average | <1ms P99 |
| False Positive Rate | 3-8% | <0.5% |
| NCC Report Compliance | 70-80% on-time | 100% automated submission |
| Fraud Analyst Efficiency | 50-80 cases/day | 200+ cases/day |

---

## 2. Business Context

### 2.1 Nigerian Telecom Fraud Landscape

Nigeria's telecommunications market serves over 220 million subscribers across four major MNOs (MTN Nigeria, Airtel Nigeria, Globacom, 9mobile) and dozens of interconnect operators. The Nigerian Communications Commission (NCC) licenses Interconnect Clearing Houses to facilitate voice traffic exchange between operators. This role places ICLs at the critical junction where fraud detection is both possible and mandated.

#### 2.1.1 Fraud Types & Economic Impact

| Fraud Type | Mechanism | Annual Impact (Est.) | Growth Trend |
|------------|-----------|---------------------|--------------|
| **CLI Masking / Spoofing** | Manipulation of A-number (caller ID) to bypass interconnect charges, disguise origin, or impersonate legitimate numbers | $1.2B | +15% YoY |
| **SIM-Box Fraud** | Routing international calls through local SIM cards to avoid international termination rates, converting international traffic to appear as local | $800M | +20% YoY |
| **Wangiri (One-Ring)** | Automated short-duration calls to premium-rate numbers designed to trigger callbacks at high per-minute charges | $400M | +25% YoY |
| **IRSF (International Revenue Share Fraud)** | Generating artificial traffic to international premium-rate numbers where the fraudster receives a revenue share | $500M | +10% YoY |
| **Traffic Pumping** | Artificially inflating call volumes to specific destinations to earn interconnect fees | $300M | +12% YoY |

#### 2.1.2 Regulatory Environment

The NCC has progressively tightened fraud detection requirements for ICL license holders:

- **Nigerian Communications Act 2003 (Sections 44, 89-92):** Establishes licensing requirements and penalties for telecommunications fraud.
- **Consumer Code of Practice Regulations 2007 (Part III):** Mandates consumer protection measures including accurate CLI presentation.
- **Numbering Regulations 2019 (Section 12):** Requires CLI integrity validation by all interconnect operators.
- **CLI Integrity Guidelines 2024:** Mandates real-time spoofing detection with 5-second blocking window and monthly incident reporting.
- **Fraud Prevention Framework 2023:** Requires ICLs to maintain real-time fraud detection with 99% accuracy and 24/7 monitoring capability.
- **NCC ICL Framework 2026:** Comprehensive framework requiring ATRS integration, automated reporting, 7-year data retention, and quarterly compliance audits.
- **Nigeria Data Protection Act 2023 (NDPA):** Governs the processing and protection of personal data including call records and subscriber information.

#### 2.1.3 Market Dynamics

- Licensed ICLs in Nigeria: 14 active operators
- Total addressable market for ACM solutions: $45M-$60M annually
- Regulatory enforcement increasing: NCC imposed $12M in fraud-related fines in 2025
- International pressure from ITU-T and GSMA for improved fraud prevention
- Competing solutions lack the throughput and latency profile required for Nigeria's call volumes

### 2.2 Business Drivers

1. **Regulatory Mandate:** NCC ICL Framework 2026 requires all ICL holders to deploy certified fraud detection systems by Q3 2026 or face license suspension.
2. **Revenue Protection:** Every undetected fraudulent call represents direct revenue loss to interconnect operators and the national treasury.
3. **Competitive Advantage:** ICLs that can guarantee fraud-free traffic command premium interconnect rates (8-15% premium observed in market).
4. **Reputational Risk:** High-profile fraud incidents (e.g., the 2025 Lagos CLI masking ring) damage operator credibility and subscriber trust.
5. **Operational Efficiency:** Manual fraud investigation consumes 40+ analyst hours per major incident; automation reduces this to <4 hours.

---

## 3. Business Objectives

### 3.1 Primary Objectives

| ID | Objective | Description | Priority |
|----|-----------|-------------|----------|
| BO-01 | **Revenue Protection** | Reduce fraud-related revenue leakage by 85-95% through real-time detection and prevention of CLI masking, SIM-box, Wangiri, IRSF, and traffic pumping fraud | P0 |
| BO-02 | **Regulatory Compliance** | Achieve 100% compliance with NCC ICL Framework 2026, including automated ATRS reporting, 7-year audit trail retention, and quarterly compliance certification | P0 |
| BO-03 | **Network Integrity** | Maintain voice network trust and quality by ensuring legitimate caller identification and preventing fraudulent traffic from entering the interconnect fabric | P0 |
| BO-04 | **Operational Excellence** | Reduce fraud investigation time by 80% through automated detection, intelligent alert triage, and streamlined analyst workflows | P1 |
| BO-05 | **Scalable Performance** | Support 150,000+ CPS with sub-millisecond P99 latency to handle Nigeria's peak traffic loads without degradation | P0 |

### 3.2 Secondary Objectives

| ID | Objective | Description | Priority |
|----|-----------|-------------|----------|
| BO-06 | **Data-Driven Intelligence** | Provide actionable analytics and trend analysis to enable proactive fraud prevention rather than reactive detection | P1 |
| BO-07 | **Multi-Operator Support** | Enable deployment across multiple ICLs with tenant isolation, operator-specific configurations, and consolidated reporting | P2 |
| BO-08 | **International Interoperability** | Support integration with international fraud detection networks (GSMA FMG, i3Forum) for cross-border fraud intelligence sharing | P2 |
| BO-09 | **Cost Optimization** | Reduce total cost of ownership by 60% compared to legacy commercial ACM solutions through efficient architecture and open-source foundations | P1 |

### 3.3 Objective Alignment Matrix

| Business Objective | NCC Requirement | Stakeholder Value | Technical Enabler |
|-------------------|----------------|-------------------|-------------------|
| Revenue Protection | CLI Integrity Guidelines 2024 | ICL Operators: reduced revenue loss | Rust detection engine, ML pipeline |
| Regulatory Compliance | ICL Framework 2026 | NCC Regulators: automated oversight | ATRS API integration, automated reporting |
| Network Integrity | Fraud Prevention Framework 2023 | MNOs: trustworthy interconnect | Real-time SIP inspection, gateway blacklisting |
| Operational Excellence | 24/7 monitoring requirement | Fraud Analysts: streamlined workflows | React dashboard, alert triage system |
| Scalable Performance | 99% detection accuracy mandate | NOC Engineers: reliable infrastructure | DragonflyDB hot cache, CQRS architecture |

---

## 4. Stakeholder Analysis

### 4.1 Stakeholder Map

| Stakeholder | Role | Interest Level | Influence Level | Key Concerns |
|-------------|------|---------------|-----------------|--------------|
| **ICL Operators** | Primary Customer | Critical | High | Revenue protection, compliance, competitive advantage, TCO |
| **NCC Regulators** | Regulatory Authority | Critical | Very High | Compliance, reporting accuracy, fraud reduction metrics, consumer protection |
| **Fraud Analysts** | Primary User | High | Medium | Alert accuracy, investigation efficiency, case management, false positive reduction |
| **NOC Engineers** | Primary User | High | Medium | System reliability, performance monitoring, threshold configuration, incident response |
| **Compliance Officers** | Primary User | High | Medium | Report accuracy, audit readiness, regulatory deadline adherence |
| **Executive Management** | Decision Maker | High | Very High | ROI, strategic positioning, risk mitigation, market share |
| **MNO Partners** | Indirect Stakeholder | Medium | Medium | Interconnect quality, settlement accuracy, fraud-free traffic |
| **IT Security Teams** | Technical Stakeholder | Medium | Medium | Data protection, access controls, vulnerability management |
| **Subscribers (End Users)** | Beneficiary | Low (indirect) | Low | Accurate caller ID, reduced spam/scam calls |

### 4.2 Stakeholder Requirements

#### 4.2.1 ICL Operators

- Real-time fraud detection with provable accuracy metrics
- Automated NCC reporting to eliminate manual overhead
- Revenue impact quantification and recovery tracking
- Multi-site deployment with centralized management
- Integration with existing BSS/OSS systems and billing platforms
- 24/7 technical support with <15-minute MTTR

#### 4.2.2 NCC Regulators

- ATRS API integration for automated incident reporting
- Standardized report formats (CSV, JSON) per NCC specifications
- Audit trail accessibility with 7-year retention
- Quarterly compliance status reporting
- Real-time dashboard access for regulatory oversight (read-only)
- Incident escalation within 4 hours for critical events

#### 4.2.3 Fraud Analysts

- Intelligent alert prioritization (severity-based ranking, ML confidence scores)
- One-click gateway blacklisting with automatic NCC notification
- CDR deep-dive investigation tools with pattern visualization
- False positive/negative feedback loop to improve ML models
- Customizable detection rule authoring (no-code rule builder)
- Exportable case files for legal proceedings

#### 4.2.4 NOC Engineers

- Real-time system health dashboard (Grafana integration)
- Performance metrics: CPS throughput, detection latency, cache hit rates
- Automated scaling triggers and capacity planning alerts
- Configuration management for detection thresholds and window parameters
- Incident runbooks with automated remediation playbooks
- Infrastructure-as-code deployment and rollback capabilities

#### 4.2.5 Executive Management

- Executive dashboard with KPIs: revenue protected, fraud prevented, compliance status
- Monthly trend analysis and ROI reporting
- Competitive benchmarking against industry standards
- Risk heat maps by fraud type, gateway, and geographic region
- Budget vs. actual cost tracking

---

## 5. Scope

### 5.1 In-Scope

#### 5.1.1 Fraud Detection Capabilities

| Capability | Description | Detection Method | Priority |
|-----------|-------------|------------------|----------|
| **CLI Masking Detection** | Identify calls with spoofed or manipulated caller IDs by cross-referencing CLI against source IP, gateway registration, and MNP databases | Real-time rule engine + ML classification | P0 |
| **SIM-Box Detection** | Detect SIM-box gateway farms by analyzing behavioral patterns: high distinct A-number counts from single endpoints, regular SIM rotation patterns, abnormal call duration distributions | Sliding window algorithm + anomaly detection | P0 |
| **Wangiri Detection** | Identify one-ring fraud campaigns targeting Nigerian numbers by detecting short-duration call bursts to premium-rate number ranges | Pattern matching + call-back rate analysis | P1 |
| **IRSF Detection** | Detect artificially generated traffic to international premium-rate destinations by analyzing destination distribution, call timing, and volume anomalies | ML clustering + destination risk scoring | P1 |
| **Traffic Anomaly Detection** | Identify unusual traffic patterns including traffic pumping, flash crowd events, and abnormal route changes | Statistical anomaly detection + baseline modeling | P1 |

#### 5.1.2 Platform Capabilities

- **Real-Time Detection Engine:** Rust-based engine processing SIP INVITE messages at 150K+ CPS with <1ms P99 latency
- **Management API:** Go-based RESTful/GraphQL API for platform administration, alert management, and gateway operations
- **ML Pipeline:** Python-based pipeline for model training, evaluation, and online inference (fraud scoring, anomaly detection)
- **Operator Dashboard:** React + TypeScript + Refine + Ant Design web application with role-based views
- **GraphQL Gateway:** Hasura-powered unified data access layer over YugabyteDB
- **NCC Integration:** Automated ATRS API integration for daily, weekly, monthly, and incident reporting
- **Data Platform:** Three-tier storage (DragonflyDB hot cache, ClickHouse OLAP, YugabyteDB ACID) with 7-year retention
- **Observability Stack:** Prometheus + Grafana + OpenTelemetry for metrics, logging, and distributed tracing
- **Multi-Region Deployment:** Three Nigerian regions (Lagos, Abuja, Asaba) with automatic failover

#### 5.1.3 Integration Points

- Class 4/5 voice switches via SIP (RFC 3261) and SIGTRAN protocols
- NCC ATRS API (REST + SFTP)
- MNP (Mobile Number Portability) database lookups
- Operator BSS/OSS systems for billing reconciliation
- CDR ingestion from interconnect switches
- GSMA fraud intelligence feeds

### 5.2 Out of Scope

| Item | Rationale | Future Consideration |
|------|-----------|---------------------|
| SMS/USSD fraud detection | Different protocol stack; separate product | Phase 3 (2027) |
| Data network (IP) fraud | VoxGuard focuses on voice network fraud | Potential add-on module |
| Billing system replacement | VoxGuard integrates with, but does not replace, existing BSS | N/A |
| Voice switch operation | VoxGuard inspects traffic; switch management remains with operators | N/A |
| Subscriber-facing applications | VoxGuard is an operator/enterprise platform; no end-user mobile app | Phase 4 (2028) |
| Physical infrastructure provisioning | VoxGuard runs on Kubernetes; hardware procurement is customer responsibility | N/A |
| Legal prosecution support | VoxGuard provides evidence data; legal action is customer responsibility | Partnership program |
| International settlement disputes | VoxGuard handles domestic NCC settlements; international disputes are out of scope | Phase 3 (2027) |

### 5.3 Scope Change Management

All scope changes must follow the AIDD governance process:
- **Tier 0 changes** (documentation, test additions): Auto-approved
- **Tier 1 changes** (new detection rules, UI features): Require Product Owner confirmation
- **Tier 2 changes** (architectural changes, new integrations, compliance modifications): Require Architecture Board and Admin approval

---

## 6. Success Metrics & KPIs

### 6.1 Performance KPIs

| KPI | Target | Measurement Method | Reporting Frequency |
|-----|--------|-------------------|---------------------|
| Detection Throughput | 150,000+ CPS sustained | Prometheus counter: `voxguard_calls_processed_total` | Real-time (Grafana) |
| Detection Latency (P99) | <1ms | Prometheus histogram: `voxguard_detection_duration_seconds` | Real-time (Grafana) |
| Detection Latency (P50) | <0.5ms | Prometheus histogram | Real-time (Grafana) |
| Cache Hit Rate | >99% | DragonflyDB metrics: `keyspace_hits / (keyspace_hits + keyspace_misses)` | Real-time (Grafana) |
| System Uptime | 99.99% (52.6 min/year downtime) | Kubernetes health checks + Prometheus alerting | Monthly |
| Mean Time to Recovery (MTTR) | <15 minutes | Incident tracking system | Per incident |

### 6.2 Accuracy KPIs

| KPI | Target | Measurement Method | Reporting Frequency |
|-----|--------|-------------------|---------------------|
| Overall Detection Accuracy | 99.8% | (TP + TN) / Total predictions, validated against analyst feedback | Weekly |
| False Positive Rate | <0.5% | FP / (FP + TN), measured against analyst-confirmed outcomes | Weekly |
| False Negative Rate | <0.2% | FN / (FN + TP), measured via honeypot testing and post-hoc analysis | Monthly |
| CLI Masking Detection Rate | >99.5% | Detected CLI masking events / Total known CLI masking events | Weekly |
| SIM-Box Detection Rate | >99.0% | Detected SIM-box events / Total known SIM-box events | Weekly |
| Wangiri Detection Rate | >98.0% | Detected Wangiri events / Total known Wangiri events | Monthly |

### 6.3 Business KPIs

| KPI | Target | Measurement Method | Reporting Frequency |
|-----|--------|-------------------|---------------------|
| Revenue Protected | >$100M/year per major ICL deployment | (Detected fraud volume) x (average interconnect rate) | Monthly |
| Fraud Case Resolution Time | <4 hours (critical), <24 hours (high) | Case management system timestamps | Weekly |
| NCC Report On-Time Rate | 100% | ATRS submission acknowledgment timestamps | Per report |
| Analyst Productivity | >200 cases/day per analyst | Case management system metrics | Weekly |
| Customer Satisfaction (NPS) | >70 | Quarterly operator survey | Quarterly |
| Platform Adoption Rate | 100% of licensed ICLs within 18 months | Sales pipeline tracking | Quarterly |

### 6.4 Compliance KPIs

| KPI | Target | Measurement Method | Reporting Frequency |
|-----|--------|-------------------|---------------------|
| NCC Compliance Score | 100% | Quarterly NCC audit results | Quarterly |
| Audit Finding Remediation | <30 days for critical, <90 days for minor | Audit tracking system | Per audit |
| Data Retention Compliance | 7-year retention verified | Archival system integrity checks (SHA-256) | Monthly |
| Incident Escalation Timeliness | 100% within 4-hour SLA | ATRS submission timestamps vs. detection timestamps | Per incident |

---

## 7. Business Rules

### 7.1 Detection Rules

| Rule ID | Rule | Trigger Condition | Action | Priority |
|---------|------|-------------------|--------|----------|
| BR-DET-001 | CLI Validation | CLI does not match registered gateway IP range or MNP record | Flag as suspected CLI masking; score >= 0.8 triggers alert | P0 |
| BR-DET-002 | SIM-Box Threshold | >= 5 distinct A-numbers from single B-number/IP within 5-second sliding window | Create fraud alert; auto-blacklist gateway if score >= 0.95 | P0 |
| BR-DET-003 | Wangiri Pattern | >= 50 calls with duration < 3 seconds from same source within 60-second window | Create fraud alert; block source after 100 occurrences | P1 |
| BR-DET-004 | IRSF Destination Risk | Call to destination on GSMA IRSF high-risk list with no prior legitimate traffic history | Create fraud alert; require analyst confirmation before blocking | P1 |
| BR-DET-005 | Traffic Anomaly | Call volume from source deviates > 3 standard deviations from 7-day rolling baseline | Create informational alert; escalate if deviation exceeds 5 sigma | P1 |

### 7.2 Operational Rules

| Rule ID | Rule | Description |
|---------|------|-------------|
| BR-OPS-001 | Gateway Blacklist Confirmation | All gateway blacklist actions require explicit analyst confirmation (AIDD Tier 1) except auto-blacklist for fraud scores >= 0.95 |
| BR-OPS-002 | NCC Submission Approval | NCC report submissions require SYSTEM_ADMIN role approval (AIDD Tier 2) |
| BR-OPS-003 | MNP Data Import | Bulk MNP data imports require admin approval and validation checksum verification (AIDD Tier 2) |
| BR-OPS-004 | Detection Threshold Changes | Changes to detection thresholds require Architecture Board review and staged rollout |
| BR-OPS-005 | False Positive Feedback | Analyst-confirmed false positives must be fed back to ML pipeline within 24 hours |

### 7.3 Compliance Rules

| Rule ID | Rule | Description |
|---------|------|-------------|
| BR-CMP-001 | Daily Report Submission | Daily statistics report submitted to NCC ATRS by 06:00 WAT following day |
| BR-CMP-002 | Critical Incident Escalation | Critical fraud incidents (>1000 affected calls or >$10K estimated loss) escalated to NCC within 4 hours |
| BR-CMP-003 | Audit Log Immutability | All audit log entries are append-only; no deletion or modification permitted |
| BR-CMP-004 | Data Retention | All fraud detection data, CDRs, and audit logs retained for minimum 7 years |
| BR-CMP-005 | Data Sovereignty | All data processing and storage must occur within Nigerian territory per NDPA requirements |

---

## 8. Constraints & Assumptions

### 8.1 Constraints

| ID | Constraint | Impact | Mitigation |
|----|-----------|--------|------------|
| C-01 | **Nigerian data sovereignty:** All data must be processed and stored within Nigeria per NDPA 2023 | Limits cloud provider options; requires Nigerian data centers | Multi-region deployment across Lagos, Abuja, Asaba with on-premises Kubernetes |
| C-02 | **NCC certification timeline:** ATRS integration must be certified by NCC before production use | Potential deployment delays if certification process extends | Early engagement with NCC technical team; pre-certification testing |
| C-03 | **Network latency budget:** Detection must complete within 1ms to avoid call setup delays | Constrains algorithm complexity; requires in-memory processing | DragonflyDB hot cache, Rust zero-copy processing, CQRS pattern |
| C-04 | **Existing switch infrastructure:** Must integrate with installed base of Kamailio/OpenSIPS/FreeSWITCH without requiring switch upgrades | Limits integration protocol options | Generic SIP event interface supporting multiple switch vendors |
| C-05 | **Budget constraint:** Total project budget capped at $2.5M for Phase 1 | Limits team size and infrastructure spend | Open-source stack (Rust, Go, Python, React); cloud-efficient architecture |
| C-06 | **Staffing:** Nigerian telecom Rust engineers are scarce | May limit detection engine development velocity | Hybrid team with remote Rust specialists; comprehensive documentation |

### 8.2 Assumptions

| ID | Assumption | Risk if Invalid | Validation Method |
|----|-----------|-----------------|-------------------|
| A-01 | ICL operators will provide SIP event feeds in real time (not batched) | Detection latency SLA cannot be met | Confirmed with top-3 ICLs; SIP integration specs validated |
| A-02 | NCC ATRS API will be available and stable with published specifications | Automated reporting will require manual fallback | ATRS API documentation obtained; sandbox access confirmed |
| A-03 | MNP database will provide sub-5ms lookup responses | CLI validation accuracy will degrade | MNP provider SLA review; local caching strategy as fallback |
| A-04 | Peak traffic will not exceed 200K CPS within 18 months | Scaling architecture sufficient with 33% headroom | Based on NCC traffic growth projections; auto-scaling configured |
| A-05 | Nigerian data center infrastructure supports Kubernetes orchestration | Deployment model must change to VM-based | Confirmed with MDXi (Lagos), Galaxy Backbone (Abuja) facilities |
| A-06 | Operators will dedicate fraud analyst staff to use the platform | Platform adoption and accuracy feedback loop depends on operator staffing | Training program included in deployment; managed service offering as backup |

### 8.3 Dependencies

| ID | Dependency | Owner | Status |
|----|-----------|-------|--------|
| D-01 | NCC ATRS API sandbox access | NCC Technical Division | Confirmed |
| D-02 | MNP database access agreement | MNP Central Authority | In progress |
| D-03 | ICL SIP event feed provisioning | Individual ICL operators | Confirmed (top-3) |
| D-04 | Nigerian data center hosting contracts | MDXi / Galaxy Backbone | Signed |
| D-05 | GSMA fraud intelligence feed subscription | GSMA FMG | Pending |
| D-06 | HashiCorp Vault Enterprise license | HashiCorp | Procured |

---

## 9. ROI Analysis

### 9.1 Cost Model

#### 9.1.1 Development Costs (Phase 1)

| Category | Cost | Notes |
|----------|------|-------|
| Engineering Team (12 months) | $1,200,000 | 8 engineers (Rust, Go, Python, React, DevOps) |
| Architecture & Design | $150,000 | Solution architecture, security design, compliance consulting |
| Infrastructure (Development) | $120,000 | Development environments, CI/CD, testing infrastructure |
| Third-Party Licenses | $80,000 | Hasura Cloud, HashiCorp Vault, monitoring tools |
| NCC Certification & Compliance | $100,000 | Certification testing, compliance consulting, audit preparation |
| Training & Documentation | $50,000 | Operator training programs, technical documentation |
| Project Management & QA | $200,000 | Project management, quality assurance, UAT coordination |
| Contingency (15%) | $285,000 | Risk buffer |
| **Total Phase 1** | **$2,185,000** | |

#### 9.1.2 Annual Operating Costs

| Category | Annual Cost | Notes |
|----------|-------------|-------|
| Infrastructure (Production) | $360,000 | Three-region deployment, databases, networking |
| Team (Operations) | $480,000 | 4 engineers (SRE, platform, ML, support) |
| Licenses & Subscriptions | $120,000 | Hasura, Vault, GSMA feeds, monitoring |
| NCC Compliance | $60,000 | Annual audit, certification renewal |
| **Total Annual OpEx** | **$1,020,000** | |

### 9.2 Benefit Model

#### 9.2.1 Revenue Protection (per ICL deployment)

| Fraud Type | Current Annual Loss | Detection Rate | Revenue Protected |
|------------|-------------------|----------------|-------------------|
| CLI Masking | $80M | 99.5% | $79.6M |
| SIM-Box | $40M | 99.0% | $39.6M |
| Wangiri | $15M | 98.0% | $14.7M |
| IRSF | $20M | 97.0% | $19.4M |
| Traffic Anomalies | $10M | 95.0% | $9.5M |
| **Total** | **$165M** | | **$162.8M** |

#### 9.2.2 Operational Savings

| Category | Annual Savings | Notes |
|----------|---------------|-------|
| Fraud Analyst Productivity | $200,000 | 3x throughput improvement; fewer analysts needed |
| Manual NCC Reporting Elimination | $100,000 | Automated reporting replaces 2 FTE compliance staff |
| Reduced False Positive Investigation | $150,000 | 90% reduction in false positive investigation time |
| Avoided NCC Penalties | $500,000 | Compliance automation eliminates penalty risk |
| **Total Annual Savings** | **$950,000** | |

### 9.3 ROI Summary

| Metric | Value |
|--------|-------|
| Total Investment (Year 1) | $2,185,000 (development) + $1,020,000 (operations) = $3,205,000 |
| Annual Benefit (per ICL) | $162.8M (revenue protected) + $950K (operational savings) = $163.75M |
| Payback Period | <1 month (post-deployment) |
| 3-Year ROI | >15,000% |
| 5-Year NPV (10% discount rate) | >$600M (across 5 ICL deployments) |

> **Note:** ROI calculations are conservative estimates based on industry benchmarks and Nigerian-specific fraud volume data from NCC 2025 annual report. Actual results will vary by operator size and traffic profile.

---

## 10. Risk Assessment

### 10.1 Risk Register

| ID | Risk | Probability | Impact | Severity | Mitigation Strategy | Owner |
|----|------|------------|--------|----------|---------------------|-------|
| R-01 | NCC certification delays beyond Q3 2026 | Medium | High | High | Early engagement; pre-certification testing; phased deployment starting with non-regulated features | Compliance Lead |
| R-02 | Detection engine cannot sustain 150K CPS under production conditions | Low | Critical | High | Continuous performance testing; horizontal scaling architecture; DragonflyDB cluster mode | Engineering Lead |
| R-03 | ML model accuracy degrades with evolving fraud patterns | Medium | High | High | Continuous model retraining pipeline; human-in-the-loop feedback; model monitoring and drift detection | ML Lead |
| R-04 | ICL operators resist integration due to existing switch configurations | Medium | Medium | Medium | Generic SIP event interface; vendor-agnostic design; professional services for custom integrations | Product Lead |
| R-05 | Data breach compromising CDR or subscriber data | Low | Critical | High | Encryption at rest and in transit (mTLS); RBAC; audit logging; penetration testing; HashiCorp Vault | Security Lead |
| R-06 | Key personnel departure during critical development phase | Medium | Medium | Medium | Comprehensive documentation; knowledge sharing; competitive compensation; AIDD reduces bus factor | HR / PM |
| R-07 | Nigerian data center infrastructure reliability | Medium | High | High | Three-region deployment; automatic failover; RPO <1 min, RTO <15 min | DevOps Lead |
| R-08 | MNP database unavailability impacting CLI validation | Medium | Medium | Medium | Local MNP cache with 24-hour TTL; graceful degradation to rule-based validation | Engineering Lead |
| R-09 | Competitor launches similar product before VoxGuard GA | Low | Medium | Low | Accelerated timeline; unique performance differentiators (latency, accuracy); first-mover NCC certification | Product Lead |
| R-10 | NDPA compliance issues with cross-border data sharing | Low | High | Medium | All processing within Nigeria; NDPA-compliant data handling; legal review of international feed integrations | Legal / Compliance |

### 10.2 Risk Heat Map

```
             │ Low Impact │ Medium Impact │ High Impact │ Critical Impact │
─────────────┼────────────┼───────────────┼─────────────┼─────────────────│
High Prob    │            │               │             │                 │
Medium Prob  │            │ R-04, R-06    │ R-01, R-03  │                 │
             │            │               │ R-07, R-08  │                 │
Low Prob     │ R-09       │ R-10          │             │ R-02, R-05      │
```

---

## 11. Timeline & Milestones

### 11.1 Phase Overview

| Phase | Name | Duration | Start | End | Key Deliverables |
|-------|------|----------|-------|-----|------------------|
| **Phase 1** | Foundation | 6 months | Jan 2026 | Jun 2026 | Detection engine, management API, basic dashboard, NCC ATRS integration |
| **Phase 2** | Enhancement | 4 months | Jul 2026 | Oct 2026 | ML pipeline, advanced analytics, multi-region deployment, full compliance |
| **Phase 3** | Scale | 4 months | Nov 2026 | Feb 2027 | Multi-operator deployment, advanced ML models, international integration |
| **Phase 4** | Innovation | Ongoing | Mar 2027+ | - | SMS fraud, blockchain audit, AI-driven autonomous response |

### 11.2 Phase 1 Milestones

| Milestone | Target Date | Deliverables | Success Criteria |
|-----------|-------------|-------------|------------------|
| M1.1: Architecture Complete | Jan 31, 2026 | Architecture docs, tech stack decisions, infrastructure design | Architecture Board approval |
| M1.2: Detection Engine Alpha | Mar 15, 2026 | Rust detection engine with CLI masking and SIM-box detection | 100K CPS, <2ms P99 in staging |
| M1.3: Management API v1 | Mar 31, 2026 | Go API with CRUD for alerts, gateways, users; Hasura GraphQL layer | API functional test suite passing |
| M1.4: Dashboard MVP | Apr 30, 2026 | React dashboard with alert list, gateway management, basic analytics | Fraud analyst UAT sign-off |
| M1.5: NCC ATRS Integration | May 15, 2026 | Automated daily/weekly/monthly reporting via ATRS API | NCC sandbox validation passed |
| M1.6: Performance Certification | May 31, 2026 | Load testing, security audit, compliance review | 150K CPS, <1ms P99, security audit passed |
| M1.7: Phase 1 GA | Jun 30, 2026 | Production deployment at first ICL operator | 30-day production stability |

### 11.3 Phase 2 Milestones

| Milestone | Target Date | Deliverables | Success Criteria |
|-----------|-------------|-------------|------------------|
| M2.1: ML Pipeline v1 | Aug 15, 2026 | Python ML pipeline with fraud scoring and anomaly detection models | 99.8% accuracy on validation set |
| M2.2: Advanced Analytics | Sep 15, 2026 | ClickHouse OLAP integration, trend analysis dashboards, executive reporting | Analyst productivity 3x improvement |
| M2.3: Multi-Region GA | Oct 15, 2026 | Three-region deployment (Lagos, Abuja, Asaba) with automatic failover | RTO <15 min, RPO <1 min validated |
| M2.4: NCC Certification | Oct 31, 2026 | Full NCC ICL Framework 2026 compliance certification | NCC certification letter issued |

---

## 12. AIDD Compliance

### 12.1 AIDD Governance Framework

VoxGuard development and operations follow the Autonomous Intelligence-Driven Development (AIDD) governance model as defined in the project's CLAUDE.md constitution. This framework ensures that autonomous tooling (including Claude Code, CI/CD pipelines, and automated operations) operates within controlled boundaries.

### 12.2 Tiered Approval Model

| Tier | Scope | Approval | BRD Applicability |
|------|-------|----------|-------------------|
| **Tier 0 (Auto-Approve)** | Read-only operations, documentation, tests, analytics views | None required | BRD updates, metric viewing, report generation (read-only) |
| **Tier 1 (Confirm)** | State-modifying operations with limited blast radius | Explicit user confirmation (`X-Confirm: true`) | Individual gateway blocks, detection rule changes, fraud alert acknowledgment |
| **Tier 2 (Admin Approval)** | Irreversible operations, regulatory submissions, bulk changes | SYSTEM_ADMIN role + approval reason | NCC report submissions, MNP bulk imports, compliance settings, database migrations |

### 12.3 Business Requirements Alignment with AIDD

| Business Requirement | AIDD Tier | Rationale |
|---------------------|-----------|-----------|
| View fraud dashboards and analytics | Tier 0 | Read-only; no state modification |
| Generate NCC compliance report (draft) | Tier 1 | Creates document but does not submit |
| Submit NCC compliance report to ATRS | Tier 2 | Regulatory submission; irreversible |
| Block individual gateway | Tier 1 | Reversible; single-entity impact |
| Bulk import MNP database | Tier 2 | Large-scale data modification |
| Modify detection thresholds | Tier 1 | Impacts detection behavior; requires staged rollout |
| Change authentication settings | Tier 2 | Security-critical; affects all users |

### 12.4 Autonomous Operation Guardrails

1. **No autonomous NCC submissions:** All regulatory report submissions require human admin approval regardless of automation level.
2. **Fraud score thresholds:** Auto-blacklisting only triggered at fraud score >= 0.95 (conservative threshold to minimize autonomous false positives).
3. **Rollback capability:** All Tier 1 actions must be reversible within 5 minutes.
4. **Audit trail:** Every action, including autonomous operations, generates an immutable audit log entry with actor identity, timestamp, action details, and AIDD tier classification.
5. **Circuit breakers:** Autonomous operations are rate-limited (max 100 auto-blacklists per hour) with circuit breaker patterns to prevent runaway automation.

---

## 13. Appendices

### Appendix A: Glossary

| Term | Definition |
|------|-----------|
| ACM | Anti-Call Masking -- System for detecting and preventing caller ID fraud |
| ATRS | Automated Trouble Reporting System -- NCC's centralized incident reporting platform |
| BSS | Business Support System -- Operator billing and customer management systems |
| CDR | Call Detail Record -- Detailed record of a telephone call including parties, duration, and routing |
| CLI | Calling Line Identification -- The caller ID number presented to the called party |
| CPS | Calls Per Second -- Throughput metric for voice processing systems |
| DDD | Domain-Driven Design -- Software design approach organizing code around business domains |
| ICL | Interconnect Clearing License -- NCC license type for voice traffic clearing operators |
| IRSF | International Revenue Share Fraud -- Fraud scheme generating traffic to premium-rate international numbers |
| MNO | Mobile Network Operator -- Licensed operator of mobile telecommunications networks |
| MNP | Mobile Number Portability -- System allowing subscribers to retain numbers when changing operators |
| NCC | Nigerian Communications Commission -- Nigeria's telecommunications regulatory authority |
| NDPA | Nigeria Data Protection Act 2023 -- Primary data protection legislation |
| NOC | Network Operations Center -- Centralized monitoring and management facility |
| OSS | Operations Support System -- Operator network management and provisioning systems |
| SIP | Session Initiation Protocol -- Standard protocol for voice call signaling (RFC 3261) |
| SIGTRAN | Signaling Transport -- Protocols for carrying SS7 signaling over IP networks |
| Wangiri | Japanese for "one ring" -- Fraud scheme using short-duration calls to provoke callbacks |

### Appendix B: Referenced Documents

| Document | Location | Relevance |
|----------|----------|-----------|
| VoxGuard Product Requirements Document | `docs/PRD.md` | Detailed product specifications |
| Architecture Overview | `docs/ARCHITECTURE.md` | Technical architecture details |
| NCC Compliance Specification | `docs/ncc/NCC_COMPLIANCE_SPECIFICATION.md` | Regulatory requirements |
| NCC Reporting Requirements | `docs/ncc/NCC_REPORTING_REQUIREMENTS.md` | Report formats and schedules |
| Security Hardening Guide | `docs/SECURITY_HARDENING.md` | Security implementation details |
| Data Retention & Archival | `docs/DATA_RETENTION_ARCHIVAL.md` | Data lifecycle management |
| AIDD Approval Tiers | `docs/AIDD_APPROVAL_TIERS.md` | AIDD governance details |
| Multi-Region Deployment | `docs/MULTI_REGION_DEPLOYMENT.md` | Regional deployment architecture |

### Appendix C: Approval Signatures

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Executive Sponsor | _________________ | _________________ | ____/____/2026 |
| Product Owner | _________________ | _________________ | ____/____/2026 |
| Chief Architect | _________________ | _________________ | ____/____/2026 |
| Compliance Officer | _________________ | _________________ | ____/____/2026 |
| Engineering Lead | _________________ | _________________ | ____/____/2026 |

---

*This document is maintained under version control and subject to the AIDD governance framework. Changes to this BRD follow the scope change management process defined in Section 5.3.*
