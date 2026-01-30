-- ============================================================================
-- Anti-Call Masking Platform - Extended Schema
-- Additional tables for complete platform functionality
-- Version: 2.0 | Date: 2026-01-30
-- ============================================================================

-- ============================================================================
-- CALL RECORDS (CDR Data)
-- ============================================================================
CREATE TABLE IF NOT EXISTS acm_call_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Call identifiers
    call_id VARCHAR(100) UNIQUE NOT NULL,
    session_id VARCHAR(100),

    -- Number information
    a_number VARCHAR(30) NOT NULL,           -- Calling number
    b_number VARCHAR(30) NOT NULL,           -- Called number
    original_cli VARCHAR(30),                -- Original CLI if modified
    diversion_number VARCHAR(30),            -- Call forwarding number

    -- Call metadata
    call_type VARCHAR(20) DEFAULT 'voice',   -- voice, sms, ussd
    direction VARCHAR(10) DEFAULT 'inbound', -- inbound, outbound, transit

    -- Timing
    setup_time TIMESTAMP WITH TIME ZONE NOT NULL,
    answer_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER DEFAULT 0,
    ring_duration_seconds INTEGER DEFAULT 0,

    -- Carrier/Route info
    ingress_carrier_id VARCHAR(50),
    egress_carrier_id VARCHAR(50),
    ingress_trunk_id VARCHAR(50),
    egress_trunk_id VARCHAR(50),

    -- Geographic info
    a_number_country VARCHAR(3),
    b_number_country VARCHAR(3),
    a_number_region VARCHAR(100),

    -- SIP details
    sip_response_code INTEGER,
    sip_reason VARCHAR(255),
    user_agent VARCHAR(255),

    -- Analysis flags
    is_analyzed BOOLEAN DEFAULT false,
    is_flagged BOOLEAN DEFAULT false,
    risk_score DECIMAL(5,2) DEFAULT 0,
    detection_results JSONB DEFAULT '[]'::jsonb,

    -- Related alert
    alert_id UUID REFERENCES acm_alerts(id),

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT valid_call_type CHECK (call_type IN ('voice', 'sms', 'ussd')),
    CONSTRAINT valid_direction CHECK (direction IN ('inbound', 'outbound', 'transit'))
);

CREATE INDEX IF NOT EXISTS idx_call_records_a_number ON acm_call_records(a_number);
CREATE INDEX IF NOT EXISTS idx_call_records_b_number ON acm_call_records(b_number);
CREATE INDEX IF NOT EXISTS idx_call_records_setup_time ON acm_call_records(setup_time DESC);
CREATE INDEX IF NOT EXISTS idx_call_records_ingress ON acm_call_records(ingress_carrier_id);
CREATE INDEX IF NOT EXISTS idx_call_records_flagged ON acm_call_records(is_flagged) WHERE is_flagged = true;
CREATE INDEX IF NOT EXISTS idx_call_records_alert ON acm_call_records(alert_id);

-- ============================================================================
-- NUMBER REPUTATION
-- ============================================================================
CREATE TABLE IF NOT EXISTS acm_number_reputation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(30) NOT NULL UNIQUE,

    -- Reputation metrics
    reputation_score DECIMAL(5,2) DEFAULT 50.00,  -- 0-100, higher is better
    risk_level VARCHAR(20) DEFAULT 'unknown',

    -- Statistics
    total_calls BIGINT DEFAULT 0,
    flagged_calls BIGINT DEFAULT 0,
    confirmed_fraud_calls BIGINT DEFAULT 0,
    false_positive_calls BIGINT DEFAULT 0,

    -- Behavioral patterns
    avg_call_duration DECIMAL(10,2),
    calls_per_day_avg DECIMAL(10,2),
    unique_destinations INTEGER DEFAULT 0,

    -- Classification
    number_type VARCHAR(30),  -- mobile, landline, voip, premium, toll_free
    carrier VARCHAR(100),
    country VARCHAR(3),
    region VARCHAR(100),

    -- Status
    is_blocked BOOLEAN DEFAULT false,
    is_whitelisted BOOLEAN DEFAULT false,
    block_reason TEXT,

    -- Timestamps
    first_seen_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    last_seen_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    last_flagged_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT valid_risk_level CHECK (risk_level IN ('critical', 'high', 'medium', 'low', 'trusted', 'unknown'))
);

