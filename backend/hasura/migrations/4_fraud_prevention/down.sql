-- ============================================================
-- FRAUD PREVENTION SCHEMA ROLLBACK
-- Migration: 4_fraud_prevention/down.sql
-- ============================================================

-- Drop views first
DROP VIEW IF EXISTS v_fraud_summary;

-- Drop functions
DROP FUNCTION IF EXISTS check_irsf_risk(VARCHAR);
DROP FUNCTION IF EXISTS detect_wangiri_campaign(VARCHAR, INTEGER);

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS callback_fraud_incidents CASCADE;
DROP TABLE IF EXISTS wangiri_campaigns CASCADE;
DROP TABLE IF EXISTS wangiri_incidents CASCADE;
DROP TABLE IF EXISTS premium_rate_calls CASCADE;
DROP TABLE IF EXISTS premium_rate_numbers CASCADE;
DROP TABLE IF EXISTS obr_rate_tables CASCADE;
DROP TABLE IF EXISTS obr_profiles CASCADE;
DROP TABLE IF EXISTS irsf_incidents CASCADE;
DROP TABLE IF EXISTS irsf_destinations CASCADE;
DROP TABLE IF EXISTS spoofing_blacklist CASCADE;
DROP TABLE IF EXISTS cli_verifications CASCADE;
DROP TABLE IF EXISTS fraud_feature_flags CASCADE;
DROP TABLE IF EXISTS fraud_events CASCADE;
