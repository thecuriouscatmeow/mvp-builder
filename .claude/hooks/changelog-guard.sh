#!/bin/bash
set -euo pipefail

# changelog-guard.sh - Ensures CHANGELOG.md is staged when content/design files change
# Usage: changelog-guard.sh <project-dir>

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR" || exit 1

# Get all staged files
staged_files=$(git diff --cached --name-only 2>/dev/null || echo "")

# Check if any content/design files are staged
content_files=$(echo "$staged_files" | grep -E "^docs/(0[0-6]|0[0-1])-|^src/wp-content/" || true)

if [ -z "$content_files" ]; then
  # No tracked files staged, exit clean
  exit 0
fi

# Check if CHANGELOG.md is in staged set
if echo "$staged_files" | grep -q "^docs/CHANGELOG.md$"; then
  # CHANGELOG.md is staged
  exit 0
fi

# Content files staged but CHANGELOG.md missing
echo "Content/design files modified but docs/CHANGELOG.md not staged:" >&2
echo "$content_files" >&2
exit 1
