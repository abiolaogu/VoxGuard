# VoxGuard Penetration Testing Guide

**Version:** 1.0.0
**Date:** 2026-02-03
**Classification:** Confidential

---

## Overview

This document provides procedures for conducting penetration testing on the VoxGuard platform to identify security vulnerabilities before malicious actors can exploit them.

## Scope

### In-Scope Components

- **Management API** (`services/management-api`)
- **Authentication & Authorization System**
- **Database Layer** (YugabyteDB)
- **Vault Integration** (HashiCorp Vault)
- **Network Infrastructure**
- **Web Dashboard** (if applicable)

### Out-of-Scope

- Physical security testing
- Social engineering (unless explicitly authorized)
- Denial of Service (DoS) attacks on production
- Third-party SaaS platforms (NCC systems)

## Testing Methodology

### OWASP Testing Framework

Following OWASP Web Security Testing Guide (WSTG) v4.2:

1. **Information Gathering**
2. **Configuration Testing**
3. **Authentication Testing**
4. **Authorization Testing**
5. **Session Management Testing**
6. **Input Validation Testing**
7. **Error Handling**
8. **Cryptography**
9. **Business Logic Testing**
10. **API Security Testing**

---

## Pre-Testing Setup

### 1. Environment Preparation

```bash
# Deploy test environment
docker-compose -f docker-compose.test.yml up -d

# Verify services are running
curl -k https://localhost:8081/health
```

### 2. Test Accounts

Create test accounts with varying privilege levels:

```sql
-- Super Admin
INSERT INTO users (id, username, email, password_hash, is_active)
VALUES (gen_random_uuid(), 'test_superadmin', 'admin@test.local', '$2a$12$HASH', true);

-- Regular User
INSERT INTO users (id, username, email, password_hash, is_active)
VALUES (gen_random_uuid(), 'test_user', 'user@test.local', '$2a$12$HASH', true);

-- Locked Account
INSERT INTO users (id, username, email, password_hash, is_active, is_locked)
VALUES (gen_random_uuid(), 'test_locked', 'locked@test.local', '$2a$12$HASH', true, true);
```

### 3. Testing Tools

**Required Tools:**
- **Burp Suite Professional** - Web application testing
- **OWASP ZAP** - Automated scanning
- **Postman/Insomnia** - API testing
- **sqlmap** - SQL injection testing
- **jwt_tool** - JWT manipulation
- **Nmap** - Network scanning
- **Metasploit** - Exploitation framework

**Installation:**
```bash
# Burp Suite
wget https://portswigger.net/burp/releases/download -O burpsuite.jar

# OWASP ZAP
docker pull owasp/zap2docker-stable

# jwt_tool
git clone https://github.com/ticarpi/jwt_tool
cd jwt_tool && pip3 install -r requirements.txt
```

---

## Authentication Testing

### A. Password Policy Testing

**Objective:** Verify password complexity requirements.

**Test Cases:**

1. **Weak Password Submission**
```bash
curl -X POST https://localhost:8081/api/v1/users \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "weakpass",
    "email": "weak@test.local",
    "password": "12345",
    "first_name": "Test",
    "last_name": "User"
  }'

# Expected: 400 Bad Request - "password must be at least 12 characters"
```

2. **No Special Characters**
```bash
# Try: "Password123" (no special char)
# Expected: Rejection
```

3. **No Uppercase**
```bash
# Try: "password123!" (no uppercase)
# Expected: Rejection
```

**Pass Criteria:** All weak passwords rejected.

### B. Brute Force Protection

**Objective:** Verify account lockout after failed attempts.

**Test Procedure:**
```bash
# Script to test lockout
for i in {1..6}; do
  curl -X POST https://localhost:8081/api/v1/auth/login \
    -H "Content-Type: application/json" \
    -d '{
      "username": "test_user",
      "password": "wrongpassword"
    }'
  echo "Attempt $i"
  sleep 1
done

# After 5 attempts, account should be locked
# Attempt 6 should return: "account is locked"
```

**Verify Lockout Duration:**
```sql
SELECT username, is_locked, locked_until FROM users WHERE username = 'test_user';
-- locked_until should be ~30 minutes from now
```

