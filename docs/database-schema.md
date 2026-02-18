# Database Schema — VoxGuard
> Version: 1.0 | Last Updated: 2026-02-18 | Status: Draft
> Classification: Internal | Author: AIDD System

## 1. Overview

Database schema design for VoxGuard using YugabyteDB as the primary distributed SQL database.

## 2. Database Strategy

- **Primary Store**: YugabyteDB (PostgreSQL-compatible distributed SQL)
- **Cache**: DragonflyDB (Redis-compatible)
- **Search**: Quickwit (full-text search and analytics)
- **Object Store**: RustFS (S3-compatible)

## 3. Core Tables

### 3.1 Users & Authentication
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255),
    status VARCHAR(20) DEFAULT 'active',
    role VARCHAR(50) DEFAULT 'user',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 3.2 Core Entities
```sql
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    plan VARCHAR(50) DEFAULT 'free',
    status VARCHAR(20) DEFAULT 'active',
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE resources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    config JSONB DEFAULT '{}'::jsonb,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 3.3 Audit Trail
```sql
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id UUID,
    details JSONB DEFAULT '{}'::jsonb,
    ip_address INET,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## 4. Indexes

```sql
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_resources_org ON resources(org_id, type);
CREATE INDEX idx_audit_user ON audit_log(user_id, created_at DESC);
CREATE INDEX idx_audit_resource ON audit_log(resource_type, resource_id);
```

## 5. Data Migration Strategy

- Versioned migrations using golang-migrate
- Blue-green database schema changes
- Backward-compatible migrations only
- Automated rollback procedures
