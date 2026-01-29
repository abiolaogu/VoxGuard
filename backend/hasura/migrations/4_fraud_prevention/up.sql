-- ============================================================
-- FRAUD PREVENTION DATABASE SCHEMA
-- Migration: 4_fraud_prevention/up.sql
-- Non-disruptive addition to existing anti-masking schema
-- ============================================================

-- ============================================================
-- SHARED: Fraud Events (Event Sourcing)
-- ============================================================

CREATE TABLE IF NOT EXISTS fraud_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Event identification
    aggregate_type VARCHAR(50) NOT NULL,
    aggregate_id UUID NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    event_version INTEGER DEFAULT 1,
    
    -- Event data
    event_data JSONB NOT NULL,
    metadata JSONB,
    
    -- Risk
    risk_level VARCHAR(20),
    risk_score DECIMAL(5,4),
    
    -- Processing
    occurred_at TIMESTAMPTZ DEFAULT NOW(),
    processed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_fraud_events_aggregate ON fraud_events(aggregate_type, aggregate_id);
CREATE INDEX IF NOT EXISTS idx_fraud_events_type ON fraud_events(event_type);
CREATE INDEX IF NOT EXISTS idx_fraud_events_time ON fraud_events(occurred_at DESC);

-- ============================================================
-- CLI INTEGRITY CONTEXT
-- ============================================================

CREATE TABLE IF NOT EXISTS cli_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- CLI data
    presented_cli VARCHAR(20) NOT NULL,
    actual_cli VARCHAR(20),
    network_cli VARCHAR(20),
    
    -- Verification results
    spoofing_detected BOOLEAN DEFAULT FALSE,
    spoofing_type VARCHAR(50),
    confidence_score DECIMAL(5,4),
    
    -- Analysis
    verification_method VARCHAR(50),
    ss7_analysis JSONB,
    sip_header_analysis JSONB,
    stir_shaken_result JSONB,
    
    -- Metadata
    carrier_id UUID REFERENCES carriers(id),
    call_direction VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cli_presented ON cli_verifications(presented_cli);
CREATE INDEX IF NOT EXISTS idx_cli_spoofing ON cli_verifications(spoofing_detected, spoofing_type);
CREATE INDEX IF NOT EXISTS idx_cli_timestamp ON cli_verifications(created_at DESC);

CREATE TABLE IF NOT EXISTS spoofing_blacklist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    number_pattern VARCHAR(30) NOT NULL,
    pattern_type VARCHAR(20) NOT NULL,
    spoofing_type VARCHAR(50),
    reason TEXT,
    reported_by UUID,
    incident_count INTEGER DEFAULT 1,
    first_seen TIMESTAMPTZ DEFAULT NOW(),
    last_seen TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    
    UNIQUE(number_pattern, pattern_type)
);

-- ============================================================
-- REVENUE PROTECTION CONTEXT: IRSF
-- ============================================================

CREATE TABLE IF NOT EXISTS irsf_destinations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_code VARCHAR(5) NOT NULL,
    prefix VARCHAR(15) NOT NULL,
    country_name VARCHAR(100),
    
    -- Risk assessment
    risk_level VARCHAR(20) NOT NULL,
    fraud_types TEXT[],
    average_fraud_rate DECIMAL(18,4),
    
    -- Tracking
    incident_count INTEGER DEFAULT 0,
    last_incident_at TIMESTAMPTZ,
    
    -- Status
    is_blacklisted BOOLEAN DEFAULT FALSE,
    is_monitored BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(country_code, prefix)
);

CREATE TABLE IF NOT EXISTS irsf_incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Call details
    source_number VARCHAR(20) NOT NULL,
    destination_number VARCHAR(20) NOT NULL,
    destination_country VARCHAR(5) NOT NULL,
    destination_prefix VARCHAR(15),
    
    -- Detection
    risk_score DECIMAL(5,4) NOT NULL,
    irsf_indicators JSONB NOT NULL,
    detection_method VARCHAR(50),
    matched_pattern_id UUID REFERENCES irsf_destinations(id),
    
    -- Financial impact
    call_duration_seconds INTEGER,
    rate_per_minute DECIMAL(18,4),
    estimated_loss DECIMAL(18,4),
    
    -- Actions
    action_taken VARCHAR(50),
    blocked_at TIMESTAMPTZ,
    
    -- Metadata
    carrier_id UUID REFERENCES carriers(id),
    subscriber_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_irsf_destination ON irsf_incidents(destination_country, destination_prefix);
CREATE INDEX IF NOT EXISTS idx_irsf_risk ON irsf_incidents(risk_score DESC);
CREATE INDEX IF NOT EXISTS idx_irsf_timestamp ON irsf_incidents(created_at DESC);

-- ============================================================
-- REVENUE PROTECTION CONTEXT: OBR
-- ============================================================

