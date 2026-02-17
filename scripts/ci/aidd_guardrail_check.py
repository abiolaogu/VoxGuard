#!/usr/bin/env python3
"""
AIDD guardrail checker for pull requests.

This script validates PR tier declarations against changed files and enforces
basic Tier 2 approval metadata requirements.
"""

from __future__ import annotations

import argparse
import fnmatch
import json
import re
import sys
from pathlib import Path

T0_PATTERNS = [
    "*.md",
    "*.mdx",
    "*.rst",
    "*.txt",
    "*.adoc",
    "docs/**",
    ".gitignore",
    ".editorconfig",
    ".prettierrc",
    ".prettierignore",
    ".gitattributes",
    "CHANGELOG.md",
    "README.md",
    "CONTRIBUTING.md",
]

T2_PATTERNS = [
    ".github/workflows/**",
    "infrastructure/**",
    "database/**",
    "hasura/**",
    "security/**",
    "monitoring/**",
    "Dockerfile",
    "**/Dockerfile",
    "**/*.sql",
    "**/migrations/**",
    "**/auth/**",
    "**/authorization/**",
]

INVALID_APPROVAL_VALUES = {"", "n/a", "na", "none", "pending", "tbd", "not required"}


def normalize_path(path: str) -> str:
    return path.strip().lstrip("./")


def matches_any(path: str, patterns: list[str]) -> bool:
    return any(fnmatch.fnmatch(path, pattern) for pattern in patterns)


def classify_file(path: str) -> int:
    if matches_any(path, T2_PATTERNS):
        return 2
    if matches_any(path, T0_PATTERNS):
        return 0
    return 1


def parse_declared_tier(pr_body: str) -> tuple[int | None, str | None]:
    matches = re.findall(r"-\s*\[(x|X)\]\s*\*\*T([012])\*\*", pr_body or "")
    if not matches:
        return None, (
            "PR body must declare exactly one AIDD tier using the checkbox format "
            "for T0/T1/T2."
        )
    if len(matches) > 1:
        return None, "Multiple AIDD tiers were selected; select exactly one."
    return int(matches[0][1]), None


def parse_admin_approval_reference(pr_body: str) -> str | None:
    if not pr_body:
        return None
    match = re.search(r"(?im)^Admin Approval Reference:\s*(.+)$", pr_body)
    if not match:
        return None
    return match.group(1).strip()


def load_changed_files(path: Path) -> list[str]:
    if not path.exists():
        return []
    files = []
    for raw in path.read_text(encoding="utf-8").splitlines():
        candidate = normalize_path(raw)
        if candidate:
            files.append(candidate)
    return files


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate AIDD PR guardrails.")
    parser.add_argument("--changed-files", required=True, type=Path)
    parser.add_argument("--pr-body", required=True, type=Path)
    parser.add_argument("--out", required=False, type=Path)
    args = parser.parse_args()

    changed_files = load_changed_files(args.changed_files)
    pr_body = args.pr_body.read_text(encoding="utf-8") if args.pr_body.exists() else ""

    per_file = {path: classify_file(path) for path in changed_files}
    required_tier = max(per_file.values(), default=0)
    declared_tier, parse_error = parse_declared_tier(pr_body)
    admin_approval_ref = parse_admin_approval_reference(pr_body)

    errors: list[str] = []
    warnings: list[str] = []

    if parse_error:
        errors.append(parse_error)
    elif declared_tier is not None and declared_tier < required_tier:
        errors.append(
            f"Declared tier T{declared_tier} is too low for changed files; minimum required is T{required_tier}."
        )

    if declared_tier is not None and declared_tier > required_tier:
        warnings.append(
            f"Declared tier T{declared_tier} is stricter than required tier T{required_tier}."
        )

    if declared_tier == 2:
        value = (admin_approval_ref or "").strip().lower()
        if value in INVALID_APPROVAL_VALUES:
            errors.append(
                "Tier 2 PRs must include a non-placeholder 'Admin Approval Reference: <ticket/link>'."
            )

    result = {
        "required_tier": f"T{required_tier}",
        "declared_tier": None if declared_tier is None else f"T{declared_tier}",
        "changed_files": changed_files,
        "file_tiers": {path: f"T{tier}" for path, tier in per_file.items()},
        "admin_approval_reference": admin_approval_ref,
        "errors": errors,
        "warnings": warnings,
    }

    payload = json.dumps(result, indent=2)
    if args.out:
        args.out.write_text(payload + "\n", encoding="utf-8")
    print(payload)

    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
