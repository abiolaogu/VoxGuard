-- PostgreSQL initialization script for CDR logs
-- This script runs automatically when the postgres container starts

-- CDR logs table
CREATE TABLE IF NOT EXISTS cdr_logs (
    id SERIAL PRIMARY KEY,
    call_id VARCHAR(255) NOT NULL,
    a_number VARCHAR(50) NOT NULL,
    b_number VARCHAR(50) NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    answer_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    duration_seconds DECIMAL(10, 2) DEFAULT 0,
    state VARCHAR(20) NOT NULL,
    cli VARCHAR(50),
    p_asserted_identity VARCHAR(50),
    has_cli_mismatch BOOLEAN DEFAULT FALSE,
    source_ip VARCHAR(45),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index on b_number for fast lookups
CREATE INDEX IF NOT EXISTS idx_cdr_b_number ON cdr_logs(b_number);

-- Index on start_time for time-range queries
CREATE INDEX IF NOT EXISTS idx_cdr_start_time ON cdr_logs(start_time);

-- Index on call_id for lookups
CREATE INDEX IF NOT EXISTS idx_cdr_call_id ON cdr_logs(call_id);

-- Composite index for masking analysis
CREATE INDEX IF NOT EXISTS idx_cdr_analysis ON cdr_logs(b_number, start_time, has_cli_mismatch);

-- Alerts table
CREATE TABLE IF NOT EXISTS masking_alerts (
    id SERIAL PRIMARY KEY,
    alert_id VARCHAR(255) NOT NULL UNIQUE,
    call_id VARCHAR(255),
    b_number VARCHAR(50) NOT NULL,
    distinct_caller_count INTEGER NOT NULL,
    masking_probability DECIMAL(5, 4) NOT NULL,
    risk_level VARCHAR(20) NOT NULL,
    detection_method VARCHAR(20) NOT NULL,
    features_json JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by VARCHAR(100),
    notes TEXT
);

-- Index on b_number for alert lookups
CREATE INDEX IF NOT EXISTS idx_alerts_b_number ON masking_alerts(b_number);

-- Index on created_at for time-based queries
CREATE INDEX IF NOT EXISTS idx_alerts_created_at ON masking_alerts(created_at);

-- Index on risk_level for filtering
CREATE INDEX IF NOT EXISTS idx_alerts_risk_level ON masking_alerts(risk_level);

-- View for daily CDR summary
CREATE OR REPLACE VIEW daily_cdr_summary AS
SELECT 
    DATE(start_time) as call_date,
    b_number,
    COUNT(*) as total_calls,
    COUNT(CASE WHEN state = 'completed' THEN 1 END) as completed_calls,
    COUNT(CASE WHEN state = 'answered' OR state = 'completed' THEN 1 END) as answered_calls,
    ROUND(AVG(duration_seconds)::numeric, 2) as avg_duration,
    COUNT(CASE WHEN has_cli_mismatch THEN 1 END) as cli_mismatch_count,
    COUNT(DISTINCT a_number) as distinct_callers
FROM cdr_logs
GROUP BY DATE(start_time), b_number;

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO cdr_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO cdr_user;
