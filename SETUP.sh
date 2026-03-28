#!/bin/bash
# Run from repo root to install mandatory skills for Ascendant Ventures projects
# Usage: bash SETUP.sh

set -e

echo "Installing Superpowers (obra/superpowers)..."
npx -y skills add obra/superpowers --yes

echo "Installing Impeccable (pbakaus/impeccable)..."
npx -y skills add pbakaus/impeccable --yes

echo "Writing .mcp.json (Context7)..."
cat > .mcp.json << 'EOF'
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    }
  }
}
EOF

echo "Installing Foundary (ascendantventures/foundary)..."
# Clone foundary if not cached, then init
FOUNDARY_CACHE="$HOME/.foundary-cache"
if [ ! -d "$FOUNDARY_CACHE" ]; then
  git clone https://github.com/ascendantventures/foundary.git "$FOUNDARY_CACHE"
else
  git -C "$FOUNDARY_CACHE" pull --quiet
fi
node "$FOUNDARY_CACHE/bin/foundary" init

echo "Installing Foundary CI workflow..."
mkdir -p .github/workflows
curl -s "https://raw.githubusercontent.com/ascendantventures/foundary/main/ci/foundary.yml" \
  -o .github/workflows/foundary.yml 2>/dev/null || \
  cp "$FOUNDARY_CACHE/ci/foundary.yml" .github/workflows/foundary.yml 2>/dev/null || \
  cat > .github/workflows/foundary.yml << 'CIEOF'
name: Foundary Governance Check
on:
  pull_request:
    branches: [main, master]
jobs:
  foundary-audit:
    name: Verify Foundary Pipeline Compliance
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Check Foundary initialized
        run: |
          if [ ! -f ".foundary/config.json" ]; then
            echo "❌ FOUNDARY: .foundary/config.json missing. Run: foundary init"
            exit 1
          fi
          echo "✅ Foundary initialized"
      - name: Strict audit enforcement (if enabled)
        if: ${{ vars.FOUNDARY_REQUIRE_AUDIT == 'true' }}
        run: |
          if [ ! -d ".foundary/audit" ] || ! ls .foundary/audit/*.jsonl >/dev/null 2>&1; then
            echo "❌ FOUNDARY: Strict mode enabled. This PR has no Foundary audit trail."
            exit 1
          fi
          echo "✅ Audit trail present"
CIEOF

echo "Setting up GitHub branch protection..."
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
DEFAULT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
if [ -n "$REPO" ]; then
  echo '{"required_status_checks":{"strict":false,"contexts":["Foundary Governance Check"]},"enforce_admins":false,"required_pull_request_reviews":null,"restrictions":null,"allow_force_pushes":false,"allow_deletions":false}' | \
    gh api --method PUT "repos/$REPO/branches/$DEFAULT_BRANCH/protection" --input - > /dev/null 2>&1 && \
    echo "  ✅ Branch protection enabled (Foundary CI required)" || \
    echo "  ⚠️  Branch protection failed — set manually in GitHub settings"
fi

echo ""
echo "✅ Done. Next steps:"
echo "  1. Copy AGENTS.md and CLAUDE.md templates from workspace/.agents/templates/new-repo/"
echo "  2. Fill in project-specific sections"
echo "  3. Commit .mcp.json, AGENTS.md, CLAUDE.md, .foundary/config.json, .github/workflows/foundary.yml"
echo "  4. On first Claude Code session, run /teach-impeccable"
echo "  5. Governance active: Foundary CI blocks PRs, hooks enforce pipeline use"
echo ""
echo "Foundary commands:"
echo "  foundary run --task <spec>          Feature work"
echo "  foundary hotfix --message <msg>     Small fixes (1-5 files)"
echo "  FOUNDARY_ADMIN=1 git commit         Emergency override (audited)"
