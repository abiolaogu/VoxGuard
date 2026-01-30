#!/bin/bash
# ============================================================================
# Nigerian MNO Prefixes Seeding Script
# Seeds the MNP database with Nigerian mobile operator prefixes
# Version: 2.0 | Date: 2026-01-22
# ============================================================================

set -euo pipefail

# Configuration
YUGABYTE_HOST="${YUGABYTE_HOST:-localhost}"
YUGABYTE_PORT="${YUGABYTE_PORT:-5433}"
YUGABYTE_USER="${YUGABYTE_USER:-opensips}"
YUGABYTE_PASSWORD="${YUGABYTE_PASSWORD:-acm_secure_2026}"
YUGABYTE_DB="${YUGABYTE_DB:-opensips}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }

export PGPASSWORD="${YUGABYTE_PASSWORD}"
PSQL="psql -h ${YUGABYTE_HOST} -p ${YUGABYTE_PORT} -U ${YUGABYTE_USER} -d ${YUGABYTE_DB}"

log_info "=============================================="
log_info "Nigerian MNO Prefixes Seeding"
log_info "=============================================="

# MTN Nigeria prefixes (2026)
log_info "Seeding MTN Nigeria prefixes..."
MTN_PREFIXES=(703 706 803 806 810 813 814 816 903 906 913 916)
for PREFIX in "${MTN_PREFIXES[@]}"; do
    ${PSQL} -c "
        INSERT INTO mnp_data (msisdn, original_network_id, hosting_network_id, routing_number)
        SELECT '234${PREFIX}' || generate_series(0000000, 0000099)::text,
               'NG001', 'NG001', 'D013'
        ON CONFLICT (msisdn) DO NOTHING
    " 2>/dev/null || true
done

# Airtel Nigeria prefixes
log_info "Seeding Airtel Nigeria prefixes..."
AIRTEL_PREFIXES=(701 708 802 808 812 901 902 904 907 912)
for PREFIX in "${AIRTEL_PREFIXES[@]}"; do
    ${PSQL} -c "
        INSERT INTO mnp_data (msisdn, original_network_id, hosting_network_id, routing_number)
        SELECT '234${PREFIX}' || generate_series(0000000, 0000099)::text,
               'NG002', 'NG002', 'D018'
        ON CONFLICT (msisdn) DO NOTHING
    " 2>/dev/null || true
done

# Glo Nigeria prefixes
log_info "Seeding Glo Nigeria prefixes..."
GLO_PREFIXES=(705 805 807 811 815 905 915)
for PREFIX in "${GLO_PREFIXES[@]}"; do
    ${PSQL} -c "
        INSERT INTO mnp_data (msisdn, original_network_id, hosting_network_id, routing_number)
        SELECT '234${PREFIX}' || generate_series(0000000, 0000099)::text,
               'NG003', 'NG003', 'D015'
        ON CONFLICT (msisdn) DO NOTHING
    " 2>/dev/null || true
done

# 9mobile Nigeria prefixes
log_info "Seeding 9mobile Nigeria prefixes..."
MOBILE9_PREFIXES=(809 817 818 908 909)
for PREFIX in "${MOBILE9_PREFIXES[@]}"; do
    ${PSQL} -c "
        INSERT INTO mnp_data (msisdn, original_network_id, hosting_network_id, routing_number)
        SELECT '234${PREFIX}' || generate_series(0000000, 0000099)::text,
               'NG004', 'NG004', 'D019'
        ON CONFLICT (msisdn) DO NOTHING
    " 2>/dev/null || true
done

# Seed some sample ported numbers
log_info "Seeding sample ported numbers..."
${PSQL} -c "
    -- MTN to Airtel
    INSERT INTO mnp_data (msisdn, original_network_id, hosting_network_id, routing_number, is_ported, port_date)
    VALUES 
        ('2348031234567', 'NG001', 'NG002', 'D018', true, '2025-06-15'),
        ('2348032234567', 'NG001', 'NG002', 'D018', true, '2025-07-20'),
        ('2348033234567', 'NG001', 'NG003', 'D015', true, '2025-08-10')
    ON CONFLICT (msisdn) DO UPDATE SET
        hosting_network_id = EXCLUDED.hosting_network_id,
        routing_number = EXCLUDED.routing_number;
    
    -- Airtel to MTN
    INSERT INTO mnp_data (msisdn, original_network_id, hosting_network_id, routing_number, is_ported, port_date)
    VALUES 
        ('2348021234567', 'NG002', 'NG001', 'D013', true, '2025-05-01'),
        ('2348022234567', 'NG002', 'NG001', 'D013', true, '2025-09-15')
    ON CONFLICT (msisdn) DO UPDATE SET
        hosting_network_id = EXCLUDED.hosting_network_id,
        routing_number = EXCLUDED.routing_number;
    
    -- Glo to 9mobile
    INSERT INTO mnp_data (msisdn, original_network_id, hosting_network_id, routing_number, is_ported, port_date)
    VALUES 
        ('2348051234567', 'NG003', 'NG004', 'D019', true, '2025-04-22')
    ON CONFLICT (msisdn) DO UPDATE SET
        hosting_network_id = EXCLUDED.hosting_network_id,
        routing_number = EXCLUDED.routing_number;
" 2>/dev/null || true

# Verify
TOTAL=$(${PSQL} -t -c "SELECT COUNT(*) FROM mnp_data")
PORTED=$(${PSQL} -t -c "SELECT COUNT(*) FROM mnp_data WHERE is_ported = true")

log_info "=============================================="
log_info "✅ Nigerian MNO prefixes seeded!"
log_info "Total numbers: ${TOTAL}"
log_info "Ported numbers: ${PORTED}"
log_info "=============================================="

# Also seed to DragonflyDB cache
log_info "Warming up DragonflyDB cache..."
DRAGONFLY_HOST="${DRAGONFLY_HOST:-localhost}"
DRAGONFLY_PORT="${DRAGONFLY_PORT:-6379}"

# Use redis-cli if available
if command -v redis-cli &> /dev/null; then
    # Cache MNO reference data
    redis-cli -h ${DRAGONFLY_HOST} -p ${DRAGONFLY_PORT} SET "mno:NG001" '{"name":"MTN Nigeria","routing_number":"D013"}' EX 86400
    redis-cli -h ${DRAGONFLY_HOST} -p ${DRAGONFLY_PORT} SET "mno:NG002" '{"name":"Airtel Nigeria","routing_number":"D018"}' EX 86400
    redis-cli -h ${DRAGONFLY_HOST} -p ${DRAGONFLY_PORT} SET "mno:NG003" '{"name":"Globacom","routing_number":"D015"}' EX 86400
    redis-cli -h ${DRAGONFLY_HOST} -p ${DRAGONFLY_PORT} SET "mno:NG004" '{"name":"9mobile","routing_number":"D019"}' EX 86400
    log_info "DragonflyDB cache warmed up"
else
    log_warn "redis-cli not found, skipping cache warm-up"
fi

log_info "Done!"
