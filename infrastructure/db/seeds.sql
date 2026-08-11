-- VoxGuard Seed Data: Gateways (Trunks), Calls, and Fraud Alerts
-- Matches Schema Version 2.0 (acm_ prefix)

-- 1. Insert Trunks (Gateways)
-- Maps to dashboard 'Gateways' view
INSERT INTO acm_trunks (trunk_id, name, trunk_type, host, is_active, health_status, total_calls, avg_acd) VALUES
('LAG-Main-01', 'Lagos Primary Gateway', 'sip', '10.0.1.5', true, 'healthy', 15420, 45.5),
('ABJ-Backup-02', 'Abuja Backup', 'sip', '10.0.2.10', true, 'healthy', 8500, 50.2),
('PHC-Legacy-03', 'Port Harcourt Legacy', 'sip', '10.0.3.15', true, 'degraded', 4200, 21.0),
('KAN-Edge-04', 'Kano Edge', 'sip', '10.0.4.20', false, 'down', 0, 0)
ON CONFLICT (trunk_id) DO NOTHING;

-- 2. Insert Call Records
-- Maps to dashboard 'Call Logs' view
INSERT INTO acm_call_records (call_id, a_number, b_number, ingress_carrier_id, is_flagged, duration_seconds, setup_time) VALUES
('uuid-101', '+2348030001001', '+2347050002001', 'NG-MTN', false, 120, NOW() - INTERVAL '2 minutes'),
('uuid-102', '+2348090001002', '+2348120002002', 'NG-9MOBILE', true, 0, NOW() - INTERVAL '5 minutes'),
('uuid-103', '+2347030001003', '+2349090002003', 'NG-GLO', false, 340, NOW() - INTERVAL '10 minutes'),
('uuid-104', '+2348020001004', '+2348020002004', 'NG-AIRTEL', false, 65, NOW() - INTERVAL '12 minutes'),
('uuid-105', '+2348030001005', '+2347050002005', 'NG-MTN', true, 15, NOW() - INTERVAL '15 minutes')
ON CONFLICT (call_id) DO NOTHING;

-- 3. Insert Fraud Alerts
-- Maps to dashboard 'Fraud Prevention' modules
INSERT INTO acm_alerts (a_number, b_number, detection_type, severity, notes, status, confidence_score, detected_at) VALUES
('+2348090001002', '+2348120002002', 'sim_box', 'critical', 'High-cost destination pattern detected', 'new', 99.5, NOW() - INTERVAL '5 minutes'),
('+2348020001004', '+2348020002004', 'wangiri', 'medium', 'Short duration call flood', 'investigating', 65.0, NOW() - INTERVAL '30 minutes'),
('+2347012345678', '+2347011111111', 'cli_spoofing', 'high', 'Mismatched origin headers', 'resolved', 88.0, NOW() - INTERVAL '1 hour');
