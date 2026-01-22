# GitHub Copilot Workspace Agent - Human Playbook

## Quick Start: Your AI Teammate

GitHub Copilot Workspace Agent is your autonomous development partner. This playbook shows you exactly how to delegate work effectively.

## The 3-Second Rule

**Feature Request** → Assign issue to @copilot with title: `Feat: Add [X]`
**Bug Fix** → Assign issue to @copilot with title: `Fix: [Error] in [File]`
**Test Generation** → Assign issue to @copilot with title: `Test: [Module]`
**Documentation** → Assign issue to @copilot with title: `Docs: Update [Feature]`

That's it. Copilot handles the rest.

## Command Templates

### Feature Requests

**Template:**
```
Title: Feat: Add [feature name]

@copilot

Implement [specific feature]. Requirements:
- [Requirement 1]
- [Requirement 2]
- [Requirement 3]

Acceptance criteria:
- [ ] [Criterion 1]
- [ ] [Criterion 2]

Follow existing patterns in [relevant file/module].
```

**Example:**
```
Title: Feat: Add competitor price tracking

@copilot

Implement a competitor price tracking module. Requirements:
- Fetch pricing data from specified competitor URLs
- Store historical pricing in JSON format
- Generate price comparison reports
- Send alerts when competitor prices drop below ours

Acceptance criteria:
- [ ] Can track multiple competitors simultaneously
- [ ] Handles network failures gracefully
- [ ] Generates daily summary reports
- [ ] Includes comprehensive test coverage

Follow existing patterns in scripts/market_scan.py.
```

### Bug Fixes

**Template:**
```
Title: Fix: [Brief error description]

@copilot

**Error**: [Exact error message or unexpected behavior]

**Location**: [File path and line number if known]

**Steps to reproduce**:
1. [Step 1]
2. [Step 2]
3. [Error occurs]

**Expected behavior**: [What should happen]

**Actual behavior**: [What currently happens]
```

**Example:**
```
Title: Fix: Date parsing fails for ISO 8601 format

@copilot

**Error**: ValueError: time data '2024-01-15T10:30:00Z' does not match format '%Y-%m-%d'

**Location**: scripts/market_scan.py line 127

**Steps to reproduce**:
1. Run `python scripts/market_scan.py --date 2024-01-15T10:30:00Z`
2. Script crashes with ValueError

**Expected behavior**: Should parse ISO 8601 dates correctly

**Actual behavior**: Only parses YYYY-MM-DD format

**Fix should**:
- Handle ISO 8601 format (with and without timezone)
- Maintain backward compatibility with existing format
- Add test cases for various date formats
```

### Test Generation

**Template:**
```
Title: Test: [Module or feature to test]

@copilot

Add comprehensive tests for [module/feature]. Focus on:
- [Test category 1]
- [Test category 2]
- [Test category 3]

Target coverage: [percentage or specific scenarios]
```

**Example:**
```
Title: Test: market_scan.py API error handling

@copilot

Add comprehensive tests for scripts/market_scan.py. Focus on:
- Network timeout scenarios
- API rate limiting responses (429 errors)
- Malformed JSON responses
- Empty result sets
- Invalid API keys

Target coverage: 100% of error handling paths

Use pytest fixtures to mock external API calls.
```

### Documentation Updates

**Template:**
```
Title: Docs: [What to document]

@copilot

Update documentation for [feature/module]. Include:
- [Documentation need 1]
- [Documentation need 2]
- [Documentation need 3]

Follow [specific style guide if applicable].
```

**Example:**
```
Title: Docs: Update README for new sync features

@copilot

Update README.md to document the new bidirectional sync capabilities. Include:
- Overview of sync functionality
- Configuration instructions (sync-config.yaml)
- Usage examples for both factory→product and product→factory sync
- Conflict resolution strategies
- Troubleshooting common sync issues

Follow the existing README structure. Add a new "Bidirectional Sync" section after "Product Derivation".
```

### Refactoring

**Template:**
```
Title: Refactor: [What to refactor]

@copilot

Refactor [module/function] to [goal]. Requirements:
- [Requirement 1]
- [Requirement 2]
- Maintain backward compatibility: [Yes/No]

Current issues:
- [Issue 1]
- [Issue 2]
```

