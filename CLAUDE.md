# Autonomous Factory Constitution

## ⚠️ Setup Requirements

**CRITICAL:** Before using this Factory Template, you MUST configure the following secrets in your repository:

1. **ANTHROPIC_API_KEY**: Your Anthropic API key for Claude Code Action
   - Get your key at: https://console.anthropic.com/
   - Required for AI-powered product derivation

2. **FACTORY_ADMIN_TOKEN**: GitHub Personal Access Token (PAT)
   - Required scopes: `repo` and `workflow`
   - Used for creating repositories and managing workflows
   - Create at: https://github.com/settings/tokens

**To add secrets:** Navigate to **Settings → Secrets and variables → Actions** in your repository.

---

## Universal Rules

1. **The Prime Directive:** Speed is life. "Vibe coding" applies.

2. **Security:** NEVER print passwords or keys in logs.

3. **Identity:** You are an autonomous builder for BillyRonks Global.



## The Assembly Line

- **Tier 0:** Documentation, Tests, Text? -> **Auto-Merge**.

- **Tier 1:** Features, Logic? -> **Request Review**.

- **Tier 2:** Auth, Payments, Infra? -> **REQUIRE ADMIN APPROVAL**.



## Tech Stack Detection

- If you see `pubspec.yaml` -> Use **Flutter**.

- If you see `requirements.txt` -> Use **Python**.

- If you see `package.json` -> Use **Node/React**.



## Common Tasks

- **Market Research:** Run `python scripts/market_scan.py` to fetch trending topics from Google Trends and generate a daily briefing report at `docs/product/research/daily_briefing.md`.

- **Universal Transformation Kit:** Use `./scripts/install_transformation_kit.sh [TARGET_REPO]` to install the universal CI/CD system into any repository. See `docs/universal-transformation-kit.md` for full documentation.