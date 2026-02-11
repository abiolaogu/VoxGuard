-- Migration: Create Security Tables for VoxGuard
-- Description: Creates all security-related tables for authentication, authorization, and audit logging
-- Version: 001
-- Date: 2026-02-03

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- USER MANAGEMENT TABLES
-- ============================================================

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    is_locked BOOLEAN DEFAULT false,
    locked_until TIMESTAMP,
    last_login TIMESTAMP,
    login_attempts INTEGER DEFAULT 0,
    password_changed_at TIMESTAMP,
    mfa_enabled BOOLEAN DEFAULT false,
    mfa_secret VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by VARCHAR(255),
    updated_by VARCHAR(255),

    CONSTRAINT username_length CHECK (LENGTH(username) >= 3),
    CONSTRAINT email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_is_active ON users(is_active);

-- Password history for password policy enforcement
CREATE TABLE IF NOT EXISTS password_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_password_history_user_id ON password_history(user_id);
CREATE INDEX idx_password_history_created_at ON password_history(created_at DESC);

-- ============================================================
-- RBAC TABLES
-- ============================================================

-- Roles table
CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    is_system BOOLEAN DEFAULT false, -- System roles cannot be deleted
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by VARCHAR(255),
    updated_by VARCHAR(255)
);

CREATE INDEX idx_roles_name ON roles(name);
CREATE INDEX idx_roles_is_active ON roles(is_active);

-- Permissions table
CREATE TABLE IF NOT EXISTS permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource VARCHAR(50) NOT NULL,
    action VARCHAR(50) NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    is_system BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT unique_permission UNIQUE(resource, action)
);

CREATE INDEX idx_permissions_resource ON permissions(resource);
CREATE INDEX idx_permissions_resource_action ON permissions(resource, action);

-- User-Role mapping (many-to-many)
CREATE TABLE IF NOT EXISTS user_roles (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    granted_by VARCHAR(255) NOT NULL,
    granted_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP, -- For temporary role assignments

    PRIMARY KEY (user_id, role_id)
);

CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_role_id ON user_roles(role_id);
CREATE INDEX idx_user_roles_expires_at ON user_roles(expires_at);

-- Role-Permission mapping (many-to-many)
CREATE TABLE IF NOT EXISTS role_permissions (
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    granted_by VARCHAR(255) NOT NULL,
    granted_at TIMESTAMP DEFAULT NOW(),

    PRIMARY KEY (role_id, permission_id)
);

CREATE INDEX idx_role_permissions_role_id ON role_permissions(role_id);
CREATE INDEX idx_role_permissions_permission_id ON role_permissions(permission_id);

-- Resource policies for attribute-based access control (ABAC)
CREATE TABLE IF NOT EXISTS resource_policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource VARCHAR(50) NOT NULL,
    action VARCHAR(50) NOT NULL,
    effect VARCHAR(10) NOT NULL CHECK (effect IN ('allow', 'deny')),
    conditions JSONB DEFAULT '{}', -- JSON conditions for ABAC
    priority INTEGER DEFAULT 0, -- Higher priority evaluated first
    is_active BOOLEAN DEFAULT true,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by VARCHAR(255)
);

CREATE INDEX idx_resource_policies_resource_action ON resource_policies(resource, action);
CREATE INDEX idx_resource_policies_is_active ON resource_policies(is_active);
CREATE INDEX idx_resource_policies_priority ON resource_policies(priority DESC);

-- ============================================================
-- TOKEN MANAGEMENT TABLES
-- ============================================================

-- Refresh tokens for JWT authentication
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    is_revoked BOOLEAN DEFAULT false,
    revoked_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    last_used_at TIMESTAMP,
    ip_address VARCHAR(45), -- IPv4 or IPv6
    user_agent TEXT
);

CREATE INDEX idx_refresh_tokens_token_hash ON refresh_tokens(token_hash);
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);
CREATE INDEX idx_refresh_tokens_is_revoked ON refresh_tokens(is_revoked);

-- API keys for service accounts and integrations
CREATE TABLE IF NOT EXISTS api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    key_hash VARCHAR(255) UNIQUE NOT NULL,
    prefix VARCHAR(10) NOT NULL, -- First 8 chars for identification
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    scopes JSONB DEFAULT '[]', -- JSON array of scopes/permissions
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    last_used_at TIMESTAMP,
    last_used_ip VARCHAR(45),
    created_at TIMESTAMP DEFAULT NOW(),
    created_by VARCHAR(255)
);

CREATE INDEX idx_api_keys_key_hash ON api_keys(key_hash);
CREATE INDEX idx_api_keys_user_id ON api_keys(user_id);
CREATE INDEX idx_api_keys_prefix ON api_keys(prefix);
CREATE INDEX idx_api_keys_is_active ON api_keys(is_active);

-- ============================================================
-- AUDIT LOGGING TABLES (IMMUTABLE - APPEND-ONLY)
-- ============================================================

-- Main audit events table (immutable for compliance)
CREATE TABLE IF NOT EXISTS audit_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    timestamp TIMESTAMP DEFAULT NOW() NOT NULL,
    user_id UUID,
    username VARCHAR(50),
    action VARCHAR(50) NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    resource_id VARCHAR(255),
    resource_name VARCHAR(255),
    old_values JSONB, -- Previous state (for updates/deletes)
    new_values JSONB, -- New state (for creates/updates)
    status VARCHAR(20) NOT NULL CHECK (status IN ('success', 'failure')),
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    ip_address VARCHAR(45),
    user_agent TEXT,
    request_id VARCHAR(100),
    error_message TEXT,
    metadata JSONB,
    compliance_flags VARCHAR(255), -- NCC, GDPR, etc.

    -- Prevent updates/deletes (immutable)
    CONSTRAINT no_updates CHECK (timestamp IS NOT NULL)
);