CREATE INDEX IF NOT EXISTS idx_number_reputation_score ON acm_number_reputation(reputation_score);
CREATE INDEX IF NOT EXISTS idx_number_reputation_risk ON acm_number_reputation(risk_level);
CREATE INDEX IF NOT EXISTS idx_number_reputation_blocked ON acm_number_reputation(is_blocked) WHERE is_blocked = true;

-- ============================================================================
-- BLOCKED NUMBERS
-- ============================================================================
CREATE TABLE IF NOT EXISTS acm_blocked_numbers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(30) NOT NULL,
    number_pattern VARCHAR(50),  -- For pattern matching (e.g., +234801*)

    block_type VARCHAR(30) NOT NULL DEFAULT 'manual',
    reason TEXT NOT NULL,
    severity VARCHAR(20) DEFAULT 'high',

    -- Source of block
    source VARCHAR(50) DEFAULT 'manual',  -- manual, auto, ncc, carrier
    reference_id VARCHAR(100),            -- External reference

    -- Scope
    applies_to_inbound BOOLEAN DEFAULT true,
    applies_to_outbound BOOLEAN DEFAULT true,

    -- Validity
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMP WITH TIME ZONE,

    -- Audit
    blocked_by UUID REFERENCES acm_users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT valid_block_type CHECK (block_type IN ('manual', 'auto', 'temporary', 'permanent', 'ncc_directive'))
);

CREATE INDEX IF NOT EXISTS idx_blocked_numbers_phone ON acm_blocked_numbers(phone_number);
CREATE INDEX IF NOT EXISTS idx_blocked_numbers_pattern ON acm_blocked_numbers(number_pattern);
CREATE INDEX IF NOT EXISTS idx_blocked_numbers_active ON acm_blocked_numbers(is_active) WHERE is_active = true;

-- ============================================================================
-- WHITELISTED NUMBERS
-- ============================================================================
CREATE TABLE IF NOT EXISTS acm_whitelisted_numbers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(30) NOT NULL,
    number_pattern VARCHAR(50),

    entity_name VARCHAR(255),        -- Organization name
    entity_type VARCHAR(50),         -- bank, government, carrier, enterprise

    reason TEXT,
    verification_status VARCHAR(30) DEFAULT 'pending',
    verified_by UUID REFERENCES acm_users(id),
    verified_at TIMESTAMP WITH TIME ZONE,

    -- NCC registration
    ncc_registered BOOLEAN DEFAULT false,
    ncc_registration_id VARCHAR(100),

    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMP WITH TIME ZONE,

    created_by UUID REFERENCES acm_users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT valid_verification CHECK (verification_status IN ('pending', 'verified', 'rejected', 'expired'))
);

CREATE INDEX IF NOT EXISTS idx_whitelist_phone ON acm_whitelisted_numbers(phone_number);
CREATE INDEX IF NOT EXISTS idx_whitelist_entity ON acm_whitelisted_numbers(entity_name);
CREATE INDEX IF NOT EXISTS idx_whitelist_active ON acm_whitelisted_numbers(is_active) WHERE is_active = true;

-- ============================================================================
-- DETECTION RULES
-- ============================================================================
CREATE TABLE IF NOT EXISTS acm_detection_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,

    -- Rule definition
    rule_type VARCHAR(50) NOT NULL,
    conditions JSONB NOT NULL,           -- Rule conditions in JSON
    actions JSONB DEFAULT '[]'::jsonb,   -- Actions to take when triggered

    -- Thresholds
    severity VARCHAR(20) DEFAULT 'medium',
    confidence_weight DECIMAL(5,2) DEFAULT 1.0,

    -- Scope
    applies_to_carriers JSONB DEFAULT '[]'::jsonb,
    applies_to_countries JSONB DEFAULT '[]'::jsonb,

    -- Status
    is_active BOOLEAN DEFAULT true,
    is_system_rule BOOLEAN DEFAULT false,

    -- Statistics
    total_triggers BIGINT DEFAULT 0,
    true_positives BIGINT DEFAULT 0,
    false_positives BIGINT DEFAULT 0,

    -- Audit
    created_by UUID REFERENCES acm_users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT valid_rule_type CHECK (rule_type IN (
        'cpm_threshold', 'acd_threshold', 'cli_pattern', 'geo_mismatch',
        'sim_box', 'premium_rate', 'wangiri', 'robocall', 'custom'
    ))
);

