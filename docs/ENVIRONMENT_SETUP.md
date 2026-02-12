# VoxGuard Environment Setup Guide

This guide walks you through setting up a complete local development environment for the VoxGuard platform. Follow each section in order for a smooth onboarding experience.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Clone and Install](#clone-and-install)
- [Environment Variables](#environment-variables)
- [Database Setup](#database-setup)
- [Backend Services](#backend-services)
- [Frontend](#frontend)
- [Running Tests](#running-tests)
- [Common Issues and Troubleshooting](#common-issues-and-troubleshooting)
- [IDE Setup](#ide-setup)

---

## Prerequisites

Ensure the following tools are installed on your development machine before proceeding.

| Tool       | Minimum Version | Installation                                      |
|------------|-----------------|---------------------------------------------------|
| Node.js    | 20.x+          | [nodejs.org](https://nodejs.org/) or `nvm install 20` |
| Rust       | 1.75+           | [rustup.rs](https://rustup.rs/)                   |
| Go         | 1.22+           | [go.dev/dl](https://go.dev/dl/)                   |
| Python     | 3.11+           | [python.org](https://www.python.org/downloads/)   |
| Docker     | 24.x+          | [docker.com](https://www.docker.com/get-started)  |
| Docker Compose | 2.x+       | Included with Docker Desktop                      |
| pnpm       | 8.x+           | `npm install -g pnpm@8`                           |
| Git        | 2.40+           | [git-scm.com](https://git-scm.com/)              |

### Verify Installations

```bash
node --version       # v20.x.x
rustc --version      # rustc 1.75.x
go version           # go1.22.x
python3 --version    # Python 3.11.x
docker --version     # Docker 24.x.x
docker compose version  # Docker Compose v2.x.x
pnpm --version       # 8.x.x
git --version        # git 2.40.x
```

### Additional Tools (Recommended)

- **Turbo:** Installed as a project dependency; no global install needed
- **cargo-watch:** For Rust hot-reloading during development — `cargo install cargo-watch`
- **air:** For Go hot-reloading during development — `go install github.com/cosmtrek/air@latest`
- **Hasura CLI:** For managing Hasura metadata and migrations — `curl -L https://github.com/hasura/graphql-engine/raw/stable/cli/get.sh | bash`

---

## Clone and Install

### Step 1: Clone the Repository

```bash
git clone git@github.com:<org>/VoxGuard.git
cd VoxGuard
```

### Step 2: Install Node.js Dependencies

VoxGuard uses pnpm workspaces and Turborepo for monorepo management.

```bash
pnpm install
```

This installs dependencies for all packages and services in the monorepo, including `packages/web`.

### Step 3: Verify Turbo

```bash
pnpm turbo --version
```

### Step 4: Install Rust Dependencies

```bash
cd backend/rust
cargo build
cd ../..
```

### Step 5: Install Go Dependencies

```bash
cd backend/go
go mod download
cd ../..
```

### Step 6: Install Python Dependencies

It is strongly recommended to use a virtual environment.

```bash
cd backend/python
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cd ../..
```

---

## Environment Variables

VoxGuard uses environment variables for service configuration. Create a `.env` file in the project root by copying the template:

```bash
cp .env.example .env
```

If `.env.example` does not exist, create `.env` with the following variables:

```env
# =============================================================================
# VoxGuard Environment Configuration
# =============================================================================

# --- Frontend (packages/web) ---
VITE_API_BASE_URL=http://localhost:8080/api/v1
VITE_HASURA_ENDPOINT=http://localhost:8081/v1/graphql
VITE_HASURA_WS_ENDPOINT=ws://localhost:8081/v1/graphql
VITE_APP_TITLE=VoxGuard

# --- Hasura ---
HASURA_ENDPOINT=http://localhost:8081
HASURA_ADMIN_SECRET=voxguard-dev-secret
HASURA_GRAPHQL_ENABLE_CONSOLE=true
HASURA_GRAPHQL_DEV_MODE=true
HASURA_GRAPHQL_LOG_LEVEL=info

# --- Database (YugabyteDB) ---
DATABASE_URL=postgresql://voxguard:voxguard_dev@localhost:5433/voxguard
DATABASE_POOL_SIZE=10
DATABASE_SSL_MODE=disable

# --- DragonflyDB (Redis-compatible cache) ---
DRAGONFLY_URL=redis://localhost:6379
DRAGONFLY_MAX_CONNECTIONS=50

# --- ClickHouse (Analytics) ---
CLICKHOUSE_URL=http://localhost:8123
CLICKHOUSE_DATABASE=voxguard_analytics
CLICKHOUSE_USER=voxguard
CLICKHOUSE_PASSWORD=voxguard_dev

# --- Rust Detection Engine ---
RUST_LOG=info
DETECTION_ENGINE_HOST=0.0.0.0
DETECTION_ENGINE_PORT=8090
DETECTION_ENGINE_WORKERS=4

# --- Go Management API ---
GO_API_HOST=0.0.0.0
GO_API_PORT=8080
GO_API_LOG_LEVEL=info
JWT_SECRET=voxguard-jwt-dev-secret
JWT_EXPIRATION=24h

# --- Python ML Pipeline ---
ML_API_HOST=0.0.0.0
ML_API_PORT=8070
ML_MODEL_PATH=./models
ML_LOG_LEVEL=INFO

# --- Observability ---
PROMETHEUS_PORT=9090
GRAFANA_PORT=3001
GRAFANA_ADMIN_PASSWORD=admin
TEMPO_ENDPOINT=http://localhost:4317
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
```

> **Security Notice:** Never commit `.env` files to version control. The `.gitignore` is configured to exclude them. For production secrets, use a dedicated secrets manager.

---

## Database Setup

VoxGuard uses three database systems. All are configured to run via Docker Compose for local development.

### Start All Databases

From the project root, run:

```bash
docker compose -f database/docker-compose.yml up -d
```

This starts:

| Service       | Purpose                    | Port(s)           |
|---------------|----------------------------|--------------------|
| DragonflyDB   | Caching, rate limiting     | `6379`             |
| ClickHouse    | CDR analytics, reporting   | `8123` (HTTP), `9000` (native) |
| YugabyteDB    | Operational data (SQL)     | `5433` (YSQL), `9042` (YCQL), `7000` (master UI) |
| Hasura        | GraphQL API layer          | `8081`             |

### Docker Compose Configuration

If the Docker Compose file does not exist, create `database/docker-compose.yml`:

```yaml
version: "3.9"

services:
  dragonflydb:
    image: docker.dragonflydb.io/dragonflydb/dragonfly:latest
    container_name: voxguard-dragonfly
    ports:
      - "6379:6379"
    volumes:
      - dragonfly_data:/data
    ulimits:
      memlock: -1
    restart: unless-stopped

  clickhouse:
    image: clickhouse/clickhouse-server:latest
    container_name: voxguard-clickhouse
    ports:
      - "8123:8123"
      - "9000:9000"
    volumes:
      - clickhouse_data:/var/lib/clickhouse
    environment:
      CLICKHOUSE_DB: voxguard_analytics
      CLICKHOUSE_USER: voxguard
      CLICKHOUSE_PASSWORD: voxguard_dev
    restart: unless-stopped

  yugabytedb:
    image: yugabytedb/yugabyte:latest
    container_name: voxguard-yugabyte
    ports:
      - "5433:5433"
      - "9042:9042"
      - "7000:7000"
    command: >
      bin/yugabyted start
      --daemon=false
      --tserver_flags="ysql_enable_auth=false"
    volumes:
      - yugabyte_data:/home/yugabyte/yb_data
    restart: unless-stopped

  hasura:
    image: hasura/graphql-engine:v2.36.0
    container_name: voxguard-hasura
    ports:
      - "8081:8080"
    depends_on:
      - yugabytedb
    environment:
      HASURA_GRAPHQL_DATABASE_URL: postgresql://yugabyte@yugabytedb:5433/voxguard
      HASURA_GRAPHQL_ADMIN_SECRET: voxguard-dev-secret
      HASURA_GRAPHQL_ENABLE_CONSOLE: "true"
      HASURA_GRAPHQL_DEV_MODE: "true"
      HASURA_GRAPHQL_LOG_LEVEL: info
      HASURA_GRAPHQL_ENABLED_APIS: metadata,graphql,pgdump,config
    restart: unless-stopped

volumes:
  dragonfly_data:
  clickhouse_data:
  yugabyte_data:
```

### Verify Databases

```bash
# DragonflyDB
redis-cli -p 6379 ping
# Expected: PONG

# ClickHouse
curl http://localhost:8123/ping
# Expected: Ok.

# YugabyteDB
psql -h localhost -p 5433 -U yugabyte -d voxguard -c "SELECT version();"

# Hasura Console
open http://localhost:8081/console
```

### Apply Hasura Metadata and Migrations

```bash
cd hasura
hasura metadata apply --admin-secret voxguard-dev-secret
hasura migrate apply --all-databases --admin-secret voxguard-dev-secret
hasura metadata reload --admin-secret voxguard-dev-secret
cd ..
```

---

## Backend Services

### Rust Detection Engine

```bash
cd backend/rust

# Build
cargo build

# Run (development mode with hot-reloading)
cargo watch -x run

# Run (without hot-reloading)
cargo run

# The detection engine starts on port 8090 by default.
```

Verify:
```bash
curl http://localhost:8090/health
# Expected: {"status": "healthy"}
```

### Go Management API

```bash
cd backend/go

# Build
go build -o voxguard-api ./cmd/api

# Run (development mode with hot-reloading)
air

# Run (without hot-reloading)
go run ./cmd/api

# The management API starts on port 8080 by default.
```

Verify:
```bash
curl http://localhost:8080/api/v1/health
# Expected: {"status": "healthy"}
```

### Python ML Pipeline

```bash
cd backend/python

# Activate virtual environment
source .venv/bin/activate

# Install dependencies (if not done already)
pip install -r requirements.txt

# Run
python -m uvicorn app.main:app --host 0.0.0.0 --port 8070 --reload

# The ML API starts on port 8070 by default.
```

Verify:
```bash
curl http://localhost:8070/health
# Expected: {"status": "healthy"}
```

---

## Frontend

The frontend is located in `packages/web` and is built with React, Refine, Ant Design, and TypeScript.

### Install and Run

```bash
# From the project root
pnpm --filter web dev
```

Or navigate directly:

```bash
cd packages/web
pnpm dev
```

The development server starts at **http://localhost:5173** by default.

### Build for Production

```bash
pnpm --filter web build
```

### Preview Production Build

```bash
pnpm --filter web preview
```

---

## Running Tests

### All Tests (via Turbo)

```bash
pnpm turbo run test
```

### Rust Tests

```bash
cd backend/rust
cargo test --all
```

With verbose output:
```bash
cargo test --all -- --nocapture
```

### Go Tests

```bash
cd backend/go
go test ./...
```

With verbose output and race detection:
```bash
go test -v -race ./...
```

### Python Tests

```bash
cd backend/python
source .venv/bin/activate
pytest
```

With coverage:
```bash
pytest --cov=app --cov-report=html
```

### Frontend Tests

```bash
pnpm --filter web test
```

### Integration Tests

Integration tests require all services and databases to be running.

```bash
# Start all infrastructure
docker compose -f database/docker-compose.yml up -d

# Run integration tests
pnpm turbo run test:integration
```

---

## Common Issues and Troubleshooting

### Port Conflicts

**Symptom:** A service fails to start with "address already in use."

**Solution:** Check which process is using the port and stop it:
```bash
lsof -i :<port-number>
kill -9 <PID>
```

Common ports: 5173 (frontend), 6379 (DragonflyDB), 8080 (Go API), 8081 (Hasura), 8090 (Rust), 8070 (Python ML), 8123 (ClickHouse), 5433 (YugabyteDB).

### Docker Memory Issues

**Symptom:** Containers crash or fail to start, especially ClickHouse or YugabyteDB.

**Solution:** Increase Docker Desktop memory allocation to at least 8 GB (recommended: 12 GB). Go to Docker Desktop > Settings > Resources > Memory.

### pnpm Install Fails

**Symptom:** `pnpm install` fails with dependency resolution errors.

**Solution:**
```bash
# Clear pnpm store and reinstall
pnpm store prune
rm -rf node_modules
pnpm install
```

### Rust Build Fails

**Symptom:** `cargo build` fails with missing system dependencies.

**Solution (macOS):**
```bash
xcode-select --install
brew install openssl pkg-config
```

**Solution (Linux/Ubuntu):**
```bash
sudo apt-get install build-essential libssl-dev pkg-config
```

### Hasura Console Not Loading

**Symptom:** Hasura console at `localhost:8081/console` shows a blank page or connection error.

**Solution:** Ensure YugabyteDB is healthy before Hasura starts:
```bash
docker compose -f database/docker-compose.yml restart hasura
```

Check Hasura logs:
```bash
docker logs voxguard-hasura
```

### Python Virtual Environment Issues

**Symptom:** `ModuleNotFoundError` when running the ML pipeline.

**Solution:** Ensure the virtual environment is activated:
```bash
source backend/python/.venv/bin/activate
which python  # Should point to .venv/bin/python
pip install -r backend/python/requirements.txt
```

### Hot Reload Not Working

**Symptom:** Changes are not reflected in the running application.

**Solution:**
- **Frontend:** Ensure Vite's HMR is not blocked by a firewall. Try restarting the dev server.
- **Rust:** Ensure `cargo-watch` is installed: `cargo install cargo-watch`
- **Go:** Ensure `air` is installed and `.air.toml` exists in the Go service directory.

### YugabyteDB Connection Refused

**Symptom:** Cannot connect to YugabyteDB on port 5433.

**Solution:** YugabyteDB may take 15-30 seconds to become ready after container start. Wait and retry:
```bash
docker logs voxguard-yugabyte
# Look for "YugabyteDB started successfully"
```

---

## IDE Setup

### Visual Studio Code (Recommended)

Install the following extensions for the best development experience:

#### Required Extensions

| Extension                  | ID                                    | Purpose                                |
|----------------------------|---------------------------------------|----------------------------------------|
| rust-analyzer              | `rust-lang.rust-analyzer`             | Rust language support, IntelliSense    |
| Go                         | `golang.go`                           | Go language support                    |
| Python                     | `ms-python.python`                    | Python language support                |
| Pylance                    | `ms-python.vscode-pylance`            | Python type checking and IntelliSense  |
| ESLint                     | `dbaeumer.vscode-eslint`              | JavaScript/TypeScript linting          |
| Prettier                   | `esbenp.prettier-vscode`              | Code formatting                        |

#### Recommended Extensions

| Extension                  | ID                                    | Purpose                                |
|----------------------------|---------------------------------------|----------------------------------------|
| Docker                     | `ms-azuretools.vscode-docker`         | Docker file support and management     |
| GraphQL                    | `graphql.vscode-graphql`              | GraphQL syntax and IntelliSense        |
| YAML                       | `redhat.vscode-yaml`                  | YAML file support                      |
| Even Better TOML           | `tamasfe.even-better-toml`            | TOML file support (Rust Cargo.toml)    |
| Error Lens                 | `usernamehw.errorlens`                | Inline error highlighting              |
| GitLens                    | `eamodio.gitlens`                     | Advanced Git integration               |
| Thunder Client             | `rangav.vscode-thunder-client`        | API testing (alternative to Postman)   |

#### Workspace Settings

The repository includes a `.vscode/settings.json` with recommended settings. Key configurations:

```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "[rust]": {
    "editor.defaultFormatter": "rust-lang.rust-analyzer",
    "editor.formatOnSave": true
  },
  "[go]": {
    "editor.defaultFormatter": "golang.go",
    "editor.formatOnSave": true
  },
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter",
    "editor.formatOnSave": true
  },
  "eslint.workingDirectories": ["packages/web"],
  "typescript.preferences.importModuleSpecifier": "relative",
  "rust-analyzer.check.command": "clippy"
}
```

### JetBrains IDEs

If you prefer JetBrains IDEs, use:
- **RustRover** or **IntelliJ with Rust plugin** for Rust development
- **GoLand** for Go development
- **PyCharm** for Python development
- **WebStorm** for frontend development

Ensure the following plugins are installed: Prettier, ESLint, and the GraphQL plugin.

---

## Next Steps

Once your environment is set up:

1. Read the [Architecture Documentation](ARCHITECTURE.md) to understand the system design
2. Review the [Contributing Guide](../CONTRIBUTING.md) for workflow and standards
3. Explore the [API Reference](API_REFERENCE.md) for endpoint documentation
4. Check the [AIDD Approval Tiers](AIDD_APPROVAL_TIERS.md) to understand the review process

If you encounter issues not covered in this guide, please open a GitHub Discussion or reach out to the team.
