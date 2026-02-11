-- ============================================================================
-- VoxGuard - Gateway Management Schema
-- Version: 1.0 | Date: 2026-02-02
-- Factory System: Critical Missing Feature Implementation
-- ============================================================================

-- ============================================================================
-- GATEWAYS TABLE
-- Core entity for fraud detection - represents SIP gateways/trunks
-- ============================================================================
CREATE TABLE IF NOT EXISTS acm_gateways (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Gateway identification
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,              -- Unique gateway code (e.g., "GTW-NG-MTN-01")

    -- Network information
    ip_address INET NOT NULL,
    port INTEGER DEFAULT 5060,
    protocol VARCHAR(10) DEFAULT 'UDP',            -- UDP, TCP, TLS

    -- Carrier/Operator information
    carrier_name VARCHAR(100),                     -- MTN, Glo, Airtel, 9mobile, etc.
    carrier_type VARCHAR(50),                      -- MNO, MVNO, ICL, International
    country_code VARCHAR(3) DEFAULT 'NGA',
    region VARCHAR(100),                           -- Lagos, Abuja, Asaba, etc.

    -- Gateway classification
    gateway_type VARCHAR(50) NOT NULL,             -- ingress, egress, transit
    direction VARCHAR(20) DEFAULT 'bidirectional', -- inbound, outbound, bidirectional

    -- Fraud detection configuration
    is_monitored BOOLEAN DEFAULT true,
    fraud_threshold INTEGER DEFAULT 5,             -- Alert threshold for sliding window
    max_concurrent_calls INTEGER DEFAULT 1000,
    max_calls_per_second INTEGER DEFAULT 100,

    -- Status and health
    status VARCHAR(20) DEFAULT 'active',           -- active, inactive, suspended, blacklisted
    is_blacklisted BOOLEAN DEFAULT false,
    blacklist_reason TEXT,
    blacklisted_at TIMESTAMP WITH TIME ZONE,
    blacklisted_by UUID REFERENCES acm_users(id),

    health_status VARCHAR(20) DEFAULT 'healthy',   -- healthy, degraded, critical, unknown
    last_heartbeat TIMESTAMP WITH TIME ZONE,

    -- Statistics (updated periodically)
    total_calls_today BIGINT DEFAULT 0,
    failed_calls_today BIGINT DEFAULT 0,
    fraud_alerts_today BIGINT DEFAULT 0,
    avg_call_duration_seconds DECIMAL(10,2),

    -- Performance metrics
    current_concurrent_calls INTEGER DEFAULT 0,
    peak_concurrent_calls INTEGER DEFAULT 0,
    current_cps DECIMAL(10,2) DEFAULT 0,           -- Current calls per second
    peak_cps DECIMAL(10,2) DEFAULT 0,

    -- Compliance
    ncc_license_number VARCHAR(100),
    license_expiry_date DATE,
    is_ncc_compliant BOOLEAN DEFAULT true,

    -- Contact information
    technical_contact_name VARCHAR(100),
    technical_contact_email VARCHAR(100),
    technical_contact_phone VARCHAR(30),

    -- Additional metadata
    description TEXT,
    configuration JSONB DEFAULT '{}'::jsonb,       -- Custom gateway configuration
    tags TEXT[],                                   -- Searchable tags

    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES acm_users(id),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_by UUID REFERENCES acm_users(id),

    -- Constraints
    CONSTRAINT valid_gateway_type CHECK (gateway_type IN ('ingress', 'egress', 'transit')),
    CONSTRAINT valid_status CHECK (status IN ('active', 'inactive', 'suspended', 'blacklisted')),
    CONSTRAINT valid_health CHECK (health_status IN ('healthy', 'degraded', 'critical', 'unknown')),
    CONSTRAINT valid_direction CHECK (direction IN ('inbound', 'outbound', 'bidirectional')),
    CONSTRAINT valid_protocol CHECK (protocol IN ('UDP', 'TCP', 'TLS'))
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_gateways_code ON acm_gateways(code);
CREATE INDEX IF NOT EXISTS idx_gateways_ip ON acm_gateways(ip_address);
CREATE INDEX IF NOT EXISTS idx_gateways_status ON acm_gateways(status);
CREATE INDEX IF NOT EXISTS idx_gateways_blacklisted ON acm_gateways(is_blacklisted) WHERE is_blacklisted = true;
CREATE INDEX IF NOT EXISTS idx_gateways_carrier ON acm_gateways(carrier_name);
CREATE INDEX IF NOT EXISTS idx_gateways_region ON acm_gateways(region);
CREATE INDEX IF NOT EXISTS idx_gateways_type ON acm_gateways(gateway_type);
CREATE INDEX IF NOT EXISTS idx_gateways_health ON acm_gateways(health_status);
CREATE INDEX IF NOT EXISTS idx_gateways_created_at ON acm_gateways(created_at DESC);

-- Full-text search index
CREATE INDEX IF NOT EXISTS idx_gateways_search ON acm_gateways USING gin(
    to_tsvector('english', coalesce(name, '') || ' ' ||
                          coalesce(code, '') || ' ' ||
                          coalesce(carrier_name, '') || ' ' ||
                          coalesce(description, ''))
);

-- ============================================================================
-- GATEWAY AUDIT LOG
-- Track all changes to gateway configuration and status
-- ============================================================================
CREATE TABLE IF NOT EXISTS acm_gateway_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gateway_id UUID NOT NULL REFERENCES acm_gateways(id) ON DELETE CASCADE,

    -- Change tracking
    action VARCHAR(50) NOT NULL,                   -- created, updated, blacklisted, activated, etc.
    field_changed VARCHAR(100),                    -- Field name that was changed
    old_value TEXT,                                -- Previous value (JSON serialized)
    new_value TEXT,                                -- New value (JSON serialized)

    -- Context
    reason TEXT,                                   -- Why the change was made
    user_id UUID REFERENCES acm_users(id),
    user_name VARCHAR(100),
    ip_address INET,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT valid_action CHECK (action IN (
        'created', 'updated', 'activated', 'deactivated',
        'blacklisted', 'unblacklisted', 'suspended', 'deleted'
    ))
);