CREATE TABLE IF NOT EXISTS obr_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscriber_id UUID NOT NULL UNIQUE,
    
    -- Origin classification
    origin_country VARCHAR(5),
    origin_carrier_id UUID REFERENCES carriers(id),
    origin_type VARCHAR(20),
    
    -- Rating
    rating_plan_id UUID,
    
    -- Limits
    daily_limit DECIMAL(18,4),
    monthly_limit DECIMAL(18,4),
    international_limit DECIMAL(18,4),
    premium_rate_limit DECIMAL(18,4),
    
    -- Current usage
    current_daily_spend DECIMAL(18,4) DEFAULT 0,
    current_monthly_spend DECIMAL(18,4) DEFAULT 0,
    last_reset_date DATE DEFAULT CURRENT_DATE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS obr_rate_tables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rating_plan_id UUID NOT NULL,
    
    -- Route
    destination_prefix VARCHAR(15) NOT NULL,
    origin_type VARCHAR(20) NOT NULL,
    
    -- Rates
    rate_per_minute DECIMAL(18,6) NOT NULL,
    connection_fee DECIMAL(18,4) DEFAULT 0,
    minimum_duration_seconds INTEGER DEFAULT 0,
    
    -- Fraud adjustment
    fraud_risk_multiplier DECIMAL(5,4) DEFAULT 1.0,
    
    effective_from TIMESTAMPTZ DEFAULT NOW(),
    effective_to TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_obr_route ON obr_rate_tables(destination_prefix, origin_type);

-- ============================================================
-- REVENUE PROTECTION CONTEXT: Premium Rate
-- ============================================================

CREATE TABLE IF NOT EXISTS premium_rate_numbers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    number VARCHAR(20) NOT NULL UNIQUE,
    country_code VARCHAR(5) NOT NULL,
    
    -- Service details
    service_category VARCHAR(50),
    content_provider_id UUID,
    content_provider_name VARCHAR(200),
    
    -- Rates
    rate_per_minute DECIMAL(18,4),
    rate_per_call DECIMAL(18,4),
    max_duration_seconds INTEGER,
    
    -- Registration
    registration_number VARCHAR(100),
    registration_valid BOOLEAN DEFAULT TRUE,
    registration_expiry DATE,
    
    -- Fraud status
    fraud_reports INTEGER DEFAULT 0,
    is_blocked BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS premium_rate_calls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Call details
    premium_number_id UUID REFERENCES premium_rate_numbers(id),
    caller_number VARCHAR(20) NOT NULL,
    
    -- Consent
    consent_status VARCHAR(20),
    consent_timestamp TIMESTAMPTZ,
    
    -- Fraud analysis
    fraud_indicators JSONB,
    risk_score DECIMAL(5,4),
    
    -- Financial
    call_duration_seconds INTEGER,
    charge_amount DECIMAL(18,4),
    
    -- Actions
    action_taken VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_premium_caller ON premium_rate_calls(caller_number);
CREATE INDEX IF NOT EXISTS idx_premium_risk ON premium_rate_calls(risk_score DESC);

-- ============================================================
-- CALL PATTERN CONTEXT: Wangiri
-- ============================================================

CREATE TABLE IF NOT EXISTS wangiri_incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Missed call details
    source_number VARCHAR(20) NOT NULL,
    target_number VARCHAR(20) NOT NULL,
    ring_duration_ms INTEGER NOT NULL,
    
    -- Analysis
    wangiri_indicators JSONB NOT NULL,
    confidence_score DECIMAL(5,4) NOT NULL,
    
    -- Callback tracking
    callback_attempted BOOLEAN DEFAULT FALSE,
    callback_destination VARCHAR(20),
    callback_cost DECIMAL(18,4),
    callback_duration_seconds INTEGER,
    
    -- Campaign association
    campaign_id UUID,
    
    -- Actions
    warning_sent BOOLEAN DEFAULT FALSE,
    callback_blocked BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_wangiri_source ON wangiri_incidents(source_number);
CREATE INDEX IF NOT EXISTS idx_wangiri_confidence ON wangiri_incidents(confidence_score DESC);
CREATE INDEX IF NOT EXISTS idx_wangiri_timestamp ON wangiri_incidents(created_at DESC);

CREATE TABLE IF NOT EXISTS wangiri_campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Source identification
    source_numbers TEXT[] NOT NULL,
    source_country VARCHAR(5),
    source_carrier_id UUID,
    
    -- Campaign characteristics
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    targeted_prefixes TEXT[],
    avg_ring_duration_ms INTEGER,
    
    -- Impact
    total_call_attempts INTEGER DEFAULT 0,
    successful_callbacks INTEGER DEFAULT 0,
    estimated_revenue_loss DECIMAL(18,4) DEFAULT 0,
    
    -- Mitigation
    status VARCHAR(20) DEFAULT 'ACTIVE',
    blocked_numbers TEXT[],
    alerts_sent INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_wangiri_campaign_status ON wangiri_campaigns(status);