CREATE INDEX IF NOT EXISTS idx_detection_rules_type ON acm_detection_rules(rule_type);
CREATE INDEX IF NOT EXISTS idx_detection_rules_active ON acm_detection_rules(is_active) WHERE is_active = true;

-- ============================================================================
-- ALERT COMMENTS
-- ============================================================================
CREATE TABLE IF NOT EXISTS acm_alert_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_id UUID NOT NULL REFERENCES acm_alerts(id) ON DELETE CASCADE,

    comment TEXT NOT NULL,
    comment_type VARCHAR(30) DEFAULT 'note',

    -- Attachments
    attachments JSONB DEFAULT '[]'::jsonb,

    -- For status changes
    old_status VARCHAR(20),
    new_status VARCHAR(20),

    author_id UUID REFERENCES acm_users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT valid_comment_type CHECK (comment_type IN ('note', 'status_change', 'assignment', 'escalation', 'resolution'))
);

CREATE INDEX IF NOT EXISTS idx_alert_comments_alert ON acm_alert_comments(alert_id);
CREATE INDEX IF NOT EXISTS idx_alert_comments_author ON acm_alert_comments(author_id);

-- ============================================================================
-- COMPLIANCE REPORTS
-- ============================================================================
CREATE TABLE IF NOT EXISTS acm_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    report_type VARCHAR(50) NOT NULL,
    report_name VARCHAR(255) NOT NULL,
    description TEXT,

    -- Report period
    period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    period_end TIMESTAMP WITH TIME ZONE NOT NULL,

    -- Report data
    report_data JSONB,
    summary JSONB,

    -- File info
    file_path VARCHAR(500),
    file_size_bytes BIGINT,
    file_format VARCHAR(20) DEFAULT 'pdf',

    -- NCC submission
    is_ncc_report BOOLEAN DEFAULT false,
    ncc_submission_status VARCHAR(30),
    ncc_submission_id VARCHAR(100),
    submitted_at TIMESTAMP WITH TIME ZONE,

    -- Status
    status VARCHAR(30) DEFAULT 'generating',
    error_message TEXT,

    generated_by UUID REFERENCES acm_users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,

    CONSTRAINT valid_report_type CHECK (report_type IN (
        'daily_summary', 'weekly_summary', 'monthly_summary',
        'ncc_daily', 'ncc_monthly', 'carrier_report', 'incident_report', 'custom'
    )),
    CONSTRAINT valid_report_status CHECK (status IN ('generating', 'completed', 'failed', 'submitted'))
);

CREATE INDEX IF NOT EXISTS idx_reports_type ON acm_reports(report_type);
CREATE INDEX IF NOT EXISTS idx_reports_period ON acm_reports(period_start, period_end);
CREATE INDEX IF NOT EXISTS idx_reports_ncc ON acm_reports(is_ncc_report) WHERE is_ncc_report = true;

-- ============================================================================
-- API KEYS
-- ============================================================================
CREATE TABLE IF NOT EXISTS acm_api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    name VARCHAR(255) NOT NULL,
    description TEXT,

    -- Key details
    key_prefix VARCHAR(10) NOT NULL,      -- First 8 chars for identification
    key_hash VARCHAR(255) NOT NULL,       -- Hashed API key

    -- Permissions
    permissions JSONB DEFAULT '["read"]'::jsonb,
    allowed_ips JSONB DEFAULT '[]'::jsonb,
    rate_limit INTEGER DEFAULT 1000,      -- Requests per minute

    -- Scope
    carrier_scope JSONB DEFAULT '[]'::jsonb,  -- Limit to specific carriers

    -- Status
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMP WITH TIME ZONE,
    last_used_at TIMESTAMP WITH TIME ZONE,
    usage_count BIGINT DEFAULT 0,

    -- Audit
    created_by UUID REFERENCES acm_users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    revoked_at TIMESTAMP WITH TIME ZONE,
    revoked_by UUID REFERENCES acm_users(id)
);