CREATE INDEX IF NOT EXISTS idx_gateway_audit_gateway ON acm_gateway_audit_logs(gateway_id);
CREATE INDEX IF NOT EXISTS idx_gateway_audit_created ON acm_gateway_audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_gateway_audit_action ON acm_gateway_audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_gateway_audit_user ON acm_gateway_audit_logs(user_id);

-- ============================================================================
-- GATEWAY METRICS (Time-series data)
-- Historical performance and health metrics
-- Note: Heavy metrics should go to QuestDB, but we keep recent data here
-- ============================================================================
CREATE TABLE IF NOT EXISTS acm_gateway_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gateway_id UUID NOT NULL REFERENCES acm_gateways(id) ON DELETE CASCADE,

    -- Time bucket (5-minute intervals)
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,

    -- Call volume metrics
    total_calls INTEGER DEFAULT 0,
    successful_calls INTEGER DEFAULT 0,
    failed_calls INTEGER DEFAULT 0,
    fraud_detected_calls INTEGER DEFAULT 0,

    -- Performance metrics
    avg_call_duration_seconds DECIMAL(10,2),
    max_concurrent_calls INTEGER DEFAULT 0,
    avg_cps DECIMAL(10,2) DEFAULT 0,
    max_cps DECIMAL(10,2) DEFAULT 0,

    -- Quality metrics
    avg_response_time_ms DECIMAL(10,2),
    p95_response_time_ms DECIMAL(10,2),
    p99_response_time_ms DECIMAL(10,2),

    -- Error rates
    error_rate DECIMAL(5,2) DEFAULT 0,             -- Percentage
    timeout_count INTEGER DEFAULT 0,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    UNIQUE(gateway_id, timestamp)
);

CREATE INDEX IF NOT EXISTS idx_gateway_metrics_gateway ON acm_gateway_metrics(gateway_id);
CREATE INDEX IF NOT EXISTS idx_gateway_metrics_timestamp ON acm_gateway_metrics(timestamp DESC);

