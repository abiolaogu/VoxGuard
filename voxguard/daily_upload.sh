#!/bin/bash
# ============================================================================
# NCC Daily CDR Report SFTP Uploader
# Generates and uploads daily fraud/CDR reports to NCC
# Version: 2.0 | Date: 2026-01-22
# ============================================================================

set -euo pipefail

# Configuration
NCC_SFTP_HOST="${NCC_SFTP_HOST:-sftp.ncc.gov.ng}"
NCC_SFTP_PORT="${NCC_SFTP_PORT:-22}"
NCC_SFTP_USER="${NCC_SFTP_USER:-}"
NCC_ICL_LICENSE="${NCC_ICL_LICENSE:-}"
CLICKHOUSE_URL="${CLICKHOUSE_URL:-http://clickhouse:8123}"
REPORT_DIR="/var/acm/reports"
KEY_FILE="/etc/acm/keys/ncc_sftp_key"
LOG_FILE="/var/log/acm/ncc_upload.log"

# Ensure directories exist
mkdir -p "${REPORT_DIR}" "$(dirname ${LOG_FILE})"

# Logging function
log() {
    local level=$1
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] $*" | tee -a "${LOG_FILE}"
}

# Generate report date (yesterday)
REPORT_DATE=$(date -d "yesterday" '+%Y-%m-%d')
REPORT_DATE_SHORT=$(date -d "yesterday" '+%Y%m%d')
ICL_LICENSE_SAFE=$(echo "${NCC_ICL_LICENSE}" | tr '/' '_')
REPORT_FILENAME="CDR_${ICL_LICENSE_SAFE}_${REPORT_DATE_SHORT}.csv.gz"
REPORT_PATH="${REPORT_DIR}/${REPORT_FILENAME}"

log "INFO" "Starting NCC daily report generation for ${REPORT_DATE}"

# Query ClickHouse for CDRs
log "INFO" "Querying ClickHouse for CDRs..."

QUERY="
SELECT
    '${NCC_ICL_LICENSE}' as icl_license,
    call_id,
    formatDateTime(start_time, '%Y-%m-%dT%H:%M:%SZ') as timestamp_wat,
    caller_id as calling_number,
    called_number,
    duration_seconds,
    IPv4NumToString(source_ip) as ingress_ip,
    if(isNull(dest_ip), '', IPv4NumToString(dest_ip)) as egress_ip,
    fraud_detected,
    fraud_type,
    fraud_action as action_taken
FROM acm.cdrs
WHERE toDate(start_time) = '${REPORT_DATE}'
ORDER BY start_time
FORMAT CSVWithNames
"

# Execute query and compress
curl -s "${CLICKHOUSE_URL}" \
    --data-urlencode "query=${QUERY}" \
    | gzip > "${REPORT_PATH}"

# Check if report was generated
if [[ ! -s "${REPORT_PATH}" ]]; then
    log "WARN" "No CDRs found for ${REPORT_DATE}, creating empty report"
    echo "icl_license,call_id,timestamp_wat,calling_number,called_number,duration_seconds,ingress_ip,egress_ip,fraud_detected,fraud_type,action_taken" | gzip > "${REPORT_PATH}"
fi

REPORT_SIZE=$(stat -f%z "${REPORT_PATH}" 2>/dev/null || stat -c%s "${REPORT_PATH}")
log "INFO" "Report generated: ${REPORT_FILENAME} (${REPORT_SIZE} bytes)"

# Generate checksum
sha256sum "${REPORT_PATH}" > "${REPORT_PATH}.sha256"
log "INFO" "Checksum generated: ${REPORT_FILENAME}.sha256"

# Upload to NCC SFTP
if [[ -n "${NCC_SFTP_USER}" ]] && [[ -f "${KEY_FILE}" ]]; then
    log "INFO" "Uploading to NCC SFTP: ${NCC_SFTP_HOST}:${NCC_SFTP_PORT}"
    
    # Create SFTP batch commands
    SFTP_BATCH=$(mktemp)
    cat > "${SFTP_BATCH}" << EOF
cd /incoming/${REPORT_DATE_SHORT:0:6}
put ${REPORT_PATH}
put ${REPORT_PATH}.sha256
bye
EOF

    # Execute SFTP upload
    if sftp -i "${KEY_FILE}" \
            -P "${NCC_SFTP_PORT}" \
            -o StrictHostKeyChecking=no \
            -o BatchMode=yes \
            -b "${SFTP_BATCH}" \
            "${NCC_SFTP_USER}@${NCC_SFTP_HOST}"; then
        log "INFO" "Successfully uploaded report to NCC"
        
        # Record successful upload
        curl -s "${CLICKHOUSE_URL}" --data-urlencode "query=
            INSERT INTO acm.ncc_uploads (report_date, filename, file_size, uploaded_at, status)
            VALUES ('${REPORT_DATE}', '${REPORT_FILENAME}', ${REPORT_SIZE}, now(), 'SUCCESS')
        " || true
    else
        log "ERROR" "Failed to upload report to NCC"
        
        # Record failed upload
        curl -s "${CLICKHOUSE_URL}" --data-urlencode "query=
            INSERT INTO acm.ncc_uploads (report_date, filename, file_size, uploaded_at, status)
            VALUES ('${REPORT_DATE}', '${REPORT_FILENAME}', ${REPORT_SIZE}, now(), 'FAILED')
        " || true
        
        exit 1
    fi
    
    rm -f "${SFTP_BATCH}"
else
    log "WARN" "SFTP credentials not configured, skipping upload"
    log "INFO" "Report saved locally: ${REPORT_PATH}"
fi

# Cleanup old reports (keep 30 days)
log "INFO" "Cleaning up old reports..."
find "${REPORT_DIR}" -name "CDR_*.csv.gz" -mtime +30 -delete 2>/dev/null || true
find "${REPORT_DIR}" -name "CDR_*.sha256" -mtime +30 -delete 2>/dev/null || true

# Generate fraud summary for NCC
log "INFO" "Generating fraud summary..."

FRAUD_SUMMARY=$(curl -s "${CLICKHOUSE_URL}" --data-urlencode "query=
SELECT
    fraud_type,
    count() as count,
    round(avg(confidence), 2) as avg_confidence,
    countIf(action = 'block') as blocked,
    countIf(action = 'penalty_billing') as penalty_billed
FROM acm.fraud_events
WHERE toDate(timestamp) = '${REPORT_DATE}'
GROUP BY fraud_type
FORMAT JSON
")

log "INFO" "Fraud summary for ${REPORT_DATE}:"
echo "${FRAUD_SUMMARY}" | tee -a "${LOG_FILE}"

log "INFO" "NCC daily report process completed"

# Exit successfully
exit 0
