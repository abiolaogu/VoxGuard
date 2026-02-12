# VoxGuard Compliance & Regulatory Matrix

**Version:** 1.0
**Date:** February 12, 2026
**Status:** Approved
**Owner:** VoxGuard Compliance & Legal Team
**Classification:** Confidential -- Internal Use Only
**AIDD Compliance:** Tier 0 (Documentation)

---

## Document Control

| Field | Value |
|-------|-------|
| Document ID | VG-CRM-2026-001 |
| Version | 1.0 |
| Author | VoxGuard Compliance Team |
| Reviewed By | Legal Counsel, Security Architect, CTO |
| Approved By | Executive Steering Committee |
| Effective Date | February 12, 2026 |
| Next Review | May 2026 (quarterly) |

### Revision History

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| 0.1 | January 12, 2026 | Compliance Team | Initial regulatory mapping |
| 0.5 | January 28, 2026 | Legal Counsel | Legal review and NDPA mapping |
| 0.9 | February 7, 2026 | Security Architect | SOC 2 and ISO 27001 mapping |
| 1.0 | February 12, 2026 | Steering Committee | Final approval |

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Compliance Overview Dashboard](#2-compliance-overview-dashboard)
3. [NCC Regulatory Requirements](#3-ncc-regulatory-requirements)
4. [Data Protection (NDPA & GDPR)](#4-data-protection-ndpa--gdpr)
5. [SOC 2 Type II Controls Mapping](#5-soc-2-type-ii-controls-mapping)
6. [ISO 27001 Controls Mapping](#6-iso-27001-controls-mapping)
7. [PCI-DSS Requirements](#7-pci-dss-requirements)
8. [Telecom-Specific Regulations](#8-telecom-specific-regulations)
9. [AIDD Compliance](#9-aidd-compliance)
10. [Audit Requirements](#10-audit-requirements)
11. [Compliance Calendar](#11-compliance-calendar)
12. [Gap Analysis & Remediation Plan](#12-gap-analysis--remediation-plan)

---

## 1. Executive Summary

This Compliance & Regulatory Matrix provides a comprehensive mapping of all regulatory, legal, and industry requirements applicable to the VoxGuard Anti-Call Masking & Voice Network Fraud Detection Platform. The matrix covers Nigerian telecommunications regulations (NCC), data protection laws (NDPA, GDPR), international security standards (SOC 2 Type II, ISO 27001, PCI-DSS), telecommunications industry standards (ITU-T, GSMA), and the AIDD autonomous operation governance framework.

### 1.1 Compliance Posture Summary

| Regulatory Domain | Total Requirements | Compliant | Partial | Planned | Compliance Rate |
|-------------------|--------------------|-----------|---------|---------|-----------------|
| NCC Regulatory | 28 | 18 | 7 | 3 | 64% (89% with Partial) |
| NDPA (Data Protection) | 15 | 10 | 3 | 2 | 67% (87% with Partial) |
| GDPR (International) | 12 | 7 | 3 | 2 | 58% (83% with Partial) |
| SOC 2 Type II | 25 | 16 | 6 | 3 | 64% (88% with Partial) |
| ISO 27001 | 30 | 19 | 7 | 4 | 63% (87% with Partial) |
| PCI-DSS | 12 | 6 | 4 | 2 | 50% (83% with Partial) |
| ITU-T / GSMA | 10 | 6 | 3 | 1 | 60% (90% with Partial) |
| AIDD Governance | 8 | 8 | 0 | 0 | 100% |
| **Total** | **140** | **90** | **33** | **17** | **64% (88% with Partial)** |

### 1.2 Status Definitions

| Status | Definition | Color Code |
|--------|-----------|------------|
| **Compliant** | Requirement fully implemented, tested, and documented. Evidence available for audit. | Green |
| **Partial** | Implementation in progress or partially complete. Remediation plan in place with target date. | Yellow |
| **Planned** | Requirement identified and scheduled for implementation. Design complete or in progress. | Orange |
| **Not Applicable** | Requirement does not apply to VoxGuard's scope of operations. Justification documented. | Gray |

---

## 2. Compliance Overview Dashboard

### 2.1 Critical Compliance Deadlines

| Deadline | Regulation | Requirement | Status | Risk Level |
|----------|-----------|-------------|--------|------------|
| **Q3 2026** | NCC ICL Framework 2026 | Certified fraud detection system deployment | Partial | **Critical** |
| **June 2026** | NCC CLI Integrity | Real-time CLI validation operational | Compliant | Low |
| **Ongoing** | NCC Reporting | Daily/weekly/monthly ATRS submissions | Partial | **High** |
| **Ongoing** | NDPA 2023 | Data protection impact assessment complete | Compliant | Low |
| **December 2026** | SOC 2 Type II | Initial audit period completion | Planned | Medium |
| **March 2027** | ISO 27001 | Certification audit | Planned | Medium |

### 2.2 Compliance Risk Heat Map

```
                 │ Low Likelihood │ Medium Likelihood │ High Likelihood │
─────────────────┼────────────────┼───────────────────┼─────────────────│
Critical Impact  │ Data breach    │ NCC certification │                 │
                 │                │ delay             │                 │
High Impact      │ PCI-DSS audit  │ NDPA enforcement  │ NCC reporting   │
                 │ finding        │ action            │ deadline miss   │
Medium Impact    │ ISO 27001 gap  │ SOC 2 exception   │                 │
Low Impact       │ GSMA guideline │                   │                 │
                 │ deviation      │                   │                 │
```

---

## 3. NCC Regulatory Requirements

### 3.1 Nigerian Communications Act 2003

| ID | Requirement | Section | Description | VoxGuard Implementation | Status | Evidence |
|----|-------------|---------|-------------|------------------------|--------|----------|
| NCC-001 | ICL License Compliance | Sec 44 | Maintain valid Interconnect Clearing License and comply with all license conditions | Platform designed for ICL-licensed operators; compliance features built-in | **Compliant** | License validation module in Management API |
| NCC-002 | Fraud Prevention Obligation | Sec 89 | Operators must implement measures to prevent telecommunications fraud | VoxGuard detection engine provides real-time fraud prevention for CLI masking, SIM-box, Wangiri, IRSF, traffic anomalies | **Compliant** | Detection engine operational; 5 fraud types covered |
| NCC-003 | Consumer Protection | Sec 90 | Protect consumers from fraudulent telecommunications activities | CLI validation prevents spoofed caller IDs from reaching consumers | **Compliant** | CLI validation in detection engine |
| NCC-004 | Penalty Acknowledgment | Sec 92 | Acknowledge and prepare for penalties for non-compliance | Compliance monitoring dashboard; automated deadline tracking | **Compliant** | Compliance calendar in Management API |

### 3.2 CLI Integrity Guidelines 2024

| ID | Requirement | Description | VoxGuard Implementation | Status | Evidence |
|----|-------------|-------------|------------------------|--------|----------|
| NCC-CLI-001 | Real-Time CLI Validation | All operators must implement CLI validation for incoming calls | Detection engine validates CLI against source IP, gateway registration, and MNP records in <1ms | **Compliant** | Performance benchmarks; detection engine code |
| NCC-CLI-002 | 5-Second Blocking Window | Spoofed CLIs must be blocked or flagged within 5 seconds | VoxGuard achieves <1ms detection, well within 5-second requirement | **Compliant** | Latency metrics (Prometheus) |
| NCC-CLI-003 | Monthly Incident Reporting | Monthly reporting of detected spoofing incidents to NCC | ATRS integration generates monthly compliance reports automatically | **Partial** | ATRS integration in sandbox testing; target: May 2026 |
| NCC-CLI-004 | Industry CLI Database Participation | Mandatory participation in industry CLI database for number validation | MNP database integration for CLI validation | **Partial** | MNP integration operational; full industry database participation pending NCC consortium setup |

### 3.3 Fraud Prevention Framework 2023

| ID | Requirement | Description | VoxGuard Implementation | Status | Evidence |
|----|-------------|-------------|------------------------|--------|----------|
| NCC-FPF-001 | Real-Time Detection System | ICL holders must deploy real-time fraud detection systems | Rust detection engine processing 150K+ CPS in real time | **Compliant** | Load test results; production metrics |
| NCC-FPF-002 | 99% Detection Accuracy | Minimum 99% detection accuracy for known fraud patterns | Target 99.8% accuracy; currently achieving 99.5% with rule engine (ML pipeline will improve) | **Partial** | Accuracy metrics; ML pipeline planned for Aug 2026 |
| NCC-FPF-003 | 24/7 Monitoring Capability | Round-the-clock fraud monitoring capability | Prometheus + Grafana + PagerDuty alerting provides 24/7 automated monitoring | **Compliant** | Observability stack documentation; alert configuration |
| NCC-FPF-004 | 4-Hour Critical Escalation | Critical incidents escalated to NCC within 4 hours | ATRS integration with automated critical incident reporting | **Partial** | ATRS incident API integration in development; manual SFTP fallback operational |
| NCC-FPF-005 | Qualified Personnel | Fraud detection personnel must be qualified and trained | Operator training program included in deployment package | **Planned** | Training materials in development; target: May 2026 |

### 3.4 NCC ICL Framework 2026

| ID | Requirement | Description | VoxGuard Implementation | Status | Evidence |
|----|-------------|-------------|------------------------|--------|----------|
| NCC-ICL-001 | ATRS Integration | Automated integration with NCC ATRS for all report types | ATRS REST API + SFTP integration for daily, weekly, monthly, and incident reports | **Partial** | ATRS sandbox integration complete; production testing pending NCC approval |
| NCC-ICL-002 | Certified Detection System | Fraud detection system must be NCC-certified | Certification package in preparation; target submission Q3 2026 | **Planned** | Certification plan documented; test evidence collection in progress |
| NCC-ICL-003 | 7-Year Data Retention | All fraud detection data retained for minimum 7 years | Three-tier storage (hot/warm/cold) with automated archival and SHA-256 integrity verification | **Compliant** | Data Retention & Archival documentation; archival system operational |
| NCC-ICL-004 | Quarterly Compliance Audit | Quarterly compliance audits by NCC-approved auditor | Audit-ready documentation; immutable audit logs; compliance evidence repository | **Partial** | Audit preparation in progress; first audit expected Q4 2026 |
| NCC-ICL-005 | Settlement Dispute Resolution | System must support settlement dispute tracking and resolution | Settlement dispute management in Management API with evidence attachment | **Compliant** | Settlement API endpoints operational |
| NCC-ICL-006 | MNP Integration | Integration with Mobile Number Portability database | MNP lookup service with DragonflyDB caching (24h TTL) | **Compliant** | MNP integration documentation; cache hit rate metrics |
| NCC-ICL-007 | Incident Response Plan | Documented incident response procedures | Incident response runbook with severity classification and escalation procedures | **Compliant** | `docs/runbook.md`; incident response training |

### 3.5 NCC Reporting Requirements

| ID | Report Type | Frequency | Deadline | Format | Submission | Status | Evidence |
|----|-------------|-----------|----------|--------|------------|--------|----------|
| NCC-RPT-001 | Daily Statistics | Daily | 06:00 WAT following day | CSV + JSON | SFTP + ATRS API | **Partial** | Report generation functional; ATRS submission in sandbox testing |
| NCC-RPT-002 | Weekly Summary | Weekly | Monday 12:00 WAT | JSON | ATRS API | **Partial** | Report generation functional; ATRS submission in sandbox testing |
| NCC-RPT-003 | Monthly Compliance | Monthly | 5th of month | JSON + PDF | ATRS API + Portal | **Partial** | Report generation functional; portal submission not yet implemented |
| NCC-RPT-004 | Incident Reports | Per event | Varies by severity (4h critical, 24h high, 72h medium) | JSON | ATRS API | **Partial** | Critical incident reporting in development; SFTP fallback operational |
| NCC-RPT-005 | Annual Compliance | Annual | January 31st | PDF + attachments | NCC Portal | **Planned** | First annual report due January 2027 |
| NCC-RPT-006 | Settlement Reports | Per dispute | 5 business days from dispute initiation | JSON + evidence | ATRS API | **Compliant** | Settlement report generation operational |

---

## 4. Data Protection (NDPA & GDPR)

### 4.1 Nigeria Data Protection Act 2023 (NDPA)

| ID | Requirement | NDPA Section | Description | VoxGuard Implementation | Status | Evidence |
|----|-------------|-------------|-------------|------------------------|--------|----------|
| NDPA-001 | Lawful Processing Basis | Sec 25 | Data processing must have a lawful basis (consent, legitimate interest, legal obligation) | Legitimate interest (fraud prevention) + legal obligation (NCC mandate) as processing basis | **Compliant** | Privacy policy; processing basis documentation |
| NDPA-002 | Data Protection Impact Assessment | Sec 29 | DPIA required for high-risk processing activities | DPIA completed for VoxGuard platform covering CDR processing, fraud detection, and NCC reporting | **Compliant** | DPIA document (internal) |
| NDPA-003 | Data Minimization | Sec 26(c) | Collect only data adequate, relevant, and necessary for stated purpose | VoxGuard collects only SIP metadata (A-number, B-number, source IP, timestamp); no voice content captured | **Compliant** | Data flow documentation; no voice recording capability |
| NDPA-004 | Purpose Limitation | Sec 26(b) | Data processed only for specified, explicit, and legitimate purposes | Data used exclusively for fraud detection, NCC compliance reporting, and platform operations | **Compliant** | Privacy policy; data processing register |
| NDPA-005 | Storage Limitation | Sec 26(e) | Data not kept longer than necessary; retention periods justified | 7-year retention per NCC mandate; auto-deletion after retention period | **Compliant** | Data retention policy; automated deletion scripts |
| NDPA-006 | Data Security | Sec 38 | Appropriate technical and organizational measures to protect data | mTLS, AES-256, RBAC, Vault secrets management, audit logging | **Compliant** | Security hardening documentation; penetration test results |
| NDPA-007 | Breach Notification (NDPC) | Sec 40 | Notify Nigeria Data Protection Commission within 72 hours of breach | Incident response plan includes NDPC notification procedure | **Partial** | Incident response plan drafted; notification workflow in development |
| NDPA-008 | Breach Notification (Data Subjects) | Sec 41 | Notify affected data subjects without undue delay if high risk | Subscriber notification procedure documented; template notifications prepared | **Partial** | Notification templates drafted; automated delivery not yet implemented |
| NDPA-009 | Cross-Border Transfer | Sec 43 | Restrictions on transfer of personal data outside Nigeria | All data processing and storage within Nigeria (Lagos, Abuja, Asaba); no cross-border transfer | **Compliant** | Data sovereignty policy; infrastructure documentation |
| NDPA-010 | Data Protection Officer | Sec 31 | Appoint DPO for high-risk processing activities | DPO appointment recommended for each ICL operator; VoxGuard provides DPO tooling (audit logs, DSAR support) | **Partial** | DPO tooling included in platform; operator appointment is operator responsibility |
| NDPA-011 | Records of Processing | Sec 28 | Maintain records of all processing activities | Processing activity register maintained in YugabyteDB with audit trail | **Compliant** | Processing register API endpoint |
| NDPA-012 | Data Subject Rights (Access) | Sec 34 | Data subjects have right to access their personal data | DSAR (Data Subject Access Request) endpoint in Management API | **Compliant** | DSAR API documentation |
| NDPA-013 | Data Subject Rights (Erasure) | Sec 36 | Right to erasure (subject to legal retention requirements) | Erasure supported for data beyond NCC 7-year retention mandate; audit log entries retained | **Compliant** | Erasure API with retention policy enforcement |
| NDPA-014 | Data Subject Rights (Portability) | Sec 37 | Right to receive data in structured, machine-readable format | Data export in JSON and CSV formats via Management API | **Compliant** | Data export API documentation |
| NDPA-015 | Annual Compliance Audit | Sec 30 | Annual data protection compliance audit | NDPA compliance audit integrated into annual NCC compliance cycle | **Planned** | First audit scheduled Q4 2026 |

### 4.2 GDPR (For International Partners)

| ID | Requirement | GDPR Article | Description | VoxGuard Implementation | Status | Evidence |
|----|-------------|-------------|-------------|------------------------|--------|----------|
| GDPR-001 | Lawful Basis | Art 6 | Lawful basis for processing | Legitimate interest (fraud prevention) documented in processing records | **Compliant** | Legitimate interest assessment |
| GDPR-002 | Privacy by Design | Art 25 | Data protection by design and default | Privacy embedded in architecture: data minimization, encryption, access controls | **Compliant** | Architecture documentation; DPIA |
| GDPR-003 | Data Protection Impact Assessment | Art 35 | DPIA for high-risk processing | DPIA completed covering all processing activities | **Compliant** | DPIA document |
| GDPR-004 | International Transfer Safeguards | Art 46 | Appropriate safeguards for international data transfers | No international data transfer by design; all processing within Nigeria | **Compliant** | Data sovereignty policy |
| GDPR-005 | Breach Notification (72 hours) | Art 33 | Supervisory authority notification within 72 hours | Incident response plan includes 72-hour notification procedure for GDPR-relevant incidents | **Partial** | Incident response plan; automated notification in development |
| GDPR-006 | Data Subject Rights | Art 15-22 | Access, rectification, erasure, portability, objection | DSAR endpoints in Management API; automated processing | **Compliant** | DSAR API documentation |
| GDPR-007 | Records of Processing | Art 30 | Maintain processing records | Processing activity register maintained | **Compliant** | Processing register |
| GDPR-008 | Data Processor Agreements | Art 28 | Written agreements with data processors | DPA templates for operator agreements; sub-processor register maintained | **Partial** | DPA template drafted; not yet executed with all partners |
| GDPR-009 | Consent Management | Art 7 | Consent mechanisms where consent is the legal basis | Not primary legal basis (legitimate interest used); consent mechanisms available for optional features | **Compliant** | N/A (legitimate interest basis) |
| GDPR-010 | Privacy Policy | Art 13-14 | Transparent privacy information | Privacy policy published; processing information provided at collection | **Compliant** | Privacy policy document |
| GDPR-011 | Data Minimization | Art 5(1)(c) | Adequate, relevant, and limited to purpose | SIP metadata only; no voice content; no unnecessary personal data | **Compliant** | Data flow documentation |
| GDPR-012 | DPO Appointment | Art 37 | DPO for large-scale processing | DPO role defined; operator responsible for appointment | **Partial** | DPO role description; tooling provided |

---

## 5. SOC 2 Type II Controls Mapping

### 5.1 Trust Service Criteria

| ID | TSC | Criteria | VoxGuard Implementation | Status | Evidence |
|----|-----|---------|------------------------|--------|----------|
| SOC-CC1.1 | CC1 | COSO Principle 1: Integrity and ethical values | Code of conduct; AIDD governance framework; ethical AI guidelines | **Compliant** | AIDD governance documentation |
| SOC-CC1.2 | CC1 | COSO Principle 2: Board oversight | Executive Steering Committee; Architecture Review Board | **Compliant** | Project Charter; meeting minutes |
| SOC-CC1.3 | CC1 | COSO Principle 3: Management establishes structure and authority | Organizational structure defined; RACI matrix; escalation procedures | **Compliant** | Project Charter Section 10 |
| SOC-CC1.4 | CC1 | COSO Principle 4: Commitment to competence | Technical skills requirements; training program; code review process | **Partial** | Job descriptions; training plan in development |
| SOC-CC1.5 | CC1 | COSO Principle 5: Accountability enforcement | AIDD tier enforcement; audit logging; performance reviews | **Compliant** | AIDD Approval Tiers documentation |

### 5.2 Security Controls

| ID | TSC | Criteria | VoxGuard Implementation | Status | Evidence |
|----|-----|---------|------------------------|--------|----------|
| SOC-CC6.1 | CC6 | Logical access security | RS256 JWT authentication; RBAC authorization; Hasura role-based permissions | **Compliant** | Security hardening documentation |
| SOC-CC6.2 | CC6 | User authentication | RS256 JWT with 15-min expiry; refresh token rotation; MFA for admin roles | **Compliant** | JWT implementation; MFA configuration |
| SOC-CC6.3 | CC6 | Access authorization | 6-role RBAC model; least privilege; Hasura permission rules | **Compliant** | RBAC matrix; Hasura metadata |
| SOC-CC6.4 | CC6 | Access restriction to assets | Network segmentation; Kubernetes namespace isolation; database-level access controls | **Compliant** | Network policies; namespace configuration |
| SOC-CC6.5 | CC6 | Access revocation | Immediate token revocation; DragonflyDB session invalidation; user deactivation API | **Compliant** | Revocation API; session management |
| SOC-CC6.6 | CC6 | Physical access security | Data center physical security (MDXi, Galaxy Backbone managed) | **Partial** | Data center compliance certificates pending |
| SOC-CC6.7 | CC6 | Encryption of data at rest | AES-256 for databases; Vault Transit engine for sensitive fields; S3 SSE for archives | **Compliant** | Encryption configuration; Vault policies |
| SOC-CC6.8 | CC6 | Encryption of data in transit | TLS 1.3 for external; mTLS for internal; certificate rotation via Vault PKI | **Compliant** | TLS configuration; mTLS certificates |

### 5.3 Availability Controls

| ID | TSC | Criteria | VoxGuard Implementation | Status | Evidence |
|----|-----|---------|------------------------|--------|----------|
| SOC-A1.1 | A1 | Availability commitments | 99.99% uptime SLA; documented in operator agreements | **Partial** | SLA template drafted; not yet contractually binding |
| SOC-A1.2 | A1 | System capacity management | Auto-scaling (HPA); capacity planning; 33% headroom maintained | **Compliant** | Auto-scaling configuration; capacity projections |
| SOC-A1.3 | A1 | Recovery procedures | Automated failover (<30s); disaster recovery (RPO <1min, RTO <15min) | **Partial** | Multi-region architecture designed; full DR testing pending (Phase 2) |
| SOC-A1.4 | A1 | Backup and recovery | YugabyteDB Raft replication; DragonflyDB persistence; S3 archival | **Compliant** | Backup configuration; recovery procedures |

### 5.4 Processing Integrity Controls

| ID | TSC | Criteria | VoxGuard Implementation | Status | Evidence |
|----|-----|---------|------------------------|--------|----------|
| SOC-PI1.1 | PI1 | Input validation | MSISDN format validation; IP address validation; SIP header parsing | **Compliant** | Value object validation in Rust detection engine |
| SOC-PI1.2 | PI1 | Processing accuracy | 99.8% detection accuracy target; ML model monitoring; false positive tracking | **Partial** | Rule engine achieving 99.5%; ML pipeline for 99.8% planned Aug 2026 |
| SOC-PI1.3 | PI1 | Output completeness | NCC report completeness validation; SHA-256 integrity checks on archived data | **Compliant** | Report validation logic; archival integrity checks |

### 5.5 Confidentiality Controls

| ID | TSC | Criteria | VoxGuard Implementation | Status | Evidence |
|----|-----|---------|------------------------|--------|----------|
| SOC-C1.1 | C1 | Confidential information identification | Data classification scheme: Public, Internal, Confidential, Restricted | **Compliant** | Data classification policy |
| SOC-C1.2 | C1 | Confidential information disposal | Automated deletion after retention period; secure wipe for decommissioned storage | **Partial** | Automated deletion operational; secure wipe procedure in development |
| SOC-C1.3 | C1 | NDA and confidentiality agreements | Operator agreements include confidentiality clauses; employee NDAs | **Planned** | Agreement templates drafted; execution pending |

---

## 6. ISO 27001 Controls Mapping

### 6.1 Organizational Controls (Annex A.5)

| ID | ISO Control | Description | VoxGuard Implementation | Status | Evidence |
|----|------------|-------------|------------------------|--------|----------|
| ISO-A5.1 | A.5.1 | Policies for information security | Information security policy documented; AIDD governance framework | **Compliant** | Security policy; AIDD documentation |
| ISO-A5.2 | A.5.2 | Information security roles and responsibilities | Security roles defined in project charter; RACI matrix | **Compliant** | Project Charter Section 10; RACI matrix |
| ISO-A5.3 | A.5.3 | Segregation of duties | RBAC with 6 roles; AIDD tiered approvals; no single person can submit NCC reports without admin approval | **Compliant** | RBAC matrix; AIDD tier documentation |
| ISO-A5.4 | A.5.4 | Management responsibilities | Steering Committee oversight; quarterly security reviews | **Compliant** | Meeting schedule; review cadence |
| ISO-A5.5 | A.5.5 | Contact with authorities | NCC liaison established; NDPC contact registered; CERT-NG contact | **Partial** | NCC liaison confirmed; NDPC and CERT-NG registration in progress |
| ISO-A5.6 | A.5.6 | Contact with special interest groups | GSMA FMG membership pending; ITU-T participation via NCC | **Partial** | GSMA application submitted; ITU-T via NCC confirmed |

### 6.2 People Controls (Annex A.6)

| ID | ISO Control | Description | VoxGuard Implementation | Status | Evidence |
|----|------------|-------------|------------------------|--------|----------|
| ISO-A6.1 | A.6.1 | Screening | Background checks for team members with access to production systems | **Partial** | Policy defined; not all checks complete |
| ISO-A6.2 | A.6.2 | Terms and conditions of employment | Security responsibilities in employment contracts; NDA clauses | **Partial** | Contract templates include security clauses; not all executed |
| ISO-A6.3 | A.6.3 | Information security awareness, education, and training | Security awareness training for all team members; annual refresher | **Planned** | Training program design complete; delivery scheduled Q2 2026 |
| ISO-A6.4 | A.6.4 | Disciplinary process | Disciplinary process for security policy violations documented | **Compliant** | HR policy documentation |
| ISO-A6.5 | A.6.5 | Responsibilities after termination | Access revocation procedure; exit interview checklist; NDA enforcement | **Compliant** | Offboarding checklist; access revocation API |

### 6.3 Physical Controls (Annex A.7)

| ID | ISO Control | Description | VoxGuard Implementation | Status | Evidence |
|----|------------|-------------|------------------------|--------|----------|
| ISO-A7.1 | A.7.1 | Physical security perimeters | Data center physical security managed by hosting providers (MDXi, Galaxy Backbone) | **Partial** | Hosting provider security certifications requested |
| ISO-A7.2 | A.7.2 | Physical entry controls | Biometric + card access at data centers; visitor logs maintained | **Partial** | Hosting provider controls; VoxGuard-specific controls TBD |
| ISO-A7.3 | A.7.3 | Securing offices, rooms, and facilities | Development team works in secured office with access controls | **Compliant** | Office security policy |
| ISO-A7.4 | A.7.4 | Physical security monitoring | CCTV and security monitoring at data center facilities | **Partial** | Hosting provider responsibility; audit pending |

### 6.4 Technological Controls (Annex A.8)

| ID | ISO Control | Description | VoxGuard Implementation | Status | Evidence |
|----|------------|-------------|------------------------|--------|----------|
| ISO-A8.1 | A.8.1 | User endpoint devices | Managed devices for production access; MDM policy | **Planned** | MDM solution selection in progress |
| ISO-A8.2 | A.8.2 | Privileged access rights | SYSTEM_ADMIN role restricted; Vault access logging; sudo auditing | **Compliant** | RBAC implementation; Vault audit logs |
| ISO-A8.3 | A.8.3 | Information access restriction | RBAC at application, GraphQL, and database levels; Hasura permissions | **Compliant** | Multi-layer access control implementation |
| ISO-A8.4 | A.8.4 | Access to source code | GitHub branch protection; PR review required; AIDD-governed merges | **Compliant** | GitHub settings; CI/CD configuration |
| ISO-A8.5 | A.8.5 | Secure authentication | RS256 JWT; MFA for admin roles; bcrypt password hashing (cost=12) | **Compliant** | Authentication implementation documentation |
| ISO-A8.6 | A.8.6 | Capacity management | Auto-scaling with defined thresholds; capacity planning forecasts | **Compliant** | HPA configuration; capacity planning document |
| ISO-A8.7 | A.8.7 | Protection against malware | Container image scanning; dependency vulnerability scanning (Trivy, Snyk) | **Compliant** | CI/CD pipeline security checks |
| ISO-A8.8 | A.8.8 | Management of technical vulnerabilities | Regular dependency updates; CVE monitoring; 72-hour critical patch SLA | **Compliant** | Vulnerability management process; patch history |
| ISO-A8.9 | A.8.9 | Configuration management | Infrastructure as Code (Helm, Terraform); GitOps (ArgoCD); no manual changes | **Compliant** | IaC repository; ArgoCD configuration |
| ISO-A8.10 | A.8.10 | Information deletion | Automated deletion after retention period; secure deletion verification | **Partial** | Automated deletion operational; secure wipe for storage TBD |
| ISO-A8.11 | A.8.11 | Data masking | PII masking in logs; field-level encryption for sensitive data via Vault Transit | **Compliant** | Log masking configuration; Vault Transit policies |
| ISO-A8.12 | A.8.12 | Data leakage prevention | Network egress filtering; no external data transfer; DLP monitoring | **Partial** | Network policies implemented; dedicated DLP tool planned Q3 2026 |
| ISO-A8.13 | A.8.13 | Information backup | YugabyteDB replication (RF3); DragonflyDB persistence; S3 archival | **Compliant** | Backup configuration; recovery testing results |
| ISO-A8.14 | A.8.14 | Redundancy of information processing | Multi-region deployment (3 regions); automatic failover | **Partial** | Single-region operational; multi-region planned Oct 2026 |
| ISO-A8.15 | A.8.15 | Logging | Comprehensive audit logging; immutable append-only logs; 7-year retention | **Compliant** | Audit logging implementation; retention policy |
| ISO-A8.16 | A.8.16 | Monitoring activities | Prometheus + Grafana; PagerDuty alerting; 24/7 automated monitoring | **Compliant** | Observability stack documentation |
| ISO-A8.17 | A.8.17 | Clock synchronization | NTP synchronization across all nodes; nanosecond-precision timestamps in detection engine | **Compliant** | NTP configuration; timestamp validation |
| ISO-A8.18 | A.8.18 | Use of privileged utility programs | Restricted to SYSTEM_ADMIN; logged via audit system | **Compliant** | Access control; audit logging |
| ISO-A8.19 | A.8.19 | Installation of software on operational systems | Immutable container images; no SSH to production; GitOps-only deployment | **Compliant** | Container security policy; ArgoCD enforcement |
| ISO-A8.20 | A.8.20 | Network security | Network segmentation; Kubernetes network policies; firewall rules | **Compliant** | Network architecture documentation |
| ISO-A8.21 | A.8.21 | Security of network services | mTLS for all internal communication; TLS 1.3 for external | **Compliant** | mTLS configuration; certificate management |
| ISO-A8.22 | A.8.22 | Segregation of networks | Production, staging, development in separate Kubernetes namespaces and VPCs | **Compliant** | Network topology documentation |
| ISO-A8.23 | A.8.23 | Web filtering | Egress filtering; DNS-based web filtering for production nodes | **Partial** | Basic egress filtering; dedicated web filter planned |
| ISO-A8.24 | A.8.24 | Use of cryptography | AES-256 (rest), TLS 1.3 (transit), RS256 (JWT), SHA-256 (integrity), bcrypt (passwords) | **Compliant** | Cryptographic standards documentation |
| ISO-A8.25 | A.8.25 | Secure development lifecycle | AIDD governance; code review; automated testing; security scanning in CI/CD | **Compliant** | SDLC documentation; CI/CD pipeline |
| ISO-A8.26 | A.8.26 | Application security requirements | Security requirements in PRD; threat modeling; OWASP compliance | **Compliant** | PRD security section; threat model |

---

## 7. PCI-DSS Requirements

> **Scope Note:** VoxGuard does not directly process, store, or transmit cardholder data. However, PCI-DSS controls are mapped because VoxGuard integrates with operator billing systems (BSS) that handle billing data, and settlement dispute resolution may involve financial transaction references.

### 7.1 PCI-DSS v4.0 Control Mapping

| ID | PCI-DSS Req | Description | VoxGuard Implementation | Status | Evidence |
|----|------------|-------------|------------------------|--------|----------|
| PCI-001 | Req 1 | Install and maintain network security controls | Kubernetes network policies; firewall rules; network segmentation between VoxGuard and BSS | **Compliant** | Network architecture; firewall rules |
| PCI-002 | Req 2 | Apply secure configurations to all system components | CIS benchmarks for Kubernetes; hardened container images; no default credentials | **Compliant** | Security hardening documentation |
| PCI-003 | Req 3 | Protect stored account data | VoxGuard does not store card data; billing references are tokenized before storage | **Compliant** | Data flow documentation; no card data in scope |
| PCI-004 | Req 4 | Protect cardholder data with strong cryptography during transmission | mTLS for BSS integration; TLS 1.3 for all external connections | **Compliant** | mTLS configuration; TLS settings |
| PCI-005 | Req 5 | Protect all systems and networks from malicious software | Container image scanning (Trivy); runtime security monitoring | **Compliant** | CI/CD security pipeline |
| PCI-006 | Req 6 | Develop and maintain secure systems and software | AIDD SDLC; code review; dependency scanning; security testing | **Compliant** | SDLC documentation; CI/CD pipeline |
| PCI-007 | Req 7 | Restrict access to system components by business need to know | RBAC with least privilege; Hasura row-level security | **Compliant** | RBAC matrix; Hasura permissions |
| PCI-008 | Req 8 | Identify users and authenticate access | RS256 JWT; MFA for admin; unique user IDs; password complexity | **Compliant** | Authentication documentation |
| PCI-009 | Req 9 | Restrict physical access to cardholder data | Data center physical security (hosting provider managed) | **Partial** | Hosting provider certifications pending |
| PCI-010 | Req 10 | Log and monitor all access to system components | Immutable audit logs; 7-year retention; real-time monitoring | **Compliant** | Audit logging implementation |
| PCI-011 | Req 11 | Test security of systems and networks regularly | Penetration testing planned quarterly; vulnerability scanning in CI/CD | **Partial** | First penetration test scheduled Q2 2026; automated scanning operational |
| PCI-012 | Req 12 | Support information security with organizational policies and programs | Security policies documented; AIDD governance; incident response plan | **Partial** | Policies documented; annual review process in development |

---

## 8. Telecom-Specific Regulations

### 8.1 ITU-T Recommendations

| ID | Recommendation | Description | VoxGuard Implementation | Status | Evidence |
|----|---------------|-------------|------------------------|--------|----------|
| ITU-001 | E.156 | Guidelines for international telephone routing | IRSF detection uses ITU-T E.156 destination risk scoring for international number ranges | **Compliant** | IRSF detection engine; E.156 integration |
| ITU-002 | E.157 | International numbering resource management | Nigerian numbering plan (+234) validation; international prefix validation | **Compliant** | MSISDN value object validation |
| ITU-003 | E.164 | International public telecommunication numbering plan | E.164 format validation for all CLI processing; proper international prefix handling | **Compliant** | Number format validation in detection engine |
| ITU-004 | Q.850 | ISUP cause codes | SIP-to-ISUP cause code mapping for call disconnection reasons | **Compliant** | Cause code mapping in voice switch integration |
| ITU-005 | X.800 | Security architecture for open systems interconnection | Security architecture aligned with X.800 framework (authentication, access control, data confidentiality, data integrity, non-repudiation) | **Compliant** | Security architecture documentation |

### 8.2 GSMA Fraud Management Guidelines

| ID | Guideline | Description | VoxGuard Implementation | Status | Evidence |
|----|----------|-------------|------------------------|--------|----------|
| GSMA-001 | FS.11 | SIM Swap Fraud Prevention | Not in scope (VoxGuard focuses on voice fraud, not SIM management) | **N/A** | Out of scope justification |
| GSMA-002 | FS.19 | CLI Spoofing Prevention | Full CLI validation against MNP, gateway IP, and ML-based scoring | **Compliant** | CLI detection implementation |
| GSMA-003 | FS.40 | SIM Box Fraud Detection | Sliding window detection with 5-second window, distinct A-number counting, behavioral analysis | **Compliant** | SIM-box detection engine |
| GSMA-004 | FS.07 | Wangiri Fraud Prevention | Short-duration call burst detection; premium-rate number range monitoring | **Partial** | Basic detection implemented; ML enhancement planned Aug 2026 |
| GSMA-005 | FS.14 | IRSF Prevention | Destination risk scoring using GSMA/ITU high-risk number databases | **Partial** | Basic scoring implemented; GSMA feed subscription pending |

### 8.3 Nigerian Numbering Plan Compliance

| ID | Requirement | Description | VoxGuard Implementation | Status | Evidence |
|----|-------------|-------------|------------------------|--------|----------|
| NNP-001 | +234 Prefix Validation | All Nigerian numbers must use +234 international prefix | MSISDN value object validates +234 prefix for Nigerian numbers | **Compliant** | MSISDN validation code |
| NNP-002 | Operator Prefix Recognition | Recognize MNO prefixes (MTN: 0803/0806/0816/etc., Airtel: 0802/0808/etc., Glo: 0805/0807/etc., 9mobile: 0809/0818/etc.) | Nigerian prefix database with operator mapping; updated quarterly | **Compliant** | `scripts/seed-nigerian-prefixes.sh`; prefix database |
| NNP-003 | Premium Rate Number Identification | Identify and flag calls to premium rate numbers | Premium rate number range database for Wangiri/IRSF detection | **Compliant** | Premium rate number database |
| NNP-004 | Emergency Number Protection | Never block calls to emergency numbers (112, 199, etc.) | Emergency number allowlist bypasses all fraud detection | **Compliant** | Emergency number bypass configuration |
| NNP-005 | Number Portability Awareness | Respect ported numbers in CLI validation | MNP database integration for accurate operator attribution of ported numbers | **Compliant** | MNP integration documentation |

---

## 9. AIDD Compliance

### 9.1 AIDD Governance Controls

| ID | Requirement | Description | VoxGuard Implementation | Status | Evidence |
|----|-------------|-------------|------------------------|--------|----------|
| AIDD-001 | Tiered Approval System | Three-tier approval model (T0/T1/T2) for all operations | AIDD tiers enforced at API gateway, GraphQL layer, and frontend | **Compliant** | AIDD_APPROVAL_TIERS.md; middleware implementation |
| AIDD-002 | Autonomous Operation Boundaries | Defined limits on autonomous agent actions | Rate limits: 100 auto-blocks/hour, 1000 auto-alerts/hour; circuit breakers | **Compliant** | Rate limiting configuration; circuit breaker policies |
| AIDD-003 | Human Override Capability | Human operators can override any autonomous decision | Override API endpoints; dashboard override controls; immediate effect | **Compliant** | Override API documentation; dashboard controls |
| AIDD-004 | Audit Trail for Autonomous Actions | All autonomous actions logged with full context | Immutable audit log entries include: agent identity, action, tier, timestamp, justification, reversibility | **Compliant** | Audit log schema; sample entries |
| AIDD-005 | Regulatory Submission Guard | NCC submissions never automated without human admin approval | T2 classification for all NCC ATRS submissions; SYSTEM_ADMIN + X-Admin-Approval header required | **Compliant** | API middleware enforcement; ATRS submission workflow |
| AIDD-006 | Conservative Auto-Blocking | Autonomous blocking only at very high confidence | Auto-block threshold: fraud score >= 0.95 (5% of total blocks are autonomous) | **Compliant** | Detection engine threshold configuration |
| AIDD-007 | Rollback Guarantee | T1 actions reversible within 5 minutes | All T1 actions (blocks, rule changes) can be reversed via undo API; state history maintained | **Compliant** | Undo API documentation; state history implementation |
| AIDD-008 | AIDD Compliance Monitoring | Regular monitoring of AIDD adherence | Weekly AIDD action distribution reports; anomaly alerts for unexpected T2 volumes | **Compliant** | Grafana AIDD dashboard; alerting rules |

### 9.2 AIDD Operation Classification

| Operation Category | Tier | Justification | Rate Limit |
|-------------------|------|---------------|------------|
| Dashboard viewing, analytics queries, health checks | T0 | Read-only; no state modification | Unlimited |
| Report generation (draft), log export | T0 | Read-only output; no external submission | Unlimited |
| Alert acknowledgment, false positive marking | T1 | Modifies alert state; reversible | 500/hour per user |
| Individual gateway blocking | T1 | Modifies traffic routing; reversible | 100/hour per user (auto); 50/hour per user (manual) |
| Detection rule creation/modification | T1 | Modifies detection behavior; reversible via version rollback | 20/hour |
| NCC report submission (to ATRS) | T2 | Regulatory submission; irreversible externally | N/A (manual only) |
| MNP bulk import | T2 | Large-scale data modification | N/A (manual only) |
| Database migration | T2 | Schema change; potentially irreversible | N/A (manual only) |
| User role/permission change | T2 | Security-critical modification | N/A (manual only) |
| Authentication/authorization settings | T2 | Security-critical; affects all users | N/A (manual only) |

---

## 10. Audit Requirements

### 10.1 Audit Trail Specifications

| Aspect | Specification |
|--------|--------------|
| **Retention Period** | 7 years (NCC ICL Framework 2026 mandate) |
| **Storage Format** | Structured JSON in YugabyteDB (warm, 0-90 days) + Parquet in S3 (cold, 90 days-7 years) |
| **Immutability** | Append-only table in YugabyteDB; S3 Object Lock (Compliance Mode) for archives |
| **Integrity** | SHA-256 hash chain; each entry references hash of previous entry |
| **Compression** | ZSTD compression for archived data (~75% size reduction) |
| **Encryption** | AES-256 at rest; TLS 1.3 in transit; Vault Transit for sensitive fields |
| **Access Control** | Read access: SYSTEM_ADMIN, COMPLIANCE_OFFICER; Write access: system only (no manual writes) |
| **Tamper Detection** | Hash chain verification; daily integrity check job; alert on chain break |

### 10.2 Audit Log Schema

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `audit_id` | UUID | Unique audit entry identifier | `a1b2c3d4-e5f6-...` |
| `timestamp` | Timestamp (ns) | Nanosecond-precision event timestamp | `2026-02-12T14:30:00.123456789Z` |
| `actor_id` | UUID | User or service account identifier | `u1234-...` or `svc-detection-engine` |
| `actor_type` | Enum | `USER`, `SERVICE`, `AUTONOMOUS_AGENT`, `SYSTEM` | `USER` |
| `actor_role` | String | RBAC role of the actor | `FRAUD_ANALYST` |
| `action` | String | Action performed | `GATEWAY_BLOCKED` |
| `aidd_tier` | Enum | `T0`, `T1`, `T2` | `T1` |
| `resource_type` | String | Type of resource affected | `GATEWAY` |
| `resource_id` | String | Identifier of affected resource | `gw-lagos-001` |
| `details` | JSON | Action-specific details | `{"fraud_score": 0.97, "reason": "SIM-box detected"}` |
| `previous_state` | JSON | State before action (for reversibility) | `{"status": "active"}` |
| `new_state` | JSON | State after action | `{"status": "blocked"}` |
| `ip_address` | String | Source IP of the actor | `10.0.1.50` |
| `user_agent` | String | Client user agent | `VoxGuard-Dashboard/1.0` |
| `hash` | String | SHA-256 of this entry + previous hash | `sha256:abc123...` |
| `previous_hash` | String | SHA-256 hash of previous entry | `sha256:xyz789...` |

### 10.3 Audit Types & Retention

| Audit Category | Logged Events | Retention | NCC Reporting |
|---------------|---------------|-----------|---------------|
| **Detection Events** | Every fraud alert generated, including score, evidence, and action taken | 7 years | Daily/Monthly aggregate |
| **Operator Actions** | All dashboard interactions: alert acknowledgment, gateway blocking, rule changes | 7 years | On request |
| **Authentication Events** | Login, logout, failed attempts, MFA events, token refresh | 7 years | On request |
| **Configuration Changes** | Detection threshold changes, RBAC modifications, system settings | 7 years | On request |
| **NCC Submissions** | Every report submitted to ATRS, including content, acknowledgment, and response | 7 years | Self-referential |
| **Data Access** | DSAR requests, data exports, bulk queries | 7 years | On request (NDPA) |
| **System Events** | Deployment, scaling, failover, database migration, archival | 7 years | On request |
| **AIDD Actions** | All T0/T1/T2 actions with tier classification and justification | 7 years | Quarterly AIDD review |

### 10.4 Audit Schedule

| Audit Type | Frequency | Auditor | Scope | Deliverable |
|-----------|-----------|---------|-------|-------------|
| Internal Security Audit | Quarterly | VoxGuard Security Team | Security controls, access reviews, vulnerability assessment | Internal audit report |
| NCC Compliance Audit | Quarterly | NCC-approved auditor | NCC regulatory compliance, ATRS integration, detection accuracy | NCC compliance certificate |
| NDPA Data Protection Audit | Annual | Independent DPA auditor | Data processing, retention, subject rights, breach procedures | NDPA compliance report |
| SOC 2 Type II Audit | Annual | Independent SOC auditor | Trust service criteria (security, availability, processing integrity, confidentiality) | SOC 2 Type II report |
| ISO 27001 Certification Audit | Annual (after initial) | ISO certification body | Information security management system | ISO 27001 certificate |
| Penetration Test | Semi-annual | Independent security firm | External and internal attack surface | Penetration test report |
| AIDD Governance Review | Quarterly | Architecture Review Board | AIDD tier compliance, autonomous operation limits, audit trail integrity | AIDD governance report |

---

## 11. Compliance Calendar

### 11.1 2026 Compliance Calendar

| Month | Activity | Regulatory Domain | Owner | Deadline |
|-------|---------|-------------------|-------|----------|
| **Jan** | Annual compliance planning | All | Compliance Lead | Jan 15 |
| **Feb** | NDPA DPIA completion | NDPA | Legal | Feb 28 |
| **Feb** | This document (Compliance Matrix v1.0) | All | Compliance Lead | Feb 12 |
| **Mar** | Q1 internal security audit | ISO 27001, SOC 2 | Security Lead | Mar 31 |
| **Mar** | First penetration test | SOC 2, ISO 27001 | Security Lead | Mar 31 |
| **Apr** | NCC ATRS sandbox validation complete | NCC | Engineering Lead | Apr 30 |
| **May** | NCC ATRS production integration go-live | NCC | Engineering Lead | May 15 |
| **May** | Operator training program delivery | NCC | Training Lead | May 31 |
| **Jun** | Q2 internal security audit | ISO 27001, SOC 2 | Security Lead | Jun 30 |
| **Jun** | Phase 1 GA compliance review | NCC, NDPA | Compliance Lead | Jun 30 |
| **Jul** | SOC 2 Type II observation period begins | SOC 2 | Compliance Lead | Jul 1 |
| **Aug** | ML pipeline compliance review (bias, fairness) | NDPA, AIDD | ML Lead | Aug 31 |
| **Sep** | Q3 internal security audit | ISO 27001, SOC 2 | Security Lead | Sep 30 |
| **Sep** | Second penetration test | SOC 2, ISO 27001 | Security Lead | Sep 30 |
| **Oct** | NCC ICL Framework 2026 certification submission | NCC | Compliance Lead | Oct 31 |
| **Oct** | Multi-region compliance validation | NCC, NDPA | DevOps Lead | Oct 31 |
| **Nov** | AIDD governance annual review | AIDD | Architecture Board | Nov 30 |
| **Dec** | SOC 2 Type II observation period ends | SOC 2 | Compliance Lead | Dec 31 |
| **Dec** | ISO 27001 Stage 1 audit preparation | ISO 27001 | Security Lead | Dec 31 |

### 11.2 Recurring Compliance Activities

| Frequency | Activity | Owner |
|-----------|---------|-------|
| **Daily** | NCC daily statistics report submission (06:00 WAT) | Automated (ATRS integration) |
| **Weekly** | NCC weekly summary report submission (Monday 12:00 WAT) | Automated (ATRS integration) |
| **Monthly** | NCC monthly compliance report submission (5th of month) | Compliance Lead (T2 approval) |
| **Monthly** | Data archival job execution and integrity verification | DevOps Lead |
| **Quarterly** | Internal security audit and access review | Security Lead |
| **Quarterly** | NCC compliance audit | External auditor |
| **Quarterly** | AIDD governance review | Architecture Board |
| **Semi-annual** | Penetration testing | External security firm |
| **Annual** | NDPA compliance audit | External DPA auditor |
| **Annual** | SOC 2 Type II audit | External SOC auditor |
| **Annual** | NCC annual compliance report (January 31st) | Compliance Lead |

---

## 12. Gap Analysis & Remediation Plan

### 12.1 Critical Gaps

| ID | Gap | Regulatory Domain | Current State | Target State | Remediation | Target Date | Owner | Priority |
|----|-----|-------------------|---------------|-------------|-------------|-------------|-------|----------|
| GAP-001 | NCC ATRS production integration not complete | NCC ICL Framework | Sandbox testing | Production automated submission | Complete ATRS API integration testing; obtain NCC production credentials | May 2026 | Engineering Lead | **Critical** |
| GAP-002 | NCC certification not yet obtained | NCC ICL Framework | Certification package in preparation | NCC certification issued | Complete all compliance evidence; submit certification package; address NCC feedback | Oct 2026 | Compliance Lead | **Critical** |
| GAP-003 | Detection accuracy at 99.5% (target 99.8%) | NCC Fraud Prevention | 99.5% with rule engine | 99.8% with ML augmentation | Deploy ML pipeline with fraud scoring models; continuous retraining | Aug 2026 | ML Lead | **High** |
| GAP-004 | Multi-region deployment not yet operational | NCC, SOC 2 | Single-region (Lagos) | 3 regions with auto-failover | Deploy Abuja and Asaba clusters; configure replication; validate failover | Oct 2026 | DevOps Lead | **High** |

### 12.2 Medium Gaps

| ID | Gap | Regulatory Domain | Current State | Target State | Remediation | Target Date | Owner | Priority |
|----|-----|-------------------|---------------|-------------|-------------|-------------|-------|----------|
| GAP-005 | GSMA fraud intelligence feed not integrated | GSMA, NCC | No GSMA feed | GSMA FS.14 IRSF feed active | Complete GSMA FMG membership; integrate IRSF feed | Sep 2026 | Product Lead | Medium |
| GAP-006 | SOC 2 Type II audit not started | SOC 2 | Controls implemented | SOC 2 report issued | Begin observation period Jul 2026; engage SOC auditor | Dec 2026 | Compliance Lead | Medium |
| GAP-007 | ISO 27001 certification not started | ISO 27001 | Controls aligned | ISO 27001 certified | Stage 1 audit preparation Dec 2026; certification Q1 2027 | Mar 2027 | Security Lead | Medium |
| GAP-008 | Penetration testing not yet conducted | SOC 2, ISO 27001 | Planned | Semi-annual pen tests operational | Engage pen test firm; first test Q1 2026 | Mar 2026 | Security Lead | Medium |
| GAP-009 | NDPC breach notification automation incomplete | NDPA | Manual procedure documented | Automated notification workflow | Implement automated NDPC notification; test with tabletop exercise | Jun 2026 | Compliance Lead | Medium |
| GAP-010 | Data center security certifications pending | ISO 27001, PCI-DSS | Hosting provider selected | Certifications on file | Obtain MDXi and Galaxy Backbone security certifications | Apr 2026 | DevOps Lead | Medium |

### 12.3 Low Gaps

| ID | Gap | Regulatory Domain | Current State | Target State | Remediation | Target Date | Owner | Priority |
|----|-----|-------------------|---------------|-------------|-------------|-------------|-------|----------|
| GAP-011 | Security awareness training program not yet delivered | ISO 27001 | Program designed | Annual training delivered | Deliver initial training; establish annual refresh cycle | May 2026 | Security Lead | Low |
| GAP-012 | DLP (Data Leakage Prevention) tool not deployed | ISO 27001 | Network policies only | Dedicated DLP monitoring | Evaluate and deploy DLP solution | Sep 2026 | Security Lead | Low |
| GAP-013 | MDM (Mobile Device Management) not deployed | ISO 27001 | Policy defined | MDM operational | Select and deploy MDM solution for production access devices | Jun 2026 | IT Lead | Low |
| GAP-014 | Operator NDAs/DPAs not fully executed | SOC 2, GDPR | Templates drafted | All agreements signed | Execute agreements with all partner operators | May 2026 | Legal | Low |

### 12.4 Remediation Progress Tracking

| Gap ID | Feb 2026 | Mar 2026 | Apr 2026 | May 2026 | Jun 2026 | Jul 2026 | Aug 2026 | Sep 2026 | Oct 2026 |
|--------|----------|----------|----------|----------|----------|----------|----------|----------|----------|
| GAP-001 | In progress | Testing | Testing | **Complete** | | | | | |
| GAP-002 | Planning | Preparation | Preparation | Evidence | Evidence | Submission | Review | Review | **Complete** |
| GAP-003 | Design | Design | Development | Development | Development | Development | **Complete** | | |
| GAP-004 | Design | Design | Provisioning | Provisioning | Testing | Testing | Testing | Validation | **Complete** |
| GAP-005 | Application | Application | Pending | Pending | Integration | Integration | Integration | **Complete** | |
| GAP-006 | Planning | Planning | Planning | Planning | Planning | **Start** | Observation | Observation | Observation |
| GAP-007 | Planning | Planning | Planning | Planning | Planning | Planning | Planning | Planning | Preparation |
| GAP-008 | Engagement | **Complete** | | Ongoing | | | Ongoing | | |
| GAP-009 | Development | Development | Development | Testing | **Complete** | | | | |
| GAP-010 | Requested | Follow-up | **Complete** | | | | | | |

---

## Appendix A: Regulatory Reference Library

| Document | Issuer | Version | Effective Date | VoxGuard Relevance |
|----------|--------|---------|---------------|-------------------|
| Nigerian Communications Act 2003 | National Assembly | - | 2003 | Primary telecommunications law; licensing framework |
| Consumer Code of Practice Regulations 2007 | NCC | - | 2007 | Consumer protection obligations |
| Type Approval Regulations 2018 | NCC | - | 2018 | Equipment and system certification |
| Numbering Regulations 2019 | NCC | - | 2019 | CLI integrity; numbering plan compliance |
| Nigeria Data Protection Act 2023 | National Assembly | - | 2023 | Primary data protection law |
| CLI Integrity Guidelines 2024 | NCC | 1.0 | 2024 | CLI validation and spoofing detection requirements |
| Fraud Prevention Framework 2023 | NCC | 1.0 | 2023 | Fraud detection system requirements |
| NCC ICL Framework 2026 | NCC | 1.0 | 2026 | Comprehensive ICL compliance framework |
| GDPR | European Parliament | - | 2018 | International partner data protection |
| SOC 2 | AICPA | 2017 TSC | 2018 | Service organization controls |
| ISO 27001:2022 | ISO | 2022 | 2022 | Information security management |
| PCI-DSS v4.0 | PCI SSC | 4.0 | 2024 | Payment card data security |
| ITU-T E.156 | ITU | - | Latest | International telephone routing guidelines |
| ITU-T E.164 | ITU | - | Latest | International numbering plan |
| GSMA FS.19 | GSMA | - | Latest | CLI spoofing prevention |
| GSMA FS.40 | GSMA | - | Latest | SIM-box fraud detection |

## Appendix B: Compliance Team Contact Information

| Role | Responsibility | Escalation Path |
|------|---------------|-----------------|
| Compliance Lead | Overall compliance program management | CTO -> Executive Sponsor |
| Legal Counsel | Regulatory interpretation, contract review | Compliance Lead -> Executive Sponsor |
| Security Architect | Security controls implementation and audit | CTO -> Compliance Lead |
| DPO (Data Protection Officer) | NDPA/GDPR compliance, DSAR management | Compliance Lead -> Legal |
| NCC Liaison | NCC relationship management, certification | Compliance Lead -> Executive Sponsor |
| External Auditor (SOC 2) | Independent SOC 2 Type II audit | Compliance Lead |
| External Auditor (ISO 27001) | ISO certification audit | Security Architect |
| Penetration Test Firm | Security assessment | Security Architect |

## Appendix C: Approval Signatures

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Compliance Lead | _________________ | _________________ | ____/____/2026 |
| Legal Counsel | _________________ | _________________ | ____/____/2026 |
| Security Architect | _________________ | _________________ | ____/____/2026 |
| CTO | _________________ | _________________ | ____/____/2026 |
| Executive Sponsor | _________________ | _________________ | ____/____/2026 |

---

*This Compliance & Regulatory Matrix is a living document reviewed quarterly. Updates follow the AIDD Tier 0 governance process (auto-approved documentation changes). Substantive compliance posture changes are reported to the Steering Committee. Next scheduled review: May 2026.*
