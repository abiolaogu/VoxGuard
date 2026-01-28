# ============================================================================
# NCC SFTP Uploader - Dockerfile
# Daily CDR report generator and uploader
# Version: 2.0 | Date: 2026-01-22
# ============================================================================

FROM alpine:3.19

# Install required packages
RUN apk add --no-cache \
    bash \
    curl \
    openssh-client \
    tzdata \
    coreutils \
    gzip

# Set timezone to WAT (West Africa Time)
ENV TZ=Africa/Lagos

# Create directories
RUN mkdir -p /var/acm/reports /var/log/acm /etc/acm/keys

# Copy upload script
COPY daily_upload.sh /usr/local/bin/daily_upload.sh
RUN chmod +x /usr/local/bin/daily_upload.sh

# Create crontab for daily upload at 01:00 WAT
RUN echo "0 1 * * * /usr/local/bin/daily_upload.sh >> /var/log/acm/cron.log 2>&1" > /etc/crontabs/root

# Health check script
RUN echo '#!/bin/sh' > /usr/local/bin/healthcheck.sh && \
    echo 'test -f /var/log/acm/ncc_upload.log && exit 0 || exit 1' >> /usr/local/bin/healthcheck.sh && \
    chmod +x /usr/local/bin/healthcheck.sh

HEALTHCHECK --interval=60s --timeout=10s --start-period=60s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh

# Run crond in foreground
CMD ["crond", "-f", "-l", "2"]
