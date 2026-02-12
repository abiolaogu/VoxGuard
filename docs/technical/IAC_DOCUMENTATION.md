# Infrastructure as Code Documentation

## VoxGuard -- Anti-Call Masking & Voice Network Fraud Detection Platform

**Version:** 1.0
**Date:** February 2026
**Status:** Production
**Classification:** Technical -- Internal
**AIDD Compliance:** Tier 0 (Documentation)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Kubernetes Cluster Architecture](#2-kubernetes-cluster-architecture)
3. [Helm Chart Structure](#3-helm-chart-structure)
4. [Docker Image Build Pipeline](#4-docker-image-build-pipeline)
5. [Database Cluster Configurations](#5-database-cluster-configurations)
6. [Hasura Configuration](#6-hasura-configuration)
7. [Observability Stack](#7-observability-stack)
8. [CI/CD Pipeline](#8-cicd-pipeline)
9. [Environment Matrix](#9-environment-matrix)
10. [Secrets Management](#10-secrets-management)
11. [Disaster Recovery Infrastructure](#11-disaster-recovery-infrastructure)

---

## 1. Overview

### 1.1 Infrastructure Philosophy

VoxGuard's infrastructure is managed entirely through code using the following principles:

| Principle | Implementation |
|---|---|
| **GitOps** | All infrastructure configuration stored in Git; cluster state reconciled from Git |
| **Immutable Infrastructure** | Container images are immutable; no SSH into production pods |
| **Declarative Configuration** | Kubernetes manifests, Helm values, Terraform modules -- no imperative scripts |
| **Environment Parity** | Dev, staging, and production use identical Helm charts with different `values-*.yaml` |
| **Least Privilege** | Every service account, network policy, and IAM role follows minimal permissions |

### 1.2 Infrastructure Stack

```mermaid
flowchart TB
    subgraph Provisioning["Infrastructure Provisioning"]
        TF[Terraform<br>Cloud resources]
    end

    subgraph Orchestration["Container Orchestration"]
        K8s[Kubernetes 1.28+<br>3-node cluster minimum]
    end

    subgraph Packaging["Application Packaging"]
        Docker[Docker<br>Multi-stage builds]
        Helm[Helm 3<br>Chart packaging]
    end

    subgraph CICD["CI/CD"]
        GHA[GitHub Actions<br>Build, test, deploy]
        Registry[Container Registry<br>ghcr.io / ECR]
    end

    subgraph Config["Configuration"]
        Values[Helm Values<br>Per-environment]
        Secrets[Vault + ESO<br>Dynamic secrets]
    end

    TF --> K8s
    Docker --> Registry
    Helm --> K8s
    GHA --> Docker
    GHA --> Helm
    Values --> Helm
    Secrets --> K8s
```

### 1.3 Repository Structure

```
infrastructure/
  terraform/
    modules/
      kubernetes/            # EKS/GKE/bare-metal K8s provisioning
      networking/            # VPC, subnets, security groups
      dns/                   # Route53 / GeoDNS
      storage/               # S3 buckets, EBS volumes
    environments/
      dev/
        main.tf
        variables.tf
        terraform.tfvars
      staging/
      production/
  helm/
    voxguard/               # Main application chart
    dragonfly/              # DragonflyDB chart
    clickhouse/             # ClickHouse chart
    yugabyte/               # YugabyteDB chart
    observability/          # Prometheus + Grafana + Tempo + Loki
    vault/                  # HashiCorp Vault chart
  docker/
    detection-engine/       # Rust Dockerfile
    management-api/         # Go Dockerfile
    ml-pipeline/            # Python Dockerfile
    web-dashboard/          # React Dockerfile
  k8s/
    base/                   # Base Kustomize manifests
    overlays/
      dev/
      staging/
      production/
  scripts/
    init-yugabyte.sh
    init-clickhouse.sh
    seed-nigerian-prefixes.sh
    backup-yugabyte.sh
    restore-yugabyte.sh
```

---

## 2. Kubernetes Cluster Architecture

### 2.1 Cluster Topology

```mermaid
flowchart TB
    subgraph Cluster["Kubernetes Cluster (3+ Nodes)"]
        subgraph CP["Control Plane"]
            API[kube-apiserver]
            Sched[kube-scheduler]
            ETCD[etcd cluster x3]
            CM[controller-manager]
        end

        subgraph Workers["Worker Nodes"]
            subgraph Node1["Node 1 (8 vCPU, 32GB)"]
                N1_DE[Detection Engine Pods]
                N1_MA[Management API Pods]
            end
            subgraph Node2["Node 2 (8 vCPU, 32GB)"]
                N2_DE[Detection Engine Pods]
                N2_Web[Web Dashboard Pods]
                N2_Hasura[Hasura Pods]
            end
            subgraph Node3["Node 3 (16 vCPU, 64GB)"]
                N3_DF[DragonflyDB Pods]
                N3_CH[ClickHouse Pods]
                N3_YB[YugabyteDB Pods]
            end
        end
    end
```

### 2.2 Namespace Design

| Namespace | Purpose | Services |
|---|---|---|
| `voxguard-prod` | Application workloads | Detection Engine, Management API, ML Pipeline, Web Dashboard, Hasura |
| `voxguard-data` | Data stores | DragonflyDB, ClickHouse, YugabyteDB |
| `voxguard-observability` | Monitoring and logging | Prometheus, Grafana, Tempo, Loki, AlertManager |
| `voxguard-security` | Security infrastructure | HashiCorp Vault, External Secrets Operator |
| `ingress-nginx` | Ingress controllers | NGINX Ingress Controller |
| `cert-manager` | TLS certificate management | cert-manager |

### 2.3 Resource Quotas

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: voxguard-prod-quota
  namespace: voxguard-prod
spec:
  hard:
    requests.cpu: "16"
    requests.memory: 32Gi
    limits.cpu: "40"
    limits.memory: 80Gi
    pods: "50"
    services: "20"
    secrets: "30"
    configmaps: "30"
    persistentvolumeclaims: "10"
```

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: voxguard-data-quota
  namespace: voxguard-data
spec:
  hard:
    requests.cpu: "12"
    requests.memory: 48Gi
    limits.cpu: "24"
    limits.memory: 96Gi
    pods: "20"
    persistentvolumeclaims: "15"
```

### 2.4 Limit Ranges

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: voxguard-prod
spec:
  limits:
  - default:
      cpu: "2"
      memory: 4Gi
    defaultRequest:
      cpu: "500m"
      memory: 512Mi
    min:
      cpu: "100m"
      memory: 128Mi
    max:
      cpu: "8"
      memory: 16Gi
    type: Container
```

### 2.5 Network Policies

```yaml
# Default deny all traffic in production namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: voxguard-prod
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

---
# Detection Engine: Allow ingress from Ingress Controller, egress to data stores + ML
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: detection-engine-policy
  namespace: voxguard-prod
spec:
  podSelector:
    matchLabels:
      app: detection-engine
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
  - from:
    - podSelector:
        matchLabels:
          app: prometheus
      namespaceSelector:
        matchLabels:
          name: voxguard-observability
    ports:
    - protocol: TCP
      port: 9090
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: voxguard-data
    ports:
    - {protocol: TCP, port: 6379}   # DragonflyDB
    - {protocol: TCP, port: 8123}   # ClickHouse
    - {protocol: TCP, port: 5433}   # YugabyteDB
  - to:
    - podSelector:
        matchLabels:
          app: ml-pipeline
    ports:
    - {protocol: TCP, port: 50051}  # gRPC
  - to:                              # DNS
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - {protocol: UDP, port: 53}
    - {protocol: TCP, port: 53}

---
# Management API: Allow ingress from Ingress Controller, egress to YugabyteDB, DragonflyDB, Vault, NCC
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: management-api-policy
  namespace: voxguard-prod
spec:
  podSelector:
    matchLabels:
      app: management-api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8081
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: voxguard-data
    ports:
    - {protocol: TCP, port: 5433}   # YugabyteDB
    - {protocol: TCP, port: 6379}   # DragonflyDB
  - to:
    - namespaceSelector:
        matchLabels:
          name: voxguard-security
    ports:
    - {protocol: TCP, port: 8200}   # Vault
  - to:                              # NCC API (external)
    - ipBlock:
        cidr: 0.0.0.0/0
    ports:
    - {protocol: TCP, port: 443}    # HTTPS
    - {protocol: TCP, port: 22}     # SFTP
  - to:                              # DNS
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - {protocol: UDP, port: 53}

---
# Data stores: Only allow ingress from application namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: data-stores-policy
  namespace: voxguard-data
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: voxguard-prod
```

### 2.6 Pod Security Standards

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: voxguard-prod
  labels:
    name: voxguard-prod
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

All containers run with:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  seccompProfile:
    type: RuntimeDefault
```

---

## 3. Helm Chart Structure

### 3.1 Chart Overview

```
helm/voxguard/
  Chart.yaml                    # Chart metadata (version, dependencies)
  values.yaml                   # Default values
  values-dev.yaml               # Development overrides
  values-staging.yaml           # Staging overrides
  values-production.yaml        # Production overrides
  templates/
    _helpers.tpl                # Template helper functions
    NOTES.txt                   # Post-install instructions

    # Application Services
    detection-engine/
      deployment.yaml
      service.yaml
      hpa.yaml
      pdb.yaml
      configmap.yaml
      serviceaccount.yaml

    management-api/
      deployment.yaml
      service.yaml
      hpa.yaml
      pdb.yaml
      configmap.yaml
      serviceaccount.yaml

    ml-pipeline/
      deployment.yaml
      service.yaml
      hpa.yaml
      configmap.yaml
      serviceaccount.yaml

    web-dashboard/
      deployment.yaml
      service.yaml
      ingress.yaml
      configmap.yaml

    hasura/
      deployment.yaml
      service.yaml
      configmap.yaml

    # Network
    network-policies/
      default-deny.yaml
      detection-engine.yaml
      management-api.yaml
      data-stores.yaml

    # RBAC
    rbac/
      service-accounts.yaml
      cluster-roles.yaml
      role-bindings.yaml
```

### 3.2 Key Helm Values

```yaml
# values.yaml (defaults)
global:
  environment: production
  imageRegistry: ghcr.io/voxguard
  imagePullSecrets:
    - name: ghcr-pull-secret

detectionEngine:
  replicaCount: 4
  image:
    repository: detection-engine
    tag: "2.0.0"
    pullPolicy: IfNotPresent
  resources:
    requests:
      cpu: "2"
      memory: 2Gi
    limits:
      cpu: "4"
      memory: 4Gi
  hpa:
    enabled: true
    minReplicas: 2
    maxReplicas: 20
    targetCPUUtilizationPercentage: 70
    targetMemoryUtilizationPercentage: 80
  pdb:
    enabled: true
    minAvailable: 2
  service:
    type: ClusterIP
    port: 8080
    metricsPort: 9090
  config:
    dragonflyUrl: "redis://dragonfly.voxguard-data:6379"
    yugabyteUrl: "postgres://voxguard:${DB_PASSWORD}@yugabyte.voxguard-data:5433/acm_db"
    clickhouseUrl: "http://clickhouse.voxguard-data:8123"
    mlPipelineUrl: "ml-pipeline.voxguard-prod:50051"
    detectionWindowSeconds: 5
    detectionThreshold: 5
    batchFlushInterval: "1s"
    batchFlushSize: 1000
  probes:
    liveness:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 5
      failureThreshold: 3
    readiness:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
      failureThreshold: 3

managementApi:
  replicaCount: 3
  image:
    repository: management-api
    tag: "2.0.0"
  resources:
    requests:
      cpu: "1"
      memory: 1Gi
    limits:
      cpu: "2"
      memory: 2Gi
  hpa:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
  pdb:
    enabled: true
    minAvailable: 1
  service:
    port: 8081
  config:
    databaseUrl: "postgres://voxguard:${DB_PASSWORD}@yugabyte.voxguard-data:5433/acm_db"
    vaultAddr: "https://vault.voxguard-security:8200"
    ginMode: "release"
    jwtIssuer: "voxguard-management-api"
    rateLimitPerMinute: 100

mlPipeline:
  replicaCount: 2
  image:
    repository: ml-pipeline
    tag: "1.0.0"
  resources:
    requests:
      cpu: "1"
      memory: 2Gi
    limits:
      cpu: "4"
      memory: 4Gi
  hpa:
    enabled: true
    minReplicas: 1
    maxReplicas: 5
    targetCPUUtilizationPercentage: 80
  service:
    port: 50051
  config:
    clickhouseUrl: "http://clickhouse.voxguard-data:8123"
    dragonflyUrl: "redis://dragonfly.voxguard-data:6379"
    modelPath: "/models/active"

webDashboard:
  replicaCount: 2
  image:
    repository: web-dashboard
    tag: "2.0.0"
  resources:
    requests:
      cpu: "200m"
      memory: 256Mi
    limits:
      cpu: "500m"
      memory: 512Mi
  service:
    port: 3000
  ingress:
    enabled: true
    className: nginx
    hosts:
      - host: voxguard.ng
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: voxguard-tls
        hosts:
          - voxguard.ng

hasura:
  replicaCount: 2
  image:
    repository: hasura/graphql-engine
    tag: "v2.36.0"
  resources:
    requests:
      cpu: "500m"
      memory: 1Gi
    limits:
      cpu: "2"
      memory: 2Gi
  service:
    port: 8082
  config:
    databaseUrl: "postgres://hasura:${HASURA_DB_PASSWORD}@yugabyte.voxguard-data:5433/acm_db"
    enableConsole: false  # Disabled in production
    enableTelemetry: false
    jwtSecret: '{"type":"RS256","jwk_url":"http://management-api.voxguard-prod:8081/.well-known/jwks.json"}'
    unauthorizedRole: "anonymous"
    adminSecret: "${HASURA_ADMIN_SECRET}"
```

### 3.3 Environment-Specific Overrides

```yaml
# values-dev.yaml
global:
  environment: development

detectionEngine:
  replicaCount: 1
  hpa:
    enabled: false
  pdb:
    enabled: false
  resources:
    requests:
      cpu: "500m"
      memory: 512Mi
    limits:
      cpu: "1"
      memory: 1Gi

managementApi:
  replicaCount: 1
  hpa:
    enabled: false
  config:
    ginMode: "debug"

webDashboard:
  replicaCount: 1
  ingress:
    hosts:
      - host: dev.voxguard.ng

hasura:
  replicaCount: 1
  config:
    enableConsole: true  # Enabled in dev
```

```yaml
# values-production.yaml
global:
  environment: production

detectionEngine:
  replicaCount: 4
  hpa:
    minReplicas: 4
    maxReplicas: 20
  resources:
    requests:
      cpu: "2"
      memory: 4Gi
    limits:
      cpu: "4"
      memory: 8Gi

managementApi:
  replicaCount: 3
  hpa:
    minReplicas: 2
    maxReplicas: 10

webDashboard:
  replicaCount: 2
  ingress:
    hosts:
      - host: voxguard.ng
    annotations:
      nginx.ingress.kubernetes.io/rate-limit: "100"
      nginx.ingress.kubernetes.io/rate-limit-window: "1m"
```

---

## 4. Docker Image Build Pipeline

### 4.1 Detection Engine (Rust)

```dockerfile
# infrastructure/docker/detection-engine/Dockerfile

# Stage 1: Build
FROM rust:1.75-bookworm AS builder

WORKDIR /app
COPY Cargo.toml Cargo.lock ./
COPY src/ src/

# Build release binary with optimizations
RUN cargo build --release --target x86_64-unknown-linux-gnu

# Stage 2: Runtime (distroless)
FROM gcr.io/distroless/cc-debian12:nonroot

COPY --from=builder /app/target/x86_64-unknown-linux-gnu/release/detection-engine /usr/local/bin/

EXPOSE 8080 9090
USER nonroot:nonroot

ENTRYPOINT ["detection-engine"]
```

**Image Size:** ~25 MB (distroless base)
**Security:** No shell, no package manager, non-root user

### 4.2 Management API (Go)

```dockerfile
# infrastructure/docker/management-api/Dockerfile

# Stage 1: Build
FROM golang:1.21-bookworm AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w" -o /management-api ./cmd/api

# Stage 2: Runtime (distroless)
FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=builder /management-api /usr/local/bin/
COPY --from=builder /app/migrations /migrations

EXPOSE 8081
USER nonroot:nonroot

ENTRYPOINT ["management-api"]
```

**Image Size:** ~15 MB (static binary + distroless)

### 4.3 ML Pipeline (Python)

```dockerfile
# infrastructure/docker/ml-pipeline/Dockerfile

# Stage 1: Build
FROM python:3.11-slim-bookworm AS builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim-bookworm

RUN groupadd -g 1000 voxguard && \
    useradd -u 1000 -g voxguard -s /bin/false voxguard

WORKDIR /app
COPY --from=builder /install /usr/local
COPY src/ src/
COPY models/ models/

RUN chown -R voxguard:voxguard /app

EXPOSE 50051
USER voxguard

ENTRYPOINT ["python", "-m", "src.main"]
```

**Image Size:** ~200 MB (Python + ML libraries)

### 4.4 Web Dashboard (React)

```dockerfile
# infrastructure/docker/web-dashboard/Dockerfile

# Stage 1: Build
FROM node:20-bookworm-slim AS builder

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --production=false

COPY . .
RUN npm run build

# Stage 2: Serve (nginx)
FROM nginx:1.25-alpine

COPY --from=builder /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

RUN adduser -D -u 1000 voxguard && \
    chown -R voxguard:voxguard /usr/share/nginx/html /var/cache/nginx /var/log/nginx

EXPOSE 3000
USER voxguard

CMD ["nginx", "-g", "daemon off;"]
```

**Image Size:** ~30 MB (nginx-alpine + static files)

### 4.5 Image Scanning

All images are scanned before pushing to the registry:

```yaml
# GitHub Actions step
- name: Scan image with Trivy
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ env.IMAGE_NAME }}:${{ env.IMAGE_TAG }}
    format: 'sarif'
    output: 'trivy-results.sarif'
    severity: 'CRITICAL,HIGH'
    exit-code: '1'  # Fail pipeline on critical/high vulnerabilities
```

---

## 5. Database Cluster Configurations

### 5.1 DragonflyDB Cluster

```yaml
# helm/dragonfly/values.yaml
dragonfly:
  replicaCount: 3
  image:
    repository: docker.dragonflydb.io/dragonflydb/dragonfly
    tag: v1.14.0
  persistence:
    enabled: true
    size: 10Gi
    storageClass: ssd
  resources:
    requests:
      cpu: "2"
      memory: 8Gi
    limits:
      cpu: "4"
      memory: 16Gi
  args:
    - "--maxmemory=6gb"
    - "--proactor_threads=4"
    - "--hz=100"
    - "--save=60 1000"
    - "--dbfilename=dump.rdb"
    - "--requirepass=${DRAGONFLY_PASSWORD}"
    - "--bind=0.0.0.0"
    - "--protected-mode=yes"
    - "--tcp-backlog=511"
    - "--timeout=0"
    - "--tcp-keepalive=300"
  replication:
    enabled: true
    # Primary: dragonfly-0
    # Replicas: dragonfly-1, dragonfly-2
    # Replica config:
    #   --replicaof dragonfly-0.dragonfly.voxguard-data 6379
  metrics:
    enabled: true
    port: 6380
  service:
    type: ClusterIP
    port: 6379
```

**Memory Configuration:**

| Parameter | Value | Rationale |
|---|---|---|
| `maxmemory` | 6 GB | Leaves 2 GB headroom for OS + replication buffers |
| `maxmemory-policy` | `allkeys-lru` | Evict least recently used keys when memory full |
| `proactor_threads` | 4 | Match CPU allocation for optimal throughput |
| `hz` | 100 | Higher frequency for TTL expiration checks |

### 5.2 ClickHouse Cluster

```yaml
# helm/clickhouse/values.yaml
clickhouse:
  shards: 3
  replicasPerShard: 2
  image:
    repository: clickhouse/clickhouse-server
    tag: "24.1"
  persistence:
    size: 500Gi
    storageClass: ssd
  resources:
    requests:
      cpu: "4"
      memory: 8Gi
    limits:
      cpu: "8"
      memory: 16Gi
  config:
    maxMemoryUsage: 10737418240   # 10 GB
    maxMemoryUsageForAllQueries: 12884901888  # 12 GB
    maxPartitionsPerInsertBlock: 100
    maxInsertThreads: 4
    mergeTreeMaxRowsToUseCache: 10000000
    markCacheSize: 5368709120     # 5 GB
    # Compression
    compression:
      method: lz4
    # Replication via ZooKeeper (or ClickHouse Keeper)
    keeper:
      enabled: true
      replicas: 3
  users:
    default:
      password: "${CLICKHOUSE_DEFAULT_PASSWORD}"
      networks:
        - "10.0.0.0/8"  # Internal VPC only
    voxguard_app:
      password: "${CLICKHOUSE_APP_PASSWORD}"
      profile: default
      quota: default
      databases:
        - acm_analytics
  zookeeper:
    enabled: true
    replicaCount: 3
    resources:
      requests:
        cpu: "500m"
        memory: 1Gi
```

**Partitioning and TTL:**

```sql
-- All tables use monthly partitioning
PARTITION BY toYYYYMM(timestamp)

-- 7-year TTL for NCC compliance
TTL timestamp + INTERVAL 7 YEAR DELETE

-- Merge settings for optimal compression
SETTINGS
    index_granularity = 8192,
    min_bytes_for_wide_part = 10485760,       -- 10 MB
    min_rows_for_wide_part = 10000,
    merge_max_block_size = 8192
```

### 5.3 YugabyteDB Cluster

```yaml
# helm/yugabyte/values.yaml
yugabyte:
  replicationFactor: 3
  master:
    replicas: 3
    resources:
      requests:
        cpu: "2"
        memory: 4Gi
      limits:
        cpu: "4"
        memory: 8Gi
    storage:
      size: 50Gi
      storageClass: ssd
  tserver:
    replicas: 3
    resources:
      requests:
        cpu: "4"
        memory: 8Gi
      limits:
        cpu: "8"
        memory: 16Gi
    storage:
      size: 200Gi
      storageClass: ssd
    gflags:
      ysql_enable_auth: true
      ysql_hba_conf_csv: "hostssl all all 0.0.0.0/0 md5"
      use_node_to_node_encryption: true
      allow_insecure_connections: false
      certs_dir: /opt/certs
      yb_num_shards_per_tserver: 4
      ysql_num_shards_per_tserver: 4
      enable_ysql: true
      ysql_max_connections: 200
      default_memory_limit_to_ram_ratio: 0.6
  authCredentials:
    ysql:
      user: voxguard_admin
      password: "${YUGABYTE_ADMIN_PASSWORD}"
      database: acm_db
  backup:
    enabled: true
    schedule: "0 2 * * *"  # Daily at 2 AM
    retention: 30           # 30 days
    storageConfig:
      type: s3
      bucket: voxguard-db-backups
      endpoint: s3.amazonaws.com
      credentials:
        secretName: yugabyte-backup-credentials
```

**Geo-Distribution Configuration:**

```yaml
# For multi-region deployment
yugabyte:
  multiRegion:
    enabled: true
    regions:
      - name: lagos
        zones: ["lagos-1a", "lagos-1b"]
        numTservers: 3
        isDefault: true
        preferredLeaders: true
      - name: abuja
        zones: ["abuja-1a"]
        numTservers: 2
        isDefault: false
      - name: asaba
        zones: ["asaba-1a"]
        numTservers: 2
        isDefault: false
    placementPolicy: "cloud.region.zone"
```

---

## 6. Hasura Configuration

### 6.1 Deployment Configuration

```yaml
# helm/voxguard/templates/hasura/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: hasura-config
  namespace: voxguard-prod
data:
  HASURA_GRAPHQL_DATABASE_URL: "postgres://hasura:$(HASURA_DB_PASSWORD)@yugabyte.voxguard-data:5433/acm_db"
  HASURA_GRAPHQL_ENABLE_CONSOLE: "false"
  HASURA_GRAPHQL_ENABLE_TELEMETRY: "false"
  HASURA_GRAPHQL_LOG_LEVEL: "warn"
  HASURA_GRAPHQL_ENABLED_LOG_TYPES: "startup,http-log,webhook-log,websocket-log,query-log"
  HASURA_GRAPHQL_UNAUTHORIZED_ROLE: "anonymous"
  HASURA_GRAPHQL_CORS_DOMAIN: "https://voxguard.ng,https://dev.voxguard.ng"
  HASURA_GRAPHQL_WS_READ_COOKIE: "true"
  HASURA_GRAPHQL_ENABLE_ALLOWLIST: "true"  # Only allow pre-approved queries in production
  HASURA_GRAPHQL_LIVE_QUERIES_MULTIPLEXED_REFETCH_INTERVAL: "1000"
  HASURA_GRAPHQL_LIVE_QUERIES_MULTIPLEXED_BATCH_SIZE: "100"
  HASURA_GRAPHQL_CONNECTIONS_PER_READ_REPLICA: "50"
  HASURA_GRAPHQL_TOTAL_MAX_CONNECTIONS: "100"
  HASURA_GRAPHQL_STRINGIFY_NUMERIC_TYPES: "true"
```

### 6.2 JWT Configuration

```json
{
  "type": "RS256",
  "jwk_url": "http://management-api.voxguard-prod:8081/.well-known/jwks.json",
  "claims_map": {
    "x-hasura-allowed-roles": {"path": "$.roles"},
    "x-hasura-default-role": {"path": "$.roles[0]"},
    "x-hasura-user-id": {"path": "$.user_id"}
  },
  "issuer": "voxguard-management-api",
  "audience": "voxguard-platform"
}
```

### 6.3 Metadata Management

Hasura metadata is version-controlled and applied via CI/CD:

```bash
# Export metadata (development)
hasura metadata export --endpoint http://localhost:8082 --admin-secret $SECRET

# Apply metadata (CI/CD)
hasura metadata apply --endpoint $HASURA_ENDPOINT --admin-secret $SECRET

# Reload metadata (after schema changes)
hasura metadata reload --endpoint $HASURA_ENDPOINT --admin-secret $SECRET
```

Metadata files tracked in Git:

```
hasura/
  metadata/
    databases.yaml
    databases/
      default/
        tables/
          tables.yaml
          acm_gateways.yaml
    actions.yaml
    cron_triggers.yaml
    remote_schemas.yaml
    rest_endpoints.yaml
  migrations/
    default/
      1706000000000_init/
        up.sql
        down.sql
  seeds/
    default/
      initial_settings.sql
```

---

## 7. Observability Stack

### 7.1 Stack Architecture

```mermaid
flowchart TB
    subgraph Sources["Telemetry Sources"]
        DE[Detection Engine]
        MA[Management API]
        ML[ML Pipeline]
        DF[DragonflyDB]
        CH[ClickHouse]
        YB[YugabyteDB]
    end

    subgraph Collection["Collection Layer"]
        Prom[Prometheus<br>Metrics scraping]
        Promtail[Promtail<br>Log collection]
        OTEL[OTLP Collector<br>Trace collection]
    end

    subgraph Storage_Obs["Storage Layer"]
        PromDB[Prometheus TSDB<br>15d retention]
        Loki_DB[Loki<br>30d retention]
        Tempo_DB[Tempo<br>7d retention]
    end

    subgraph Viz["Visualization"]
        Grafana[Grafana<br>Dashboards + Alerts]
    end

    subgraph Alert["Alerting"]
        AM[AlertManager]
        PD[PagerDuty]
        Slack[Slack]
        Email[Email]
    end

    DE -->|/metrics| Prom
    MA -->|/metrics| Prom
    DE -->|stdout JSON| Promtail
    MA -->|stdout JSON| Promtail
    DE -->|OTLP gRPC| OTEL
    MA -->|OTLP gRPC| OTEL

    Prom --> PromDB
    Promtail --> Loki_DB
    OTEL --> Tempo_DB

    PromDB --> Grafana
    Loki_DB --> Grafana
    Tempo_DB --> Grafana

    Prom --> AM
    AM --> PD
    AM --> Slack
    AM --> Email
```

### 7.2 Prometheus Configuration

```yaml
# helm/observability/prometheus-values.yaml
prometheus:
  server:
    retention: 15d
    resources:
      requests:
        cpu: "1"
        memory: 4Gi
      limits:
        cpu: "2"
        memory: 8Gi
    persistentVolume:
      size: 100Gi
      storageClass: ssd
    scrapeInterval: 15s
    evaluationInterval: 15s

  serverFiles:
    prometheus.yml:
      scrape_configs:
        - job_name: 'detection-engine'
          scrape_interval: 5s
          kubernetes_sd_configs:
            - role: pod
              namespaces:
                names: ['voxguard-prod']
          relabel_configs:
            - source_labels: [__meta_kubernetes_pod_label_app]
              regex: detection-engine
              action: keep
            - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_port]
              regex: (.+)
              target_label: __address__
              replacement: $1

        - job_name: 'management-api'
          scrape_interval: 15s
          kubernetes_sd_configs:
            - role: pod
              namespaces:
                names: ['voxguard-prod']
          relabel_configs:
            - source_labels: [__meta_kubernetes_pod_label_app]
              regex: management-api
              action: keep

        - job_name: 'dragonfly'
          scrape_interval: 10s
          static_configs:
            - targets: ['dragonfly.voxguard-data:6380']

        - job_name: 'yugabyte'
          scrape_interval: 15s
          static_configs:
            - targets:
              - 'yb-master-0.yb-masters.voxguard-data:7000'
              - 'yb-tserver-0.yb-tservers.voxguard-data:9000'
```

### 7.3 Grafana Configuration

```yaml
# helm/observability/grafana-values.yaml
grafana:
  adminPassword: "${GRAFANA_ADMIN_PASSWORD}"
  persistence:
    enabled: true
    size: 10Gi
  resources:
    requests:
      cpu: "500m"
      memory: 1Gi
  datasources:
    datasources.yaml:
      apiVersion: 1
      datasources:
        - name: Prometheus
          type: prometheus
          url: http://prometheus-server.voxguard-observability:9090
          isDefault: true
          access: proxy
        - name: Loki
          type: loki
          url: http://loki.voxguard-observability:3100
          access: proxy
        - name: Tempo
          type: tempo
          url: http://tempo.voxguard-observability:3200
          access: proxy
          jsonData:
            tracesToLogs:
              datasourceUid: loki
              tags: ['service.name']
            serviceMap:
              datasourceUid: prometheus
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
        - name: 'voxguard'
          orgId: 1
          folder: 'VoxGuard'
          type: file
          disableDeletion: true
          editable: false
          options:
            path: /var/lib/grafana/dashboards/voxguard
```

### 7.4 Tempo Configuration

```yaml
# helm/observability/tempo-values.yaml
tempo:
  resources:
    requests:
      cpu: "500m"
      memory: 2Gi
  persistence:
    size: 50Gi
  config:
    server:
      http_listen_port: 3200
    distributor:
      receivers:
        otlp:
          protocols:
            grpc:
              endpoint: 0.0.0.0:4317
            http:
              endpoint: 0.0.0.0:4318
        jaeger:
          protocols:
            thrift_http:
              endpoint: 0.0.0.0:14268
            grpc:
              endpoint: 0.0.0.0:14250
    storage:
      trace:
        backend: local
        local:
          path: /var/tempo/traces
        block:
          bloom_filter_false_positive: 0.05
          index_downsample_bytes: 1000
          encoding: zstd
    compactor:
      compaction:
        block_retention: 168h  # 7 days
```

### 7.5 Loki Configuration

```yaml
# helm/observability/loki-values.yaml
loki:
  resources:
    requests:
      cpu: "500m"
      memory: 2Gi
  persistence:
    size: 100Gi
  config:
    auth_enabled: false
    server:
      http_listen_port: 3100
    ingester:
      lifecycler:
        ring:
          replication_factor: 1
      chunk_idle_period: 5m
      chunk_retain_period: 30s
    schema_config:
      configs:
        - from: 2026-01-01
          store: boltdb-shipper
          object_store: filesystem
          schema: v11
          index:
            prefix: index_
            period: 24h
    limits_config:
      retention_period: 720h  # 30 days
      max_query_length: 721h
      max_query_parallelism: 32
    compactor:
      retention_enabled: true
      retention_delete_delay: 2h
```

---

## 8. CI/CD Pipeline

### 8.1 Pipeline Architecture

```mermaid
flowchart LR
    subgraph Trigger["Triggers"]
        Push[Push to main]
        PR[Pull Request]
        Tag[Git Tag v*]
        Schedule[Daily Schedule]
    end

    subgraph Build["Build Stage"]
        Lint[Lint + Format]
        Test[Unit Tests]
        SAST[SAST Scan]
        SCA[Dependency Scan]
    end

    subgraph Package["Package Stage"]
        Docker_Build[Docker Build]
        Docker_Scan[Image Scan]
        Docker_Push[Push to Registry]
        Helm_Lint[Helm Lint]
        Helm_Package[Helm Package]
    end

    subgraph Deploy["Deploy Stage"]
        Dev[Dev Deploy<br>Auto]
        Staging[Staging Deploy<br>Auto on main]
        Prod[Production Deploy<br>Manual Approval]
    end

    subgraph Verify["Verify Stage"]
        Smoke[Smoke Tests]
        E2E[E2E Tests]
        DAST[DAST Scan]
    end

    Push --> Build
    PR --> Build
    Build --> Package
    Package --> Dev
    Dev --> Verify
    Tag --> Package
    Package --> Staging
    Staging --> Verify
    Verify --> Prod
```

### 8.2 GitHub Actions Workflow

```yaml
# .github/workflows/ci-cd.yml
name: VoxGuard CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  release:
    types: [published]

env:
  REGISTRY: ghcr.io
  IMAGE_PREFIX: ghcr.io/${{ github.repository_owner }}/voxguard

jobs:
  # ============================================
  # LINT AND TEST
  # ============================================
  lint-test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service:
          - { name: detection-engine, path: services/detection-engine, lang: rust }
          - { name: management-api, path: services/management-api, lang: go }
          - { name: ml-pipeline, path: services/ml-pipeline, lang: python }
          - { name: web-dashboard, path: packages/web, lang: node }
    steps:
      - uses: actions/checkout@v4

      - name: Lint (${{ matrix.service.lang }})
        run: |
          case "${{ matrix.service.lang }}" in
            rust)   cd ${{ matrix.service.path }} && cargo fmt --check && cargo clippy ;;
            go)     cd ${{ matrix.service.path }} && golangci-lint run ;;
            python) cd ${{ matrix.service.path }} && ruff check . && mypy src ;;
            node)   cd ${{ matrix.service.path }} && npm ci && npm run lint ;;
          esac

      - name: Test (${{ matrix.service.lang }})
        run: |
          case "${{ matrix.service.lang }}" in
            rust)   cd ${{ matrix.service.path }} && cargo test ;;
            go)     cd ${{ matrix.service.path }} && go test ./... -race -coverprofile=coverage.out ;;
            python) cd ${{ matrix.service.path }} && pytest --cov=src tests/ ;;
            node)   cd ${{ matrix.service.path }} && npm test -- --coverage ;;
          esac

  # ============================================
  # SECURITY SCANS
  # ============================================
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: SAST (Semgrep)
        uses: returntocorp/semgrep-action@v1
        with:
          config: >-
            p/owasp-top-ten
            p/rust
            p/golang
            p/python

      - name: Secret Scan (TruffleHog)
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          extra_args: --only-verified

      - name: Dependency Scan (Snyk)
        uses: snyk/actions/node@master
        with:
          command: test
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}

  # ============================================
  # BUILD AND PUSH IMAGES
  # ============================================
  build-images:
    needs: [lint-test, security-scan]
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service:
          - { name: detection-engine, dockerfile: infrastructure/docker/detection-engine/Dockerfile }
          - { name: management-api, dockerfile: infrastructure/docker/management-api/Dockerfile }
          - { name: ml-pipeline, dockerfile: infrastructure/docker/ml-pipeline/Dockerfile }
          - { name: web-dashboard, dockerfile: infrastructure/docker/web-dashboard/Dockerfile }
    steps:
      - uses: actions/checkout@v4

      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and Push
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ${{ matrix.service.dockerfile }}
          push: true
          tags: |
            ${{ env.IMAGE_PREFIX }}/${{ matrix.service.name }}:${{ github.sha }}
            ${{ env.IMAGE_PREFIX }}/${{ matrix.service.name }}:latest

      - name: Scan Image (Trivy)
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.IMAGE_PREFIX }}/${{ matrix.service.name }}:${{ github.sha }}
          format: 'sarif'
          output: 'trivy-${{ matrix.service.name }}.sarif'
          severity: 'CRITICAL,HIGH'

  # ============================================
  # DEPLOY TO STAGING
  # ============================================
  deploy-staging:
    needs: [build-images]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - uses: actions/checkout@v4

      - name: Configure kubectl
        uses: azure/k8s-set-context@v3
        with:
          kubeconfig: ${{ secrets.KUBE_CONFIG_STAGING }}

      - name: Deploy with Helm
        run: |
          helm upgrade --install voxguard ./infrastructure/helm/voxguard \
            --namespace voxguard-prod \
            --values ./infrastructure/helm/voxguard/values-staging.yaml \
            --set global.imageTag=${{ github.sha }} \
            --wait --timeout 10m

      - name: Run Smoke Tests
        run: |
          kubectl exec -n voxguard-prod deploy/management-api -- \
            curl -sf http://localhost:8081/health
          kubectl exec -n voxguard-prod deploy/detection-engine -- \
            curl -sf http://localhost:8080/health

  # ============================================
  # DEPLOY TO PRODUCTION (Manual Approval)
  # ============================================
  deploy-production:
    needs: [deploy-staging]
    if: github.event_name == 'release'
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://voxguard.ng
    steps:
      - uses: actions/checkout@v4

      - name: Configure kubectl
        uses: azure/k8s-set-context@v3
        with:
          kubeconfig: ${{ secrets.KUBE_CONFIG_PRODUCTION }}

      - name: Deploy with Helm (Rolling Update)
        run: |
          helm upgrade --install voxguard ./infrastructure/helm/voxguard \
            --namespace voxguard-prod \
            --values ./infrastructure/helm/voxguard/values-production.yaml \
            --set global.imageTag=${{ github.event.release.tag_name }} \
            --wait --timeout 15m

      - name: Verify Deployment
        run: |
          kubectl rollout status deployment/detection-engine -n voxguard-prod --timeout=300s
          kubectl rollout status deployment/management-api -n voxguard-prod --timeout=300s
```

---

## 9. Environment Matrix

### 9.1 Environment Overview

| Property | Development | Staging | Production |
|---|---|---|---|
| **Purpose** | Local development, feature testing | Pre-production validation | Live traffic |
| **Infrastructure** | Docker Compose | Kubernetes (single node) | Kubernetes (3+ nodes, multi-region) |
| **Replicas (Detection)** | 1 | 2 | 4-20 (HPA) |
| **Replicas (Management)** | 1 | 2 | 2-10 (HPA) |
| **Replicas (ML)** | 1 | 1 | 1-5 (HPA) |
| **DragonflyDB** | Single instance | Single instance | 3 nodes (Primary + 2 replicas) |
| **ClickHouse** | Single instance | Single shard | 3 shards, 2 replicas each |
| **YugabyteDB** | Single instance | 3 nodes (RF=3) | 3+ nodes (RF=3, geo-distributed) |
| **Hasura Console** | Enabled | Enabled | Disabled |
| **Debug Logging** | Enabled | Enabled | Disabled |
| **TLS** | Self-signed | Let's Encrypt (staging) | Let's Encrypt (production) |
| **Secrets** | `.env` file | K8s Secrets | Vault + ESO |
| **Domain** | localhost | staging.voxguard.ng | voxguard.ng |
| **NCC Integration** | Mock | NCC sandbox | NCC production |
| **Data** | Seed data | Synthetic load test data | Real production data |
| **Backups** | None | Daily | Daily + continuous WAL |
| **Monitoring** | Prometheus + Grafana (local) | Full stack | Full stack + PagerDuty |

### 9.2 Environment Promotion Flow

```mermaid
flowchart LR
    Dev[Development<br>Feature branches] -->|PR merge| Staging[Staging<br>main branch]
    Staging -->|Git tag + manual approval| Prod[Production<br>Release tags]
    Staging -->|Automated tests pass| Prod

    Dev -->|Docker Compose| LocalStack[Local Stack]
    Staging -->|Helm deploy| StagingK8s[Staging K8s]
    Prod -->|Helm deploy| ProdK8s[Production K8s<br>Lagos + Abuja + Asaba]
```

---

## 10. Secrets Management

### 10.1 Secrets Architecture

```mermaid
flowchart TB
    subgraph Vault["HashiCorp Vault (HA Cluster)"]
        KV[KV v2 Engine<br>Static secrets]
        Transit[Transit Engine<br>Encryption as a Service]
        DB[Database Engine<br>Dynamic credentials]
        PKI[PKI Engine<br>Certificate issuance]
    end

    subgraph K8s["Kubernetes"]
        ESO[External Secrets Operator]
        K8sSecrets[K8s Secrets]
        Pods[Application Pods]
    end

    Vault -->|Sync secrets| ESO
    ESO -->|Create/update| K8sSecrets
    K8sSecrets -->|Mount as env/file| Pods
    Pods -->|Direct API call| Vault
```

### 10.2 Vault Configuration

```hcl
# infrastructure/vault/vault.hcl
storage "raft" {
  path = "/opt/vault/data"
  node_id = "vault-1"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = false
  tls_cert_file = "/vault/tls/vault.crt"
  tls_key_file  = "/vault/tls/vault.key"
  tls_min_version = "tls13"
}

seal "awskms" {
  region     = "af-south-1"
  kms_key_id = "arn:aws:kms:af-south-1:ACCOUNT:key/KEY_ID"
}

api_addr     = "https://vault.voxguard-security:8200"
cluster_addr = "https://vault.voxguard-security:8201"

ui = false
```

### 10.3 Vault Policies

```hcl
# policies/voxguard-detection-engine.hcl
path "secret/data/dragonfly/*" {
  capabilities = ["read"]
}

path "secret/data/clickhouse/*" {
  capabilities = ["read"]
}

path "database/creds/detection-engine" {
  capabilities = ["read"]
}

path "transit/encrypt/voxguard-pii" {
  capabilities = ["update"]
}

path "transit/decrypt/voxguard-pii" {
  capabilities = ["update"]
}
```

```hcl
# policies/voxguard-management-api.hcl
path "secret/data/jwt/*" {
  capabilities = ["read"]
}

path "secret/data/ncc/*" {
  capabilities = ["read"]
}

path "database/creds/management-api" {
  capabilities = ["read"]
}

path "transit/encrypt/voxguard-*" {
  capabilities = ["update"]
}

path "transit/decrypt/voxguard-*" {
  capabilities = ["update"]
}
```

### 10.4 External Secrets Operator

```yaml
# External Secrets Store (connects to Vault)
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: voxguard-prod
spec:
  provider:
    vault:
      server: "https://vault.voxguard-security:8200"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "voxguard-prod"
          serviceAccountRef:
            name: voxguard-sa

---
# External Secret definition
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: detection-engine-secrets
  namespace: voxguard-prod
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: detection-engine-secrets
    creationPolicy: Owner
  data:
    - secretKey: DRAGONFLY_PASSWORD
      remoteRef:
        key: secret/dragonfly/credentials
        property: password
    - secretKey: YUGABYTE_PASSWORD
      remoteRef:
        key: secret/yugabyte/detection-engine
        property: password
    - secretKey: CLICKHOUSE_PASSWORD
      remoteRef:
        key: secret/clickhouse/detection-engine
        property: password

---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: management-api-secrets
  namespace: voxguard-prod
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: management-api-secrets
    creationPolicy: Owner
  data:
    - secretKey: JWT_PRIVATE_KEY
      remoteRef:
        key: secret/jwt/signing-key
        property: private_key
    - secretKey: JWT_PUBLIC_KEY
      remoteRef:
        key: secret/jwt/signing-key
        property: public_key
    - secretKey: YUGABYTE_PASSWORD
      remoteRef:
        key: secret/yugabyte/management-api
        property: password
    - secretKey: NCC_CLIENT_ID
      remoteRef:
        key: secret/ncc/credentials
        property: client_id
    - secretKey: NCC_CLIENT_SECRET
      remoteRef:
        key: secret/ncc/credentials
        property: client_secret
    - secretKey: HASURA_ADMIN_SECRET
      remoteRef:
        key: secret/hasura/admin
        property: secret
```

### 10.5 Secrets Inventory

| Secret | Vault Path | Rotation | Used By |
|---|---|---|---|
| JWT Signing Key (RSA) | `secret/jwt/signing-key` | 90 days | Management API |
| DragonflyDB Password | `secret/dragonfly/credentials` | 90 days | Detection Engine, ML Pipeline |
| YugabyteDB Credentials | `database/creds/{service}` | 1 hour (dynamic) | All services |
| ClickHouse Password | `secret/clickhouse/{service}` | 90 days | Detection Engine, ML Pipeline |
| NCC API Credentials | `secret/ncc/credentials` | Manual (per NCC) | Management API |
| NCC SFTP Key | `secret/ncc/sftp-key` | Annual | Management API |
| Hasura Admin Secret | `secret/hasura/admin` | 90 days | Hasura |
| Grafana Admin Password | `secret/grafana/admin` | 90 days | Grafana |
| S3 Archive Credentials | `secret/s3/archival` | 90 days | Data Archival Service |
| PII Encryption Key | `transit/keys/voxguard-pii` | Automatic (Vault manages) | All services |

---

## 11. Disaster Recovery Infrastructure

### 11.1 DR Architecture

```mermaid
flowchart TB
    subgraph Primary["Lagos (Primary)"]
        P_K8s[Kubernetes Cluster]
        P_DF[DragonflyDB Primary]
        P_YB[YugabyteDB Leaders]
        P_CH[ClickHouse Shards 1-2]
        P_Vault[Vault Primary]
        P_S3[S3 Primary Bucket]
    end

    subgraph DR["Abuja (DR)"]
        DR_K8s[Kubernetes Cluster]
        DR_DF[DragonflyDB Replica]
        DR_YB[YugabyteDB Followers]
        DR_CH[ClickHouse Shard 3]
        DR_Vault[Vault Replica]
        DR_S3[S3 Cross-Region Replica]
    end

    P_DF -->|Real-time replication| DR_DF
    P_YB -->|Raft consensus| DR_YB
    P_Vault -->|Raft replication| DR_Vault
    P_S3 -->|S3 Cross-Region Replication| DR_S3
```

### 11.2 Backup Schedule

| Data | Method | Frequency | Retention | Storage |
|---|---|---|---|---|
| YugabyteDB | Full snapshot + WAL | Daily full + continuous WAL | 30 days hot, 1 year warm | S3 |
| ClickHouse | Partition backup | Weekly full, daily incremental | 30 days | S3 |
| DragonflyDB | RDB snapshot | Every 60 seconds (if 1000+ changes) | 7 days | Local + S3 |
| Vault | Raft snapshot | Daily | 30 days | S3 (encrypted) |
| Hasura Metadata | Git export | Every deploy | Git history | GitHub |
| Kubernetes State | etcd snapshot | Daily | 30 days | S3 |

### 11.3 Recovery Objectives

| Metric | Target | Test Frequency |
|---|---|---|
| RPO (Recovery Point Objective) | < 1 minute | Monthly |
| RTO (Recovery Time Objective) | < 15 minutes | Quarterly |
| Failover Time | < 30 seconds (auto) | Monthly |
| Data Integrity | 100% (no data loss) | Monthly |

### 11.4 Failover Procedure

```
1. DNS Failover (Automated - 30 seconds)
   - GeoDNS detects Lagos health check failure
   - Traffic rerouted to Abuja

2. Database Promotion (Automated - 60 seconds)
   - YugabyteDB: Raft consensus elects new leader in Abuja
   - DragonflyDB: Replica promoted to primary
   - ClickHouse: Abuja shard becomes active

3. Application Scaling (Automated - 120 seconds)
   - Abuja HPA scales Detection Engine from 2 -> 8 replicas
   - Management API scales from 1 -> 3 replicas

4. Verification (Manual - 5 minutes)
   - Verify all health checks pass
   - Verify detection engine processing events
   - Verify Grafana dashboards showing traffic
   - Verify NCC reporting functional
```

---

## AIDD Compliance Notes

This document is classified as **Tier 0 (Auto-Approve / Read-Only)** under the VoxGuard AIDD framework. Infrastructure changes are classified as follows:

- **Tier 0:** Reading documentation, viewing dashboards
- **Tier 1:** Scaling replicas, updating ConfigMaps, deploying to staging
- **Tier 2:** Production deployments, database migrations, secret rotation, network policy changes, Vault operations

---

**Document Version:** 1.0
**Classification:** Technical -- Internal
**Review Cycle:** Quarterly
**Next Review:** May 2026
**Owner:** VoxGuard Platform Engineering Team
