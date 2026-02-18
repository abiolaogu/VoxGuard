#!/usr/bin/env bash
set -euo pipefail

BRANCH="${1:-main}"
REPO="${2:-}"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI is required. Install from https://cli.github.com/"
  exit 1
fi

if [[ -z "$REPO" ]]; then
  REPO="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
fi

cat <<JSON | gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/${REPO}/branches/${BRANCH}/protection" \
  --input -
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "AIDD Tier Guardrails / Validate AIDD Tier",
      "Service CI Required Checks / Rust Unit Tests",
      "Service CI Required Checks / Go Unit Tests",
      "Service CI Required Checks / Python Unit Tests"
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": 1
  },
  "restrictions": null,
  "required_conversation_resolution": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_linear_history": true
}
JSON

echo "Branch protection configured for ${REPO}@${BRANCH}"
