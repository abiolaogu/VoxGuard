#!/usr/bin/env python3
"""
Context-Aware Market Research Scanner
Uses semantic analysis via Anthropic API to filter relevant news and auto-create GitHub issues.
"""

import os
import re
import sys
import feedparser
from datetime import datetime
from pathlib import Path
from anthropic import Anthropic
from github import Github


def extract_project_description(file_path):
    """
    Extract project description from CLAUDE.md or README.md.

    Args:
        file_path: Path to the markdown file

    Returns:
        Extracted project description or None
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Look for common patterns:
        # - "Project Description:" followed by text
        # - First paragraph after main heading
        # - "Identity:" line (from CLAUDE.md format)

        # Pattern 1: Explicit "Project Description"
        desc_match = re.search(r'(?:Project Description|Description):\s*(.+?)(?:\n\n|\n#|$)', content, re.IGNORECASE | re.DOTALL)
        if desc_match:
            return desc_match.group(1).strip()

        # Pattern 2: "Identity:" from CLAUDE.md
        identity_match = re.search(r'\*\*Identity:\*\*\s*(.+?)(?:\n|$)', content)
        if identity_match:
            return identity_match.group(1).strip()

        # Pattern 3: First substantial paragraph
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if line.startswith('#'):
                # Get text after heading until next heading or double newline
                remaining = '\n'.join(lines[i+1:])
                para_match = re.search(r'^\s*(.+?)(?:\n\n|\n#|$)', remaining, re.DOTALL)
                if para_match:
                    desc = para_match.group(1).strip()
                    if len(desc) > 20:  # Ensure it's substantial
                        return desc

        return None

    except FileNotFoundError:
        return None


def read_project_context():
    """
    Read project context from CLAUDE.md or README.md.

    Returns:
        Project description string
    """
    base_path = Path(__file__).parent.parent

    # Try CLAUDE.md first
    claude_md = base_path / 'CLAUDE.md'
    description = extract_project_description(claude_md)

    if description:
        print(f"📖 Found project context in CLAUDE.md")
        return description

    # Fallback to README.md
    readme_md = base_path / 'README.md'
    description = extract_project_description(readme_md)

    if description:
        print(f"📖 Found project context in README.md")
        return description

    # Ultimate fallback
    print("⚠️  No project description found in CLAUDE.md or README.md")
    return "BillyRonks Global - An autonomous builder and technology company"


def fetch_rss_feeds():
    """
    Fetch RSS feeds from Google News Technology and TechCrunch.

    Returns:
        List of news items with title, link, and summary
    """
    feeds = [
        ('Google News Technology', 'https://news.google.com/rss/search?q=technology&hl=en-US&gl=US&ceid=US:en'),
        ('TechCrunch', 'https://techcrunch.com/feed/')
    ]

    news_items = []

    for source_name, feed_url in feeds:
        print(f"📡 Fetching {source_name}...")
        try:
            feed = feedparser.parse(feed_url)

            for entry in feed.entries[:10]:  # Get top 10 from each source
                news_items.append({
                    'source': source_name,
                    'title': entry.get('title', 'No title'),
                    'link': entry.get('link', ''),
                    'summary': entry.get('summary', entry.get('description', ''))
                })

            print(f"   ✓ Found {len(feed.entries[:10])} articles")

        except Exception as e:
            print(f"   ✗ Error fetching {source_name}: {e}")

    return news_items


def analyze_relevance(project_description, headline, anthropic_api_key):
    """
    Use Anthropic API to determine if a headline is relevant to the project.

    Args:
        project_description: The project's description
        headline: News headline to analyze
        anthropic_api_key: Anthropic API key

    Returns:
        Tuple of (is_relevant: bool, explanation: str)
    """
    client = Anthropic(api_key=anthropic_api_key)

    prompt = f"""My project is: {project_description}

News Headline: {headline}