CREATE INDEX IF NOT EXISTS idx_api_keys_prefix ON acm_api_keys(key_prefix);
CREATE INDEX IF NOT EXISTS idx_api_keys_active ON acm_api_keys(is_active) WHERE is_active = true;

-- ============================================================================
-- WEBHOOKS
-- ============================================================================
CREATE TABLE IF NOT EXISTS acm_webhooks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    name VARCHAR(255) NOT NULL,
    url VARCHAR(500) NOT NULL,

    -- Events to trigger
    events JSONB NOT NULL,  -- ['alert.created', 'alert.critical', etc.]

    -- Authentication
    auth_type VARCHAR(30) DEFAULT 'none',
    auth_header VARCHAR(100),
    auth_value_encrypted VARCHAR(500),

    -- Configuration
    headers JSONB DEFAULT '{}'::jsonb,
    retry_count INTEGER DEFAULT 3,
    timeout_seconds INTEGER DEFAULT 30,

    -- Filters
    severity_filter JSONB DEFAULT '[]'::jsonb,
    carrier_filter JSONB DEFAULT '[]'::jsonb,

    -- Status
    is_active BOOLEAN DEFAULT true,
    last_triggered_at TIMESTAMP WITH TIME ZONE,
    last_status_code INTEGER,
    consecutive_failures INTEGER DEFAULT 0,

    -- Statistics
    total_deliveries BIGINT DEFAULT 0,
    successful_deliveries BIGINT DEFAULT 0,
    failed_deliveries BIGINT DEFAULT 0,

    created_by UUID REFERENCES acm_users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT valid_auth_type CHECK (auth_type IN ('none', 'bearer', 'basic', 'api_key', 'hmac'))
);

CREATE INDEX IF NOT EXISTS idx_webhooks_active ON acm_webhooks(is_active) WHERE is_active = true;

-- ============================================================================
-- NOTIFICATIONS
-- ============================================================================
CREATE TABLE IF NOT EXISTS acm_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    user_id UUID REFERENCES acm_users(id),

    notification_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,

    -- Related entity
    entity_type VARCHAR(50),
    entity_id UUID,

    -- Delivery
    channels JSONB DEFAULT '["in_app"]'::jsonb,

    -- Status per channel
    in_app_read BOOLEAN DEFAULT false,
    email_sent BOOLEAN DEFAULT false,
    email_sent_at TIMESTAMP WITH TIME ZONE,
    sms_sent BOOLEAN DEFAULT false,
    slack_sent BOOLEAN DEFAULT false,

    -- Priority
    priority VARCHAR(20) DEFAULT 'normal',

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE,

    CONSTRAINT valid_priority CHECK (priority IN ('low', 'normal', 'high', 'urgent'))
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON acm_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON acm_notifications(user_id, in_app_read) WHERE in_app_read = false;
CREATE INDEX IF NOT EXISTS idx_notifications_type ON acm_notifications(notification_type);

-- ============================================================================
-- TRUNKS (SIP Trunks)
-- ============================================================================
CREATE TABLE IF NOT EXISTS acm_trunks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    trunk_id VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,

    -- Carrier association
    carrier_id UUID REFERENCES acm_carriers(id),

    -- Technical details
    trunk_type VARCHAR(30) DEFAULT 'sip',
    protocol VARCHAR(20) DEFAULT 'udp',
    host VARCHAR(255),
    port INTEGER DEFAULT 5060,

    -- Capacity
    max_channels INTEGER,
    current_channels INTEGER DEFAULT 0,

    -- Direction
    allows_inbound BOOLEAN DEFAULT true,
    allows_outbound BOOLEAN DEFAULT true,

    -- Monitoring
    is_active BOOLEAN DEFAULT true,
    is_monitored BOOLEAN DEFAULT true,
    health_status VARCHAR(20) DEFAULT 'unknown',
    last_health_check TIMESTAMP WITH TIME ZONE,

    -- Statistics
    total_calls BIGINT DEFAULT 0,
    flagged_calls BIGINT DEFAULT 0,
    avg_asr DECIMAL(5,2),
    avg_acd DECIMAL(10,2),

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT valid_trunk_type CHECK (trunk_type IN ('sip', 'ss7', 'pri', 'bri')),
    CONSTRAINT valid_health CHECK (health_status IN ('healthy', 'degraded', 'down', 'unknown'))
);

