#!/bin/bash
# ============================================================================
# Nigerian ICL ACM - Stress Test Runner
# Executes SIPp scenarios against OpenSIPS with ACM detection
# Version: 2.0 | Date: 2026-01-22
# ============================================================================

set -euo pipefail

# Configuration
OPENSIPS_HOST="${OPENSIPS_HOST:-localhost}"
OPENSIPS_PORT="${OPENSIPS_PORT:-5060}"
SCENARIO_FILE="nigerian_icl.xml"
INJECTION_FILE="calls.csv"
REPORT_DIR="./reports"

# Test parameters
CALLS_PER_SECOND="${CALLS_PER_SECOND:-100}"
MAX_CALLS="${MAX_CALLS:-10000}"
CONCURRENT_CALLS="${CONCURRENT_CALLS:-500}"
TEST_DURATION="${TEST_DURATION:-60}"  # seconds

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Create report directory
mkdir -p "${REPORT_DIR}"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
REPORT_PREFIX="${REPORT_DIR}/acm_stress_${TIMESTAMP}"

log_info "=============================================="
log_info "Nigerian ICL Anti-Call Masking Stress Test"
log_info "=============================================="
log_info "Target: ${OPENSIPS_HOST}:${OPENSIPS_PORT}"
log_info "Rate: ${CALLS_PER_SECOND} calls/second"
log_info "Max Calls: ${MAX_CALLS}"
log_info "Concurrent: ${CONCURRENT_CALLS}"
log_info "Duration: ${TEST_DURATION}s"
log_info "=============================================="

# Check if SIPp is installed
if ! command -v sipp &> /dev/null; then
    log_error "SIPp is not installed. Please install it first:"
    echo "  Ubuntu/Debian: apt-get install sipp"
    echo "  macOS: brew install sipp"
    echo "  From source: https://github.com/SIPp/sipp"
    exit 1
fi

# Check if scenario files exist
if [[ ! -f "${SCENARIO_FILE}" ]]; then
    log_error "Scenario file not found: ${SCENARIO_FILE}"
    exit 1
fi

if [[ ! -f "${INJECTION_FILE}" ]]; then
    log_error "Injection file not found: ${INJECTION_FILE}"
    exit 1
fi

# Warm-up test (low rate)
log_info "Running warm-up test (10 cps for 5 seconds)..."
sipp -sf "${SCENARIO_FILE}" \
     -inf "${INJECTION_FILE}" \
     -r 10 \
     -rp 1000 \
     -m 50 \
     -l 50 \
     -trace_stat \
     -trace_err \
     -stf "${REPORT_PREFIX}_warmup_stats.csv" \
     -fd 1 \
     "${OPENSIPS_HOST}:${OPENSIPS_PORT}" \
     2>&1 | tee "${REPORT_PREFIX}_warmup.log" || true

log_info "Warm-up complete. Starting main stress test..."
sleep 2

# Main stress test
log_info "Running main stress test..."
sipp -sf "${SCENARIO_FILE}" \
     -inf "${INJECTION_FILE}" \
     -r "${CALLS_PER_SECOND}" \
     -rp 1000 \
     -m "${MAX_CALLS}" \
     -l "${CONCURRENT_CALLS}" \
     -trace_stat \
     -trace_rtt \
     -trace_err \
     -trace_screen \
     -stf "${REPORT_PREFIX}_stats.csv" \
     -fd 1 \
     -timeout 60s \
     -timeout_error \
     -recv_timeout 5000 \
     -nd \
     "${OPENSIPS_HOST}:${OPENSIPS_PORT}" \
     2>&1 | tee "${REPORT_PREFIX}_main.log"

TEST_EXIT_CODE=$?

# Generate summary
log_info "=============================================="
log_info "Test Complete - Generating Summary"
log_info "=============================================="

if [[ -f "${REPORT_PREFIX}_stats.csv" ]]; then
    # Parse stats file for key metrics
    log_info "Statistics saved to: ${REPORT_PREFIX}_stats.csv"
    
    # Show final stats
    tail -1 "${REPORT_PREFIX}_stats.csv" | while IFS=';' read -r _ _ _ _ _ calls_attempted calls_successful calls_failed _ _ _ _ _ _ _ _ _ _ _ _ response_time_avg _ _ _; do
        log_info "Calls Attempted: ${calls_attempted:-N/A}"
        log_info "Calls Successful: ${calls_successful:-N/A}"
        log_info "Calls Failed: ${calls_failed:-N/A}"
        log_info "Avg Response Time: ${response_time_avg:-N/A}ms"
    done
fi

# Check for errors
if [[ -f "${REPORT_PREFIX}_errors.log" ]]; then
    ERROR_COUNT=$(wc -l < "${REPORT_PREFIX}_errors.log" 2>/dev/null || echo "0")
    if [[ "${ERROR_COUNT}" -gt 0 ]]; then
        log_warn "Errors detected: ${ERROR_COUNT}"
        log_warn "See: ${REPORT_PREFIX}_errors.log"
    fi
fi

# Results
if [[ ${TEST_EXIT_CODE} -eq 0 ]]; then
    log_info "✅ Stress test completed successfully"
else
    log_error "❌ Stress test completed with errors (exit code: ${TEST_EXIT_CODE})"
fi

log_info "Reports saved to: ${REPORT_DIR}/"
log_info "=============================================="

exit ${TEST_EXIT_CODE}
