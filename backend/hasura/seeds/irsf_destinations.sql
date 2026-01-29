-- ============================================================
-- IRSF HIGH-RISK DESTINATIONS SEED DATA
-- Based on CFCA fraud reports and industry data
-- ============================================================

INSERT INTO irsf_destinations (country_code, prefix, country_name, risk_level, fraud_types, is_blacklisted, is_monitored) VALUES
-- CRITICAL RISK (Known IRSF hotspots)
('+960', '960', 'Maldives', 'CRITICAL', ARRAY['IRSF', 'PREMIUM_RATE'], false, true),
('+675', '675', 'Papua New Guinea', 'CRITICAL', ARRAY['IRSF', 'WANGIRI'], false, true),
('+252', '252', 'Somalia', 'CRITICAL', ARRAY['IRSF', 'WANGIRI'], false, true),
('+972', '972599', 'Palestine (Gaza)', 'CRITICAL', ARRAY['IRSF'], false, true),
('+245', '245', 'Guinea-Bissau', 'CRITICAL', ARRAY['IRSF'], false, true),

-- HIGH RISK (Premium/Satellite)
('+881', '881', 'Global Mobile Satellite', 'HIGH', ARRAY['PREMIUM_RATE', 'IRSF'], false, true),
('+882', '882', 'International Networks', 'HIGH', ARRAY['PREMIUM_RATE'], false, true),
('+883', '883', 'International Networks', 'HIGH', ARRAY['PREMIUM_RATE'], false, true),
('+870', '870', 'Inmarsat', 'HIGH', ARRAY['PREMIUM_RATE'], false, true),
('+979', '979', 'International Premium Rate', 'HIGH', ARRAY['PREMIUM_RATE', 'IRSF'], false, true),
('+686', '686', 'Kiribati', 'HIGH', ARRAY['IRSF'], false, true),
('+677', '677', 'Solomon Islands', 'HIGH', ARRAY['IRSF'], false, true),
('+678', '678', 'Vanuatu', 'HIGH', ARRAY['IRSF'], false, true),
('+688', '688', 'Tuvalu', 'HIGH', ARRAY['IRSF'], false, true),
('+682', '682', 'Cook Islands', 'HIGH', ARRAY['IRSF'], false, true),

-- MEDIUM RISK (Monitor closely)
('+53', '53', 'Cuba', 'MEDIUM', ARRAY['IRSF'], false, true),
('+850', '850', 'North Korea', 'MEDIUM', ARRAY['IRSF'], false, true),
('+380', '380900', 'Ukraine (Premium)', 'MEDIUM', ARRAY['PREMIUM_RATE'], false, true),
('+7', '7809', 'Russia (Premium)', 'MEDIUM', ARRAY['PREMIUM_RATE'], false, true),
('+44', '4490', 'UK (Premium Rate)', 'MEDIUM', ARRAY['PREMIUM_RATE'], false, true),
('+1', '1900', 'USA/Canada (Premium)', 'MEDIUM', ARRAY['PREMIUM_RATE'], false, true),

-- Nigerian Context: Premium and Special Numbers
('+234', '234700', 'Nigeria (Premium)', 'MEDIUM', ARRAY['PREMIUM_RATE'], false, true),
('+234', '234800', 'Nigeria (Toll-Free)', 'LOW', ARRAY[], false, true)

ON CONFLICT (country_code, prefix) DO UPDATE SET
    risk_level = EXCLUDED.risk_level,
    fraud_types = EXCLUDED.fraud_types,
    updated_at = NOW();