**Example:**
```
Title: Refactor: Convert architecture_audit.py to class-based design

@copilot

Refactor scripts/architecture_audit.py to use a class-based design. Requirements:
- Create ArchitectureAuditor class with methods for each audit type
- Maintain all existing functionality
- Improve testability by allowing dependency injection
- Maintain backward compatibility: Yes (CLI interface must stay the same)

Current issues:
- Functions have too many parameters (code smell)
- Difficult to mock dependencies for testing
- Global state makes parallel execution impossible
```

## Tier System: What Copilot Can Auto-Execute

### Tier 0: Full Autonomy ✅ Auto-Merge Eligible

Copilot will implement and submit immediately:
- Documentation (READMEs, docstrings, comments)
- Test additions (unit tests, integration tests)
- Code quality fixes (formatting, linting, type hints)
- Low-risk utilities (helper functions, data transformations)

**Your action**: Just review the PR when it's ready. May be auto-merged if validations pass.

### Tier 1: Standard Review 🔍 Request Review

Copilot will implement but will request your review:
- New features (API endpoints, business logic)
- Bug fixes (logic changes)
- Refactoring (architectural changes)
- Database changes (schema migrations)
- Dependency updates (major versions)

**Your action**: Review PR and approve/request changes. Merge when satisfied.

### Tier 2: Admin Approval Required 🚨 Security Critical

Copilot will ASK FIRST before implementing:
- Authentication changes (login, sessions, tokens)
- Authorization changes (permissions, access control)
- Payment processing (billing, transactions)
- Security infrastructure (rate limiting, encryption)
- Infrastructure as code (Terraform, Kubernetes)

**Your action**: Review proposal in issue. Give explicit approval before Copilot proceeds.

## Advanced Usage Patterns

### Multi-Step Features (Recommended Approach)

Instead of one massive issue, break it down:

**Bad (single issue):**
```
Title: Build complete analytics dashboard

@copilot Add analytics dashboard with graphs, filters, export, etc.
```

**Good (multiple issues):**
```
Issue 1: Feat: Add data collection for analytics
Issue 2: Feat: Add analytics API endpoints
Issue 3: Test: Add analytics endpoint tests
Issue 4: Docs: Document analytics API
Issue 5: Feat: Add analytics dashboard UI (frontend)
```

This approach:
- Allows incremental review
- Reduces PR size
- Enables parallel work
- Makes rollback easier if issues arise

### Referencing Existing Code

Help Copilot understand your codebase context:

```
Title: Feat: Add sentiment analysis to market research

@copilot

Implement sentiment analysis similar to scripts/market_scan.py patterns.

Key patterns to follow:
- Use the same API client setup (lines 15-30)
- Follow the same error handling strategy (lines 45-60)
- Output format should match existing report structure
- Add tests in the same style as tests/test_market_scan.py
```

### Providing Test Data

Give Copilot example inputs/outputs:

```
Title: Test: Add validation tests for product config

@copilot

Add tests for config/product-config.yaml validation.

Test with this valid config:
```yaml
product_name: "MyApp"
tech_stack: "python"
features: ["api", "cli"]
```

And these invalid configs:
```yaml
# Missing required field
tech_stack: "python"

# Invalid tech stack
product_name: "MyApp"
tech_stack: "invalid"
```

Expected: Valid config passes, invalid configs raise ConfigValidationError.
```

### Requesting Specific Patterns

Tell Copilot exactly what you want:

```
Title: Feat: Add retry logic to API clients

@copilot

Add exponential backoff retry logic to all API clients in scripts/.

Pattern to use:
```python
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=2, max=10))
def fetch_data():
    # existing code
```

Apply to:
- scripts/market_scan.py: fetch_trends() function
- scripts/architecture_audit.py: fetch_repo_data() function

Add tenacity to requirements.txt.
```

## Reviewing Copilot's PRs

### What to Check

1. **Does it work?** Pull the branch and test locally
2. **Tests included?** Every code change should have tests
3. **Follows patterns?** Code style matches existing codebase
4. **Complete?** All acceptance criteria met
5. **Secure?** No credentials leaked, inputs validated

### Giving Feedback

If changes are needed, comment on the PR:

```
@copilot

Good start, but please make these changes:

1. The date parsing logic should also handle timezone-aware datetimes
2. Add a test case for empty result sets
3. The error message should include the invalid date format that was attempted

Update the PR and I'll review again.
```

Copilot will iterate on your feedback.

## Troubleshooting

### Copilot Didn't Respond

**Check:**
- Did you mention @copilot in the issue?
- Is the issue assigned to Copilot?
- Are there any GitHub Actions failures?

### PR Failed Validation

