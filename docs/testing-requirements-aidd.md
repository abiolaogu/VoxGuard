# VoxGuard Testing Strategy

This document outlines the comprehensive testing strategy for the VoxGuard fraud detection platform, including unit tests, property-based tests, integration tests, contract tests, and coverage requirements.

## Table of Contents

- [Overview](#overview)
- [Testing Philosophy](#testing-philosophy)
- [Test Types](#test-types)
- [Coverage Requirements](#coverage-requirements)
- [Running Tests](#running-tests)
- [CI/CD Integration](#cicd-integration)
- [Writing Tests](#writing-tests)
- [Troubleshooting](#troubleshooting)

## Overview

VoxGuard employs a multi-layered testing strategy to ensure:

- **Correctness**: All domain logic behaves as expected
- **Reliability**: System handles edge cases and errors gracefully
- **Performance**: Detection latency remains <1ms
- **Compatibility**: API contracts remain stable across services

## Testing Philosophy

### Test Pyramid

```
         /\
        /  \  E2E Tests (Few)
       /____\
      /      \
     / Integ  \ Integration Tests (Some)
    /__________\
   /            \
  /   Unit Tests \ Unit Tests (Many)
 /________________\
```

- **Unit Tests (70%)**: Fast, isolated tests for domain entities and value objects
- **Integration Tests (20%)**: Test fraud detection algorithms with realistic data
- **Contract Tests (5%)**: Verify API boundaries between services
- **End-to-End Tests (5%)**: Full system tests (manual/exploratory)

### Key Principles

1. **Fast Feedback**: Unit tests run in <5 seconds, full suite in <2 minutes
2. **Deterministic**: Tests are reproducible and not flaky
3. **Isolated**: No external dependencies (databases, APIs) in unit tests
4. **Readable**: Tests are documentation of system behavior
5. **Coverage**: Minimum 80% code coverage enforced in CI/CD

## Test Types

### 1. Unit Tests

Test individual domain entities, value objects, and algorithms in isolation.

**Location**: `services/detection-engine/src/domain/*/tests`

**Examples**:
- MSISDN validation and normalization
- FraudScore clamping and severity calculation
- Call state machine transitions
- FraudAlert workflow

**Run**:
```bash
cd services/detection-engine
cargo test --lib
```

### 2. Property-Based Tests

Use QuickCheck to generate random inputs and verify invariants hold for all cases.

**Location**: `services/detection-engine/tests/property_based_tests.rs`

**Examples**:
- MSISDN normalization is consistent for all valid inputs
- FraudScore always clamps to [0.0, 1.0]
- DetectionWindow enforces bounds [1, 300]
- Severity levels are monotonic with score

**Run**:
```bash
cd services/detection-engine
cargo test --test property_based_tests
```

**Customize iterations**:
```bash
QUICKCHECK_TESTS=10000 cargo test --test property_based_tests
```

### 3. Integration Tests

Test fraud detection algorithms end-to-end with realistic call data scenarios.

**Location**: `services/detection-engine/tests/integration_fraud_detection.rs`

**Test Scenarios**:

#### CLI Masking Detection
- **Scenario**: International gateway with Nigerian CLI
- **Setup**: 5 calls from different A-numbers, same international IP
- **Expected**: Alert triggered on 5th call
- **Verification**: All calls flagged as fraud

#### SIM-Box Detection
- **Scenario**: Multiple calls from same source IP with different SIM cards
- **Setup**: 5 calls from different Nigerian numbers, same IP
- **Expected**: Alert triggered, single IP detected
- **Verification**: Masking attack identified

#### Sliding Window Algorithm
- **Scenario**: Distinct caller count and expiration
- **Setup**: Multiple calls within 5-second window
- **Expected**: Count increases, cooldown activates
- **Verification**: Window expires after timeout

**Run**:
```bash
cd services/detection-engine
cargo test --test integration_fraud_detection
```

### 4. Contract Tests

Verify API contracts between services to prevent breaking changes.

**Location**: `services/detection-engine/tests/contract_tests.rs`

**Contracts Tested**:
- **SIP Processor → Detection Engine**: Call event format
- **Detection Engine → Management API**: Alert notification format
- **Management API → Detection Engine**: Configuration format

**Validation**:
- Request/response structure
- Required vs optional fields
- Enum values (fraud types, severities)
- Backwards compatibility
- Data type validation (phone numbers, IPs, timestamps)

**Run**:
```bash
cd services/detection-engine
cargo test --test contract_tests
```

**Detect breaking changes**:
```bash
cargo test --test contract_tests test_breaking_change_detection
```

### 5. Performance Tests

Benchmark fraud detection latency and throughput.

**Location**: `services/detection-engine/benches/detection_benchmark.rs`

**Metrics**:
- Call registration latency (target: <1ms)
- Sliding window operations (target: <100µs)
- Alert creation latency (target: <5ms)

**Run**:
```bash
cd services/detection-engine
cargo bench
```

## Coverage Requirements

### Minimum Coverage: 80%

All services must maintain **at least 80% code coverage** to merge to main.

### Coverage by Service

| Service | Language | Tool | Target |
|---------|----------|------|--------|
| Detection Engine | Rust | cargo-tarpaulin | 80% |
| Management API | Go | go test -cover | 80% |
| SIP Processor | Python | pytest-cov | 80% |
| NCC Integration | Python | pytest-cov | 80% |
| ML Pipeline | Python | pytest-cov | 80% |

### Coverage Reports

Coverage reports are generated automatically in CI/CD and uploaded to:
- **Codecov**: https://codecov.io/gh/abiolaogu/VoxGuard
- **GitHub Artifacts**: Available in workflow runs

### View Local Coverage

#### Rust
```bash
cd services/detection-engine
cargo install cargo-tarpaulin
cargo tarpaulin --out Html --output-dir coverage
open coverage/index.html
```

#### Go
```bash
cd services/management-api
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

#### Python
```bash
cd services/sip-processor
pytest --cov=. --cov-report=html
open htmlcov/index.html
```

## Running Tests

### All Tests (Local)

```bash
# Rust detection engine
cd services/detection-engine
cargo test --all-features --verbose

# Go management API
cd services/management-api
go test -v -race ./...

# Python services
cd services/sip-processor
pytest -v tests/

cd services/ncc-integration
pytest -v tests/

cd services/ml-pipeline
pytest -v tests/
```

### Specific Test Suites

```bash
# Unit tests only
cargo test --lib

# Integration tests only
cargo test --test integration_fraud_detection

# Property-based tests only
cargo test --test property_based_tests

# Contract tests only
cargo test --test contract_tests

# Specific test function
cargo test test_cli_masking_detection --verbose
```

### Watch Mode (TDD)

```bash
# Install cargo-watch
cargo install cargo-watch

# Run tests on file changes
cargo watch -x test
```

## CI/CD Integration

### GitHub Actions Workflow

**File**: `.github/workflows/testing-coverage.yml`

**Triggers**:
- Push to `main` or `develop`
- Pull request to `main` or `develop`

**Jobs**:
1. **rust-tests**: Runs all Rust tests with coverage
2. **go-tests**: Runs all Go tests with coverage
3. **python-tests**: Runs all Python tests with coverage (matrix)
4. **property-based-tests**: Runs property-based tests with 10,000 iterations
5. **contract-tests**: Verifies API contracts haven't changed
6. **integration-tests**: Runs fraud detection scenarios
7. **coverage-summary**: Aggregates coverage and enforces 80% gate
8. **test-results**: Summarizes all test results

### Coverage Gate

**Enforcement**:
- Tests fail if coverage < 80% for any service
- PR cannot merge if tests fail
- Coverage trend visible in Codecov dashboard

**Override** (emergency only):
```yaml
# In .github/workflows/testing-coverage.yml
env:
  MINIMUM_COVERAGE: 75  # Temporary reduction
```

## Writing Tests

### Unit Test Template (Rust)

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_valid_input() {
        // Arrange
        let input = "valid_data";

        // Act
        let result = my_function(input);

        // Assert
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), expected_value);
    }

    #[test]
    fn test_invalid_input_fails() {
        let result = my_function("invalid");
        assert!(result.is_err());
    }
}
```

### Property-Based Test Template (Rust)

```rust
use quickcheck_macros::quickcheck;

#[quickcheck]
fn prop_invariant_holds(input: u64) -> bool {
    let result = my_function(input);
    // Verify invariant
    result >= 0 && result <= 100
}
```

### Integration Test Template (Rust)

```rust
#[tokio::test]
async fn test_end_to_end_scenario() {
    // Setup
    let service = create_test_service();

    // Execute scenario
    let result = service.process_request(request).await;

    // Verify
    assert_eq!(result.status, "success");
    assert!(result.data.is_some());
}
```

### Contract Test Template (Rust)

```rust
#[test]
fn test_api_contract() {
    let request = json!({
        "field1": "value1",
        "field2": 123
    });

    let parsed: MyStruct = serde_json::from_value(request).unwrap();
    assert_eq!(parsed.field1, "value1");
}
```

## Troubleshooting

### Tests Timeout

**Symptom**: Tests hang or timeout

**Solutions**:
```bash
# Increase timeout
cargo test -- --test-threads=1 --nocapture

# Run single test
cargo test test_name -- --nocapture
```

### Flaky Tests

**Symptom**: Tests pass/fail intermittently

**Common Causes**:
- Race conditions in async tests
- Time-dependent logic
- Shared mutable state

**Solutions**:
- Use `tokio::time::pause()` for time-dependent tests
- Isolate state in each test
- Use `cargo test -- --test-threads=1` to debug

### Coverage Too Low

**Symptom**: Coverage below 80%

**Solutions**:
1. Identify uncovered code:
   ```bash
   cargo tarpaulin --out Html
   # Open coverage/index.html to see missed lines
   ```

2. Add tests for uncovered branches:
   - Error handling paths
   - Edge cases
   - Enum variants

3. Remove dead code or mark as unreachable:
   ```rust
   #[cfg(not(tarpaulin_include))]
   fn internal_helper() { ... }
   ```

### Property-Based Tests Fail

**Symptom**: QuickCheck finds failing case

**Solutions**:
1. Review the failing input (displayed in output)
2. Add explicit unit test for that case
3. Fix the underlying bug
4. Re-run property test to verify

**Example**:
```
---- prop_msisdn_length_validation stdout ----
thread 'prop_msisdn_length_validation' panicked at
'Property falsifiable with [Args { country_code: 999, number: 123 }]'
```

Add unit test:
```rust
#[test]
fn test_msisdn_edge_case() {
    let result = MSISDN::new("+999123");
    assert!(result.is_err());
}
```

## Best Practices

1. **Test Naming**: Use descriptive names that explain what is being tested
   - ✅ `test_msisdn_normalizes_nigerian_format`
   - ❌ `test_msisdn_1`

2. **AAA Pattern**: Arrange, Act, Assert
   ```rust
   // Arrange
   let input = create_test_data();

   // Act
   let result = function_under_test(input);

   // Assert
   assert_eq!(result, expected);
   ```

3. **One Assertion Per Test**: Tests should verify one behavior
   - Easier to understand failures
   - More precise error messages

4. **Test Pyramid**: Write more unit tests than integration tests
   - Unit tests are faster
   - Integration tests are more brittle

5. **Avoid Test Interdependence**: Each test should be independent
   - No shared mutable state
   - No order dependencies

6. **Use Fixtures**: Extract test data creation to helpers
   ```rust
   fn create_test_call() -> Call {
       // ...
   }
   ```

7. **Test Error Paths**: Don't only test happy path
   - Invalid inputs
   - Network failures
   - Timeout scenarios

## Resources

- [Rust Testing Documentation](https://doc.rust-lang.org/book/ch11-00-testing.html)
- [QuickCheck Guide](https://docs.rs/quickcheck/latest/quickcheck/)
- [Go Testing Best Practices](https://go.dev/doc/tutorial/add-a-test)
- [Pytest Documentation](https://docs.pytest.org/)
- [Codecov Documentation](https://docs.codecov.com/)

## Changelog

### 2026-02-04
- ✅ Added property-based tests for domain entities
- ✅ Created integration tests for fraud detection algorithms
- ✅ Implemented contract tests for service boundaries
- ✅ Established 80% coverage requirement in CI/CD
- ✅ Generated comprehensive testing documentation
