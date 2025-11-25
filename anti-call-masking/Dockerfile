# Dockerfile for Anti-Call Masking Detection System
# Multi-stage build for security and size optimization

# ==============================================================================
# Stage 1: Base image with kdb+
# ==============================================================================
FROM debian:bullseye-slim AS base

# Security: Run as non-root user
RUN groupadd -r kdb && useradd -r -g kdb kdb

# Install minimal dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create application directory
WORKDIR /app

# ==============================================================================
# Stage 2: Build/Test stage
# ==============================================================================
FROM base AS builder

# Copy source code
COPY --chown=kdb:kdb src/ /app/src/
COPY --chown=kdb:kdb tests/ /app/tests/
COPY --chown=kdb:kdb scripts/ /app/scripts/

# Create required directories
RUN mkdir -p /app/logs /app/checkpoints /app/archive /app/data \
    && chown -R kdb:kdb /app

# ==============================================================================
# Stage 3: Production image
# ==============================================================================
FROM base AS production

# Labels for container metadata
LABEL maintainer="Anti-Call Masking Team" \
      version="1.0.0" \
      description="Real-time call masking fraud detection using kdb+" \
      org.opencontainers.image.source="https://github.com/abiolaogu/Anti_Call-Masking"

# Security hardening
RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl1.1 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy application from builder
COPY --from=builder --chown=kdb:kdb /app /app

# Create volume mount points
RUN mkdir -p /app/logs /app/checkpoints /app/archive /app/data /opt/kx/lic \
    && chown -R kdb:kdb /app /opt/kx

# Environment variables
ENV QHOME=/opt/kx \
    QLIC=/opt/kx/lic \
    PATH="/opt/kx/l64:${PATH}" \
    KDB_PORT=5012 \
    KDB_SWITCH_HOST=localhost \
    KDB_SWITCH_PORT=8021

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:9090/health || exit 1

# Expose ports
EXPOSE 5012 5013 9090

# Switch to non-root user
USER kdb

# Volumes for persistent data
VOLUME ["/app/logs", "/app/checkpoints", "/app/data", "/opt/kx/lic"]

# Default command
CMD ["q", "src/main.q", "-p", "5012"]
