//! Property-based tests for domain entities
//!
//! These tests use QuickCheck to generate random inputs and verify invariants.

use acm_detection::domain::value_objects::*;
use acm_detection::domain::aggregates::{Call, FraudAlert};
use acm_detection::domain::aggregates::fraud_alert::AlertStatus;
use quickcheck::TestResult;
use quickcheck_macros::quickcheck;

// === MSISDN Property-Based Tests ===

/// Nigerian numbers should always normalize to +234 format
#[quickcheck]
fn prop_nigerian_msisdn_normalization(local_number: u64) -> TestResult {
    // Generate a valid 10-digit local number
    let local = format!("{:010}", local_number % 10_000_000_000);
    let input = format!("0{}", &local[..10]);

    match MSISDN::new(&input) {
        Ok(msisdn) => {
            TestResult::from_bool(
                msisdn.as_str().starts_with("+234") &&
                msisdn.is_nigerian() &&
                msisdn.country_code() == "234"
            )
        }
        Err(_) => TestResult::discard(),
    }
}

/// Valid MSISDNs should always have correct length (8-16 chars including +)
#[quickcheck]
fn prop_msisdn_length_validation(country_code: u16, number: u64) -> TestResult {
    let cc = country_code % 1000; // Ensure reasonable country code
    let num = format!("{:010}", number % 10_000_000_000);
    let input = format!("+{}{}", cc, num);

    match MSISDN::new(&input) {
        Ok(msisdn) => {
            let len = msisdn.as_str().len();
            TestResult::from_bool(len >= 8 && len <= 16)
        }
        Err(_) => TestResult::passed(), // Invalid inputs are expected to fail
    }
}

/// MSISDN prefix extraction should be consistent
#[quickcheck]
fn prop_msisdn_prefix_consistency(base_number: u64) -> TestResult {
    let num = format!("+234{:010}", base_number % 10_000_000_000);

    match MSISDN::new(&num) {
        Ok(msisdn) => {
            let national = msisdn.national_number();
            let prefix4 = msisdn.prefix(4);
            let prefix7 = msisdn.prefix(7);

            TestResult::from_bool(
                prefix4.len() <= 4 &&
                prefix7.len() <= 7 &&
                national.starts_with(prefix4) &&
                national.starts_with(prefix7)
            )
        }
        Err(_) => TestResult::discard(),
    }
}

/// Empty and invalid formats should always fail
#[test]
fn test_msisdn_invalid_formats() {
    assert!(MSISDN::new("").is_err());
    assert!(MSISDN::new("invalid").is_err());
    assert!(MSISDN::new("123").is_err()); // Too short
    assert!(MSISDN::new("+1234567890123456789").is_err()); // Too long
    assert!(MSISDN::new("234801234567").is_ok()); // Normalized to +234...
    assert!(MSISDN::new("+234abc1234567").is_err()); // Contains letters
}

// === FraudScore Property-Based Tests ===

/// FraudScore should always clamp values to [0.0, 1.0]
#[quickcheck]
fn prop_fraud_score_clamping(value: f64) -> TestResult {
    if !value.is_finite() {
        return TestResult::discard();
    }
    let score = FraudScore::new(value);
    let clamped = score.value();
    TestResult::from_bool(clamped >= 0.0 && clamped <= 1.0)
}

/// FraudScore percentage conversion should be consistent
#[quickcheck]
fn prop_fraud_score_percentage(pct: f64) -> TestResult {
    if !pct.is_finite() {
        return TestResult::discard();
    }

    let score = FraudScore::from_percentage(pct);
    let value = score.value();
    let back_to_pct = score.as_percentage();

    // Allow small floating-point errors
    TestResult::from_bool(
        value >= 0.0 && value <= 1.0 &&
        (back_to_pct - pct.clamp(0.0, 100.0)).abs() < 0.0001
    )
}

