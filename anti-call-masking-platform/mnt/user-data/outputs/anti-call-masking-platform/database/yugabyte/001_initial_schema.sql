-- ============================================================================
-- Anti-Call Masking Platform - YugabyteDB Schema
-- Nigerian ICL (Interconnect Clearinghouse) Database
-- Version: 2.0 | Date: 2026-01-22
-- ============================================================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================================
-- GATEWAY MANAGEMENT
-- ============================================================================

-- Gateway address groups for permissions module
-- Group 1: Trusted local carriers
-- Group 10: International gateways
-- Group 66: Blacklisted sources
CREATE TABLE IF NOT EXISTS address (
    id SERIAL PRIMARY KEY,
    grp SMALLINT NOT NULL DEFAULT 0,
    ip VARCHAR(64) NOT NULL,
    mask SMALLINT NOT NULL DEFAULT 32,
    port SMALLINT NOT NULL DEFAULT 0,
    proto VARCHAR(8) DEFAULT 'any',
    pattern VARCHAR(128),
    context_info VARCHAR(256),
    tag VARCHAR(64),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE (grp, ip, mask, port)
) SPLIT INTO 3 TABLETS;

CREATE INDEX idx_address_grp ON address(grp);
CREATE INDEX idx_address_ip ON address(ip);
CREATE INDEX idx_address_tag ON address(tag);

-- Gateway profiles with detailed metadata
CREATE TABLE IF NOT EXISTS gateway_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(128) NOT NULL UNIQUE,
    carrier_code VARCHAR(16) NOT NULL,
    carrier_name VARCHAR(256),
    gateway_type VARCHAR(32) NOT NULL CHECK (gateway_type IN ('LOCAL', 'INTERNATIONAL', 'TRANSIT', 'PREMIUM')),
    address_grp SMALLINT NOT NULL REFERENCES address(grp) ON DELETE RESTRICT,
    primary_ip INET NOT NULL,
    secondary_ip INET,
    sip_port INTEGER DEFAULT 5060,
    transport VARCHAR(8) DEFAULT 'UDP' CHECK (transport IN ('UDP', 'TCP', 'TLS')),
    
    -- Traffic limits
    max_cps INTEGER DEFAULT 100,
    max_concurrent INTEGER DEFAULT 1000,
    
    -- Billing
    currency VARCHAR(3) DEFAULT 'NGN',
    local_rate_per_min DECIMAL(10, 4),
    intl_rate_per_min DECIMAL(10, 4),
    
    -- Fraud thresholds (override defaults)
    cpm_warning INTEGER DEFAULT 40,
    cpm_critical INTEGER DEFAULT 60,
    acd_warning_seconds INTEGER DEFAULT 10,
    acd_critical_seconds INTEGER DEFAULT 5,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    is_blacklisted BOOLEAN DEFAULT FALSE,
    blacklist_reason TEXT,
    last_traffic_at TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    ncc_license VARCHAR(64),
    contact_email VARCHAR(256),
    contact_phone VARCHAR(32),
    notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
) SPLIT INTO 3 TABLETS;

CREATE INDEX idx_gateway_carrier ON gateway_profiles(carrier_code);
CREATE INDEX idx_gateway_type ON gateway_profiles(gateway_type);
CREATE INDEX idx_gateway_active ON gateway_profiles(is_active);

-- ============================================================================
-- MNP (Mobile Number Portability)
-- ============================================================================

-- MNP master data
CREATE TABLE IF NOT EXISTS mnp_data (
    msisdn VARCHAR(15) PRIMARY KEY,
    original_network_id VARCHAR(8) NOT NULL,
    hosting_network_id VARCHAR(8) NOT NULL,
    routing_number VARCHAR(8) NOT NULL,
    port_date DATE,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_ported BOOLEAN GENERATED ALWAYS AS (original_network_id != hosting_network_id) STORED
) SPLIT INTO 6 TABLETS;

CREATE INDEX idx_mnp_hosting ON mnp_data(hosting_network_id);
CREATE INDEX idx_mnp_routing ON mnp_data(routing_number);
CREATE INDEX idx_mnp_ported ON mnp_data(is_ported) WHERE is_ported = TRUE;