**Pass Criteria:**
- Account locked after 5 failed attempts
- Lockout duration: 30 minutes
- Audit event logged

### C. JWT Token Security

**Objective:** Verify JWT implementation security.

**Test Cases:**

1. **Algorithm Confusion Attack**
```python
# jwt_tool test
python3 jwt_tool.py $JWT_TOKEN -X a

# Try changing RS256 to HS256
# Expected: Token rejection
```

2. **Token Expiration**
```bash
# Wait for token to expire (15 minutes)
sleep 900

# Use expired token
curl https://localhost:8081/api/v1/gateways \
  -H "Authorization: Bearer $EXPIRED_TOKEN"

# Expected: 401 Unauthorized
```

3. **Token Manipulation**
```bash
# Modify payload (change user_id)
python3 jwt_tool.py $JWT_TOKEN -I -pc user_id -pv "different-user-id"

# Expected: Signature verification failure
```

4. **None Algorithm Attack**
```python
# Try setting alg to "none"
import jwt
token = jwt.encode(payload, None, algorithm="none")

# Expected: Rejection
```

**Pass Criteria:**
- RS256 strictly enforced
- Expired tokens rejected
- Modified tokens rejected
- "none" algorithm rejected

### D. Session Management

**Objective:** Test refresh token security.

**Test Cases:**

1. **Refresh Token Reuse**
```bash
# Use refresh token once
TOKEN1=$(curl -X POST https://localhost:8081/api/v1/auth/refresh \
  -d '{"refresh_token": "'$REFRESH_TOKEN'"}' | jq -r '.access_token')

# Try using same refresh token again
TOKEN2=$(curl -X POST https://localhost:8081/api/v1/auth/refresh \
  -d '{"refresh_token": "'$REFRESH_TOKEN'"}')

# Expected: Both should work (refresh tokens are reusable until expiry)
```

2. **Token Revocation**
```bash
# Revoke token
curl -X POST https://localhost:8081/api/v1/auth/logout \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"refresh_token": "'$REFRESH_TOKEN'"}'

# Try using revoked token
curl -X POST https://localhost:8081/api/v1/auth/refresh \
  -d '{"refresh_token": "'$REFRESH_TOKEN'"}'

# Expected: "refresh token has been revoked"
```

3. **Concurrent Sessions**
```bash
# Login from multiple IPs/devices
# Verify all sessions are tracked independently
```

**Pass Criteria:**
- Refresh tokens can be revoked
- Revoked tokens cannot be used
- Session tracking per IP/device

---

## Authorization Testing

### A. Vertical Privilege Escalation

**Objective:** Verify users cannot access higher privilege functions.

**Test Procedure:**

1. **Regular User Attempting Admin Function**
```bash
# Login as regular user
USER_TOKEN=$(curl -X POST https://localhost:8081/api/v1/auth/login \
  -d '{"username": "test_user", "password": "ValidPass123!"}' \
  | jq -r '.access_token')

# Try to create a user (admin-only)
curl -X POST https://localhost:8081/api/v1/users \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d '{
    "username": "hacker",
    "email": "hacker@test.local",
    "password": "Hacked123!",
    "first_name": "Hacker",
    "last_name": "User"
  }'

# Expected: 403 Forbidden - "Required role(s): [admin]"
```

2. **Role Manipulation in Token**
```python
# Attempt to modify roles in JWT
# (Should fail due to signature verification)
```

3. **Direct Role Assignment**
```bash
# Try to assign yourself admin role
curl -X POST https://localhost:8081/api/v1/users/$USER_ID/roles \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d '{"role_id": "'$ADMIN_ROLE_ID'"}'

# Expected: 403 Forbidden
```

**Pass Criteria:**
- All unauthorized actions blocked
- Proper error messages returned
- Attempts logged in audit trail

### B. Horizontal Privilege Escalation

**Objective:** Verify users cannot access other users' data.

**Test Cases:**

1. **Access Another User's Profile**
```bash
# User A tries to view User B's profile
curl https://localhost:8081/api/v1/users/$USER_B_ID \
  -H "Authorization: Bearer $USER_A_TOKEN"

# Expected: 403 Forbidden (unless user has admin role)
```

