# Training Program Overview
## Anti-Call Masking Detection System

---

## Training Catalog

### Course Categories

| Category | Target Audience | Duration |
|----------|-----------------|----------|
| Administrator Training | System Admins, DevOps | 8 hours |
| SOC Analyst Training | Security Analysts | 6 hours |
| API Developer Training | Developers, Integrators | 4 hours |
| Executive Overview | Management, Stakeholders | 1 hour |

---

## Course 1: Administrator Training

### Module 1.1: System Architecture (2 hours)
- System components overview
- Data flow and processing pipeline
- Deployment architectures
- High availability concepts

### Module 1.2: Installation & Configuration (2 hours)
- Prerequisites and planning
- Docker deployment
- Kubernetes deployment
- Configuration management

### Module 1.3: Operations & Maintenance (2 hours)
- Health monitoring
- Log analysis
- Backup and recovery
- Performance tuning

### Module 1.4: Security & Compliance (2 hours)
- Access control management
- Audit logging
- Security best practices
- Compliance requirements

**Hands-on Labs:**
- Lab 1: Deploy ACM using Docker Compose
- Lab 2: Configure detection parameters
- Lab 3: Set up monitoring and alerting
- Lab 4: Perform backup and recovery

---

## Course 2: SOC Analyst Training

### Module 2.1: Fraud Detection Fundamentals (1 hour)
- Understanding call masking fraud
- Attack patterns and indicators
- Detection methodology
- Alert severity levels

### Module 2.2: Dashboard Operations (1.5 hours)
- Dashboard navigation
- Real-time monitoring
- Alert management
- Search and filtering

### Module 2.3: Investigation Procedures (2 hours)
- Alert triage process
- Investigation workflow
- Evidence collection
- Documentation standards

### Module 2.4: Response & Escalation (1.5 hours)
- Response procedures by severity
- Call disconnection process
- Pattern blocking
- Escalation protocols

**Hands-on Labs:**
- Lab 1: Navigate the SOC dashboard
- Lab 2: Investigate a simulated fraud alert
- Lab 3: Execute response procedures
- Lab 4: Generate incident reports

---

## Course 3: API Developer Training

### Module 3.1: API Overview (1 hour)
- API architecture
- Authentication methods
- Available endpoints
- Data models

### Module 3.2: Integration Patterns (1.5 hours)
- Event submission
- Alert retrieval
- Webhook integration
- Real-time streaming

### Module 3.3: Implementation Workshop (1.5 hours)
- Code examples
- Error handling
- Rate limiting
- Best practices

**Hands-on Labs:**
- Lab 1: Submit call events via API
- Lab 2: Build alert monitoring client
- Lab 3: Implement webhook handler

---

## Course 4: Executive Overview

### Topics Covered (1 hour)
- Business value proposition
- ROI and fraud prevention metrics
- System capabilities
- Implementation roadmap
- Success stories

---

## Training Resources

### Video Training Library

| Video ID | Title | Duration | Audience |
|----------|-------|----------|----------|
| VT-001 | System Overview | 15 min | All |
| VT-002 | Dashboard Quick Start | 20 min | Analysts |
| VT-003 | Alert Investigation Walkthrough | 30 min | Analysts |
| VT-004 | API Integration Guide | 25 min | Developers |
| VT-005 | Deployment Tutorial | 45 min | Admins |
| VT-006 | Troubleshooting Guide | 20 min | Admins |

### Documentation
- Administrator Manual
- SOC Analyst Manual
- API Developer Manual
- Quick Reference Cards

### Lab Environment
- Sandbox environment: `https://sandbox.acm.yourcompany.com`
- Test API key: Available upon registration
- Sample data: Pre-loaded fraud scenarios

---

## Certification Program

### Certification Levels

| Level | Requirements | Validity |
|-------|--------------|----------|
| ACM Certified User | Complete SOC Analyst course + exam | 2 years |
| ACM Certified Administrator | Complete Admin course + exam | 2 years |
| ACM Certified Developer | Complete Developer course + exam | 2 years |

### Examination Details
- Format: Multiple choice + practical scenarios
- Passing score: 80%
- Retake policy: 2 attempts included
- Exam duration: 90 minutes

---

## Training Schedule

### Self-Paced Online
- Available 24/7
- Complete at your own pace
- Lab access for 30 days

### Instructor-Led (Virtual)
- Weekly sessions
- Interactive Q&A
- Group exercises

### On-Site Training
- Customized curriculum
- Hands-on with your environment
- Contact training@yourcompany.com

---

## Video Training Scripts

### VT-001: System Overview

**Script Outline:**

```
[0:00-1:00] Introduction
- Welcome and objectives
- What is call masking fraud?

[1:00-4:00] The Problem
- Traditional fraud bypass techniques
- Financial impact of call masking
- Detection challenges

[4:00-8:00] Our Solution
- Real-time detection with kdb+
- 5-second sliding window
- Automatic response capabilities

[8:00-12:00] System Architecture
- Component overview
- Data flow explanation
- Integration points

[12:00-15:00] Key Features
- Sub-millisecond detection
- Auto-disconnect capability
- Analytics and reporting
- Mobile monitoring

[15:00] Summary and next steps
```

### VT-003: Alert Investigation Walkthrough

**Script Outline:**

```
[0:00-2:00] Introduction
- Investigation importance
- Alert lifecycle

[2:00-5:00] Alert Triage
- Opening alert details
- Severity assessment
- Priority assignment

[5:00-15:00] Investigation Process
- Analyzing A-numbers
- Checking source IPs
- Timeline reconstruction
- Pattern identification

[15:00-22:00] Response Actions
- Disconnecting calls (demo)
- Blocking patterns
- Documentation

[22:00-28:00] Case Study
- Real-world example
- Step-by-step walkthrough

[28:00-30:00] Summary
- Key takeaways
- Resources
```

---

## Assessment Questions

### Sample Questions - SOC Analyst

1. **What is the default detection threshold for multicall masking?**
   - A) 3 distinct A-numbers
   - B) 5 distinct A-numbers ✓
   - C) 7 distinct A-numbers
   - D) 10 distinct A-numbers

2. **What is the recommended response time for CRITICAL severity alerts?**
   - A) < 1 minute
   - B) < 5 minutes ✓
   - C) < 15 minutes
   - D) < 30 minutes

3. **Which of the following is NOT an indicator of call masking fraud?**
   - A) Multiple A-numbers to single B-number
   - B) Calls within 5-second window
   - C) Same source IP for different CLIs
   - D) Single A-number to single B-number ✓

### Sample Questions - Administrator

1. **Which port does kdb+ use for IPC communication?**
   - A) 5000 ✓
   - B) 5001
   - C) 8080
   - D) 5060

2. **What is the recommended minimum RAM for production deployment?**
   - A) 4 GB
   - B) 8 GB
   - C) 16 GB ✓
   - D) 32 GB

---

## Contact & Support

- **Training Coordinator:** training@yourcompany.com
- **Technical Support:** support@yourcompany.com
- **Documentation:** https://docs.acm.yourcompany.com
- **Community Forum:** https://community.acm.yourcompany.com