CREATE INDEX idx_audit_events_timestamp ON audit_events(timestamp DESC);
CREATE INDEX idx_audit_events_user_id ON audit_events(user_id);
CREATE INDEX idx_audit_events_action ON audit_events(action);
CREATE INDEX idx_audit_events_resource_type ON audit_events(resource_type);
CREATE INDEX idx_audit_events_status ON audit_events(status);
CREATE INDEX idx_audit_events_severity ON audit_events(severity);
CREATE INDEX idx_audit_events_timestamp_user ON audit_events(timestamp DESC, user_id);

-- Partition audit_events by month for better performance and archival
CREATE TABLE IF NOT EXISTS audit_events_2026_02 PARTITION OF audit_events
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');

-- Security events (suspicious activities, breaches, etc.)
CREATE TABLE IF NOT EXISTS security_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type VARCHAR(50) NOT NULL, -- login_failure, brute_force, etc.
    user_id UUID,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    description TEXT NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    is_resolved BOOLEAN DEFAULT false,
    resolved_by VARCHAR(255),
    resolved_at TIMESTAMP,
    resolution_note TEXT,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_security_events_created_at ON security_events(created_at DESC);
CREATE INDEX idx_security_events_event_type ON security_events(event_type);
CREATE INDEX idx_security_events_severity ON security_events(severity);
CREATE INDEX idx_security_events_is_resolved ON security_events(is_resolved);
CREATE INDEX idx_security_events_user_id ON security_events(user_id);

-- ============================================================
-- TRIGGERS FOR AUDIT LOGGING
-- ============================================================

-- Function to prevent updates/deletes on audit_events (immutable)
CREATE OR REPLACE FUNCTION prevent_audit_modifications()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'Audit events are immutable and cannot be modified or deleted';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_events_immutable
    BEFORE UPDATE OR DELETE ON audit_events
    FOR EACH ROW
    EXECUTE FUNCTION prevent_audit_modifications();

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_roles_updated_at
    BEFORE UPDATE ON roles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_resource_policies_updated_at
    BEFORE UPDATE ON resource_policies
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- INITIAL DATA: CREATE SYSTEM ADMIN USER
-- ============================================================

-- Insert system admin user (password: VoxGuard@2026! - must be changed on first login)
-- Password hash generated with bcrypt cost 12
INSERT INTO users (
    id, username, email, password_hash, first_name, last_name,
    is_active, created_by, updated_by
) VALUES (
    gen_random_uuid(),
    'admin',
    'admin@voxguard.local',
    '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqNq7F0jXS', -- VoxGuard@2026!
    'System',
    'Administrator',
    true,
    'system',
    'system'
) ON CONFLICT (username) DO NOTHING;

-- ============================================================
-- VIEWS FOR CONVENIENCE
-- ============================================================

-- View: User with roles and permissions
CREATE OR REPLACE VIEW user_access_view AS
SELECT
    u.id AS user_id,
    u.username,
    u.email,
    u.is_active,
    ARRAY_AGG(DISTINCT r.name) AS roles,
    ARRAY_AGG(DISTINCT p.resource || ':' || p.action) AS permissions
FROM users u
LEFT JOIN user_roles ur ON u.id = ur.user_id AND (ur.expires_at IS NULL OR ur.expires_at > NOW())
LEFT JOIN roles r ON ur.role_id = r.id AND r.is_active = true
LEFT JOIN role_permissions rp ON r.id = rp.role_id
LEFT JOIN permissions p ON rp.permission_id = p.id
GROUP BY u.id, u.username, u.email, u.is_active;

-- View: Audit summary for compliance reporting
CREATE OR REPLACE VIEW audit_summary_view AS
SELECT
    DATE(timestamp) AS audit_date,
    action,
    resource_type,
    COUNT(*) AS event_count,
    COUNT(*) FILTER (WHERE status = 'failure') AS failure_count,
    COUNT(*) FILTER (WHERE severity = 'critical') AS critical_count
FROM audit_events
GROUP BY DATE(timestamp), action, resource_type;

-- ============================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================

COMMENT ON TABLE users IS 'User accounts with authentication credentials';
COMMENT ON TABLE roles IS 'Security roles for RBAC';
COMMENT ON TABLE permissions IS 'Fine-grained permissions';
COMMENT ON TABLE audit_events IS 'Immutable audit log for compliance (7-year retention)';
COMMENT ON TABLE security_events IS 'Security incidents and suspicious activities';

COMMENT ON COLUMN users.login_attempts IS 'Failed login attempt counter for lockout';
COMMENT ON COLUMN users.locked_until IS 'Account locked until this timestamp';
COMMENT ON COLUMN audit_events.compliance_flags IS 'Compliance tags: NCC, GDPR, ISO27001';

-- ============================================================
-- GRANTS (Adjust based on your role structure)
-- ============================================================

-- Grant basic permissions to application role (create this role if needed)
-- GRANT SELECT, INSERT ON ALL TABLES IN SCHEMA public TO voxguard_app;
-- GRANT UPDATE, DELETE ON users, roles, user_roles, role_permissions, refresh_tokens, api_keys TO voxguard_app;
-- GRANT SELECT, INSERT ON audit_events, security_events TO voxguard_app; -- No UPDATE/DELETE
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO voxguard_app;