CREATE INDEX IF NOT EXISTS idx_trunks_carrier ON acm_trunks(carrier_id);
CREATE INDEX IF NOT EXISTS idx_trunks_active ON acm_trunks(is_active) WHERE is_active = true;

-- ============================================================================
-- RATE PATTERNS (for CPM detection)
-- ============================================================================
CREATE TABLE IF NOT EXISTS acm_rate_patterns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Pattern identification
    source_type VARCHAR(30) NOT NULL,  -- number, prefix, carrier, trunk
    source_value VARCHAR(100) NOT NULL,

    -- Time window
    window_start TIMESTAMP WITH TIME ZONE NOT NULL,
    window_end TIMESTAMP WITH TIME ZONE NOT NULL,
    window_duration_minutes INTEGER NOT NULL,

    -- Metrics
    call_count INTEGER NOT NULL,
    calls_per_minute DECIMAL(10,2) NOT NULL,
    unique_destinations INTEGER,
    avg_duration DECIMAL(10,2),

    -- Analysis
    is_anomaly BOOLEAN DEFAULT false,
    anomaly_score DECIMAL(5,2),
    baseline_cpm DECIMAL(10,2),
    deviation_percent DECIMAL(10,2),

    -- Related alert
    alert_id UUID REFERENCES acm_alerts(id),

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT valid_source_type CHECK (source_type IN ('number', 'prefix', 'carrier', 'trunk', 'country'))
);

CREATE INDEX IF NOT EXISTS idx_rate_patterns_source ON acm_rate_patterns(source_type, source_value);
CREATE INDEX IF NOT EXISTS idx_rate_patterns_window ON acm_rate_patterns(window_start, window_end);
CREATE INDEX IF NOT EXISTS idx_rate_patterns_anomaly ON acm_rate_patterns(is_anomaly) WHERE is_anomaly = true;

-- ============================================================================
-- DASHBOARD WIDGETS (User preferences)
-- ============================================================================
CREATE TABLE IF NOT EXISTS acm_dashboard_widgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    user_id UUID REFERENCES acm_users(id) ON DELETE CASCADE,

    widget_type VARCHAR(50) NOT NULL,
    title VARCHAR(255),

    -- Position
    grid_x INTEGER NOT NULL DEFAULT 0,
    grid_y INTEGER NOT NULL DEFAULT 0,
    grid_w INTEGER NOT NULL DEFAULT 4,
    grid_h INTEGER NOT NULL DEFAULT 3,

    -- Configuration
    config JSONB DEFAULT '{}'::jsonb,

    is_visible BOOLEAN DEFAULT true,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    UNIQUE(user_id, widget_type)
);

CREATE INDEX IF NOT EXISTS idx_dashboard_widgets_user ON acm_dashboard_widgets(user_id);

-- ============================================================================
-- TRIGGERS FOR updated_at
-- ============================================================================
DROP TRIGGER IF EXISTS update_acm_number_reputation_updated_at ON acm_number_reputation;
CREATE TRIGGER update_acm_number_reputation_updated_at
    BEFORE UPDATE ON acm_number_reputation
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_acm_blocked_numbers_updated_at ON acm_blocked_numbers;
CREATE TRIGGER update_acm_blocked_numbers_updated_at
    BEFORE UPDATE ON acm_blocked_numbers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_acm_whitelisted_numbers_updated_at ON acm_whitelisted_numbers;
CREATE TRIGGER update_acm_whitelisted_numbers_updated_at
    BEFORE UPDATE ON acm_whitelisted_numbers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_acm_detection_rules_updated_at ON acm_detection_rules;
CREATE TRIGGER update_acm_detection_rules_updated_at
    BEFORE UPDATE ON acm_detection_rules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_acm_alert_comments_updated_at ON acm_alert_comments;
CREATE TRIGGER update_acm_alert_comments_updated_at
    BEFORE UPDATE ON acm_alert_comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_acm_webhooks_updated_at ON acm_webhooks;
