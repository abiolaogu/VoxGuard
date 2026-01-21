# Factory Template v4.0

⚠️ **FACTORY v4.0 SETUP REQUIREMENT**

Any repository created from this template MUST have these two secrets added immediately to work:

- **ANTHROPIC_API_KEY**: Your AI Key.
- **FACTORY_ADMIN_TOKEN**: A Personal Access Token (PAT) with `repo` and `workflow` permissions.

---

## Overview

The Factory Template is a universal product derivation system for BillyRonks Global. It enables rapid creation of specialized products from a common codebase using AI-powered transformation workflows.

This template implements the **Factory v4.0 Stable** standard, providing automated product extraction, bidirectional synchronization, and intelligent conflict detection.

---

## Features

### 🏭 Universal Product Derivation
Extract standalone products from the factory template using declarative YAML configurations. The system automatically:
- Analyzes extraction patterns defined in config files
- Copies relevant files and folders to new repositories
- Applies custom replacements and transformations
- Removes excluded paths
- Maintains clean git history

### 🔄 Bidirectional Sync
Keep derived products and the factory template synchronized:
- Downstream sync: Push factory improvements to all derived products
- Upstream sync: Pull product-specific improvements back to the factory
- Configurable sync strategies (bidirectional, downstream-only, upstream-only)
- Automatic conflict detection and resolution workflows

### 🤖 AI-Powered Transformation
Leverages Claude Code Action for intelligent code transformations:
- Context-aware file extraction
- Smart dependency resolution
- Automatic configuration updates
- Preservation of code semantics

### 🛡️ Conflict Detection
Built-in conflict detection system identifies and resolves synchronization issues:
- Path overlap detection
- Dependency conflict analysis
- Automated conflict reports
- Manual resolution workflows

---

## Quick Start

### 1. Create a New Repository from Template
Click **"Use this template"** on GitHub to create your new factory instance.

### 2. Add Required Secrets
Navigate to **Settings → Secrets and variables → Actions** and add:
- `ANTHROPIC_API_KEY`: Your Anthropic API key ([Get one here](https://console.anthropic.com/))
- `FACTORY_ADMIN_TOKEN`: GitHub Personal Access Token with `repo` and `workflow` scopes

### 3. Create a Derivation Config
Copy and customize a config template:
```bash
cp templates/config/product-derivation-template.yaml configs/derive-my-product.yaml
```

Edit the config to specify:
- Target repository name
- Files and folders to extract
- String replacements to apply
- Paths to exclude

### 4. Run the Derivation Workflow
Go to **Actions → Universal Product Derivation** and click **"Run workflow"**. Specify your config file path (e.g., `configs/derive-my-product.yaml`).

The workflow will:
1. Parse your configuration
2. Create the target repository (if it doesn't exist)
3. Execute AI-powered transformation
4. Extract files to the new repository

---

## Directory Structure

```
factory-template/
├── .github/
│   └── workflows/
│       └── derive-product.yml          # Universal derivation workflow
├── configs/                             # Derivation configuration files
│   └── derive-cms.yaml                  # Example: CMS product config
├── scripts/
│   └── transform/
│       ├── detect_conflicts.py          # Conflict detection logic
│       └── setup_sync.sh                # Sync relationship setup
├── templates/
│   └── config/
│       ├── product-derivation-template.yaml  # Config template for derivation
│       └── sync-config-template.yaml         # Config template for sync
├── CLAUDE.md                            # AI assistant instructions
└── README.md                            # This file
```

---

## Configuration Examples

### Product Derivation Config
See `templates/config/product-derivation-template.yaml` for a complete example.

### Sync Config
See `templates/config/sync-config-template.yaml` for bidirectional sync configuration.

---

## Sync Setup

To establish bidirectional sync between the factory and a derived product:

```bash
./scripts/transform/setup_sync.sh configs/sync-my-product.yaml
```

This will:
- Parse the sync configuration
- Initialize sync manifests
- Set up GitHub Actions workflows in both repositories
- Configure automatic sync triggers

---

## Common Tasks

### Derive a New Product
```bash
# 1. Create config
cp templates/config/product-derivation-template.yaml configs/derive-my-app.yaml

# 2. Edit config with your requirements
nano configs/derive-my-app.yaml

# 3. Run workflow via GitHub Actions UI
```

### Detect Sync Conflicts
```bash
python scripts/transform/detect_conflicts.py configs/sync-my-product.yaml
```

### Update Derived Products
Push changes to the factory template's `main` branch. Downstream sync workflows will automatically propagate changes to derived products (if configured).

---

## Support

For issues, questions, or contributions, please open an issue in the repository.

---

## License

Proprietary - BillyRonks Global

---

**Built with [Claude Code](https://claude.ai/code) • Factory v4.0 Stable**
