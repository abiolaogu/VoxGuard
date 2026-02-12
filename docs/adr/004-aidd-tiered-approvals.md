# ADR 004: AIDD Tiered Approval System

## Metadata

| Field      | Value                                          |
|------------|------------------------------------------------|
| **Title**  | Adopt a Tiered Approval System for AI-Driven Development |
| **Date**   | 2026-01-20                                     |
| **Status** | Accepted                                       |
| **Authors**| VoxGuard Architecture Team                     |

---

## Context

VoxGuard follows an **AI-Driven Development (AIDD)** methodology in which autonomous AI coding agents (such as Claude Code, GitHub Copilot Workspace, and similar tools) are integral participants in the development process. These agents generate code, write tests, update documentation, and open pull requests with varying degrees of human supervision.

### The Problem

Without guardrails, autonomous AI-driven development introduces risks:

1. **Security risk:** AI agents may introduce vulnerabilities, misconfigure authentication, or inadvertently expose sensitive data. Changes to security-critical components (authentication, authorization, encryption, infrastructure) require expert human review that AI agents cannot replace.

2. **Review bottleneck:** Requiring full human review for every AI-generated PR creates a bottleneck that negates the velocity benefits of AIDD. Trivial changes (typo fixes, documentation updates, formatting) consume reviewer time that would be better spent on substantive code review.

3. **Accountability ambiguity:** When AI agents open PRs autonomously, it can be unclear who is responsible for verifying correctness, who approved the change, and who is accountable if a defect reaches production.

4. **Inconsistent review rigor:** Without a structured framework, some AI-generated changes receive excessive scrutiny while others receive insufficient review, depending on the reviewer's familiarity with AIDD practices.

### Requirements

- A structured system that matches review rigor to the risk level of the change.
- Fast-path approval for low-risk changes to maintain velocity.
- Mandatory expert review for high-risk changes to maintain security and stability.
- Clear accountability model for both human and AI-authored contributions.
- Compatibility with GitHub's pull request and branch protection features.

### Alternatives Evaluated

1. **Uniform review requirement (all PRs require one human reviewer):**
   - **Pros:** Simple to implement and understand.
   - **Cons:** Creates a review bottleneck for trivial changes. Treats a documentation typo fix with the same rigor as a database migration, wasting reviewer capacity. Does not scale with increased AI agent activity.

2. **No review for AI-generated PRs (trust the CI pipeline):**
   - **Pros:** Maximum velocity.
   - **Cons:** Unacceptable security risk. CI can catch syntactic and functional errors but cannot evaluate architectural appropriateness, security implications, or business logic correctness. Violates NCC compliance requirements for change management.

3. **CODEOWNERS-only approach (file-based ownership):**
   - **Pros:** Leverages GitHub's built-in CODEOWNERS feature for automatic reviewer assignment.
   - **Cons:** File-based ownership alone does not capture the risk level of a change. A one-line config change and a complete rewrite of a file trigger the same CODEOWNERS rules. Does not provide a framework for differentiating review depth.

---

## Decision

We will implement a **three-tier approval system** for all pull requests (both human-authored and AI-generated). Every PR must declare its tier, and the tier determines the review and approval requirements.

### Tier Definitions

#### T0 — Cosmetic / Documentation / Configuration

**Scope:** Changes with no functional impact on the system's behavior.

**Examples:**
- Documentation updates (README, inline comments, ADRs, guides)
- Typo and grammar fixes
- Code formatting and whitespace changes
- `.gitignore`, `.editorconfig`, and similar tooling configuration
- CI configuration changes that do not affect build or test behavior
- Dependency version bumps for non-security patch releases (e.g., 1.2.3 to 1.2.4)

**Approval requirements:**
- All CI checks must pass (linting, formatting, build, tests)
- No human reviewer required
- Auto-merge is permitted after CI passes

**Rationale:** These changes carry near-zero risk and do not affect system functionality. Requiring human review adds overhead without proportional safety benefit.

#### T1 — Standard Feature / Bug Fix

**Scope:** Changes that add, modify, or fix functional behavior.

**Examples:**
- New UI components or pages
- New or modified API endpoints
- Bug fixes
- New or updated tests
- Non-breaking refactoring
- New database queries or Hasura metadata (non-migration)
- ML model updates (non-production deployment)

**Approval requirements:**
- All CI checks must pass
- At least **one approved review** from a designated code owner or team reviewer
- Reviewer must verify correctness, test coverage, and adherence to coding standards

**Rationale:** These changes affect system behavior and require human judgment to validate correctness, completeness, and alignment with project goals. A single reviewer provides adequate oversight for standard changes.

#### T2 — Security / Infrastructure / Breaking Change

**Scope:** Changes with elevated risk that could compromise security, stability, or backward compatibility.

**Examples:**
- Authentication or authorization logic changes
- Cryptographic implementation changes
- Database schema migrations
- Infrastructure configuration (Terraform, Kubernetes, Docker Compose for production)
- Breaking API changes
- Dependency upgrades with security advisories
- CI/CD pipeline changes that affect deployment behavior
- Hasura permission or role changes
- Production ML model deployments
- Changes to monitoring alert rules or SLO definitions

