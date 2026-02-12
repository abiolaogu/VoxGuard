# VoxGuard CI/CD Pipeline Documentation

**Version:** 2.1.0
**Date:** February 12, 2026
**Status:** Production Active
**Owner:** VoxGuard Platform Engineering
**Compliance:** AIDD Tiered Approval, NCC ICL Framework 2026

---

## Table of Contents

1. [Pipeline Overview](#pipeline-overview)
2. [Trigger Events](#trigger-events)
3. [Build Stage](#build-stage)
4. [Test Stage](#test-stage)
5. [Security Scanning](#security-scanning)
6. [Quality Gates](#quality-gates)
7. [Deployment Stages](#deployment-stages)
8. [Rollback Procedures](#rollback-procedures)
9. [Environment Promotion](#environment-promotion)
10. [Secrets Management in CI](#secrets-management-in-ci)
11. [AIDD Integration](#aidd-integration)
12. [Monitoring Post-Deploy](#monitoring-post-deploy)
13. [Pipeline Maintenance](#pipeline-maintenance)

---

## Pipeline Overview

VoxGuard uses GitHub Actions as its CI/CD platform, orchestrating builds, tests, security scans, and deployments across a polyglot monorepo containing Rust, Go, Python, and React+TypeScript services. The pipeline enforces AIDD tiered approval for all changes and integrates with the full observability stack (Prometheus, Grafana, Tempo, Loki).

### Pipeline Architecture Diagram

```mermaid
flowchart TD
    subgraph Triggers
        A[Push to main] --> P[Pipeline Start]
        B[Pull Request] --> P
        C[Git Tag v*] --> P
        D[Manual Dispatch] --> P
        E[Scheduled Nightly] --> P
    end

    subgraph "Stage 1: Build"
        P --> B1[Rust: cargo build --release]
        P --> B2[Go: go build]
        P --> B3[Python: pip install]
        P --> B4[Frontend: pnpm build]
        P --> B5[Docker Images]
    end

    subgraph "Stage 2: Test"
        B1 --> T1[Unit Tests]
        B2 --> T1
        B3 --> T1
        B4 --> T1
        T1 --> T2[Integration Tests]
        T2 --> T3[E2E Tests]
        T3 --> T4[Contract Tests]
    end

    subgraph "Stage 3: Security"
        T4 --> S1[SAST Scanning]
        S1 --> S2[Dependency Scanning]
        S2 --> S3[Container Scanning]
        S3 --> S4[DAST Scanning]
    end

    subgraph "Stage 4: Quality Gates"
        S4 --> Q1{Coverage > 80%?}
        Q1 -->|Yes| Q2{No Critical Vulns?}
        Q1 -->|No| FAIL[Pipeline Fails]
        Q2 -->|Yes| Q3{Lint Pass?}
        Q2 -->|No| FAIL
        Q3 -->|Yes| Q4{Build Success?}
        Q3 -->|No| FAIL
        Q4 -->|Yes| PASS[Gates Passed]
        Q4 -->|No| FAIL
    end

    subgraph "Stage 5: Deploy"
        PASS --> DEV[Deploy to Dev]
        DEV --> STAGING[Deploy to Staging]
        STAGING --> PROD[Deploy to Production]
    end

    subgraph "Stage 6: Post-Deploy"
        PROD --> M1[Canary Checks]
        M1 --> M2[Health Endpoints]
        M2 --> M3[Smoke Tests]
        M3 -->|Fail| ROLLBACK[Automated Rollback]
        M3 -->|Pass| DONE[Deployment Complete]
    end
```

### Pipeline Execution Summary

```
┌──────────────────────────────────────────────────────────────────────────┐
│                      VoxGuard CI/CD Pipeline Flow                        │
│                                                                          │
│  Trigger ──> Build ──> Test ──> Security ──> Quality ──> Deploy ──> Mon  │
│   (1 min)   (8 min)  (6 min)   (4 min)     (1 min)    (5 min)   (3 min) │
│                                                                          │
│  Total Pipeline Duration: ~28 minutes (target), ~35 minutes (max)        │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Trigger Events

### Automatic Triggers

| Trigger | Event | Branches | Pipeline Scope |
|---------|-------|----------|---------------|
| **Push to main** | `push` | `main` | Full pipeline + deploy to dev |
| **Pull Request** | `pull_request` | `main`, `develop` | Build + test + security (no deploy) |
| **Release Tag** | `push` tags `v*` | N/A | Full pipeline + deploy to production |
| **Scheduled** | `schedule` | `main` | Nightly security scan + soak tests |

### Manual Triggers

| Trigger | Use Case | Required Parameters |
|---------|----------|-------------------|
| **workflow_dispatch** | Hotfix deployment | `environment`, `version`, `skip_tests` (boolean) |
| **repository_dispatch** | External system trigger | `event_type`, `client_payload` |

### Path-Based Filtering

```yaml
# Detection Engine (Rust) - only runs when Rust source changes
on:
  push:
    paths:
      - 'services/detection-engine/**'
      - 'Cargo.toml'
      - 'Cargo.lock'

# Management API (Go) - only runs when Go source changes
on:
  push:
    paths:
      - 'services/management-api/**'
      - 'go.mod'
      - 'go.sum'

# Processing Service (Python) - only runs when Python source changes
on:
  push:
    paths:
      - 'services/processing-service/**'
      - 'requirements*.txt'

# Frontend (React+TypeScript) - only runs when frontend source changes
on:
  push:
    paths:
      - 'packages/web/**'
      - 'pnpm-lock.yaml'
```

### Concurrency Control

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true  # Cancel stale runs on same branch
```

---

## Build Stage

### Rust Detection Engine

```yaml
build-rust:
  name: Build Detection Engine
  runs-on: ubuntu-latest
  container:
    image: rust:1.77-slim-bookworm
  steps:
    - uses: actions/checkout@v4

    - name: Cache cargo registry and build artifacts
      uses: actions/cache@v4
      with:
        path: |
          ~/.cargo/registry
          ~/.cargo/git
          target
        key: rust-${{ hashFiles('**/Cargo.lock') }}
        restore-keys: rust-

    - name: Build release binary
      run: |
        cd services/detection-engine
        cargo build --release --target x86_64-unknown-linux-gnu
      env:
        RUSTFLAGS: "-C target-cpu=native -C link-arg=-s"

    - name: Verify binary
      run: |
        ls -la target/release/detection-engine
        file target/release/detection-engine

    - name: Upload artifact
      uses: actions/upload-artifact@v4
      with:
        name: detection-engine-binary
        path: target/release/detection-engine
        retention-days: 7
```

**Build Optimizations:**
- Incremental compilation with cached `target/` directory
- `sccache` for distributed compilation caching
- Release profile with LTO (Link-Time Optimization) and `codegen-units = 1`
- Stripped debug symbols for smaller binary (~12MB)

### Go Management API

```yaml
build-go:
  name: Build Management API
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4

    - name: Setup Go
      uses: actions/setup-go@v5
      with:
        go-version: '1.22'
        cache: true

    - name: Download dependencies
      run: |
        cd services/management-api
        go mod download
        go mod verify

    - name: Build binary
      run: |
        cd services/management-api
        CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
        go build -ldflags="-s -w -X main.version=${{ github.ref_name }} -X main.commit=${{ github.sha }}" \
        -o management-api ./cmd/server

    - name: Upload artifact
      uses: actions/upload-artifact@v4
      with:
        name: management-api-binary
        path: services/management-api/management-api
        retention-days: 7
```

**Build Optimizations:**
- Static binary with `CGO_ENABLED=0` for Alpine compatibility
- Version and commit hash embedded via `-ldflags`
- Go module cache persisted across runs

### Python Processing Service

```yaml
build-python:
  name: Build Processing Service
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4

    - name: Setup Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.12'
        cache: 'pip'

    - name: Install dependencies
      run: |
        cd services/processing-service
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        pip install -r requirements-dev.txt

    - name: Validate imports
      run: |
        cd services/processing-service
        python -c "import voxguard; print(f'VoxGuard Processing v{voxguard.__version__}')"

    - name: Build wheel
      run: |
        cd services/processing-service
        pip install build
        python -m build --wheel --outdir dist/
```

### Frontend (React + TypeScript + Vite)

```yaml
build-frontend:
  name: Build Frontend
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4

    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '20'

    - name: Setup pnpm
      uses: pnpm/action-setup@v4
      with:
        version: 9

    - name: Install dependencies
      run: |
        cd packages/web
        pnpm install --frozen-lockfile

    - name: Type check
      run: |
        cd packages/web
        pnpm run typecheck

    - name: Build production bundle
      run: |
        cd packages/web
        pnpm build
      env:
        VITE_API_URL: ${{ vars.API_URL }}
        VITE_HASURA_ENDPOINT: ${{ vars.HASURA_ENDPOINT }}
        VITE_APP_VERSION: ${{ github.ref_name }}

    - name: Upload build artifacts
      uses: actions/upload-artifact@v4
      with:
        name: frontend-dist
        path: packages/web/dist
        retention-days: 7
```

**Build Optimizations:**
- `pnpm` for deterministic installs and disk-efficient node_modules
- `--frozen-lockfile` to prevent lockfile drift
- Vite code splitting, tree shaking, and chunk optimization
- Asset hashing for long-term CDN caching

### Docker Image Build

```yaml
build-docker:
  name: Build Docker Images
  needs: [build-rust, build-go, build-python, build-frontend]
  runs-on: ubuntu-latest
  strategy:
    matrix:
      service:
        - { name: detection-engine, context: services/detection-engine, dockerfile: Dockerfile }
        - { name: management-api, context: services/management-api, dockerfile: Dockerfile }
        - { name: processing-service, context: services/processing-service, dockerfile: Dockerfile }
        - { name: web, context: packages/web, dockerfile: Dockerfile }
  steps:
    - uses: actions/checkout@v4

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3

    - name: Login to Container Registry
      uses: docker/login-action@v3
      with:
        registry: ghcr.io
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}

    - name: Build and push
      uses: docker/build-push-action@v5
      with:
        context: ${{ matrix.service.context }}
        file: ${{ matrix.service.context }}/${{ matrix.service.dockerfile }}
        push: ${{ github.event_name != 'pull_request' }}
        tags: |
          ghcr.io/voxguard/${{ matrix.service.name }}:${{ github.sha }}
          ghcr.io/voxguard/${{ matrix.service.name }}:latest
        cache-from: type=gha
        cache-to: type=gha,mode=max
        build-args: |
          VERSION=${{ github.ref_name }}
          COMMIT=${{ github.sha }}
```

---

## Test Stage

### Unit Tests

Tests run in parallel across all service languages:

```yaml
test-unit:
  name: Unit Tests
  runs-on: ubuntu-latest
  strategy:
    fail-fast: false
    matrix:
      include:
        - service: detection-engine
          lang: rust
          cmd: "cargo test --lib --release -- --test-threads=4"
          coverage: "cargo tarpaulin --out xml --output-dir coverage/"
        - service: management-api
          lang: go
          cmd: "go test ./... -count=1 -race -short"
          coverage: "go test ./... -coverprofile=coverage.out -covermode=atomic"
        - service: processing-service
          lang: python
          cmd: "pytest tests/unit/ -v --tb=short"
          coverage: "pytest tests/unit/ --cov=voxguard --cov-report=xml"
        - service: web
          lang: typescript
          cmd: "pnpm run test --run"
          coverage: "pnpm run test --run --coverage"
```

**Coverage Targets:**

| Service | Language | Min Coverage | Current Coverage |
|---------|----------|-------------|-----------------|
| Detection Engine | Rust | 85% | 91% |
| Management API | Go | 80% | 84% |
| Processing Service | Python | 80% | 87% |
| Frontend | TypeScript | 75% | 79% |
| **Overall** | **All** | **80%** | **85%** |

### Integration Tests

```yaml
test-integration:
  name: Integration Tests
  needs: test-unit
  runs-on: ubuntu-latest
  services:
    yugabytedb:
      image: yugabytedb/yugabyte:2.20-latest
      ports: ['5433:5433']
    dragonfly:
      image: docker.dragonflydb.io/dragonflydb/dragonfly:latest
      ports: ['6379:6379']
    clickhouse:
      image: clickhouse/clickhouse-server:24-alpine
      ports: ['8123:8123', '9000:9000']
  steps:
    - uses: actions/checkout@v4

    - name: Wait for services
      run: |
        ./scripts/wait-for-services.sh yugabytedb:5433 dragonfly:6379 clickhouse:8123

    - name: Run database migrations
      run: |
        ./scripts/init-yugabyte.sh
        ./scripts/init-clickhouse.sh

    - name: Run integration tests
      run: |
        # Rust integration tests
        cd services/detection-engine
        cargo test --test integration_tests -- --test-threads=1

        # Go integration tests
        cd ../management-api
        go test ./tests/integration/... -v -count=1

        # Python integration tests
        cd ../processing-service
        pytest tests/integration/ -v --tb=long
      env:
        YUGABYTE_URL: "postgres://yugabyte:yugabyte@localhost:5433/voxguard_test"
        DRAGONFLY_URL: "redis://localhost:6379"
        CLICKHOUSE_URL: "http://localhost:8123"
```

### End-to-End Tests

```yaml
test-e2e:
  name: E2E Tests
  needs: test-integration
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4

    - name: Start full stack
      run: |
        docker-compose -f deployment/docker/docker-compose.yml \
          -f deployment/docker/docker-compose.test.yml up -d
        ./scripts/wait-for-services.sh localhost:8080 localhost:8081 localhost:5173

    - name: Run E2E tests
      run: |
        cd packages/web
        pnpm exec playwright install --with-deps
        pnpm run test:e2e
      env:
        BASE_URL: "http://localhost:5173"
        API_URL: "http://localhost:8081"

    - name: Run API E2E tests
      run: |
        cd tests/e2e
        ./run-api-e2e.sh

    - name: Upload test artifacts
      if: failure()
      uses: actions/upload-artifact@v4
      with:
        name: e2e-results
        path: |
          packages/web/test-results/
          packages/web/playwright-report/
```

### Contract Tests

```yaml
test-contract:
  name: Contract Tests (Pact)
  needs: test-unit
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4

    - name: Run consumer contract tests
      run: |
        cd packages/web
        pnpm run test:contract

    - name: Run provider contract verification
      run: |
        cd services/management-api
        go test ./tests/contract/... -v

    - name: Publish pacts to broker
      if: github.ref == 'refs/heads/main'
      run: |
        pact-broker publish pacts/ \
          --consumer-app-version=${{ github.sha }} \
          --broker-base-url=${{ secrets.PACT_BROKER_URL }}
```

---

## Security Scanning

### SAST (Static Application Security Testing)

```yaml
security-sast:
  name: SAST Scanning
  runs-on: ubuntu-latest
  strategy:
    fail-fast: false
    matrix:
      include:
        - name: Rust Audit
          cmd: |
            cargo install cargo-audit
            cd services/detection-engine
            cargo audit --json > ../../reports/rust-audit.json
        - name: Go Security
          cmd: |
            go install github.com/securego/gosec/v2/cmd/gosec@latest
            cd services/management-api
            gosec -fmt=json -out=../../reports/gosec.json ./...
        - name: Python Bandit
          cmd: |
            pip install bandit[toml]
            cd services/processing-service
            bandit -r voxguard/ -f json -o ../../reports/bandit.json
        - name: ESLint Security
          cmd: |
            cd packages/web
            pnpm run lint:security --format json -o ../../reports/eslint-security.json
  steps:
    - uses: actions/checkout@v4
    - name: Run ${{ matrix.name }}
      run: ${{ matrix.cmd }}
    - name: Upload SAST reports
      uses: actions/upload-artifact@v4
      with:
        name: sast-${{ matrix.name }}
        path: reports/
```

**SAST Tool Coverage:**

| Language | Tool | Checks | Severity Levels |
|----------|------|--------|----------------|
| Rust | `cargo-audit` | CVE database, unsafe code, dependency vulns | Critical, High, Medium, Low |
| Rust | `cargo-clippy` | Code correctness, performance, style | Deny, Warn, Allow |
| Go | `gosec` | SQL injection, hardcoded creds, crypto misuse | High, Medium, Low |
| Go | `staticcheck` | Bug detection, simplification, unused code | Error, Warning |
| Python | `bandit` | Injection, XSS, hardcoded passwords, crypto | Critical, High, Medium, Low |
| Python | `safety` | Known vulnerability database | Critical, High, Medium, Low |
| TypeScript | `eslint-plugin-security` | Prototype pollution, eval, regex DoS | Error, Warning |
| TypeScript | `eslint-plugin-no-secrets` | Hardcoded secrets detection | Error |

### Dependency Scanning

```yaml
security-dependencies:
  name: Dependency Scanning
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4

    - name: Rust dependency scan
      run: |
        cargo install cargo-deny
        cd services/detection-engine
        cargo deny check advisories licenses sources

    - name: Go dependency scan
      run: |
        cd services/management-api
        go install golang.org/x/vuln/cmd/govulncheck@latest
        govulncheck ./...

    - name: Python dependency scan
      run: |
        pip install safety pip-audit
        cd services/processing-service
        safety check -r requirements.txt --json > ../../reports/safety.json
        pip-audit -r requirements.txt --format json > ../../reports/pip-audit.json

    - name: Frontend dependency scan
      run: |
        cd packages/web
        pnpm audit --json > ../../reports/pnpm-audit.json

    - name: SBOM generation
      run: |
        syft . -o spdx-json > reports/sbom.spdx.json
```

### Container Scanning

```yaml
security-container:
  name: Container Scanning
  needs: build-docker
  runs-on: ubuntu-latest
  strategy:
    matrix:
      image:
        - detection-engine
        - management-api
        - processing-service
        - web
  steps:
    - name: Run Trivy scan
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: "ghcr.io/voxguard/${{ matrix.image }}:${{ github.sha }}"
        format: 'sarif'
        output: 'trivy-${{ matrix.image }}.sarif'
        severity: 'CRITICAL,HIGH'

    - name: Upload scan results to GitHub Security
      uses: github/codeql-action/upload-sarif@v3
      with:
        sarif_file: 'trivy-${{ matrix.image }}.sarif'
```

### DAST (Dynamic Application Security Testing)

```yaml
security-dast:
  name: DAST Scanning
  needs: [test-integration]
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4

    - name: Start application stack
      run: |
        docker-compose -f deployment/docker/docker-compose.yml up -d
        ./scripts/wait-for-services.sh localhost:8080 localhost:8081

    - name: Run OWASP ZAP scan
      uses: zaproxy/action-full-scan@v0.10.0
      with:
        target: 'http://localhost:8081'
        rules_file_name: '.zap/rules.tsv'
        cmd_options: '-a'

    - name: Run Nuclei scan
      run: |
        nuclei -u http://localhost:8081 -t cves/ -t exposures/ \
          -severity critical,high -json -o reports/nuclei.json
```

---

## Quality Gates

All quality gates must pass before deployment proceeds. Any failure blocks the pipeline.

```mermaid
flowchart LR
    subgraph "Quality Gate Checks"
        QG1[Test Coverage >= 80%]
        QG2[Zero Critical Vulnerabilities]
        QG3[Lint Pass - All Languages]
        QG4[Build Success - All Services]
        QG5[No Regression in Benchmarks]
        QG6[Container Scan Pass]
        QG7[License Compliance]
    end

    QG1 --> MERGE{All Passed?}
    QG2 --> MERGE
    QG3 --> MERGE
    QG4 --> MERGE
    QG5 --> MERGE
    QG6 --> MERGE
    QG7 --> MERGE

    MERGE -->|Yes| DEPLOY[Proceed to Deploy]
    MERGE -->|No| BLOCK[Block Merge/Deploy]
```

### Gate Definitions

| Gate | Threshold | Enforcement | Bypass |
|------|-----------|-------------|--------|
| **Test Coverage** | >= 80% overall, >= 75% per service | Required status check | None |
| **Critical Vulnerabilities** | 0 critical, 0 high (new) | Required status check | Security team override |
| **Lint Pass** | Zero errors (warnings allowed) | Required status check | None |
| **Build Success** | All services compile | Required status check | None |
| **Performance Regression** | < 5% degradation from baseline | Advisory (non-blocking) | Auto-approved |
| **Container Scan** | No critical CVEs in base images | Required status check | Security team override |
| **License Compliance** | No GPL/AGPL in production deps | Required status check | Legal team override |

### Gate Implementation

```yaml
quality-gates:
  name: Quality Gates
  needs: [test-unit, test-integration, security-sast, security-dependencies, security-container]
  runs-on: ubuntu-latest
  steps:
    - name: Check coverage threshold
      run: |
        COVERAGE=$(cat reports/coverage-summary.json | jq '.total.lines.pct')
        if (( $(echo "$COVERAGE < 80" | bc -l) )); then
          echo "::error::Coverage $COVERAGE% is below 80% threshold"
          exit 1
        fi
        echo "Coverage: $COVERAGE% - PASSED"

    - name: Check critical vulnerabilities
      run: |
        CRITICAL=$(cat reports/vuln-summary.json | jq '.critical')
        if [ "$CRITICAL" -gt 0 ]; then
          echo "::error::Found $CRITICAL critical vulnerabilities"
          exit 1
        fi
        echo "Zero critical vulnerabilities - PASSED"

    - name: Check lint results
      run: |
        if [ -f reports/lint-errors.json ]; then
          ERRORS=$(cat reports/lint-errors.json | jq '.errorCount')
          if [ "$ERRORS" -gt 0 ]; then
            echo "::error::Found $ERRORS lint errors"
            exit 1
          fi
        fi
        echo "Lint clean - PASSED"

    - name: Summary
      run: |
        echo "## Quality Gate Results" >> $GITHUB_STEP_SUMMARY
        echo "| Gate | Status |" >> $GITHUB_STEP_SUMMARY
        echo "|------|--------|" >> $GITHUB_STEP_SUMMARY
        echo "| Coverage | PASSED |" >> $GITHUB_STEP_SUMMARY
        echo "| Vulnerabilities | PASSED |" >> $GITHUB_STEP_SUMMARY
        echo "| Lint | PASSED |" >> $GITHUB_STEP_SUMMARY
        echo "| Build | PASSED |" >> $GITHUB_STEP_SUMMARY
```

---

## Deployment Stages

### Environment Topology

```mermaid
flowchart LR
    subgraph "Development"
        DEV_K8S[K8s Cluster - Dev]
        DEV_DB[(Dev Databases)]
    end

    subgraph "Staging"
        STG_K8S[K8s Cluster - Staging]
        STG_DB[(Staging Databases)]
    end

    subgraph "Production"
        subgraph "Lagos Primary"
            PROD_K8S_LAG[K8s Cluster - Lagos]
            PROD_DB_LAG[(Primary Databases)]
        end
        subgraph "Abuja Replica"
            PROD_K8S_ABJ[K8s Cluster - Abuja]
            PROD_DB_ABJ[(Replica Databases)]
        end
        subgraph "Asaba DR"
            PROD_K8S_ASB[K8s Cluster - Asaba]
            PROD_DB_ASB[(DR Databases)]
        end
    end

    DEV_K8S -->|Promote| STG_K8S
    STG_K8S -->|Promote| PROD_K8S_LAG
    PROD_K8S_LAG -.->|Replicate| PROD_K8S_ABJ
    PROD_K8S_LAG -.->|Replicate| PROD_K8S_ASB
```

### Dev Deployment (Automatic)

```yaml
deploy-dev:
  name: Deploy to Development
  needs: quality-gates
  if: github.ref == 'refs/heads/main'
  runs-on: ubuntu-latest
  environment:
    name: development
    url: https://dev.voxguard.ng
  steps:
    - uses: actions/checkout@v4

    - name: Setup Helm
      uses: azure/setup-helm@v4
      with:
        version: v3.14.0

    - name: Configure kubeconfig
      run: |
        echo "${{ secrets.DEV_KUBECONFIG }}" | base64 -d > kubeconfig
        export KUBECONFIG=kubeconfig

    - name: Deploy with Helm
      run: |
        helm upgrade --install voxguard ./deployment/helm/voxguard \
          --namespace voxguard-dev \
          --create-namespace \
          --set global.image.tag=${{ github.sha }} \
          --set global.environment=development \
          --values deployment/helm/values-dev.yaml \
          --wait --timeout 10m

    - name: Verify deployment
      run: |
        kubectl rollout status deployment/detection-engine -n voxguard-dev --timeout=300s
        kubectl rollout status deployment/management-api -n voxguard-dev --timeout=300s
        kubectl rollout status deployment/processing-service -n voxguard-dev --timeout=300s
        kubectl rollout status deployment/web -n voxguard-dev --timeout=300s
```

### Staging Deployment (Manual Approval)

```yaml
deploy-staging:
  name: Deploy to Staging
  needs: deploy-dev
  runs-on: ubuntu-latest
  environment:
    name: staging
    url: https://staging.voxguard.ng
  steps:
    - uses: actions/checkout@v4

    - name: Deploy with Helm
      run: |
        helm upgrade --install voxguard ./deployment/helm/voxguard \
          --namespace voxguard-staging \
          --set global.image.tag=${{ github.sha }} \
          --set global.environment=staging \
          --values deployment/helm/values-staging.yaml \
          --wait --timeout 10m

    - name: Run smoke tests
      run: |
        ./scripts/smoke-tests.sh https://staging.voxguard.ng

    - name: Run performance baseline
      run: |
        k6 run tests/performance/baseline.js \
          --env BASE_URL=https://staging.voxguard.ng \
          --out json=reports/k6-staging.json
```

### Production Deployment (Canary with Admin Approval)

```yaml
deploy-production:
  name: Deploy to Production
  needs: deploy-staging
  runs-on: ubuntu-latest
  environment:
    name: production
    url: https://app.voxguard.ng
  steps:
    - uses: actions/checkout@v4

    # Phase 1: Canary (10% traffic)
    - name: Deploy canary
      run: |
        helm upgrade --install voxguard-canary ./deployment/helm/voxguard \
          --namespace voxguard-prod \
          --set global.image.tag=${{ github.sha }} \
          --set global.environment=production \
          --set canary.enabled=true \
          --set canary.weight=10 \
          --values deployment/helm/values-prod.yaml \
          --wait --timeout 10m

    - name: Canary health check (5 minutes)
      run: |
        ./scripts/canary-check.sh \
          --duration 300 \
          --error-threshold 1.0 \
          --latency-threshold 5.0 \
          --namespace voxguard-prod

    # Phase 2: Progressive rollout (50% traffic)
    - name: Scale canary to 50%
      run: |
        helm upgrade voxguard-canary ./deployment/helm/voxguard \
          --namespace voxguard-prod \
          --set canary.weight=50 \
          --reuse-values

    - name: Canary health check (5 minutes at 50%)
      run: |
        ./scripts/canary-check.sh \
          --duration 300 \
          --error-threshold 0.5 \
          --latency-threshold 3.0 \
          --namespace voxguard-prod

    # Phase 3: Full rollout (100% traffic)
    - name: Full production deployment
      run: |
        helm upgrade --install voxguard ./deployment/helm/voxguard \
          --namespace voxguard-prod \
          --set global.image.tag=${{ github.sha }} \
          --set global.environment=production \
          --set canary.enabled=false \
          --values deployment/helm/values-prod.yaml \
          --wait --timeout 15m

    - name: Remove canary
      run: |
        helm uninstall voxguard-canary --namespace voxguard-prod || true

    - name: Post-deploy verification
      run: |
        ./scripts/post-deploy-verify.sh https://app.voxguard.ng
```

---

## Rollback Procedures

### Automated Rollback Triggers

The pipeline automatically initiates rollback when any of the following conditions are detected within the first 15 minutes after deployment:

| Trigger | Threshold | Detection Method |
|---------|-----------|-----------------|
| Error rate spike | > 1% of requests returning 5xx | Prometheus alert `VoxGuardHighErrorRate` |
| Latency degradation | P99 > 5ms for detection engine | Prometheus alert `VoxGuardHighLatency` |
| Health check failure | 3 consecutive failures on any service | Kubernetes liveness probe |
| Crash loop | Pod restart count > 3 in 5 minutes | Kubernetes event watcher |
| Canary failure | Error rate > 1% during canary phase | Canary check script |

### Rollback Execution

```yaml
rollback:
  name: Emergency Rollback
  runs-on: ubuntu-latest
  steps:
    - name: Identify last stable release
      id: stable
      run: |
        LAST_STABLE=$(helm history voxguard -n voxguard-prod --max 10 -o json \
          | jq -r '[.[] | select(.status == "deployed")] | sort_by(.revision) | .[-2].revision')
        echo "revision=$LAST_STABLE" >> $GITHUB_OUTPUT

    - name: Execute Helm rollback
      run: |
        helm rollback voxguard ${{ steps.stable.outputs.revision }} \
          --namespace voxguard-prod \
          --wait --timeout 10m

    - name: Verify rollback
      run: |
        kubectl rollout status deployment/detection-engine -n voxguard-prod --timeout=300s
        kubectl rollout status deployment/management-api -n voxguard-prod --timeout=300s

    - name: Notify team
      uses: slackapi/slack-github-action@v1
      with:
        payload: |
          {
            "text": "ROLLBACK EXECUTED: VoxGuard production rolled back to revision ${{ steps.stable.outputs.revision }}",
            "channel": "#voxguard-ops"
          }
```

### Manual Rollback Commands

```bash
# Rollback to previous revision
helm rollback voxguard 1 -n voxguard-prod

# Rollback to specific revision
helm rollback voxguard <revision-number> -n voxguard-prod

# Rollback with kubectl (emergency - bypasses Helm)
kubectl rollout undo deployment/detection-engine -n voxguard-prod
kubectl rollout undo deployment/management-api -n voxguard-prod
kubectl rollout undo deployment/processing-service -n voxguard-prod
kubectl rollout undo deployment/web -n voxguard-prod

# Verify rollback status
kubectl rollout status deployment/detection-engine -n voxguard-prod
helm history voxguard -n voxguard-prod
```

---

## Environment Promotion

### Promotion Flow

```
┌─────────────┐   Auto    ┌─────────────┐  Manual   ┌─────────────┐
│     Dev     │ ────────> │   Staging   │ ────────> │ Production  │
│             │  (on main │             │  (approval│             │
│  Automated  │   merge)  │  Smoke +    │  required)│  Canary +   │
│  tests only │           │  Perf tests │           │  Progressive│
└─────────────┘           └─────────────┘           └─────────────┘
```

### Promotion Checklist

Before promoting from staging to production:

- [ ] All quality gates passed in staging
- [ ] Smoke tests passed in staging
- [ ] Performance baseline shows no regression
- [ ] Security scan results reviewed
- [ ] Database migrations tested and reversible
- [ ] Feature flags configured for gradual rollout
- [ ] Rollback plan documented and tested
- [ ] On-call engineer confirmed availability
- [ ] NCC compliance requirements verified (if applicable)

### Image Promotion (No Rebuild)

```yaml
promote-image:
  name: Promote Image to Production Registry
  runs-on: ubuntu-latest
  steps:
    - name: Pull staging image
      run: |
        docker pull ghcr.io/voxguard/${{ matrix.service }}:staging-${{ github.sha }}

    - name: Tag for production
      run: |
        docker tag \
          ghcr.io/voxguard/${{ matrix.service }}:staging-${{ github.sha }} \
          ghcr.io/voxguard/${{ matrix.service }}:prod-${{ github.sha }}

    - name: Push production tag
      run: |
        docker push ghcr.io/voxguard/${{ matrix.service }}:prod-${{ github.sha }}
```

---

## Secrets Management in CI

### Secret Categories

| Category | Storage | Rotation | Access |
|----------|---------|----------|--------|
| **CI/CD Tokens** | GitHub Encrypted Secrets | 90 days | Workflow-scoped |
| **Database Credentials** | HashiCorp Vault | 30 days (auto) | Service-scoped |
| **API Keys** | GitHub Encrypted Secrets | 180 days | Environment-scoped |
| **TLS Certificates** | cert-manager (K8s) | Auto-renewed | Namespace-scoped |
| **NCC Credentials** | HashiCorp Vault | Annual (manual) | Restricted |
| **Container Registry** | GitHub OIDC | Per-workflow | Workflow-scoped |

### Secret Injection Architecture

```
┌──────────────────────────────────────────────────┐
│                GitHub Actions                      │
│                                                    │
│  ┌──────────────┐    ┌──────────────────────────┐ │
│  │ GitHub       │    │ Environment Secrets       │ │
│  │ Secrets      │    │ (dev/staging/production)  │ │
│  │ (global)     │    │                           │ │
│  └──────┬───────┘    └────────────┬──────────────┘ │
│         │                         │                 │
│         └─────────┬───────────────┘                 │
│                   ▼                                 │
│  ┌──────────────────────────────────────┐          │
│  │         Workflow Runtime              │          │
│  │  (secrets masked in logs)             │          │
│  └──────────────┬───────────────────────┘          │
└─────────────────┼──────────────────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────────────────┐
│              Kubernetes Cluster                    │
│                                                    │
│  ┌──────────────┐    ┌──────────────────────────┐ │
│  │ External     │    │ K8s Secrets               │ │
│  │ Secrets      │◄──│ (injected by ESO)         │ │
│  │ Operator     │    │                           │ │
│  └──────┬───────┘    └──────────────────────────┘ │
│         │                                          │
│         ▼                                          │
│  ┌──────────────────────────────────────┐          │
│  │         HashiCorp Vault               │          │
│  │  (source of truth for all secrets)    │          │
│  └──────────────────────────────────────┘          │
└──────────────────────────────────────────────────┘
```

### Secret Scanning Prevention

```yaml
# Pre-commit hook configuration (.pre-commit-config.yaml)
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
        name: Detect hardcoded secrets
        entry: gitleaks protect --staged --verbose
```

### Required GitHub Secrets

| Secret Name | Purpose | Environment |
|-------------|---------|------------|
| `DEV_KUBECONFIG` | Kubernetes config for dev cluster | Development |
| `STAGING_KUBECONFIG` | Kubernetes config for staging cluster | Staging |
| `PROD_KUBECONFIG` | Kubernetes config for production cluster | Production |
| `VAULT_ADDR` | HashiCorp Vault address | All |
| `VAULT_TOKEN` | HashiCorp Vault authentication | All |
| `SLACK_WEBHOOK_URL` | Slack notification webhook | All |
| `PAGERDUTY_KEY` | PagerDuty integration key | Production |
| `NCC_CLIENT_ID` | NCC API client ID | Production |
| `NCC_CLIENT_SECRET` | NCC API client secret | Production |
| `ANTHROPIC_API_KEY` | Claude Code AIDD agent key | All |

---

## AIDD Integration

### Autonomous PR Classification

VoxGuard integrates AIDD (Autonomous Intelligence-Driven Development) into the CI/CD pipeline. Every pull request is automatically classified into an approval tier based on the nature of changes.

```mermaid
flowchart TD
    PR[Pull Request Opened] --> CLASSIFY[AIDD Classifier]
    CLASSIFY --> ANALYZE[Analyze Changed Files]

    ANALYZE --> T0{Docs/Tests/Config Only?}
    T0 -->|Yes| TIER0[Tier 0: Auto-Merge]

    T0 -->|No| T1{Feature/Logic Changes?}
    T1 -->|Yes| TIER1[Tier 1: Review Required]

    T1 -->|No| T2{Auth/Payments/Infra?}
    T2 -->|Yes| TIER2[Tier 2: Admin Approval]

    TIER0 --> AUTO[Auto-Merge After CI Pass]
    TIER1 --> REVIEW[1 Reviewer Required]
    TIER2 --> ADMIN[Admin + Security Team Approval]
```

### Tier-Based Merge Rules

| Tier | Classification | Merge Rule | Reviewers | CI Requirements |
|------|---------------|------------|-----------|----------------|
| **T0** | Documentation, tests, comments, `.md` files, test fixtures, `pages.css` | Auto-merge after CI passes | None (bot-approved) | Build + lint only |
| **T1** | Feature code, business logic, UI components, API endpoints, fraud rules | Merge after 1 approved review | 1 team member | Full pipeline |
| **T2** | Auth/JWT changes, database migrations, K8s/Helm configs, NCC credentials, payment logic | Merge after admin + security review | Admin + Security Lead | Full pipeline + manual security review |

### AIDD Classification Workflow

```yaml
aidd-classify:
  name: AIDD PR Classification
  runs-on: ubuntu-latest
  if: github.event_name == 'pull_request'
  steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 0

    - name: Get changed files
      id: changed
      run: |
        FILES=$(gh pr diff ${{ github.event.pull_request.number }} --name-only)
        echo "files<<EOF" >> $GITHUB_OUTPUT
        echo "$FILES" >> $GITHUB_OUTPUT
        echo "EOF" >> $GITHUB_OUTPUT

    - name: Classify PR tier
      id: classify
      run: |
        TIER="T0"  # Default: auto-approve

        # Check for T2 patterns (highest priority)
        if echo "${{ steps.changed.outputs.files }}" | grep -qE \
          '(auth|jwt|migration|k8s|helm|secrets|vault|ncc|payment)'; then
          TIER="T2"
        # Check for T1 patterns
        elif echo "${{ steps.changed.outputs.files }}" | grep -qE \
          '\.(rs|go|py|ts|tsx)$' | grep -vE '(test|spec|_test|\.test\.)'; then
          TIER="T1"
        fi

        echo "tier=$TIER" >> $GITHUB_OUTPUT

    - name: Apply tier label
      run: |
        gh pr edit ${{ github.event.pull_request.number }} \
          --add-label "aidd:${{ steps.classify.outputs.tier }}"

    - name: Configure merge rules
      run: |
        case "${{ steps.classify.outputs.tier }}" in
          T0)
            echo "Auto-merge enabled for T0 PR"
            gh pr merge ${{ github.event.pull_request.number }} --auto --squash
            ;;
          T1)
            echo "Review required for T1 PR"
            gh pr edit ${{ github.event.pull_request.number }} \
              --add-reviewer "voxguard-team"
            ;;
          T2)
            echo "Admin approval required for T2 PR"
            gh pr edit ${{ github.event.pull_request.number }} \
              --add-reviewer "voxguard-admins,voxguard-security"
            ;;
        esac
```

### AIDD File Classification Matrix

| File Pattern | Tier | Rationale |
|-------------|------|-----------|
| `docs/**`, `*.md`, `README*` | T0 | Read-only documentation |
| `**/tests/**`, `**/*_test.*`, `**/*.spec.*` | T0 | Test files only |
| `**/*.css`, `**/pages.css` | T0 | Style-only changes |
| `**/.gitignore`, `**/.editorconfig` | T0 | Config files |
| `services/detection-engine/src/**/*.rs` | T1 | Detection engine logic |
| `services/management-api/**/*.go` | T1 | Management API logic |
| `services/processing-service/**/*.py` | T1 | Processing service logic |
| `packages/web/src/**/*.{ts,tsx}` | T1 | Frontend components |
| `**/auth/**`, `**/jwt/**` | T2 | Authentication changes |
| `**/migrations/**` | T2 | Database schema changes |
| `deployment/k8s/**`, `deployment/helm/**` | T2 | Infrastructure changes |
| `**/secrets*`, `**/vault*` | T2 | Secrets management |
| `**/ncc/**`, `**/compliance/**` | T2 | Regulatory compliance |

---

## Monitoring Post-Deploy

### Post-Deployment Health Checks

```mermaid
sequenceDiagram
    participant CD as CI/CD Pipeline
    participant K8S as Kubernetes
    participant PROM as Prometheus
    participant GRAF as Grafana
    participant ALERT as AlertManager
    participant OPS as Ops Team

    CD->>K8S: Deploy new version
    K8S->>K8S: Rolling update
    loop Every 30s for 15 min
        CD->>K8S: Check pod health
        CD->>PROM: Query error rate
        CD->>PROM: Query latency P99
        CD->>PROM: Query CPS throughput
    end

    alt Metrics Healthy
        CD->>GRAF: Update deployment annotation
        CD->>OPS: Notify: Deploy successful
    else Metrics Degraded
        CD->>K8S: Initiate rollback
        PROM->>ALERT: Fire rollback alert
        ALERT->>OPS: Page on-call engineer
    end
```

### Canary Check Configuration

```yaml
canary-checks:
  health_endpoints:
    - url: "https://app.voxguard.ng/api/health"
      expected_status: 200
      timeout: 5s
    - url: "https://app.voxguard.ng/api/v1/detection/health"
      expected_status: 200
      timeout: 5s
    - url: "https://app.voxguard.ng/api/v1/management/health"
      expected_status: 200
      timeout: 5s

  prometheus_checks:
    - query: 'rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) * 100'
      threshold: 1.0
      operator: "<"
      description: "Error rate below 1%"

    - query: 'histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))'
      threshold: 0.005
      operator: "<"
      description: "P99 latency below 5ms"

    - query: 'sum(rate(acm_calls_processed_total[5m]))'
      threshold: 100000
      operator: ">"
      description: "CPS throughput above 100K"

    - query: 'up{job=~"detection-engine|management-api|processing-service"}'
      threshold: 1
      operator: "=="
      description: "All services reporting UP"

  rollback_triggers:
    error_rate_threshold: 1.0      # Percentage
    latency_p99_threshold: 5.0     # Milliseconds
    consecutive_failures: 3         # Health check failures
    evaluation_window: "5m"         # Time window for evaluation
    cooldown_period: "15m"          # Time before auto-rollback activates
```

### Automated Rollback Triggers

```yaml
post-deploy-monitor:
  name: Post-Deploy Monitoring
  needs: deploy-production
  runs-on: ubuntu-latest
  timeout-minutes: 20
  steps:
    - name: Monitor for 15 minutes
      run: |
        PROMETHEUS_URL="${{ secrets.PROMETHEUS_URL }}"
        ROLLBACK=false

        for i in $(seq 1 30); do  # Check every 30 seconds for 15 minutes
          sleep 30

          # Check error rate
          ERROR_RATE=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=rate(http_requests_total{status=~\"5..\"}[5m])/rate(http_requests_total[5m])*100" \
            | jq -r '.data.result[0].value[1] // "0"')

          if (( $(echo "$ERROR_RATE > 1.0" | bc -l) )); then
            echo "::error::Error rate $ERROR_RATE% exceeds threshold"
            ROLLBACK=true
            break
          fi

          # Check P99 latency
          P99=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=histogram_quantile(0.99,rate(http_request_duration_seconds_bucket[5m]))" \
            | jq -r '.data.result[0].value[1] // "0"')

          if (( $(echo "$P99 > 0.005" | bc -l) )); then
            echo "::error::P99 latency ${P99}s exceeds 5ms threshold"
            ROLLBACK=true
            break
          fi

          echo "Check $i/30: Error rate=${ERROR_RATE}%, P99=${P99}s - OK"
        done

        if [ "$ROLLBACK" = true ]; then
          echo "::error::Post-deploy checks failed - triggering rollback"
          exit 1
        fi

        echo "Post-deploy monitoring passed - deployment stable"

    - name: Trigger rollback on failure
      if: failure()
      run: |
        gh workflow run rollback.yml \
          --field environment=production \
          --field reason="Automated: Post-deploy metrics exceeded thresholds"
```

### Grafana Deployment Annotations

```yaml
    - name: Annotate deployment in Grafana
      if: success()
      run: |
        curl -X POST "${{ secrets.GRAFANA_URL }}/api/annotations" \
          -H "Authorization: Bearer ${{ secrets.GRAFANA_TOKEN }}" \
          -H "Content-Type: application/json" \
          -d '{
            "dashboardUID": "voxguard-overview",
            "time": '$(date +%s000)',
            "tags": ["deployment", "production"],
            "text": "Deployed ${{ github.sha }} by ${{ github.actor }}"
          }'
```

---

## Pipeline Maintenance

### Pipeline Health Dashboard

| Metric | Target | Current |
|--------|--------|---------|
| Pipeline success rate | > 95% | 97.2% |
| Average pipeline duration | < 35 min | 28 min |
| Flaky test rate | < 2% | 0.8% |
| Cache hit rate | > 80% | 89% |
| Deploy frequency | >= 1/day | 2.3/day |
| Mean time to recovery | < 30 min | 12 min |

### Runner Configuration

| Runner | OS | CPU | Memory | Use Case |
|--------|----|-----|--------|----------|
| `ubuntu-latest` | Ubuntu 22.04 | 4 vCPU | 16 GB | Standard builds |
| `ubuntu-latest-8core` | Ubuntu 22.04 | 8 vCPU | 32 GB | Rust builds, E2E tests |
| `self-hosted-perf` | Ubuntu 22.04 | 16 vCPU | 64 GB | Performance benchmarks |

### Workflow File Inventory

| Workflow | File | Trigger | Purpose |
|----------|------|---------|---------|
| CI Pipeline | `ci.yml` | Push, PR | Build, test, security |
| Deploy Dev | `deploy-dev.yml` | CI success on main | Dev deployment |
| Deploy Staging | `deploy-staging.yml` | Manual approval | Staging deployment |
| Deploy Prod | `deploy-prod.yml` | Manual approval | Production deployment |
| Rollback | `rollback.yml` | Manual or automated | Emergency rollback |
| Nightly Security | `security-nightly.yml` | Cron (02:00 UTC) | Full security scan |
| AIDD Classify | `aidd-classify.yml` | PR opened/updated | PR tier classification |
| Frontend Lifecycle | `frontend-lifecycle.yml` | Push to main | Frontend sync |
| Auditor Loop | `auditor-loop.yml` | Scheduled | Automated code audit |
| Self Healing | `self-healing.yml` | Alert trigger | Auto-remediation |

---

## Appendix

### Pipeline YAML Template

For creating new service pipelines, use the template at `deployment/ci/pipeline-template.yml`.

### Related Documentation

- [ARCHITECTURE.md](./ARCHITECTURE.md) -- System architecture overview
- [DEPLOYMENT.md](./DEPLOYMENT.md) -- Deployment guide
- [TESTING.md](./TESTING.md) -- Testing strategy
- [SECURITY_HARDENING.md](./SECURITY_HARDENING.md) -- Security controls
- [AIDD_APPROVAL_TIERS.md](./AIDD_APPROVAL_TIERS.md) -- AIDD tier definitions
- [OBSERVABILITY.md](./OBSERVABILITY.md) -- Monitoring and observability
- [DISASTER_RECOVERY.md](./DISASTER_RECOVERY.md) -- Disaster recovery plan
