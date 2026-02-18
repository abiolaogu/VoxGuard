# Branch Protection Required Checks

This repository uses AIDD guardrails plus language-specific service checks as required status checks on `main`.

## Required checks

- `AIDD Tier Guardrails / Validate AIDD Tier`
- `Service CI Required Checks / Rust Unit Tests`
- `Service CI Required Checks / Go Unit Tests`
- `Service CI Required Checks / Python Unit Tests`

## Apply branch protection

Run from the repository root with a token that has repository admin rights:

```bash
export GH_TOKEN=<github_token_with_repo_admin>
./scripts/ci/configure_branch_protection.sh main
```

Optional explicit repository target:

```bash
./scripts/ci/configure_branch_protection.sh main owner/repo
```

## Notes

- `Service CI Required Checks` always emits all three checks.
- Each check runs tests only when its path changed:
  - Rust: `services/detection-engine/**`
  - Go: `services/management-api/**`
  - Python: `services/sip-processor/**`
