# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in the Anti-Call Masking Detection System, please report it responsibly:

1. **DO NOT** create a public GitHub issue
2. Email security concerns to: security@example.com
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Any suggested fixes

We will respond within 48 hours and work with you to address the issue.

## Security Measures

### Authentication & Authorization
- All IPC connections should be authenticated
- Use strong passwords for switch connections
- Implement network segmentation

### Data Protection
- Call data is processed in-memory
- Checkpoints are stored securely
- PII handling follows data protection regulations

### Network Security
- Use TLS for all external connections
- Implement network policies in Kubernetes
- Restrict egress traffic

### Secrets Management
- Never hardcode credentials in source code
- Use Kubernetes Secrets or external vault
- Rotate credentials regularly

## Security Scanning

This project uses:
- **Trivy**: Container and filesystem vulnerability scanning
- **Semgrep**: Static Application Security Testing (SAST)
- **TruffleHog**: Secret detection in source code

## Hardening Checklist

- [ ] Change default ESL password
- [ ] Enable TLS for switch connections
- [ ] Configure network policies
- [ ] Set resource limits
- [ ] Enable audit logging
- [ ] Implement RBAC
- [ ] Use non-root container user
- [ ] Enable read-only root filesystem where possible
