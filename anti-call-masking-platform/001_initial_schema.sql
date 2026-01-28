-- ============================================================================
-- Anti-Call Masking Platform - ClickHouse Schema
-- High-Performance Analytics Database
-- Version: 2.0 | Date: 2026-01-22
-- ============================================================================

-- ============================================================================
-- CDR (Call Detail Records)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS acm;

-- Main CDR table with partitioning by month
CREATE TABLE IF NOT EXISTS acm.cdrs (
    id UUID DEFAULT generateUUIDv4(),
    call_id String,
    
    -- Timestamps
    start_time DateTime64(3) CODEC(Delta, ZSTD(1)),
    connect_time Nullable(DateTime64(3)),
    end_time Nullable(DateTime64(3)),
    
    -- Parties
    caller_id String CODEC(ZSTD(1)),
    called_number String CODEC(ZSTD(1)),
    caller_display String CODEC(ZSTD(1)),
    
    -- Source
    source_ip IPv4 CODEC(ZSTD(1)),
    source_port UInt16,
    source_gateway_id Nullable(String) CODEC(ZSTD(1)),
    source_gateway_group UInt8,
    
    -- Destination
    dest_ip Nullable(IPv4) CODEC(ZSTD(1)),
    dest_port Nullable(UInt16),
    dest_gateway_id Nullable(String) CODEC(ZSTD(1)),
    
    -- Call metrics
    duration_seconds UInt32 DEFAULT 0,
    ring_duration_seconds UInt16 DEFAULT 0,
    pdd_ms UInt32 DEFAULT 0,  -- Post-dial delay
    
    -- SIP details
    sip_response_code UInt16,
    sip_response_reason String CODEC(ZSTD(1)),
    user_agent String CODEC(ZSTD(1)),
    
    -- MNP
    mnp_ported Bool DEFAULT false,
    mnp_original_network String CODEC(ZSTD(1)),
    mnp_hosting_network String CODEC(ZSTD(1)),
    mnp_routing_number String CODEC(ZSTD(1)),
    
    -- Fraud detection
    fraud_detected Bool DEFAULT false,
    fraud_type LowCardinality(String) DEFAULT 'NONE',
    fraud_confidence Float32 DEFAULT 0,
    fraud_severity UInt8 DEFAULT 0,
    fraud_action LowCardinality(String) DEFAULT 'allow',
    detection_latency_us UInt32 DEFAULT 0,
    
    -- Billing
    billed Bool DEFAULT false,
    penalty_billing Bool DEFAULT false,
    local_rate Decimal(10, 4) DEFAULT 0,
    intl_rate Decimal(10, 4) DEFAULT 0,
    billed_amount Decimal(15, 4) DEFAULT 0,
    currency LowCardinality(String) DEFAULT 'NGN',
    
    -- Region/Node
    region LowCardinality(String) DEFAULT 'lagos',
    node_id String CODEC(ZSTD(1)),
    
    -- Headers (for debugging)
    p_asserted_identity String CODEC(ZSTD(1)),
    from_header String CODEC(ZSTD(1)),
    
    -- Metadata
    created_at DateTime64(3) DEFAULT now64(3)
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(start_time)
ORDER BY (start_time, source_ip, caller_id)
TTL start_time + INTERVAL 13 MONTH DELETE
SETTINGS index_granularity = 8192;

-- Secondary indexes
ALTER TABLE acm.cdrs ADD INDEX idx_call_id (call_id) TYPE bloom_filter GRANULARITY 1;
ALTER TABLE acm.cdrs ADD INDEX idx_caller_id (caller_id) TYPE bloom_filter GRANULARITY 1;
ALTER TABLE acm.cdrs ADD INDEX idx_fraud (fraud_detected) TYPE minmax GRANULARITY 1;

-- ============================================================================
-- REAL-TIME METRICS
-- ============================================================================

-- Detection metrics (aggregated every 10 seconds)
CREATE TABLE IF NOT EXISTS acm.detection_metrics (
    timestamp DateTime CODEC(Delta, ZSTD(1)),
    region LowCardinality(String),
    node_id String CODEC(ZSTD(1)),
    
    -- Volume metrics
    total_calls UInt64,
    fraud_detected UInt64,
    calls_blocked UInt64,
    calls_flagged UInt64,
    penalty_billed UInt64,
    
    -- Fraud type breakdown
    fraud_cli_mask UInt32,
    fraud_simbox UInt32,
    fraud_refiling UInt32,
    fraud_header_manip UInt32,
    fraud_blacklist UInt32,
    
    -- Latency metrics (microseconds)
    latency_min UInt32,
    latency_max UInt32,
    latency_avg Float32,
    latency_p50 UInt32,
    latency_p95 UInt32,
    latency_p99 UInt32,
    
    -- Cache metrics
    cache_hits UInt64,
    cache_misses UInt64,
    cache_hit_rate Float32,
    
    -- MNP metrics
    mnp_lookups UInt64,
    mnp_cache_hits UInt64,
    mnp_ported_calls UInt64,
    
    -- NCC reporting
    ncc_reports_sent UInt32,
    ncc_reports_failed UInt32,
    
    -- Error counts
    detection_errors UInt32,
    db_errors UInt32,
    cache_errors UInt32
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, region, node_id)
TTL timestamp + INTERVAL 3 MONTH DELETE
SETTINGS index_granularity = 8192;

-- ============================================================================
-- FRAUD ANALYTICS
-- ============================================================================

-- Fraud events detailed log
CREATE TABLE IF NOT EXISTS acm.fraud_events (
    id UUID DEFAULT generateUUIDv4(),
    timestamp DateTime64(3) CODEC(Delta, ZSTD(1)),
    
    call_id String,
    fraud_type LowCardinality(String),
    
    -- Source details
    source_ip IPv4 CODEC(ZSTD(1)),
    source_gateway_id String CODEC(ZSTD(1)),
    source_gateway_group UInt8,
    
    -- CLI details
    caller_id String CODEC(ZSTD(1)),
    called_number String CODEC(ZSTD(1)),
    
    -- Detection details
    confidence Float32,
    severity UInt8,
    action LowCardinality(String),
    reasons Array(String) CODEC(ZSTD(1)),
    
    -- Raw detection data
    detection_data String CODEC(ZSTD(3)),  -- JSON blob
    
    -- NCC status
    ncc_reported Bool DEFAULT false,
    ncc_report_id String CODEC(ZSTD(1)),
    ncc_report_time Nullable(DateTime64(3)),
    
    region LowCardinality(String),
    node_id String CODEC(ZSTD(1))
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, fraud_type, source_ip)
TTL timestamp + INTERVAL 25 MONTH DELETE
SETTINGS index_granularity = 8192;

-- SIM-box suspect tracking
CREATE TABLE IF NOT EXISTS acm.simbox_suspects (
    cli String,
    first_seen DateTime CODEC(Delta, ZSTD(1)),
    last_seen DateTime CODEC(Delta, ZSTD(1)),
    
    -- Behavioral metrics
    total_calls UInt64,
    unique_destinations UInt32,
    avg_call_duration Float32,
    calls_per_minute Float32,
    max_concurrent UInt16,
    
    -- Time patterns
    night_call_ratio Float32,  -- % calls between 22:00-06:00
    weekend_call_ratio Float32,
    short_call_ratio Float32,  -- % calls < 10 seconds
    
    -- Score
    fraud_score Float32,
    confidence Float32,
    
    -- Status
    is_blocked Bool DEFAULT false,
    blocked_at Nullable(DateTime),
    block_reason String CODEC(ZSTD(1)),
    
    -- Source info
    primary_source_ip IPv4 CODEC(ZSTD(1)),
    source_ips Array(IPv4) CODEC(ZSTD(1)),
    
    region LowCardinality(String),
    updated_at DateTime DEFAULT now()
)
ENGINE = ReplacingMergeTree(updated_at)
ORDER BY (cli)
SETTINGS index_granularity = 8192;

-- ============================================================================
-- GATEWAY ANALYTICS
-- ============================================================================

-- Per-gateway traffic stats (hourly rollup)
CREATE TABLE IF NOT EXISTS acm.gateway_stats_hourly (
    hour DateTime CODEC(Delta, ZSTD(1)),
    gateway_id String CODEC(ZSTD(1)),
    gateway_group UInt8,
    region LowCardinality(String),
    
    -- Traffic
    total_calls UInt64,
    connected_calls UInt64,
    failed_calls UInt64,
    total_minutes Decimal(15, 2),
    
    -- ASR/ACD
    asr Float32,  -- Answer-Seizure Ratio
    acd Float32,  -- Average Call Duration
    
    -- Fraud
    fraud_detected UInt32,
    fraud_blocked UInt32,
    fraud_rate Float32,
    
    -- Fraud type breakdown
    cli_mask_count UInt32,
    simbox_count UInt32,
    refiling_count UInt32,
    
    -- Financial impact
    potential_fraud_amount Decimal(15, 2),
    recovered_amount Decimal(15, 2),
    
    -- Performance
    avg_pdd_ms Float32,
    p95_pdd_ms UInt32
)
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(hour)
ORDER BY (hour, gateway_id, region)
TTL hour + INTERVAL 13 MONTH DELETE
SETTINGS index_granularity = 8192;

-- ============================================================================
-- MNP ANALYTICS
-- ============================================================================

-- MNP lookup stats
CREATE TABLE IF NOT EXISTS acm.mnp_stats_hourly (
    hour DateTime CODEC(Delta, ZSTD(1)),
    region LowCardinality(String),
    
    total_lookups UInt64,
    cache_hits UInt64,
    db_lookups UInt64,
    lookup_errors UInt32,
    
    -- By network
    mtn_lookups UInt32,
    airtel_lookups UInt32,
    glo_lookups UInt32,
    mobile9_lookups UInt32,
    
    -- Ported numbers
    ported_calls UInt64,
    ported_mtn_to_airtel UInt32,
    ported_mtn_to_glo UInt32,
    ported_airtel_to_mtn UInt32,
    ported_airtel_to_glo UInt32,
    ported_glo_to_mtn UInt32,
    ported_glo_to_airtel UInt32,
    
    -- Latency
    avg_lookup_us Float32,
    p99_lookup_us UInt32
)
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(hour)
ORDER BY (hour, region)
TTL hour + INTERVAL 13 MONTH DELETE
SETTINGS index_granularity = 8192;

-- ============================================================================
-- MATERIALIZED VIEWS
-- ============================================================================

-- Real-time fraud dashboard (last 5 minutes)
CREATE MATERIALIZED VIEW IF NOT EXISTS acm.mv_fraud_realtime
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMMDD(window_start)
ORDER BY (window_start, fraud_type, region)
TTL window_start + INTERVAL 7 DAY DELETE
AS SELECT
    toStartOfFiveMinutes(timestamp) AS window_start,
    fraud_type,
    region,
    count() AS event_count,
    uniqExact(source_ip) AS unique_sources,
    uniqExact(caller_id) AS unique_clis,
    avg(confidence) AS avg_confidence,
    max(severity) AS max_severity,
    countIf(ncc_reported = true) AS ncc_reported_count
FROM acm.fraud_events
GROUP BY window_start, fraud_type, region;

-- Hourly CDR summary
CREATE MATERIALIZED VIEW IF NOT EXISTS acm.mv_cdr_hourly
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(hour)
ORDER BY (hour, source_gateway_group, region)
TTL hour + INTERVAL 13 MONTH DELETE
AS SELECT
    toStartOfHour(start_time) AS hour,
    source_gateway_group,
    region,
    
    count() AS total_calls,
    countIf(sip_response_code BETWEEN 200 AND 299) AS successful_calls,
    countIf(duration_seconds > 0) AS connected_calls,
    sum(duration_seconds) AS total_duration_seconds,
    avg(duration_seconds) AS avg_duration,
    
    countIf(fraud_detected = true) AS fraud_calls,
    countIf(penalty_billing = true) AS penalty_calls,
    countIf(mnp_ported = true) AS ported_calls,
    
    avg(detection_latency_us) AS avg_detection_latency,
    quantile(0.99)(detection_latency_us) AS p99_detection_latency
FROM acm.cdrs
GROUP BY hour, source_gateway_group, region;

-- Daily fraud summary
CREATE MATERIALIZED VIEW IF NOT EXISTS acm.mv_fraud_daily
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(day)
ORDER BY (day, fraud_type)
TTL day + INTERVAL 25 MONTH DELETE
AS SELECT
    toDate(timestamp) AS day,
    fraud_type,
    
    count() AS total_events,
    uniqExact(source_ip) AS unique_source_ips,
    uniqExact(caller_id) AS unique_clis,
    uniqExact(source_gateway_id) AS unique_gateways,
    
    avg(confidence) AS avg_confidence,
    countIf(action = 'block') AS blocked_count,
    countIf(action = 'penalty_billing') AS penalty_count,
    countIf(action = 'flag') AS flagged_count,
    countIf(ncc_reported = true) AS reported_to_ncc
FROM acm.fraud_events
GROUP BY day, fraud_type;

-- ============================================================================
-- DICTIONARY FOR LOOKUPS
-- ============================================================================

-- Gateway lookup dictionary
CREATE DICTIONARY IF NOT EXISTS acm.dict_gateways (
    gateway_id String,
    gateway_name String,
    carrier_code String,
    gateway_type String,
    is_active UInt8
)
PRIMARY KEY gateway_id
SOURCE(POSTGRESQL(
    host 'yugabyte'
    port 5433
    user 'opensips'
    password 'CHANGE_ME'
    db 'opensips'
    table 'gateway_profiles'
))
LAYOUT(HASHED())
LIFETIME(MIN 300 MAX 600);

-- MNO reference dictionary
CREATE DICTIONARY IF NOT EXISTS acm.dict_mno (
    network_id String,
    mno_name String,
    mno_code String,
    routing_number String
)
PRIMARY KEY network_id
SOURCE(POSTGRESQL(
    host 'yugabyte'
    port 5433
    user 'opensips'
    password 'CHANGE_ME'
    db 'opensips'
    table 'mno_reference'
))
LAYOUT(HASHED())
LIFETIME(MIN 3600 MAX 7200);

-- ============================================================================
-- USEFUL QUERIES
-- ============================================================================

-- Top fraud sources (last 24 hours)
-- SELECT 
--     source_ip,
--     count() AS fraud_count,
--     uniqExact(caller_id) AS unique_clis,
--     groupArray(10)(fraud_type) AS fraud_types
-- FROM acm.fraud_events
-- WHERE timestamp > now() - INTERVAL 24 HOUR
-- GROUP BY source_ip
-- ORDER BY fraud_count DESC
-- LIMIT 20;

-- Fraud rate by gateway (last hour)
-- SELECT 
--     source_gateway_id,
--     count() AS total_calls,
--     countIf(fraud_detected = true) AS fraud_calls,
--     round(fraud_calls / total_calls * 100, 2) AS fraud_rate_pct
-- FROM acm.cdrs
-- WHERE start_time > now() - INTERVAL 1 HOUR
-- GROUP BY source_gateway_id
-- HAVING total_calls > 100
-- ORDER BY fraud_rate_pct DESC;

-- Detection latency percentiles
-- SELECT 
--     quantile(0.50)(detection_latency_us) AS p50,
--     quantile(0.95)(detection_latency_us) AS p95,
--     quantile(0.99)(detection_latency_us) AS p99,
--     max(detection_latency_us) AS max_latency
-- FROM acm.cdrs
-- WHERE start_time > now() - INTERVAL 1 HOUR;