**Approval requirements:**
- All CI checks must pass
- **Admin-level approval** required from a team lead, security engineer, or designated admin reviewer
- Reviewer must perform a thorough security and impact assessment
- For database migrations: a rollback plan must be documented in the PR description
- For breaking changes: a migration guide must be included

**Rationale:** These changes carry the highest risk. A compromised authentication flow, a botched migration, or a misconfigured infrastructure change can cause data loss, security breaches, or extended outages. Admin-level review ensures these changes receive the scrutiny they demand.

### Implementation

#### GitHub Branch Protection Rules

```yaml
# Branch protection for main
main:
  required_status_checks:
    strict: true
    contexts:
      - lint
      - build
      - test
      - security-scan
  required_pull_request_reviews:
    # T0: configured via auto-merge label + GitHub Actions
    # T1: one reviewer from CODEOWNERS
    # T2: admin reviewer (dismiss_stale_reviews enabled)
    required_approving_review_count: 0  # Managed per-tier by automation
    dismiss_stale_reviews: true
    require_code_owner_reviews: true
```

#### Tier Declaration

Every PR must include a tier declaration in the PR description body using the following format:

```markdown
## AIDD Tier Classification
- [x] **T0** — Cosmetic / docs / config
- [ ] **T1** — Standard feature / bugfix
- [ ] **T2** — Security / infrastructure / breaking change
```

A GitHub Actions workflow validates the tier declaration and enforces the corresponding approval requirements:

- **T0 PRs** are labeled `aidd:t0` and auto-merged after CI passes.
- **T1 PRs** are labeled `aidd:t1` and require one approving review before merge.
- **T2 PRs** are labeled `aidd:t2` and require admin approval before merge. A Slack notification is sent to the security review channel.

#### Tier Escalation

If a reviewer determines that a PR is under-classified (e.g., declared as T0 but contains functional changes), the reviewer must:

1. Request changes on the PR
2. Ask the author to re-classify to the correct tier
3. The updated tier triggers the corresponding approval requirements

Tier escalation is always permitted; tier de-escalation requires justification.

#### AI Agent Accountability

- Every PR opened by an AI agent must include the `Co-Authored-By` trailer in commit messages identifying the AI tool.
- The human who initiated or supervises the AI agent is listed as the PR author and is accountable for the contents.
- AI agents are not permitted to approve PRs. Only human reviewers can provide approvals.
- AI agents are not permitted to merge PRs. Merge actions must be taken by a human or by the auto-merge automation (T0 only, after CI passes).

---

## Consequences

### Positive

- **Right-sized review effort:** Low-risk changes flow through quickly without consuming reviewer time, while high-risk changes receive thorough scrutiny. This optimizes the team's total review capacity.
- **Clear accountability:** The tier system and AI co-authorship requirements make it unambiguous who authored, reviewed, and approved every change.
- **Scalable AIDD adoption:** As AI agent activity increases, the tiered system prevents the review pipeline from becoming a bottleneck. T0 auto-merge handles the high volume of trivial AI-generated changes, while T1 and T2 gates ensure human oversight where it matters.
- **Regulatory compliance:** The explicit tier declaration, approval records, and audit trail satisfy NCC change management requirements.
- **Security posture:** Critical changes are explicitly flagged and routed to qualified reviewers, reducing the risk of security-sensitive changes slipping through with inadequate review.

### Negative

- **Classification overhead:** Authors must evaluate the risk level of their changes and declare a tier. Incorrect classification can lead to under-review (security risk) or over-review (velocity cost).
- **Automation complexity:** Implementing the tier-aware automation (label assignment, conditional approval requirements, auto-merge) requires custom GitHub Actions workflows that must be maintained.
- **Potential for gaming:** Authors or AI agents might deliberately under-classify changes to avoid review. This requires vigilance from reviewers and periodic audits of tier classifications.
- **Tier boundary ambiguity:** Some changes straddle tier boundaries (e.g., a bug fix that also modifies a Hasura permission). The team must develop judgment for correct classification, which takes time.

### Mitigations

- Provide clear, example-rich documentation of tier classifications (see `docs/AIDD_APPROVAL_TIERS.md`) and update it as edge cases arise.
- Implement automated tier suggestion based on changed file paths (e.g., changes to `infrastructure/`, `hasura/metadata/permissions/`, or `**/auth/**` automatically suggest T2).
- Conduct monthly audits of tier classifications to identify patterns of under-classification and address them with team guidance.
- Include tier classification as a checklist item in the PR template to ensure it is not overlooked.

---

## References

- [VoxGuard AIDD Approval Tiers Documentation](../AIDD_APPROVAL_TIERS.md)
- [GitHub Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches)
- [Conventional Comments for Code Review](https://conventionalcomments.org/)
- [NIST SP 800-218: Secure Software Development Framework](https://csrc.nist.gov/publications/detail/sp/800-218/final)
