# GitHub Web Upload Guide

## Uploading Anti-Call Masking Platform to GitHub

This guide explains how to upload the project files to https://github.com/abiolaogu/Anti_Call-Masking using the GitHub web interface.

---

## Complete File List (Verified)

Here are all the files that need to be uploaded:

```
anti-call-masking-platform/
├── README.md
├── database/
│   ├── clickhouse/
│   │   └── 001_initial_schema.sql
│   └── yugabyte/
│       └── 001_initial_schema.sql
├── deployment/
│   ├── docker/
│   │   └── docker-compose.yml
│   └── kubernetes/
│       └── detection-engine.yaml
├── detection-engine/
│   ├── Cargo.toml
│   ├── Dockerfile
│   └── src/
│       ├── lib.rs
│       ├── main.rs
│       ├── cache/
│       │   └── mod.rs
│       ├── config/
│       │   └── mod.rs
│       ├── db/
│       │   └── mod.rs
│       ├── detection/
│       │   └── mod.rs
│       ├── handlers/
│       │   ├── mod.rs
│       │   ├── alerts.rs
│       │   ├── blacklist.rs
│       │   ├── detection.rs
│       │   ├── gateway.rs
│       │   ├── health.rs
│       │   ├── metrics.rs
│       │   ├── mnp.rs
│       │   └── websocket.rs
│       ├── metrics/
│       │   └── mod.rs
│       ├── models/
│       │   └── mod.rs
│       ├── questdb/
│       │   └── mod.rs          ← NEW: QuestDB client (replaces kdb+)
│       └── reporting/
│           └── mod.rs
├── docs/
│   └── GITHUB_UPLOAD_GUIDE.md
├── management-api/
│   ├── Dockerfile
│   ├── go.mod
│   ├── main.go
│   ├── cmd/
│   │   └── server/
│   │       └── main.go
│   └── internal/
│       ├── config/
│       │   └── config.go
│       ├── database/
│       │   └── database.go
│       ├── middleware/
│       │   └── middleware.go
│       ├── models/
│       │   └── models.go
│       └── services/
│           └── services.go
├── monitoring/
│   ├── grafana/
│   │   ├── dashboards/
│   │   │   └── fraud-detection.json
│   │   └── provisioning/
│   │       ├── dashboards/
│   │       │   └── dashboards.yml
│   │       └── datasources/
│   │           └── datasources.yml
│   └── prometheus/
│       ├── prometheus.yml
│       └── alerts/
│           └── acm_alerts.yml
├── ncc-compliance/
│   └── sftp-uploader/
│       ├── Dockerfile
│       └── daily_upload.sh
├── opensips-integration/
│   └── opensips-acm.cfg
├── scripts/
│   ├── init-clickhouse.sh
│   ├── init-yugabyte.sh
│   └── seed-nigerian-prefixes.sh
└── stress-testing/
    └── sipp/
        ├── calls.csv
        ├── nigerian_icl.xml
        └── run_stress_test.sh
```

**Total: 51 files**

---

## Method 1: Git CLI (RECOMMENDED - Fastest)

This is the fastest and most reliable method.

### Step 1: Clone Your Repository
```bash
git clone https://github.com/abiolaogu/Anti_Call-Masking.git
cd Anti_Call-Masking
```

### Step 2: Download and Extract Files
Download the `anti-call-masking-platform` folder from Claude's response, then copy all contents:

```bash
# If downloaded as zip, extract first
unzip anti-call-masking-platform.zip

# Copy all files to the cloned repo (overwrites existing)
cp -r anti-call-masking-platform/* .
```

### Step 3: Commit and Push
```bash
git add .
git commit -m "Add production ACM platform with QuestDB analytics

Features:
- Rust detection engine (<1ms latency, 150K CPS)
- QuestDB for real-time time-series (replaces kdb+)
- OpenSIPS integration with fraud detection
- YugabyteDB for MNP and persistence
- ClickHouse for historical analytics
- NCC compliance (ATRS API + SFTP)
- Docker Compose and Kubernetes deployments
- Go Management API
- Prometheus/Grafana monitoring"

git push origin main
```

---

## Method 2: GitHub Web Interface (Step-by-Step)

If you don't have Git installed, use the GitHub web interface.

### Understanding GitHub Web Limitations
- GitHub web can upload files but **not folders directly**
- To create nested folders, include the path in the filename
- Maximum 100 files per upload
- Maximum 25MB per file

### Step-by-Step Upload Process

#### Phase 1: Upload Root Files
1. Go to https://github.com/abiolaogu/Anti_Call-Masking
2. Click **"Add file"** → **"Upload files"**
3. Upload: `README.md`
4. Commit message: "Update README with QuestDB architecture"
5. Click **"Commit changes"**

#### Phase 2: Upload Database Schemas
1. Click **"Add file"** → **"Create new file"**
2. In filename, type: `database/yugabyte/001_initial_schema.sql`
3. Paste the SQL content
4. Commit message: "Add YugabyteDB schema"
5. Repeat for: `database/clickhouse/001_initial_schema.sql`

#### Phase 3: Upload Detection Engine (Rust)

**Root files:**
1. Create: `detection-engine/Cargo.toml` (paste content)
2. Create: `detection-engine/Dockerfile` (paste content)

