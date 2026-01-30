#!/bin/bash
# ============================================================================
# ClickHouse Initialization Script
# Sets up the ACM analytics database schema
# Version: 2.0 | Date: 2026-01-22
# ============================================================================

set -euo pipefail

# Configuration
CLICKHOUSE_HOST="${CLICKHOUSE_HOST:-localhost}"
CLICKHOUSE_PORT="${CLICKHOUSE_PORT:-8123}"
CLICKHOUSE_USER="${CLICKHOUSE_USER:-default}"
CLICKHOUSE_PASSWORD="${CLICKHOUSE_PASSWORD:-}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_DIR="${SCRIPT_DIR}/../database/clickhouse"

# ClickHouse client command
CH_CLIENT="clickhouse-client --host ${CLICKHOUSE_HOST} --port 9000"
if [[ -n "${CLICKHOUSE_PASSWORD}" ]]; then
    CH_CLIENT="${CH_CLIENT} --password ${CLICKHOUSE_PASSWORD}"
fi

# For HTTP interface
CH_URL="http://${CLICKHOUSE_HOST}:${CLICKHOUSE_PORT}"

log_info "=============================================="
log_info "ClickHouse ACM Schema Initialization"
log_info "=============================================="
log_info "Host: ${CLICKHOUSE_HOST}:${CLICKHOUSE_PORT}"

# Wait for ClickHouse to be ready
log_info "Waiting for ClickHouse to be ready..."
MAX_RETRIES=30
RETRY_COUNT=0

while ! curl -s "${CH_URL}/ping" > /dev/null 2>&1; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [[ ${RETRY_COUNT} -ge ${MAX_RETRIES} ]]; then
        log_error "ClickHouse is not ready after ${MAX_RETRIES} attempts"
        exit 1
    fi
    log_warn "Waiting for ClickHouse... (${RETRY_COUNT}/${MAX_RETRIES})"
    sleep 2
done

log_info "ClickHouse is ready!"

# Apply schema using HTTP interface
log_info "Applying schema migrations..."
for SCHEMA_FILE in "${SCHEMA_DIR}"/*.sql; do
    if [[ -f "${SCHEMA_FILE}" ]]; then
        FILENAME=$(basename "${SCHEMA_FILE}")
        log_info "Applying: ${FILENAME}"
        
        # Read file and execute each statement
        while IFS= read -r -d ';' STATEMENT || [[ -n "${STATEMENT}" ]]; do
            # Skip empty statements and comments
            CLEAN_STMT=$(echo "${STATEMENT}" | sed '/^--/d' | tr '\n' ' ' | xargs)
            if [[ -n "${CLEAN_STMT}" ]] && [[ ! "${CLEAN_STMT}" =~ ^-- ]]; then
                curl -s "${CH_URL}" \
                    --data-binary "${CLEAN_STMT};" \
                    || log_warn "Statement may have failed: ${CLEAN_STMT:0:50}..."
            fi
        done < "${SCHEMA_FILE}"
    fi
done

# Verify database
log_info "Verifying ACM database..."
TABLES=$(curl -s "${CH_URL}" --data "SELECT count() FROM system.tables WHERE database = 'acm' FORMAT TabSeparated")
log_info "Created ${TABLES} tables in 'acm' database"

# List tables
log_info "Tables in ACM database:"
curl -s "${CH_URL}" --data "SELECT name FROM system.tables WHERE database = 'acm' ORDER BY name FORMAT TabSeparated" | while read -r TABLE; do
    log_info "  - ${TABLE}"
done

# Create additional table for NCC uploads tracking
log_info "Creating NCC uploads tracking table..."
curl -s "${CH_URL}" --data "
CREATE TABLE IF NOT EXISTS acm.ncc_uploads (
    report_date Date,
    filename String,
    file_size UInt64,
    uploaded_at DateTime DEFAULT now(),
    status LowCardinality(String)
)
ENGINE = MergeTree()
ORDER BY (report_date)
TTL uploaded_at + INTERVAL 13 MONTH DELETE
"

log_info "=============================================="
log_info "✅ ClickHouse initialization complete!"
log_info "=============================================="
