# AIDD Approval Tiers — VoxGuard

> Autonomous Intelligence-Driven Development — Tiered Approval for Destructive Operations

## Tier Definitions

### Tier 0 — Auto-Approve (Read-Only)
No confirmation required. Used for documentation, test runs, and read-only GET endpoints.

**Examples:**
- View dashboard, alerts, analytics
- Read fraud detection status
- View ML model status
- Export reports (read-only)

### Tier 1 — Require Confirmation
Operations that modify state but are individually reversible or low-blast-radius.
Requires `X-Confirm: true` header in API requests.

**Examples:**
- Block a single phone number
- Create/update/delete a fraud detection rule
- Toggle a traffic control rule
- Confirm a false positive/true positive
- Disconnect a single fraudulent call
- Generate an NCC compliance report
- Create a settlement dispute

### Tier 2 — Require Admin Approval
Operations that are hard to reverse, affect shared state, or have regulatory implications.
Requires `SYSTEM_ADMIN` role and `X-Admin-Approval` header with reason string.

**Examples:**
- Submit a compliance report to NCC regulator
- Escalate a settlement dispute to NCC
- Import MNP data (bulk database update)
- Bulk delete operations
- Run database migrations
- Modify authentication/authorization settings

## VoxGuard Operation → Tier Mapping

| Operation | Tier |
|-----------|------|
| View dashboard/alerts/analytics | 0 |
| View ML model status | 0 |
| View detection engine health | 0 |
| Block phone number | 1 |
| Create/update fraud rule | 1 |
| Toggle traffic rule | 1 |
| Disconnect single call | 1 |
| Confirm false/true positive | 1 |
| Generate NCC report | 1 |
| Create settlement dispute | 1 |
| Submit report to NCC | 2 |
| Escalate dispute to NCC | 2 |
| Import MNP data | 2 |
| Bulk delete records | 2 |

## Frontend Badge Specifications

- **Tier 0:** No badge displayed
- **Tier 1:** Yellow "Confirm" badge — show confirmation dialog before executing
- **Tier 2:** Red "Admin Approval" badge with lock icon — show admin approval dialog with reason textarea

## Integration with CLAUDE.md

This document aligns with the AIDD tiered approval system defined in the project's `CLAUDE.md`. All automated tooling (Claude Code, CI/CD pipelines) should respect these tiers when executing operations.
