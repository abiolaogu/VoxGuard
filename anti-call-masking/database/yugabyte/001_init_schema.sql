-- ============================================================================
-- Anti-Call Masking Platform - Database Schema
-- YugabyteDB (PostgreSQL-compatible)
-- Version: 2.0 | Date: 2026-01-30
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- USERS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS acm_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'viewer',
    avatar_url VARCHAR(500),
    is_active BOOLEAN NOT NULL DEFAULT true,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT valid_role CHECK (role IN ('admin', 'analyst', 'developer', 'viewer'))
);

-- Create index for email lookups
CREATE INDEX IF NOT EXISTS idx_acm_users_email ON acm_users(email);
CREATE INDEX IF NOT EXISTS idx_acm_users_role ON acm_users(role);

-- ============================================================================
-- ALERTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS acm_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Call information
    a_number VARCHAR(20) NOT NULL,  -- Calling number (CLI)
    b_number VARCHAR(20) NOT NULL,  -- Called number
    original_cli VARCHAR(20),       -- Original CLI before masking

    -- Detection details
    severity VARCHAR(20) NOT NULL DEFAULT 'medium',
    status VARCHAR(20) NOT NULL DEFAULT 'new',
    detection_type VARCHAR(50) NOT NULL,
    confidence_score DECIMAL(5,2) NOT NULL DEFAULT 0.00,

    -- Analysis data
    risk_indicators JSONB DEFAULT '[]'::jsonb,
    call_metadata JSONB DEFAULT '{}'::jsonb,

    -- Carrier information
    carrier_id VARCHAR(50),
    carrier_name VARCHAR(255),
    trunk_id VARCHAR(50),

    -- Geographic data
    origin_country VARCHAR(3),
    origin_region VARCHAR(100),

    -- Timestamps
    detected_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Assignment
    assigned_to UUID REFERENCES acm_users(id),

    -- Notes and comments
    notes TEXT,

    CONSTRAINT valid_severity CHECK (severity IN ('critical', 'high', 'medium', 'low')),
    CONSTRAINT valid_status CHECK (status IN ('new', 'investigating', 'confirmed', 'false_positive', 'resolved'))
);

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_acm_alerts_severity ON acm_alerts(severity);
CREATE INDEX IF NOT EXISTS idx_acm_alerts_status ON acm_alerts(status);
CREATE INDEX IF NOT EXISTS idx_acm_alerts_detected_at ON acm_alerts(detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_acm_alerts_a_number ON acm_alerts(a_number);
CREATE INDEX IF NOT EXISTS idx_acm_alerts_b_number ON acm_alerts(b_number);
CREATE INDEX IF NOT EXISTS idx_acm_alerts_carrier ON acm_alerts(carrier_id);
CREATE INDEX IF NOT EXISTS idx_acm_alerts_assigned ON acm_alerts(assigned_to);

-- ============================================================================
-- SETTINGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS acm_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category VARCHAR(50) NOT NULL,
    key VARCHAR(100) NOT NULL,
    value JSONB NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    UNIQUE(category, key)
);

CREATE INDEX IF NOT EXISTS idx_acm_settings_category ON acm_settings(category);

-- ============================================================================
-- CARRIERS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS acm_carriers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    carrier_id VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    country VARCHAR(3),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    is_active BOOLEAN NOT NULL DEFAULT true,
    trust_score DECIMAL(5,2) DEFAULT 100.00,
    total_calls BIGINT DEFAULT 0,
    flagged_calls BIGINT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_acm_carriers_carrier_id ON acm_carriers(carrier_id);

