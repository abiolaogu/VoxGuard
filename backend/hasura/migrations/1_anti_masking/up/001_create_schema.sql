-- ============================================================================
-- Anti-Call Masking Platform - Core Infrastructure Schema
-- YugabyteDB (PostgreSQL-compatible) Migration
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- Domain Event Store (Shared across all bounded contexts)
-- ============================================================================

CREATE TABLE domain_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_type VARCHAR(100) NOT NULL,
    aggregate_id UUID NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB NOT NULL,
    metadata JSONB DEFAULT '{}',
    occurred_at TIMESTAMPTZ DEFAULT NOW(),
    processed_at TIMESTAMPTZ,
    version INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for efficient event replay
CREATE INDEX idx_domain_events_aggregate ON domain_events(aggregate_type, aggregate_id, version);
CREATE INDEX idx_domain_events_type ON domain_events(event_type);
CREATE INDEX idx_domain_events_unprocessed ON domain_events(occurred_at) WHERE processed_at IS NULL;

-- ============================================================================
-- Carriers (Value Object / Reference Data)
-- ============================================================================

CREATE TABLE carriers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    country_code VARCHAR(3) NOT NULL DEFAULT 'NGA',
    prefixes VARCHAR[] NOT NULL DEFAULT '{}',
    api_endpoint TEXT,
    authentication_config JSONB DEFAULT '{}',
    rate_limit_per_second INTEGER DEFAULT 100,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert Nigerian carriers
INSERT INTO carriers (code, name, country_code, prefixes, is_active) VALUES
    ('MTN', 'MTN Nigeria', 'NGA', ARRAY['0803', '0806', '0703', '0706', '0813', '0816', '0814', '0903', '0906'], TRUE),
    ('GLO', 'Globacom', 'NGA', ARRAY['0805', '0807', '0705', '0815', '0811', '0905'], TRUE),
    ('AIRTEL', 'Airtel Nigeria', 'NGA', ARRAY['0802', '0808', '0708', '0812', '0701', '0902', '0901', '0907'], TRUE),
    ('9MOBILE', '9mobile', 'NGA', ARRAY['0809', '0818', '0817', '0909', '0908'], TRUE);

-- ============================================================================
-- Gateways (Aggregate)
-- ============================================================================

CREATE TYPE gateway_type AS ENUM ('LOCAL', 'INTERNATIONAL', 'TRANSIT');

CREATE TABLE gateways (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    ip_address INET NOT NULL UNIQUE,
    carrier_id UUID REFERENCES carriers(id),
    carrier_name VARCHAR(100),
    gateway_type gateway_type NOT NULL DEFAULT 'LOCAL',
    is_active BOOLEAN DEFAULT TRUE,
    is_blacklisted BOOLEAN DEFAULT FALSE,
    blacklist_reason TEXT,
    blacklisted_at TIMESTAMPTZ,
    blacklisted_by VARCHAR(100),
    blacklist_expires_at TIMESTAMPTZ,
    fraud_threshold DECIMAL(5,4) DEFAULT 0.85,
    cpm_limit INTEGER DEFAULT 60,
    acd_threshold DECIMAL(8,2) DEFAULT 10.0,
    total_calls BIGINT DEFAULT 0,
    fraud_calls BIGINT DEFAULT 0,
    last_call_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_gateways_ip ON gateways(ip_address);
CREATE INDEX idx_gateways_active ON gateways(is_active, is_blacklisted);
CREATE INDEX idx_gateways_carrier ON gateways(carrier_id);

-- ============================================================================
-- Call Verifications (Aggregate Root)
-- ============================================================================

CREATE TYPE call_status AS ENUM ('RINGING', 'ACTIVE', 'COMPLETED', 'FAILED', 'BLOCKED');
CREATE TYPE detection_method AS ENUM ('SLIDING_WINDOW', 'PATTERN_MATCH', 'ML_MODEL', 'MANUAL');

CREATE TABLE call_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    call_id VARCHAR(100) UNIQUE,
    a_number VARCHAR(20) NOT NULL,
    b_number VARCHAR(20) NOT NULL,
    a_carrier_id UUID REFERENCES carriers(id),
    b_carrier_id UUID REFERENCES carriers(id),
    source_ip INET NOT NULL,
    gateway_id UUID REFERENCES gateways(id),
    status call_status NOT NULL DEFAULT 'RINGING',
    is_flagged BOOLEAN DEFAULT FALSE,
    masking_detected BOOLEAN DEFAULT FALSE,
    confidence_score DECIMAL(5,4),
    detection_method detection_method,
    raw_cli VARCHAR(50),
    verified_cli VARCHAR(50),
    p_asserted_identity VARCHAR(100),
    remote_party_id VARCHAR(100),
    alert_id UUID,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    answered_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    duration_seconds INTEGER,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Partition by time for efficient querying
-- In production, use YugabyteDB table partitioning
CREATE INDEX idx_calls_b_number ON call_verifications(b_number, started_at);
CREATE INDEX idx_calls_a_number ON call_verifications(a_number, started_at);
CREATE INDEX idx_calls_gateway ON call_verifications(gateway_id, started_at);
CREATE INDEX idx_calls_flagged ON call_verifications(is_flagged, started_at) WHERE is_flagged = TRUE;
CREATE INDEX idx_calls_alert ON call_verifications(alert_id) WHERE alert_id IS NOT NULL;

-- ============================================================================
-- Fraud Alerts (Aggregate Root)
-- ============================================================================

CREATE TYPE fraud_type AS ENUM ('CLI_MASKING', 'SIMBOX', 'WANGIRI', 'IRSF', 'PBX_HACKING');
CREATE TYPE severity_level AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL');
CREATE TYPE alert_status AS ENUM ('PENDING', 'ACKNOWLEDGED', 'INVESTIGATING', 'RESOLVED', 'REPORTED_NCC');
CREATE TYPE resolution_type AS ENUM ('CONFIRMED_FRAUD', 'FALSE_POSITIVE', 'ESCALATED', 'WHITELISTED');

CREATE TABLE fraud_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    b_number VARCHAR(20) NOT NULL,
    fraud_type fraud_type NOT NULL,
    score DECIMAL(5,4) NOT NULL,
    severity severity_level NOT NULL,
    distinct_callers INTEGER NOT NULL DEFAULT 0,
    a_numbers VARCHAR[] DEFAULT '{}',
    source_ips INET[] DEFAULT '{}',
    gateway_ids UUID[] DEFAULT '{}',
    status alert_status NOT NULL DEFAULT 'PENDING',
    acknowledged_by VARCHAR(100),
    acknowledged_at TIMESTAMPTZ,
    resolved_by VARCHAR(100),
    resolved_at TIMESTAMPTZ,
    resolution resolution_type,
    resolution_notes TEXT,
    ncc_reported BOOLEAN DEFAULT FALSE,
    ncc_report_id VARCHAR(100),
    ncc_reported_at TIMESTAMPTZ,
    detected_at TIMESTAMPTZ DEFAULT NOW(),
    window_start TIMESTAMPTZ,
    window_end TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_alerts_status ON fraud_alerts(status, detected_at);
CREATE INDEX idx_alerts_severity ON fraud_alerts(severity, status);
CREATE INDEX idx_alerts_b_number ON fraud_alerts(b_number);
CREATE INDEX idx_alerts_ncc ON fraud_alerts(ncc_reported, ncc_report_id);

-- ============================================================================
-- Blacklist (Entity)
-- ============================================================================

CREATE TYPE blacklist_entry_type AS ENUM ('MSISDN', 'IP', 'GATEWAY', 'IMEI', 'IMSI');
CREATE TYPE blacklist_source AS ENUM ('MANUAL', 'AUTO', 'NCC', 'CARRIER');

CREATE TABLE blacklist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entry_type blacklist_entry_type NOT NULL,
    value VARCHAR(100) NOT NULL,
    reason TEXT,
    source blacklist_source NOT NULL DEFAULT 'MANUAL',
    added_by VARCHAR(100),
    alert_id UUID REFERENCES fraud_alerts(id),
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(entry_type, value)
);