/// Severity levels should be monotonic with score
#[test]
fn test_fraud_score_severity_monotonic() {
    let scores = vec![0.0, 0.2, 0.4, 0.6, 0.8, 0.95];
    let severities: Vec<_> = scores.iter()
        .map(|&s| FraudScore::new(s).severity().as_int())
        .collect();

    // Check monotonicity (each severity >= previous)
    for i in 1..severities.len() {
        assert!(severities[i] >= severities[i-1],
            "Severity should increase with score: {:?}", severities);
    }
}

/// Block threshold should be consistent
#[quickcheck]
fn prop_fraud_score_block_threshold(value: f64) -> bool {
    let score = FraudScore::new(value);
    if score.value() >= 0.85 {
        score.exceeds_block_threshold()
    } else {
        !score.exceeds_block_threshold()
    }
}

// === IPAddress Property-Based Tests ===

/// Valid IP addresses should parse correctly
#[quickcheck]
fn prop_ip_address_parsing(a: u8, b: u8, c: u8, d: u8) -> bool {
    let ip_str = format!("{}.{}.{}.{}", a, b, c, d);
    IPAddress::new(&ip_str).is_ok()
}

/// Private IP detection should be consistent
#[test]
fn test_ip_address_private_detection() {
    // RFC 1918 private ranges
    assert!(IPAddress::new("192.168.1.1").unwrap().is_private());
    assert!(IPAddress::new("10.0.0.1").unwrap().is_private());
    assert!(IPAddress::new("172.16.0.1").unwrap().is_private());
    assert!(IPAddress::new("127.0.0.1").unwrap().is_private());

    // Public IPs should not be private
    assert!(!IPAddress::new("8.8.8.8").unwrap().is_private());
    assert!(!IPAddress::new("1.1.1.1").unwrap().is_private());
}

/// IPv6 loopback should be detected as private
#[test]
fn test_ip_address_ipv6_private() {
    assert!(IPAddress::new("::1").unwrap().is_private());
    assert!(IPAddress::new("::ffff:127.0.0.1").unwrap().is_private());
}

// === DetectionWindow Property-Based Tests ===

/// Detection window should enforce bounds [1, 300]
#[quickcheck]
fn prop_detection_window_bounds(seconds: u32) -> TestResult {
    match DetectionWindow::new(seconds) {
        Ok(window) => {
            let s = window.seconds();
            TestResult::from_bool(s >= 1 && s <= 300 && s == seconds)
        }
        Err(_) => {
            // Should fail if out of bounds
            TestResult::from_bool(seconds == 0 || seconds > 300)
        }
    }
}

// === DetectionThreshold Property-Based Tests ===

/// Detection threshold should enforce bounds [1, 100]
#[quickcheck]
fn prop_detection_threshold_bounds(distinct_callers: usize) -> TestResult {
    match DetectionThreshold::new(distinct_callers) {
        Ok(threshold) => {
            let dc = threshold.distinct_callers();
            TestResult::from_bool(dc >= 1 && dc <= 100 && dc == distinct_callers)
        }
        Err(_) => {
            // Should fail if out of bounds
            TestResult::from_bool(distinct_callers == 0 || distinct_callers > 100)
        }
    }
}

// === Call Aggregate Property-Based Tests ===

/// Calls should always start in Ringing status
#[quickcheck]
fn prop_call_initial_state(seed: u64) -> TestResult {
    let a_num = format!("+234{:010}", seed % 10_000_000_000);
    let b_num = format!("+234{:010}", seed.wrapping_add(1) % 10_000_000_000);

    let a_number = match MSISDN::new(&a_num) {
        Ok(n) => n,
        Err(_) => return TestResult::discard(),
    };
    let b_number = match MSISDN::new(&b_num) {
        Ok(n) => n,
        Err(_) => return TestResult::discard(),
    };
    let source_ip = IPAddress::new("192.168.1.1").unwrap();

    let (call, _event) = Call::new(a_number, b_number, source_ip);

    TestResult::from_bool(
        call.status() == CallStatus::Ringing &&
        !call.is_flagged() &&
        call.is_active() &&
        call.fraud_score().value() == 0.0
    )
}