-- ============================================================================
-- AUDIT LOG TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS acm_audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES acm_users(id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_acm_audit_user ON acm_audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_acm_audit_entity ON acm_audit_log(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_acm_audit_created ON acm_audit_log(created_at DESC);

-- ============================================================================
-- INSERT DEFAULT DATA
-- ============================================================================

-- Default admin user (password: demo123)
INSERT INTO acm_users (email, password_hash, name, role) VALUES
    ('admin@acm.com', '$2a$10$rQEY7zQGJZGPv9PKPJ9qXeH8JZxHxHxHxHxHxHxHxHxHxHxHxHxH', 'System Admin', 'admin'),
    ('analyst@acm.com', '$2a$10$rQEY7zQGJZGPv9PKPJ9qXeH8JZxHxHxHxHxHxHxHxHxHxHxHxHxH', 'Senior Analyst', 'analyst'),
    ('developer@acm.com', '$2a$10$rQEY7zQGJZGPv9PKPJ9qXeH8JZxHxHxHxHxHxHxHxHxHxHxHxHxH', 'Dev User', 'developer'),
    ('viewer@acm.com', '$2a$10$rQEY7zQGJZGPv9PKPJ9qXeH8JZxHxHxHxHxHxHxHxHxHxHxHxHxH', 'Read Only', 'viewer')
ON CONFLICT (email) DO NOTHING;

-- Default settings
INSERT INTO acm_settings (category, key, value, description) VALUES
    ('detection', 'cpm_warning_threshold', '40', 'Calls per minute warning threshold'),
    ('detection', 'cpm_critical_threshold', '60', 'Calls per minute critical threshold'),
    ('detection', 'acd_warning_threshold', '10', 'Average call duration warning (seconds)'),
    ('detection', 'acd_critical_threshold', '5', 'Average call duration critical (seconds)'),
    ('detection', 'cli_spoof_detection', 'true', 'Enable CLI spoofing detection'),
    ('notification', 'email_enabled', 'true', 'Enable email notifications'),
    ('notification', 'slack_enabled', 'false', 'Enable Slack notifications'),
    ('notification', 'critical_alert_sound', 'true', 'Play sound for critical alerts'),
    ('api', 'rate_limit', '1000', 'API rate limit per minute'),
    ('api', 'webhook_enabled', 'false', 'Enable webhook notifications')
ON CONFLICT (category, key) DO NOTHING;

-- Sample carriers
INSERT INTO acm_carriers (carrier_id, name, country, is_active, trust_score) VALUES
    ('NG-MTN', 'MTN Nigeria', 'NGA', true, 95.00),
    ('NG-GLO', 'Globacom', 'NGA', true, 92.00),
    ('NG-AIRTEL', 'Airtel Nigeria', 'NGA', true, 94.00),
    ('NG-9MOBILE', '9mobile', 'NGA', true, 90.00),
    ('INT-UNKNOWN', 'Unknown International', NULL, true, 50.00)
ON CONFLICT (carrier_id) DO NOTHING;

-- Sample alerts for demo
INSERT INTO acm_alerts (a_number, b_number, severity, status, detection_type, confidence_score, carrier_id, carrier_name, origin_country, risk_indicators) VALUES
    ('+2348012345678', '+2349087654321', 'critical', 'new', 'cli_spoofing', 95.50, 'INT-UNKNOWN', 'Unknown International', 'USA', '["High CPM", "Short ACD", "International origin claiming local CLI"]'),
    ('+447912345678', '+2348055555555', 'high', 'investigating', 'sim_box', 88.20, 'INT-UNKNOWN', 'Unknown International', 'GBR', '["Multiple destinations", "Pattern matching SIM box"]'),
    ('+2348033333333', '+2349011111111', 'medium', 'new', 'premium_rate', 72.00, 'NG-MTN', 'MTN Nigeria', 'NGA', '["Premium rate number", "Unusual call pattern"]'),
    ('+12125551234', '+2348022222222', 'high', 'confirmed', 'cli_spoofing', 91.80, 'INT-UNKNOWN', 'Unknown International', 'USA', '["Spoofed US number", "High volume"]'),
    ('+2348044444444', '+2349099999999', 'low', 'resolved', 'false_answer', 45.00, 'NG-GLO', 'Globacom', 'NGA', '["Short ring time"]')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers
DROP TRIGGER IF EXISTS update_acm_users_updated_at ON acm_users;
CREATE TRIGGER update_acm_users_updated_at
    BEFORE UPDATE ON acm_users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_acm_alerts_updated_at ON acm_alerts;
CREATE TRIGGER update_acm_alerts_updated_at
    BEFORE UPDATE ON acm_alerts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_acm_settings_updated_at ON acm_settings;
CREATE TRIGGER update_acm_settings_updated_at
    BEFORE UPDATE ON acm_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_acm_carriers_updated_at ON acm_carriers;
CREATE TRIGGER update_acm_carriers_updated_at
    BEFORE UPDATE ON acm_carriers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
