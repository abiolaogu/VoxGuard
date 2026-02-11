#!/bin/bash
# =============================================================================
# VoxGuard Platform Startup Script
# Run all platform services sequentially or in parallel
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$PROJECT_ROOT/infrastructure/docker"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default mode
SEQUENTIAL=false
STOP_MODE=false
STATUS_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --sequential|-s)
            SEQUENTIAL=true
            shift
            ;;
        --stop)
            STOP_MODE=true
            shift
            ;;
        --status)
            STATUS_MODE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --sequential, -s  Start services one by one with health checks"
            echo "  --stop            Stop all services"
            echo "  --status          Show status of all services"
            echo "  --help, -h        Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

wait_for_service() {
    local service=$1
    local url=$2
    local max_attempts=${3:-30}
    local attempt=1

    log_info "Waiting for $service to be ready..."
    while [ $attempt -le $max_attempts ]; do
        if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|302\|301"; then
            log_success "$service is ready!"
            return 0
        fi
        echo -n "."
        sleep 2
        ((attempt++))
    done
    log_warn "$service may not be fully ready (timeout after $max_attempts attempts)"
    return 1
}

wait_for_postgres() {
    local host=$1
    local port=$2
    local max_attempts=${3:-30}
    local attempt=1

    log_info "Waiting for PostgreSQL at $host:$port..."
    while [ $attempt -le $max_attempts ]; do
        if PGPASSWORD=acm_secure_2026 psql -h "$host" -p "$port" -U opensips -d opensips -c "SELECT 1" > /dev/null 2>&1; then
            log_success "PostgreSQL is ready!"
            return 0
        fi
        echo -n "."
        sleep 2
        ((attempt++))
    done
    log_warn "PostgreSQL may not be fully ready"
    return 1
}

show_status() {
    echo ""
    echo "======================================"
    echo "       VoxGuard Platform Status       "
    echo "======================================"
    echo ""

    cd "$DOCKER_DIR"
    docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || docker-compose ps

    echo ""
    echo "Service URLs:"
    echo "  - Frontend:    http://localhost:3000"
    echo "  - Grafana:     http://localhost:3003 (admin/acm_grafana_2026)"
    echo "  - Prometheus:  http://localhost:9091"
    echo "  - QuestDB:     http://localhost:9002"
    echo "  - ClickHouse:  http://localhost:8123/play"
    echo "  - YugabyteDB:  http://localhost:9005"
    echo "  - Homer SIP:   http://localhost:9080"
    echo "  - Hasura:      http://localhost:8082"
    echo ""
}

stop_all() {
    log_info "Stopping all VoxGuard services..."

    # Stop frontend
    pkill -f "vite.*VoxGuard" 2>/dev/null || true
    pkill -f "node.*VoxGuard/packages/web" 2>/dev/null || true

    # Stop metrics server
    pkill -f "metrics-server.py" 2>/dev/null || true

    # Stop docker services
    cd "$DOCKER_DIR"
    docker-compose down

    log_success "All services stopped"
}

start_sequential() {
    log_info "Starting VoxGuard Platform (Sequential Mode)"
    echo "=============================================="
    echo ""

    cd "$DOCKER_DIR"

    # 1. Start DragonflyDB (Redis alternative)
    log_info "1/9 Starting DragonflyDB..."
    docker-compose up -d dragonfly
    sleep 3

    # 2. Start YugabyteDB
    log_info "2/9 Starting YugabyteDB..."
    docker-compose up -d yugabyte
    sleep 5
    wait_for_postgres "localhost" "5433" 60

    # 3. Start ClickHouse
    log_info "3/9 Starting ClickHouse..."
    docker-compose up -d clickhouse
    sleep 3
    wait_for_service "ClickHouse" "http://localhost:8123/ping" 30

    # 4. Start QuestDB
    log_info "4/9 Starting QuestDB..."
    docker-compose up -d questdb
    sleep 3
    wait_for_service "QuestDB" "http://localhost:9002" 30

    # 5. Start Prometheus
    log_info "5/9 Starting Prometheus..."
    docker-compose up -d prometheus
    sleep 2
    wait_for_service "Prometheus" "http://localhost:9091" 30

    # 6. Start Grafana
    log_info "6/9 Starting Grafana..."
    docker-compose up -d grafana
    sleep 3
    wait_for_service "Grafana" "http://localhost:3003" 30

    # 7. Start Homer SIP
    log_info "7/9 Starting Homer SIP Capture..."
    docker-compose up -d homer-postgres homer
    sleep 3
    wait_for_service "Homer" "http://localhost:9080" 30

    # 8. Start Hasura
    log_info "8/9 Starting Hasura GraphQL..."
    docker-compose up -d hasura
    sleep 5
    wait_for_service "Hasura" "http://localhost:8082/healthz" 30

    # 9. Start Frontend
    log_info "9/9 Starting VoxGuard Frontend..."
    cd "$PROJECT_ROOT/packages/web"
    npm run dev > /tmp/voxguard-frontend.log 2>&1 &
    sleep 5
    wait_for_service "Frontend" "http://localhost:3000" 30

    # Start mock metrics server for demo
    log_info "Starting mock metrics server..."
    if [ -f /tmp/metrics-server.py ]; then
        python3 /tmp/metrics-server.py > /tmp/metrics-server.log 2>&1 &
        sleep 2
    fi

    echo ""
    log_success "All VoxGuard services started successfully!"
    show_status
}

start_parallel() {
    log_info "Starting VoxGuard Platform (Parallel Mode)"
    echo "============================================"
    echo ""

    cd "$DOCKER_DIR"

    # Start all docker services
    log_info "Starting Docker services..."
    docker-compose up -d dragonfly yugabyte clickhouse questdb prometheus grafana homer-postgres homer hasura

    # Wait for critical services
    sleep 10
    log_info "Waiting for services to be healthy..."

    # Start frontend
    log_info "Starting VoxGuard Frontend..."
    cd "$PROJECT_ROOT/packages/web"
    npm run dev > /tmp/voxguard-frontend.log 2>&1 &

    # Start mock metrics server
    if [ -f /tmp/metrics-server.py ]; then
        python3 /tmp/metrics-server.py > /tmp/metrics-server.log 2>&1 &
    fi

    sleep 8
    log_success "All VoxGuard services started!"
    show_status
}

# Main execution
if [ "$STATUS_MODE" = true ]; then
    show_status
elif [ "$STOP_MODE" = true ]; then
    stop_all
elif [ "$SEQUENTIAL" = true ]; then
    start_sequential
else
    start_parallel
fi