-- Nigerian MNO reference table
CREATE TABLE IF NOT EXISTS mno_reference (
    network_id VARCHAR(8) PRIMARY KEY,
    mno_name VARCHAR(64) NOT NULL,
    mno_code VARCHAR(16) NOT NULL,
    routing_number VARCHAR(8) NOT NULL UNIQUE,
    prefixes TEXT[] NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Seed Nigerian MNOs (2026 data)
INSERT INTO mno_reference (network_id, mno_name, mno_code, routing_number, prefixes) VALUES
    ('NG001', 'MTN Nigeria', 'MTN', 'D013', ARRAY['703','706','803','806','810','813','814','816','903','906','913','916']),
    ('NG002', 'Airtel Nigeria', 'AIRTEL', 'D018', ARRAY['701','708','802','808','812','901','902','904','907','912']),
    ('NG003', 'Globacom', 'GLO', 'D015', ARRAY['705','805','807','811','815','905','915']),
    ('NG004', '9mobile', '9MOBILE', 'D019', ARRAY['809','817','818','908','909'])
ON CONFLICT (network_id) DO UPDATE SET
    routing_number = EXCLUDED.routing_number,
    prefixes = EXCLUDED.prefixes;

-- ============================================================================
-- FRAUD DETECTION
-- ============================================================================

-- Fraud detection thresholds per prefix/carrier
CREATE TABLE IF NOT EXISTS fraud_detection_profiles (
    id SERIAL PRIMARY KEY,
    profile_name VARCHAR(64) NOT NULL,
    prefix VARCHAR(16),
    carrier_code VARCHAR(16),
    
    -- SIM-box thresholds
    cpm_warning INTEGER DEFAULT 40,
    cpm_critical INTEGER DEFAULT 60,
    acd_warning_seconds DECIMAL(6, 2) DEFAULT 10.0,
    acd_critical_seconds DECIMAL(6, 2) DEFAULT 5.0,
    unique_dest_warning INTEGER DEFAULT 100,
    unique_dest_critical INTEGER DEFAULT 200,
    concurrent_warning INTEGER DEFAULT 20,
    concurrent_critical INTEGER DEFAULT 50,
    
    -- Behavioral analysis
    night_call_threshold DECIMAL(5, 2) DEFAULT 30.0,  -- % of calls during night
    weekend_call_threshold DECIMAL(5, 2) DEFAULT 40.0,
    short_call_ratio DECIMAL(5, 2) DEFAULT 50.0,      -- % of calls < 10 seconds
    
    -- Scoring weights
    weight_cpm DECIMAL(3, 2) DEFAULT 0.30,
    weight_acd DECIMAL(3, 2) DEFAULT 0.25,
    weight_unique_dest DECIMAL(3, 2) DEFAULT 0.20,
    weight_concurrent DECIMAL(3, 2) DEFAULT 0.15,
    weight_behavioral DECIMAL(3, 2) DEFAULT 0.10,
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT chk_weights CHECK (
        weight_cpm + weight_acd + weight_unique_dest + weight_concurrent + weight_behavioral = 1.0
    )
);

CREATE INDEX idx_fraud_profile_prefix ON fraud_detection_profiles(prefix);
CREATE INDEX idx_fraud_profile_carrier ON fraud_detection_profiles(carrier_code);

-- Insert default profile
INSERT INTO fraud_detection_profiles (profile_name, prefix) VALUES
    ('Default Nigerian', '234')
ON CONFLICT DO NOTHING;

-- Fraud alerts storage
CREATE TABLE IF NOT EXISTS fraud_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    call_id VARCHAR(128) NOT NULL,
    fraud_type VARCHAR(32) NOT NULL CHECK (fraud_type IN (
        'CLI_MASK', 'SIM_BOX', 'REFILING', 'HDR_MANIP', 
        'UNAUTH_ROUTE', 'MNP_BYPASS', 'BLACKLIST', 'ANOMALY'
    )),
    source_ip INET NOT NULL,
    source_port INTEGER,
    caller_id VARCHAR(32) NOT NULL,
    called_number VARCHAR(32) NOT NULL,
    gateway_id UUID REFERENCES gateway_profiles(id),
    
    -- Detection details
    confidence DECIMAL(5, 2) NOT NULL,
    severity SMALLINT NOT NULL CHECK (severity BETWEEN 1 AND 5),
    action_taken VARCHAR(32) NOT NULL,
    reasons TEXT[],
    raw_data JSONB,
    
    -- NCC reporting
    ncc_reported BOOLEAN DEFAULT FALSE,
    ncc_report_id VARCHAR(64),
    ncc_report_time TIMESTAMP WITH TIME ZONE,
    
    -- Timestamps
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
) SPLIT INTO 6 TABLETS;