CREATE INDEX idx_blacklist_lookup ON blacklist(entry_type, value, is_active);
CREATE INDEX idx_blacklist_expires ON blacklist(expires_at) WHERE expires_at IS NOT NULL;

-- ============================================================================
-- MNP Records (Mobile Number Portability)
-- ============================================================================

CREATE TABLE mnp_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    msisdn VARCHAR(20) UNIQUE NOT NULL,
    original_carrier_id UUID REFERENCES carriers(id),
    current_carrier_id UUID REFERENCES carriers(id),
    routing_number VARCHAR(10),
    ported_at TIMESTAMPTZ,
    is_ported BOOLEAN DEFAULT FALSE,
    last_verified_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_mnp_msisdn ON mnp_records(msisdn);
CREATE INDEX idx_mnp_carrier ON mnp_records(current_carrier_id);

-- ============================================================================
-- NCC Compliance Reports
-- ============================================================================

CREATE TYPE report_type AS ENUM ('ATRS', 'DAILY_CDR', 'MONTHLY_SUMMARY', 'INCIDENT');
CREATE TYPE report_status AS ENUM ('PENDING', 'SUBMITTED', 'ACKNOWLEDGED', 'REJECTED');

CREATE TABLE ncc_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_type report_type NOT NULL,
    reference_number VARCHAR(100) UNIQUE,
    period_start TIMESTAMPTZ,
    period_end TIMESTAMPTZ,
    alert_ids UUID[] DEFAULT '{}',
    total_calls BIGINT,
    fraud_calls BIGINT,
    fraud_rate DECIMAL(8,4),
    status report_status NOT NULL DEFAULT 'PENDING',
    submitted_at TIMESTAMPTZ,
    acknowledged_at TIMESTAMPTZ,
    ncc_reference VARCHAR(100),
    response_data JSONB DEFAULT '{}',
    file_path TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_ncc_reports_status ON ncc_reports(status, report_type);
CREATE INDEX idx_ncc_reports_period ON ncc_reports(period_start, period_end);

-- ============================================================================
-- Audit Log
-- ============================================================================

CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type VARCHAR(100) NOT NULL,
    entity_id UUID NOT NULL,
    action VARCHAR(50) NOT NULL,
    actor_id VARCHAR(100),
    actor_role VARCHAR(50),
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_entity ON audit_log(entity_type, entity_id);
CREATE INDEX idx_audit_actor ON audit_log(actor_id);
CREATE INDEX idx_audit_time ON audit_log(created_at);

-- ============================================================================
-- Trigger: Update timestamps
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_carriers_updated_at BEFORE UPDATE ON carriers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_gateways_updated_at BEFORE UPDATE ON gateways
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_call_verifications_updated_at BEFORE UPDATE ON call_verifications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_fraud_alerts_updated_at BEFORE UPDATE ON fraud_alerts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_blacklist_updated_at BEFORE UPDATE ON blacklist
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
