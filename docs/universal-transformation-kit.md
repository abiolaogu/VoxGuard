# Universal Repository Transformation Kit

## Overview

The Universal Repository Transformation Kit is a collection of configuration-driven workflows and scripts that enable any repository to adopt the BillyRonks Global Autonomous Factory model. All components accept dynamic configuration inputs and contain no hardcoded project references.

## Components

### 1. Configuration Schema

**Location**: `templates/config/universal-config-schema.yaml`

Defines the structure for configuring any repository. Key sections:

- **Repository Metadata**: Name, type, organization
- **Tech Stack Detection**: Language, framework, package manager
- **Build/Test/Lint Configuration**: Commands and settings
- **Automation Tiers**: Three-tier system for change management
- **CI/CD Settings**: Triggers, branches, secrets
- **Market Research Integration**: Optional strategic opportunity scanning

### 2. Tech Stack Detection

**Location**: `scripts/universal/detect_tech_stack.py`

**Purpose**: Automatically detects the technology stack of any repository

**Usage**:
```bash
python scripts/universal/detect_tech_stack.py [--path PATH] [--format json|yaml]
```

**Supported Languages**: Python, JavaScript/TypeScript, Dart/Flutter, Go, Rust, Ruby, Java

**Detection Methods**:
- Package manager identification (npm, pip, cargo, etc.)
- Framework detection (React, Django, Flutter, etc.)
- Build system discovery
- Test framework identification
- Linting tool detection

**Output**: JSON/YAML structure with complete tech stack information

### 3. Universal Test Runner

**Location**: `scripts/universal/universal_test.py`

**Purpose**: Runs tests for any repository based on detected or configured tech stack

**Usage**:
```bash
python scripts/universal/universal_test.py [OPTIONS]

Options:
  --config PATH     Path to configuration file (optional)
  --coverage        Enable coverage reporting
  --command CMD     Explicitly specify test command
  --path PATH       Repository root path
```

**Features**:
- Auto-detects test framework
- Supports coverage reporting
- Works with pytest, npm test, flutter test, go test, cargo test
- Configuration priority: explicit > config file > auto-detection

### 4. Universal Build Script

**Location**: `scripts/universal/universal_build.py`

**Purpose**: Builds any repository based on detected or configured tech stack

**Usage**:
```bash
python scripts/universal/universal_build.py [OPTIONS]

Options:
  --config PATH       Path to configuration file (optional)
  --production        Build for production
  --command CMD       Explicitly specify build command
  --path PATH         Repository root path
```

**Features**:
- Auto-detects build system
- Production mode support
- Works with npm, flutter, cargo, go, python
- Configuration priority: explicit > config file > auto-detection

### 5. Universal Lint Script

**Location**: `scripts/universal/universal_lint.py`

**Purpose**: Runs linting for any repository based on detected or configured tech stack

**Usage**:
```bash
python scripts/universal/universal_lint.py [OPTIONS]

Options:
  --config PATH     Path to configuration file (optional)
  --fix             Auto-fix issues where possible
  --command CMD     Explicitly specify lint command
  --path PATH       Repository root path
```

**Features**:
- Auto-detects linting tools
- Auto-fix support
- Works with eslint, pylint, flutter analyze, cargo clippy, etc.
- Configuration priority: explicit > config file > auto-detection

### 6. Universal CI/CD Workflow

**Location**: `.github/workflows/universal-ci.yml`

**Purpose**: Implements tier-based automation system for any repository

**Features**:

#### Tier Detection
Automatically classifies changes into three tiers:

- **Tier 0 (Green)**: Documentation, Tests, Text
  - Auto-merges after passing CI
  - Paths: `docs/`, `*.md`, `tests/`, `*.txt`

- **Tier 1 (Yellow)**: Features, Logic
  - Requests human review
  - Paths: `src/`, `lib/`, `scripts/`

- **Tier 2 (Red)**: Auth, Payments, Infrastructure
  - Requires admin approval
  - Paths: `.github/workflows/`, `auth/`, `payment/`, `infrastructure/`

#### Pipeline Stages

1. **Tech Stack Detection**: Identifies language and tools
2. **Lint**: Runs appropriate linter
3. **Test**: Executes test suite with coverage
4. **Build**: Creates production build
5. **Auto-Action**: Merges, requests review, or flags for admin based on tier

#### Triggers

- Pull requests to main/master/develop
- Pushes to main/master/develop

## Integration Guide

### For New Repositories

1. **Copy the Kit**:
   ```bash
   # Copy workflows
   cp .github/workflows/universal-ci.yml YOUR_REPO/.github/workflows/

   # Copy scripts
   cp -r scripts/universal YOUR_REPO/scripts/

   # Copy config template
   cp templates/config/universal-config-schema.yaml YOUR_REPO/
   ```

2. **Configure Repository** (optional):
   - Edit `universal-config-schema.yaml` with your settings
   - Or let auto-detection handle everything

3. **Enable Workflow**:
   - Commit and push the workflow
   - The pipeline will automatically detect your tech stack