CREATE INDEX idx_fraud_alerts_type ON fraud_alerts(fraud_type);
CREATE INDEX idx_fraud_alerts_source ON fraud_alerts(source_ip);
CREATE INDEX idx_fraud_alerts_caller ON fraud_alerts(caller_id);
CREATE INDEX idx_fraud_alerts_detected ON fraud_alerts(detected_at DESC);
CREATE INDEX idx_fraud_alerts_ncc ON fraud_alerts(ncc_reported) WHERE ncc_reported = FALSE;

-- Blacklist table
CREATE TABLE IF NOT EXISTS blacklist (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entry_type VARCHAR(16) NOT NULL CHECK (entry_type IN ('IP', 'CLI', 'PREFIX', 'CARRIER')),
    entry_value VARCHAR(64) NOT NULL,
    reason TEXT NOT NULL,
    severity SMALLINT DEFAULT 3 CHECK (severity BETWEEN 1 AND 5),
    
    -- Source of blacklist
    source VARCHAR(32) NOT NULL DEFAULT 'INTERNAL' CHECK (source IN ('INTERNAL', 'NCC', 'CARRIER', 'AUTOMATED')),
    source_ref VARCHAR(128),
    
    -- Validity
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    is_permanent BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Audit
    added_by VARCHAR(128),
    notes TEXT,
    
    UNIQUE (entry_type, entry_value)
);

CREATE INDEX idx_blacklist_type ON blacklist(entry_type);
CREATE INDEX idx_blacklist_value ON blacklist(entry_value);
CREATE INDEX idx_blacklist_active ON blacklist(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_blacklist_expires ON blacklist(expires_at) WHERE expires_at IS NOT NULL;

-- ============================================================================
-- SETTLEMENT & BILLING
-- ============================================================================

-- Settlement disputes
CREATE TABLE IF NOT EXISTS settlement_disputes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dispute_type VARCHAR(32) NOT NULL CHECK (dispute_type IN (
        'CALL_MASKING', 'SIM_BOX', 'UNAUTHORIZED_ROUTE', 'RATE_DISPUTE', 'VOLUME_DISPUTE'
    )),
    
    -- Parties
    reporting_carrier VARCHAR(64) NOT NULL,
    disputed_carrier VARCHAR(64) NOT NULL,
    
    -- Call details
    call_ids TEXT[] NOT NULL,
    call_count INTEGER NOT NULL,
    total_minutes DECIMAL(12, 2),
    
    -- Financial
    original_amount DECIMAL(15, 2) NOT NULL,
    disputed_amount DECIMAL(15, 2) NOT NULL,
    recovery_amount DECIMAL(15, 2),
    currency VARCHAR(3) DEFAULT 'NGN',
    
    -- Evidence
    fraud_alert_ids UUID[],
    evidence_docs TEXT[],
    notes TEXT,
    
    -- Status tracking
    status VARCHAR(32) DEFAULT 'OPEN' CHECK (status IN (
        'OPEN', 'UNDER_REVIEW', 'ESCALATED', 'RESOLVED', 'REJECTED', 'CLOSED'
    )),
    resolution TEXT,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by VARCHAR(128),
    
    -- NCC escalation
    ncc_escalated BOOLEAN DEFAULT FALSE,
    ncc_case_id VARCHAR(64),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
) SPLIT INTO 3 TABLETS;

CREATE INDEX idx_disputes_status ON settlement_disputes(status);
CREATE INDEX idx_disputes_reporting ON settlement_disputes(reporting_carrier);
CREATE INDEX idx_disputes_disputed ON settlement_disputes(disputed_carrier);
CREATE INDEX idx_disputes_created ON settlement_disputes(created_at DESC);

-- ============================================================================
-- DYNAMIC ROUTING (OpenSIPS dr_* tables)
-- ============================================================================

-- Routing rules
CREATE TABLE IF NOT EXISTS dr_rules (
    ruleid SERIAL PRIMARY KEY,
    groupid VARCHAR(32) NOT NULL DEFAULT '',
    prefix VARCHAR(64) NOT NULL,
    timerec VARCHAR(256) DEFAULT '',
    priority INTEGER DEFAULT 0,
    routeid VARCHAR(64) DEFAULT '',
    gwlist VARCHAR(256) NOT NULL,
    attrs VARCHAR(256) DEFAULT '',
    description VARCHAR(256) DEFAULT ''
);

