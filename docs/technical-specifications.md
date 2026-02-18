# VoxGuard API Reference

**Version:** 1.0
**Date:** February 12, 2026
**Status:** Production
**Owner:** VoxGuard Engineering Team
**Classification:** Confidential -- Internal Use Only
**AIDD Compliance:** Tier 0 (Documentation)

---

## Document Control

| Field | Value |
|-------|-------|
| Document ID | VG-API-2026-001 |
| Version | 1.0 |
| Author | VoxGuard Engineering Team |
| Reviewed By | Architecture Board, Security Architect |
| Approved By | CTO |
| Effective Date | February 12, 2026 |
| Next Review | May 2026 |

---

## Table of Contents

1. [Overview](#1-overview)
2. [Authentication & Authorization](#2-authentication--authorization)
3. [Common Conventions](#3-common-conventions)
4. [Detection Engine API (Rust)](#4-detection-engine-api-rust)
5. [Management API (Go)](#5-management-api-go)
6. [GraphQL API (Hasura)](#6-graphql-api-hasura)
7. [NCC Compliance API (Python)](#7-ncc-compliance-api-python)
8. [Metrics & Health Endpoints](#8-metrics--health-endpoints)
9. [WebSocket & Subscriptions](#9-websocket--subscriptions)
10. [Error Handling](#10-error-handling)
11. [Rate Limiting](#11-rate-limiting)
12. [SDKs & Client Libraries](#12-sdks--client-libraries)

---

## 1. Overview

VoxGuard exposes four API layers, each optimized for its domain:

| API Layer | Technology | Base URL | Purpose |
|-----------|-----------|----------|---------|
| **Detection Engine** | Rust / Actix-web | `http://localhost:8080` | Real-time fraud detection (<1ms latency) |
| **Management API** | Go / Gin | `http://localhost:8081` | CRUD operations, gateway management, analytics |
| **GraphQL API** | Hasura | `http://localhost:8082/v1/graphql` | Frontend data access, real-time subscriptions |
| **NCC Compliance** | Python | `http://localhost:8083` | NCC ATRS integration, report generation |

### API Architecture

```
                    ┌─────────────────────────┐
                    │    Web / Mobile Apps     │
                    │   (React, Flutter, iOS)  │
                    └────────────┬────────────┘
                                 │ GraphQL (Hasura)
                    ┌────────────▼────────────┐
                    │     Hasura Gateway       │
                    │  (Auth, Permissions, WS) │
                    └────────────┬────────────┘
                                 │
           ┌─────────────────────┼─────────────────────┐
           │                     │                      │
  ┌────────▼────────┐  ┌────────▼────────┐  ┌─────────▼────────┐
  │ Detection Engine │  │ Management API  │  │ NCC Compliance   │
  │  (Rust, :8080)   │  │  (Go, :8081)    │  │ (Python, :8083)  │
  └────────┬────────┘  └────────┬────────┘  └─────────┬────────┘
           │                     │                      │
  ┌────────▼─────────────────────▼──────────────────────▼────────┐
  │  DragonflyDB  │  YugabyteDB  │  ClickHouse  │  QuestDB      │
  └──────────────────────────────────────────────────────────────┘
```

---

## 2. Authentication & Authorization

### 2.1 JWT Authentication

All Management API and GraphQL requests require a JWT Bearer token (except `/auth/login` and `/auth/refresh`).

**Token Request:**
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "username": "analyst@voxguard.ng",
  "password": "secure-password"
}
```

**Token Response:**
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4...",
  "expires_at": "2026-02-12T14:30:00Z",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "analyst@voxguard.ng",
    "roles": ["analyst"],
    "is_active": true,
    "last_login": "2026-02-12T12:30:00Z"
  }
}
```

**Using the Token:**
```http
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

**JWT Claims Structure:**
```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "username": "analyst@voxguard.ng",
  "email": "analyst@voxguard.ng",
  "roles": ["analyst"],
  "iat": 1707739800,
  "exp": 1707743400,
  "iss": "acm-management-api",
  "sub": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Token Refresh:**
```http
POST /api/v1/auth/refresh
Content-Type: application/json

{
  "refresh_token": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4..."
}
```

**Logout:**
```http
POST /api/v1/auth/logout
Authorization: Bearer {access_token}
```

### 2.2 Role-Based Access Control (RBAC)

| Role | Level | Permissions |
|------|-------|------------|
| **viewer** | 1 | Read alerts, dashboards only |
| **operator** | 2 | viewer + acknowledge alerts |
| **analyst** | 3 | operator + investigate, whitelist, export data |
| **supervisor** | 4 | analyst + modify configuration, detection thresholds |
| **admin** | 5 | Full administrative access, user management, NCC submissions |
| **superadmin** | 6 | System-level access, all roles override |

### 2.3 Service-to-Service Authentication

Internal microservice communication uses:
- **API Key Authentication** via `X-API-Key` header
- **mTLS** for secure mesh communication between services
- **Hasura Admin Secret** for backend-to-Hasura queries

---

## 3. Common Conventions

### 3.1 Request Headers

| Header | Required | Description |
|--------|----------|-------------|
| `Authorization` | Yes (except public endpoints) | `Bearer {jwt_token}` |
| `Content-Type` | Yes (for POST/PUT/PATCH) | `application/json` |
| `Accept` | Optional | `application/json` (default) |
| `X-Request-ID` | Optional | Unique request identifier for tracing (auto-generated if omitted) |
| `Accept-Language` | Optional | `en`, `fr`, `pt`, `ha`, `yo`, `ig`, `ar`, `es`, `zh`, `sw` |

### 3.2 Pagination

All list endpoints support cursor-based pagination:

```http
GET /api/v1/alerts?limit=20&offset=0&sort=detected_at&order=desc
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `limit` | integer | 20 | Items per page (max 100) |
| `offset` | integer | 0 | Number of items to skip |
| `sort` | string | `created_at` | Sort field |
| `order` | string | `desc` | Sort direction (`asc` or `desc`) |

**Pagination Response Headers:**
```
X-Total-Count: 1542
X-Page-Size: 20
X-Page-Offset: 0
```

### 3.3 Filtering

List endpoints support field-based filtering:

```http
GET /api/v1/alerts?status=pending&severity=critical&fraud_type=CLI_MASKING
GET /api/v1/gateways?is_active=true&carrier_name=MTN
```

### 3.4 Date/Time Format

All timestamps use ISO 8601 format in UTC:
```
2026-02-12T14:30:00Z
```

Date range filters use `_from` and `_to` suffixes:
```http
GET /api/v1/alerts?detected_at_from=2026-02-01T00:00:00Z&detected_at_to=2026-02-12T23:59:59Z
```

### 3.5 Phone Number Format

All phone numbers use E.164 format:
```
+2348012345678   (Nigerian mobile)
+2349012345678   (Nigerian mobile)
+44207123456     (UK landline)
```

---

## 4. Detection Engine API (Rust)

**Base URL:** `http://localhost:8080`
**Technology:** Rust / Actix-web
**Latency Target:** <1ms P99
**Throughput:** 150,000+ CPS

> The Detection Engine is the core real-time fraud detection service. It processes call events, maintains sliding detection windows in DragonflyDB, and generates fraud alerts.

### 4.1 Register Call Event

Registers a call for real-time fraud detection. This is the primary high-throughput endpoint called by the Voice Switch integration.

```http
POST /event
Content-Type: application/json
```

**Request Body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `call_id` | string (UUID) | No | Unique call identifier (auto-generated if omitted) |
| `a_number` | string | **Yes** | Calling party number (E.164 format) |
| `b_number` | string | **Yes** | Called party number (E.164 format) |
| `source_ip` | string | No | Source gateway IP (defaults to `0.0.0.0`) |
| `switch_id` | string | No | Voice switch identifier |
| `timestamp` | string (ISO 8601) | No | Event timestamp (defaults to server time) |

**Request Example:**
```json
{
  "call_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "a_number": "+2348012345678",
  "b_number": "+2348098765432",
  "source_ip": "10.0.1.50",
  "switch_id": "lagos-c4-01"
}
```

**Response (No Fraud Detected):**
```json
{
  "status": "ok",
  "latency_us": 142
}
```

**Response (Fraud Alert Generated):**
```json
{
  "status": "alert",
  "alert": {
    "alert_id": "ALERT-1707739800123456",
    "b_number": "+2348098765432",
    "call_count": 7,
    "created_at": "2026-02-12T14:30:00.123456Z",
    "description": "Masking Attack Detected"
  },
  "latency_us": 287
}
```

**Detection Algorithm:**
- Maintains a 5-second sliding window per B-number
- Triggers alert when >= 5 distinct A-numbers call the same B-number within the window
- Nanosecond-precision timestamps for accurate windowing

### 4.2 Get Threat Level

Returns the current threat assessment for a specific B-number.

```http
GET /threat/{b_number}
```

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `b_number` | string | Target phone number (E.164, URL-encoded) |

**Response:**
```json
{
  "b_number": "+2348098765432",
  "threat_level": "high",
  "distinct_callers": 4,
  "threshold": 5,
  "requires_action": false
}
```

### 4.3 Acknowledge Alert

Acknowledges a fraud alert, assigning it to an analyst.

```http
POST /alerts/{alert_id}/acknowledge
Content-Type: application/json
```

**Request Body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `alert_id` | string | **Yes** | Alert identifier |
| `user_id` | string | **Yes** | Acknowledging analyst identifier |

**Response:**
```json
{
  "status": "acknowledged",
  "alert_id": "ALERT-1707739800123456",
  "acknowledged_by": "analyst-1"
}
```

### 4.4 Get Alert

Retrieves details for a specific alert.

```http
GET /alerts/{alert_id}
```

**Response:**
```json
{
  "alert_id": "ALERT-1707739800123456",
  "b_number": "+2348098765432",
  "a_numbers": ["+2348011111111", "+2348022222222", "+2348033333333", "+2348044444444", "+2348055555555"],
  "call_count": 5,
  "source_ips": ["10.0.1.50", "10.0.1.51"],
  "severity": "critical",
  "status": "new",
  "created_at": "2026-02-12T14:30:00.123456Z",
  "acknowledged_by": null,
  "acknowledged_at": null,
  "resolved_by": null,
  "resolved_at": null
}
```

### 4.5 Resolve Alert

Resolves a fraud alert with a disposition.

```http
POST /alerts/{alert_id}/resolve
Content-Type: application/json
```

**Request Body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `user_id` | string | **Yes** | Resolving analyst identifier |
| `resolution` | string (enum) | **Yes** | `confirmed_fraud`, `false_positive`, `escalated`, `whitelisted` |
| `notes` | string | No | Resolution notes |

**Response:**
```json
{
  "status": "resolved",
  "alert_id": "ALERT-1707739800123456",
  "resolved_by": "analyst-1",
  "resolution": "confirmed_fraud"
}
```

---

## 5. Management API (Go)

**Base URL:** `http://localhost:8081`
**Technology:** Go / Gin
**Authentication:** JWT Bearer Token

> The Management API provides CRUD operations, dashboard analytics, user management, and integration endpoints for the VoxGuard platform.

### 5.1 Gateway Management

#### List Gateways

```http
GET /api/v1/gateways
Authorization: Bearer {token}
```

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `is_active` | boolean | Filter by active status |
| `carrier_name` | string | Filter by carrier (MTN, Glo, Airtel, 9mobile) |
| `gateway_type` | string | Filter by type (`local`, `international`, `transit`) |
| `is_blacklisted` | boolean | Filter by blacklist status |
| `limit` | integer | Items per page (default 20, max 100) |
| `offset` | integer | Pagination offset |

**Response:**
```json
{
  "data": [
    {
      "id": "gw-001",
      "name": "Lagos Gateway 1",
      "ip_address": "10.0.0.1",
      "carrier_name": "MTN Nigeria",
      "gateway_type": "local",
      "fraud_threshold": 0.75,
      "cpm_limit": 100,
      "acd_threshold": 15.0,
      "is_active": true,
      "is_blacklisted": false,
      "calls_today": 45230,
      "fraud_count": 12,
      "created_at": "2026-01-15T10:00:00Z",
      "updated_at": "2026-02-12T08:30:00Z"
    }
  ],
  "total": 42,
  "limit": 20,
  "offset": 0
}
```

**Required Role:** `analyst` or higher

#### Create Gateway

```http
POST /api/v1/gateways
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| `name` | string | **Yes** | 3-100 characters |
| `ip_address` | string | **Yes** | Valid IPv4/IPv6 |
| `carrier_name` | string | **Yes** | Known carrier name |
| `gateway_type` | string | **Yes** | `local`, `international`, `transit` |
| `fraud_threshold` | float | No | 0.0-1.0 (default 0.75) |
| `cpm_limit` | integer | No | 1-10000 (default 100) |
| `acd_threshold` | float | No | 0.0-300.0 (default 15.0) |

**Required Role:** `admin` or higher

#### Get Gateway Details

```http
GET /api/v1/gateways/{id}
Authorization: Bearer {token}
```

**Required Role:** `analyst` or higher

#### Update Gateway

```http
PUT /api/v1/gateways/{id}
Authorization: Bearer {token}
Content-Type: application/json
```

**Required Role:** `admin` or higher

#### Delete Gateway

```http
DELETE /api/v1/gateways/{id}
Authorization: Bearer {token}
```

**Required Role:** `admin` or higher

#### Get Gateway Statistics

```http
GET /api/v1/gateways/{id}/stats
Authorization: Bearer {token}
```

**Response:**
```json
{
  "gateway_id": "gw-001",
  "period": "24h",
  "total_calls": 45230,
  "fraud_calls": 12,
  "fraud_rate": 0.027,
  "avg_acd": 180.5,
  "peak_cpm": 87,
  "uptime_percent": 99.99
}
```

**Required Role:** `analyst` or higher

#### Enable/Disable Gateway

```http
POST /api/v1/gateways/{id}/enable
POST /api/v1/gateways/{id}/disable
Authorization: Bearer {token}
```

**Required Role:** `admin` or higher

#### Update Thresholds

```http
PATCH /api/v1/gateways/{id}/thresholds
Authorization: Bearer {token}
Content-Type: application/json

{
  "fraud_threshold": 0.80,
  "cpm_limit": 150,
  "acd_threshold": 20.0
}
```

**Required Role:** `supervisor` or higher

#### Blacklist Gateway

```http
POST /api/v1/gateways/{id}/blacklist
Authorization: Bearer {token}
Content-Type: application/json

{
  "reason": "Confirmed CLI masking source",
  "expires_at": "2026-03-12T00:00:00Z"
}
```

**Required Role:** `admin` or higher

### 5.2 Fraud Alert Management

#### List Fraud Alerts

```http
GET /api/v1/fraud/alerts
Authorization: Bearer {token}
```

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `status` | string | `pending`, `acknowledged`, `investigating`, `resolved`, `reported_ncc` |
| `severity` | integer | 1 (low) to 5 (critical) |
| `event_type` | string | `CLI_MASK`, `SIM_BOX`, `REFILING`, `WANGIRI`, `IRSF` |
| `detected_at_from` | string | ISO 8601 start date |
| `detected_at_to` | string | ISO 8601 end date |
| `is_acknowledged` | boolean | Filter by acknowledgment status |
| `limit` | integer | Items per page |
| `offset` | integer | Pagination offset |

**Response:**
```json
{
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "call_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
      "event_type": "CLI_MASK",
      "source_ip": "10.0.1.50",
      "caller_id": "+2348012345678",
      "called_number": "+2348098765432",
      "confidence": 0.97,
      "severity": 5,
      "action_taken": "gateway_blocked",
      "description": "CLI masking attack: 7 distinct callers in 5s window",
      "is_acknowledged": false,
      "acknowledged_by": null,
      "acknowledged_at": null,
      "is_resolved": false,
      "resolved_by": null,
      "resolved_at": null,
      "resolution_notes": null,
      "ncc_reported": false,
      "ncc_report_id": null,
      "detected_at": "2026-02-12T14:30:00Z"
    }
  ],
  "total": 156,
  "limit": 20,
  "offset": 0
}
```

**Required Role:** `analyst` or higher

#### Get Alert Details

```http
GET /api/v1/fraud/alerts/{id}
Authorization: Bearer {token}
```

**Required Role:** `analyst` or higher

#### Acknowledge Alert

```http
POST /api/v1/fraud/alerts/{id}/acknowledge
Authorization: Bearer {token}
```

**Required Role:** `analyst` or higher

#### Resolve Alert

```http
POST /api/v1/fraud/alerts/{id}/resolve
Authorization: Bearer {token}
Content-Type: application/json

{
  "resolution": "confirmed_fraud",
  "notes": "Verified CLI masking attack from gateway gw-042. 7 distinct A-numbers targeting same B-number within 3.2 seconds."
}
```

| Field | Type | Required | Values |
|-------|------|----------|--------|
| `resolution` | string | **Yes** | `confirmed_fraud`, `false_positive`, `escalated`, `whitelisted` |
| `notes` | string | No | Resolution notes (max 2000 chars) |

**Required Role:** `analyst` or higher

#### Get SIM Box Suspects

```http
GET /api/v1/fraud/simbox-suspects
Authorization: Bearer {token}
```

**Required Role:** `analyst` or higher

#### Get Fraud Patterns

```http
GET /api/v1/fraud/patterns
Authorization: Bearer {token}
```

**Required Role:** `analyst` or higher

#### Get Geographic Heatmap

```http
GET /api/v1/fraud/heatmap
Authorization: Bearer {token}
```

**Required Role:** `analyst` or higher

### 5.3 Blacklist Management

#### List Blacklist Entries

```http
GET /api/v1/blacklist
Authorization: Bearer {token}
```

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `entry_type` | string | `ip`, `cli`, `prefix`, `carrier` |
| `source` | string | `manual`, `ncc`, `auto` |
| `is_active` | boolean | Filter active entries |

**Response:**
```json
{
  "data": [
    {
      "id": "bl-001",
      "entry_type": "cli",
      "value": "+2348012345678",
      "reason": "Confirmed fraud source",
      "source": "manual",
      "added_by": "admin@voxguard.ng",
      "expires_at": "2026-06-12T00:00:00Z",
      "is_active": true,
      "ncc_synced": true,
      "ncc_synced_at": "2026-02-12T15:00:00Z"
    }
  ],
  "total": 89
}
```

**Required Role:** `analyst` or higher (read), `admin` (write)

#### Add to Blacklist

```http
POST /api/v1/blacklist
Authorization: Bearer {token}
Content-Type: application/json

{
  "entry_type": "cli",
  "value": "+2348012345678",
  "reason": "Confirmed CLI masking source",
  "expires_at": "2026-06-12T00:00:00Z"
}
```

| Field | Type | Required | Values |
|-------|------|----------|--------|
| `entry_type` | string | **Yes** | `ip`, `cli`, `prefix`, `carrier` |
| `value` | string | **Yes** | Entry value (IP, phone number, prefix, or carrier name) |
| `reason` | string | **Yes** | Reason for blacklisting |
| `expires_at` | string | No | Expiry date (ISO 8601). Permanent if omitted. |

**Required Role:** `admin` or higher

#### Remove from Blacklist

```http
DELETE /api/v1/blacklist/{id}
Authorization: Bearer {token}
```

**Required Role:** `admin` or higher

#### Sync with NCC Blacklist

```http
POST /api/v1/blacklist/sync-ncc
Authorization: Bearer {token}
```

Synchronizes the local blacklist with the NCC national blacklist.

**Required Role:** `admin` or higher

### 5.4 MNP (Mobile Number Portability)

#### Lookup MSISDN

```http
GET /api/v1/mnp/lookup/{msisdn}
Authorization: Bearer {token}
```

**Path Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `msisdn` | string | Nigerian mobile number (E.164 or local format) |

**Response:**
```json
{
  "msisdn": "+2348012345678",
  "routing_number": "62001",
  "operator_name": "MTN Nigeria",
  "is_ported": false,
  "source": "cache"
}
```

| Source | Description |
|--------|-------------|
| `cache` | Result from DragonflyDB cache |
| `database` | Result from YugabyteDB |
| `prefix` | Derived from number prefix lookup |

**Required Role:** `analyst` or higher

#### Bulk MSISDN Lookup

```http
POST /api/v1/mnp/bulk-lookup
Authorization: Bearer {token}
Content-Type: application/json

{
  "msisdns": ["+2348012345678", "+2348098765432", "+2349011111111"]
}
```

Max 100 numbers per request.

**Required Role:** `analyst` or higher

#### MNP Statistics

```http
GET /api/v1/mnp/stats
Authorization: Bearer {token}
```

**Required Role:** `analyst` or higher

#### Import MNP Data

```http
POST /api/v1/mnp/import
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Required Role:** `admin` or higher (AIDD Tier 2)

### 5.5 NCC Compliance

#### List Compliance Reports

```http
GET /api/v1/compliance/reports
Authorization: Bearer {token}
```

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `report_type` | string | `daily`, `weekly`, `monthly` |
| `status` | string | `pending`, `submitted`, `acknowledged`, `failed` |
| `report_date_from` | string | Start date filter |
| `report_date_to` | string | End date filter |

**Response:**
```json
{
  "data": [
    {
      "id": "rpt-20260212",
      "report_type": "daily",
      "report_date": "2026-02-12",
      "total_calls": 8542100,
      "fraud_calls": 2341,
      "file_path": "/reports/ACM_DAILY_ICL-001_20260212.csv",
      "submitted_at": "2026-02-12T05:30:00Z",
      "ncc_ack_id": "NCC-ACK-2026021200042",
      "status": "acknowledged"
    }
  ],
  "total": 30
}
```

**Required Role:** `analyst` or higher

#### Get Report Details

```http
GET /api/v1/compliance/reports/{id}
Authorization: Bearer {token}
```

**Required Role:** `analyst` or higher

#### Generate Compliance Report

```http
POST /api/v1/compliance/reports/generate
Authorization: Bearer {token}
Content-Type: application/json

{
  "report_type": "daily",
  "report_date": "2026-02-12"
}
```

**Required Role:** `admin` or higher (AIDD Tier 1 for draft, Tier 2 for submission)

#### Get Audit Trail

```http
GET /api/v1/compliance/audit-trail
Authorization: Bearer {token}
```

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `actor` | string | Filter by user |
| `action` | string | Filter by action type |
| `from` | string | Start timestamp |
| `to` | string | End timestamp |

**Required Role:** `analyst` or higher

#### List Settlement Disputes

```http
GET /api/v1/compliance/settlement-disputes
Authorization: Bearer {token}
```

**Required Role:** `analyst` or higher

#### Create Settlement Dispute

```http
POST /api/v1/compliance/settlement-disputes
Authorization: Bearer {token}
Content-Type: application/json

{
  "dispute_type": "fraud_related",
  "operator": "MTN Nigeria",
  "amount": 1500000.00,
  "currency": "NGN",
  "description": "Disputed interconnect charges for CLI-masked traffic from gateway gw-042",
  "evidence_ids": ["alert-001", "alert-002", "cdr-batch-042"]
}
```

**Required Role:** `analyst` or higher

### 5.6 Dashboard & Analytics

#### Dashboard Summary

```http
GET /api/v1/dashboard/summary
Authorization: Bearer {token}
```

**Response:**
```json
{
  "total_calls_24h": 8542100,
  "fraud_calls_24h": 2341,
  "fraud_rate_24h": 0.027,
  "active_gateways": 42,
  "pending_alerts": 7,
  "avg_confidence": 0.94,
  "fraud_by_type": {
    "CLI_MASK": 1456,
    "SIM_BOX": 423,
    "WANGIRI": 267,
    "IRSF": 142,
    "REFILING": 53
  },
  "top_offenders": [
    {"id": "gw-042", "name": "Lagos Gateway 42", "fraud_count": 156}
  ],
  "ncc_report_status": "submitted"
}
```

**Required Role:** `analyst` or higher

#### Real-Time Statistics

```http
GET /api/v1/dashboard/realtime
Authorization: Bearer {token}
```

**Required Role:** `analyst` or higher

#### Trend Analysis

```http
GET /api/v1/dashboard/trends
Authorization: Bearer {token}
```

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `period` | string | `1h`, `6h`, `24h`, `7d`, `30d` |
| `metric` | string | `fraud_rate`, `total_calls`, `alert_count` |

**Required Role:** `analyst` or higher

#### CDR Summary

```http
GET /api/v1/analytics/cdr-summary
Authorization: Bearer {token}
```

**Required Role:** `analyst` or higher

#### Traffic Analysis

```http
GET /api/v1/analytics/traffic-analysis
Authorization: Bearer {token}
```

**Required Role:** `analyst` or higher

#### Fraud Trends

```http
GET /api/v1/analytics/fraud-trends
Authorization: Bearer {token}
```

**Required Role:** `analyst` or higher

#### Gateway Performance

```http
GET /api/v1/analytics/gateway-performance
Authorization: Bearer {token}
```

**Required Role:** `analyst` or higher

#### Export Data

```http
POST /api/v1/analytics/export
Authorization: Bearer {token}
Content-Type: application/json

{
  "format": "csv",
  "data_type": "alerts",
  "date_from": "2026-02-01T00:00:00Z",
  "date_to": "2026-02-12T23:59:59Z",
  "filters": {
    "severity": [4, 5],
    "event_type": ["CLI_MASK", "SIM_BOX"]
  }
}
```

**Required Role:** `admin` or higher

### 5.7 User Management

#### List Users

```http
GET /api/v1/users
Authorization: Bearer {token}
```

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `role` | string | Filter by role |
| `is_active` | boolean | Filter by active status |

**Required Role:** `admin` or higher

#### Create User

```http
POST /api/v1/users
Authorization: Bearer {token}
Content-Type: application/json

{
  "username": "new.analyst@voxguard.ng",
  "email": "new.analyst@voxguard.ng",
  "password": "SecureP@ssw0rd!",
  "roles": ["analyst"],
  "is_active": true
}
```

**Password Policy:** Minimum 12 characters, requires uppercase, lowercase, digit, and special character.

**Required Role:** `admin` or higher

#### Update User

```http
PUT /api/v1/users/{id}
Authorization: Bearer {token}
Content-Type: application/json
```

**Required Role:** `admin` or higher

#### Delete User

```http
DELETE /api/v1/users/{id}
Authorization: Bearer {token}
```

**Required Role:** `admin` or higher

---

## 6. GraphQL API (Hasura)

**Endpoint:** `http://localhost:8082/v1/graphql`
**WebSocket:** `ws://localhost:8082/v1/graphql`
**Technology:** Hasura GraphQL Engine over YugabyteDB

> The GraphQL API is the primary data access layer for web and mobile frontend applications. It provides real-time subscriptions, fine-grained RBAC, and optimized query execution.

### 6.1 Custom Scalars

| Scalar | Format | Example |
|--------|--------|---------|
| `DateTime` | ISO 8601 | `"2026-02-12T14:30:00Z"` |
| `UUID` | UUID v4 | `"550e8400-e29b-41d4-a716-446655440000"` |
| `JSON` | Raw JSON | `{"key": "value"}` |

### 6.2 Enums

```graphql
enum CallStatus    { RINGING, ACTIVE, COMPLETED, FAILED, BLOCKED }
enum FraudType     { CLI_MASKING, SIMBOX, WANGIRI, IRSF, PBX_HACKING }
enum AlertStatus   { PENDING, ACKNOWLEDGED, INVESTIGATING, RESOLVED, REPORTED_NCC }
enum Severity      { LOW, MEDIUM, HIGH, CRITICAL }
enum ResolutionType { CONFIRMED_FRAUD, FALSE_POSITIVE, ESCALATED, WHITELISTED }
enum UserRole      { USER, PROVIDER, ANALYST, ADMIN, SUPER_ADMIN }
enum UserStatus    { PENDING, ACTIVE, SUSPENDED, DEACTIVATED }
```

### 6.3 Queries

#### Alerts

```graphql
# List alerts with filters
query GetAlerts($limit: Int, $offset: Int, $status: AlertStatus, $severity: Severity) {
  alerts(limit: $limit, offset: $offset, status: $status, severity: $severity) {
    id
    call_id
    fraud_type
    severity
    status
    confidence
    caller_id
    called_number
    source_ip
    description
    detected_at
    acknowledged_by
    acknowledged_at
    resolved_by
    resolved_at
    resolution_notes
    ncc_reported
  }
}

# Get alert count by status
query AlertCounts {
  alertsCount(status: PENDING)
}

# Single alert
query GetAlert($id: UUID!) {
  alert(id: $id) {
    id
    fraud_type
    severity
    status
    confidence
    description
    detected_at
  }
}
```

#### Gateways

```graphql
query GetGateways($limit: Int, $offset: Int, $isActive: Boolean) {
  gateways(limit: $limit, offset: $offset, isActive: $isActive) {
    id
    name
    ip_address
    carrier_name
    gateway_type
    is_active
    is_blacklisted
    fraud_threshold
    cpm_limit
    acd_threshold
    created_at
    updated_at
  }
}

query GetGateway($id: UUID!) {
  gateway(id: $id) {
    id
    name
    ip_address
    carrier_name
    gateway_type
    is_active
    is_blacklisted
  }
}
```

#### Users & Dashboard

```graphql
query Me {
  me {
    id
    username
    email
    roles
    is_active
    last_login
  }
}

query DashboardSummary {
  dashboardSummary {
    total_calls_24h
    fraud_calls_24h
    fraud_rate_24h
    active_gateways
    pending_alerts
  }
}
```

### 6.4 Mutations

```graphql
# Alert workflow
mutation AcknowledgeAlert($alertId: UUID!) {
  acknowledgeAlert(alertId: $alertId) {
    id
    status
    acknowledged_by
    acknowledged_at
  }
}

mutation ResolveAlert($alertId: UUID!, $resolution: ResolutionType!, $notes: String) {
  resolveAlert(alertId: $alertId, resolution: $resolution, notes: $notes) {
    id
    status
    resolved_by
    resolved_at
    resolution_notes
  }
}

mutation ReportToNCC($alertId: UUID!) {
  reportToNCC(alertId: $alertId) {
    id
    ncc_reported
  }
}

# Gateway management
mutation CreateGateway($input: CreateGatewayInput!) {
  createGateway(input: $input) {
    id
    name
    ip_address
  }
}

mutation BlacklistGateway($id: UUID!, $reason: String!) {
  blacklistGateway(id: $id, reason: $reason) {
    id
    is_blacklisted
  }
}

# Authentication
mutation Login($email: String!, $password: String!) {
  login(email: $email, password: $password) {
    access_token
    refresh_token
    user {
      id
      username
      roles
    }
  }
}
```

### 6.5 Hasura Permissions (Row-Level Security)

| Table | Role | Select | Insert | Update | Delete |
|-------|------|--------|--------|--------|--------|
| `acm_alerts` | admin | All | All | All | All |
| `acm_alerts` | analyst | All | No | status, notes | No |
| `acm_alerts` | viewer | All (read-only) | No | No | No |
| `acm_gateways` | admin | All | All | All | All |
| `acm_gateways` | analyst | All | No | No | No |
| `acm_users` | admin | All | All | All | All |
| `acm_users` | analyst | id, username, role | No | No | No |
| `acm_settings` | admin | All | All | All | No |
| `acm_settings` | analyst | Non-sensitive only | No | No | No |
| `acm_audit_logs` | admin | All | All | No | No |
| `acm_audit_logs` | analyst | All | Insert only | No | No |

---

## 7. NCC Compliance API (Python)

**Base URL:** `http://localhost:8083`
**Technology:** Python / FastAPI
**Authentication:** OAuth 2.0 Client Credentials (for NCC ATRS)

> The NCC Compliance API handles all interactions with the Nigerian Communications Commission's Automated Trouble Reporting System (ATRS), including fraud incident submission, compliance report generation, and SFTP CDR uploads.

### 7.1 Submit Fraud Incident to NCC

```http
POST /api/v1/ncc/incidents
Authorization: Bearer {internal_token}
Content-Type: application/json
```

**Request Body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `incident_type` | string | **Yes** | `CLI_SPOOFING`, `WANGIRI`, `IRSF`, `REVENUE_FRAUD`, `SIM_BOX`, `OTHER` |
| `severity` | string | **Yes** | `CRITICAL`, `HIGH`, `MEDIUM`, `LOW` |
| `detected_at` | string | **Yes** | ISO 8601 detection timestamp |
| `b_number` | string | **Yes** | Target phone number |
| `a_numbers` | array | **Yes** | Source phone numbers (max 100) |
| `detection_window_ms` | integer | **Yes** | Detection window duration in milliseconds |
| `source_ips` | array | No | Source gateway IPs |
| `actions_taken` | array | No | Actions taken (e.g., `gateway_blocked`, `alert_generated`) |
| `metadata` | object | No | Additional incident metadata |

**Response:**
```json
{
  "incident_id": "NCC-INC-2026021200042",
  "status": "RECEIVED"
}
```

**NCC ATRS Incident Statuses:** `RECEIVED`, `ACKNOWLEDGED`, `INVESTIGATING`, `CROSS_OPERATOR`, `RESOLVED`, `CLOSED`

### 7.2 NCC ATRS OAuth 2.0 Authentication

The NCC Compliance service authenticates with the NCC ATRS API using OAuth 2.0 Client Credentials:

```
Token Endpoint: {NCC_ATRS_BASE_URL}/oauth/token
Grant Type: client_credentials
Scopes: fraud:write, fraud:read, compliance:write, compliance:read
```

**Required Headers for NCC Requests:**
```
Authorization: Bearer {ncc_oauth_token}
X-ICL-License: {icl_license_number}
X-Request-ID: {unique_request_id}
```

### 7.3 Report Generation

Reports are generated in NCC-compliant CSV format:

| Report Type | Filename Pattern | Schedule |
|------------|-----------------|----------|
| Daily Statistics | `ACM_DAILY_{LICENSE}_{YYYYMMDD}.csv` | 05:30 WAT daily |
| Alert Details | `ACM_ALERTS_{LICENSE}_{YYYYMMDD}.csv` | 05:30 WAT daily |
| Top Targets | `ACM_TARGETS_{LICENSE}_{YYYYMMDD}.csv` | 05:30 WAT daily |
| Weekly Summary | Generated with weekly aggregation | Monday 11:00 WAT |
| Monthly Summary | Generated with monthly aggregation | 5th at 16:00 WAT |

All reports include SHA-256 checksums for integrity verification.

### 7.4 SFTP CDR Upload

CDR files are uploaded to the NCC SFTP server using:
- SSH key authentication (RSA)
- Atomic transfers (upload to `.tmp` then rename)
- Upload verification with size matching

---

## 8. Metrics & Health Endpoints

### 8.1 Health Check (All Services)

```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "service": "detection-engine",
  "region": "lagos",
  "uptime_seconds": 864000,
  "databases": {
    "dragonfly": "connected",
    "yugabyte": "connected",
    "clickhouse": "connected",
    "questdb": "connected"
  }
}
```

**Status Values:** `healthy`, `degraded`, `unhealthy`

**HTTP Status Codes:**
- `200` - Healthy or Degraded
- `503` - Unhealthy

### 8.2 Kubernetes Probes

```http
GET /healthz        # Liveness probe (process alive)
GET /readyz         # Readiness probe (ready for traffic)
```

### 8.3 Prometheus Metrics

```http
GET /metrics
```

**Key Metrics:**

| Metric | Type | Labels | Description |
|--------|------|--------|-------------|
| `acm_calls_total` | Counter | `status`, `region` | Total calls processed |
| `acm_detection_latency_seconds` | Histogram | `region` | Detection latency distribution |
| `acm_alerts_total` | Counter | `fraud_type`, `severity`, `region` | Alerts generated |
| `acm_cache_operations_total` | Counter | `operation`, `result` | Cache hit/miss rates |
| `acm_active_calls` | Gauge | - | Current calls in detection window |
| `acm_pending_alerts` | Gauge | - | Unacknowledged alerts count |
| `acm_gateway_calls_total` | Counter | `gateway_id`, `carrier` | Calls per gateway |
| `acm_blacklist_entries` | Gauge | `entry_type` | Current blacklist size |
| `acm_ncc_reports_total` | Counter | `report_type`, `status` | NCC reports generated |

---

## 9. WebSocket & Subscriptions

### 9.1 GraphQL Subscriptions

**WebSocket URL:** `ws://localhost:8082/v1/graphql`
**Protocol:** `graphql-ws`

```graphql
# Real-time alert notifications
subscription OnAlertCreated {
  alertCreated {
    id
    fraud_type
    severity
    status
    caller_id
    called_number
    detected_at
  }
}

# Alert status changes
subscription OnAlertUpdated($id: UUID!) {
  alertUpdated(id: $id) {
    id
    status
    acknowledged_by
    resolved_by
  }
}

# New call registrations
subscription OnCallRegistered {
  callRegistered {
    id
    a_number
    b_number
    status
    created_at
  }
}

# Gateway blacklist events
subscription OnGatewayBlacklisted {
  gatewayBlacklisted {
    id
    name
    ip_address
    is_blacklisted
  }
}
```

### 9.2 Dashboard Real-Time Updates

The web dashboard uses polling queries with 10-second intervals for:
- Alert count subscriptions (New, Critical, Investigating, Confirmed)
- Recent alerts table
- Dashboard summary statistics

---

## 10. Error Handling

### 10.1 Standard Error Response

All APIs return errors in a consistent format:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request: a_number is required",
    "details": [
      {
        "field": "a_number",
        "message": "Field is required and must be in E.164 format"
      }
    ],
    "request_id": "req-550e8400-e29b-41d4"
  }
}
```

### 10.2 Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `VALIDATION_ERROR` | 400 | Invalid request parameters or body |
| `UNAUTHORIZED` | 401 | Missing or invalid authentication token |
| `FORBIDDEN` | 403 | Insufficient role permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `CONFLICT` | 409 | Resource conflict (duplicate entry, state conflict) |
| `RATE_LIMITED` | 429 | Too many requests (see Rate Limiting section) |
| `INTERNAL_ERROR` | 500 | Unexpected server error |
| `SERVICE_UNAVAILABLE` | 503 | Dependent service unavailable (database, cache) |

### 10.3 GraphQL Error Format

```json
{
  "errors": [
    {
      "message": "Not authorized",
      "extensions": {
        "code": "FORBIDDEN",
        "path": "$.selectionSet.deleteGateway"
      }
    }
  ]
}
```

---

## 11. Rate Limiting

### 11.1 Management API Limits

| Endpoint Category | Limit | Window | Scope |
|-------------------|-------|--------|-------|
| Authentication | 10 requests | 1 minute | Per IP |
| Read operations | 100 requests | 1 minute | Per user |
| Write operations | 30 requests | 1 minute | Per user |
| Export/Report | 5 requests | 1 minute | Per user |
| Admin operations | 50 requests | 1 minute | Per user |

### 11.2 Rate Limit Headers

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1707740460
```

### 11.3 Rate Limit Response

```http
HTTP/1.1 429 Too Many Requests
Retry-After: 42
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1707740460

{
  "error": {
    "code": "RATE_LIMITED",
    "message": "Rate limit exceeded. Retry after 42 seconds.",
    "request_id": "req-550e8400"
  }
}
```

---

## 12. SDKs & Client Libraries

### 12.1 Web (TypeScript/React)

The web portal uses Apollo Client for GraphQL:

```typescript
import { ApolloClient, InMemoryCache, split, HttpLink } from '@apollo/client';
import { GraphQLWsLink } from '@apollo/client/link/subscriptions';
import { createClient } from 'graphql-ws';

const httpLink = new HttpLink({ uri: '/v1/graphql' });
const wsLink = new GraphQLWsLink(createClient({ url: 'ws://localhost:8082/v1/graphql' }));

const client = new ApolloClient({
  link: split(
    ({ query }) => /* subscription check */,
    wsLink,
    httpLink
  ),
  cache: new InMemoryCache(),
});
```

### 12.2 Flutter (Dart)

Ferry GraphQL client with code generation:

```dart
import 'package:ferry/ferry.dart';

final client = Client(
  link: HttpLink('http://localhost:8082/v1/graphql'),
  cache: Cache(),
);
```

### 12.3 Android (Kotlin)

Apollo Kotlin with Hilt dependency injection:

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object ApolloModule {
    @Provides
    @Singleton
    fun provideApolloClient(): ApolloClient {
        return ApolloClient.Builder()
            .serverUrl("http://localhost:8082/v1/graphql")
            .build()
    }
}
```

### 12.4 iOS (Swift)

Apollo iOS with The Composable Architecture:

```swift
let apolloClient = ApolloClient(url: URL(string: "http://localhost:8082/v1/graphql")!)
```

---

*This document is maintained under version control and subject to the AIDD governance framework. All API changes must be reflected in this reference before deployment.*