2. **Modify Another User's Data**
```bash
curl -X PATCH https://localhost:8081/api/v1/users/$USER_B_ID \
  -H "Authorization: Bearer $USER_A_TOKEN" \
  -d '{"email": "hacked@test.local"}'

# Expected: 403 Forbidden
```

3. **IDOR (Insecure Direct Object Reference)**
```bash
# Try sequential IDs
for id in $(seq 1 100); do
  curl https://localhost:8081/api/v1/users/$id \
    -H "Authorization: Bearer $USER_TOKEN"
done

# Expected: 403 for all unauthorized IDs
```

**Pass Criteria:**
- Users can only access their own data
- UUID usage prevents ID enumeration
- Authorization checks on every request

### C. Permission Bypass

**Objective:** Test fine-grained permission enforcement.

**Test Cases:**

1. **Missing Permission**
```bash
# User with "gateway:read" tries to write
curl -X POST https://localhost:8081/api/v1/gateways \
  -H "Authorization: Bearer $READ_ONLY_TOKEN" \
  -d '{"name": "Hacker Gateway", ...}'

# Expected: 403 - "Required permission: gateway:write"
```

2. **Policy Condition Bypass**
```bash
# Try to bypass PBAC conditions
# E.g., approve high-severity alert with medium-only permission
```

**Pass Criteria:**
- Permissions strictly enforced
- Policy conditions cannot be bypassed

---

## Input Validation Testing

### A. SQL Injection

**Objective:** Verify protection against SQL injection.

**Test Cases:**

1. **Authentication Bypass**
```bash
curl -X POST https://localhost:8081/api/v1/auth/login \
  -d '{"username": "admin'\'' OR '\''1'\''='\''1", "password": "anything"}'

# Expected: Login failure (not SQL error)
```

2. **Data Extraction**
```bash
# Try in search/filter parameters
curl "https://localhost:8081/api/v1/users?username=admin' UNION SELECT password FROM users--"

# Expected: No SQL error, no data leakage
```

3. **Blind SQL Injection**
```bash
# Time-based blind SQLi
curl "https://localhost:8081/api/v1/users?id=1' AND SLEEP(5)--"

# Expected: Normal response time (no delay)
```

**Tools:**
```bash
# Automated testing with sqlmap
sqlmap -u "https://localhost:8081/api/v1/users?id=1" \
  --cookie="Authorization=Bearer $TOKEN" \
  --level=5 --risk=3
```

**Pass Criteria:**
- No SQL injection vulnerabilities
- Parameterized queries used throughout
- No database errors exposed

### B. Cross-Site Scripting (XSS)

**Objective:** Verify XSS protection (if web interface exists).

**Test Cases:**

1. **Reflected XSS**
```bash
curl "https://localhost:8081/api/v1/search?q=<script>alert('XSS')</script>"

# Expected: Sanitized output or JSON response (API context)
```

2. **Stored XSS**
```bash
# Try storing XSS in user profile
curl -X PATCH https://localhost:8081/api/v1/users/$USER_ID \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"first_name": "<script>alert(1)</script>"}'

# Later retrieve and verify sanitization
```

**Pass Criteria:**
- All user input sanitized
- Content-Type headers set correctly
- CSP headers present

### C. Command Injection

**Objective:** Verify no OS command execution possible.

**Test Cases:**

```bash
# Try command injection in various inputs
curl -X POST https://localhost:8081/api/v1/gateways \
  -d '{"name": "Gateway; rm -rf /", "ip_address": "127.0.0.1"}'

# Expected: Validation error or sanitized input
```

**Pass Criteria:**
- No system commands executed
- Input validation on all fields

---

## API Security Testing

### A. Mass Assignment

**Objective:** Verify protection against mass assignment.

**Test Cases:**

```bash
# Try to set privileged fields
curl -X POST https://localhost:8081/api/v1/users \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "username": "hacker",
    "email": "hacker@test.local",
    "password": "Valid123!",
    "first_name": "Hacker",
    "last_name": "User",
    "is_active": true,
    "is_locked": false,
    "login_attempts": 0,
    "roles": ["superadmin"]
  }'

# Expected: Only allowed fields accepted, roles assigned via separate endpoint
```