### For Existing Repositories

1. **Audit Current Setup**:
   ```bash
   python scripts/universal/detect_tech_stack.py
   ```

2. **Test Scripts Locally**:
   ```bash
   # Test linting
   python scripts/universal/universal_lint.py

   # Test building
   python scripts/universal/universal_build.py

   # Test suite
   python scripts/universal/universal_test.py
   ```

3. **Integrate Workflow**:
   - Add `universal-ci.yml` to `.github/workflows/`
   - Customize tier paths if needed

## Configuration Priority

All universal scripts follow this priority order:

1. **Explicit Command**: `--command` flag (highest priority)
2. **Config File**: `--config` flag pointing to YAML/JSON
3. **Auto-Detection**: Tech stack detection (lowest priority)

This allows maximum flexibility while maintaining zero-config operation.

## No Hardcoded Values

The transformation kit is designed with complete abstraction:

- ✅ No repository names hardcoded
- ✅ No organization names hardcoded
- ✅ No language assumptions
- ✅ No framework requirements
- ✅ No specific file structures required
- ✅ All configuration is dynamic

## Supported Tech Stacks

### Languages
- Python (pip, poetry, pipenv)
- JavaScript/TypeScript (npm, yarn, pnpm)
- Dart (pub, Flutter)
- Go (go modules)
- Rust (cargo)
- Ruby (bundler)
- Java (maven, gradle)
- C# (.NET)

### Frameworks
- **Web**: React, Vue, Angular, Svelte, Next.js, Nuxt
- **Backend**: Django, Flask, FastAPI, Express, Rails
- **Mobile**: Flutter
- **Desktop**: Electron, Flutter Desktop

### Test Frameworks
- pytest, unittest (Python)
- Jest, Mocha, Vitest (JavaScript)
- Flutter Test (Dart)
- Go Test (Go)
- Cargo Test (Rust)

### Linters
- pylint, flake8, black, ruff (Python)
- eslint, prettier (JavaScript)
- flutter analyze (Dart)
- cargo clippy (Rust)
- go vet (Go)

## Examples

### Example 1: Python Project

```bash
# Auto-detect and test
python scripts/universal/universal_test.py

# Output:
# 🔍 Auto-detecting test command...
# ✓ Detected test command: pytest
# 🧪 Running tests: pytest --cov --cov-report=html --cov-report=term
```

### Example 2: React Project

```bash
# Auto-detect and build
python scripts/universal/universal_build.py --production

# Output:
# 🔍 Auto-detecting build command...
# ✓ Detected build command: npm run build
# 🔨 Running build: npm run build
```

### Example 3: Flutter Project

```bash
# Auto-detect tech stack
python scripts/universal/detect_tech_stack.py

# Output:
# {
#   "tech_stack": {
#     "primary_language": "dart",
#     "framework": "flutter",
#     "package_manager": "pub"
#   },
#   "build": {"enabled": true, "command": "flutter build"},
#   "test": {"enabled": true, "command": "flutter test"}
# }
```

## Architecture

### Design Principles

1. **Zero Configuration**: Works out of the box with auto-detection
2. **Full Customization**: Accepts explicit configuration when needed
3. **No Hard Dependencies**: Only requires Python 3.x
4. **Language Agnostic**: Supports any language/framework
5. **Progressive Enhancement**: Detects available tools and uses them

### Extensibility

To add support for a new language:

1. Update `detect_tech_stack.py`:
   - Add language indicator to `detect_language()`
   - Add framework patterns to `detect_framework()`
   - Add build/test/lint commands

2. Test detection:
   ```bash
   python scripts/universal/detect_tech_stack.py --path /path/to/project
   ```

3. No workflow changes needed - it adapts automatically

## Troubleshooting

### Tech Stack Not Detected

**Issue**: Script doesn't detect your language/framework

**Solution**:
```bash
# Use explicit configuration
python scripts/universal/universal_test.py --command "your-test-command"
```

Or create a config file:
```yaml
tech_stack:
  test:
    command: "your-test-command"
```

### Workflow Permissions

**Issue**: Auto-merge fails with permission error

**Solution**: Enable workflow permissions in repository settings:
- Settings → Actions → General → Workflow permissions
- Enable "Read and write permissions"

### Tier Detection Issues

**Issue**: Wrong tier assigned to changes

**Solution**: Customize tier paths in `universal-ci.yml`:
```yaml
TIER_2_PATTERNS=(
  ".github/workflows/"
  "your-custom-path/"
)
```

## Contributing

To extend the transformation kit:

1. **Add New Detection Logic**: Update `detect_tech_stack.py`
2. **Add New Script**: Follow the pattern in existing universal scripts
3. **Update Documentation**: Add examples and usage
4. **Test with Multiple Projects**: Verify language-agnostic behavior

## License

Part of the BillyRonks Global Autonomous Factory system.

## Related Documentation

- [CLAUDE.md](../CLAUDE.md) - Autonomous Factory Constitution
- [Product Derivation](../templates/config/product-derivation-template.yaml) - Repository extraction system