CREATE INDEX idx_dr_rules_prefix ON dr_rules(prefix);
CREATE INDEX idx_dr_rules_group ON dr_rules(groupid);

-- Gateways for dynamic routing
CREATE TABLE IF NOT EXISTS dr_gateways (
    gwid VARCHAR(64) PRIMARY KEY,
    type INTEGER DEFAULT 0,
    address VARCHAR(128) NOT NULL,
    strip INTEGER DEFAULT 0,
    pri_prefix VARCHAR(16) DEFAULT '',
    attrs VARCHAR(256) DEFAULT '',
    probe_mode INTEGER DEFAULT 0,
    state INTEGER DEFAULT 0,
    socket VARCHAR(128) DEFAULT '',
    description VARCHAR(256) DEFAULT ''
);

-- Gateway groups
CREATE TABLE IF NOT EXISTS dr_groups (
    id SERIAL PRIMARY KEY,
    username VARCHAR(64) DEFAULT '',
    domain VARCHAR(128) DEFAULT '',
    groupid INTEGER DEFAULT 0,
    description VARCHAR(256) DEFAULT ''
);

-- ============================================================================
-- DISPATCHER (Load balancing)
-- ============================================================================

CREATE TABLE IF NOT EXISTS dispatcher (
    id SERIAL PRIMARY KEY,
    setid INTEGER NOT NULL DEFAULT 0,
    destination VARCHAR(192) NOT NULL DEFAULT '',
    socket VARCHAR(128) DEFAULT '',
    state INTEGER DEFAULT 0,
    weight VARCHAR(64) DEFAULT '',
    priority INTEGER DEFAULT 0,
    attrs VARCHAR(256) DEFAULT '',
    description VARCHAR(256) DEFAULT ''
);

CREATE INDEX idx_dispatcher_setid ON dispatcher(setid);

-- ============================================================================
-- ACCOUNTING (CDRs)
-- ============================================================================

CREATE TABLE IF NOT EXISTS acc (
    id BIGSERIAL PRIMARY KEY,
    method VARCHAR(16) NOT NULL DEFAULT '',
    from_tag VARCHAR(64) NOT NULL DEFAULT '',
    to_tag VARCHAR(64) NOT NULL DEFAULT '',
    callid VARCHAR(128) NOT NULL DEFAULT '',
    sip_code VARCHAR(3) NOT NULL DEFAULT '',
    sip_reason VARCHAR(128) NOT NULL DEFAULT '',
    time TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Extended fields
    src_ip VARCHAR(64) DEFAULT '',
    dst_ip VARCHAR(64) DEFAULT '',
    caller_id VARCHAR(32) DEFAULT '',
    called_number VARCHAR(32) DEFAULT '',
    
    -- Fraud detection
    fraud_detected BOOLEAN DEFAULT FALSE,
    fraud_type VARCHAR(32) DEFAULT '',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
) SPLIT INTO 6 TABLETS;

CREATE INDEX idx_acc_callid ON acc(callid);
CREATE INDEX idx_acc_time ON acc(time DESC);
CREATE INDEX idx_acc_fraud ON acc(fraud_detected) WHERE fraud_detected = TRUE;