-- Partition by month for better performance (optional, for production)
-- CREATE TABLE acm_gateway_metrics_y2026m02 PARTITION OF acm_gateway_metrics
--     FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');

-- ============================================================================
-- GATEWAY BLACKLIST RULES
-- Automated blacklisting rules based on fraud patterns
-- ============================================================================
CREATE TABLE IF NOT EXISTS acm_gateway_blacklist_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Rule definition
    rule_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,

    -- Conditions (JSON-based for flexibility)
    conditions JSONB NOT NULL,                     -- {fraud_alerts: {gt: 10}, time_window: "1h"}

    -- Action
    action VARCHAR(50) DEFAULT 'blacklist',        -- blacklist, suspend, alert_only
    auto_apply BOOLEAN DEFAULT false,              -- Automatically apply or require manual review

    -- Status
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 10,                   -- Higher priority rules execute first

    -- Statistics
    times_triggered BIGINT DEFAULT 0,
    last_triggered_at TIMESTAMP WITH TIME ZONE,

    -- Audit
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES acm_users(id),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_by UUID REFERENCES acm_users(id),

    CONSTRAINT valid_action CHECK (action IN ('blacklist', 'suspend', 'alert_only'))
);

CREATE INDEX IF NOT EXISTS idx_blacklist_rules_active ON acm_gateway_blacklist_rules(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_blacklist_rules_priority ON acm_gateway_blacklist_rules(priority DESC);

-- ============================================================================
-- UPDATE TIMESTAMPS TRIGGER
-- ============================================================================
CREATE OR REPLACE FUNCTION update_gateway_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_gateways_update_timestamp
    BEFORE UPDATE ON acm_gateways
    FOR EACH ROW
    EXECUTE FUNCTION update_gateway_timestamp();

CREATE TRIGGER trg_blacklist_rules_update_timestamp
    BEFORE UPDATE ON acm_gateway_blacklist_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_gateway_timestamp();

-- ============================================================================
-- SEED DATA - Example Gateways
-- ============================================================================
INSERT INTO acm_gateways (
    name, code, ip_address, port, carrier_name, carrier_type,
    gateway_type, direction, region, status
) VALUES
    ('MTN Lagos Primary', 'GTW-NG-MTN-LAG-01', '10.20.30.40', 5060, 'MTN Nigeria', 'MNO', 'ingress', 'bidirectional', 'Lagos', 'active'),
    ('Glo Abuja Gateway', 'GTW-NG-GLO-ABJ-01', '10.20.30.50', 5060, 'Globacom', 'MNO', 'ingress', 'inbound', 'Abuja', 'active'),
    ('Airtel Asaba Trunk', 'GTW-NG-AIR-ASB-01', '10.20.30.60', 5060, 'Airtel Nigeria', 'MNO', 'transit', 'bidirectional', 'Asaba', 'active'),
    ('International Gateway 1', 'GTW-INT-001', '10.20.30.70', 5060, 'International Partner', 'International', 'egress', 'outbound', 'Lagos', 'active')
ON CONFLICT (code) DO NOTHING;

-- ============================================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================================
COMMENT ON TABLE acm_gateways IS 'Core gateway/trunk entities monitored for fraud detection';
COMMENT ON TABLE acm_gateway_audit_logs IS 'Audit trail for all gateway configuration changes';
COMMENT ON TABLE acm_gateway_metrics IS 'Historical performance metrics (recent data, archived to QuestDB)';
COMMENT ON TABLE acm_gateway_blacklist_rules IS 'Automated blacklisting rules based on fraud patterns';

COMMENT ON COLUMN acm_gateways.fraud_threshold IS 'Number of distinct callers to same B-number before triggering alert';
COMMENT ON COLUMN acm_gateways.is_blacklisted IS 'Gateway is blocked from processing calls due to fraud';
COMMENT ON COLUMN acm_gateways.health_status IS 'Real-time health status based on heartbeat and metrics';