CREATE TRIGGER update_acm_webhooks_updated_at
    BEFORE UPDATE ON acm_webhooks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_acm_trunks_updated_at ON acm_trunks;
CREATE TRIGGER update_acm_trunks_updated_at
    BEFORE UPDATE ON acm_trunks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_acm_dashboard_widgets_updated_at ON acm_dashboard_widgets;
CREATE TRIGGER update_acm_dashboard_widgets_updated_at
    BEFORE UPDATE ON acm_dashboard_widgets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- INSERT DEFAULT DETECTION RULES
-- ============================================================================
INSERT INTO acm_detection_rules (name, description, rule_type, conditions, severity, is_system_rule, is_active) VALUES
    ('High CPM Detection', 'Detect numbers with calls per minute exceeding threshold', 'cpm_threshold',
     '{"threshold": 60, "window_minutes": 1, "min_calls": 10}', 'critical', true, true),

    ('Short ACD Detection', 'Detect patterns with unusually short average call duration', 'acd_threshold',
     '{"max_acd_seconds": 5, "window_minutes": 5, "min_calls": 20}', 'high', true, true),

    ('CLI Spoofing Pattern', 'Detect potential CLI manipulation patterns', 'cli_pattern',
     '{"check_format": true, "check_country_mismatch": true, "check_known_spoof_patterns": true}', 'critical', true, true),

    ('SIM Box Detection', 'Detect SIM box fraud patterns', 'sim_box',
     '{"min_destinations": 50, "window_hours": 1, "max_acd_seconds": 30, "check_gsm_patterns": true}', 'critical', true, true),

    ('Wangiri Detection', 'Detect one-ring callback fraud', 'wangiri',
     '{"max_ring_seconds": 3, "min_occurrences": 5, "window_minutes": 10}', 'high', true, true),

    ('Premium Rate Detection', 'Detect calls to premium rate numbers', 'premium_rate',
     '{"check_known_prefixes": true, "alert_on_international": true}', 'medium', true, true),

    ('Geographic Mismatch', 'Detect geographic anomalies in call patterns', 'geo_mismatch',
     '{"check_impossible_travel": true, "max_country_switches": 3, "window_hours": 1}', 'medium', true, true)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- INSERT SAMPLE DATA FOR TESTING
-- ============================================================================

-- Sample blocked numbers
INSERT INTO acm_blocked_numbers (phone_number, block_type, reason, severity, source) VALUES
    ('+2349999999999', 'permanent', 'Confirmed fraud operator', 'critical', 'manual'),
    ('+1900*', 'permanent', 'Premium rate prefix blocked', 'high', 'ncc'),
    ('+882*', 'permanent', 'Satellite phone prefix - high fraud risk', 'high', 'auto')
ON CONFLICT DO NOTHING;

-- Sample whitelisted numbers
INSERT INTO acm_whitelisted_numbers (phone_number, entity_name, entity_type, verification_status, ncc_registered) VALUES
    ('+2341234567890', 'Central Bank of Nigeria', 'government', 'verified', true),
    ('+2349000000000', 'NCC Helpline', 'government', 'verified', true),
    ('+2348000000000', 'MTN Customer Care', 'carrier', 'verified', true)
ON CONFLICT DO NOTHING;

-- Sample trunks
INSERT INTO acm_trunks (trunk_id, name, trunk_type, host, port, is_active, health_status) VALUES
    ('TRK-MTN-01', 'MTN Primary', 'sip', 'sip.mtn.ng', 5060, true, 'healthy'),
    ('TRK-GLO-01', 'Glo Primary', 'sip', 'sip.gloworld.com', 5060, true, 'healthy'),
    ('TRK-AIRTEL-01', 'Airtel Primary', 'sip', 'sip.airtel.ng', 5060, true, 'healthy'),
    ('TRK-9MOB-01', '9mobile Primary', 'sip', 'sip.9mobile.com.ng', 5060, true, 'degraded'),
    ('TRK-INT-01', 'International Gateway', 'sip', 'intl-gw.acm.ng', 5060, true, 'healthy')
ON CONFLICT (trunk_id) DO NOTHING;