-- Missed calls
CREATE TABLE IF NOT EXISTS missed_calls (
    id BIGSERIAL PRIMARY KEY,
    method VARCHAR(16) NOT NULL DEFAULT '',
    from_tag VARCHAR(64) NOT NULL DEFAULT '',
    to_tag VARCHAR(64) NOT NULL DEFAULT '',
    callid VARCHAR(128) NOT NULL DEFAULT '',
    sip_code VARCHAR(3) NOT NULL DEFAULT '',
    sip_reason VARCHAR(128) NOT NULL DEFAULT '',
    time TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- DIALOG (Active calls tracking)
-- ============================================================================

CREATE TABLE IF NOT EXISTS dialog (
    id BIGSERIAL PRIMARY KEY,
    hash_entry INTEGER NOT NULL,
    hash_id INTEGER NOT NULL,
    callid VARCHAR(255) NOT NULL,
    from_uri VARCHAR(255) NOT NULL,
    from_tag VARCHAR(64) NOT NULL,
    to_uri VARCHAR(255) NOT NULL,
    to_tag VARCHAR(64) NOT NULL,
    mangled_from_uri VARCHAR(255) DEFAULT '',
    mangled_to_uri VARCHAR(255) DEFAULT '',
    caller_cseq VARCHAR(20) NOT NULL,
    callee_cseq VARCHAR(20) NOT NULL,
    caller_contact VARCHAR(255) NOT NULL,
    callee_contact VARCHAR(255) NOT NULL,
    caller_route_set VARCHAR(512) DEFAULT '',
    callee_route_set VARCHAR(512) DEFAULT '',
    caller_sock VARCHAR(64) NOT NULL,
    callee_sock VARCHAR(64) NOT NULL,
    state INTEGER NOT NULL,
    start_time INTEGER NOT NULL,
    timeout INTEGER NOT NULL,
    sflags INTEGER DEFAULT 0,
    iflags INTEGER DEFAULT 0,
    toroute_name VARCHAR(64) DEFAULT '',
    req_uri VARCHAR(255) DEFAULT '',
    xdata VARCHAR(512) DEFAULT '',
    
    UNIQUE (hash_entry, hash_id)
);

CREATE INDEX idx_dialog_callid ON dialog(callid);

-- ============================================================================
-- AUDIT LOG
-- ============================================================================

CREATE TABLE IF NOT EXISTS audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    action VARCHAR(64) NOT NULL,
    entity_type VARCHAR(64) NOT NULL,
    entity_id VARCHAR(128),
    actor VARCHAR(128) NOT NULL,
    actor_ip INET,
    old_value JSONB,
    new_value JSONB,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_audit_action ON audit_log(action);
CREATE INDEX idx_audit_entity ON audit_log(entity_type, entity_id);
CREATE INDEX idx_audit_actor ON audit_log(actor);
CREATE INDEX idx_audit_created ON audit_log(created_at DESC);

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers
CREATE TRIGGER trg_address_updated
    BEFORE UPDATE ON address
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_gateway_updated
    BEFORE UPDATE ON gateway_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_fraud_profile_updated
    BEFORE UPDATE ON fraud_detection_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_disputes_updated
    BEFORE UPDATE ON settlement_disputes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Function to check if IP is blacklisted
CREATE OR REPLACE FUNCTION is_ip_blacklisted(check_ip INET)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM blacklist
        WHERE entry_type = 'IP'
        AND is_active = TRUE
        AND (expires_at IS NULL OR expires_at > NOW())
        AND entry_value::inet >>= check_ip
    );
END;
$$ LANGUAGE plpgsql;

-- Function to get MNP routing number
CREATE OR REPLACE FUNCTION get_mnp_routing(p_msisdn VARCHAR)
RETURNS VARCHAR AS $$
DECLARE
    v_routing VARCHAR;
BEGIN
    SELECT routing_number INTO v_routing
    FROM mnp_data
    WHERE msisdn = p_msisdn;
    
    RETURN COALESCE(v_routing, '');
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SEED DATA
-- ============================================================================

-- Insert gateway groups
INSERT INTO address (grp, ip, mask, port, proto, tag, context_info) VALUES
    -- Group 1: Trusted local carriers
    (1, '10.0.1.0', 24, 0, 'any', 'MTN_NIGERIA', 'MTN Nigeria local gateway'),
    (1, '10.0.2.0', 24, 0, 'any', 'AIRTEL_NIGERIA', 'Airtel Nigeria local gateway'),
    (1, '10.0.3.0', 24, 0, 'any', 'GLO_NIGERIA', 'Globacom local gateway'),
    (1, '10.0.4.0', 24, 0, 'any', '9MOBILE', '9mobile local gateway'),
    
    -- Group 10: International gateways (example - replace with real IPs)
    (10, '203.0.113.0', 24, 0, 'any', 'INTL_GW_1', 'International gateway 1'),
    (10, '198.51.100.0', 24, 0, 'any', 'INTL_GW_2', 'International gateway 2')
ON CONFLICT (grp, ip, mask, port) DO NOTHING;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO opensips;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO opensips;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE address IS 'Gateway IP addresses grouped by trust level for OpenSIPS permissions';
COMMENT ON TABLE gateway_profiles IS 'Detailed gateway/carrier profiles with fraud thresholds';
COMMENT ON TABLE mnp_data IS 'Mobile Number Portability database for Nigerian numbers';
COMMENT ON TABLE fraud_alerts IS 'Detected fraud events with NCC reporting status';
COMMENT ON TABLE blacklist IS 'Blacklisted IPs, CLIs, prefixes and carriers';
COMMENT ON TABLE settlement_disputes IS 'Financial disputes between carriers due to fraud';
COMMENT ON TABLE fraud_detection_profiles IS 'Configurable fraud detection thresholds per prefix/carrier';