CREATE INDEX IF NOT EXISTS idx_wangiri_campaign_time ON wangiri_campaigns(start_time DESC);

-- ============================================================
-- CALL PATTERN CONTEXT: Callback Fraud
-- ============================================================

CREATE TABLE IF NOT EXISTS callback_fraud_incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Trigger
    trigger_type VARCHAR(30) NOT NULL,
    trigger_call_id UUID,
    
    -- Callback details
    callback_source VARCHAR(20) NOT NULL,
    callback_destination VARCHAR(20) NOT NULL,
    callback_duration_seconds INTEGER,
    
    -- Risk
    destination_risk_level VARCHAR(20),
    fraud_type VARCHAR(50),
    
    -- Financial impact
    domestic_cost DECIMAL(18,4) DEFAULT 0,
    international_cost DECIMAL(18,4) DEFAULT 0,
    premium_cost DECIMAL(18,4) DEFAULT 0,
    total_loss DECIMAL(18,4) DEFAULT 0,
    
    -- Detection
    detection_method VARCHAR(50),
    detection_time TIMESTAMPTZ DEFAULT NOW(),
    
    -- Actions
    action_taken VARCHAR(50),
    subscriber_notified BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_callback_destination ON callback_fraud_incidents(callback_destination);
CREATE INDEX IF NOT EXISTS idx_callback_loss ON callback_fraud_incidents(total_loss DESC);

-- ============================================================
-- FEATURE FLAGS
-- ============================================================

CREATE TABLE IF NOT EXISTS fraud_feature_flags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flag_name VARCHAR(100) NOT NULL UNIQUE,
    flag_value BOOLEAN DEFAULT FALSE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default feature flags
INSERT INTO fraud_feature_flags (flag_name, flag_value, description) VALUES
    ('fraud.cli.enabled', true, 'CLI spoofing detection'),
    ('fraud.cli.block', false, 'Auto-block CLI spoofing'),
    ('fraud.irsf.enabled', true, 'IRSF detection'),
    ('fraud.irsf.block', false, 'Auto-block IRSF (monitor first)'),
    ('fraud.wangiri.enabled', true, 'Wangiri detection'),
    ('fraud.wangiri.block', false, 'Auto-block wangiri callbacks'),
    ('fraud.premium.enabled', true, 'Premium rate monitoring'),
    ('fraud.obr.enabled', false, 'Origin-based rating')
ON CONFLICT (flag_name) DO NOTHING;

-- ============================================================
-- VIEWS
-- ============================================================

CREATE OR REPLACE VIEW v_fraud_summary AS
SELECT 
    DATE_TRUNC('day', created_at) AS date,
    'CLI_SPOOFING' AS fraud_type,
    COUNT(*) AS incident_count,
    AVG(confidence_score) AS avg_confidence
FROM cli_verifications
WHERE spoofing_detected = TRUE
GROUP BY DATE_TRUNC('day', created_at)

UNION ALL

SELECT 
    DATE_TRUNC('day', created_at) AS date,
    'IRSF' AS fraud_type,
    COUNT(*) AS incident_count,
    AVG(risk_score) AS avg_confidence
FROM irsf_incidents
GROUP BY DATE_TRUNC('day', created_at)

UNION ALL

SELECT 
    DATE_TRUNC('day', created_at) AS date,
    'WANGIRI' AS fraud_type,
    COUNT(*) AS incident_count,
    AVG(confidence_score) AS avg_confidence
FROM wangiri_incidents
GROUP BY DATE_TRUNC('day', created_at);

-- ============================================================
-- STORED PROCEDURES
-- ============================================================

CREATE OR REPLACE FUNCTION check_irsf_risk(p_destination VARCHAR(20))
RETURNS TABLE (
    risk_level VARCHAR(20),
    is_blacklisted BOOLEAN,
    matched_prefix VARCHAR(15)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.risk_level,
        d.is_blacklisted,
        d.prefix AS matched_prefix
    FROM irsf_destinations d
    WHERE p_destination LIKE d.prefix || '%'
    ORDER BY LENGTH(d.prefix) DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION detect_wangiri_campaign(
    p_source_number VARCHAR(20),
    p_lookback_minutes INTEGER DEFAULT 60
)
RETURNS TABLE (
    is_campaign BOOLEAN,
    call_count INTEGER,
    campaign_id UUID
) AS $$
DECLARE
    v_count INTEGER;
    v_campaign_id UUID;
BEGIN
    SELECT COUNT(*), MAX(wc.campaign_id)
    INTO v_count, v_campaign_id
    FROM wangiri_incidents wc
    WHERE wc.source_number = p_source_number
    AND wc.created_at > NOW() - (p_lookback_minutes || ' minutes')::INTERVAL;
    
    RETURN QUERY SELECT 
        v_count >= 10 AS is_campaign,
        v_count,
        v_campaign_id;
END;
$$ LANGUAGE plpgsql;
