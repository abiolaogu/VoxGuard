#!/bin/bash
# ============================================================================
# YugabyteDB Initialization Script
# Sets up the ACM database schema and initial data
# Version: 2.0 | Date: 2026-01-22
# ============================================================================

set -euo pipefail

# Configuration
YUGABYTE_HOST="${YUGABYTE_HOST:-localhost}"
YUGABYTE_PORT="${YUGABYTE_PORT:-5433}"
YUGABYTE_USER="${YUGABYTE_USER:-yugabyte}"
YUGABYTE_PASSWORD="${YUGABYTE_PASSWORD:-yugabyte}"
YUGABYTE_DB="${YUGABYTE_DB:-opensips}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_DIR="${SCRIPT_DIR}/../database/yugabyte"

# Connection string
export PGPASSWORD="${YUGABYTE_PASSWORD}"
PSQL="psql -h ${YUGABYTE_HOST} -p ${YUGABYTE_PORT} -U ${YUGABYTE_USER}"

log_info "=============================================="
log_info "YugabyteDB ACM Schema Initialization"
log_info "=============================================="
log_info "Host: ${YUGABYTE_HOST}:${YUGABYTE_PORT}"
log_info "Database: ${YUGABYTE_DB}"

# Wait for YugabyteDB to be ready
log_info "Waiting for YugabyteDB to be ready..."
MAX_RETRIES=30
RETRY_COUNT=0

while ! ${PSQL} -d yugabyte -c "SELECT 1" > /dev/null 2>&1; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [[ ${RETRY_COUNT} -ge ${MAX_RETRIES} ]]; then
        log_error "YugabyteDB is not ready after ${MAX_RETRIES} attempts"
        exit 1
    fi
    log_warn "Waiting for YugabyteDB... (${RETRY_COUNT}/${MAX_RETRIES})"
    sleep 2
done

log_info "YugabyteDB is ready!"

# Create database if not exists
log_info "Creating database ${YUGABYTE_DB}..."
${PSQL} -d yugabyte -c "CREATE DATABASE ${YUGABYTE_DB}" 2>/dev/null || log_warn "Database already exists"

# Create opensips user if not exists
log_info "Creating opensips user..."
${PSQL} -d yugabyte -c "CREATE USER opensips WITH PASSWORD 'acm_secure_2026'" 2>/dev/null || log_warn "User already exists"
${PSQL} -d yugabyte -c "GRANT ALL PRIVILEGES ON DATABASE ${YUGABYTE_DB} TO opensips" 2>/dev/null || true

# Apply schema
log_info "Applying schema migrations..."
for SCHEMA_FILE in "${SCHEMA_DIR}"/*.sql; do
    if [[ -f "${SCHEMA_FILE}" ]]; then
        FILENAME=$(basename "${SCHEMA_FILE}")
        log_info "Applying: ${FILENAME}"
        ${PSQL} -d ${YUGABYTE_DB} -f "${SCHEMA_FILE}" || {
            log_error "Failed to apply ${FILENAME}"
            exit 1
        }
    fi
done

# Verify tables
log_info "Verifying tables..."
TABLES=$(${PSQL} -d ${YUGABYTE_DB} -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'")
log_info "Created ${TABLES} tables"

# Grant permissions
log_info "Granting permissions to opensips user..."
${PSQL} -d ${YUGABYTE_DB} -c "GRANT ALL ON ALL TABLES IN SCHEMA public TO opensips"
${PSQL} -d ${YUGABYTE_DB} -c "GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO opensips"

log_info "=============================================="
log_info "✅ YugabyteDB initialization complete!"
log_info "=============================================="
