# ============================================================================
# ACM Management API - Dockerfile
# Multi-stage build for Go service
# Version: 2.0 | Date: 2026-01-22
# ============================================================================

# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /build

# Install build dependencies
RUN apk add --no-cache git ca-certificates

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source
COPY . .

# Build
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s -X main.Version=2.0" \
    -o /build/management-api .

# Runtime stage
FROM alpine:3.19

RUN apk add --no-cache ca-certificates tzdata curl

# Create non-root user
RUN addgroup -S acm && adduser -S acm -G acm

WORKDIR /app

# Copy binary
COPY --from=builder /build/management-api /app/management-api

# Set ownership
RUN chown -R acm:acm /app

USER acm

# Environment defaults
ENV PORT=8081
ENV TZ=Africa/Lagos

EXPOSE 8081

HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8081/health || exit 1

ENTRYPOINT ["/app/management-api"]
