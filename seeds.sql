-- Seed Gateways
INSERT INTO gateways (id, name, type, host, status, latency_ms, success_rate) VALUES
('gw-01', 'MTN-Direct', 'SMPP', '10.0.1.5', 'active', 45, 99.8),
('gw-02', 'Glo-SIP-Pri', 'SIP', '10.0.2.10', 'active', 55, 98.5),
('gw-03', 'Airtel-Fallback', 'HTTP', 'api.airtel.ng', 'inactive', 0, 0)
ON CONFLICT (id) DO NOTHING;

-- Seed Call Verifications
INSERT INTO calls (id, call_id, a_number, b_number, carrier, status, latency_ms, created_at) VALUES
('c-01', 'uid-101', '08031234567', '07039876543', 'MTN', 'verified', 120, NOW() - INTERVAL '2 minutes'),
('c-02', 'uid-102', '08051112223', '08123334445', 'Glo', 'masked', 450, NOW() - INTERVAL '5 minutes'),
('c-03', 'uid-103', '+447911123456', '08098887776', '9mobile', 'suspicious', 800, NOW() - INTERVAL '10 minutes')
ON CONFLICT (id) DO NOTHING;

-- Seed Blacklist
INSERT INTO blacklist (id, number, reason, added_by, source, created_at) VALUES
('bl-01', '+2348000000000', 'Robocall Spam', 'system', 'HONEYPOT', NOW())
ON CONFLICT (id) DO NOTHING;

-- Seed Fraud Alerts (IRSF/Wangiri)
INSERT INTO acm_alerts (id, detection_type, severity, status, data, created_at) VALUES
('a-01', 'IRSF', 'critical', 'active', '{"destination_country": "Maldives", "destination_prefix": "960", "call_count": 450, "estimated_cost": 500000}', NOW()),
('a-02', 'WANGIRI', 'high', 'active', '{"a_number_range": "+881...", "missed_calls": 120, "avg_ring_duration_sec": 1.5, "callbacks_count": 45}', NOW())
ON CONFLICT (id) DO NOTHING;
