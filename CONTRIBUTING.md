# Contributing to VoxGuard

Thank you for your interest in contributing to VoxGuard. This document provides guidelines and processes for contributing to the project. VoxGuard is a telecommunications fraud detection platform built as a monorepo, and we welcome contributions across all of its components.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Commit Message Convention](#commit-message-convention)
- [Pull Request Template](#pull-request-template)
- [Review Process](#review-process)
- [Testing Requirements](#testing-requirements)
- [Documentation Requirements](#documentation-requirements)
- [AIDD Compliance](#aidd-compliance)

---

## Code of Conduct

All contributors are expected to adhere to our [Code of Conduct](CODE_OF_CONDUCT.md). We are committed to providing a welcoming and inclusive environment for everyone. Please read it before participating. Violations should be reported to the maintainers at conduct@voxguard.io.

---

## Getting Started

### 1. Fork the Repository

Fork the VoxGuard repository to your own GitHub account using the GitHub UI or the CLI:

```bash
gh repo fork <org>/VoxGuard --clone
```

### 2. Clone Your Fork

```bash
git clone git@github.com:<your-username>/VoxGuard.git
cd VoxGuard
```

### 3. Install Dependencies

VoxGuard uses **pnpm** and **Turborepo** for monorepo management.

```bash
pnpm install
```

Refer to [docs/ENVIRONMENT_SETUP.md](docs/ENVIRONMENT_SETUP.md) for the full environment setup guide including backend services.

### 4. Create a Branch

All work must be done on a feature branch. Use the following naming convention:

| Prefix       | Purpose                          | Example                              |
|--------------|----------------------------------|--------------------------------------|
| `feat/`      | New feature                      | `feat/cdr-analysis-dashboard`        |
| `fix/`       | Bug fix                          | `fix/detection-engine-memory-leak`   |
| `docs/`      | Documentation only               | `docs/update-api-reference`          |
| `refactor/`  | Code refactoring (no behavior change) | `refactor/simplify-ml-pipeline` |
| `chore/`     | Tooling, CI, dependencies        | `chore/upgrade-turbo-config`         |
| `test/`      | Adding or updating tests         | `test/add-hasura-integration-tests`  |

```bash
git checkout -b feat/your-feature-name
```

Branch names must be lowercase, use hyphens as separators, and be descriptive of the change.

---

## Development Workflow

Follow this structured workflow for all contributions:

### Step 1: Create an Issue

Before starting work, ensure there is a GitHub issue describing the task. If one does not exist, create it with:

- A clear title and description
- Relevant labels (e.g., `bug`, `feature`, `documentation`, `security`)
- The affected package or service (e.g., `packages/web`, `backend/rust`, `services/ml`)
- The AIDD tier classification (T0, T1, or T2)

### Step 2: Create a Branch

Create a branch from `main` following the naming convention above. Reference the issue number in the branch name when practical (e.g., `feat/42-cdr-analysis`).

### Step 3: Develop

- Make focused, incremental commits
- Follow the coding standards for the language you are working in
- Keep changes scoped to the issue at hand
- Run linters and formatters before committing

### Step 4: Test

- Write or update tests to cover your changes
- Ensure all existing tests pass locally before pushing
- Run the relevant test suite for your package (see [Testing Requirements](#testing-requirements))

### Step 5: Open a Pull Request

- Push your branch and open a PR against `main`
- Fill out the PR template completely
- Link the related issue(s)
- Ensure CI passes before requesting review

---

## Coding Standards

### Rust (Detection Engine, Core Services)

- **Formatter:** `rustfmt` — all code must be formatted with `cargo fmt`
- **Linter:** `clippy` — all code must pass `cargo clippy -- -D warnings` with zero warnings
- Use idiomatic Rust patterns; prefer `Result` and `Option` over panics
- Document all public functions and types with `///` doc comments
- Minimum edition: Rust 2021

```bash
cargo fmt --all --check
cargo clippy --all-targets --all-features -- -D warnings
```

### Go (Management API)

- **Formatter:** `gofmt` — all code must be formatted with `gofmt`
- **Linter:** `golangci-lint` — all code must pass `golangci-lint run`
- Follow [Effective Go](https://go.dev/doc/effective_go) guidelines
- Use structured logging (zerolog or slog)
- All exported functions and types must have GoDoc comments

```bash
gofmt -l .
golangci-lint run ./...
```

### Python (ML Pipeline, Scripts)

- **Formatter:** `black` — all code must be formatted with `black`
- **Linter:** `ruff` — all code must pass `ruff check`
- Type hints are required for all function signatures
- Follow PEP 8 conventions
- Use virtual environments; do not commit system-level packages

```bash
black --check .
ruff check .
```

### TypeScript / React (Frontend — `packages/web`)

- **Linter:** `ESLint` — all code must pass `pnpm lint`
- **Formatter:** `Prettier` — all code must be formatted with Prettier
- Use functional components with hooks
- Use TypeScript strict mode; avoid `any` types
- Follow the project's Refine + Ant Design patterns

```bash
pnpm --filter web lint
pnpm --filter web format:check
```

---

## Commit Message Convention

VoxGuard follows the [Conventional Commits](https://www.conventionalcommits.org/) specification. Every commit message must conform to this format:

```
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

### Types

| Type         | Description                                      |
|--------------|--------------------------------------------------|
| `feat`       | A new feature                                    |
| `fix`        | A bug fix                                        |
| `docs`       | Documentation only changes                       |
| `chore`      | Tooling, CI, build, or dependency changes        |
| `refactor`   | Code change that neither fixes a bug nor adds a feature |
| `test`       | Adding or correcting tests                       |
| `perf`       | Performance improvement                          |
| `style`      | Formatting, whitespace (no logic change)         |
| `ci`         | Changes to CI configuration or scripts           |

### Scopes

Use the package or service name as scope: `web`, `rust`, `go`, `ml`, `hasura`, `infra`, `monitoring`, `db`.

### Examples

```
feat(web): add CDR analysis dashboard page
fix(rust): resolve memory leak in detection engine connection pool
docs(hasura): update GraphQL subscription examples
chore(infra): upgrade Terraform provider to v5.x
refactor(ml): simplify feature extraction pipeline
```

### Breaking Changes

Append `!` after the type/scope or include `BREAKING CHANGE:` in the footer:

```
feat(rust)!: redesign detection rule evaluation API

BREAKING CHANGE: Detection rules now use a declarative YAML format
instead of the previous Rust DSL.
```

Commit messages are enforced by `commitlint` via a pre-commit hook.

---

## Pull Request Template

When opening a PR, use the following template:

```markdown
## Description

<!-- Provide a clear and concise description of what this PR does. -->

Closes #<issue-number>

## Changes

- [ ] Change 1
- [ ] Change 2

## Testing

<!-- Describe how you tested these changes. -->

- [ ] Unit tests added/updated
- [ ] Integration tests added/updated (if applicable)
- [ ] Manual testing performed

## Screenshots

<!-- If applicable, add screenshots or screen recordings. -->

## AIDD Tier Classification

<!-- Declare the AIDD tier for this PR. See docs/AIDD_APPROVAL_TIERS.md -->

- [ ] **T0** — Cosmetic / docs / config (auto-merge eligible)
- [ ] **T1** — Standard feature / bugfix (one reviewer required)
- [ ] **T2** — Security / infrastructure / breaking change (admin approval required)

## Checklist

- [ ] My code follows the project's coding standards
- [ ] I have performed a self-review of my code
- [ ] I have added tests that prove my fix or feature works
- [ ] New and existing unit tests pass locally
- [ ] I have updated documentation as needed
- [ ] I have declared the correct AIDD tier
- [ ] My commits follow the Conventional Commits convention
```

---

## Review Process

Pull requests follow a tiered review process based on the AIDD classification:

### T0 — Cosmetic / Documentation / Configuration

- **Examples:** typo fixes, README updates, comment improvements, `.gitignore` changes
- **Review requirement:** Automated CI checks only
- **Merge policy:** Auto-merge after CI passes
- **Turnaround target:** Immediate upon CI completion

### T1 — Standard Feature / Bug Fix

- **Examples:** new UI components, API endpoints, bug fixes, test additions
- **Review requirement:** At least **one approved review** from a code owner or designated reviewer
- **Merge policy:** Merge after approval and CI passes
- **Turnaround target:** Within 1 business day

### T2 — Security / Infrastructure / Breaking Change

- **Examples:** authentication changes, database migrations, infrastructure modifications, breaking API changes, dependency upgrades with security implications
- **Review requirement:** **Admin-level approval** required (team lead or security reviewer)
- **Merge policy:** Merge only after admin approval and CI passes
- **Turnaround target:** Within 2 business days

### General Review Guidelines

- Reviewers should focus on correctness, security, performance, and maintainability
- Use GitHub suggestions for small changes
- Request changes rather than approving with unresolved concerns
- Be respectful and constructive in all feedback

---

## Testing Requirements

All contributions must include appropriate test coverage.

### Unit Tests (Required)

- Every new function, method, or component must have corresponding unit tests
- Bug fixes must include a regression test that reproduces the original issue
- Aim for meaningful coverage, not just line-count metrics

### Integration Tests (Required for API Changes)

- Any change to an API endpoint (REST or GraphQL) must include integration tests
- Hasura metadata changes must include tests validating permissions and relationships
- Database migration changes must include tests verifying data integrity

### Test Commands by Service

| Service         | Command                          |
|-----------------|----------------------------------|
| Rust            | `cargo test --all`               |
| Go              | `go test ./...`                  |
| Python          | `pytest`                         |
| Frontend (web)  | `pnpm --filter web test`         |
| All (Turbo)     | `pnpm turbo run test`            |

### CI Pipeline

The CI pipeline runs all tests automatically on every PR. A PR cannot be merged if any test fails. The pipeline includes:

1. Linting and formatting checks
2. Unit tests for all affected packages
3. Integration tests for affected services
4. Build verification

---

## Documentation Requirements

- Any change to a **public API** must include corresponding documentation updates
- New features must include usage examples in the relevant documentation
- Architecture changes must update `docs/ARCHITECTURE.md`
- Environment or dependency changes must update `docs/ENVIRONMENT_SETUP.md`
- ADRs (Architecture Decision Records) must be created for significant technical decisions in `docs/adr/`
- Inline code comments should explain "why," not "what"

---

## AIDD Compliance

VoxGuard follows an **AI-Driven Development (AIDD)** methodology. All contributions, whether human or AI-generated, must comply with the following:

### Tier Declaration

Every pull request **must** declare its AIDD tier (T0, T1, or T2) in the PR description. This determines the review and approval workflow. See [docs/AIDD_APPROVAL_TIERS.md](docs/AIDD_APPROVAL_TIERS.md) for full tier definitions and examples.

### Autonomous Agent Contributions

Contributions generated by autonomous AI agents (e.g., Claude Code, GitHub Copilot Workspace, or similar tools) must:

1. **Tag the AI as co-author** in the commit message footer:

   ```
   Co-Authored-By: Claude <noreply@anthropic.com>
   ```

2. **Declare the contribution as AI-assisted** in the PR description
3. **Undergo the same review process** as human-authored code — AI-generated code receives no special exemptions
4. **Pass all automated checks** including linting, formatting, and tests
5. **Include human verification** — a human contributor must verify the AI output before marking the PR as ready for review

### Accountability

The human who opens the PR is responsible for all code within it, regardless of whether it was written by a human or an AI agent. AI tooling is an accelerator, not a substitute for engineering judgment.

---

## Questions?

If you have questions about contributing, please open a [GitHub Discussion](https://github.com/<org>/VoxGuard/discussions) or reach out to the maintainers.

Thank you for contributing to VoxGuard.