/// Call status transitions should respect state machine
#[test]
fn test_call_state_transitions() {
    let a_number = MSISDN::new("+2348011111111").unwrap();
    let b_number = MSISDN::new("+2348098765432").unwrap();
    let source_ip = IPAddress::new("192.168.1.1").unwrap();

    let (mut call, _) = Call::new(a_number, b_number, source_ip);

    // Valid transitions
    assert!(call.update_status(CallStatus::Active).is_ok());
    assert_eq!(call.status(), CallStatus::Active);

    assert!(call.update_status(CallStatus::Completed).is_ok());
    assert_eq!(call.status(), CallStatus::Completed);

    // Invalid transition from terminal state
    assert!(call.update_status(CallStatus::Active).is_err());
    assert!(call.update_status(CallStatus::Ringing).is_err());
}

/// Calls cannot be flagged twice
#[test]
fn test_call_flag_idempotency() {
    let a_number = MSISDN::new("+2348011111111").unwrap();
    let b_number = MSISDN::new("+2348098765432").unwrap();
    let source_ip = IPAddress::new("192.168.1.1").unwrap();

    let (mut call, _) = Call::new(a_number, b_number, source_ip);

    let score = FraudScore::new(0.95);
    assert!(call.flag_as_fraud("alert-1".into(), score).is_ok());
    assert!(call.is_flagged());

    // Second flag should fail
    assert!(call.flag_as_fraud("alert-2".into(), score).is_err());
}

/// CLI masking detection heuristic
#[test]
fn test_call_cli_masking_detection() {
    let nigerian_num = MSISDN::new("+2348011111111").unwrap();
    let b_number = MSISDN::new("+2348098765432").unwrap();

    // Nigerian number from private IP - not CLI masking
    let private_ip = IPAddress::new("192.168.1.1").unwrap();
    let (call, _) = Call::new(nigerian_num.clone(), b_number.clone(), private_ip);
    assert!(!call.is_potential_cli_masking());

    // Nigerian number from public IP - potential CLI masking
    let public_ip = IPAddress::new("8.8.8.8").unwrap();
    let (call2, _) = Call::new(nigerian_num, b_number, public_ip);
    assert!(call2.is_potential_cli_masking());
}

// === FraudAlert Aggregate Property-Based Tests ===

/// FraudAlerts should always start in Pending status
#[quickcheck]
fn prop_alert_initial_state(seed: u64) -> TestResult {
    let b_num = format!("+234{:010}", seed % 10_000_000_000);
    let b_number = match MSISDN::new(&b_num) {
        Ok(n) => n,
        Err(_) => return TestResult::discard(),
    };

    let now = chrono::Utc::now();
    let window_start = now - chrono::Duration::seconds(5);

    let (alert, _event) = FraudAlert::create(
        b_number,
        FraudType::MaskingAttack,
        FraudScore::new(0.85),
        vec!["+2348011111111".into()],
        vec!["call-1".into()],
        vec!["192.168.1.1".into()],
        window_start,
        now,
    );

    TestResult::from_bool(
        alert.is_pending() &&
        !alert.is_resolved() &&
        !alert.ncc_reported() &&
        alert.distinct_callers() == 1
    )
}

/// Alert workflow state transitions
#[test]
fn test_alert_workflow() {
    let b_number = MSISDN::new("+2348098765432").unwrap();
    let now = chrono::Utc::now();

    let (mut alert, _) = FraudAlert::create(
        b_number,
        FraudType::MaskingAttack,
        FraudScore::new(0.85),
        vec!["+2348011111111".into()],
        vec!["call-1".into()],
        vec!["192.168.1.1".into()],
        now - chrono::Duration::seconds(5),
        now,
    );

    // Pending -> Acknowledged
    assert!(alert.acknowledge("analyst-1").is_ok());
    assert_eq!(alert.status(), AlertStatus::Acknowledged);

    // Cannot acknowledge twice
    assert!(alert.acknowledge("analyst-2").is_err());

    // Acknowledged -> Investigating
    assert!(alert.start_investigation().is_ok());
    assert_eq!(alert.status(), AlertStatus::Investigating);

    // Investigating -> Resolved
    use acm_detection::domain::events::AlertResolution;
    assert!(alert.resolve("analyst-1", AlertResolution::ConfirmedFraud, None).is_ok());
    assert!(alert.is_resolved());

    // Cannot resolve twice
    assert!(alert.resolve("analyst-2", AlertResolution::FalsePositive, None).is_err());
}

