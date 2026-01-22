# GitHub Copilot Workspace Agent Usage Guide

## Overview

This repository is configured to work with GitHub Copilot Workspace Agent, allowing you to delegate development tasks to Copilot with confidence. Copilot will automatically validate its changes against our project standards before opening pull requests.

## Configuration

The repository includes a `.github/copilot-setup-steps.yml` file that defines how Copilot validates its work. This configuration ensures:

- **Dependencies are installed** correctly
- **Tests pass** before submitting changes
- **Code formatting** follows project standards
- **Linting rules** are satisfied
- **Type checking** validates code correctness

## How to Delegate Tasks to Copilot

### 1. Open a GitHub Issue or Comment

Create a new issue or comment on an existing one with a clear description of what you want Copilot to do:

```
@copilot Create a new market analysis script that fetches trending topics from Reddit
```

### 2. Be Specific About Requirements

The more specific you are, the better Copilot can help:

```
@copilot Add unit tests for the market_scan.py script. Focus on:
- Testing API error handling
- Mocking external API calls
- Validating output format
```

### 3. Copilot Will Validate Before Submitting

Before opening a PR, Copilot automatically runs:
- Dependency installation
- Unit tests
- Code formatting checks (Black)
- Linting (Flake8)
- Type checking (MyPy)
- Syntax validation

If any step fails, Copilot will fix the issues before submitting.

## Best Practices

### Clear Task Descriptions

**Good:**
```
@copilot Add error handling to scripts/market_scan.py for network timeouts.
Include retry logic with exponential backoff (max 3 retries).
```

**Less Effective:**
```
@copilot Fix the script
```

### Break Down Complex Tasks

For large features, break them into smaller tasks:

1. First issue: "Add data validation to market_scan.py"
2. Second issue: "Add unit tests for market_scan.py validation"
3. Third issue: "Add documentation for market_scan.py functions"

### Reference Existing Code

Point Copilot to relevant files or patterns:

```
@copilot Create a new script similar to scripts/market_scan.py but for analyzing
competitor pricing. Follow the same structure and error handling patterns.
```

## Task Examples

### Adding New Features

```
@copilot Implement a new function in scripts/market_scan.py that filters results
by minimum engagement threshold (likes + shares). Add type hints and docstrings.
```

### Fixing Bugs

```
@copilot Fix the date parsing error in scripts/market_scan.py line 45. The current
implementation fails for dates in ISO format.
```

### Refactoring

```
@copilot Refactor scripts/architecture_audit.py to use a class-based approach
instead of procedural code. Maintain backward compatibility.
```

### Adding Tests

```
@copilot Add comprehensive unit tests for scripts/market_scan.py covering:
- Happy path scenarios
- Error conditions (API failures, invalid inputs)
- Edge cases (empty responses, malformed data)
```

### Documentation

```
@copilot Add detailed docstrings to all functions in scripts/market_scan.py
following Google style guide. Include parameter types, return values, and examples.
```

## What Copilot Can Do

- Write new features and functions
- Fix bugs and errors
- Add tests and improve coverage
- Refactor existing code
- Add documentation and type hints
- Update dependencies
- Improve error handling

## What Copilot Cannot Do

- Make architectural decisions without guidance
- Access external systems or APIs (it works in a sandbox)
- Merge or approve its own PRs
- Access secrets or credentials

## Reviewing Copilot's Work

Even though Copilot validates its changes, human review is essential:

1. **Check the PR description** - Does it accurately describe the changes?
2. **Review the code** - Does it follow project conventions?
3. **Verify tests** - Are edge cases covered?
4. **Test locally** - Does it work in your environment?
5. **Consider security** - Are there any security implications?

## Validation Details

### Setup Phase
Copilot installs:
- Production dependencies from `requirements.txt`
- Development tools: pytest, flake8, black, mypy

### Test Phase
- Runs pytest on the `tests/` directory
- Executes type checking with MyPy
- **Note:** As tests are added to the project, Copilot will validate against them

### Lint Phase
- **Black**: Ensures consistent code formatting (100 char line length)
- **Flake8**: Catches style violations and potential bugs

### Validate Phase
- Confirms essential project files exist
- Validates Python syntax without execution

## Troubleshooting

### Copilot's PR Failed Validation

If Copilot opens a PR that fails CI checks:
1. The `.github/copilot-setup-steps.yml` may need updates
2. Comment on the PR with specific feedback
3. Copilot can iterate on the changes

### Copilot Didn't Understand the Task

If Copilot's implementation misses the mark:
1. Provide more specific requirements in a comment
2. Reference specific files, functions, or patterns to follow
3. Include acceptance criteria

### Need to Update Validation Rules

To modify what Copilot checks:
1. Edit `.github/copilot-setup-steps.yml`
2. Add, remove, or modify validation steps
3. Commit and push changes
4. Copilot will use the new rules for future tasks

## Integration with Factory Template

This repository follows the **Autonomous Factory Constitution** (see `CLAUDE.md`). Copilot's configuration aligns with these principles:

- **Speed First**: Automated validation allows fast iteration
- **Auto-Merge Capable**: Docs and tests can be auto-merged if validation passes
- **Security**: Secrets are never logged or exposed
- **Tech Stack Aware**: Configuration adapts to Python project structure

## Additional Resources

- [GitHub Copilot Workspace Documentation](https://docs.github.com/en/copilot/using-github-copilot/using-github-copilot-workspace)
- [Factory Template README](../README.md)
- [Autonomous Factory Constitution](../CLAUDE.md)

## Support

For issues or questions about Copilot configuration:
1. Check existing [GitHub Issues](../../issues)
2. Review [Copilot Workspace Agent docs](https://docs.github.com/en/copilot)
3. Open a new issue with the `copilot` label
