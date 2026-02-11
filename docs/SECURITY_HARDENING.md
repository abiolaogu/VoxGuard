# VoxGuard Security Hardening Guide

**Version:** 1.0.0
**Date:** 2026-02-03
**Status:** Production-Ready
**Compliance:** NCC ICL Framework 2026, ISO 27001

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication & Authorization](#authentication--authorization)
3. [Secrets Management](#secrets-management)
4. [Audit Logging](#audit-logging)
5. [Network Security](#network-security)
6. [Database Security](#database-security)
7. [Deployment Security](#deployment-security)
8. [Incident Response](#incident-response)

---

## Overview

This document describes the security hardening implementation for VoxGuard, covering authentication, authorization, secrets management, and audit logging in compliance with NCC ICL Framework 2026 requirements.

### Security Objectives

- **Authentication:** RS256 JWT with refresh tokens and MFA support
- **Authorization:** Fine-grained RBAC with policy-based access control
- **Secrets Management:** HashiCorp Vault integration for all sensitive data
- **Audit Logging:** Immutable audit trail with 7-year retention
- **Compliance:** NCC ICL Framework, GDPR, ISO 27001 alignment

### Threat Model

**Assets Protected:**
- User credentials and authentication tokens
- NCC API credentials and SFTP keys
- Database credentials
- Fraud detection algorithms and ML models
- Call Detail Records (CDRs) and audit logs

**Threat Actors:**
- External attackers attempting unauthorized access
- Malicious insiders with legitimate credentials
- Compromised service accounts
- Advanced Persistent Threats (APTs)

---

## Authentication & Authorization

### JWT Authentication (RS256)

VoxGuard uses RS256 (RSA Signature with SHA-256) for JWT signing, providing asymmetric cryptography benefits:

**Key Management:**
```bash
# Keys are stored in HashiCorp Vault
vault kv get secret/jwt/signing-key

# Rotate keys every 90 days
vault kv put secret/jwt/signing-key \
  private_key="$(cat new-private-key.pem)" \
  public_key="$(cat new-public-key.pem)" \
  created_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

**Token Structure:**
```json
{
  "user_id": "uuid",
  "username": "string",
  "email": "string",
  "roles": ["admin", "operator"],
  "permissions": ["gateway:read", "gateway:write"],
  "token_type": "access",
  "iat": 1706961600,
  "exp": 1706965200,
  "nbf": 1706961600,
  "iss": "voxguard-management-api",
  "sub": "user_id",
  "jti": "unique-token-id"
}
```

**Token Lifetime:**
- Access Token: 15 minutes
- Refresh Token: 7 days
- API Key: Configurable (default: 90 days)

**Implementation:**
```go
// services/management-api/internal/domain/security/service/auth_service.go
service := NewAuthService(repo, auditService, vaultClient, logger, config)
response, err := service.Login(ctx, loginRequest, ipAddr, userAgent)
```

### Role-Based Access Control (RBAC)

**System Roles:**

| Role | Description | Permissions |
|------|-------------|-------------|
| `superadmin` | Full system access | All permissions |
| `admin` | Administrative access | User management, gateway config, fraud alerts |
| `operator` | Operational access | Gateway management, alert handling |
| `analyst` | Analysis and reporting | Read-only access to alerts and reports |
| `auditor` | Compliance and audit | Read-only access to audit logs |
| `readonly` | View-only access | Read-only access to all resources |

**Permission Format:**
```
resource:action
Examples:
  - gateway:read
  - gateway:write
  - fraud_alert:approve
  - user:create
  - audit:read
```

**Fine-Grained Permissions:**
```sql
SELECT id, resource, action, display_name FROM permissions;

-- Examples:
-- gateway:read       - View gateways
-- gateway:create     - Create new gateways
-- gateway:update     - Modify gateways
-- gateway:delete     - Delete gateways
-- fraud_alert:read   - View fraud alerts
-- fraud_alert:update - Acknowledge/update alerts
-- fraud_alert:approve - Resolve fraud alerts
-- user:read          - View users
-- user:create        - Create users
-- compliance:export  - Export compliance reports
-- audit:read         - View audit logs
```

**Policy-Based Access Control (PBAC):**
```json
{
  "resource": "fraud_alert",
  "action": "approve",
  "effect": "allow",
  "conditions": {
    "severity": {"$in": ["medium", "high"]},
    "user_department": "fraud_ops"
  },
  "priority": 10
}
```

**Usage:**
```go
// Check access
result, err := rbacService.CheckAccess(ctx, entity.AccessCheck{
    UserID:   userID,
    Resource: "gateway",
    Action:   "write",
    Context: map[string]interface{}{
        "gateway_type": "international",
    },
})

if !result.Allowed {
    return errors.New("access denied: " + result.Reason)
}
```

### Multi-Factor Authentication (MFA)

**TOTP-Based MFA:**
```go
// Enable MFA for user
secret, qrCode, err := authService.EnableMFA(ctx, userID)

// Verify MFA code
valid := authService.VerifyMFACode(secret, code)
```

**MFA Enforcement:**
- Required for `superadmin` and `admin` roles
- Optional for other roles (recommended)
- 6-digit TOTP codes (30-second window)
- Backup codes generated during setup

### Account Lockout Policy

**Failed Login Protection:**
- Maximum attempts: 5
- Lockout duration: 30 minutes
- Automatic unlock after lockout period
- Security event logged for excessive attempts

**Implementation:**
```sql
-- Lockout trigger
UPDATE users SET
    is_locked = true,
    locked_until = NOW() + INTERVAL '30 minutes'
WHERE id = $1 AND login_attempts >= 5;
```

### Password Policy

**Requirements:**
- Minimum length: 12 characters
- Must contain: uppercase, lowercase, number, special character
- Password history: Last 5 passwords cannot be reused
- Maximum age: 90 days (configurable)
- No common passwords (dictionary check)

**Implementation:**
```go
func (s *AuthService) validatePassword(password string) error {
    if len(password) < 12 {
        return errors.New("password must be at least 12 characters")
    }
    // Check complexity requirements...
}
```

---

## Secrets Management

### HashiCorp Vault Integration

**Vault Architecture:**
```
┌─────────────────────────────────────────┐
│         VoxGuard Management API         │
│  ┌────────────────────────────────────┐ │
│  │      Vault Client Service          │ │
│  └────────────────────────────────────┘ │
└──────────────────┬──────────────────────┘
                   │ TLS 1.3
                   │ Token Auth
                   ▼
┌─────────────────────────────────────────┐
│        HashiCorp Vault Cluster          │
│  ┌──────────┐  ┌──────────┐            │
│  │ KV Store │  │ Transit  │  Database  │
│  │  (v2)    │  │ Engine   │  Engine    │
│  └──────────┘  └──────────┘            │
└─────────────────────────────────────────┘
```

**Secrets Stored in Vault:**
- JWT signing keys (RSA 2048-bit)
- NCC API credentials (client ID, secret, SFTP keys)
- Database credentials (dynamic, rotated hourly)
- Encryption keys for sensitive data
- Third-party API keys

**Vault Configuration:**
```hcl
# infrastructure/vault/vault.hcl
storage "postgresql" {
  connection_url = "postgres://vault:PASSWORD@yugabyte:5433/vault_db"
  ha_enabled     = "true"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = "false"
  tls_cert_file = "/vault/config/tls/vault.crt"
  tls_key_file  = "/vault/config/tls/vault.key"
  tls_min_version = "tls13"
}
```

**Dynamic Database Credentials:**
```go
// Get short-lived database credentials
creds, err := vaultClient.GetDatabaseCredentials(ctx, "voxguard-app")
// Returns: username, password, lease_id (valid for 1 hour)

// Renew lease before expiration
err = vaultClient.RenewDatabaseLease(ctx, creds.LeaseID)
```

**Secret Rotation:**
- JWT keys: 90 days
- Database credentials: 1 hour (dynamic)
- NCC credentials: Manual rotation (as required by NCC)
- API keys: 90 days (configurable)

### Vault Policies

**Application Policy:**
```hcl
# policies/voxguard-app-policy.hcl
path "secret/data/jwt/*" {
  capabilities = ["read"]
}

path "database/creds/voxguard-app" {
  capabilities = ["read"]
}

path "transit/encrypt/voxguard-*" {
  capabilities = ["update"]
}
```

**Deployment:**
```bash
# Apply policy
vault policy write voxguard-app policies/voxguard-app-policy.hcl

# Create token with policy
vault token create -policy=voxguard-app -ttl=720h
```

### Environment Variables

**Never store secrets in environment variables in production:**

```bash
# ❌ BAD - Secrets in environment
export JWT_SECRET="my-secret-key"
export DATABASE_PASSWORD="password123"

# ✅ GOOD - Vault references
export VAULT_ADDR="https://vault:8200"
export VAULT_TOKEN="s.XXXXXXXXXXXXXXXXXXXX"
```

**Application reads from Vault:**
```go
jwtKeys, err := vaultClient.GetJWTSigningKey(ctx)
nccCreds, err := vaultClient.GetNCCCredentials(ctx)
dbCreds, err := vaultClient.GetDatabaseCredentials(ctx, "voxguard-app")
```

---

## Audit Logging

### Immutable Audit Trail

**Compliance Requirement:** NCC ICL Framework mandates 7-year audit retention.

**Implementation:**
- Append-only database table with triggers preventing updates/deletes
- All sensitive operations logged automatically
- Logs include: who, what, when, where, status, old/new values
- Partitioned by month for performance
- Archived to cold storage annually

**Audit Event Structure:**
```go
type AuditEvent struct {
    ID              string    // UUID
    Timestamp       time.Time
    UserID          string
    Username        string
    Action          string    // create, update, delete, login, export
    ResourceType    string    // user, gateway, fraud_alert
    ResourceID      string
    ResourceName    string
    OldValues       string    // JSON of previous state
    NewValues       string    // JSON of new state
    Status          string    // success or failure
    Severity        string    // low, medium, high, critical
    IPAddress       string
    UserAgent       string
    RequestID       string
    ErrorMessage    string
    Metadata        string    // Additional context (JSON)
    ComplianceFlags string    // NCC, GDPR, ISO27001
}
```

**Database Protection:**
```sql
-- Trigger prevents modifications
CREATE TRIGGER audit_events_immutable
    BEFORE UPDATE OR DELETE ON audit_events
    FOR EACH ROW
    EXECUTE FUNCTION prevent_audit_modifications();

-- Function raises exception
CREATE OR REPLACE FUNCTION prevent_audit_modifications()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Audit events are immutable';
END;
$$ LANGUAGE plpgsql;
```

**Usage:**
```go
// Automatic logging via middleware
auditService.LogEvent(ctx, entity.AuditEvent{
    UserID:       userID,
    Action:       "update",
    ResourceType: "gateway",
    ResourceID:   gatewayID,
    OldValues:    oldJSON,
    NewValues:    newJSON,
    Status:       entity.StatusSuccess,
    Severity:     entity.SeverityMedium,
})
```

**Actions Logged:**
- Authentication events (login, logout, MFA)
- User management (create, update, delete, role assignment)
- Gateway operations (create, update, delete, blacklist)
- Fraud alert actions (acknowledge, resolve, export)
- Configuration changes
- Data exports
- API key operations
- Policy changes

### Query and Export

**Query Audit Logs:**
```go
events, total, err := auditService.QueryAuditLogs(ctx, entity.AuditFilter{
    UserID:    "user-uuid",
    Action:    "delete",
    StartTime: time.Now().AddDate(0, 0, -30),
    EndTime:   time.Now(),
}, page, pageSize)
```

**Export for Compliance:**
```go
// Export to JSON or CSV
data, err := auditService.ExportAuditLogs(ctx, filter, "json")

// Generate compliance report
report, err := auditService.GenerateComplianceReport(ctx, startDate, endDate)
```

**Audit Statistics:**
```go
stats, err := auditService.GetAuditStats(ctx, startTime, endTime)
// Returns: total events, events by action, by resource, by severity, failure rate
```

### Retention and Archival

**Retention Policy:**
- Hot storage (database): 1 year
- Warm storage (compressed): 3 years
- Cold storage (S3 Glacier): 7 years (minimum)
- After 7 years: Legal review required before deletion

**Archival Process:**
```go
// Run monthly job
err := auditService.ArchiveOldLogs(ctx, 7) // 7 years retention

// Exports to JSON, compresses, uploads to S3/Glacier
// Maintains tamper-proof hash chain
```

---

## Network Security

### TLS Configuration

**Requirements:**
- TLS 1.3 only (1.2 minimum for legacy clients)
- Strong cipher suites only
- Perfect Forward Secrecy (PFS)
- HSTS headers
- Certificate pinning for critical services

**Nginx Configuration:**
```nginx
ssl_protocols TLSv1.3 TLSv1.2;
ssl_ciphers 'TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:ECDHE-RSA-AES256-GCM-SHA384';
ssl_prefer_server_ciphers on;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

### Firewall Rules

**Ingress:**
- Allow HTTPS (443) from internet
- Allow SSH (22) from bastion host only
- Allow PostgreSQL (5433) from application subnet only
- Deny all other inbound traffic

**Egress:**
- Allow HTTPS (443) to NCC API endpoints
- Allow SFTP (22) to NCC SFTP server
- Allow DNS (53) to DNS servers
- Deny all other outbound traffic by default

### Rate Limiting

**API Rate Limits:**
```go
// middleware.go - RateLimiter
// 100 requests per minute per user
// 1000 requests per minute per IP (burst)
```

**DDoS Protection:**
- CloudFlare or AWS Shield
- WAF rules for common attack patterns
- Geographic filtering if applicable

---

## Database Security

### Encryption

**At Rest:**
- YugabyteDB native encryption (AES-256)
- Vault-managed encryption keys
- Encrypted backups

**In Transit:**
- TLS 1.3 for all database connections
- Certificate-based authentication

**Column-Level Encryption:**
```sql
-- Sensitive fields encrypted via Vault Transit engine
-- Example: MFA secrets, API keys
INSERT INTO users (mfa_secret) VALUES (
    vault_encrypt('transit/encrypt/voxguard-data', 'SECRET_VALUE')
);
```

### Access Control

**Principle of Least Privilege:**
```sql
-- Application user has limited permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON users, gateways TO voxguard_app;
GRANT SELECT, INSERT ON audit_events TO voxguard_app; -- No UPDATE/DELETE

-- Read-only user for analytics
GRANT SELECT ON ALL TABLES TO voxguard_readonly;

-- Admin user for migrations only
GRANT ALL PRIVILEGES ON DATABASE acm_db TO voxguard_admin;
```

### Connection Pooling

**pgxpool Configuration:**
```go
config.MaxConns = 50
config.MinConns = 10
config.MaxConnLifetime = time.Hour
config.MaxConnIdleTime = 30 * time.Minute
config.HealthCheckPeriod = 30 * time.Second
```

### Backup and Recovery

**Backup Strategy:**
- Full backup: Daily at 02:00 UTC
- Incremental backup: Every 6 hours
- Transaction logs: Continuous archival
- Retention: 30 days (hot), 1 year (warm), 7 years (cold)
- Encryption: AES-256
- Off-site replication: 3 availability zones

**Disaster Recovery:**
- RPO (Recovery Point Objective): 1 hour
- RTO (Recovery Time Objective): 4 hours
- Regular restore testing: Monthly

---

## Deployment Security

### Container Security

**Base Images:**
- Use minimal base images (Alpine, Distroless)
- No root user in containers
- Regular vulnerability scanning

**Docker Security:**
```dockerfile
# Non-root user
RUN addgroup -g 1000 voxguard && \
    adduser -D -u 1000 -G voxguard voxguard
USER voxguard

# Read-only root filesystem
docker run --read-only --tmpfs /tmp ...

# Resource limits
docker run --memory="512m" --cpus="1.0" ...
```

### Kubernetes Security

**Pod Security Standards:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: voxguard-api
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
  containers:
  - name: api
    securityContext:
      readOnlyRootFilesystem: true
      allowPrivilegeEscalation: false
      capabilities:
        drop:
          - ALL
```

**Network Policies:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: voxguard-api-policy
spec:
  podSelector:
    matchLabels:
      app: voxguard-api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: nginx-ingress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: yugabyte
    ports:
    - protocol: TCP
      port: 5433
```

### Secrets Management in K8s

**External Secrets Operator:**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: voxguard-secrets
spec:
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: voxguard-secrets
  data:
  - secretKey: jwt-private-key
    remoteRef:
      key: secret/jwt/signing-key
      property: private_key
```

---

## Incident Response

### Security Event Detection

**Automated Alerts:**
- Multiple failed login attempts
- Privilege escalation attempts
- Unusual data access patterns
- Configuration changes
- Policy violations

**Security Event Types:**
```go
const (
    EventBruteForce       = "brute_force_attempt"
    EventAccountLocked    = "account_locked"
    EventPrivilegeEscalation = "privilege_escalation"
    EventDataExfiltration = "data_exfiltration"
    EventPolicyViolation  = "policy_violation"
    EventUnusualAccess    = "unusual_access_pattern"
)
```

### Incident Response Workflow

**1. Detection**
- Security event logged automatically
- Alert triggered if severity is HIGH or CRITICAL
- On-call engineer notified via PagerDuty/Opsgenie

**2. Triage**
- Review security event details
- Check related audit logs
- Assess scope and impact

**3. Containment**
- Revoke compromised credentials
- Lock affected user accounts
- Block suspicious IP addresses
- Isolate affected systems

**4. Investigation**
- Collect forensic data
- Analyze attack vector
- Identify root cause

**5. Recovery**
- Restore from clean backup if needed
- Reset compromised credentials
- Apply security patches

**6. Post-Incident**
- Document findings
- Update security policies
- Conduct post-mortem
- Implement preventive measures

### Emergency Procedures

**Revoke All Tokens:**
```sql
-- Emergency: Revoke all refresh tokens
UPDATE refresh_tokens SET is_revoked = true, revoked_at = NOW();

-- Or for specific user
UPDATE refresh_tokens SET is_revoked = true
WHERE user_id = 'compromised-user-id';
```

**Lock All Accounts:**
```sql
-- Emergency: Lock all non-admin accounts
UPDATE users SET is_locked = true, locked_until = NOW() + INTERVAL '24 hours'
WHERE id NOT IN (SELECT user_id FROM user_roles WHERE role_id = 'superadmin-role-id');
```

**Vault Seal:**
```bash
# Emergency: Seal Vault to prevent access
vault operator seal
```

---

## Security Checklist

### Pre-Production

- [ ] All secrets migrated to Vault
- [ ] TLS 1.3 enabled on all services
- [ ] Database encryption at rest enabled
- [ ] Audit logging tested and verified
- [ ] Password policy enforced
- [ ] MFA enabled for admin accounts
- [ ] Firewall rules configured
- [ ] Rate limiting enabled
- [ ] Security scanning completed (SAST/DAST)
- [ ] Penetration testing completed
- [ ] Backup and restore tested
- [ ] Incident response plan documented

### Post-Production

- [ ] Monitor audit logs daily
- [ ] Review security events weekly
- [ ] Rotate secrets quarterly
- [ ] Update dependencies monthly
- [ ] Conduct security audits annually
- [ ] Test disaster recovery quarterly
- [ ] Review access permissions quarterly
- [ ] Penetration testing annually

---

## Compliance Mapping

### NCC ICL Framework 2026

| Requirement | Implementation |
|-------------|----------------|
| Strong Authentication | RS256 JWT + MFA |
| Access Control | RBAC with fine-grained permissions |
| Audit Trail | Immutable audit log (7-year retention) |
| Secrets Management | HashiCorp Vault |
| Data Encryption | TLS 1.3, AES-256 at rest |
| Incident Response | Automated detection + playbooks |

### ISO 27001:2022

| Control | Implementation |
|---------|----------------|
| A.9.2 User Access Management | RBAC + periodic reviews |
| A.9.4 System Access Control | Password policy + lockout |
| A.12.4 Logging | Comprehensive audit trail |
| A.14.1 Cryptography | Vault + TLS 1.3 + AES-256 |

---

## Support

For security issues or questions, contact:
- Security Team: security@voxguard.com
- Emergency Hotline: +234-XXX-XXXX-XXX
- PGP Key: [Link to public key]

**Report vulnerabilities responsibly through our bug bounty program.**

---

*This document is confidential and intended for authorized VoxGuard personnel only.*