Is this news directly relevant to my project? Answer YES or NO. If YES, explain the opportunity in one sentence."""

    try:
        message = client.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=150,
            messages=[
                {"role": "user", "content": prompt}
            ]
        )

        response = message.content[0].text.strip()

        # Parse response
        is_relevant = response.upper().startswith('YES')

        if is_relevant:
            # Extract explanation (everything after YES)
            explanation = response[3:].strip()
            if explanation.startswith('.') or explanation.startswith(','):
                explanation = explanation[1:].strip()
            return True, explanation

        return False, ""

    except Exception as e:
        print(f"   ✗ Error calling Anthropic API: {e}")
        return False, ""


def check_issue_exists(github_client, repo_name, news_url):
    """
    Check if an issue with this URL already exists.

    Args:
        github_client: GitHub client instance
        repo_name: Repository name (owner/repo)
        news_url: URL to check for

    Returns:
        True if issue exists, False otherwise
    """
    try:
        repo = github_client.get_repo(repo_name)
        issues = repo.get_issues(state='all', labels=['strategic-opportunity'])

        for issue in issues:
            if news_url in issue.body:
                return True

        return False

    except Exception as e:
        print(f"   ✗ Error checking existing issues: {e}")
        return False


def create_github_issue(github_client, repo_name, headline, explanation, news_url):
    """
    Create a GitHub issue for a relevant news item.

    Args:
        github_client: GitHub client instance
        repo_name: Repository name (owner/repo)
        headline: News headline
        explanation: Relevance explanation from LLM
        news_url: Source URL

    Returns:
        Created issue object or None
    """
    try:
        repo = github_client.get_repo(repo_name)

        # Get or create the label
        try:
            label = repo.get_label('strategic-opportunity')
        except:
            label = repo.create_label('strategic-opportunity', '8B5CF6', 'AI-identified strategic opportunity')

        title = f"Opportunity: {headline}"
        body = f"""**Relevance Analysis:** {explanation}

**Source:** {news_url}

---
*Auto-generated by context-aware market research scanner*"""

        issue = repo.create_issue(
            title=title,
            body=body,
            labels=[label]
        )

        print(f"   ✓ Created issue #{issue.number}: {headline[:50]}...")
        return issue

    except Exception as e:
        print(f"   ✗ Error creating GitHub issue: {e}")
        return None


def main():
    """Main execution function."""
    print("🤖 Context-Aware Market Research Scanner")
    print("=" * 50)

    # Step 1: Read project context
    print("\n📋 Step 1: Reading project context...")
    project_description = read_project_context()
    print(f"   Context: {project_description}")

    # Check for required environment variables
    anthropic_api_key = os.getenv('ANTHROPIC_API_KEY')
    github_token = os.getenv('GITHUB_TOKEN')
    github_repo = os.getenv('GITHUB_REPOSITORY')  # Format: owner/repo

    if not anthropic_api_key:
        print("\n❌ Error: ANTHROPIC_API_KEY environment variable not set")
        return 1

    if not github_token:
        print("\n❌ Error: GITHUB_TOKEN environment variable not set")
        return 1

    if not github_repo:
        print("\n⚠️  Warning: GITHUB_REPOSITORY not set, using default 'billyronks/billyronks-production-01'")
        github_repo = 'billyronks/billyronks-production-01'

    # Step 2: Fetch news feeds
    print("\n📰 Step 2: Fetching global news signals...")
    news_items = fetch_rss_feeds()
    print(f"   Total articles fetched: {len(news_items)}")

    if not news_items:
        print("\n⚠️  No news items found")
        return 0

    # Step 3: Semantic filtering
    print(f"\n🧠 Step 3: Semantic filtering ({len(news_items)} articles)...")
    github_client = Github(github_token)
    relevant_count = 0
    created_count = 0
    skipped_count = 0

    for i, item in enumerate(news_items, 1):
        print(f"\n   [{i}/{len(news_items)}] Analyzing: {item['title'][:60]}...")

        # Check relevance
        is_relevant, explanation = analyze_relevance(
            project_description,
            item['title'],
            anthropic_api_key
        )

        if is_relevant:
            relevant_count += 1
            print(f"   ✓ RELEVANT: {explanation[:80]}...")

            # Step 4: Deduplication check
            if check_issue_exists(github_client, github_repo, item['link']):
                print(f"   ⊘ Issue already exists, skipping...")
                skipped_count += 1
                continue

            # Step 5: Create GitHub issue
            issue = create_github_issue(
                github_client,
                github_repo,
                item['title'],
                explanation,
                item['link']
            )

            if issue:
                created_count += 1
        else:
            print(f"   ⊘ Not relevant")

    # Summary
    print("\n" + "=" * 50)
    print("✅ Scan complete!")
    print(f"   Articles analyzed: {len(news_items)}")
    print(f"   Relevant opportunities: {relevant_count}")
    print(f"   New issues created: {created_count}")
    print(f"   Duplicates skipped: {skipped_count}")

    return 0


if __name__ == '__main__':
    try:
        exit(main())
    except KeyboardInterrupt:
        print("\n\n⚠️  Scan interrupted by user")
        exit(130)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        exit(1)