/// Auto-block threshold logic
#[test]
fn test_alert_auto_block_logic() {
    let b_number = MSISDN::new("+2348098765432").unwrap();
    let now = chrono::Utc::now();

    // High score (0.95) + Critical severity -> should auto-block
    let (alert1, _) = FraudAlert::create(
        b_number.clone(),
        FraudType::MaskingAttack,
        FraudScore::new(0.95),
        vec!["+2348011111111".into()],
        vec!["call-1".into()],
        vec!["192.168.1.1".into()],
        now - chrono::Duration::seconds(5),
        now,
    );
    assert!(alert1.should_auto_block());
    assert_eq!(alert1.severity(), Severity::Critical);

    // Medium score (0.6) + Medium severity -> should not auto-block
    let (alert2, _) = FraudAlert::create(
        b_number,
        FraudType::MaskingAttack,
        FraudScore::new(0.6),
        vec!["+2348011111111".into()],
        vec!["call-1".into()],
        vec!["192.168.1.1".into()],
        now - chrono::Duration::seconds(5),
        now,
    );
    assert!(!alert2.should_auto_block());
    assert_eq!(alert2.severity(), Severity::Medium);
}

/// Adding calls to escalating alerts
#[quickcheck]
fn prop_alert_add_calls_increases_count(initial_callers: u8) -> TestResult {
    if initial_callers == 0 || initial_callers > 20 {
        return TestResult::discard();
    }

    let b_number = MSISDN::new("+2348098765432").unwrap();
    let now = chrono::Utc::now();

    let a_numbers: Vec<String> = (0..initial_callers)
        .map(|i| format!("+234801{:07}", i))
        .collect();
    let call_ids: Vec<String> = (0..initial_callers)
        .map(|i| format!("call-{}", i))
        .collect();

    let (mut alert, _) = FraudAlert::create(
        b_number,
        FraudType::MaskingAttack,
        FraudScore::new(0.85),
        a_numbers,
        call_ids,
        vec!["192.168.1.1".into()],
        now - chrono::Duration::seconds(5),
        now,
    );

    let original_count = alert.distinct_callers();

    // Add new calls
    alert.add_calls(
        vec!["call-new-1".into(), "call-new-2".into()],
        vec!["+2348099999999".into(), "+2348088888888".into()],
    );

    TestResult::from_bool(alert.distinct_callers() == original_count + 2)
}

// === Edge Cases and Boundary Conditions ===

#[test]
fn test_edge_cases() {
    // Minimum valid MSISDN
    assert!(MSISDN::new("+1234567").is_ok());

    // Maximum valid MSISDN
    assert!(MSISDN::new("+123456789012345").is_ok());

    // Boundary detection window
    assert!(DetectionWindow::new(1).is_ok());
    assert!(DetectionWindow::new(300).is_ok());
    assert!(DetectionWindow::new(0).is_err());
    assert!(DetectionWindow::new(301).is_err());

    // Boundary detection threshold
    assert!(DetectionThreshold::new(1).is_ok());
    assert!(DetectionThreshold::new(100).is_ok());
    assert!(DetectionThreshold::new(0).is_err());
    assert!(DetectionThreshold::new(101).is_err());

    // FraudScore boundaries
    assert_eq!(FraudScore::new(-100.0).value(), 0.0);
    assert_eq!(FraudScore::new(100.0).value(), 1.0);
    assert_eq!(FraudScore::new(f64::NAN).value(), 0.0); // NaN should clamp to 0
    assert_eq!(FraudScore::new(f64::INFINITY).value(), 1.0); // Infinity should clamp to 1
}
