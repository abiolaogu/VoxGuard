# Product Requirements Document (PRD)
## Anti-Call Masking Detection System

### 1. Introduction
The Anti-Call Masking Detection System is a real-time fraud detection platform designed to identify and mitigate "Call Masking" (CLI Spoofing) attacks in telecommunications networks. It leverages high-performance computing to detect patterns where multiple A-numbers (clean caller IDs) are used to reach a single B-number (destination) within a short time window.

### 2. Objectives
-   **Minimize Latency**: Detection must occur in < 1 millisecond.
-   ** maximize Scalability**: Support internet-scale traffic (millions of concurrent calls).
-   **Eliminate Fraud**: Automatically identify and block masking attempts before they cause significant revenue loss.

### 3. User Personas
-   **SOC Analyst**: Monitors real-time alerts and investigates fraud patterns.
-   **Network Administrator**: Manages the infrastructure (Kubernetes, ClickHouse, DragonflyDB).
-   **API Developer**: Integrates the fraud detection engine with Voice Switches (Kamailio, Asterisk).
-   **Executive**: Views high-level reports on fraud savings and system ROI.

### 4. Functional Requirements
#### 4.1 Detection Engine
-   Must use a sliding window algorithm (default 5 seconds).
-   Must trigger an alert if > X distinct A-numbers call one B-number.
-   Must be stateless to allow horizontal scaling.

#### 4.2 Storage & History
-   All call events must be logged asynchronously for historical analysis.
-   Alerts must be persisted indefinitely for legal/compliance auditing.

#### 4.3 API
-   RESTful API for submitting call events.
-   Health check endpoint for load balancers.

### 5. Non-Functional Requirements
-   **Performance**: 99th percentile latency < 1ms.
-   **Availability**: 99.999% uptime.
-   **Security**: Internal APIs strictly isolated; no public internet access to databases.
