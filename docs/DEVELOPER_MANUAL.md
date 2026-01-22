# 🏭 Factory v4.0: Developer Handbook

> **Welcome to the Autonomous Software Factory**
> This is not just a code template. This is an active Assembly Line where AI Agents (Claude) work alongside humans to build, ship, and evolve products at unprecedented velocity.

---

## 📖 Table of Contents

1. [The Assembly Line Philosophy](#-the-assembly-line-philosophy)
2. [Getting Started](#-getting-started)
3. [The Research Loop](#-the-research-loop)
4. [Day-to-Day Workflows](#-day-to-day-workflows)
5. [The Brain: MCP Server](#-the-brain-mcp-server)
6. [The Rules: Tiered Autonomy](#-the-rules-tiered-autonomy)
7. [Manual Override & Troubleshooting](#-manual-override--troubleshooting)
8. [Quick Reference](#-quick-reference)

---

## 🤖 The Assembly Line Philosophy

### You Are Now a Factory Operator

**Traditional Software Development:**
- 👨‍💻 You write every line of code
- 🔧 You manually configure CI/CD
- 📊 You research competitors by hand
- 📝 You write documentation yourself

**Factory v4.0 Software Development:**
- 🤖 AI Agents write code based on your specifications
- ⚙️ Workflows auto-configure based on CLAUDE.md context
- 🔬 Research bots scan the market daily and create opportunity issues
- 📚 Documentation generates automatically from releases

### Your New Role

You are no longer just a developer—you are a **Factory Operator** who:
- **Configures** the assembly line (CLAUDE.md, .coderabbit.yaml)
- **Monitors** autonomous workflows (GitHub Actions)
- **Approves** critical changes (Tier 2 security reviews)
- **Steers** product direction (approving research opportunities)
- **Coordinates** AI agents (via MCP tools in your IDE)

**The Philosophy:** Let AI handle the repetitive work. You focus on architecture, product decisions, and human creativity.

---

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have:
- A GitHub account with admin access to your organization
- [GitHub CLI](https://cli.github.com/) installed (optional but recommended)
- [Python 3.8+](https://www.python.org/downloads/) for local scripts
- An IDE that supports MCP (Cursor, Windsurf, or Claude Desktop)

### Step 1: Create Your Factory

1. Navigate to [billyronks/factory-template](https://github.com/billyronks/factory-template)
2. Click **"Use this template"** → **"Create a new repository"**
3. Name your repository (e.g., `my-saas-factory`)
4. Choose **Private** (recommended) or **Public**
5. Click **"Create repository"**

### Step 2: Configure Required Secrets

⚠️ **CRITICAL:** Without these secrets, the factory cannot operate.

Navigate to: `Settings → Secrets and variables → Actions → New repository secret`

#### 1️⃣ ANTHROPIC_API_KEY

**Purpose:** Powers Claude Code Action for all AI workflows

**Get your key:**
- Visit [Anthropic Console](https://console.anthropic.com/)
- Create an API key (starts with `sk-ant-...`)
- Copy the key

**Used by:**
- Research Ingestion Pipeline
- Product Derivation
- Bidirectional Sync
- Marketing Automation
- Sales Activation

#### 2️⃣ FACTORY_ADMIN_TOKEN

**Purpose:** GitHub Personal Access Token (PAT) for cross-repo operations

**Required Scopes:**
- ✅ `repo` (full control of repositories)
- ✅ `workflow` (manage GitHub Actions)

**Create token:**
- Go to [GitHub Token Settings](https://github.com/settings/tokens)
- Click **"Generate new token (classic)"**
- Select required scopes
- Set expiration (90 days or no expiration)
- Copy the token (starts with `ghp_...`)

**Used by:**
- Product Initiation (creates new repos)
- Bidirectional Sync (pushes to child repos)
- Module Injection (clones modules)

### Step 3: Verify Installation

```bash
# Clone your new factory
git clone https://github.com/your-org/your-factory.git
cd your-factory

# Verify critical files exist
ls -la CLAUDE.md .coderabbit.yaml .github/workflows/

# Test a workflow (optional)
gh workflow run research-loop.yml
```

If all files are present, you're ready to operate the factory! 🎉

---

## 🔁 The Research Loop

### What is the Research Loop?

The **Research Loop** is Factory v4.0's autonomous intelligence gathering system. It continuously monitors the market, analyzes trends, and surfaces opportunities—all without human intervention.

Think of it as your factory's "eyes and ears" that never sleep.

### The Three Components

#### 1️⃣ Continuous Market Intelligence (Daily Automated Scanning)

**Workflow:** `.github/workflows/research-loop.yml`

**Schedule:** Every day at 8 AM UTC

**What It Does:**
- Extracts your project context from `CLAUDE.md`
- Scans news sources for competitor launches, regulatory changes, and market trends
- Filters for **signal vs. noise** (ignores generic tech news)
- Creates GitHub Issues for actionable intelligence

**Example Output:**

If a competitor launches a new feature relevant to your product:

```
Title: feat(intelligence): AI-powered invoice categorization detected in market

Body:
🕵️ Competitor Update: QuickBooks just launched AI-powered invoice categorization.

Key Features:
- Automatic expense categorization using GPT-4
- 95% accuracy claimed
- Available on Pro tier ($35/month)

Recommendation: We should implement similar categorization to stay competitive.
Our existing OCR pipeline can be extended with Claude API for this feature.

Source: TechCrunch Article (2026-01-22)
```

**Manual Trigger:**

```bash
gh workflow run research-loop.yml
```

**Customization:**

The workflow reads your `CLAUDE.md` to understand your product niche. Update your project description to improve relevance filtering:

```markdown
# CLAUDE.md
## Identity

**You are an autonomous builder for:** Invoice Processing SaaS for SMBs

**Core Features:** OCR, QuickBooks sync, expense categorization, receipt management
```

---

#### 2️⃣ Research Ingestion Pipeline (Manual Research Processing)

**Workflow:** `.github/workflows/research-ingestion.yml`

**Trigger:** When you push files to `research/incoming/`

**What It Does:**
- Detects new research files (PDFs, markdown, competitor analysis, etc.)
- Creates a GitHub Issue for each file
- Claude analyzes the content and extracts opportunities
- Posts analysis as a comment on the issue

**How to Use:**

```bash
# Step 1: Create a research file
cat > research/incoming/stripe-competitor-analysis.md <<EOF
# Stripe Expands into Invoicing

Stripe just launched "Stripe Invoicing Pro" with these features:
- Recurring invoice templates
- Multi-currency support
- Automated payment reminders
- Integration with Stripe Tax

Pricing: $50/month + 0.5% per transaction

Market Opportunity:
We could build a lighter-weight version targeting freelancers
at $15/month with similar core features but without the enterprise bloat.
EOF

# Step 2: Commit and push
git add research/incoming/stripe-competitor-analysis.md
git commit -m "research: Add Stripe invoicing competitor analysis"
git push

# Step 3: Wait for automation
# - Workflow triggers automatically
# - Issue created: "🕵️ Research Ingestion: stripe-competitor-analysis.md"
# - Claude analyzes and comments with product recommendations
```

**Claude's Analysis Format:**

```
@claude analyzed stripe-competitor-analysis.md

SUMMARY:
This document analyzes Stripe's new invoicing product targeting SMBs and enterprises.

KEY OPPORTUNITIES:
1. Underserved Market: Freelancers ($15/month price point)
2. Feature Gap: Simpler UX without enterprise complexity
3. Competitive Advantage: Faster setup (<5 minutes vs. 30+ minutes)

PRODUCT RECOMMENDATION:
Build "InvoiceLight" - A lightweight invoicing tool for freelancers/solopreneurs.
- Core features: Recurring templates, payment reminders, multi-currency
- Differentiation: Zero setup, beautiful templates, mobile-first design
- Pricing: $15/month (vs. Stripe's $50/month)

NEXT STEPS:
If approved, add label `approved-for-development` to trigger product creation.
```

**Pro Tip:** Drop any type of research here:
- Competitor changelogs (scraped from websites)
- Market research reports (PDF exports)
- Customer interview notes (markdown summaries)
- Trend analysis (Google Trends data)

---

#### 3️⃣ Context-Aware Market Scanner (Local Script)

**Script:** `scripts/market_scan.py`

**Purpose:** Run on-demand market scans locally or in CI/CD

**How It Works:**

1. **Reads Context:** Extracts project description from `CLAUDE.md` or `README.md`
2. **Fetches News:** Pulls latest articles from Google News and TechCrunch RSS feeds
3. **Semantic Filtering:** Uses Claude API to determine if each headline is relevant
4. **Deduplication:** Checks if issue already exists for this news URL
5. **Creates Issues:** Auto-generates GitHub issues for relevant opportunities

**Manual Execution:**

```bash
# Step 1: Set environment variables
export ANTHROPIC_API_KEY="sk-ant-..."
export GITHUB_TOKEN="ghp_..."
export GITHUB_REPOSITORY="billyronks/factory-template"

# Step 2: Run the scanner
python scripts/market_scan.py
```

**Example Output:**

```
🤖 Context-Aware Market Research Scanner
==================================================

📋 Step 1: Reading project context...
📖 Found project context in CLAUDE.md
   Context: Invoice Processing SaaS for SMBs

📰 Step 2: Fetching global news signals...
📡 Fetching Google News Technology...
   ✓ Found 10 articles
📡 Fetching TechCrunch...
   ✓ Found 10 articles
   Total articles fetched: 20

🧠 Step 3: Semantic filtering (20 articles)...

   [1/20] Analyzing: OpenAI launches GPT-5 with vision capabilities...
   ⊘ Not relevant

   [2/20] Analyzing: QuickBooks announces AI-powered expense categorization...
   ✓ RELEVANT: Direct competitor adding AI features we should match
   ✓ Created issue #42: Opportunity: QuickBooks announces AI-powered expense...

   [3/20] Analyzing: Stripe acquires invoice automation startup...
   ✓ RELEVANT: Payment processor moving into our market segment
   ✓ Created issue #43: Opportunity: Stripe acquires invoice automation startup

   ...

==================================================
✅ Scan complete!
   Articles analyzed: 20
   Relevant opportunities: 3
   New issues created: 3
   Duplicates skipped: 0
```

**Integrate into CI/CD:**

Add scheduled scanning to your workflow:

```yaml
# .github/workflows/research-loop.yml
on:
  schedule:
    - cron: '0 8 * * *'  # Daily at 8 AM
  workflow_dispatch:

jobs:
  market-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          pip install anthropic PyGithub feedparser

      - name: Run market scanner
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GITHUB_REPOSITORY: ${{ github.repository }}
        run: python scripts/market_scan.py
```

---

### The Research Loop Cycle

Here's how all three components work together:

```
┌─────────────────────────────────────────────────────────┐
│                    RESEARCH LOOP                        │
└─────────────────────────────────────────────────────────┘

1. CONTINUOUS INTELLIGENCE (Automated Daily)
   ├─ research-loop.yml runs at 8 AM UTC
   ├─ Claude scans competitor news and market trends
   └─ Creates issues for actionable intelligence
         │
         ↓
2. MANUAL RESEARCH (Human-Triggered)
   ├─ You drop PDFs/markdown into research/incoming/
   ├─ research-ingestion.yml detects new files
   └─ Claude analyzes and extracts opportunities
         │
         ↓
3. ON-DEMAND SCANNING (Local or CI/CD)
   ├─ Run market_scan.py for immediate insights
   ├─ Fetches RSS feeds + semantic filtering
   └─ Auto-creates GitHub issues for opportunities
         │
         ↓
4. OPPORTUNITY APPROVAL
   ├─ Review issues tagged with strategic-opportunity or research-ingestion
   ├─ Add label: approved-for-development
   └─ Triggers Product Initiation workflow
         │
         ↓
5. PRODUCT CREATION
   └─ New repository spawned with reusable components
```

---

### Best Practices for the Research Loop

#### ✅ DO:
- **Keep CLAUDE.md updated** with your current product focus (affects relevance filtering)
- **Review research issues weekly** to catch emerging trends early
- **Archive old research files** after analysis (move from `incoming/` to `archive/`)
- **Tag urgent opportunities** with `priority-high` for faster review
- **Use the `/research` directory structure:**
  ```
  research/
  ├── incoming/          # New research (triggers workflow)
  ├── archive/           # Processed research (for reference)
  └── opportunities/     # Approved concepts (pre-development)
  ```

#### ❌ DON'T:
- **Don't commit large binary files** (>10MB) to `research/incoming/`—use cloud links instead
- **Don't ignore research issues** for more than 2 weeks (market moves fast)
- **Don't disable the research-loop workflow** unless absolutely necessary
- **Don't skip context in CLAUDE.md** (generic descriptions produce irrelevant results)

---

### Measuring Research Loop Effectiveness

Track these metrics to optimize your intelligence gathering:

```bash
# Number of opportunities identified (last 30 days)
gh issue list --label strategic-opportunity --state all --limit 100 \
  | grep "$(date -d '30 days ago' +%Y-%m)" | wc -l

# Conversion rate: Opportunities → Approved Products
gh issue list --label approved-for-development --state all --limit 100

# Average time from research → product creation
# (Manual calculation: Check issue creation date vs. product-initiation workflow run)
```

**Good Benchmarks:**
- **Signal-to-Noise Ratio:** 10-20% of scanned articles should be relevant
- **Approval Rate:** 20-30% of research opportunities should get approved for development
- **Response Time:** Review research issues within 48 hours of creation

---

## 📋 Day-to-Day Workflows

This section explains the four core workflows you'll use daily as a Factory Operator.

### 🔬 Workflow 1: "I have a product idea"

**Goal:** Turn market research into actionable product opportunities

**The Process:**

1. **Drop a research file into the inbox:**
   ```bash
   # Create a markdown file with your research
   cat > research/incoming/competitor-analysis.md <<EOF
   # Competitor X Launch Analysis

   Competitor X just launched AI-powered invoice processing.
   They're targeting SMBs with $99/month pricing.
   Key features: OCR, auto-categorization, QuickBooks sync.

   Market opportunity: We could build this faster with our existing
   auth and billing modules.
   EOF

   git add research/incoming/competitor-analysis.md
   git commit -m "research: Add competitor analysis"
   git push
   ```

2. **Watch the automation trigger:**
   - **Workflow:** `.github/workflows/research-ingestion.yml`
   - **Trigger:** Detects new files in `research/incoming/`
   - **Action:** Creates a GitHub Issue titled `🕵️ Research Ingestion: competitor-analysis.md`

3. **Wait for Claude to analyze:**
   - Claude reads the file content
   - Extracts key opportunities and gaps
   - Recommends a product concept
   - Posts analysis as a comment on the issue

4. **You decide:** Review the issue and either:
   - Add label `approved-for-development` → Triggers product creation
   - Close the issue if not viable
   - Comment with refinements for Claude to consider

**Example Issue Created:**

```
Title: 🕵️ Research Ingestion: competitor-analysis.md
Labels: research-ingestion, trigger-claude

@claude SYSTEM EVENT: New research detected in research/incoming/competitor-analysis.md

TASK: Analyze this research artifact and extract product opportunities.

1. Summarize: What is this document about?
2. Extract: List any key opportunities or gaps
3. Recommend: Suggest a new product concept
```

**Pro Tip:** You can also trigger this manually:
```bash
gh workflow run research-ingestion.yml
```

---

### 🏗️ Workflow 2: "I need to build the product"

**Goal:** Automatically create a new product repository when an opportunity is approved

**The Process:**

1. **Approve an opportunity:**
   - Go to the research issue from Workflow 1
   - Add label: `approved-for-development`
   - This immediately triggers `.github/workflows/product-initiation.yml`

2. **Watch the factory spin up a new repo:**
   - **Workflow:** `.github/workflows/product-initiation.yml`
   - **Trigger:** Label `approved-for-development` added to any issue
   - **Actions:**
     1. Claude generates a "Reuse Plan" by reading `.repo-index/components.yaml`
     2. Determines which existing components can be reused
     3. Creates a new GitHub repository (e.g., `product-1737549600`)
     4. Prepares to copy reusable components

3. **The new repo is ready:**
   - Check your GitHub organization for the new repo
   - It contains the factory CI/CD system
   - It includes CLAUDE.md with context from the parent

**Example Output:**

```bash
# Terminal output from workflow:
Creating new product repo: product-1737549600
✓ Created repository billyronks/product-1737549600
✓ Initialized with factory template
✓ Copied reusable components: auth, billing, ui-kit
```

**What Gets Copied:**

The workflow analyzes `.repo-index/components.yaml` to determine what to reuse:

```yaml
# Example .repo-index/components.yaml
components:
  - name: auth
    path: packages/auth
    reusable: true
    dependencies: []

  - name: billing
    path: packages/billing
    reusable: true
    dependencies: [auth]

  - name: ui-kit
    path: packages/ui
    reusable: true
    dependencies: []
```

**Manual Alternative:**

If you want to control the repo name and components:

```bash
# Edit the workflow input manually
gh workflow run product-initiation.yml \
  -f issue_number=42 \
  -f repo_name=invoice-processor \
  -f components=auth,billing,ui-kit
```

---

### 🔄 Workflow 3: "I need to sync code"

**Goal:** Keep code synchronized between the Core Factory (parent) and Product Repos (children)

**The Process:**

1. **Identify what needs syncing:**
   - You updated the `auth` module in the parent factory
   - You want to push those changes to 3 child products

2. **Define the path mapping:**
   - **Source Path:** `packages/auth` (in parent factory)
   - **Target Path:** `src/auth` (in child repo)
   - **Mapping Format:** `packages/auth:src/auth`

3. **Trigger the sync:**
   ```bash
   gh workflow run bidirectional-sync.yml \
     -f target_repo=billyronks/invoice-processor \
     -f sync_path=packages/auth:src/auth
   ```

4. **Watch Claude perform intelligent merge:**
   - **Workflow:** `.github/workflows/bidirectional-sync.yml`
   - **Actions:**
     1. Checks out both source and target repos
     2. Compares files in the mapped paths
     3. Copies updated files from source → target
     4. If conflicts exist, Claude attempts intelligent merge
     5. Commits changes to target repo
     6. Pushes to `main` branch

**Example Scenarios:**

**Scenario A: Push Auth Updates to Child**
```bash
# From parent factory
gh workflow run bidirectional-sync.yml \
  -f target_repo=billyronks/product-1737549600 \
  -f sync_path=packages/auth:src/auth
```

**Scenario B: Pull Feature from Child to Parent**
```bash
# From child product repo
gh workflow run bidirectional-sync.yml \
  -f target_repo=billyronks/factory-template \
  -f sync_path=src/new-feature:packages/new-feature
```

**Scenario C: Sync Multiple Paths**
You can trigger multiple syncs in parallel:
```bash
gh workflow run bidirectional-sync.yml -f target_repo=billyronks/child-1 -f sync_path=packages/auth:src/auth
gh workflow run bidirectional-sync.yml -f target_repo=billyronks/child-2 -f sync_path=packages/auth:src/auth
gh workflow run bidirectional-sync.yml -f target_repo=billyronks/child-3 -f sync_path=packages/auth:src/auth
```

**Conflict Resolution:**

If files differ significantly, Claude will:
1. Attempt semantic merge (preserving both changes)
2. If auto-merge fails, create a PR for human review
3. Comment with explanation of conflicts

**Pro Tip:** Set up a scheduled sync for critical modules:

```yaml
# Add to bidirectional-sync.yml
on:
  schedule:
    - cron: '0 3 * * 1' # Every Monday at 3 AM
  workflow_dispatch:
    # ... existing inputs
```

---

### 🚀 Workflow 4: "I am ready to launch"

**Goal:** Activate sales and marketing automation when you publish a release

**The Process:**

1. **Publish a GitHub Release:**
   ```bash
   # Option A: Via GitHub CLI
   gh release create v1.0.0 \
     --title "Invoice Processor v1.0" \
     --notes "Automatically process invoices with AI-powered OCR and QuickBooks sync."

   # Option B: Via GitHub UI
   # Go to: Releases → Draft a new release
   ```

2. **Watch the sales automation trigger:**
   - **Workflow:** `.github/workflows/sales-activation.yml`
   - **Trigger:** Release published
   - **Actions:**
     1. Loads Ideal Customer Profile (ICP) from `config/ideal-customer-profile.yaml`
     2. Simulates Clay API call to enrich leads
     3. Simulates 11x.ai SDR agent for outreach generation
     4. Simulates HubSpot sync

3. **Review the sales pipeline:**
   - Check the workflow logs for lead counts
   - In production, this would actually push to Clay/HubSpot
   - For now, it's a simulation showing you the process

**Example ICP Configuration:**

```yaml
# config/ideal-customer-profile.yaml
icp:
  b2b_saas:
    company_size: "50-500"
    industries:
      - "technology"
      - "financial services"
      - "healthcare"
    funding_stage: ["series_a", "series_b", "series_c"]
    technologies:
      - "kubernetes"
      - "aws"
      - "microservices"
    titles:
      - "CTO"
      - "VP Engineering"
      - "Head of Platform"
    signals:
      - "recent_funding"
      - "hiring_engineering"
      - "technology_adoption"
```

**What Happens:**

```
Workflow Output:
================
✓ Reading ICP from config/ideal-customer-profile.yaml
✓ Connecting to Clay API...
✓ Finding CTOs in Fintech companies using Kubernetes...
✓ FOUND: 142 qualified leads

✓ Triggering AI SDR Agent (Alice)...
✓ Generating personalized email sequence for: Invoice Processor v1.0
✓ Drafting messaging based on 'recent_funding' signal

✓ Pushing 142 contacts to HubSpot Pipeline: 'Product Launch'
✓ Status: SUCCESS
```

**Customizing for Production:**

To connect real sales tools, add these secrets:

```bash
# For Clay integration
CLAY_API_KEY=your_clay_api_key

# For 11x.ai integration
ELEVENLABS_API_KEY=your_11x_api_key

# For HubSpot integration
HUBSPOT_API_KEY=your_hubspot_api_key
```

Then update `.github/workflows/sales-activation.yml` to call real APIs instead of simulations.

**Manual Trigger:**

You can activate sales without publishing a release:

```bash
gh workflow run sales-activation.yml -f product_name=LuckyBag
```

---

## 🧠 The Brain: MCP Server

### What is MCP?

**Model Context Protocol (MCP)** allows your IDE to communicate with the factory's tools. Instead of manually triggering workflows via GitHub UI, you can run them directly from Cursor or Windsurf.

### Available MCP Tools

Factory v4.0 includes two MCP servers:

#### 1️⃣ Repo Operations Server (`mcp-server/repo-operations.py`)

**Tools:**
- `derive_product()` - Trigger product derivation workflow
- `trigger_sync()` - Trigger bidirectional sync workflow

**Use Cases:**
- "Claude, derive a new product called invoice-processor from our factory"
- "Claude, sync the auth package to billyronks/child-repo"

#### 2️⃣ Sales Automation Server (`mcp-server/sales_server.py`)

**Tools:**
- `search_prospects()` - Find prospects matching ICP criteria
- `create_outreach_sequence()` - Generate personalized outreach campaigns

**Use Cases:**
- "Claude, find 50 CTOs in fintech companies using Kubernetes"
- "Claude, create a cold email sequence for product launch"

### Setting Up MCP Locally

**Step 1: Install Dependencies**

```bash
cd mcp-server
pip install mcp
```

**Step 2: Configure Your IDE**

**For Cursor:**

1. Open Cursor Settings
2. Navigate to: **Extensions → MCP**
3. Add server configuration:

```json
{
  "mcpServers": {
    "factory-repo-ops": {
      "command": "python",
      "args": ["/absolute/path/to/mcp-server/repo-operations.py"]
    },
    "factory-sales": {
      "command": "python",
      "args": ["/absolute/path/to/mcp-server/sales_server.py"]
    }
  }
}
```

**For Windsurf:**

1. Open Windsurf Settings
2. Go to: **AI Tools → Model Context Protocol**
3. Add server configurations:

```json
{
  "mcp": {
    "servers": [
      {
        "name": "factory-repo-ops",
        "command": "python /absolute/path/to/mcp-server/repo-operations.py"
      },
      {
        "name": "factory-sales",
        "command": "python /absolute/path/to/mcp-server/sales_server.py"
      }
    ]
  }
}
```

**For Claude Desktop:**

1. Edit `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS)
2. Or `%APPDATA%\Claude\claude_desktop_config.json` (Windows)
3. Add:

```json
{
  "mcpServers": {
    "factory-repo-ops": {
      "command": "python",
      "args": ["/absolute/path/to/mcp-server/repo-operations.py"]
    },
    "factory-sales": {
      "command": "python",
      "args": ["/absolute/path/to/mcp-server/sales_server.py"]
    }
  }
}
```

**Step 3: Restart Your IDE**

Close and reopen Cursor/Windsurf/Claude Desktop for changes to take effect.

**Step 4: Verify Connection**

In your IDE, ask Claude:

```
"What MCP tools do you have access to?"
```

Expected response:
```
I have access to the following MCP tools:
- derive_product (from factory-repo-ops)
- trigger_sync (from factory-repo-ops)
- search_prospects (from factory-sales)
- create_outreach_sequence (from factory-sales)
```

### Using MCP Tools in Your IDE

**Example 1: Derive a Product**

```
You: "Claude, use the factory MCP to derive a new product called 'email-parser' from our monorepo"

Claude: *calls derive_product(source_repo="billyronks/factory-template", new_product_name="email-parser", config_path="configs/derive-email-parser.yaml")*

Claude: "Product derivation workflow triggered. Check GitHub Actions for progress."
```

**Example 2: Sync Code**

```
You: "Claude, sync the auth module to our invoice-processor product"

Claude: *calls trigger_sync(target_repo="billyronks/invoice-processor", sync_path="packages/auth:src/auth")*

Claude: "Sync workflow started. Changes will be pushed to billyronks/invoice-processor shortly."
```

**Example 3: Find Prospects**

```
You: "Claude, find 50 prospects in healthcare using AWS and Kubernetes"

Claude: *calls search_prospects(industry="healthcare", company_size="50-500", location="United States")*

Claude: "Found 50 qualified prospects matching your criteria. Ready to create outreach sequence?"
```

### MCP Best Practices

1. **Use absolute paths** in MCP config (not relative paths)
2. **Ensure GitHub CLI is authenticated:** Run `gh auth login` before using MCP tools
3. **Set environment variables:**
   ```bash
   export GITHUB_TOKEN=ghp_your_token
   export ANTHROPIC_API_KEY=sk-ant-your_key
   ```
4. **Test tools individually** before chaining them in complex commands

---

## ⚖️ The Rules: Tiered Autonomy

### Understanding the Three Tiers

Factory v4.0 uses **risk-based automation** defined in `.coderabbit.yaml`:

| **Tier** | **Risk Level** | **File Patterns** | **Automation** | **Review Required** |
|----------|----------------|-------------------|----------------|---------------------|
| **Tier 0** | Low | `docs/**`, `**/*.test.ts`, `README.md` | ✅ Auto-Merge | None (optional review) |
| **Tier 1** | Medium | `src/features/**`, `src/utils/**` | ⏸️ Request Review | 1 human approval |
| **Tier 2** | High | `src/auth/**`, `src/payments/**`, `infrastructure/**` | 🔒 Strict Gating | 2 approvals + security team |

### How It Works

1. **AI agent (Claude) creates a PR** via workflow
2. **CodeRabbit analyzes the PR** against `.coderabbit.yaml` rules
3. **Tier is determined** by matching file paths
4. **Automation policy is applied:**
   - **Tier 0:** CodeRabbit auto-approves (if configured)
   - **Tier 1:** Requests review from team, waits for 1 approval
   - **Tier 2:** Requires 2 approvals + mandatory security team review

### Configuration

**File:** `.coderabbit.yaml`

```yaml
# Tiered Autonomy Configuration
reviews:
  high_level_summary: true
  auto_review:
    enabled: true
    ignore_title_keywords:
      - "WIP"
    path_filters:
      - "!dist/**"
      - "!**/*.lock"

# Tier Definitions
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

### Customizing Tiers

**Add Tier 0 for config files:**

```yaml
- name: "Tier 0: Low Risk"
  conditions:
    - "files MATCHING 'docs/**'"
    - "files MATCHING '**/*.test.ts'"
    - "files MATCHING 'config/**/*.yaml'"  # ← Add this
  auto_approve: true
```

**Protect ML models as Tier 2:**

```yaml
- name: "Tier 2: Critical Security"
  conditions:
    - "files MATCHING 'src/auth/**'"
    - "files MATCHING 'src/payments/**'"
    - "files MATCHING 'infrastructure/**'"
    - "files MATCHING 'models/**'"  # ← Add this
  require_approval_count: 2
  required_reviewers:
    - "billyronks/security-team"
    - "billyronks/ml-team"  # ← Add ML team
```

### Manual Override

If a bot gets stuck or makes a mistake:

**Option 1: Override via Label**

1. Add label `manual-override` to the PR
2. This bypasses tier rules and allows manual merge

**Option 2: Close and Recreate**

1. Close the AI-generated PR
2. Manually create a new PR with correct changes
3. Tag the AI in a comment: `@claude please update this PR to include XYZ`

**Option 3: Emergency Disable**

Temporarily disable auto-approvals:

```yaml
# In .coderabbit.yaml
reviews:
  auto_review:
    enabled: false  # ← Change to false
```

Commit, push, and all PRs will require manual approval until re-enabled.

---

## 🛠️ Manual Override & Troubleshooting

### Common Workflow Failures

| **Error** | **Cause** | **Solution** |
|-----------|-----------|--------------|
| `ANTHROPIC_API_KEY not found` | Secret not configured | Settings → Secrets → Actions → Add `ANTHROPIC_API_KEY` |
| `FACTORY_ADMIN_TOKEN invalid` | PAT missing scopes | Regenerate token with `repo` and `workflow` scopes |
| `Repository already exists` | Derivation target exists | Delete target repo or change name in workflow input |
| `Permission denied (publickey)` | SSH key issue | Use HTTPS clone instead, or add SSH key to GitHub |
| `No changes to sync` | Source and target identical | Expected behavior—nothing to sync |
| `Claude API timeout` | Rate limit or network issue | Wait 5 minutes and re-run workflow |
| `CodeRabbit not responding` | Service outage | Check https://status.coderabbit.ai |

### Manual Workflow Execution

If a workflow fails repeatedly, run the underlying operation manually:

**Research Ingestion (Manual):**

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
export GITHUB_TOKEN="ghp_..."
export GITHUB_REPOSITORY="your-org/your-repo"

python scripts/market_scan.py
```

**Product Derivation (Manual):**

```bash
# Create target repo
gh repo create your-org/new-product --private

# Clone target
git clone https://github.com/your-org/new-product.git
cd new-product

# Copy files from parent
cp -r ../factory-template/packages/auth ./src/auth
cp -r ../factory-template/packages/billing ./src/billing

# Update imports
find . -name "*.ts" -exec sed -i 's/@factory\/auth/@product\/auth/g' {} +

# Commit and push
git add .
git commit -m "chore: Initial derivation from factory"
git push origin main
```

**Bidirectional Sync (Manual):**

```bash
# Add child repo as remote
git remote add child https://github.com/your-org/child-repo.git
git fetch child

# Cherry-pick specific commits
git cherry-pick abc123def

# Or merge entire branch
git merge child/main

# Push changes
git push origin main
```

### Debugging MCP Connection Issues

**Problem:** IDE doesn't recognize MCP tools

**Solutions:**

1. **Check Python path:**
   ```bash
   which python  # Use this path in MCP config
   ```

2. **Test MCP server directly:**
   ```bash
   python mcp-server/repo-operations.py
   # Should start without errors
   ```

3. **Check logs:**
   - **Cursor:** View → Developer Tools → Console
   - **Windsurf:** Help → Show Logs
   - **Claude Desktop:** ~/Library/Logs/Claude/

4. **Verify MCP package:**
   ```bash
   pip show mcp  # Should show version info
   ```

### Emergency Brake: Disable All Automation

If AI agents are causing problems:

1. **Pause all scheduled workflows:**
   ```bash
   # Disable cron triggers in all workflow files
   find .github/workflows -name "*.yml" -exec sed -i 's/^  schedule:/#  schedule:/g' {} +
   git add .github/workflows
   git commit -m "chore: Pause all scheduled workflows"
   git push
   ```

2. **Remove API keys (nuclear option):**
   - Settings → Secrets → Actions
   - Delete `ANTHROPIC_API_KEY`
   - All AI workflows will fail immediately

3. **Disable CodeRabbit:**
   ```yaml
   # In .coderabbit.yaml
   reviews:
     auto_review:
       enabled: false
   policy: []  # Clear all policies
   ```

4. **Restore manually when ready:**
   - Re-add API key
   - Re-enable workflows
   - Re-configure .coderabbit.yaml

---

## 🎯 Quick Reference

### Essential Commands

```bash
# ==========================================
# Research & Product Workflows
# ==========================================

# Manually trigger research ingestion
gh workflow run research-ingestion.yml

# Manually trigger product initiation
gh workflow run product-initiation.yml

# Run local market scan
python scripts/market_scan.py

# ==========================================
# Code Synchronization
# ==========================================

# Sync parent → child
gh workflow run bidirectional-sync.yml \
  -f target_repo=org/child \
  -f sync_path=packages/core:src

# Sync child → parent (run from child)
gh workflow run bidirectional-sync.yml \
  -f target_repo=org/parent \
  -f sync_path=src:packages/core

# ==========================================
# Sales & Marketing
# ==========================================

# Trigger sales activation
gh workflow run sales-activation.yml \
  -f product_name=MyProduct

# Publish release (triggers sales automation)
gh release create v1.0.0 \
  --title "Product Launch" \
  --notes "Revolutionary new features"

# ==========================================
# Debugging & Maintenance
# ==========================================

# View workflow runs
gh run list --workflow=research-ingestion.yml

# View logs for failed run
gh run view 123456789 --log-failed

# Re-run failed workflow
gh run rerun 123456789

# Check factory architecture
python scripts/architecture_audit.py
```

### Key Files at a Glance

| **File** | **Purpose** |
|----------|-------------|
| `CLAUDE.md` | Factory DNA—context for all AI agents |
| `.coderabbit.yaml` | Tiered autonomy rules for PR reviews |
| `config/ideal-customer-profile.yaml` | ICP for sales automation |
| `.github/workflows/research-ingestion.yml` | Research → Opportunity pipeline |
| `.github/workflows/product-initiation.yml` | Opportunity → New Repo creation |
| `.github/workflows/bidirectional-sync.yml` | Parent ↔ Child code sync |
| `.github/workflows/sales-activation.yml` | Release → Sales automation |
| `mcp-server/repo-operations.py` | MCP tools for repo operations |
| `mcp-server/sales_server.py` | MCP tools for sales automation |
| `research/incoming/` | Drop research files here to trigger analysis |
| `.repo-index/components.yaml` | Reusable component manifest |

### Workflow Triggers at a Glance

| **Trigger** | **Workflow** | **Action** |
|-------------|--------------|------------|
| Push to `research/incoming/` | Research Ingestion | Creates issue with Claude analysis |
| Label `approved-for-development` | Product Initiation | Creates new product repo |
| Manual dispatch | Bidirectional Sync | Syncs code between repos |
| Publish GitHub Release | Sales Activation | Activates sales automation |
| Daily cron (2 AM) | Repo Analysis | Updates component index |

### MCP Tools Quick Reference

```python
# Repo Operations
derive_product(
  source_repo="billyronks/factory-template",
  new_product_name="invoice-processor",
  config_path="configs/derive.yaml"
)

trigger_sync(
  target_repo="billyronks/child-repo",
  sync_path="packages/auth:src/auth"
)

# Sales Automation
search_prospects(
  industry="fintech",
  company_size="50-500",
  location="United States"
)

create_outreach_sequence(
  prospect_ids=[1, 2, 3],
  campaign_type="product_launch"
)
```

---

## 📚 Additional Resources

- **Universal Transformation Kit:** `docs/universal-transformation-kit.md` - Install factory CI/CD in any repo
- **Architecture Documentation:** `docs/architecture/` - Deep dives into factory internals
- **Claude Code Action:** [anthropics/claude-code-action](https://github.com/anthropics/claude-code-action) - Official docs
- **MCP Protocol:** [Model Context Protocol](https://modelcontextprotocol.io/) - Specification
- **Factory Constitution:** `CLAUDE.md` - Complete operating rules

---

## 🎓 Learning Path

**Week 1: Foundation**
- Set up your first factory from template
- Configure secrets and run verification
- Trigger your first research ingestion
- Review and approve an opportunity

**Week 2: Product Creation**
- Create your first product repo via product-initiation
- Set up MCP in your IDE
- Use MCP to trigger a sync workflow
- Customize your ICP for sales automation

**Week 3: Advanced Operations**
- Customize tiered autonomy rules
- Set up scheduled syncs for critical modules
- Integrate real Clay/HubSpot APIs
- Build custom MCP tools for your workflow

**Week 4: Scale**
- Operate 3+ product repos simultaneously
- Create bidirectional sync pipelines
- Automate release → sales → marketing pipeline
- Train your team on factory operations

---

**Welcome to the future of software development. Ship fast. Build autonomously. Stay ahead.**

🏭 **Factory v4.0** | Powered by Claude & BillyRonks Global
