# ============================================================================
# Anti-Call Masking Detection Engine - Dockerfile
# Multi-stage build for optimized Rust binary
# Version: 2.0 | Date: 2026-01-22
# ============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Build
# -----------------------------------------------------------------------------
FROM rust:1.75-bookworm AS builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    libpq-dev \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# Copy manifests first for dependency caching
COPY Cargo.toml Cargo.lock ./

# Create dummy main.rs to cache dependencies
RUN mkdir -p src && \
    echo "fn main() {}" > src/main.rs && \
    echo "pub fn lib() {}" > src/lib.rs

# Build dependencies only (cached layer)
RUN cargo build --release && \
    rm -rf src target/release/deps/acm_detection*

# Copy actual source code
COPY src ./src

# Build the actual application
RUN cargo build --release --bin acm-detection-engine

# Verify binary
RUN ls -la target/release/acm-detection-engine

# -----------------------------------------------------------------------------
# Stage 2: Runtime
# -----------------------------------------------------------------------------
FROM debian:bookworm-slim AS runtime

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r acm && useradd -r -g acm acm

# Create directories
RUN mkdir -p /app /var/log/acm /etc/acm && \
    chown -R acm:acm /app /var/log/acm /etc/acm

WORKDIR /app

# Copy binary from builder
COPY --from=builder /build/target/release/acm-detection-engine /app/acm-detection-engine

# Copy any config files if present
COPY --from=builder /build/config* /etc/acm/ 2>/dev/null || true

# Set ownership
RUN chown -R acm:acm /app

# Switch to non-root user
USER acm

# Environment defaults
ENV RUST_LOG=info,acm_detection=debug
ENV RUST_BACKTRACE=0
ENV ACM_HOST=0.0.0.0
ENV ACM_PORT=8080
ENV ACM_METRICS_PORT=9090

# Expose ports
EXPOSE 8080 9090

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Run
ENTRYPOINT ["/app/acm-detection-engine"]
