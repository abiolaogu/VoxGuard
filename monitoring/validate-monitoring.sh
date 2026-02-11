#!/bin/bash
# ============================================================================
# VoxGuard Monitoring Validation Script
# Version: 1.0 | Date: 2026-02-05
# Purpose: Validate monitoring infrastructure configuration and connectivity
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
print_header() {
    echo ""
    echo "========================================="
    echo "$1"
    echo "========================================="
}

print_test() {
    echo -n "Testing: $1... "
    TESTS_RUN=$((TESTS_RUN + 1))
}

print_pass() {
    echo -e "${GREEN}PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

print_fail() {
    echo -e "${RED}FAIL${NC}"
    echo "  Error: $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

print_skip() {
    echo -e "${YELLOW}SKIP${NC} - $1"
}

# ============================================================================
# Configuration File Validation
# ============================================================================
print_header "Configuration File Validation"

# Test Prometheus configuration
print_test "Prometheus configuration file exists"
if [ -f "prometheus/prometheus.yml" ]; then
    print_pass
else
    print_fail "prometheus/prometheus.yml not found"
fi

# Test Prometheus alert rules
print_test "Prometheus alert rules exist"
if [ -d "prometheus/alerts" ] && [ "$(ls -A prometheus/alerts/*.yml 2>/dev/null)" ]; then
    print_pass
else
    print_fail "No alert rules found in prometheus/alerts/"
fi

# Test Tempo configuration
print_test "Tempo configuration file exists"
if [ -f "tempo/tempo.yaml" ]; then
    print_pass
else
    print_fail "tempo/tempo.yaml not found"
fi

# Test AlertManager configuration
print_test "AlertManager configuration file exists"
if [ -f "alertmanager/alertmanager.yml" ]; then
    print_pass
else
    print_fail "alertmanager/alertmanager.yml not found"
fi

# Test Grafana dashboards
print_test "Grafana dashboards exist"
DASHBOARD_COUNT=$(find grafana/dashboards -name "*.json" 2>/dev/null | wc -l)
if [ "$DASHBOARD_COUNT" -ge 3 ]; then
    print_pass
    echo "  Found $DASHBOARD_COUNT dashboards"
else
    print_fail "Expected at least 3 dashboards, found $DASHBOARD_COUNT"
fi

# Test Grafana datasource provisioning
print_test "Grafana datasource provisioning exists"
if [ -f "grafana/provisioning/datasources/datasources.yml" ]; then
    print_pass
else
    print_fail "grafana/provisioning/datasources/datasources.yml not found"
fi

# ============================================================================
# Configuration Syntax Validation
# ============================================================================
print_header "Configuration Syntax Validation"

# Validate Prometheus config with promtool (if available)
print_test "Prometheus configuration syntax"
if command -v promtool &> /dev/null; then
    if promtool check config prometheus/prometheus.yml &> /dev/null; then
        print_pass
    else
        print_fail "Invalid Prometheus configuration"
    fi
else
    print_skip "promtool not installed"
fi

# Validate Prometheus alert rules with promtool (if available)
print_test "Prometheus alert rules syntax"
if command -v promtool &> /dev/null; then
    RULE_ERRORS=0
    for rule_file in prometheus/alerts/*.yml; do
        if [ -f "$rule_file" ]; then
            if ! promtool check rules "$rule_file" &> /dev/null; then
                RULE_ERRORS=$((RULE_ERRORS + 1))
            fi
        fi
    done
    if [ $RULE_ERRORS -eq 0 ]; then
        print_pass
    else
        print_fail "$RULE_ERRORS rule file(s) have syntax errors"
    fi
else
    print_skip "promtool not installed"
fi

# Validate AlertManager config with amtool (if available)
print_test "AlertManager configuration syntax"
if command -v amtool &> /dev/null; then
    if amtool check-config alertmanager/alertmanager.yml &> /dev/null; then
        print_pass
    else
        print_fail "Invalid AlertManager configuration"
    fi
else
    print_skip "amtool not installed"
fi

# Validate Grafana dashboards are valid JSON
print_test "Grafana dashboards JSON syntax"
JSON_ERRORS=0
for dashboard in grafana/dashboards/*.json; do
    if [ -f "$dashboard" ]; then
        if ! python3 -m json.tool "$dashboard" &> /dev/null; then
            JSON_ERRORS=$((JSON_ERRORS + 1))
        fi
    fi
done
if [ $JSON_ERRORS -eq 0 ]; then
    print_pass
else
    print_fail "$JSON_ERRORS dashboard(s) have invalid JSON"
fi

# ============================================================================
# Service Connectivity (Docker-based)
# ============================================================================
print_header "Service Connectivity (requires running services)"

# Test Prometheus connectivity
print_test "Prometheus service health"
if curl -s -f http://localhost:9091/-/healthy &> /dev/null; then
    print_pass
else
    print_skip "Prometheus not running or not accessible"
fi

# Test Prometheus targets
print_test "Prometheus scrape targets"
if TARGETS=$(curl -s http://localhost:9091/api/v1/targets 2>/dev/null); then
    if echo "$TARGETS" | grep -q '"status":"success"'; then
        print_pass
    else
        print_fail "Prometheus targets API returned error"
    fi
else
    print_skip "Prometheus not running or not accessible"
fi

# Test Grafana connectivity
print_test "Grafana service health"
if curl -s -f http://localhost:3003/api/health &> /dev/null; then
    print_pass
else
    print_skip "Grafana not running or not accessible"
fi

# Test Tempo connectivity
print_test "Tempo service ready"
if curl -s -f http://localhost:3200/ready &> /dev/null; then
    print_pass
else
    print_skip "Tempo not running or not accessible"
fi

# Test AlertManager connectivity
print_test "AlertManager service health"
if curl -s -f http://localhost:9093/-/healthy &> /dev/null; then
    print_pass
else
    print_skip "AlertManager not running or not accessible"
fi

# ============================================================================
# Alert Rule Validation
# ============================================================================
print_header "Alert Rule Content Validation"

# Check for critical alert rules
print_test "Critical severity alerts configured"
if grep -r "severity: critical" prometheus/alerts/ &> /dev/null; then
    print_pass
else
    print_fail "No critical severity alerts found"
fi

# Check for NCC compliance alerts
print_test "NCC compliance alerts configured"
if grep -r "NCC" prometheus/alerts/ &> /dev/null; then
    print_pass
else
    print_fail "No NCC compliance alerts found"
fi

# Check for detection engine alerts
print_test "Detection engine alerts configured"
if grep -r "DetectionEngine\|acm-detection-engine" prometheus/alerts/ &> /dev/null; then
    print_pass
else
    print_fail "No detection engine alerts found"
fi

# ============================================================================
# Dashboard Validation
# ============================================================================
print_header "Dashboard Content Validation"

# Check for required dashboards
print_test "Voice Switch dashboard exists"
if [ -f "grafana/dashboards/voice-switch.json" ]; then
    print_pass
else
    print_fail "voice-switch.json not found"
fi

print_test "Detection Engine dashboard exists"
if [ -f "grafana/dashboards/detection-engine.json" ]; then
    print_pass
else
    print_fail "detection-engine.json not found"
fi

print_test "SLA Monitoring dashboard exists"
if [ -f "grafana/dashboards/sla-monitoring.json" ]; then
    print_pass
else
    print_fail "sla-monitoring.json not found"
fi

# ============================================================================
# Summary
# ============================================================================
print_header "Validation Summary"

echo "Tests Run:    $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
else
    echo -e "Tests Failed: ${GREEN}$TESTS_FAILED${NC}"
fi

PASS_RATE=$((TESTS_PASSED * 100 / TESTS_RUN))
echo "Pass Rate:    ${PASS_RATE}%"

echo ""
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All validation tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some validation tests failed. Please review errors above.${NC}"
    exit 1
fi