**What happens:**
Copilot's PR may fail if:
- Tests don't pass
- Code doesn't pass linting
- Type checking fails

**What to do:**
- Copilot should auto-fix and update the PR
- If not, comment with the specific failure and ask for a fix

### Copilot Misunderstood the Task

**What to do:**
```
@copilot

This isn't quite what I needed. Let me clarify:

[More specific requirements]

Please update the PR with these changes.
```

### Need to Update Validation Rules

If you need to change what Copilot validates before submitting PRs:

1. Edit `.github/copilot-setup-steps.yml`
2. Commit changes
3. Copilot will use new rules for future PRs

## Best Practices Checklist

- [ ] Use clear, specific titles following convention (Feat:, Fix:, Test:, Docs:)
- [ ] Include acceptance criteria for features
- [ ] Reference existing code patterns when possible
- [ ] Break large features into smaller issues
- [ ] Provide example inputs/outputs for complex logic
- [ ] Review PRs thoroughly before merging
- [ ] Give specific feedback when requesting changes
- [ ] Test Copilot's changes locally before merging

## Common Task Patterns

### Adding a New Script

```
Title: Feat: Add competitor analysis script

@copilot

Create scripts/competitor_analysis.py following the structure of scripts/market_scan.py.

Features:
- Fetch competitor data from [source]
- Analyze pricing, features, positioning
- Generate comparison report in markdown
- Support CLI arguments: --competitor [name] --output [path]

Include:
- Type hints for all functions
- Docstrings (Google style)
- Unit tests in tests/test_competitor_analysis.py
- Error handling with descriptive messages
```

### Updating Configuration

```
Title: Feat: Add new product derivation template

@copilot

Create templates/config/saas-product-template.yaml for SaaS products.

Include sections for:
- Tech stack (frontend, backend, database)
- Authentication method
- Payment provider
- Deployment target (cloud platform)
- Feature flags

Follow the structure of templates/config/product-derivation-template.yaml.
Add validation schema to templates/config/universal-config-schema.yaml.
```

### Performance Optimization

```
Title: Fix: Optimize market_scan.py for large datasets

@copilot

Optimize scripts/market_scan.py to handle 10,000+ trend results.

Current issue: Script becomes slow with large result sets (>5000 items)

Improvements needed:
- Add pagination to API calls
- Implement batch processing (chunks of 100)
- Add progress indicator for long operations
- Cache API responses (5-minute TTL)

Maintain backward compatibility. Add performance tests.
```

## Integration with Factory Template

This repository follows the **Autonomous Factory Constitution** (`CLAUDE.md`). When working with Copilot:

- **Speed matters**: Tier 0 tasks should be completed quickly
- **Safety first**: Tier 2 tasks require extra caution
- **Tech stack aware**: Copilot knows this is a Python project
- **Testing required**: All code changes need tests

Copilot is configured to align with these principles automatically.

## Resources

- **Agent Constitution**: `.github/copilot-instructions.md` - What rules Copilot follows
- **Setup Configuration**: `.github/copilot-setup-steps.yml` - How Copilot validates work
- **Detailed Usage Guide**: `docs/COPILOT_USAGE.md` - Extended documentation
- **Factory Constitution**: `CLAUDE.md` - Overall factory principles

## Quick Reference Card

```
╔════════════════════════════════════════════════════════════════╗
║               COPILOT WORKSPACE AGENT CHEAT SHEET              ║
╠════════════════════════════════════════════════════════════════╣
║ FEATURE    │ Feat: Add [X]                                     ║
║ BUG FIX    │ Fix: [Error] in [File]                            ║
║ TESTS      │ Test: [Module]                                    ║
║ DOCS       │ Docs: Update [Feature]                            ║
║ REFACTOR   │ Refactor: [Component]                             ║
╠════════════════════════════════════════════════════════════════╣
║ TIER 0     │ Docs, Tests → Auto-merge eligible                 ║
║ TIER 1     │ Features, Bugs → Review required                  ║
║ TIER 2     │ Auth, Payments → Admin approval required          ║
╠════════════════════════════════════════════════════════════════╣
║ ALWAYS INCLUDE: Acceptance criteria, example code, patterns    ║
║ BREAK DOWN: Large features into multiple small issues          ║
║ REVIEW: Every PR before merging, even Tier 0                   ║
╚════════════════════════════════════════════════════════════════╝
```

---

**Ready to delegate?** Create an issue, mention @copilot, and watch your AI teammate get to work.
