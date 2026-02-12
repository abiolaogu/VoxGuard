# Product Requirements Document (PRD)
## Anti-Call Masking Detection System

> **See Also:** For the consolidated PRD with full implementation status tracking, refer to [`../PRD.md`](../PRD.md) (1,046 lines). This file is the clean requirements-focused PRD.

**Version:** 2.0
**Last Updated:** January 2026
**Status:** Production
**Product Owner:** [Product Team]

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Problem Statement](#2-problem-statement)
3. [Goals & Objectives](#3-goals--objectives)
4. [User Personas](#4-user-personas)
5. [User Stories](#5-user-stories)
6. [Functional Requirements](#6-functional-requirements)
7. [Non-Functional Requirements](#7-non-functional-requirements)
8. [Success Metrics](#8-success-metrics)
9. [Constraints & Assumptions](#9-constraints--assumptions)
10. [Release Plan](#10-release-plan)

---

## 1. Executive Summary

### 1.1 Product Vision

The Anti-Call Masking Detection System (ACM) is a real-time fraud detection platform that protects telecommunications networks from CLI spoofing attacks. By detecting and preventing multicall masking fraud, the system protects consumers, prevents revenue loss, and ensures regulatory compliance with NCC requirements.

### 1.2 Value Proposition

| Stakeholder | Value |
|-------------|-------|
| **Telecom Operators** | Prevent fraud losses, maintain reputation |
| **Consumers** | Protection from scam calls |
| **Regulators (NCC)** | Industry compliance, fraud reduction |
| **Enterprise Customers** | Brand protection, secure communications |

### 1.3 Key Differentiators

- **Sub-millisecond Detection**: < 1ms latency vs. industry standard of 100ms+
- **150,000+ CPS**: Handles Nigeria's highest traffic volumes
- **99.8% Accuracy**: Industry-leading detection rate
- **NCC Integrated**: First-party ATRS integration
- **Real-time Response**: Automatic call disconnection

---

## 2. Problem Statement

### 2.1 The Fraud Problem

Call masking (CLI spoofing) is a significant telecommunications fraud where attackers:

1. **Generate multiple fake caller IDs** to reach the same victim
2. **Bypass traditional fraud detection** by using unique numbers each time
3. **Execute social engineering attacks** with legitimacy appearance
4. **Cause financial and reputational damage** to operators and consumers

### 2.2 Impact Analysis

| Impact Area | Annual Cost (Nigeria) |
|-------------|----------------------|
| Direct Fraud Losses | ₦15+ billion |
| Customer Churn | ₦5+ billion |
| Regulatory Fines | ₦2+ billion |
| Brand Damage | Immeasurable |

### 2.3 Current Limitations

Traditional fraud detection systems fail because:
- Detection occurs after calls complete (post-processing)
- Static rules cannot adapt to evolving patterns
- Legacy systems cannot handle modern traffic volumes
- No real-time integration with SIP infrastructure

---

## 3. Goals & Objectives

### 3.1 Primary Goals

| Goal | Target | Timeline |
|------|--------|----------|
| Reduce fraud losses | 80% reduction | Year 1 |
| Detection latency | < 1ms | Launch |
| System availability | 99.99% | Ongoing |
| NCC compliance | 100% | Launch |

### 3.2 Business Objectives

1. **Protect Revenue**: Minimize fraud-related losses
2. **Ensure Compliance**: Meet all NCC requirements
3. **Enhance Trust**: Improve customer confidence
4. **Enable Scale**: Support network growth

### 3.3 Technical Objectives

1. **Real-time Processing**: Sub-millisecond detection
2. **High Throughput**: 150,000+ calls per second
3. **High Availability**: 99.99% uptime
4. **Seamless Integration**: Works with existing infrastructure

---

## 4. User Personas

### 4.1 SOC Analyst - "Adaeze"

**Role:** Security Operations Center Analyst
**Experience:** 3 years in telecom security
**Goals:**
- Monitor fraud alerts in real-time
- Investigate suspicious patterns
- Minimize false positives
- Meet response time SLAs

**Pain Points:**
- Alert fatigue from too many false positives
- Slow investigation tools
- Lack of historical context

**Needs:**
- Clear, actionable alerts
- One-click investigation
- Pattern visualization
- Bulk operations

### 4.2 Network Administrator - "Chidi"

**Role:** Infrastructure/Network Administrator
**Experience:** 5 years in telecommunications
**Goals:**
- Maintain system uptime
- Manage capacity
- Deploy updates without downtime
- Optimize performance

**Pain Points:**
- Complex deployments
- Unclear error messages
- Performance troubleshooting

**Needs:**
- Simple deployment
- Clear monitoring
- Automated scaling
- Comprehensive logs

### 4.3 API Developer - "Funke"

**Role:** Integration Developer at Carrier
**Experience:** 4 years in telecom software
**Goals:**
- Integrate ACM with voice switches
- Build custom reporting
- Automate workflows

**Pain Points:**
- Poor API documentation
- Inconsistent responses
- Rate limiting issues

**Needs:**
- Clear API documentation
- SDKs in multiple languages
- Webhooks for events
- Sandbox environment

### 4.4 Compliance Officer - "Emeka"

**Role:** Regulatory Compliance Manager
**Experience:** 7 years in telecom compliance
**Goals:**
- Ensure NCC compliance
- Generate compliance reports
- Pass regulatory audits
- Stay ahead of regulations

**Pain Points:**
- Manual report generation
- Unclear regulatory requirements
- Audit preparation stress

**Needs:**
- Automated NCC reporting
- Compliance dashboards
- Audit trail
- Regulatory updates

### 4.5 Executive - "Ngozi"

**Role:** Chief Technology Officer
**Experience:** 15 years in telecommunications
**Goals:**
- Reduce fraud losses
- Demonstrate ROI
- Strategic planning
- Risk management

**Pain Points:**
- Lack of executive visibility
- Unclear ROI metrics
- Competitive pressure

**Needs:**
- Executive dashboards
- ROI calculations
- Trend analysis
- Benchmark data

---

## 5. User Stories

### 5.1 Detection & Alerting

| ID | Story | Priority |
|----|-------|----------|
| US-001 | As a SOC analyst, I want to see real-time alerts when fraud is detected so I can respond immediately | P0 |
| US-002 | As a SOC analyst, I want alerts categorized by severity so I can prioritize my response | P0 |
| US-003 | As a SOC analyst, I want one-click call disconnection so I can stop active fraud | P0 |
| US-004 | As a system, I want to automatically detect multicall masking so fraud is caught in real-time | P0 |
| US-005 | As a SOC analyst, I want to add numbers to whitelist so legitimate call centers aren't flagged | P1 |

### 5.2 Investigation

| ID | Story | Priority |
|----|-------|----------|
| US-010 | As a SOC analyst, I want to see all A-numbers involved in an attack so I can understand the scope | P0 |
| US-011 | As a SOC analyst, I want to see historical alerts for a B-number so I can identify repeat targets | P1 |
| US-012 | As a SOC analyst, I want to export investigation data so I can share with law enforcement | P1 |
| US-013 | As a SOC analyst, I want to correlate alerts with source IPs so I can identify attack infrastructure | P2 |

### 5.3 Configuration

| ID | Story | Priority |
|----|-------|----------|
| US-020 | As an admin, I want to configure detection thresholds so I can tune for my network | P0 |
| US-021 | As an admin, I want to enable/disable auto-disconnect so I can control automatic responses | P0 |
| US-022 | As an admin, I want to manage API keys so I can control system access | P1 |
| US-023 | As an admin, I want to configure alert routing so the right team is notified | P1 |

### 5.4 Reporting

| ID | Story | Priority |
|----|-------|----------|
| US-030 | As a compliance officer, I want automatic daily NCC reports so I meet regulatory requirements | P0 |
| US-031 | As an executive, I want a fraud summary dashboard so I can see overall trends | P1 |
| US-032 | As a compliance officer, I want to generate ad-hoc reports so I can answer regulatory queries | P1 |
| US-033 | As an analyst, I want to see detection accuracy metrics so I can tune the system | P2 |

### 5.5 Integration

| ID | Story | Priority |
|----|-------|----------|
| US-040 | As a developer, I want a REST API so I can submit call events | P0 |
| US-041 | As a developer, I want webhook notifications so my system is alerted to fraud | P1 |
| US-042 | As a developer, I want SDK libraries so integration is easier | P2 |
| US-043 | As a developer, I want a sandbox environment so I can test integrations | P1 |

---

## 6. Functional Requirements

### 6.1 Core Detection

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-001 | System SHALL detect when 5+ distinct A-numbers call the same B-number within 5 seconds | P0 |
| FR-002 | System SHALL generate alerts with severity based on A-number count | P0 |
| FR-003 | System SHALL support configurable detection thresholds (3-20) | P0 |
| FR-004 | System SHALL support configurable time windows (1-30 seconds) | P0 |
| FR-005 | System SHALL maintain a whitelist of exempt B-numbers | P0 |
| FR-006 | System SHALL support pattern-based blocking | P1 |

### 6.2 Alert Management

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-010 | System SHALL display alerts in real-time dashboard | P0 |
| FR-011 | System SHALL support alert acknowledgment | P0 |
| FR-012 | System SHALL support alert status transitions (new → investigating → resolved) | P0 |
| FR-013 | System SHALL support alert assignment to analysts | P1 |
| FR-014 | System SHALL support alert notes and comments | P1 |
| FR-015 | System SHALL support marking alerts as false positives | P1 |

### 6.3 Actions

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-020 | System SHALL support automatic call disconnection | P0 |
| FR-021 | System SHALL support manual call disconnection | P0 |
| FR-022 | System SHALL support pattern blocking | P1 |
| FR-023 | System SHALL log all actions with audit trail | P0 |

### 6.4 Reporting

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-030 | System SHALL generate daily NCC compliance reports | P0 |
| FR-031 | System SHALL upload reports to NCC SFTP by 06:00 WAT | P0 |
| FR-032 | System SHALL generate monthly compliance summaries | P0 |
| FR-033 | System SHALL support ad-hoc report generation | P1 |
| FR-034 | System SHALL support report export (CSV, PDF) | P1 |

### 6.5 API

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-040 | System SHALL provide REST API for event submission | P0 |
| FR-041 | System SHALL provide REST API for alert queries | P0 |
| FR-042 | System SHALL provide REST API for configuration | P0 |
| FR-043 | System SHALL support webhook notifications | P1 |
| FR-044 | System SHALL support batch event submission | P1 |

---

## 7. Non-Functional Requirements

### 7.1 Performance

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-001 | Detection latency P99 | < 1ms |
| NFR-002 | Throughput | 150,000 CPS |
| NFR-003 | API response time P99 | < 5ms |
| NFR-004 | Dashboard load time | < 2s |

### 7.2 Availability

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-010 | System availability | 99.99% |
| NFR-011 | Recovery Time Objective (RTO) | 1 hour |
| NFR-012 | Recovery Point Objective (RPO) | 15 minutes |
| NFR-013 | Planned maintenance window | < 4 hours/month |

### 7.3 Scalability

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-020 | Horizontal scaling | Auto-scale 2-10 instances |
| NFR-021 | Storage growth handling | 1 PB capacity |
| NFR-022 | Connection handling | 15,000 concurrent |

### 7.4 Security

| ID | Requirement | Standard |
|----|-------------|----------|
| NFR-030 | Encryption in transit | TLS 1.3 |
| NFR-031 | Encryption at rest | AES-256 |
| NFR-032 | Authentication | OAuth 2.0 / API Keys |
| NFR-033 | Authorization | RBAC |
| NFR-034 | Audit logging | 5-year retention |

### 7.5 Compliance

| ID | Requirement | Standard |
|----|-------------|----------|
| NFR-040 | NCC CLI Guidelines | Full compliance |
| NFR-041 | NDPR (Data Protection) | Full compliance |
| NFR-042 | Data residency | Nigeria only |
| NFR-043 | Report retention | 7 years |

### 7.6 Usability

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-050 | Dashboard accessibility | WCAG 2.1 AA |
| NFR-051 | Mobile responsiveness | Full support |
| NFR-052 | Training time | < 2 hours |

---

## 8. Success Metrics

### 8.1 Key Performance Indicators (KPIs)

| Metric | Target | Measurement |
|--------|--------|-------------|
| Fraud Detection Rate | > 99% | Monthly |
| False Positive Rate | < 0.2% | Monthly |
| Detection Latency P99 | < 1ms | Real-time |
| System Uptime | > 99.99% | Monthly |
| NCC Report Compliance | 100% | Daily |
| Alert Response Time | < 5 min (P1) | Per incident |

### 8.2 Business Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Fraud Loss Reduction | 80% | Quarterly |
| Customer Complaints (fraud) | 90% reduction | Quarterly |
| Regulatory Fines | ₦0 | Annual |
| ROI | > 300% | Annual |

### 8.3 User Satisfaction

| Metric | Target | Measurement |
|--------|--------|-------------|
| SOC Analyst Satisfaction | > 4.0/5.0 | Quarterly survey |
| API Developer Satisfaction | > 4.0/5.0 | Quarterly survey |
| System Net Promoter Score | > 50 | Annual |

---

## 9. Constraints & Assumptions

### 9.1 Constraints

| Type | Constraint |
|------|------------|
| **Budget** | Initial deployment within allocated CAPEX |
| **Timeline** | Must be production-ready for NCC deadline |
| **Technology** | Must integrate with existing OpenSIPS infrastructure |
| **Compliance** | All data must remain in Nigeria |
| **Resources** | Operations team of 5 for 24/7 coverage |

### 9.2 Assumptions

| Assumption | Risk if Invalid |
|------------|-----------------|
| Network latency to detection engine < 10ms | May need edge deployment |
| SIP switch can call HTTP API synchronously | May need async mode |
| NCC ATRS API will be available | May need manual reporting |
| Traffic will not exceed 175,000 CPS | May need scaling |
| False positive tolerance is < 1% | May need threshold tuning |

### 9.3 Dependencies

| Dependency | Owner | Status |
|------------|-------|--------|
| OpenSIPS integration | Network Team | Complete |
| NCC ATRS credentials | Compliance | Complete |
| Data center capacity | Infrastructure | Complete |
| Security review | Security Team | Complete |
| Legal review | Legal | Complete |

---

## 10. Release Plan

### 10.1 Release Phases

| Phase | Scope | Timeline | Status |
|-------|-------|----------|--------|
| Alpha | Core detection, basic dashboard | Completed | Done |
| Beta | Full dashboard, NCC reporting | Completed | Done |
| GA 1.0 | Production release | Completed | Done |
| GA 2.0 | Enhanced analytics, mobile | Current | Active |

### 10.2 Feature Roadmap

**Q1 2026 (Current):**
- Enhanced NCC compliance reporting
- Mobile application
- Advanced analytics dashboard

**Q2 2026:**
- Machine learning anomaly detection
- Cross-operator coordination
- Enhanced API features

**Q3 2026:**
- Predictive fraud prevention
- Real-time threat intelligence
- Advanced pattern recognition

**Q4 2026:**
- International expansion support
- Multi-tenant capabilities
- Advanced automation

### 10.3 Success Criteria for GA

- [ ] All P0 requirements implemented
- [ ] Performance targets met
- [ ] NCC compliance verified
- [ ] Security audit passed
- [ ] Operations team trained
- [ ] Documentation complete
- [ ] Runbooks validated

---

## Appendix A: Glossary

| Term | Definition |
|------|------------|
| A-Number | Calling party phone number (source) |
| B-Number | Called party phone number (destination) |
| CLI | Calling Line Identification |
| CPS | Calls Per Second |
| Detection Window | Time period for counting distinct A-numbers |
| False Positive | Alert for legitimate traffic |
| Masking Attack | Multiple A-numbers calling same B-number |
| NCC | Nigerian Communications Commission |
| ATRS | Automated Trouble Reporting System |

---

## Appendix B: Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-06 | Product Team | Initial release |
| 2.0 | 2026-01 | Product Team | NCC compliance, enhanced features |

---

**Document Classification:** Internal
**Review Cycle:** Quarterly
**Next Review:** April 2026