**Pass Criteria:**
- Sensitive fields cannot be set directly
- Proper DTOs/validation in place

### B. Rate Limiting

**Objective:** Verify rate limiting enforcement.

**Test Cases:**

```bash
# Flood requests
for i in $(seq 1 150); do
  curl https://localhost:8081/api/v1/gateways \
    -H "Authorization: Bearer $TOKEN" &
done
wait

# Expected: 429 Too Many Requests after limit exceeded
```

**Pass Criteria:**
- Rate limits enforced (100 req/min)
- Retry-After header present
- Rate limit headers returned

### C. CORS Configuration

**Objective:** Verify CORS is properly configured.

**Test Cases:**

```bash
# Test from unauthorized origin
curl https://localhost:8081/api/v1/users \
  -H "Origin: https://evil.com" \
  -H "Authorization: Bearer $TOKEN"

# Expected: No Access-Control-Allow-Origin header or rejection
```

**Pass Criteria:**
- CORS restricted to authorized origins
- Credentials not allowed for wildcards

---

## Cryptography Testing

### A. TLS Configuration

**Objective:** Verify strong TLS configuration.

**Test Cases:**

```bash
# Test SSL/TLS with testssl.sh
./testssl.sh https://localhost:8081

# Check for:
# - TLS 1.3 support
# - No SSLv3, TLS 1.0, TLS 1.1
# - Strong cipher suites only
# - Perfect Forward Secrecy (PFS)
```

**Expected Results:**
- Grade A or A+ on SSL Labs
- TLS 1.3 preferred
- No weak ciphers

### B. Password Storage

**Objective:** Verify secure password hashing.

**Test Cases:**

```sql
-- Verify bcrypt hashing
SELECT password_hash FROM users LIMIT 1;
-- Should start with $2a$ or $2b$ (bcrypt)

-- Verify cost factor (should be >= 12)
-- $2a$12$ means cost 12
```

**Pass Criteria:**
- bcrypt with cost >= 12
- No plaintext passwords
- Salted hashes

### C. Secrets in Code

**Objective:** Verify no hardcoded secrets.

**Tools:**
```bash
# Scan for secrets
trufflehog git file:///path/to/voxguard --only-verified

# Check for common patterns
grep -r "password.*=.*['\"]" services/
grep -r "api_key.*=.*['\"]" services/
grep -r "secret.*=.*['\"]" services/
```

**Pass Criteria:**
- No hardcoded credentials
- All secrets in Vault
- No secrets in logs

---

## Business Logic Testing

### A. Account Lockout Recovery

**Objective:** Test account recovery procedures.

**Test Cases:**

1. **Lockout Expiry**
```sql
-- Set locked_until to past
UPDATE users SET locked_until = NOW() - INTERVAL '1 minute' WHERE username = 'test_user';

-- Try login
-- Expected: Automatic unlock and successful login
```

2. **Manual Unlock**
```bash
# Admin unlocks user
curl -X POST https://localhost:8081/api/v1/users/$USER_ID/unlock \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Expected: User can now login
```

### B. Token Lifecycle

**Objective:** Verify token expiration and renewal.

**Test Cases:**

1. **Access Token Expiry** (15 minutes)
```bash
# Get token
TOKEN=$(login...)

# Wait 16 minutes
sleep 960

# Use token
curl https://localhost:8081/api/v1/gateways -H "Authorization: Bearer $TOKEN"

# Expected: 401 Unauthorized
```

2. **Refresh Token Expiry** (7 days)
```bash
# Set refresh token expiry to past
UPDATE refresh_tokens SET expires_at = NOW() - INTERVAL '1 day' WHERE user_id = $USER_ID;

# Try refresh
# Expected: "refresh token has expired"
```

---

## Audit Logging Testing

### A. Log Completeness

**Objective:** Verify all sensitive actions are logged.

**Test Procedure:**

```bash
# Perform various actions
# 1. Login
# 2. Create user
# 3. Update gateway
# 4. Delete resource
# 5. Failed authentication
# 6. Privilege escalation attempt

# Verify all are in audit_events
SELECT * FROM audit_events WHERE user_id = $USER_ID ORDER BY timestamp DESC;
```