**Source files:**
1. Create: `detection-engine/src/lib.rs`
2. Create: `detection-engine/src/main.rs`
3. Create: `detection-engine/src/cache/mod.rs`
4. Create: `detection-engine/src/config/mod.rs`
5. Create: `detection-engine/src/db/mod.rs`
6. Create: `detection-engine/src/detection/mod.rs`
7. Create: `detection-engine/src/handlers/mod.rs`
8. Create: `detection-engine/src/handlers/alerts.rs`
9. Create: `detection-engine/src/handlers/blacklist.rs`
10. Create: `detection-engine/src/handlers/detection.rs`
11. Create: `detection-engine/src/handlers/gateway.rs`
12. Create: `detection-engine/src/handlers/health.rs`
13. Create: `detection-engine/src/handlers/metrics.rs`
14. Create: `detection-engine/src/handlers/mnp.rs`
15. Create: `detection-engine/src/handlers/websocket.rs`
16. Create: `detection-engine/src/metrics/mod.rs`
17. Create: `detection-engine/src/models/mod.rs`
18. Create: `detection-engine/src/questdb/mod.rs` ← **QuestDB client**
19. Create: `detection-engine/src/reporting/mod.rs`

#### Phase 4: Upload Management API (Go)
1. Create: `management-api/Dockerfile`
2. Create: `management-api/go.mod`
3. Create: `management-api/main.go`
4. Create: `management-api/cmd/server/main.go`
5. Create: `management-api/internal/config/config.go`
6. Create: `management-api/internal/database/database.go`
7. Create: `management-api/internal/middleware/middleware.go`
8. Create: `management-api/internal/models/models.go`
9. Create: `management-api/internal/services/services.go`

#### Phase 5: Upload Deployment Files
1. Create: `deployment/docker/docker-compose.yml` ← **Includes QuestDB**
2. Create: `deployment/kubernetes/detection-engine.yaml`

#### Phase 6: Upload Monitoring Configuration
1. Create: `monitoring/prometheus/prometheus.yml`
2. Create: `monitoring/prometheus/alerts/acm_alerts.yml`
3. Create: `monitoring/grafana/dashboards/fraud-detection.json`
4. Create: `monitoring/grafana/provisioning/dashboards/dashboards.yml`
5. Create: `monitoring/grafana/provisioning/datasources/datasources.yml`

#### Phase 7: Upload OpenSIPS Configuration
1. Create: `opensips-integration/opensips-acm.cfg`

#### Phase 8: Upload Scripts
1. Create: `scripts/init-yugabyte.sh`
2. Create: `scripts/init-clickhouse.sh`
3. Create: `scripts/seed-nigerian-prefixes.sh`

#### Phase 9: Upload NCC Compliance
1. Create: `ncc-compliance/sftp-uploader/Dockerfile`
2. Create: `ncc-compliance/sftp-uploader/daily_upload.sh`

#### Phase 10: Upload Stress Testing
1. Create: `stress-testing/sipp/nigerian_icl.xml`
2. Create: `stress-testing/sipp/calls.csv`
3. Create: `stress-testing/sipp/run_stress_test.sh`

---

## Method 3: GitHub Desktop (Visual)

1. Download [GitHub Desktop](https://desktop.github.com/)
2. Sign in with your GitHub account
3. Clone: `https://github.com/abiolaogu/Anti_Call-Masking`
4. Open the cloned folder in your file explorer
5. Copy all files from the downloaded `anti-call-masking-platform` folder
6. Return to GitHub Desktop - it shows all changed files
7. Write commit message: "Add production ACM platform with QuestDB"
8. Click **"Commit to main"**
9. Click **"Push origin"**

---

## Verification After Upload

After uploading, verify these key files exist:

### Must-Have Files:
- [ ] `README.md` - Updated with QuestDB architecture
- [ ] `detection-engine/src/questdb/mod.rs` - QuestDB client
- [ ] `deployment/docker/docker-compose.yml` - Has QuestDB service
- [ ] `detection-engine/Cargo.toml` - Has `sqlx` dependency

### Test the Setup:
```bash
# Clone fresh
git clone https://github.com/abiolaogu/Anti_Call-Masking.git
cd Anti_Call-Masking

# Verify Docker Compose is valid
docker-compose -f deployment/docker/docker-compose.yml config

# Start services
docker-compose -f deployment/docker/docker-compose.yml up -d

# Check services
docker-compose -f deployment/docker/docker-compose.yml ps
```

### Expected Services Running:
- `acm-engine` (Rust detection) - Port 8080
- `questdb` - Ports 9009, 8812, 9000
- `dragonfly` - Port 6379
- `yugabyte` - Port 5433
- `clickhouse` - Port 8123
- `management-api` (Go) - Port 8081
- `prometheus` - Port 9091
- `grafana` - Port 3000

---

## QuestDB Access After Deployment

### Web Console (SQL queries):
```
http://localhost:9000
```

### PostgreSQL Wire Protocol:
```
Host: localhost
Port: 8812
User: admin
Password: quest
Database: qdb
```

### InfluxDB Line Protocol (high-speed ingestion):
```
Host: localhost
Port: 9009
```

---

## Troubleshooting

### "File already exists" error
- Edit the existing file instead of creating new
- Or delete the old file first, then create new

### Nested folder not created
- Make sure to include the full path in the filename
- Example: `detection-engine/src/questdb/mod.rs` creates all folders

### Push rejected
- Pull latest changes first: `git pull origin main`
- Then push again: `git push origin main`

### Docker Compose errors
- Ensure all paths in `docker-compose.yml` are correct
- Check that schema files exist in `database/` folder

---

## Quick Reference: Key QuestDB Files

| File | Purpose |
|------|---------|
| `detection-engine/src/questdb/mod.rs` | QuestDB Rust client |
| `detection-engine/src/lib.rs` | Exports questdb module |
| `detection-engine/Cargo.toml` | Has sqlx dependency |
| `deployment/docker/docker-compose.yml` | QuestDB service definition |
| `README.md` | Architecture diagram with QuestDB |

---

## Support

If you encounter issues:
1. Check file paths match exactly
2. Verify all 51 files are uploaded
3. Test with `docker-compose config` before starting services
