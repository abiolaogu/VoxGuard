# 🏭 Factory v4.0: Developer Handbook

> **Welcome to the Autonomous Software Factory**
> This is not just a code template. This is an active Assembly Line where AI Agents (Claude) work alongside humans to build, ship, and evolve products at unprecedented velocity.

---

## 📖 Table of Contents

1. [The Concept](#-the-concept)
2. [Getting Started](#-getting-started)
3. [The 5 Engines](#-the-5-engines)
4. [Rules of Engagement](#-rules-of-engagement)
5. [Manual Override & Troubleshooting](#-manual-override--troubleshooting)

---

## 🧠 The Concept

### What is Factory v4.0?

Factory v4.0 transforms GitHub repositories into **autonomous manufacturing plants** for software. Instead of manually managing CI/CD, market research, and product evolution, you configure intelligent workflows that:

- **Listen** to market signals and auto-generate feature requests
- **Derive** new products from a monorepo template by spinning out polyrepos
- **Sync** code bidirectionally between parent and child repositories
- **Generate** marketing assets automatically when you publish a release
- **Enforce** tiered autonomy rules based on code risk level

### The Assembly Line Metaphor

Think of your repository as a factory floor with different stations:

| **Station** | **Function** | **Automation Level** |
|-------------|--------------|----------------------|
| 🧬 **Genesis** | Initialize new repos with CLAUDE.md context | Human-triggered |
| 🔬 **Research Loop** | Scan the web daily for product-specific intelligence | Fully Autonomous |
| 🧩 **Derivation** | Extract products from monorepo to polyrepo | Semi-Autonomous |
| 🔄 **Neural Sync** | Bidirectional code sync between repos | On-Demand |
| 📢 **Go-to-Market** | Auto-generate marketing assets on release | Fully Autonomous |

**Key Insight:** AI Agents (Claude) are first-class citizens in this factory. They don't just assist—they actively operate the machinery based on rules you define.

---

## 🚀 Getting Started

### Step 1: Create a New Repository from This Template

1. Navigate to [billyronks/factory-template](https://github.com/billyronks/factory-template)
2. Click **"Use this template"** → **"Create a new repository"**
3. Name your repository (e.g., `my-awesome-product`)
4. Choose **Public** or **Private** based on your needs
5. Click **"Create repository"**

### Step 2: Configure Required Secrets

⚠️ **CRITICAL:** Before using any Factory v4.0 workflows, you MUST configure these secrets in your repository:

#### Navigate to: `Settings → Secrets and variables → Actions → New repository secret`

#### 1️⃣ **ANTHROPIC_API_KEY**
- **Purpose:** Powers Claude Code Action for AI-driven product derivation, market intelligence, and code generation
- **How to get it:**
  - Go to [Anthropic Console](https://console.anthropic.com/)
  - Create an API key
  - Copy the key (starts with `sk-ant-...`)
- **Used by:**
  - Research Loop (market intelligence scanning)
  - Product Derivation (transforming monorepo to polyrepo)
  - Bidirectional Sync (intelligent code merging)
  - Marketing Automation (content generation)

#### 2️⃣ **FACTORY_ADMIN_TOKEN**
- **Purpose:** GitHub Personal Access Token (PAT) for creating repositories and managing workflows across your GitHub organization
- **Required Scopes:**
  - ✅ `repo` (full control of private repositories)
  - ✅ `workflow` (update GitHub Actions workflows)
- **How to create:**
  - Go to [GitHub Token Settings](https://github.com/settings/tokens)
  - Click **"Generate new token (classic)"**
  - Select the required scopes above
  - Set expiration (recommend 90 days or "No expiration" for production factories)
  - Copy the token (starts with `ghp_...`)
- **Used by:**
  - Product Derivation (creates new child repositories)
  - Bidirectional Sync (pushes code to child repos)
  - Module Injection (clones and transplants code modules)

### Step 3: Verify Installation

Run this command in your terminal to ensure everything is configured:

```bash
# Clone your new repository
git clone https://github.com/your-org/your-repo.git
cd your-repo

# Check for critical files
ls -la CLAUDE.md .coderabbit.yaml .github/workflows/

# Run a test workflow (if you have gh CLI installed)
gh workflow run research-loop.yml
```

If all files are present and workflows execute, you're ready to build! 🎉

---

## 🔧 The 5 Engines

### 1️⃣ Genesis: CLAUDE.md Context Engine

**File:** `CLAUDE.md`

**Purpose:** This file is the "DNA" of your factory. It tells AI agents:
- What your product is
- What tech stack to use
- Security rules (never print secrets)
- Tiered autonomy rules (which PRs can auto-merge)

**How to Use:**

1. **Edit CLAUDE.md for your product:**
   ```markdown
   ## Identity
   You are building a SaaS platform for HR automation.

   ## Tech Stack
   - Frontend: React + TypeScript
   - Backend: Node.js + PostgreSQL
   - Hosting: AWS Lambda
   ```

2. **Define your Assembly Line Tiers:**
   ```markdown
   ## The Assembly Line
   - **Tier 0:** Docs, Tests → Auto-Merge
   - **Tier 1:** Features, Bug Fixes → Request Review
   - **Tier 2:** Auth, Payments, Infrastructure → REQUIRE ADMIN APPROVAL
   ```

3. **Commit and push:**
   ```bash
   git add CLAUDE.md
   git commit -m "docs: Update factory context for HR SaaS"
   git push
   ```

**Pro Tip:** AI agents read CLAUDE.md before every workflow run. Keep it up-to-date as your product evolves!

---

### 2️⃣ Research Loop: Continuous Market Intelligence

**Workflow:** `.github/workflows/research-loop.yml`

**Purpose:** Runs daily to scan the web for product-specific market intelligence and auto-creates GitHub issues for competitive features, regulatory changes, or viral user complaints.

**How It Works:**

1. **Extracts project context** from `CLAUDE.md` (first 5 lines)
2. **Scans news feeds** via Google News and TechCrunch RSS
3. **Semantic filtering** using Claude to determine relevance
4. **Auto-creates issues** with label `strategic-opportunity` if a trend is actionable

**When to Use:**

- **Automatic:** Runs daily at 8 AM UTC via cron schedule
- **Manual Trigger:** Go to **Actions** → **Continuous Market Intelligence** → **Run workflow**

**Example Output:**

```
Issue #42: Opportunity: Competitor X launches AI-powered resume parsing
Label: strategic-opportunity
Body: Relevance Analysis: Direct competitor in HR space launched feature that
      automates resume parsing using GPT-4. We should implement this to stay competitive.
Source: https://techcrunch.com/...
```

**Script:** You can also run the research scanner manually:

```bash
python scripts/market_scan.py
```

**Configuration:**

Edit the workflow to change scan frequency:
```yaml
on:
  schedule:
    - cron: '0 8 * * *' # Change to '0 */6 * * *' for every 6 hours
```

---

### 3️⃣ Derivation: Monorepo to Polyrepo Transformation

**Workflow:** `.github/workflows/derive-product.yml`

**Purpose:** Extracts a standalone product from your monorepo and spins it out into a new child repository.

**How It Works:**

1. **Parse a derivation config** (e.g., `configs/derive-cms.yaml`)
2. **Create a new GitHub repository** (requires `FACTORY_ADMIN_TOKEN`)
3. **Extract specified files/folders** based on config
4. **Apply transformations** (rename imports, update package.json, etc.)
5. **Push to the new repo** with clean git history

**When to Use:**

- You have a monorepo with multiple products (e.g., `packages/cms`, `packages/api`, `packages/mobile`)
- You want to spin out `packages/cms` into its own repo for a client or open-source release
- You need to create a white-labeled version of your core product

**How to Run:**

1. **Create a derivation config** at `configs/derive-cms.yaml`:
   ```yaml
   derivation:
     target:
       repository: "billyronks/cms-standalone"
       visibility: private
     extraction:
       include:
         - "packages/cms/**"
         - "packages/shared/utils/**"
       exclude:
         - "**/*.test.ts"
         - "**/node_modules/**"
     replacements:
       - pattern: "@monorepo/cms"
         replacement: "@cms-standalone/core"
       - pattern: "import.*from.*'@monorepo/shared'"
         replacement: "import { utils } from './utils'"
   ```

2. **Trigger the workflow:**
   ```bash
   gh workflow run derive-product.yml -f config_file=configs/derive-cms.yaml
   ```

3. **Wait for Claude to transform the code:**
   - The workflow will create `billyronks/cms-standalone`
   - Extract files from `packages/cms`
   - Apply all replacements
   - Push to the new repo

**Alternative Workflow:** `.github/workflows/monorepo-to-polyrepo.yml` (older, simpler version)

---

### 4️⃣ Neural Sync: Bidirectional Code Sharing

**Workflow:** `.github/workflows/bidirectional-sync.yml`

**Purpose:** Keep code in sync between a parent (monorepo) and child (polyrepo) repository. Changes in either repo can be synced to the other.

**How It Works:**

1. **Checkout both repos** (parent and child)
2. **Compare files** based on path mapping (e.g., `packages/core:src/core`)
3. **Intelligent merge** using Claude if conflicts exist
4. **Push changes** to the target repo

**When to Use:**

- You derived a product (Engine #3) and want to push updates from parent → child
- A client made changes to their child repo and you want to pull improvements back to parent
- You're maintaining a shared component library across multiple products

**How to Run:**

**Scenario A: Push Updates from Parent to Child**
```bash
gh workflow run bidirectional-sync.yml \
  -f target_repo=billyronks/cms-standalone \
  -f sync_path=packages/cms:src
```

**Scenario B: Pull Changes from Child to Parent**
```bash
# Run from the CHILD repo
gh workflow run bidirectional-sync.yml \
  -f target_repo=billyronks/factory-template \
  -f sync_path=src:packages/cms
```

**Path Mapping Format:**
- `source_path:target_path`
- Example: `packages/core:src/core` means:
  - Source: `packages/core/` in current repo
  - Target: `src/core/` in target repo

**Conflict Resolution:**
- If files differ, Claude will attempt to merge them
- If Claude can't merge automatically, it creates a PR for human review

---

### 5️⃣ Go-to-Market: Automated Marketing Content

**Workflow:** `.github/workflows/marketing-automation.yml`

**Purpose:** When you publish a GitHub Release, this workflow auto-generates marketing assets (blog post, social media posts, press release) based on your release notes.

**How It Works:**

1. **Triggered** when you publish a release on GitHub
2. **Extracts release notes** from the release body
3. **Generates 3 marketing assets** using Claude:
   - `marketing/blog-post.md`: Technical blog announcement
   - `marketing/social-posts.md`: 5 LinkedIn/Twitter posts
   - `marketing/press-release.md`: Formal press release
4. **Opens a review issue** for the marketing team

**When to Use:**

- You're ready to announce a new version to the world
- You want consistent, professional marketing copy
- You need to move fast and don't have time to write 3 versions of the same announcement

**How to Trigger:**

1. **Create and publish a GitHub Release:**
   ```bash
   # Via GitHub UI: Releases → Draft a new release
   # Or via gh CLI:
   gh release create v1.2.0 --title "AI-Powered Resume Parser" --notes "Added GPT-4 integration for resume parsing. 10x faster than manual review."
   ```

2. **Wait for the workflow to complete** (~2 minutes)

3. **Review the generated content:**
   - Go to **Issues** → Find "Marketing Assets for Release v1.2.0"
   - Review the social posts in the issue body
   - Check `marketing/blog-post.md` and `marketing/press-release.md` in a new PR

4. **Publish or edit:**
   - If approved, copy content to your blog/social media
   - If edits needed, update the files in the PR and merge

**Pro Tip:** Edit the workflow prompt to match your brand voice:
```yaml
prompt: |
  Style: Edgy, developer-focused, use emojis. Sound like Elon Musk announcing a SpaceX launch.
```

---

## ⚖️ Rules of Engagement

### Tiered Autonomy System

Factory v4.0 uses a **3-tier risk system** defined in `.coderabbit.yaml` to determine how much automation is allowed:

| **Tier** | **Risk Level** | **Example Files** | **Automation** | **Review Required** |
|----------|----------------|-------------------|----------------|---------------------|
| **Tier 0** | Low Risk | `docs/**`, `*.test.ts`, `README.md` | ✅ Auto-Merge | None (optional human review) |
| **Tier 1** | Medium Risk | `src/features/**`, `src/utils/**` | ⏸️ Request Review | 1 human approval required |
| **Tier 2** | High Risk | `src/auth/**`, `src/payments/**`, `infrastructure/**` | 🔒 Strict Gating | 2 approvals + security team review |

### How It Works

1. **CodeRabbit analyzes PR** based on `.coderabbit.yaml` rules
2. **Matches file paths** to tier definitions
3. **Applies automation policy:**
   - **Tier 0:** If all changes are in `docs/` or `**/*.test.ts`, CodeRabbit can auto-approve (if configured)
   - **Tier 1:** Requests review from team members, requires 1 approval before merge
   - **Tier 2:** Requires 2 approvals + mandatory `billyronks/security-team` review

### Configuration

**File:** `.coderabbit.yaml`

```yaml
policy:
  # Tier 0: Low Risk (Docs, Tests) -> Auto-approval allowed
  - name: "Tier 0: Low Risk"
    conditions:
      - "files MATCHING 'docs/**'"
      - "files MATCHING '**/*.test.ts'"
    auto_approve: true

  # Tier 2: High Risk (Auth, Payments) -> Strict Human Review
  - name: "Tier 2: Critical Security"
    conditions:
      - "files MATCHING 'src/auth/**'"
      - "files MATCHING 'src/payments/**'"
      - "files MATCHING 'infrastructure/**'"
    require_approval_count: 2
    required_reviewers:
      - "billyronks/security-team"
```

### Customizing Tiers for Your Product

**Example: Add Tier 0 for config files:**
```yaml
- name: "Tier 0: Low Risk"
  conditions:
    - "files MATCHING 'docs/**'"
    - "files MATCHING '**/*.test.ts'"
    - "files MATCHING 'configs/**/*.yaml'"  # Add this line
  auto_approve: true
```

**Example: Protect ML models as Tier 2:**
```yaml
- name: "Tier 2: Critical Security"
  conditions:
    - "files MATCHING 'src/auth/**'"
    - "files MATCHING 'src/payments/**'"
    - "files MATCHING 'infrastructure/**'"
    - "files MATCHING 'models/**'"  # Add this line
  require_approval_count: 2
  required_reviewers:
    - "billyronks/security-team"
    - "billyronks/ml-team"  # Add ML team review
```

---

## 🛠️ Manual Override & Troubleshooting

### When Workflows Fail

If any workflow fails, you have 3 options:

#### Option 1: Check Logs

1. Go to **Actions** tab in GitHub
2. Click the failed workflow run
3. Expand the failed step to see error logs
4. Common issues:
   - **Missing Secrets:** Verify `ANTHROPIC_API_KEY` and `FACTORY_ADMIN_TOKEN` are set
   - **Permission Denied:** Ensure PAT has `repo` and `workflow` scopes
   - **API Rate Limit:** Wait 1 hour or use a different API key

#### Option 2: Re-run the Workflow

1. Go to **Actions** → Failed workflow run
2. Click **"Re-run failed jobs"**
3. If issue persists, try **"Re-run all jobs"**

#### Option 3: Manual Execution

If the workflow keeps failing, you can run the underlying scripts manually:

**Research Loop:**
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
export GITHUB_TOKEN="ghp_..."
export GITHUB_REPOSITORY="your-org/your-repo"
python scripts/market_scan.py
```

**Derivation (conceptual example):**
```bash
# Clone target repo
git clone https://github.com/your-org/new-product.git
cd new-product

# Manually copy files from monorepo
cp -r ../factory-template/packages/cms/* ./src/

# Update imports (use find/replace or sed)
find . -type f -name "*.ts" -exec sed -i 's/@monorepo\/cms/@cms-standalone\/core/g' {} +

# Commit and push
git add .
git commit -m "chore: Initial derivation from monorepo"
git push origin main
```

**Bidirectional Sync (manual merge):**
```bash
# Add child repo as a remote
git remote add child-repo https://github.com/your-org/child-repo.git
git fetch child-repo

# Cherry-pick specific commits
git cherry-pick abc123def456

# Or merge a branch
git merge child-repo/feature-branch
```

### Common Issues

| **Error** | **Cause** | **Solution** |
|-----------|-----------|--------------|
| `ANTHROPIC_API_KEY not found` | Secret not configured | Add secret in Settings → Secrets → Actions |
| `gh: command not found` | GitHub CLI not installed | Workflows don't require gh CLI locally, but if testing manually: `brew install gh` |
| `Permission denied (publickey)` | FACTORY_ADMIN_TOKEN missing `repo` scope | Recreate PAT with correct scopes |
| `Repository already exists` | Derivation tried to create existing repo | Delete the target repo or change target name in config |
| `No changes to sync` | Source and target repos are identical | This is normal—nothing to sync |
| `Claude timeout` | API request took too long | Re-run the workflow; usually resolves itself |

### Disabling AI Automation (Emergency Brake)

If AI agents are making unwanted changes, you can temporarily disable automation:

1. **Pause Research Loop:**
   ```yaml
   # In .github/workflows/research-loop.yml
   on:
     # schedule:
     #   - cron: '0 8 * * *'  # Comment out cron
     workflow_dispatch:  # Keep manual trigger
   ```

2. **Disable Auto-Merge:**
   ```yaml
   # In .coderabbit.yaml
   policy:
     - name: "Tier 0: Low Risk"
       conditions:
         - "files MATCHING 'docs/**'"
       auto_approve: false  # Change to false
   ```

3. **Remove Anthropic API Key (nuclear option):**
   - Settings → Secrets → Actions → Delete `ANTHROPIC_API_KEY`
   - All AI workflows will fail, but core git operations still work

---

## 📚 Additional Resources

- **Universal Transformation Kit:** See `docs/universal-transformation-kit.md` for cross-repo CI/CD system
- **Architecture Audit Script:** Run `python scripts/architecture_audit.py` to validate factory integrity
- **Claude Code Action Docs:** [anthropics/claude-code-action](https://github.com/anthropics/claude-code-action)
- **BillyRonks Global Constitution:** Read `CLAUDE.md` for the full factory operating system

---

## 🎯 Quick Reference

### Essential Commands

```bash
# Trigger market research scan
gh workflow run research-loop.yml

# Derive a new product
gh workflow run derive-product.yml -f config_file=configs/derive-cms.yaml

# Sync code to child repo
gh workflow run bidirectional-sync.yml -f target_repo=org/child -f sync_path=packages/core:src

# Run local market scan
python scripts/market_scan.py

# Validate factory architecture
python scripts/architecture_audit.py
```

### Key Files

- `CLAUDE.md` - Factory DNA (context for AI agents)
- `.coderabbit.yaml` - Tiered autonomy rules
- `.github/workflows/research-loop.yml` - Market intelligence scanner
- `.github/workflows/derive-product.yml` - Product derivation engine
- `.github/workflows/bidirectional-sync.yml` - Code sync engine
- `.github/workflows/marketing-automation.yml` - Marketing content generator

---

**Welcome to the future of software development. Ship fast. Build autonomously. Stay ahead.**

🏭 **Factory v4.0** | Powered by Claude & BillyRonks Global