**Pass Criteria:**
- All actions logged
- Logs include: who, what, when, where, result
- Failed attempts logged

### B. Log Immutability

**Objective:** Verify audit logs cannot be modified.

**Test Cases:**

```sql
-- Try to update audit event
UPDATE audit_events SET action = 'hacked' WHERE id = $EVENT_ID;
-- Expected: ERROR: Audit events are immutable

-- Try to delete audit event
DELETE FROM audit_events WHERE id = $EVENT_ID;
-- Expected: ERROR: Audit events are immutable
```

**Pass Criteria:**
- UPDATE trigger prevents modifications
- DELETE trigger prevents deletions
- Error logged when attempted

---

## Vault Integration Testing

### A. Secret Access Control

**Objective:** Verify Vault policies enforced.

**Test Cases:**

```bash
# Try to access secret without permission
VAULT_TOKEN=$UNAUTHORIZED_TOKEN vault kv get secret/ncc/credentials

# Expected: Permission denied
```

### B. Dynamic Credentials

**Objective:** Test database credential rotation.

**Test Cases:**

```bash
# Get dynamic credentials
CREDS=$(vault read database/creds/voxguard-app -format=json)
USERNAME=$(echo $CREDS | jq -r '.data.username')
PASSWORD=$(echo $CREDS | jq -r '.data.password')

# Use credentials
psql -h yugabyte -U $USERNAME -d acm_db

# Wait for expiry (1 hour)
# Try again
# Expected: Credentials no longer work
```

**Pass Criteria:**
- Credentials work within lease period
- Credentials revoked after expiry
- New credentials generated on each request

---

## Remediation Priority

### Critical (Fix Immediately)
- SQL Injection
- Authentication bypass
- Hardcoded secrets
- Privilege escalation

### High (Fix within 7 days)
- XSS vulnerabilities
- Weak cryptography
- Missing authorization checks
- Audit logging gaps

### Medium (Fix within 30 days)
- Rate limiting issues
- Information disclosure
- CORS misconfiguration
- Session management weaknesses

### Low (Fix when possible)
- Missing security headers
- Verbose error messages
- Directory listings

---

## Reporting

### Report Structure

1. **Executive Summary**
   - Tested period
   - Methodology
   - Key findings
   - Risk rating

2. **Detailed Findings**
   - Vulnerability description
   - Impact assessment
   - Proof of concept
   - Remediation steps
   - CVSS score

3. **Test Results Matrix**
   - Pass/Fail for each test
   - Evidence (screenshots, logs)

4. **Recommendations**
   - Security improvements
   - Best practices
   - Compliance gaps

### Sample Report Entry

```markdown
## Finding: Weak Password Accepted

**Severity:** HIGH
**CVSS:** 7.5
**Status:** OPEN

**Description:**
The system accepts passwords shorter than 12 characters, violating the stated password policy.

**Impact:**
Users may choose weak passwords susceptible to brute force attacks.

**Proof of Concept:**
```bash
curl -X POST https://localhost:8081/api/v1/users \
  -d '{"username": "test", "password": "Pass1!", ...}'
# Expected: Rejection
# Actual: User created
```

**Remediation:**
Update password validation in `auth_service.go`:
```go
if len(password) < 12 {
    return errors.New("password must be at least 12 characters")
}
```

**Verification:**
Retest after fix deployment.
```

---

## Continuous Testing

### Automated Security Testing

**CI/CD Integration:**
```yaml
# .github/workflows/security-scan.yml
name: Security Scan
on: [push, pull_request]
jobs:
  security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: SAST with Semgrep
      run: semgrep --config=auto .
    - name: Dependency Scan
      run: snyk test
    - name: Secret Scan
      run: trufflehog filesystem .
```

### Schedule

- **Automated Scans:** Daily (SAST, dependency check)
- **Manual Testing:** Quarterly
- **Full Penetration Test:** Annually (by third party)
- **Red Team Exercise:** Annually

---

## Contact

**Security Team:** security@voxguard.com
**Bug Bounty:** https://voxguard.com/security/bug-bounty

---

*Last Updated: 2026-02-03*
*Next Review: 2026-08-03*
